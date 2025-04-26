part of '../game_state.dart';

// Contains utility methods and general game actions
extension UtilityLogic on GameState {

  // Helper method to format time intervals in a human-readable way
  String _formatTimeInterval(int seconds) {
    final int days = seconds ~/ 86400;
    final int hours = (seconds % 86400) ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    final int remainingSeconds = seconds % 60;

    if (days > 0) {
      return '$days day${days > 1 ? 's' : ''}, $hours hour${hours > 1 ? 's' : ''}';
    } else if (hours > 0) {
      return '$hours hour${hours > 1 ? 's' : ''}, $minutes minute${minutes > 1 ? 's' : ''}';
    } else if (minutes > 0) {
      return '$minutes minute${minutes > 1 ? 's' : ''}, $remainingSeconds second${remainingSeconds > 1 ? 's' : ''}';
    } else {
      return '$remainingSeconds second${remainingSeconds > 1 ? 's' : ''}';
    }
  }

  // Enable premium features (called when purchase is successful)
  void enablePremium() {
    print("🔵 enablePremium called. Current isPremium: $isPremium");
    if (!isPremium) {
      isPremium = true;
      print("🟢 isPremium set to true.");
      awardPlatinumPoints(1500); // Handles points, animation flag, AND notifyListeners
      showPremiumPurchaseNotification = true; // SET flag for the notification widget
      print("💎 Premium Enabled. Called awardPlatinumPoints(1500) and set showPremiumPurchaseNotification=true.");
    } else {
      print("🟡 enablePremium: Already premium.");
    }
  }

  // Method to dismiss the premium purchase notification
  void dismissPremiumPurchaseNotification() {
    if (showPremiumPurchaseNotification) {
      showPremiumPurchaseNotification = false;
      print("⚫️ Premium purchase notification dismissed.");
      notifyListeners();
    }
  }

  // Manual click to earn money
  void tap() {
    // Calculate earnings for this tap, applying relevant multipliers
    double earned = clickValue * clickMultiplier * prestigeMultiplier;
    
    money += earned;
    totalEarned += earned;
    manualEarnings += earned;
    taps++;
    lifetimeTaps++; // Increment lifetime taps count for persistent tracking

    String hourKey = TimeUtils.getHourKey(DateTime.now());
    _updateHourlyEarnings(hourKey, earned); // Track manual earnings hourly

    notifyListeners();
  }

  // Buy a click boost (e.g., 2x for 5 minutes)
  bool buyClickBoost() {
    double cost = 1000.0; // Define cost for the boost
    Duration duration = const Duration(minutes: 5);
    double multiplierAmount = 2.0;

    if (money >= cost) {
      money -= cost;
      clickMultiplier = multiplierAmount;
      clickBoostEndTime = DateTime.now().add(duration);

      print("🚀 Click Boost Purchased! ($multiplierAmount x for ${duration.inMinutes} mins)");
      notifyListeners();
      return true;
    }
    return false;
  }

  // Calculate total net worth (money + businesses + investments + real estate)
  double calculateNetWorth() {
    double businessesValue = 0;
    for (var business in businesses) {
       businessesValue += business.getCurrentValue(); // Assumes Business has this method
    }

    double investmentsValue = getTotalInvestmentValue(); // Use existing method

    double realEstateValue = 0.0;
    for (var locale in realEstateLocales) {
      realEstateValue += locale.getTotalValue(); // Use locale's method
    }

    return money + businessesValue + investmentsValue + realEstateValue;
  }

  // Calculate the total income from all sources per second, applying all multipliers
  double calculateTotalIncomePerSecond() {
    double businessInc = getBusinessIncomePerSecond(); // Already includes multipliers
    double realEstateInc = getRealEstateIncomePerSecond() * incomeMultiplier * prestigeMultiplier;
    double dividendInc = getTotalDividendIncomePerSecond(); // Base dividend income
    double diversificationBonus = calculateDiversificationBonus();
    double adjustedDividendInc = dividendInc * incomeMultiplier * prestigeMultiplier * (1 + diversificationBonus);

    return businessInc + realEstateInc + adjustedDividendInc;
  }

  // Get combined income per second from all sources with their respective multipliers applied
  Map<String, double> getCombinedIncomeBreakdown() {
    double businessIncome = getBusinessIncomePerSecond(); // Includes multipliers
    double realEstateIncome = getRealEstateIncomePerSecond() * incomeMultiplier * prestigeMultiplier;
    double dividendIncomeBase = getTotalDividendIncomePerSecond();
    double diversificationBonus = calculateDiversificationBonus();
    double investmentIncome = dividendIncomeBase * incomeMultiplier * prestigeMultiplier * (1 + diversificationBonus);

    return {
      'business': businessIncome,
      'realEstate': realEstateIncome,
      'investment': investmentIncome,
      'total': businessIncome + realEstateIncome + investmentIncome,
    };
  }

  // Function to check if each *individual* income source exceeds the given threshold
  bool hasCombinedIncomeOfAmount(double threshold) {
    Map<String, double> incomeBreakdown = getCombinedIncomeBreakdown();

    // Check if all three INDIVIDUAL income sources (after multipliers) exceed the threshold
    return incomeBreakdown['business']! >= threshold &&
           incomeBreakdown['realEstate']! >= threshold &&
           incomeBreakdown['investment']! >= threshold;
  }

