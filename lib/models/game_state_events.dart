import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'event.dart';
import 'game_state.dart';
import 'business.dart';
import 'real_estate.dart';

// Extension for game_state.dart to handle game events
extension GameStateEvents on GameState {
  // Constants
  static const double EVENT_INCOME_PENALTY = -0.25; // Existing penalty (will be superseded by the multiplier)
  static const int EVENT_COOLDOWN_SECONDS = 600; // 10 minutes between events
  static const int EVENT_MIN_BUSINESSES = 3; // Min businesses needed to trigger events
  static const int EVENT_MIN_LOCALES = 2; // Min locales with properties needed to trigger events
  static const int EVENT_MAX_PER_HOUR = 4; // Maximum 4 events in a 60-minute window
  
  // Negative Multiplier for active, unresolved events
  static const double NEGATIVE_EVENT_MULTIPLIER = -0.25;
  
  // Check if event system should be unlocked
  void _checkEventUnlockConditions() {
    if (eventsUnlocked) return; // Already unlocked
    
    // Count owned businesses
    int businessCount = 0;
    for (var business in businesses) {
      if (business.level > 0) businessCount++;
    }
    
    // Count locales with properties
    Set<String> localesWithProperties = {};
    for (var locale in realEstateLocales) {
      for (var property in locale.properties) {
        if (property.owned > 0) {
          localesWithProperties.add(locale.id);
          break;
        }
      }
    }
    
    // Update counters
    businessesOwnedCount = businessCount;
    localesWithPropertiesCount = localesWithProperties.length;
    
    // Check unlock conditions
    if (businessCount >= EVENT_MIN_BUSINESSES || 
        localesWithProperties.length >= EVENT_MIN_LOCALES) {
      eventsUnlocked = true;
      notifyListeners();
    }
  }
  
  // Check if it's time to trigger a new event
  void _checkEventTriggers() {
    if (!eventsUnlocked) return;
    if (activeEvents.length >= 3) return; // Max 3 active events
    
    final now = DateTime.now();
    
    // Clean up old event times (remove events older than 1 hour)
    recentEventTimes.removeWhere((time) => now.difference(time).inMinutes > 60);
    
    // Check if we already have maximum events per hour
    if (recentEventTimes.length >= EVENT_MAX_PER_HOUR) return;
    
    // Check cooldown period
    if (lastEventTime != null) {
      final timeSinceLastEvent = now.difference(lastEventTime!).inSeconds;
      if (timeSinceLastEvent < EVENT_COOLDOWN_SECONDS) return;
    }
    
    // Random chance to trigger event (10% chance per check when eligible)
    if (Random().nextDouble() < 0.1) {
      _triggerRandomEvent();
      lastEventTime = now;
      recentEventTimes.add(now); // Track this event for the hourly limit
    }
  }
  
