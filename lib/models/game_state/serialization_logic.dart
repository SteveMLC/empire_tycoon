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
      'lifetimeTaps': lifetimeTaps,
      'gameStartTime': gameStartTime.toIso8601String(),
      'currentDay': currentDay,
      'incomeMultiplier': incomeMultiplier,
      'clickMultiplier': clickMultiplier,
      'prestigeMultiplier': prestigeMultiplier,
      'networkWorth': networkWorth,
      'reincorporationUsesAvailable': reincorporationUsesAvailable,
      'totalReincorporations': totalReincorporations, // Save total reincorporations performed
      'lastOpened': lastOpened.toIso8601String(),
      'isInitialized': isInitialized,
      'activeMarketEvents': activeMarketEvents.map((e) => e.toJson()).toList(),
      'lastEventResolvedTime': lastEventResolvedTime?.toIso8601String(),

      // Platinum Points System Data
      'platinumPoints': platinumPoints, // SAVE platinum points
      '_retroactivePPAwarded': _retroactivePPAwarded,
      'ppPurchases': ppPurchases,
      'ppOwnedItems': ppOwnedItems.toList(), // Convert Set to List for JSON
      'isGoldenCursorUnlocked': isGoldenCursorUnlocked,
      'isExecutiveThemeUnlocked': isExecutiveThemeUnlocked,
      'isPlatinumFrameUnlocked': isPlatinumFrameUnlocked,
      'isPlatinumFrameActive': isPlatinumFrameActive,

      // --- Added: Serialize offline income notification state ---
      'offlineEarningsAwarded': offlineEarningsAwarded,
      'offlineDurationForNotification': offlineDurationForNotification?.inSeconds,
      'shouldShowOfflineEarnings': shouldShowOfflineEarnings,
      // --- End Added ---

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
      'platinumFoundationsApplied': platinumFoundationsApplied,
      'platinumFacadeAppliedBusinessIds': platinumFacadeAppliedBusinessIds.toList(),
      'isPlatinumCrestUnlocked': isPlatinumCrestUnlocked,
      'platinumSpireLocaleId': platinumSpireLocaleId,
      // --- End Added ---

      // Boost Timer Data
      'boostRemainingSeconds': boostRemainingSeconds,

      'username': username,
      'userAvatar': userAvatar,

      // New Executive Stats Theme properties
      'isExecutiveStatsThemeUnlocked': isExecutiveStatsThemeUnlocked,
      'selectedStatsTheme': selectedStatsTheme,
    };

    if (clickBoostEndTime != null) {
      json['clickBoostEndTime'] = clickBoostEndTime!.toIso8601String();
    }

    // Save businesses state
    json['businesses'] = businesses.map((business) => {
      'id': business.id,
      'level': business.level,
      'unlocked': business.unlocked,
      'secondsSinceLastIncome': business.secondsSinceLastIncome,
      'isUpgrading': business.isUpgrading,
      'upgradeEndTime': business.upgradeEndTime?.toIso8601String(),
      'initialUpgradeDurationSeconds': business.initialUpgradeDurationSeconds,
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
  Future<void> fromJson(Map<String, dynamic> json) async { // <-- Mark as async
     print("🔄 GameState.fromJson starting...");
    // Reset defaults before loading to ensure clean state
    // resetToDefaults(); // NO! This clears lifetime stats. Load over existing defaults.

    money = (json['money'] as num?)?.toDouble() ?? 500.0;
    totalEarned = (json['totalEarned'] as num?)?.toDouble() ?? money;
    manualEarnings = (json['manualEarnings'] as num?)?.toDouble() ?? 0.0;
    passiveEarnings = (json['passiveEarnings'] as num?)?.toDouble() ?? 0.0;
    isPremium = json['isPremium'] ?? false;
    investmentEarnings = (json['investmentEarnings'] as num?)?.toDouble() ?? 0.0;
    investmentDividendEarnings = (json['investmentDividendEarnings'] as num?)?.toDouble() ?? 0.0;
    realEstateEarnings = (json['realEstateEarnings'] as num?)?.toDouble() ?? 0.0;
    clickValue = (json['clickValue'] as num?)?.toDouble() ?? 1.5;
    taps = json['taps'] ?? 0;
    clickLevel = json['clickLevel'] ?? 1;
    totalRealEstateUpgradesPurchased = json['totalRealEstateUpgradesPurchased'] ?? 0;
    username = json['username'];
    userAvatar = json['userAvatar'];

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

    // Load prestige/multipliers
    currentDay = json['currentDay'] ?? DateTime.now().weekday;
    incomeMultiplier = (json['incomeMultiplier'] as num?)?.toDouble() ?? 1.0;
    clickMultiplier = (json['clickMultiplier'] as num?)?.toDouble() ?? 1.0;
    prestigeMultiplier = (json['prestigeMultiplier'] as num?)?.toDouble() ?? 1.0;
    networkWorth = (json['networkWorth'] as num?)?.toDouble() ?? 0.0;
    reincorporationUsesAvailable = json['reincorporationUsesAvailable'] ?? 0;
    totalReincorporations = json['totalReincorporations'] ?? 0;
    isInitialized = json['isInitialized'] ?? false;

    // Load lastSaved timestamp (use for offline calc baseline if lastOpened is missing/invalid)
    DateTime loadedLastSaved = DateTime.now(); // Fallback
    if (json['lastSaved'] != null) {
        try {
            loadedLastSaved = DateTime.parse(json['lastSaved']);
            print("📅 Loaded lastSaved timestamp: ${loadedLastSaved.toIso8601String()}");
        } catch (e) {
            print("❌ Error parsing lastSaved timestamp: $e. Using current time as fallback.");
        }
    } else {
        print("⚠️ No lastSaved timestamp found, using current time as fallback.");
    }
    lastSaved = loadedLastSaved; // Assign after parsing

    // CRITICAL FIX: Handle lastOpened robustly for offline progress calculation
    DateTime previousOpen = loadedLastSaved; // Default to lastSaved if lastOpened is missing/invalid
    if (json['lastOpened'] != null) {
        try {
            previousOpen = DateTime.parse(json['lastOpened']);
            print("📆 Loaded lastOpened timestamp: ${previousOpen.toIso8601String()}");
            // Ensure lastOpened is not before lastSaved (can happen with clock issues)
            if (previousOpen.isBefore(loadedLastSaved)) {
                print("⚠️ lastOpened is before lastSaved. Using lastSaved for offline calculation.");
                previousOpen = loadedLastSaved;
            }
        } catch (e) {
            print("❌ Error parsing lastOpened timestamp: $e. Using lastSaved for offline calculation.");
            previousOpen = loadedLastSaved;
        }
    } else {
        print("⚠️ No lastOpened timestamp found, using lastSaved for offline calculation.");
    }

    // Calculate offline time
    DateTime now = DateTime.now();
    int secondsElapsed = 0;
    if (now.isAfter(previousOpen)) {
        secondsElapsed = now.difference(previousOpen).inSeconds;
    } else {
        print("⚠️ Current time is not after previous open time. No offline progress possible.");
    }

    // Always update lastOpened to current time *before* processing offline progress
    lastOpened = now;
    print("🔄 Updated lastOpened to: ${lastOpened.toIso8601String()}");

    // Process offline progress if significant time elapsed
    if (secondsElapsed > 10) { // Threshold to avoid processing for brief closes
      print("💰 --- Calling _processOfflineProgress --- 💰");
      print("  Pre-Offline Money: $money");
      print("  Pre-Offline incomeMultiplier: $incomeMultiplier");
      print("  Pre-Offline prestigeMultiplier: $prestigeMultiplier");
      print("  Pre-Offline isPermanentIncomeBoostActive: $isPermanentIncomeBoostActive");
      _processOfflineProgress(secondsElapsed);
      print("✅ --- Returned from _processOfflineProgress --- ✅");
      print("  Post-Offline Money: $money"); // Verify if money was updated
    } else {
       print("ℹ️ Skipping offline progress calculation (elapsed time <= 10s).");
    }

    // Load click boost state
    if (json['clickBoostEndTime'] != null) {
      try {
          clickBoostEndTime = DateTime.parse(json['clickBoostEndTime']);
          // Check if the boost is already expired
          if (now.isAfter(clickBoostEndTime!)) {
            clickMultiplier = 1.0; // Reset multiplier if expired
            clickBoostEndTime = null;
          }
      } catch(e) {
          print("❌ Error parsing clickBoostEndTime: $e");
          clickMultiplier = 1.0;
          clickBoostEndTime = null;
      }
    } else {
        clickMultiplier = 1.0; // Ensure reset if no end time saved
        clickBoostEndTime = null;
    }

    // Load businesses
    if (json['businesses'] != null && json['businesses'] is List) {
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
    platinumFoundationsApplied = Map<String, int>.from(json['platinumFoundationsApplied'] ?? {});
    platinumFacadeAppliedBusinessIds = Set<String>.from(json['platinumFacadeAppliedBusinessIds'] ?? []);
    isPlatinumCrestUnlocked = json['isPlatinumCrestUnlocked'] ?? false;
    platinumSpireLocaleId = json['platinumSpireLocaleId'];

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
    achievementManager.evaluateAchievements(this); // Evaluate achievements based on loaded state

    // Ensure timers are set up after loading
    _setupTimers();

    // --- ADDED: Load offline income notification state ---
    offlineEarningsAwarded = (json['offlineEarningsAwarded'] as num?)?.toDouble() ?? 0.0;
    int? durationSeconds = json['offlineDurationForNotification'] as int?;
    offlineDurationForNotification = durationSeconds != null ? Duration(seconds: durationSeconds) : null;
    shouldShowOfflineEarnings = json['shouldShowOfflineEarnings'] ?? false;
    // --- End ADDED ---

    // New Executive Stats Theme properties
    isExecutiveStatsThemeUnlocked = json['isExecutiveStatsThemeUnlocked'] ?? false;
    selectedStatsTheme = json['selectedStatsTheme']; // Can be null

    notifyListeners(); // Notify UI after loading is complete
    print("✅ GameState.fromJson complete.");
  }

  // Process progress while game was closed
  void _processOfflineProgress(int secondsElapsed) {
    print("--- START Offline Progress Calculation ---"); // START Logging Block
    print("Input secondsElapsed: $secondsElapsed");

    if (secondsElapsed <= 0) {
      print("Offline time <= 0 seconds. Skipping calculation.");
      print("--- END Offline Progress Calculation (Skipped) ---");
      return;
    }

    // Cap offline progress to a reasonable limit (e.g., 1 day) to prevent exploits/overload
    final int maxOfflineSeconds = 86400; // 24 hours
    int cappedSeconds = min(secondsElapsed, maxOfflineSeconds);
    print("Capped offline seconds: $cappedSeconds");

    // Declare income variables locally
    double offlineBusinessIncome = 0;
    double offlineRealEstateIncome = 0;
    double offlineDividendIncome = 0;

    // ADDED: Store the duration used for calculation
    offlineDurationForNotification = Duration(seconds: cappedSeconds);
    print("Stored offlineDurationForNotification: ${offlineDurationForNotification?.inSeconds}s");

    print("💵 Processing offline income for $cappedSeconds seconds (capped from $secondsElapsed)");
    // Removed duplicate logs from previous attempt

    // --- Get relevant persistent boost multipliers ---
    print("Multiplier Check:");
    double businessEfficiencyMultiplier = isPlatinumEfficiencyActive ? 1.05 : 1.0;
    print("  businessEfficiencyMultiplier: $businessEfficiencyMultiplier (isPlatinumEfficiencyActive: $isPlatinumEfficiencyActive)");
    double portfolioMultiplier = isPlatinumPortfolioActive ? 1.25 : 1.0;
    print("  portfolioMultiplier: $portfolioMultiplier (isPlatinumPortfolioActive: $isPlatinumPortfolioActive)");
    double permanentIncomeMultiplier = isPermanentIncomeBoostActive ? 1.05 : 1.0;
    print("  permanentIncomeMultiplier: $permanentIncomeMultiplier (isPermanentIncomeBoostActive: $isPermanentIncomeBoostActive)");
    print("  incomeMultiplier (global): $incomeMultiplier");
    print("  prestigeMultiplier (global): $prestigeMultiplier");
    // --- End Get relevant boost multipliers ---

    // Calculate offline income from businesses
    print("Business Income Calculation:");
    double totalBusinessBaseIncomePerCycle = 0;
    for (var business in businesses) {
      if (business.level > 0) {
        int cycles = cappedSeconds ~/ business.incomeInterval;
        if (cycles > 0) {
          // Get base income (includes interval factor)
          // Note: Pass isResilienceActive if needed
          double baseIncomePerCycleRaw = business.getCurrentIncome(isResilienceActive: isPlatinumResilienceActive);
          
          // Apply efficiency multiplier
          double baseIncomePerCycleWithEfficiency = baseIncomePerCycleRaw * businessEfficiencyMultiplier;
          totalBusinessBaseIncomePerCycle += baseIncomePerCycleWithEfficiency; // Sum base * efficiency for logging
          
          // Apply standard game multipliers
          double finalIncomeForBusiness = baseIncomePerCycleWithEfficiency * cycles * incomeMultiplier * prestigeMultiplier;
          
          // Apply permanent boost
          finalIncomeForBusiness *= permanentIncomeMultiplier; // Apply permanent boost BEFORE event check for consistency with live update

          // Apply Income Surge (if applicable)
          if (isIncomeSurgeActive) finalIncomeForBusiness *= 2.0;

          // Check for event AFTER all other multipliers
          bool hasEvent = hasActiveEventForBusiness(business.id); 
          if (hasEvent) {
              finalIncomeForBusiness *= GameStateEvents.NEGATIVE_EVENT_MULTIPLIER; // Apply -0.25
          }
          
          offlineBusinessIncome += finalIncomeForBusiness;
          // Update print log to show final income added
          print("  Business '${business.name}' (Lvl ${business.level}): Cycles=$cycles, RawBaseIncome=$baseIncomePerCycleRaw, BaseWithEff=$baseIncomePerCycleWithEfficiency, Event=$hasEvent -> Added $finalIncomeForBusiness");
        }
      }
    }
    print("  Total Business Base*Efficiency (sum): $totalBusinessBaseIncomePerCycle");
    print("  Subtotal Business Offline Income (after ALL boosts/penalties): $offlineBusinessIncome");

    // Calculate offline income from real estate (Process per property)
    print("Real Estate Income Calculation:");
    offlineRealEstateIncome = 0.0; // Reset before calculation
    for (var locale in realEstateLocales) {
      if (locale.unlocked) {
        bool isLocaleAffectedByEvent = hasActiveEventForLocale(locale.id);
        bool isFoundationApplied = platinumFoundationsApplied.containsKey(locale.id);
        bool isYachtDocked = platinumYachtDockedLocaleId == locale.id;
        double foundationMultiplier = isFoundationApplied ? 1.05 : 1.0;
        double yachtMultiplier = isYachtDocked ? 1.05 : 1.0;

        for (var property in locale.properties) {
          if (property.owned > 0) {
            // Get base income per property (includes owned count)
            double basePropertyIncomePerSecond = property.getTotalIncomePerSecond(isResilienceActive: isPlatinumResilienceActive);
            
            // Apply locale-specific multipliers (Foundation, Yacht)
            double incomeWithLocaleBoosts = basePropertyIncomePerSecond * foundationMultiplier * yachtMultiplier;

            // Apply standard global multipliers and duration
            double finalPropertyIncome = incomeWithLocaleBoosts * cappedSeconds * incomeMultiplier * prestigeMultiplier;

            // Apply the overall permanent boost
            finalPropertyIncome *= permanentIncomeMultiplier;
            
            // Apply Income Surge (if applicable)
            if (isIncomeSurgeActive) finalPropertyIncome *= 2.0;

            // Check for negative event affecting the LOCALE and apply multiplier AFTER all bonuses
            if (isLocaleAffectedByEvent) {
              finalPropertyIncome *= GameStateEvents.NEGATIVE_EVENT_MULTIPLIER; // Apply -0.25
            }
            
            offlineRealEstateIncome += finalPropertyIncome;
            // Optional: Add print log per property if needed for debugging
            // print("    Property '${property.name}' in '${locale.name}': Base/s=$basePropertyIncomePerSecond, Event=$isLocaleAffectedByEvent -> Added $finalPropertyIncome");
          }
        }
      }
    }
    print("  Subtotal RE Offline Income (after ALL boosts/penalties): $offlineRealEstateIncome");


    // Calculate offline income from dividends (Reverted to simpler calculation structure)
    print("Dividend Income Calculation:");
    offlineDividendIncome = 0.0; // Reset before calculation
    double diversificationBonus = calculateDiversificationBonus();
    print("  Diversification Bonus: ${diversificationBonus.toStringAsFixed(4)}");
    double totalDividendBasePerSecond = 0;
    for (var investment in investments) {
      if (investment.owned > 0 && investment.hasDividends()) {
          double baseDividendPerSecondRaw = investment.getDividendIncomePerSecond();
          
          // Apply Portfolio and Diversification bonus first
          double effectiveDividendPerShare = baseDividendPerSecondRaw * portfolioMultiplier * (1 + diversificationBonus);
          totalDividendBasePerSecond += effectiveDividendPerShare * investment.owned; // Sum base * bonuses * owned for logging
          
          // Apply standard game multipliers, duration, and owned count
          double finalIncomeForInvestment = effectiveDividendPerShare * investment.owned * cappedSeconds *
                                             incomeMultiplier * prestigeMultiplier;
          
          // Apply permanent income boost
          finalIncomeForInvestment *= permanentIncomeMultiplier;

          // Apply Income Surge (if applicable)
          if (isIncomeSurgeActive) finalIncomeForInvestment *= 2.0;

          offlineDividendIncome += finalIncomeForInvestment;
          print("  Investment '${investment.name}' (Owned ${investment.owned}): RawDiv/s=$baseDividendPerSecondRaw, EffDiv/s=$effectiveDividendPerShare -> Added $finalIncomeForInvestment");
      }
    }
     print("  Total Dividend Effective Base/s*Owned (sum): $totalDividendBasePerSecond");
     print("  Subtotal Dividend Offline Income (after ALL boosts): $offlineDividendIncome");

    // Calculate total and store for notification *before* adding to main money
    double totalOfflineEarnings = offlineBusinessIncome + offlineRealEstateIncome + offlineDividendIncome;
    print("Calculated Total Offline Earnings: \$${totalOfflineEarnings.toStringAsFixed(2)}");

    if (totalOfflineEarnings > 0) {
        offlineEarningsAwarded = totalOfflineEarnings;
        // Duration is already set above
        shouldShowOfflineEarnings = true; // ADDED: Set flag to trigger notification
        print("📬 Stored \$${offlineEarningsAwarded.toStringAsFixed(2)} and duration ${offlineDurationForNotification?.inSeconds}s in GameState for notification. Notification flag set: $shouldShowOfflineEarnings");
    } else {
        offlineEarningsAwarded = 0.0; // Ensure it's zero if no earnings
        shouldShowOfflineEarnings = false; // ADDED: Ensure flag is off if no earnings
        print("📬 No positive offline earnings, setting offlineEarningsAwarded to 0 and notification flag to false.");
    }


    // Add calculated offline income to game state totals
    print("Applying offline earnings to GameState:");
    print("  Money BEFORE: $money");
    money += totalOfflineEarnings;
    print("  Money AFTER: $money");
    print("  TotalEarned BEFORE: $totalEarned");
    totalEarned += totalOfflineEarnings;
    print("  TotalEarned AFTER: $totalEarned");
    print("  PassiveEarnings (Business) BEFORE: $passiveEarnings");
    passiveEarnings += offlineBusinessIncome; // Attribute business to passive
    print("  PassiveEarnings AFTER: $passiveEarnings");
    print("  RealEstateEarnings BEFORE: $realEstateEarnings");
    realEstateEarnings += offlineRealEstateIncome;
    print("  RealEstateEarnings AFTER: $realEstateEarnings");
    print("  InvestmentDividendEarnings BEFORE: $investmentDividendEarnings");
    investmentDividendEarnings += offlineDividendIncome;
    print("  InvestmentDividendEarnings AFTER: $investmentDividendEarnings");

    // Removed duplicate summary logs

    print("--- END Offline Progress Calculation ---"); // END Logging Block
  }

  // Helper to prune old hourly earnings (e.g., older than 7 days)
  void _pruneHourlyEarnings() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    List<String> keysToRemove = [];
    for (String key in hourlyEarnings.keys) {
      try {
        List<String> parts = key.split('-');
        if (parts.length == 4) {
          DateTime entryTime = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]), int.parse(parts[3]));
          if (entryTime.isBefore(cutoff)) {
            keysToRemove.add(key);
          }
        } else {
          keysToRemove.add(key); // Invalid key format
        }
      } catch (e) {
        keysToRemove.add(key); // Error parsing key
        print("Error pruning hourly earnings key: $key, Error: $e");
      }
    }
    if (keysToRemove.isNotEmpty) {
       print("🧹 Pruning ${keysToRemove.length} old hourly earnings entries.");
       for (String key in keysToRemove) {
         hourlyEarnings.remove(key);
       }
    }
  }

  // Helper to prune old persistent net worth history (e.g., older than 7 days)
   void _prunePersistentNetWorthHistory() {
      final cutoffMs = DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
      List<int> keysToRemove = [];
      for (int key in persistentNetWorthHistory.keys) {
        if (key < cutoffMs) {
          keysToRemove.add(key);
        }
      }
       if (keysToRemove.isNotEmpty) {
         print("🧹 Pruning ${keysToRemove.length} old persistent net worth entries.");
         for (int key in keysToRemove) {
            persistentNetWorthHistory.remove(key);
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