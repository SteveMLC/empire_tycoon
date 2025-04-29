part of '../game_state.dart';

// Contains methods related to the Prestige (Reincorporation) system
extension PrestigeLogic on GameState {

  // Reincorporate (prestige) to earn permanent multipliers
  bool reincorporate() {
    // Check if we have any available uses or meet the minimum requirement
    updateReincorporationUses(); // Ensure usesAvailable is current
    double currentNetWorth = calculateNetWorth();
    double minRequiredNetWorth = getMinimumNetWorthForReincorporation();

    // Verify player can reincorporate
    if (reincorporationUsesAvailable <= 0 && currentNetWorth < minRequiredNetWorth) {
      print("❌ Reincorporation Failed: Requirements not met (Uses: $reincorporationUsesAvailable, Net Worth: $currentNetWorth, Required: $minRequiredNetWorth)");
      return false;
    }

    // Determine which prestige level threshold is being met/used for this reincorporation
    double baseRequirement = 1000000.0; // $1 million
    int currentPrestigeLevelUsed = 0; // The level being consumed NOW
    int achievedLevels = getAchievedReincorporationLevels(); // Total levels already achieved based on networkWorth

    // Find the highest threshold met by currentNetWorth that hasn't been used yet
    for (int level = 1; level <= 9; level++) { // Check up to 100T threshold
      double threshold = baseRequirement * pow(10, level - 1);
      if (currentNetWorth >= threshold && level > achievedLevels) {
        currentPrestigeLevelUsed = level;
        // Don't break, find the highest applicable level
      }
    }

    // If using a banked use (reincorporationUsesAvailable > 0), the level used is the next available one
    if (reincorporationUsesAvailable > 0 && currentPrestigeLevelUsed == 0) {
        currentPrestigeLevelUsed = achievedLevels + 1;
    }

    // If still 0, something is wrong or the net worth didn't meet the *next* threshold
    if (currentPrestigeLevelUsed == 0) {
         print("❌ Reincorporation Failed: Could not determine prestige level to use (Achieved: $achievedLevels, Net Worth: $currentNetWorth)");
         return false;
    }

    // Calculate the networkWorth increment for the level being used
    // Level 1 ($1M) adds 0.01, Level 2 ($10M) adds 0.1, Level 3 ($100M) adds 1.0, etc.
    double networkWorthIncrement = pow(10, currentPrestigeLevelUsed - 1).toDouble() / 100.0;

    // Update network worth (persistent lifetime stat)
    networkWorth += networkWorthIncrement;

    // Recalculate total achieved levels based on the *new* networkWorth
    int totalPrestigeLevels = getAchievedReincorporationLevels();

    // Calculate new prestige multiplier (permanent click/income bonus)
    // Example: 1.1x per level (adjust as needed)
    prestigeMultiplier = 1.0 + (0.1 * totalPrestigeLevels); // 1.1x, 1.2x, 1.3x...
    // Ensure minimum bonus if needed (e.g., first level gives 1.2x)
    // if (totalPrestigeLevels == 1 && prestigeMultiplier < 1.2) {
    //    prestigeMultiplier = 1.2;
    // }

    // Update passive income multiplier (permanent bonus to passive sources)
    // Example: 1.2x compounding per level
    incomeMultiplier = pow(1.2, totalPrestigeLevels).toDouble();

    // Consume a reincorporation use if one was available
    if (reincorporationUsesAvailable > 0) {
      reincorporationUsesAvailable--;
    }

    // Increment total reincorporations counter
    totalReincorporations++;

    // --- Store Platinum and Premium Items to preserve --- 
    // Save any state that should persist through reincorporation
    Map<String, dynamic> preservedState = {
      'platinumPoints': platinumPoints,
      'ppPurchases': ppPurchases,
      'ppOwnedItems': ppOwnedItems.toList(),
      'isExecutiveStatsThemeUnlocked': isExecutiveStatsThemeUnlocked,
      'selectedStatsTheme': selectedStatsTheme,
      'isPlatinumEfficiencyActive': isPlatinumEfficiencyActive,
      'isPlatinumPortfolioActive': isPlatinumPortfolioActive,
      'isPlatinumResilienceActive': isPlatinumResilienceActive,
      'isPermanentIncomeBoostActive': isPermanentIncomeBoostActive,
      'isPermanentClickBoostActive': isPermanentClickBoostActive,
      'isPlatinumTowerUnlocked': isPlatinumTowerUnlocked,
      'isPlatinumVentureUnlocked': isPlatinumVentureUnlocked,
      'isPlatinumIslandsUnlocked': isPlatinumIslandsUnlocked,
      'isPlatinumYachtUnlocked': isPlatinumYachtUnlocked,
      'isPlatinumIslandUnlocked': isPlatinumIslandUnlocked,
      'isPlatinumStockUnlocked': isPlatinumStockUnlocked,
      'isPlatinumCrestUnlocked': isPlatinumCrestUnlocked,
      'isPlatinumFrameUnlocked': isPlatinumFrameUnlocked,
      'isPlatinumFrameActive': isPlatinumFrameActive,
      'isGoldenCursorUnlocked': isGoldenCursorUnlocked,
      'isPremium': isPremium,
      'retroactivePPAwarded': _retroactivePPAwarded,
    };

    // --- Reset Game State --- 
    double startingMoney = 500.0; // Base starting money
    money = startingMoney * prestigeMultiplier; // Start with more money based on prestige
    totalEarned = money; // Reset total earned to starting money
    manualEarnings = 0.0;
    passiveEarnings = 0.0;
    investmentEarnings = 0.0;
    investmentDividendEarnings = 0.0;
    realEstateEarnings = 0.0;

    // Click Value: Reset based on level, but apply prestige multiplier
    // Keep clickLevel across reincorporation
    double baseClickValue = 1.5;
    double levelMultiplier = 1.0 + ((clickLevel - 1) * 0.5); // Assuming 50% increase per level
    clickValue = baseClickValue * levelMultiplier * prestigeMultiplier;
    taps = 0; // Reset taps for the current click level
    // clickLevel = 1; // Keep click level

    // Note: lifetimeTaps is intentionally not reset

    // Reset time tracking
    lastSaved = DateTime.now();
    lastOpened = DateTime.now();
    currentDay = DateTime.now().weekday;

    // Reset all temporary boosts
    clickMultiplier = 1.0;
    clickBoostEndTime = null;
    boostRemainingSeconds = 0;
    adBoostRemainingSeconds = 0;
    platinumClickFrenzyRemainingSeconds = 0;
    platinumSteadyBoostRemainingSeconds = 0;
    platinumClickFrenzyEndTime = null;
    platinumSteadyBoostEndTime = null;
    isIncomeSurgeActive = false;
    incomeSurgeEndTime = null;
    
    // Reset yacht docking (but keep ownership)
    platinumYachtDockedLocaleId = null;

    // Cancel any active timers
    cancelBoostTimer();
    cancelAdBoostTimer();
    _cancelPlatinumTimers();

    // Reset stats tracking (keep persistent net worth)
    hourlyEarnings = {};

    // Reset market events
    activeMarketEvents = [];

    // Reset businesses
    for (var business in businesses) {
      business.level = 0; // Reset business to starting level
      business.unlocked = false; // Default to locked
    }
    // Re-unlock initial businesses
    businesses[0].unlocked = true; // Mobile Car Wash
    businesses[1].unlocked = true; // Pop-Up Food Stall
    businesses[2].unlocked = true; // Boutique Coffee Roaster
    
    // Reset investments to zero ownership
    for (var investment in investments) {
      investment.owned = 0; // Reset to no owned investments
    }
    
    // Reset real estate
    _resetRealEstateForReincorporation();
    
    // Re-initialize businesses and investments
    _initializeDefaultBusinesses(); // From initialization_logic.dart
    _initializeDefaultInvestments(); // From initialization_logic.dart
    
    // Reset event system state
    activeEvents = [];
    lastEventTime = null;
    eventsUnlocked = false;
    recentEventTimes = [];
    businessesOwnedCount = 0;
    localesWithPropertiesCount = 0;
    
    // Reset event achievement tracking fields
    totalEventsResolved = 0;
    eventsResolvedByTapping = 0;
    eventsResolvedByFee = 0;
    eventFeesSpent = 0.0;
    eventsResolvedByAd = 0;
    eventsResolvedByLocale = {};
    lastEventResolvedTime = null;
    resolvedEvents = [];

    // Reset achievement tracking (keep completed status)
    _pendingAchievementNotifications.clear();
    _currentAchievementNotification = null;
    _isAchievementNotificationVisible = false;
    
    // --- Restore Platinum and Premium Items ---
    // Restore persisted state
    platinumPoints = preservedState['platinumPoints'];
    ppPurchases = Map<String, int>.from(preservedState['ppPurchases']);
    ppOwnedItems = Set<String>.from(preservedState['ppOwnedItems']);
    isExecutiveStatsThemeUnlocked = preservedState['isExecutiveStatsThemeUnlocked'];
    selectedStatsTheme = preservedState['selectedStatsTheme'];
    isPlatinumEfficiencyActive = preservedState['isPlatinumEfficiencyActive'];
    isPlatinumPortfolioActive = preservedState['isPlatinumPortfolioActive'];
    isPlatinumResilienceActive = preservedState['isPlatinumResilienceActive'];
    isPermanentIncomeBoostActive = preservedState['isPermanentIncomeBoostActive'];
    isPermanentClickBoostActive = preservedState['isPermanentClickBoostActive'];
    isPlatinumTowerUnlocked = preservedState['isPlatinumTowerUnlocked']; 
    isPlatinumVentureUnlocked = preservedState['isPlatinumVentureUnlocked'];
    isPlatinumIslandsUnlocked = preservedState['isPlatinumIslandsUnlocked'];
    isPlatinumYachtUnlocked = preservedState['isPlatinumYachtUnlocked'];
    isPlatinumIslandUnlocked = preservedState['isPlatinumIslandUnlocked'];
    isPlatinumStockUnlocked = preservedState['isPlatinumStockUnlocked'];
    isPlatinumCrestUnlocked = preservedState['isPlatinumCrestUnlocked'];
    isPlatinumFrameUnlocked = preservedState['isPlatinumFrameUnlocked'];
    isPlatinumFrameActive = preservedState['isPlatinumFrameActive'];
    isGoldenCursorUnlocked = preservedState['isGoldenCursorUnlocked'];
    isPremium = preservedState['isPremium'];
    _retroactivePPAwarded = preservedState['retroactivePPAwarded'];
    
    // Update unlocks based on new starting money and preserved state
    _updateBusinessUnlocks(); // From business_logic.dart
    _updateRealEstateUnlocks(); // From real_estate_logic.dart
    _updateInvestmentUnlocks(); // From investment_logic.dart

    // Notify listeners that state has changed
    notifyListeners();

    print("✅ Reincorporated! Level Used: $currentPrestigeLevelUsed, New Network Worth: $networkWorth, Prestige Multiplier: $prestigeMultiplier, Passive Bonus: $incomeMultiplier");
    return true;
  }