  // Generate and add a random event
  void _triggerRandomEvent() {
    // Prepare business and locale IDs for potential targeting
    List<String> businessIds = [];
    for (var business in businesses) {
      if (business.level > 0) businessIds.add(business.id);
    }
    
    List<String> localeIds = [];
    for (var locale in realEstateLocales) {
      for (var property in locale.properties) {
        if (property.owned > 0) {
          localeIds.add(locale.id);
          break;
        }
      }
    }
    
    if (businessIds.isEmpty && localeIds.isEmpty) return;
    
    // Events can only impact EITHER a single business OR a single locale - NEVER BOTH
    List<String> affectedBusinessIds = [];
    List<String> affectedLocaleIds = [];
    
    // First determine if we will affect a business or a locale (never both)
    bool affectBusiness = businessIds.isNotEmpty && (localeIds.isEmpty || Random().nextBool());
    
    if (affectBusiness && businessIds.isNotEmpty) {
      // Choose ONE RANDOM BUSINESS - never multiple
      int randomIndex = Random().nextInt(businessIds.length);
      // Only add a single business ID to the array - ONLY ONE BUSINESS AT A TIME
      affectedBusinessIds = [businessIds[randomIndex]];
      // Ensure locale list is empty - NEVER AFFECT BOTH A BUSINESS AND A LOCALE
      affectedLocaleIds = [];
    } else if (localeIds.isNotEmpty) {
      // Choose ONE RANDOM LOCALE - never multiple
      int randomIndex = Random().nextInt(localeIds.length);
      // Only add a single locale ID to the array - ONLY ONE LOCALE AT A TIME
      affectedLocaleIds = [localeIds[randomIndex]];
      // Ensure business list is empty - NEVER AFFECT BOTH A BUSINESS AND A LOCALE
      affectedBusinessIds = [];
    }
    
    // Verify we're only affecting one entity - either one business XOR one locale
    assert(affectedBusinessIds.length <= 1 && affectedLocaleIds.length <= 1);
    assert(!(affectedBusinessIds.isNotEmpty && affectedLocaleIds.isNotEmpty));
    
    // Create the event
    GameEvent newEvent;
    int attempts = 0; // Prevent infinite loop in rare cases
    do {
      newEvent = _createRandomEvent(affectedBusinessIds, affectedLocaleIds, isResilienceActive: isPlatinumResilienceActive);
      attempts++;
    } while (
      isDisasterShieldActive && 
      newEvent.type == EventType.disaster && 
      attempts < 10 // Safety break
    );

    // Only add the event if it's not a disaster while the shield is active (or if we failed to find a non-disaster)
    if (!(isDisasterShieldActive && newEvent.type == EventType.disaster)) {
      // NEW SAFEGUARD: Double-check ad event limits before adding
      bool canAddEvent = true;
      
      if (newEvent.resolution.type == EventResolutionType.adBased && !isPremium) {
        // For non-premium users, count existing ad events again as a final safeguard
        int currentAdEvents = activeEvents.where((event) => 
          !event.isResolved && event.resolution.type == EventResolutionType.adBased
        ).length;
        
        if (currentAdEvents >= 1) {
          canAddEvent = false;
          print("INFO: Prevented adding ad event - non-premium user already has ${currentAdEvents} ad events");
        }
      }
      
      if (canAddEvent) {
        activeEvents.add(newEvent);
        print("INFO: Added new ${newEvent.resolution.type.name} event: ${newEvent.name}");
      } else {
        print("INFO: Event generation blocked by ad limit policy");
      }
      
      notifyListeners();
      // ADDED: Notify AdMobService of event state change for predictive ad loading
      notifyAdMobServiceOfEventStateChange();
    } else {
      print("INFO: Disaster event blocked by shield.");
      // Optionally trigger a different, less impactful event?
    }
  }
  
