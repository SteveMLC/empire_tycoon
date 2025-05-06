part of '../game_state.dart';

// Contains methods related to interacting with the Game Event system
extension EventLogic on GameState {

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

  // Process tap for tap challenge events
  void processTapForEvent(GameEvent event) {
    if (event.resolution.type != EventResolutionType.tapChallenge) return;

    // Get current and required taps
    Map<String, dynamic> tapData = event.resolution.value as Map<String, dynamic>; // Assume value is correct type
    int current = tapData['current'] ?? 0;
    int required = tapData['required'] ?? 0;

    // Increment taps and check if complete
    current++;
    tapData['current'] = current;

    // Increment lifetime taps to track event taps as well
    lifetimeTaps++;

    if (current >= required) {
      event.resolve();

      // Update event achievement tracking
      totalEventsResolved++;
      eventsResolvedByTapping++;
      trackEventResolution(event, "tap"); // Use the tracking method
    }

    notifyListeners();
  }

  // Track event resolution for achievement tracking
  void trackEventResolution(GameEvent event, String method) {
    // Track resolution time
    lastEventResolvedTime = DateTime.now();

    // Track resolution by locale
    for (String localeId in event.affectedLocaleIds) {
      eventsResolvedByLocale[localeId] = (eventsResolvedByLocale[localeId] ?? 0) + 1;
    }

    // Store resolved event history (ensure it's the resolved event)
    if (event.isResolved) { // Only add if actually resolved
        resolvedEvents.add(event);
        if (resolvedEvents.length > 25) { // Keep only the last 25 events
          resolvedEvents.removeAt(0);
        }
    }

    // Track stats based on resolution method
    // (These are updated directly where resolution happens now, e.g., processTapForEvent)
    // switch (method) {
    //   case "tap":
    //     eventsResolvedByTapping++;
    //     break;
    //   case "fee":
    //     eventsResolvedByFee++;
    //     // eventFeesSpent is updated directly in the UI/service layer where fee is paid
    //     break;
    //   case "ad":
    //     eventsResolvedByAd++;
    //     break;
    // }
    // totalEventsResolved++; // Also updated directly where resolution happens

    // Notify listeners of state change
    notifyListeners();
  }

   // Property for getting total income per second (used *by* the event system in game_state_events.dart)
   // This needs to stay accessible or be passed to the event system.
   // Keeping it here is simpler given the `part of` structure.
  double get totalIncomePerSecond {
    double total = 0.0;

    // Add business income (using the dedicated method)
    total += getBusinessIncomePerSecond(); // Already includes multipliers and event effects

    // Add real estate income (using the dedicated method)
    total += getRealEstateIncomePerSecond() * incomeMultiplier; // Removed prestigeMultiplier from here

    // Add dividend income from investments
    double dividendIncome = 0.0;
    double diversificationBonus = calculateDiversificationBonus();
    for (var investment in investments) {
      if (investment.owned > 0 && investment.hasDividends()) {
        dividendIncome += investment.getDividendIncomePerSecond() * investment.owned;
      }
    }
    // Apply multipliers and bonus to total dividend income
    total += dividendIncome * incomeMultiplier * (1 + diversificationBonus); // Removed prestigeMultiplier

    return total;
  }

} 