  // Get the minimum net worth required for the *next* reincorporation level
  double getMinimumNetWorthForReincorporation() {
    // Calculate the next threshold level based on already achieved levels
    int achievedLevels = getAchievedReincorporationLevels();
    int nextLevel = achievedLevels + 1;

    // Calculate the net worth required for that next level
    double baseRequirement = 1000000.0; // $1 million for level 1
    double nextThreshold = baseRequirement * pow(10, nextLevel - 1);

    return nextThreshold;
  }

  // Calculate the number of achieved reincorporation levels based on persistent networkWorth
  int getAchievedReincorporationLevels() {
    int levelsAchieved = 0;
    double baseWorthPerLevel = 0.01; // Level 1 = 0.01, Level 2 = 0.1, etc.
    if (networkWorth > 0) {
      // Check thresholds: 0.01, 0.1, 1.0, 10.0, 100.0, 1k, 10k, 100k, 1M
      for (int i = 0; i < 9; i++) { // Check 9 levels (up to 100T)
        if (networkWorth >= (baseWorthPerLevel * pow(10, i))) {
          levelsAchieved++;
        } else {
          break; // Stop checking once a threshold isn't met
        }
      }
    }
    return levelsAchieved;
  }

  // Check and update available reincorporation uses based on current net worth vs achieved levels
  void updateReincorporationUses() {
    double currentNetWorth = calculateNetWorth();
    double baseRequirement = 1000000.0; // $1 million for first unlock
    int achievedLevels = getAchievedReincorporationLevels(); // Based on persistent networkWorth

    // Calculate how many thresholds the currentNetWorth crosses IN TOTAL
    int totalThresholdsCrossed = 0;
    if (currentNetWorth >= baseRequirement) {
       // Calculate how many power-of-10 thresholds ($1M, $10M, $100M...) have been crossed
       totalThresholdsCrossed = (log(currentNetWorth / baseRequirement) / log(10)).floor() + 1;
       // Clamp at a max reasonable number if necessary (e.g., 9 levels for 100T)
       totalThresholdsCrossed = min(totalThresholdsCrossed, 9);
    }

    // Available uses = Total thresholds crossed by current net worth - Levels already achieved/used
    int newAvailableUses = max(0, totalThresholdsCrossed - achievedLevels);

    // Update the state if it changed
    if (reincorporationUsesAvailable != newAvailableUses) {
       reincorporationUsesAvailable = newAvailableUses;
       // Optional: Notify listeners only if the value changes
       // notifyListeners(); 
       // Usually called before reincorporate action, so notification might happen there
    }
  }

} 