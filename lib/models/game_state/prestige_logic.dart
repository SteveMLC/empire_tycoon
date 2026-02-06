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

    // MODIFIED: Only use the NEXT level after the achieved levels
    // Instead of finding the highest applicable level, we only use the next one
    int nextLevel = achievedLevels + 1;
    if (nextLevel <= 9) { // Make sure we don't go beyond our max levels (9 total)
      double nextThreshold = baseRequirement * pow(10, nextLevel - 1);
      if (currentNetWorth >= nextThreshold) {
        currentPrestigeLevelUsed = nextLevel;
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

    // FIXED: Store actual networth at time of reincorporation instead of just threshold increment
    // Add the current networth to the lifetime accumulated networth
    lifetimeNetworkWorth += currentNetWorth;

    // Calculate the networkWorth increment for the level being used (for prestige level tracking)
    // Level 1 ($1M) adds 0.01, Level 2 ($10M) adds 0.1, Level 3 ($100M) adds 1.0, etc.
    double networkWorthIncrement = pow(10, currentPrestigeLevelUsed - 1).toDouble() / 100.0;

    // Update network worth (persistent lifetime stat for prestige level tracking)
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
      'resolvedEvents': resolvedEvents.map((e) => e.toJson()).toList(),
      'lastEventResolvedTime': lastEventResolvedTime?.toIso8601String(),
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
      // ADDED: Store current taps to preserve hustle progress
      'taps': taps,
      'clickLevel': clickLevel,
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
    // Keep clickLevel across reincorporation; use TapBoostConfig for consistency with Hustle screen
    clickValue = TapBoostConfig.getClickBaseValueForLevel(clickLevel) * prestigeMultiplier;
    // REMOVED: taps = 0; // No longer reset taps for the current click level
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
    autoClickerRemainingSeconds = 0;
    autoClickerEndTime = null;
    isIncomeSurgeActive = false;
    incomeSurgeEndTime = null;
    
    // Reset yacht docking (but keep ownership)
    platinumYachtDockedLocaleId = null;

    // Cancel any active timers
    cancelBoostTimer();
    cancelAdBoostTimer();
    _cancelPlatinumTimers();

    // Record reincorporation point as cumulative lifetime so the Lifetime chart shows total progress (no drop)
    final int preResetMs = DateTime.now().millisecondsSinceEpoch;
    persistentNetWorthHistory[preResetMs] = lifetimeNetworkWorth;

    // Reset stats tracking
    // Keep persistent net worth history so the lifetime chart shows all progress,
    // but clear the per-run history so the current run starts fresh.
    hourlyEarnings = {};
    runNetWorthHistory.clear();

    // Reset market events
    activeMarketEvents = [];

    // Reset businesses
    for (var business in businesses) {
      business.level = 0; // Reset business to starting level
      business.unlocked = false; // Default to locked
      // Reset upgrade timer state
      business.isUpgrading = false;
      business.upgradeEndTime = null;
      business.initialUpgradeDurationSeconds = null;
      // Reset branching state (allows re-selection after reincorporation)
      business.selectedBranchId = null;
      business.hasMadeBranchChoice = false;
      business.branchSelectionTime = null;
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

    // Reset run-specific challenge and timed effects (do not carry over to new run)
    activeChallenge = null;
    isDisasterShieldActive = false;
    disasterShieldEndTime = null;
    isCrisisAcceleratorActive = false;
    crisisAcceleratorEndTime = null;
    
    // We're now preserving event stats through reincorporation
    // DO NOT reset event achievement tracking fields

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
    
    // ADDED: Restore hustle taps progress
    taps = preservedState['taps'];
    clickLevel = preservedState['clickLevel'];
    
    // Restore event stats
    totalEventsResolved = preservedState['totalEventsResolved'];
    totalEventFeesPaid = preservedState['totalEventFeesPaid'];
    eventsResolvedByTapping = preservedState['eventsResolvedByTapping'];
    eventsResolvedByFee = preservedState['eventsResolvedByFee'];
    eventFeesSpent = preservedState['eventFeesSpent'];
    eventsResolvedByAd = preservedState['eventsResolvedByAd'];
    eventsResolvedByFallback = preservedState['eventsResolvedByFallback'] ?? 0;
    eventsResolvedByPP = preservedState['eventsResolvedByPP'] ?? 0;
    ppSpentOnEventSkips = preservedState['ppSpentOnEventSkips'] ?? 0;
    eventsResolvedByLocale = Map<String, int>.from(preservedState['eventsResolvedByLocale']);
    
    // Restore resolved events history
    if (preservedState['resolvedEvents'] != null) {
      final List<dynamic> eventsList = preservedState['resolvedEvents'] as List<dynamic>;
      resolvedEvents = eventsList
          .map((e) => GameEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    
    // Restore last event resolved time if available
    if (preservedState['lastEventResolvedTime'] != null) {
      lastEventResolvedTime = DateTime.parse(preservedState['lastEventResolvedTime']);
    }
    
    // Update unlocks based on new starting money and preserved state
    _updateBusinessUnlocks(); // From business_logic.dart
    _updateRealEstateUnlocks(); // From real_estate_logic.dart
    _updateInvestmentUnlocks(); // From investment_logic.dart

    // Seed run net worth history with the new run's starting net worth so the chart has one point immediately
    final int postResetMs = DateTime.now().millisecondsSinceEpoch;
    runNetWorthHistory[postResetMs] = calculateNetWorth();

    // Notify listeners that state has changed
    notifyListeners();

    print("✅ Reincorporated! Level Used: $currentPrestigeLevelUsed, New Network Worth: $networkWorth, Lifetime Network Worth: $lifetimeNetworkWorth, Prestige Multiplier: $prestigeMultiplier, Passive Bonus: $incomeMultiplier");
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

    // MODIFIED: Only allow ONE level at a time, even if net worth crosses multiple thresholds
    int newAvailableUses = 0;
    if (currentNetWorth >= getMinimumNetWorthForReincorporation()) {
      newAvailableUses = 1;
    }

    // Update the state if it changed
    if (reincorporationUsesAvailable != newAvailableUses) {
       reincorporationUsesAvailable = newAvailableUses;
       // Optional: Notify listeners only if the value changes
       // notifyListeners(); 
       // Usually called before reincorporate action, so notification might happen there
    }
  }

} 
