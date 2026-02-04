part of '../game_state.dart';

// Contains methods related to saving and loading game state (Serialization)
extension SerializationLogic on GameState {

  // Convert game state to JSON
  Map<String, dynamic> toJson() {
    print("💾 GameState.toJson starting...");
    Map<String, dynamic> json = {
      'money': money,
      'totalEarned': totalEarned,
      'manualEarnings': manualEarnings,
      'passiveEarnings': passiveEarnings,
      'investmentEarnings': investmentEarnings,
      'investmentDividendEarnings': investmentDividendEarnings, // Added for serialization
      'realEstateEarnings': realEstateEarnings, // Added for serialization
      'clickValue': clickValue,
      'taps': taps,
      'clickLevel': clickLevel,
      'totalRealEstateUpgradesPurchased': totalRealEstateUpgradesPurchased, // Serialize this

      // >> NEW: Serialize achievement tracking fields
      'totalUpgradeSpending': totalUpgradeSpending,
      'luxuryUpgradeSpending': luxuryUpgradeSpending,
      'fullyUpgradedPropertyIds': fullyUpgradedPropertyIds.toList(), // Convert Set to List
      'fullyUpgradedPropertiesPerLocale': fullyUpgradedPropertiesPerLocale,
      'localesWithOneFullyUpgradedProperty': localesWithOneFullyUpgradedProperty.toList(), // Convert Set to List
      'fullyUpgradedLocales': fullyUpgradedLocales.toList(), // Convert Set to List
      // << END NEW

      'isPremium': isPremium,
    'hasUsedPremiumRestore': hasUsedPremiumRestore,
    'isEligibleForPremiumRestore': isEligibleForPremiumRestore,
      'lifetimeTaps': lifetimeTaps,
      'gameStartTime': gameStartTime.toIso8601String(),
      'hasShownRateUsDialog': hasShownRateUsDialog,
      'rateUsDialogShownAt': rateUsDialogShownAt?.toIso8601String(),
      'currentDay': currentDay,
      'incomeMultiplier': incomeMultiplier,
      'clickMultiplier': clickMultiplier,
      'prestigeMultiplier': prestigeMultiplier,
      'networkWorth': networkWorth,
      'lifetimeNetworkWorth': lifetimeNetworkWorth,
      'reincorporationUsesAvailable': reincorporationUsesAvailable,
      'totalReincorporations': totalReincorporations, // Save total reincorporations performed
      'maxedFoodStallBranches': maxedFoodStallBranches.toList(), // Track maxed food stall branches
      'lastOpened': lastOpened.toIso8601String(),
      'lastSaved': DateTime.now().toIso8601String(), // Save timestamp when game is saved
      'isInitialized': isInitialized,
      'activeMarketEvents': activeMarketEvents.map((e) => e.toJson()).toList(),
      'lastEventResolvedTime': lastEventResolvedTime?.toIso8601String(),

      // Platinum Points System Data
      'platinumPoints': platinumPoints, // SAVE platinum points
      '_retroactivePPAwarded': _retroactivePPAwarded,
      'ppPurchases': ppPurchases,
      'ppOwnedItems': ppOwnedItems.toList(), // Convert Set to List for JSON
      'redeemedPromoCodes': redeemedPromoCodes.toList(),
      'isGoldenCursorUnlocked': isGoldenCursorUnlocked,
      'isExecutiveThemeUnlocked': isExecutiveThemeUnlocked,
      'isPlatinumFrameUnlocked': isPlatinumFrameUnlocked,
      'isPlatinumFrameActive': isPlatinumFrameActive,

      // --- Added: Serialize persistent upgrade flags ---
      'isPlatinumEfficiencyActive': isPlatinumEfficiencyActive,
      'isPlatinumPortfolioActive': isPlatinumPortfolioActive,
      'isPlatinumResilienceActive': isPlatinumResilienceActive,
      'isPermanentIncomeBoostActive': isPermanentIncomeBoostActive,
      'isPermanentClickBoostActive': isPermanentClickBoostActive,
      // --- End Added ---

      // --- Added: Serialize unlockable flags ---
      'isPlatinumTowerUnlocked': isPlatinumTowerUnlocked,
      'isPlatinumVentureUnlocked': isPlatinumVentureUnlocked,
      'isPlatinumStockUnlocked': isPlatinumStockUnlocked,
      'isPlatinumIslandsUnlocked': isPlatinumIslandsUnlocked,
      'isPlatinumYachtUnlocked': isPlatinumYachtUnlocked,
      'isPlatinumIslandUnlocked': isPlatinumIslandUnlocked,
      // --- End Added ---

      // --- Added: Serialize Yacht Docking Location ---
      'platinumYachtDockedLocaleId': platinumYachtDockedLocaleId,
      // --- End Added ---

      // --- Added: Platinum Vault Item State (Timers, Cooldowns, etc.) ---
      'disasterShieldEndTime': disasterShieldEndTime?.toIso8601String(),
      'crisisAcceleratorEndTime': crisisAcceleratorEndTime?.toIso8601String(),
      'incomeSurgeEndTime': incomeSurgeEndTime?.toIso8601String(),
      'incomeSurgeCooldownEnd': incomeSurgeCooldownEnd?.toIso8601String(),
      'cashCacheCooldownEnd': cashCacheCooldownEnd?.toIso8601String(),
      'timeWarpUsesThisPeriod': timeWarpUsesThisPeriod,
      'lastTimeWarpReset': lastTimeWarpReset?.toIso8601String(),
      'timeWarpCooldownEnd': timeWarpCooldownEnd?.toIso8601String(),
      'platinumFoundationsApplied': platinumFoundationsApplied,
      'platinumFacadeAppliedBusinessIds': platinumFacadeAppliedBusinessIds.toList(),
      'isPlatinumCrestUnlocked': isPlatinumCrestUnlocked,
      'platinumSpireLocaleId': platinumSpireLocaleId,
      // --- End Added ---

      // --- Added: UI State Persistence ---
      'lastSelectedRealEstateLocaleId': lastSelectedRealEstateLocaleId,
      // --- End Added ---

      // Boost Timer Data
      'boostRemainingSeconds': boostRemainingSeconds,

      'username': username,
      'userAvatar': userAvatar,
      
      // Google Play Games Services properties
      'isGooglePlayConnected': isGooglePlayConnected,
      'googlePlayPlayerId': googlePlayPlayerId,
      'googlePlayDisplayName': googlePlayDisplayName,
      'googlePlayAvatarUrl': googlePlayAvatarUrl,
      'lastCloudSync': lastCloudSync?.toIso8601String(),
      'lastLoginDay': lastLoginDay?.toIso8601String(),
      'consecutiveLoginDays': consecutiveLoginDays,
      
      // ADDED: Mogul avatars fields
      'isMogulAvatarsUnlocked': isMogulAvatarsUnlocked,
      'selectedMogulAvatarId': selectedMogulAvatarId,
      
      // ADDED: Premium avatars fields
      'isPremiumAvatarsUnlocked': isPremiumAvatarsUnlocked,
      'selectedPremiumAvatarId': selectedPremiumAvatarId,

      // New Executive Stats Theme properties
      'isExecutiveStatsThemeUnlocked': isExecutiveStatsThemeUnlocked,
      'selectedStatsTheme': selectedStatsTheme,

      // Challenge system data
      'activeChallenge': activeChallenge?.toJson(),
      'platinumChallengeLastUsedTime': platinumChallengeLastUsedTime?.toIso8601String(),
      'platinumChallengeUsesToday': platinumChallengeUsesToday,
      'lastPlatinumChallengeDayTracked': lastPlatinumChallengeDayTracked?.toIso8601String(),
    };

    if (clickBoostEndTime != null) {
      json['clickBoostEndTime'] = clickBoostEndTime!.toIso8601String();
    }

    // Save businesses state (including branching data)
    json['businesses'] = businesses.map((business) => {
      'id': business.id,
      'level': business.level,
      'unlocked': business.unlocked,
      'secondsSinceLastIncome': business.secondsSinceLastIncome,
      'isUpgrading': business.isUpgrading,
      'upgradeEndTime': business.upgradeEndTime?.toIso8601String(),
      'initialUpgradeDurationSeconds': business.initialUpgradeDurationSeconds,
      // ADDED: Branching system state
      'selectedBranchId': business.selectedBranchId,
      'hasMadeBranchChoice': business.hasMadeBranchChoice,
      'branchSelectionTime': business.branchSelectionTime?.toIso8601String(),
    }).toList();

    // Save investments state
    json['investments'] = investments.map((investment) => {
      'id': investment.id,
      'owned': investment.owned,
      'purchasePrice': investment.purchasePrice,
      'currentPrice': investment.currentPrice,
      'priceHistory': investment.priceHistory,
      // Save auto-invest state
      'autoInvestEnabled': investment.autoInvestEnabled,
      'autoInvestAmount': investment.autoInvestAmount,
      // Save dynamic trend properties
      'currentTrend': investment.currentTrend,
      'trendDuration': investment.trendDuration,
    }).toList();

    // Save real estate state
    json['realEstateLocales'] = realEstateLocales.map((locale) => {
      'id': locale.id,
      'unlocked': locale.unlocked,
      'properties': locale.properties.map((property) => {
        'id': property.id,
        'owned': property.owned,
        // Save the IDs of purchased upgrades
        'purchasedUpgradeIds': property.upgrades
            .where((upgrade) => upgrade.purchased)
            .map((upgrade) => upgrade.id)
            .toList(),
      }).toList(),
    }).toList();

    // Save new stats tracking
    json['hourlyEarnings'] = hourlyEarnings;
    // Convert int keys to strings for JSON compatibility
    json['persistentNetWorthHistory'] = persistentNetWorthHistory.map(
      (key, value) => MapEntry(key.toString(), value)
    );

    // Save achievements
    json['achievements'] = achievementManager.achievements.map((achievement) => achievement.toJson()).toList();

    // Save event system data using the extension method from game_state_events.dart
    json.addAll(eventsToJson()); // This includes event tracking stats

    print("✅ GameState.toJson complete.");
    return json;
  }

