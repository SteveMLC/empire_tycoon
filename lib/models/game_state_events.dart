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
  static const double EVENT_INCOME_PENALTY = -0.25; // -25% income (negative value)
  static const int EVENT_COOLDOWN_SECONDS = 900; // 15 minutes between events
  static const int EVENT_MIN_BUSINESSES = 4; // Min businesses needed to trigger events
  static const int EVENT_MIN_LOCALES = 2; // Min locales with properties needed to trigger events
  static const int EVENT_MAX_PER_HOUR = 3; // Maximum 3 events in a 60-minute window
  
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
    GameEvent newEvent = _createRandomEvent(affectedBusinessIds, affectedLocaleIds);
    
    // Add to active events
    activeEvents.add(newEvent);
    notifyListeners();
  }
  
  // Create a random event with the given affected targets
  GameEvent _createRandomEvent(List<String> businessIds, List<String> localeIds) {
    final eventTypes = EventType.values;
    final resolutionTypes = EventResolutionType.values;
    
    // Pick random type and resolution
    final eventType = eventTypes[Random().nextInt(eventTypes.length)];
    
    // Random single resolution type (one of three: tap, fee, or ad-based)
    // Note: We exclude time-based resolutions as they don't require user interaction
    final activeResolutionTypes = [
      EventResolutionType.tapChallenge,
      EventResolutionType.feeBased,
      EventResolutionType.adBased
    ];
    final resolutionType = activeResolutionTypes[Random().nextInt(activeResolutionTypes.length)];
    
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
    
    // Generate resolution details based on type
    EventResolution resolution;
    
    switch (resolutionType) {
      case EventResolutionType.timeBased:
        // Time-based: 15-minute duration (reduced from 60 minutes)
        int duration = 900; // 900 seconds (15 minutes)
        resolution = EventResolution(
          type: EventResolutionType.timeBased,
          value: duration,
        );
        break;
        
      case EventResolutionType.adBased:
        // Ad-based: Resolves when player watches an ad
        resolution = EventResolution(
          type: EventResolutionType.adBased,
          value: null,
        );
        break;
        
      case EventResolutionType.feeBased:
        // Fee-based: Costs 20-100% of current income per second
        double fee = totalIncomePerSecond * (0.2 + Random().nextDouble() * 0.8) * 60; // 20-100% of income for 1 minute
        fee = max(100, fee.roundToDouble()); // Minimum fee of $100
        
        resolution = EventResolution(
          type: EventResolutionType.feeBased,
          value: fee,
        );
        break;
        
      case EventResolutionType.tapChallenge:
        // Tap challenge: Requires 20-50 taps
        resolution = EventResolution(
          type: EventResolutionType.tapChallenge,
          value: {
            'required': 20 + Random().nextInt(31),
            'current': 0,
          },
        );
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
      resolution: resolution,
      startTime: DateTime.now(),
    );
  }
  
  // Update existing events (check for resolved events, update timers)
  void _updateEvents() {
    if (activeEvents.isEmpty) return;
    
    final now = DateTime.now();
    List<GameEvent> eventsToRemove = [];
    
    for (var event in activeEvents) {
      // Check if time-based events have expired
      if (event.resolution.type == EventResolutionType.timeBased) {
        final timeLimit = event.resolution.value as int;
        final elapsed = now.difference(event.startTime).inSeconds;
        
        if (elapsed >= timeLimit) {
          event.resolve();
          eventsToRemove.add(event);
        }
      }
      
      // Mark resolved events for removal
      if (event.isResolved) {
        eventsToRemove.add(event);
      }
    }
    
    // Remove resolved events
    if (eventsToRemove.isNotEmpty) {
      activeEvents.removeWhere((event) => eventsToRemove.contains(event));
      notifyListeners();
    }
  }
  
  // Process tap for tap challenge events
  void processTapForEvent(GameEvent event) {
    if (event.resolution.type != EventResolutionType.tapChallenge) return;
    
    // Get current and required taps
    Map<String, dynamic> tapData = event.resolution.value as Map<String, dynamic>;
    int current = tapData['current'] ?? 0;
    int required = tapData['required'] ?? 0;
    
    // Increment taps and check if complete
    current++;
    tapData['current'] = current;
    
    // Increment lifetime taps to track event taps as well
    lifetimeTaps++; 
    
    if (current >= required) {
      event.resolve();
    }
    
    notifyListeners();
  }
  
  // Check if a business is affected by an active event
  bool hasActiveEventForBusiness(String businessId) {
    for (var event in activeEvents) {
      if (!event.isResolved && event.affectedBusinessIds.contains(businessId)) {
        return true;
      }
    }
    return false;
  }
  
  // Check if a locale is affected by an active event
  bool hasActiveEventForLocale(String localeId) {
    for (var event in activeEvents) {
      if (!event.isResolved && event.affectedLocaleIds.contains(localeId)) {
        return true;
      }
    }
    return false;
  }
  
  // Process all game events (called from main update loop)
  void checkAndTriggerEvents() {
    // No need to check if not initialized
    if (!isInitialized) return;
    
    // Check if events should be unlocked
    _checkEventUnlockConditions();
    
    // Process existing events and trigger new ones if unlocked
    if (eventsUnlocked) {
      _updateEvents();      // Update existing events
      _checkEventTriggers(); // Check for new events
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
      'eventsResolvedByTapping': eventsResolvedByTapping,
      'eventsResolvedByFee': eventsResolvedByFee,
      'eventFeesSpent': eventFeesSpent,
      'eventsResolvedByAd': eventsResolvedByAd,
      'eventsResolvedByLocale': eventsResolvedByLocale,
      'lastEventResolvedTime': lastEventResolvedTime?.toIso8601String(),
      'resolvedEvents': resolvedEvents.map((e) => e.toJson()).toList(),
    };
  }
  
  // Load event data from JSON
  void eventsFromJson(Map<String, dynamic> json) {
    if (json.containsKey('activeEvents')) {
      final List<dynamic> eventsList = json['activeEvents'] as List<dynamic>;
      activeEvents = eventsList
          .map((e) => GameEvent.fromJson(e as Map<String, dynamic>))
          .toList();
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
    eventsResolvedByTapping = json['eventsResolvedByTapping'] as int? ?? 0;
    eventsResolvedByFee = json['eventsResolvedByFee'] as int? ?? 0;
    eventFeesSpent = json['eventFeesSpent'] as double? ?? 0.0;
    eventsResolvedByAd = json['eventsResolvedByAd'] as int? ?? 0;
    
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