  // Create a random event with the given affected targets
  GameEvent _createRandomEvent(List<String> businessIds, List<String> localeIds, {required bool isResilienceActive}) {
    final eventTypes = EventType.values;
    
    // Pick random event type
    final eventType = eventTypes[Random().nextInt(eventTypes.length)];
    
    // NEW LOGIC: Intelligently select resolution type based on premium status, existing events,
    // and player progression (new player protection)
    
    // Count how many active ad-based events currently exist
    int existingAdEvents = activeEvents.where((event) => 
      !event.isResolved && event.resolution.type == EventResolutionType.adBased
    ).length;
    
    // NEW PLAYER PROTECTION: Don't require ads until player has solved at least 4 events
    // This improves the new player experience by letting them learn the event system first
    const int minEventsBeforeAds = 4;
    bool playerHasEnoughExperience = totalEventsResolved >= minEventsBeforeAds;
    
    // Available resolution types based on premium status, existing events, and player experience
    List<EventResolutionType> availableResolutionTypes = [
      EventResolutionType.tapChallenge,
      EventResolutionType.feeBased,
    ];
    
    // Add ad-based resolution only if:
    // 1. Player has resolved at least 4 events (new player protection), AND
    // 2. User has premium (no limit), OR
    // 3. User doesn't have premium but there are no existing ad events (max 1)
    if (playerHasEnoughExperience && (isPremium || existingAdEvents == 0)) {
      availableResolutionTypes.add(EventResolutionType.adBased);
    }
    
    // Select resolution type from available options
    final resolutionType = availableResolutionTypes[Random().nextInt(availableResolutionTypes.length)];
    
    // Determine resolution value based on type
    dynamic resolutionValue;
    switch (resolutionType) {
      case EventResolutionType.tapChallenge:
        int requiredTaps = 50 + Random().nextInt(151); // Base 50-200 taps
        // FIX: Apply accelerator effect here
        if (isCrisisAcceleratorActive) { // Check the flag from GameState
            requiredTaps = (requiredTaps * 0.5).ceil(); // Halve and round up
            print("INFO: Crisis Accelerator reduced tap requirement to $requiredTaps");
        }
        resolutionValue = {'required': requiredTaps, 'current': 0};
        break;
      case EventResolutionType.feeBased:
        // Calculate fee based on player's current income per second
        // Ensure we access totalIncomePerSecond correctly (it's a getter on GameState)
        double currentIncomePerSecond = this.totalIncomePerSecond; // Accessing the getter directly
        double fee = (currentIncomePerSecond * 60 * Random().nextDouble() * 0.5) + 100; // 0-30 mins of income + base 100
        // NOTE: Cost reduction needs to be applied where the fee is actually paid (UI/Service layer)
        // We cannot halve it here as the accelerator might expire before payment.
        resolutionValue = fee;
        break;
      case EventResolutionType.adBased:
        // Ad-based doesn't have a numeric value here, resolution handled by ad completion callback
        resolutionValue = true; 
        break;
      case EventResolutionType.timeBased:
        // Duration handled by the event itself, no specific value needed here
        resolutionValue = null;
        break;
    }
    
    // Get names of affected businesses and locales for more descriptive messages
    List<String> affectedBusinessNames = [];
    List<String> affectedLocaleNames = [];
    
    for (var businessId in businessIds) {
      var business = businesses.firstWhere((b) => b.id == businessId, orElse: () => Business(
        id: '', 
        name: 'Unknown', 
        description: '', 
        basePrice: 0, 
        baseIncome: 0, 
        incomeInterval: 0, 
        unlocked: false, 
        level: 0, 
        icon: Icons.error, 
        levels: [
          // Add at least one level since the Business class methods try to access the levels array
          BusinessLevel(
            cost: 0,
            incomePerSecond: 0,
            description: 'Default',
            timerSeconds: 0,
          )
        ],
        maxLevel: 10,
        secondsSinceLastIncome: 0,
      ));
      affectedBusinessNames.add(business.name);
    }
    
    for (var localeId in localeIds) {
      var locale = realEstateLocales.firstWhere((l) => l.id == localeId, orElse: () => RealEstateLocale(
        id: '', 
        name: 'Unknown', 
        theme: '', 
        unlocked: false, 
        icon: Icons.error, 
        properties: [
          // Add at least one property since RealEstateLocale methods try to access the properties array
          RealEstateProperty(
            id: 'default_property',
            name: 'Default Property',
            purchasePrice: 0,
            baseCashFlowPerSecond: 0,
            unlocked: false,
            owned: 0
          )
        ]
      ));
      affectedLocaleNames.add(locale.name);
    }
    
    // Generate event details based on type
    String name;
    String description;
    
    switch (eventType) {
      case EventType.disaster:
        final disasters = [
          {'name': 'Earthquake', 'desc': 'A minor earthquake has damaged some of your properties.'},
          {'name': 'Flood', 'desc': 'Flooding has damaged several of your properties.'},
          {'name': 'Fire', 'desc': 'A fire has affected operations at some of your properties.'},
        ];
        final selected = disasters[Random().nextInt(disasters.length)];
        name = selected['name']!;
        
        // Create a more detailed description with location names
        if (localeIds.isNotEmpty) {
          String locations = affectedLocaleNames.join(' and ');
          description = selected['desc']!.replaceFirst('.', ' in $locations.');
        } else if (businessIds.isNotEmpty) {
          String businesses = affectedBusinessNames.join(' and ');
          description = selected['desc']!.replaceFirst('.', ' at $businesses.');
        } else {
          description = selected['desc']!;
        }
        break;
        
      case EventType.economic:
        final issues = [
          {'name': 'Recession', 'desc': 'An economic downturn is reducing customer spending.'},
          {'name': 'Inflation', 'desc': 'Rising costs are cutting into your profits.'},
          {'name': 'Currency Crisis', 'desc': 'Currency fluctuations are hurting your bottom line.'},
        ];
        final selected = issues[Random().nextInt(issues.length)];
        name = selected['name']!;
        
        // For economic events, either use business names or generic description
        if (businessIds.isNotEmpty) {
          String businesses = affectedBusinessNames.join(' and ');
          description = selected['desc']!.replaceFirst('.', ' for $businesses.');
        } else {
          description = selected['desc']!;
        }
        break;
        
      case EventType.security:
        final issues = [
          {'name': 'Break-in', 'desc': 'A break-in has disrupted operations at some locations.'},
          {'name': 'Cyber Attack', 'desc': 'A cyber attack has affected your payment systems.'},
          {'name': 'Theft', 'desc': 'Some inventory has been stolen from your businesses.'},
        ];
        final selected = issues[Random().nextInt(issues.length)];
        name = selected['name']!;
        
        // For security events, add location context
        if (businessIds.isNotEmpty) {
          String businesses = affectedBusinessNames.join(' and ');
          description = selected['desc']!.replaceFirst('some locations', '$businesses');
          description = description.replaceFirst('your businesses', '$businesses');
        } else if (localeIds.isNotEmpty) {
          String locations = affectedLocaleNames.join(' and ');
          description = selected['desc']!.replaceFirst('some locations', 'properties in $locations');
          description = description.replaceFirst('your businesses', 'your properties in $locations');
        } else {
          description = selected['desc']!;
        }
        break;
        
      case EventType.utility:
        final issues = [
          {'name': 'Power Outage', 'desc': 'A power outage has affected your operations.'},
          {'name': 'Internet Outage', 'desc': 'Internet connectivity issues are hurting business.'},
          {'name': 'Water Main Break', 'desc': 'A water main break has temporarily closed some locations.'},
        ];
        final selected = issues[Random().nextInt(issues.length)];
        name = selected['name']!;
        
        // For utility events, specify affected areas
        if (localeIds.isNotEmpty) {
          String locations = affectedLocaleNames.join(' and ');
          description = selected['desc']!.replaceFirst('.', ' in $locations.');
          description = description.replaceFirst('some locations', 'locations in $locations');
        } else if (businessIds.isNotEmpty) {
          String businesses = affectedBusinessNames.join(' and ');
          description = selected['desc']!.replaceFirst('.', ' at $businesses.');
          description = description.replaceFirst('some locations', '$businesses');
        } else {
          description = selected['desc']!;
        }
        break;
        
      case EventType.staff:
        final issues = [
          {'name': 'Staff Shortage', 'desc': 'A staff shortage is affecting your ability to operate at full capacity.'},
          {'name': 'Strike', 'desc': 'Workers are on strike at some of your business locations.'},
          {'name': 'Training Issue', 'desc': 'Poor training has led to reduced efficiency.'},
        ];
        final selected = issues[Random().nextInt(issues.length)];
        name = selected['name']!;
        
        // For staff events, add business names
        if (businessIds.isNotEmpty) {
          String businesses = affectedBusinessNames.join(' and ');
          description = selected['desc']!.replaceFirst('.', ' at $businesses.');
          description = description.replaceFirst('some of your businesses', '$businesses');
        } else {
          description = selected['desc']!;
        }
        break;
    }
    
    // Create and return the event
    return GameEvent(
      id: const Uuid().v4(),
      name: name,
      description: description,
      type: eventType,
      affectedBusinessIds: businessIds,
      affectedLocaleIds: localeIds,
      resolution: EventResolution(
        type: resolutionType,
        value: resolutionValue,
      ),
      startTime: DateTime.now(),
    );
  }
  