  // Reset game state to default values without creating a new instance
  // Use for full game reset, not reincorporation
  void resetToDefaults() {
    print("🔄 Resetting game state to defaults...");
    
    // Save premium status and platinum points before reset
    bool premiumStatus = isPremium;
    int pPoints = platinumPoints;
    
    // Reset basic player stats
    money = 500.0;
    totalEarned = 500.0;
    manualEarnings = 0.0;
    passiveEarnings = 0.0;
    investmentEarnings = 0.0;
    investmentDividendEarnings = 0.0;
    realEstateEarnings = 0.0;
    clickValue = 1.5;
    taps = 0;
    clickLevel = 1;
    totalRealEstateUpgradesPurchased = 0;

    // Reset lifetime stats
    lifetimeTaps = 0;
    gameStartTime = DateTime.now();

    // Reset time tracking
    lastSaved = DateTime.now();
    lastOpened = DateTime.now();
    currentDay = DateTime.now().weekday;

    // Reset multipliers and boosters
    incomeMultiplier = 1.0;
    clickMultiplier = 1.0;
    clickBoostEndTime = null;

    // Reset prestige system
    prestigeMultiplier = 1.0;
    networkWorth = 0.0;
    reincorporationUsesAvailable = 0;
    totalReincorporations = 0;

    // Reset stats tracking (including persistent)
    hourlyEarnings = {};
    persistentNetWorthHistory = {};

    // Reset market events
    activeMarketEvents = [];

    // Re-initialize businesses, investments, and real estate with default values
    _initializeDefaultBusinesses();
    _initializeDefaultInvestments();
    _initializeRealEstateLocales();
    
    // CRITICAL FIX: Ensure all businesses are explicitly reset to level 0
    for (var business in businesses) {
      business.level = 0;
      business.secondsSinceLastIncome = 0;
      business.unlocked = business.id == 'mobile_car_wash' || business.id == 'food_stall' || business.id == 'coffee_roaster';
    }
    
    // CRITICAL FIX: Ensure all investments are explicitly reset to owned = 0
    for (var investment in investments) {
      investment.owned = 0;
      investment.purchasePrice = 0.0;
      investment.autoInvestEnabled = false;
      investment.autoInvestAmount = 0.0;
    }
    
    // CRITICAL FIX: Ensure all real estate properties are reset
    for (var locale in realEstateLocales) {
      // Only unlock the first locale (Rural Kenya)
      locale.unlocked = locale.id == 'rural_kenya';
      
      for (var property in locale.properties) {
        property.owned = 0;
        property.unlocked = locale.id == 'rural_kenya'; // Only unlock properties in the first locale
        
        // Reset all upgrades
        for (var upgrade in property.upgrades) {
          upgrade.purchased = false;
        }
      }
    }
    
    // Reset Achievement tracking fields
    totalUpgradeSpending = 0.0;
    luxuryUpgradeSpending = 0.0;
    fullyUpgradedPropertyIds = {};
    fullyUpgradedPropertiesPerLocale = {};
    localesWithOneFullyUpgradedProperty = {};
    fullyUpgradedLocales = {};

    // Reset Achievements (clear completion status)
    for (var achievement in achievementManager.achievements) {
      achievement.completed = false;
    }
    
    // Reset notification queue
    _pendingAchievementNotifications.clear();
    _currentAchievementNotification = null;
    _isAchievementNotificationVisible = false;

    // Reset event system state
    activeEvents = [];
    lastEventTime = null;
    eventsUnlocked = false;
    recentEventTimes = [];
    businessesOwnedCount = 0;
    localesWithPropertiesCount = 0;
    totalEventsResolved = 0;
    eventsResolvedByTapping = 0;
    eventsResolvedByFee = 0;
    eventFeesSpent = 0.0;
    eventsResolvedByAd = 0;
    eventsResolvedByLocale = {};
    lastEventResolvedTime = null;
    resolvedEvents = [];

    // Restore premium status and platinum points
    isPremium = premiumStatus;
    platinumPoints = pPoints;

    // Update unlocks based on starting money
    _updateBusinessUnlocks();
    _updateRealEstateUnlocks();

    // Notify listeners that state has changed
    notifyListeners();

    print("✅ Game state reset complete.");
  }

  // This method should not override or call super.dispose(), as it's an extension.
  // It only handles cancelling timers specific to the GameState logic.
  void dispose() {
    print("🗑️ Disposing GameState - Cancelling timers...");
    _saveTimer?.cancel();
    _updateTimer?.cancel();
    _investmentUpdateTimer?.cancel();
    // No super.dispose() call here
    print("✅ Timers cancelled.");
  }

  // ADDED: Method to clear offline notification state
  void clearOfflineNotification() {
    offlineEarningsAwarded = 0.0;
    offlineDurationForNotification = null;
    // No notifyListeners here, typically called from UI dismiss action
    // which will handle its own state update/rebuild.
    print("Cleared offline notification state.");
  }
} 