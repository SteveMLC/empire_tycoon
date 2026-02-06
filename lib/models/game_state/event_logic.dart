part of '../game_state.dart';

// Contains methods related to interacting with the Game Event system
extension EventLogic on GameState {
  // Check if a business is affected by an active event
  // Optimized business event check with direct indexing
  bool hasActiveEventForBusiness(String businessId) {
    // Use direct indexing for better performance
    final int eventCount = activeEvents.length;
    for (int i = 0; i < eventCount; i++) {
      final event = activeEvents[i];
      // Check resolution status first (faster boolean check)
      if (event.isResolved) continue;
      
      // Only check affected IDs if not resolved
      if (event.affectedBusinessIds.contains(businessId)) {
        return true;
      }
    }
    
    return false;
  }

  // Check if a locale is affected by an active event
  // Optimized locale event check with direct indexing
  bool hasActiveEventForLocale(String localeId) {
    // Use direct indexing for better performance
    final int eventCount = activeEvents.length;
    for (int i = 0; i < eventCount; i++) {
      final event = activeEvents[i];
      // Check resolution status first (faster boolean check)
      if (event.isResolved) continue;
      
      // Only check affected IDs if not resolved
      if (event.affectedLocaleIds.contains(localeId)) {
        return true;
      }
    }
    
    return false;
  }

  // Process tap for tap challenge events
  // Optimized tap processing with direct access and early returns
  void processTapForEvent(GameEvent event) {
    // Early return for non-tap events (most common case)
    if (event.resolution.type != EventResolutionType.tapChallenge) return;
    if (event.isResolved) return; // Don't process already resolved events

    try {
      // Direct access to tap data with null safety
      final Map<String, dynamic> tapData = event.resolution.value as Map<String, dynamic>;
      final int current = (tapData['current'] ?? 0) + 1; // Increment in a single operation
      final int required = tapData['required'] ?? 0;

      // Apply Platinum Resilience: Reduce required taps by 10% if active
      final double resilienceMultiplier = isPlatinumResilienceActive ? 0.9 : 1.0;
      final int finalRequired = (required * resilienceMultiplier).ceil(); // Use ceil to ensure it doesn't become 0 easily

      // Update the current tap count
      tapData['current'] = current;

      // Increment lifetime taps counter
      lifetimeTaps++;

      // Check if challenge is complete using the adjusted requirement
      final bool isComplete = current >= finalRequired;
      
      if (isComplete) {
        // Mark as resolved
        event.resolve();

        // Update achievement tracking in a single batch
        totalEventsResolved++;
        eventsResolvedByTapping++;
        
        // Track the resolution with the dedicated method
        trackEventResolution(event, "tap");
        
        print('✅ Event "${event.name}" resolved by tapping ($current/$finalRequired taps)');
      }

      // Only notify listeners once per tap
      notifyListeners();
    } catch (e) {
      print('Error in processTapForEvent: $e');
      // Don't let errors break the tap challenge - continue processing
    }
  }

  // Track event resolution for achievement tracking
  // Optimized event resolution tracking with efficient history management
  void trackEventResolution(GameEvent event, String method) {
    try {
      // Skip processing if the event isn't actually resolved
      if (!event.isResolved) return;
      
      // Track resolution time (single operation)
      lastEventResolvedTime = DateTime.now();

      // Track resolution by locale with efficient iteration
      final localeIds = event.affectedLocaleIds;
      final int localeCount = localeIds.length;
      
      for (int i = 0; i < localeCount; i++) {
        final String localeId = localeIds[i];
        eventsResolvedByLocale[localeId] = (eventsResolvedByLocale[localeId] ?? 0) + 1;
      }
      
      // Track fee paid for resolving the event (if applicable)
      if (event.resolutionFeePaid != null && event.resolutionFeePaid! > 0) {
        totalEventFeesPaid += event.resolutionFeePaid!;
        
        // If this was a fee-based resolution, update the counter
        if (event.resolution.type == EventResolutionType.feeBased) {
          eventsResolvedByFee++;
        }
      }

      // Store resolved event in history with constant-time operations
      // Add to the end (constant time operation)
      resolvedEvents.add(event);
      
      // Efficiently maintain history size limit with a single operation
      const int maxHistorySize = 25;
      if (resolvedEvents.length > maxHistorySize) {
        // Use sublist for efficient truncation (single operation)
        resolvedEvents = resolvedEvents.sublist(resolvedEvents.length - maxHistorySize);
      }

      // Notify listeners of all state changes at once
      notifyListeners();
    } catch (e) {
      print('Error in trackEventResolution: $e');
    }
  }

  // Property for getting total income per second (used *by* the event system in game_state_events.dart)
  // This needs to stay accessible or be passed to the event system.
  // Keeping it here is simpler given the `part of` structure.
  // Optimized income calculation with efficient iteration and math operations
  double get totalIncomePerSecond {
    try {
      // Initialize with business income (already optimized)
      double total = getBusinessIncomePerSecond();
      
      // Add real estate income with single multiplication
      total += getRealEstateIncomePerSecond() * incomeMultiplier;

      // Calculate dividend income with optimized iteration
      double dividendIncome = 0.0;
      final int investmentCount = investments.length;
      
      // Use direct indexing for better performance
      for (int i = 0; i < investmentCount; i++) {
        final investment = investments[i];
        final int owned = investment.owned;
        
        // Skip investments not owned or without dividends (combined check)
        if (owned <= 0 || !investment.hasDividends()) continue;
        
        double baseDiv = investment.getDividendIncomePerSecond();
        baseDiv *= PacingConfig.dividendMultiplierByMarketCap(investment.marketCap);
        dividendIncome += baseDiv;
      }
      
      // Only calculate diversification bonus if we have dividend income
      if (dividendIncome > 0) {
        // Apply multipliers and bonus in a single calculation
        final double diversificationBonus = calculateDiversificationBonus();
        total += dividendIncome * incomeMultiplier * (1 + diversificationBonus);
      }

      return total;
    } catch (e) {
      print('Error calculating totalIncomePerSecond: $e');
      return 0.0; // Return safe value on error
    }
  }
} 