  // Update existing events (check for resolved events, update timers)
  void _updateEvents() {
    final now = DateTime.now();
    bool hasChanges = false;
    List<GameEvent> eventsToRemove = [];
    final int eventCount = activeEvents.length;
    
    // Use direct index access for better performance
    for (int i = 0; i < eventCount; i++) {
      final event = activeEvents[i];
      
      // Check if event is already resolved and needs to be removed
      if (event.isResolved) {
        eventsToRemove.add(event);
        hasChanges = true;
        print('🗑️ Removing resolved event: ${event.name}');
        continue;
      }
      
      // Check if ANY event has auto-expired (all events now have auto-expiry)
      if (event.hasExpired) {
        event.resolve(); // Mark as resolved
        eventsToRemove.add(event);
        hasChanges = true;
        print('⏰ Event auto-expired: ${event.name} (${event.timeRemainingFormatted} remaining)');
        
        // Track the resolution
        this.trackEventResolution(event, "auto_expire");
        continue; // Skip further processing for expired events
      }
      
      // Legacy support: Check if time-based events have expired (for backwards compatibility)
      if (event.resolution.type == EventResolutionType.timeBased) {
        final timeLimit = event.resolution.value as int;
        final elapsed = now.difference(event.startTime).inSeconds;
        
        if (elapsed >= timeLimit) {
          event.resolve(); // Mark as resolved
          eventsToRemove.add(event);
          hasChanges = true;
          print('⏰ Time-based event expired: ${event.name}');
          
          // Track the resolution
          this.trackEventResolution(event, "time");
          continue; // Skip further processing for expired events
        }
      }
      
      // Update tap challenge timers (if they have time limits)
      if (event.resolution.type == EventResolutionType.tapChallenge) {
        final Map<String, dynamic> tapData = event.resolution.value as Map<String, dynamic>;
        // Only apply time limits if they exist in the tap data
        if (tapData.containsKey('timeLimit')) {
          final int totalTime = tapData['timeLimit'] ?? 60;
          final int elapsedSeconds = now.difference(event.startTime).inSeconds;
          final int remainingSeconds = totalTime - elapsedSeconds;
          tapData['remainingSeconds'] = remainingSeconds > 0 ? remainingSeconds : 0;
          
          // Auto-expire tap challenges that run out of time
          if (remainingSeconds <= 0 && !event.isResolved) {
            event.resolve();
            eventsToRemove.add(event);
            hasChanges = true;
            print('⏰ Tap challenge timed out: ${event.name}');
            
            // Track the resolution as timeout
            this.trackEventResolution(event, "timeout");
          }
        }
      }
    }
    
    // Remove resolved events from the active list
    if (eventsToRemove.isNotEmpty) {
      for (final eventToRemove in eventsToRemove) {
        activeEvents.remove(eventToRemove);
      }
      hasChanges = true;
      print('📊 Active events count after cleanup: ${activeEvents.length}');
    }
    
    if (hasChanges) {
      notifyListeners();
      // ADDED: Notify AdMobService of event state change for predictive ad loading
      notifyAdMobServiceOfEventStateChange();
    }
  }
  
