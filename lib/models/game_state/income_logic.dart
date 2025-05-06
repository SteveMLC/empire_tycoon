part of '../game_state.dart';

extension IncomeLogic on GameState {
  double _calculateIncomePerSecond() {
    return calculateTotalIncomePerSecond();
  }

  // Calculate total income per second (including all sources)
  double calculateTotalIncomePerSecond() {
    // Business income per second
    double businessIncome = 0.0;
    for (var business in businesses) {
      if (business.level > 0) {
        double cyclesPerSecond = 1 / business.incomeInterval;
        double baseIncomePerSecond = business.getCurrentIncome(isResilienceActive: isPlatinumResilienceActive) * cyclesPerSecond;
        // Apply efficiency multiplier
        double modifiedIncomePerSecond = baseIncomePerSecond * (isPlatinumEfficiencyActive ? 1.05 : 1.0);
        businessIncome += modifiedIncomePerSecond;
      }
    }
    
    // Real estate income per second
    double realEstateIncome = 0.0;
    for (var locale in realEstateLocales) {
      if (locale.unlocked) {
        bool isFoundationApplied = platinumFoundationsApplied.containsKey(locale.id);
        bool isYachtDocked = platinumYachtDockedLocaleId == locale.id;
        double foundationMultiplier = isFoundationApplied ? 1.05 : 1.0;
        double yachtMultiplier = isYachtDocked ? 1.05 : 1.0;
        
        for (var property in locale.properties) {
          if (property.owned > 0) {
            double basePerSecond = property.getTotalIncomePerSecond(isResilienceActive: isPlatinumResilienceActive);
            realEstateIncome += basePerSecond * foundationMultiplier * yachtMultiplier;
          }
        }
      }
    }
    
    // Dividend income per second
    double dividendIncome = 0.0;
    double diversificationBonus = calculateDiversificationBonus();
    double portfolioMultiplier = isPlatinumPortfolioActive ? 1.25 : 1.0;
    
    for (var investment in investments) {
      if (investment.owned > 0 && investment.hasDividends()) {
        double baseDividendPerSecond = investment.getDividendIncomePerSecond();
        double effectiveDividendPerShare = baseDividendPerSecond * portfolioMultiplier * (1 + diversificationBonus);
        dividendIncome += effectiveDividendPerShare * investment.owned;
      }
    }
    
    // Apply global multipliers
    double baseTotal = businessIncome + realEstateIncome + dividendIncome;
    double withGlobalMultipliers = baseTotal * incomeMultiplier;
    
    // Apply permanent income boost
    if (isPermanentIncomeBoostActive) {
      withGlobalMultipliers *= 1.05;
    }
    
    // Apply income surge if active
    if (isIncomeSurgeActive) {
      withGlobalMultipliers *= 2.0;
    }
    
    return withGlobalMultipliers;
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