  // Load game from JSON - NOW ASYNC
  // UPDATED: Added optional incomeService parameter to ensure consistent income calculation
  Future<void> fromJson(Map<String, dynamic> json, {dynamic incomeService}) async { // <-- Mark as async
     print("🔄 GameState.fromJson starting...");
    // Reset defaults before loading to ensure clean state
    // resetToDefaults(); // NO! This clears lifetime stats. Load over existing defaults.

    money = (json['money'] as num?)?.toDouble() ?? 500.0;
    totalEarned = (json['totalEarned'] as num?)?.toDouble() ?? money;
    manualEarnings = (json['manualEarnings'] as num?)?.toDouble() ?? 0.0;
    passiveEarnings = (json['passiveEarnings'] as num?)?.toDouble() ?? 0.0;
    isPremium = json['isPremium'] ?? false;
    hasUsedPremiumRestore = json['hasUsedPremiumRestore'] ?? false;
    isEligibleForPremiumRestore = json['isEligibleForPremiumRestore'] ?? false;
    investmentEarnings = (json['investmentEarnings'] as num?)?.toDouble() ?? 0.0;
    investmentDividendEarnings = (json['investmentDividendEarnings'] as num?)?.toDouble() ?? 0.0;
    realEstateEarnings = (json['realEstateEarnings'] as num?)?.toDouble() ?? 0.0;
    clickValue = (json['clickValue'] as num?)?.toDouble() ?? 1.5;
    taps = json['taps'] ?? 0;
    clickLevel = json['clickLevel'] ?? 1;
    totalRealEstateUpgradesPurchased = json['totalRealEstateUpgradesPurchased'] ?? 0;
    username = json['username'];
    userAvatar = json['userAvatar'];
    
    // Load Google Play Games Services properties
    isGooglePlayConnected = json['isGooglePlayConnected'] ?? false;
    googlePlayPlayerId = json['googlePlayPlayerId'];
    googlePlayDisplayName = json['googlePlayDisplayName'];
    googlePlayAvatarUrl = json['googlePlayAvatarUrl'];
    if (json['lastCloudSync'] != null) {
      try {
        lastCloudSync = DateTime.parse(json['lastCloudSync']);
      } catch (_) {
        lastCloudSync = null;
      }
    }
    if (json['lastLoginDay'] != null) {
      try {
        lastLoginDay = DateTime.parse(json['lastLoginDay']);
      } catch (_) {
        lastLoginDay = null;
      }
    }
    consecutiveLoginDays = json['consecutiveLoginDays'] ?? 1;
    
    // ADDED: Load mogul avatars fields
    isMogulAvatarsUnlocked = json['isMogulAvatarsUnlocked'] ?? false;
    selectedMogulAvatarId = json['selectedMogulAvatarId'];

    // ADDED: Load premium avatars fields
    isPremiumAvatarsUnlocked = json['isPremiumAvatarsUnlocked'] ?? false;
    selectedPremiumAvatarId = json['selectedPremiumAvatarId'];

    // Load achievement tracking fields
    totalUpgradeSpending = (json['totalUpgradeSpending'] as num?)?.toDouble() ?? 0.0;
    luxuryUpgradeSpending = (json['luxuryUpgradeSpending'] as num?)?.toDouble() ?? 0.0;
    fullyUpgradedPropertyIds = Set<String>.from(json['fullyUpgradedPropertyIds'] ?? []);
    fullyUpgradedPropertiesPerLocale = Map<String, int>.from(json['fullyUpgradedPropertiesPerLocale'] ?? {});
    localesWithOneFullyUpgradedProperty = Set<String>.from(json['localesWithOneFullyUpgradedProperty'] ?? []);
    fullyUpgradedLocales = Set<String>.from(json['fullyUpgradedLocales'] ?? []);

    // Load lifetime stats (or initialize if they don't exist yet)
    lifetimeTaps = json['lifetimeTaps'] ?? taps; // Use current taps if lifetimeTaps not stored yet
    if (json['gameStartTime'] != null) {
      try {
        gameStartTime = DateTime.parse(json['gameStartTime']);
      } catch (_) {
        gameStartTime = DateTime.now(); // Fallback
      }
    } else {
      gameStartTime = DateTime.now(); // Initialize if missing
    }
    hasShownRateUsDialog = json['hasShownRateUsDialog'] ?? false;
    rateUsDialogShownAt = _parseDateTimeSafe(json['rateUsDialogShownAt']);

    // Load prestige/multipliers
    currentDay = json['currentDay'] ?? DateTime.now().weekday;
    incomeMultiplier = (json['incomeMultiplier'] as num?)?.toDouble() ?? 1.0;
    clickMultiplier = (json['clickMultiplier'] as num?)?.toDouble() ?? 1.0;
    prestigeMultiplier = (json['prestigeMultiplier'] as num?)?.toDouble() ?? 1.0;
    networkWorth = (json['networkWorth'] as num?)?.toDouble() ?? 0.0;
    lifetimeNetworkWorth = (json['lifetimeNetworkWorth'] as num?)?.toDouble() ?? 0.0;
    reincorporationUsesAvailable = json['reincorporationUsesAvailable'] ?? 0;
    totalReincorporations = json['totalReincorporations'] ?? 0;
    maxedFoodStallBranches = json['maxedFoodStallBranches'] != null 
        ? Set<String>.from(json['maxedFoodStallBranches']) 
        : {};
    isInitialized = json['isInitialized'] ?? false;

    // Load lastSaved timestamp (use for offline calc baseline if lastOpened is missing/invalid)
    if (json['lastSaved'] != null) {
      try {
        lastSaved = DateTime.parse(json['lastSaved']);
      } catch (_) {
        lastSaved = DateTime.now();
      }
    } else {
      lastSaved = DateTime.now();
    }
    
    // Load lastOpened timestamp (required for offline calculation)
    if (json['lastOpened'] != null) {
      try {
        lastOpened = DateTime.parse(json['lastOpened']);
      } catch (_) {
        lastOpened = DateTime.now();
      }
    } else {
      lastOpened = DateTime.now();
    }
    
    // Calculate offline time
    DateTime now = DateTime.now();
    
    // Make sure current time is valid (after last opened - handles clock tampering or anomalies)
    if (!now.isAfter(lastOpened)) {
      print("⚠️ Current time is not after previous open time. No offline progress possible.");
      lastOpened = now; // Reset to current time to be safe
    }
    
    // Always update lastOpened to current time
    lastOpened = now;

    // Read business data
    if (json['businesses'] != null) {
      List<dynamic> businessesJson = json['businesses'];
      for (var businessJson in businessesJson) {
        if (businessJson is Map && businessJson['id'] != null) {
          String id = businessJson['id'];
          int index = businesses.indexWhere((b) => b.id == id);
          if (index != -1) {
            businesses[index].level = businessJson['level'] ?? 0;
            businesses[index].unlocked = businessJson['unlocked'] ?? (businesses[index].level > 0);
            businesses[index].secondsSinceLastIncome = businessJson['secondsSinceLastIncome'] ?? 0;
            businesses[index].isUpgrading = businessJson['isUpgrading'] ?? false;
            businesses[index].upgradeEndTime = businessJson['upgradeEndTime'] != null
                ? DateTime.tryParse(businessJson['upgradeEndTime'])
                : null;
            businesses[index].initialUpgradeDurationSeconds = businessJson['initialUpgradeDurationSeconds'];
            
            // ADDED: Load branching system state
            businesses[index].selectedBranchId = businessJson['selectedBranchId'];
            businesses[index].hasMadeBranchChoice = businessJson['hasMadeBranchChoice'] ?? false;
            businesses[index].branchSelectionTime = businessJson['branchSelectionTime'] != null
                ? DateTime.tryParse(businessJson['branchSelectionTime'])
                : null;
            
            // MIGRATION: For existing saves where food_stall is past level 3 but has no branch selected,
            // auto-assign the Burger Bar path as the safe default (matches original progression)
            if (id == 'food_stall' && 
                !json.containsKey('maxedFoodStallBranches') &&
                businesses[index].level >= 3 && 
                businesses[index].hasBranching &&
                !businesses[index].hasMadeBranchChoice) {
              print("🔄 Migration: Auto-assigning Burger Bar branch to existing food_stall at level ${businesses[index].level}");
              businesses[index].selectedBranchId = 'burger_bar';
              businesses[index].hasMadeBranchChoice = true;
              businesses[index].branchSelectionTime = DateTime.now();
            }

            // CRITICAL FIX: If loading reveals an upgrade ended while offline, complete it immediately
            if (businesses[index].isUpgrading && businesses[index].upgradeEndTime != null && businesses[index].upgradeEndTime!.isBefore(now)) {
               print("🔧 Completing offline upgrade for ${businesses[index].name}...");
               businesses[index].completeUpgrade(); // Use the model's method
               // Note: Unlocks based on the new level will be handled later by _updateBusinessUnlocks
            }
          }
        }
      }
    }

    // Load investments
    if (json['investments'] != null && json['investments'] is List) {
      List<dynamic> investmentsJson = json['investments'];
      for (var investmentJson in investmentsJson) {
        if (investmentJson is Map && investmentJson['id'] != null) {
          String id = investmentJson['id'];
          int index = investments.indexWhere((i) => i.id == id);
          if (index != -1) {
            investments[index].owned = investmentJson['owned'] ?? 0;
            investments[index].currentPrice = (investmentJson['currentPrice'] as num?)?.toDouble() ?? investments[index].basePrice;
            investments[index].purchasePrice = (investmentJson['purchasePrice'] as num?)?.toDouble() ?? 0.0; // Default to 0 if missing

             // Load auto-invest state
             investments[index].autoInvestEnabled = investmentJson['autoInvestEnabled'] ?? false;
             investments[index].autoInvestAmount = (investmentJson['autoInvestAmount'] as num?)?.toDouble() ?? 0.0;

            // Load dynamic trend properties if available, otherwise use defaults
            if (investmentJson.containsKey('currentTrend')) {
              investments[index].currentTrend = (investmentJson['currentTrend'] as num?)?.toDouble() ?? investments[index].trend;
            }
            if (investmentJson.containsKey('trendDuration')) {
              investments[index].trendDuration = investmentJson['trendDuration'] ?? 0;
            }
            
            // Initialize target price if not set during deserialization
            investments[index].setTargetPrice(investments[index].basePrice);

            // Load price history safely
            if (investmentJson['priceHistory'] != null && investmentJson['priceHistory'] is List) {
              try {
                List<dynamic> history = investmentJson['priceHistory'];
                investments[index].priceHistory = history
                    .map((e) => (e is num) ? e.toDouble() : investments[index].basePrice)
                    .toList();
                 // Ensure history has correct length
                 while (investments[index].priceHistory.length < 30) {
                    investments[index].priceHistory.insert(0, investments[index].basePrice);
                 }
                 while (investments[index].priceHistory.length > 30) {
                    investments[index].priceHistory.removeAt(0);
                 }
              } catch (e) {
                print('Error parsing price history for $id: $e. Resetting.');
                investments[index].priceHistory = List.generate(30, (_) => investments[index].basePrice);
              }
            } else {
                 investments[index].priceHistory = List.generate(30, (_) => investments[index].basePrice);
            }
          }
        }
      }
    }

    // Ensure real estate upgrades are loaded before applying saved state
    if (realEstateInitializationFuture != null) {
      print("⏳ Waiting for real estate initialization before loading saved state...");
      await realEstateInitializationFuture;
      print("✅ Real estate initialization complete. Proceeding with loading saved state.");
    }

    // Load real estate
    if (json['realEstateLocales'] != null && json['realEstateLocales'] is List) {
      List<dynamic> realEstateJson = json['realEstateLocales'];
      for (var localeJson in realEstateJson) {
        if (localeJson is Map && localeJson['id'] != null) {
          String id = localeJson['id'];
          int localeIndex = realEstateLocales.indexWhere((locale) => locale.id == id);
          if (localeIndex != -1) {
            realEstateLocales[localeIndex].unlocked = localeJson['unlocked'] ?? false;
            if (localeJson['properties'] != null && localeJson['properties'] is List) {
              List<dynamic> propertiesJson = localeJson['properties'];
              for (var propertyJson in propertiesJson) {
                if (propertyJson is Map && propertyJson['id'] != null) {
                  String propertyId = propertyJson['id'];
                  int propertyIndex = realEstateLocales[localeIndex].properties.indexWhere((p) => p.id == propertyId);
                  if (propertyIndex != -1) {
                    final property = realEstateLocales[localeIndex].properties[propertyIndex];
                    property.owned = propertyJson['owned'] ?? 0;
                    if (propertyJson['purchasedUpgradeIds'] != null && propertyJson['purchasedUpgradeIds'] is List) {
                      List<String> purchasedIds = List<String>.from(propertyJson['purchasedUpgradeIds']);
                      int appliedCount = 0;
                       // Mark all current upgrades as not purchased first
                       for (var upgrade in property.upgrades) {
                          upgrade.purchased = false;
                       }
                       // Then mark the loaded ones as purchased
                      for (var upgrade in property.upgrades) {
                        if (purchasedIds.contains(upgrade.id)) {
                           upgrade.purchased = true;
                           appliedCount++;
                        }
                      }
                      // print("🔧 Applied purchased status to $appliedCount/${property.upgrades.length} upgrades for ${property.name}.");
                    } else {
                       // Ensure all current upgrades are marked not purchased if save data is missing
                       for (var upgrade in property.upgrades) {
                         upgrade.purchased = false;
                       }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    // Load stats
    if (json['hourlyEarnings'] != null && json['hourlyEarnings'] is Map) {
      try {
        hourlyEarnings = Map<String, double>.from(
          (json['hourlyEarnings'] as Map).map(
            (key, value) => MapEntry(key.toString(), (value as num).toDouble())
          )
        );
         // Prune old hourly earnings after loading
         _pruneHourlyEarnings();
      } catch (e) {
        print("Error loading hourlyEarnings: $e. Resetting.");
        hourlyEarnings = {};
      }
    } else {
      hourlyEarnings = {}; // Initialize if not found
    }

    if (json['persistentNetWorthHistory'] != null && json['persistentNetWorthHistory'] is Map) {
      try {
        persistentNetWorthHistory = Map<int, double>.from(
          (json['persistentNetWorthHistory'] as Map).map(
            (key, value) => MapEntry(int.parse(key.toString()), (value as num).toDouble())
          )
        );
         // Prune old net worth history after loading
         _prunePersistentNetWorthHistory();
      } catch (e) {
        print("Error loading persistentNetWorthHistory: $e. Resetting.");
        persistentNetWorthHistory = {};
      }
    } else {
      persistentNetWorthHistory = {}; // Initialize if not found
    }

    // Initialize/Load achievements
    achievementManager = AchievementManager(this); // Re-initialize with current state
    if (json['achievements'] != null && json['achievements'] is List) {
      List<dynamic> achievementsJson = json['achievements'];
      for (var achievementJson in achievementsJson) {
         if (achievementJson is Map && achievementJson['id'] != null) {
             String id = achievementJson['id'];
             bool completed = achievementJson['completed'] ?? false;
             int index = achievementManager.achievements.indexWhere((a) => a.id == id);
             if (index != -1) {
                // Only set completed status, progress is recalculated
                achievementManager.achievements[index].completed = completed;
             }
         }
      }
    }

    // Load event system data using the extension method from game_state_events.dart
    eventsFromJson(json);
    // Ensure event tracking stats are correctly typed
    totalEventsResolved = json['totalEventsResolved'] ?? 0;
    eventsResolvedByTapping = json['eventsResolvedByTapping'] ?? 0;
    eventsResolvedByFee = json['eventsResolvedByFee'] ?? 0;
    eventFeesSpent = (json['eventFeesSpent'] as num?)?.toDouble() ?? 0.0;
    eventsResolvedByAd = json['eventsResolvedByAd'] ?? 0;
    eventsResolvedByFallback = json['eventsResolvedByFallback'] ?? 0;
    eventsResolvedByLocale = Map<String, int>.from(json['eventsResolvedByLocale'] ?? {});
    if (json['lastEventResolvedTime'] != null) {
        try { lastEventResolvedTime = DateTime.parse(json['lastEventResolvedTime']); } catch (_) {}
    }
    // Note: ResolvedEvents list is handled within eventsFromJson

    // Load active/resolved events using the dedicated method
    eventsFromJson(json);

    // Load platinum points system data
    platinumPoints = json['platinumPoints'] ?? 0; // LOAD platinum points, default to 0
    _retroactivePPAwarded = json['_retroactivePPAwarded'] ?? false;
    ppPurchases = Map<String, int>.from(json['ppPurchases'] ?? {});
    ppOwnedItems = Set<String>.from(json['ppOwnedItems'] ?? []); // Load Set from List
    redeemedPromoCodes = Set<String>.from(json['redeemedPromoCodes'] ?? []);
    isGoldenCursorUnlocked = json['isGoldenCursorUnlocked'] ?? false;
    isExecutiveThemeUnlocked = json['isExecutiveThemeUnlocked'] ?? false;
    isPlatinumFrameUnlocked = json['isPlatinumFrameUnlocked'] ?? false;
    isPlatinumFrameActive = json['isPlatinumFrameActive'] ?? false;

    // Load persistent upgrade flags
    isPlatinumEfficiencyActive = json['isPlatinumEfficiencyActive'] ?? false;
    isPlatinumPortfolioActive = json['isPlatinumPortfolioActive'] ?? false;
    isPlatinumResilienceActive = json['isPlatinumResilienceActive'] ?? false;
    isPermanentIncomeBoostActive = json['isPermanentIncomeBoostActive'] ?? false;
    isPermanentClickBoostActive = json['isPermanentClickBoostActive'] ?? false;

    // Load unlockable flags
    isPlatinumTowerUnlocked = json['isPlatinumTowerUnlocked'] ?? false;
    isPlatinumVentureUnlocked = json['isPlatinumVentureUnlocked'] ?? false;
    isPlatinumStockUnlocked = json['isPlatinumStockUnlocked'] ?? false;
    isPlatinumIslandsUnlocked = json['isPlatinumIslandsUnlocked'] ?? false;
    isPlatinumYachtUnlocked = json['isPlatinumYachtUnlocked'] ?? false;
    isPlatinumIslandUnlocked = json['isPlatinumIslandUnlocked'] ?? false;

    // Load Yacht Docking Location
    platinumYachtDockedLocaleId = json['platinumYachtDockedLocaleId'];

    // --- Added: Load Platinum Vault Item State (Timers, Cooldowns, etc.) ---
    disasterShieldEndTime = _parseDateTimeSafe(json['disasterShieldEndTime']);
    crisisAcceleratorEndTime = _parseDateTimeSafe(json['crisisAcceleratorEndTime']);
    incomeSurgeEndTime = _parseDateTimeSafe(json['incomeSurgeEndTime']);
    incomeSurgeCooldownEnd = _parseDateTimeSafe(json['incomeSurgeCooldownEnd']);
    cashCacheCooldownEnd = _parseDateTimeSafe(json['cashCacheCooldownEnd']);
    timeWarpUsesThisPeriod = json['timeWarpUsesThisPeriod'] ?? 0;
    lastTimeWarpReset = _parseDateTimeSafe(json['lastTimeWarpReset']);
    timeWarpCooldownEnd = _parseDateTimeSafe(json['timeWarpCooldownEnd']);
    platinumFoundationsApplied = Map<String, int>.from(json['platinumFoundationsApplied'] ?? {});
    platinumFacadeAppliedBusinessIds = Set<String>.from(json['platinumFacadeAppliedBusinessIds'] ?? []);
    isPlatinumCrestUnlocked = json['isPlatinumCrestUnlocked'] ?? false;
    platinumSpireLocaleId = json['platinumSpireLocaleId'];

    // --- Added: Load UI State Persistence ---
    lastSelectedRealEstateLocaleId = json['lastSelectedRealEstateLocaleId'];
    // --- End Added ---

    // Recalculate active flags based on loaded end times
    isDisasterShieldActive = disasterShieldEndTime != null && disasterShieldEndTime!.isAfter(DateTime.now());
    isCrisisAcceleratorActive = crisisAcceleratorEndTime != null && crisisAcceleratorEndTime!.isAfter(DateTime.now());
    isIncomeSurgeActive = incomeSurgeEndTime != null && incomeSurgeEndTime!.isAfter(DateTime.now());
    // --- End Added ---

    // Load boost timer data
    boostRemainingSeconds = json['boostRemainingSeconds'] ?? 0;

    // --- Added: Re-apply unlocks based on loaded flags ---
    if (isPlatinumStockUnlocked) {
      _addPlatinumStockInvestment(); // Ensure stock exists if unlocked
    }
    // Business/Real Estate unlocks are handled by the update calls below
    // --- End Added ---

    // Re-evaluate unlocks and achievements after loading everything
    _updateBusinessUnlocks();
    _updateRealEstateUnlocks();
    _updateLoginStreak(DateTime.now());
    achievementManager.evaluateAchievements(this); // Evaluate achievements based on loaded state

    // Timers are managed by TimerService; no setup here.

    // New Executive Stats Theme properties
    isExecutiveStatsThemeUnlocked = json['isExecutiveStatsThemeUnlocked'] ?? false;
    selectedStatsTheme = json['selectedStatsTheme']; // Can be null

    // Load platinum facade data
    if (json['platinumFacadeAppliedBusinessIds'] != null) {
      platinumFacadeAppliedBusinessIds = (json['platinumFacadeAppliedBusinessIds'] as List)
          .map((e) => e as String)
          .toSet();
      
      // Also make sure to apply to the actual business objects
      for (final businessId in platinumFacadeAppliedBusinessIds) {
        final businessIndex = businesses.indexWhere((b) => b.id == businessId);
        if (businessIndex >= 0) {
          businesses[businessIndex].hasPlatinumFacade = true;
        }
      }
    }

    // --- Added: Load challenge system data ---
    if (json['activeChallenge'] != null) {
      activeChallenge = Challenge.fromJson(json['activeChallenge']);
    }
    platinumChallengeLastUsedTime = _parseDateTimeSafe(json['platinumChallengeLastUsedTime']);
    platinumChallengeUsesToday = json['platinumChallengeUsesToday'] ?? 0;
    lastPlatinumChallengeDayTracked = _parseDateTimeSafe(json['lastPlatinumChallengeDayTracked']);
    // --- End Added ---

    // Calculate and apply offline income since last save
    if (lastSaved != null) { // Check if lastSaved was loaded successfully
      // UPDATED: Pass the IncomeService to ensure consistent income calculation
      processOfflineIncome(lastSaved, incomeService: incomeService);
    } else {
      print("⚠️ Skipping offline income processing: lastSaved time not available.");
    }

    notifyListeners(); // Notify UI after loading is complete
    print("✅ GameState.fromJson complete.");
  }

  // Helper to prune old hourly earnings (e.g., older than 7 days)
  // Optimized pruning for hourly earnings with fixed-size limit
  void _pruneHourlyEarnings() {
    // If we're under the limit, no need to prune
    if (hourlyEarnings.length <= UpdateLogic._maxHistoryEntries) {
      return;
    }
    
    // Two-step approach: First remove old entries (time-based), then if still over limit, remove oldest entries
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final List<String> keysToRemove = [];
    final List<MapEntry<String, DateTime>> validEntries = [];
    
    // Step 1: Identify old entries and collect valid entries with their timestamps
    for (final String key in hourlyEarnings.keys) {
      try {
        final List<String> parts = key.split('-');
        if (parts.length == 4) {
          final DateTime entryTime = DateTime(
            int.parse(parts[0]), 
            int.parse(parts[1]), 
            int.parse(parts[2]), 
            int.parse(parts[3])
          );
          
          if (entryTime.isBefore(cutoff)) {
            keysToRemove.add(key); // Old entry, mark for removal
          } else {
            validEntries.add(MapEntry(key, entryTime)); // Valid entry, keep track with timestamp
          }
        } else {
          keysToRemove.add(key); // Invalid key format
        }
      } catch (e) {
        keysToRemove.add(key); // Error parsing key
        print("Error pruning hourly earnings key: $key, Error: $e");
      }
    }
    
    // Remove old entries
    for (final String key in keysToRemove) {
      hourlyEarnings.remove(key);
    }
    
    // Step 2: If still over limit, sort valid entries by time and remove oldest ones
    if (hourlyEarnings.length > UpdateLogic._maxHistoryEntries) {
      // Sort by time (oldest first)
      validEntries.sort((a, b) => a.value.compareTo(b.value));
      
      // Calculate how many to remove
      final int excessEntries = hourlyEarnings.length - UpdateLogic._maxHistoryEntries;
      
      // Remove oldest entries up to the limit
      for (int i = 0; i < excessEntries && i < validEntries.length; i++) {
        hourlyEarnings.remove(validEntries[i].key);
      }
    }
  }

  // Helper to prune old persistent net worth history (e.g., older than 7 days)
  // Optimized pruning for net worth history with fixed-size limit
  void _prunePersistentNetWorthHistory() {
    // If we're under the limit, no need for aggressive pruning
    if (persistentNetWorthHistory.length <= UpdateLogic._maxHistoryEntries) {
      // Just do basic time-based pruning
      final cutoffMs = DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
      persistentNetWorthHistory.removeWhere((key, _) => key < cutoffMs);
      return;
    }
    
    // Two-step approach: First remove old entries, then if still over limit, remove with sampling
    final cutoffMs = DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
    
    // Step 1: Remove entries older than cutoff
    persistentNetWorthHistory.removeWhere((key, _) => key < cutoffMs);
    
    // Step 2: If still over limit, use intelligent sampling to keep a representative dataset
    if (persistentNetWorthHistory.length > UpdateLogic._maxHistoryEntries) {
      // Sort keys by timestamp (oldest first)
      final List<int> sortedKeys = persistentNetWorthHistory.keys.toList()
        ..sort();
      
      // Calculate how many entries to keep
      final int entriesToKeep = UpdateLogic._maxHistoryEntries;
      
      // If we have more entries than we want to keep
      if (sortedKeys.length > entriesToKeep) {
        // Create a new map with sampled entries
        final Map<int, double> sampledHistory = {};
        
        // Always keep newest and oldest entries
        sampledHistory[sortedKeys.first] = persistentNetWorthHistory[sortedKeys.first]!;
        sampledHistory[sortedKeys.last] = persistentNetWorthHistory[sortedKeys.last]!;
        
        // Sample the rest with even distribution
        final int step = (sortedKeys.length - 2) ~/ (entriesToKeep - 2);
        for (int i = 1; i < entriesToKeep - 1; i++) {
          final int index = 1 + (i * step);
          if (index < sortedKeys.length - 1) {
            sampledHistory[sortedKeys[index]] = persistentNetWorthHistory[sortedKeys[index]]!;
          }
        }
        
        // Replace the original map with our sampled version
        persistentNetWorthHistory.clear();
        persistentNetWorthHistory.addAll(sampledHistory);
      }
    }
  }

  // Helper function to safely parse DateTime strings
  DateTime? _parseDateTimeSafe(String? dateString) {
    if (dateString == null) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      print("Error parsing DateTime string '$dateString': $e");
      return null;
    }
  }

} 