  // Check if a business is affected by an active event
  // Optimized with early return and direct iteration
  bool hasActiveEventForBusiness(String businessId) {
    final int eventCount = activeEvents.length;
    for (int i = 0; i < eventCount; i++) {
      final event = activeEvents[i];
      if (!event.isResolved && event.affectedBusinessIds.contains(businessId)) {
        return true;
      }
    }
    return false;
  }
  
  // Check if a locale is affected by an active event
  // Optimized with early return and direct iteration
  bool hasActiveEventForLocale(String localeId) {
    final int eventCount = activeEvents.length;
    for (int i = 0; i < eventCount; i++) {
      final event = activeEvents[i];
      if (!event.isResolved && event.affectedLocaleIds.contains(localeId)) {
        return true;
      }
    }
    return false;
  }
  
  // Process all game events (called from main update loop)
  // Optimized to avoid redundant checks and improve performance
  void checkAndTriggerEvents() {
    // No need to check if not initialized
    if (!isInitialized) return;
    
    // Check if events should be unlocked (only if not already unlocked)
    if (!eventsUnlocked) {
      _checkEventUnlockConditions();
    }
    
    // Process existing events and trigger new ones if unlocked
    if (eventsUnlocked) {
      // Only update events if there are active events to process
      if (activeEvents.isNotEmpty) {
        _updateEvents();
      }
      
      // Only check for new events if we haven't reached the maximum
      if (activeEvents.length < 3) {
        _checkEventTriggers();
      }
    }
  }
  
  // Convert event data to JSON for persistence
  Map<String, dynamic> eventsToJson() {
    return {
      'activeEvents': activeEvents.map((e) => e.toJson()).toList(),
      'lastEventTime': lastEventTime?.toIso8601String(),
      'eventsUnlocked': eventsUnlocked,
      'businessesOwnedCount': businessesOwnedCount,
      'localesWithPropertiesCount': localesWithPropertiesCount,
      'recentEventTimes': recentEventTimes.map((t) => t.toIso8601String()).toList(),
      
      // Event achievement tracking data
      'totalEventsResolved': totalEventsResolved,
      'totalEventFeesPaid': totalEventFeesPaid,
      'eventsResolvedByTapping': eventsResolvedByTapping,
      'eventsResolvedByFee': eventsResolvedByFee,
      'eventFeesSpent': eventFeesSpent,
      'eventsResolvedByAd': eventsResolvedByAd,
      'eventsResolvedByFallback': eventsResolvedByFallback,
      'eventsResolvedByPP': eventsResolvedByPP,
      'ppSpentOnEventSkips': ppSpentOnEventSkips,
      'eventsResolvedByLocale': eventsResolvedByLocale,
      'lastEventResolvedTime': lastEventResolvedTime?.toIso8601String(),
      'resolvedEvents': resolvedEvents.map((e) => e.toJson()).toList(),
    };
  }
  
