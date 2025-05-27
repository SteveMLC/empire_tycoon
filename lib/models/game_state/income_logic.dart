part of '../game_state.dart';

extension IncomeLogic on GameState {
  double _calculateIncomePerSecond() {
    return calculateTotalIncomePerSecond();
  }

  // Calculate total income per second (including all sources)
  double calculateTotalIncomePerSecond() {
    // CRITICAL FIX: Use the fixed income calculation methods that properly account for events
    
    // Business income per second - use the fixed method that accounts for events
    double businessIncome = getBusinessIncomePerSecond();
    
    // Real estate income per second - use the fixed method that accounts for events
    double realEstateIncome = getRealEstateIncomePerSecond();
    
    // Dividend income per second - use the fixed method that accounts for all multipliers
    double dividendIncome = getDividendIncomePerSecond();
    
    // Sum up all income sources (multipliers already applied in each method)
    double totalIncome = businessIncome + realEstateIncome + dividendIncome;
    
    return totalIncome;
  }

  // Handle player tapping to earn money
  void tap() {
    // Calculate base earnings including permanent boost
    double permanentClickMultiplier = isPermanentClickBoostActive ? 1.1 : 1.0;
    double baseEarnings = clickValue * permanentClickMultiplier; // Base * Permanent Vault Boost

    // Apply Ad boost multiplier
    double adBoostMultiplier = isAdBoostActive ? 10.0 : 1.0;

    // Apply Platinum Boosters multiplier
    double platinumBoostMultiplier = 1.0;
    if (platinumClickFrenzyRemainingSeconds > 0) {
        platinumBoostMultiplier = 10.0;
    } else if (platinumSteadyBoostRemainingSeconds > 0) {
        platinumBoostMultiplier = 2.0;
    }

    // Combine all multipliers: Base * Prestige * Ad * Platinum
    double finalEarnings = baseEarnings * clickMultiplier * adBoostMultiplier * platinumBoostMultiplier;

    print("~~~ GameState.tap() called. BaseClick: $clickValue, PermVaultMult: ${permanentClickMultiplier.toStringAsFixed(1)}x, PrestigeMult: ${clickMultiplier.toStringAsFixed(1)}x, AdBoostMult: ${adBoostMultiplier.toStringAsFixed(1)}x, PlatinumBoostMult: ${platinumBoostMultiplier.toStringAsFixed(1)}x, Final: $finalEarnings ~~~ "); // Updated DEBUG LOG

    money += finalEarnings;
    totalEarned += finalEarnings;
    manualEarnings += finalEarnings;
    taps++;
    lifetimeTaps++;

    notifyListeners();
  }

  // Helper method to update hourly earnings - use the updated method in update_logic.dart
  void _updateHourlyEarnings(String hourKey, double amount) {
    // Forward to the main implementation in update_logic.dart
    updateHourlyEarnings(hourKey, amount);
  }
} 