  // Load event data from JSON
  void eventsFromJson(Map<String, dynamic> json) {
    if (json.containsKey('activeEvents')) {
      final List<dynamic> eventsList = json['activeEvents'] as List<dynamic>;
      List<GameEvent> loadedEvents = eventsList
          .map((e) => GameEvent.fromJson(e as Map<String, dynamic>))
          .toList();
      
      // NEW LOGIC: Limit events on load to prevent overwhelming players
      // Keep only unresolved events and limit to 3 maximum
      List<GameEvent> unresolvedEvents = loadedEvents.where((event) => !event.isResolved).toList();
      
      if (unresolvedEvents.length > 3) {
        // Sort by start time (oldest first) and keep the 3 oldest events
        unresolvedEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
        unresolvedEvents = unresolvedEvents.take(3).toList();
        print("INFO: Limited loaded events to 3 (was ${loadedEvents.length})");
      }
      
      activeEvents = unresolvedEvents;
    }
    
    if (json.containsKey('lastEventTime') && json['lastEventTime'] != null) {
      lastEventTime = DateTime.parse(json['lastEventTime'] as String);
    }
    
    eventsUnlocked = json['eventsUnlocked'] as bool? ?? false;
    businessesOwnedCount = json['businessesOwnedCount'] as int? ?? 0;
    localesWithPropertiesCount = json['localesWithPropertiesCount'] as int? ?? 0;
    
    // Load recent event times
    if (json.containsKey('recentEventTimes') && json['recentEventTimes'] != null) {
      final List<dynamic> timesList = json['recentEventTimes'] as List<dynamic>;
      recentEventTimes = timesList
          .map((t) => DateTime.parse(t as String))
          .toList();
      
      // Clean up old event times (remove events older than 1 hour)
      final now = DateTime.now();
      recentEventTimes.removeWhere((time) => now.difference(time).inMinutes > 60);
    } else {
      recentEventTimes = [];
    }
    
    // Load event achievement tracking data
    totalEventsResolved = json['totalEventsResolved'] as int? ?? 0;
    totalEventFeesPaid = json['totalEventFeesPaid'] as double? ?? 0.0;
    eventsResolvedByTapping = json['eventsResolvedByTapping'] as int? ?? 0;
    eventsResolvedByFee = json['eventsResolvedByFee'] as int? ?? 0;
    eventFeesSpent = json['eventFeesSpent'] as double? ?? 0.0;
    eventsResolvedByAd = json['eventsResolvedByAd'] as int? ?? 0;
    eventsResolvedByFallback = json['eventsResolvedByFallback'] as int? ?? 0;
    eventsResolvedByPP = json['eventsResolvedByPP'] as int? ?? 0;
    ppSpentOnEventSkips = json['ppSpentOnEventSkips'] as int? ?? 0;
    
    // Load locale-specific event tracking
    if (json.containsKey('eventsResolvedByLocale') && json['eventsResolvedByLocale'] != null) {
      final localeData = json['eventsResolvedByLocale'] as Map<String, dynamic>;
      eventsResolvedByLocale = {};
      localeData.forEach((key, value) {
        eventsResolvedByLocale[key] = value as int;
      });
    }
    
    // Load last event resolved timestamp
    if (json.containsKey('lastEventResolvedTime') && json['lastEventResolvedTime'] != null) {
      lastEventResolvedTime = DateTime.parse(json['lastEventResolvedTime'] as String);
    }
    
    // Load resolved events history
    if (json.containsKey('resolvedEvents') && json['resolvedEvents'] != null) {
      final List<dynamic> eventsList = json['resolvedEvents'] as List<dynamic>;
      resolvedEvents = eventsList
          .map((e) => GameEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }
}
