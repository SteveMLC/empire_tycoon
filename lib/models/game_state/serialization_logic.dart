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
      'lastSaved': DateTime.now().toIso8601String(), // Save current time as last saved
      'lastOpened': DateTime.now().toIso8601String(), // Also update lastOpened on save
      'isInitialized': isInitialized,
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
    if (now.isAfter(previousOpen)) { // Only calculate if time has passed
        secondsElapsed = now.difference(previousOpen).inSeconds;
    }
    print("⏱️ Time since last opened: ${secondsElapsed} seconds");

    // Always update lastOpened to current time *before* processing offline progress
    lastOpened = now;
    print("🔄 Updated lastOpened to: ${lastOpened.toIso8601String()}");

    // Process offline progress if significant time elapsed
    if (secondsElapsed > 10) { // Threshold to avoid processing for brief closes
      print("💰 Processing offline progress for $secondsElapsed seconds...");
      _processOfflineProgress(secondsElapsed);
      print("✅ Offline progress complete.");
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

    // Ensure initialization flag is set AFTER loading and potential async ops
    isInitialized = true;

    // Re-evaluate unlocks and achievements after loading everything
    _updateBusinessUnlocks();
    _updateRealEstateUnlocks();
    achievementManager.evaluateAchievements(this); // Evaluate achievements based on loaded state

    // Ensure timers are set up after loading
    _setupTimers();

    notifyListeners(); // Notify UI after loading is complete
    print("✅ GameState.fromJson complete.");
  }

  // Process progress while game was closed
  void _processOfflineProgress(int secondsElapsed) {
    if (secondsElapsed <= 0) return;

    // Cap offline progress to a reasonable limit (e.g., 1 day) to prevent exploits/overload
    final int maxOfflineSeconds = 86400; // 24 hours
    int cappedSeconds = min(secondsElapsed, maxOfflineSeconds);

    // Declare income variables locally
    double offlineBusinessIncome = 0;
    double offlineRealEstateIncome = 0;
    double offlineDividendIncome = 0;

    print("💵 Processing offline income for $cappedSeconds seconds (capped from $secondsElapsed)");
    print("📊 Time away: ${_formatTimeInterval(secondsElapsed)}");
    print("📊 Income period: ${_formatTimeInterval(cappedSeconds)}");

    // Calculate offline income from businesses
    for (var business in businesses) {
      if (business.level > 0) {
        int cycles = cappedSeconds ~/ business.incomeInterval;
        if (cycles > 0) {
          bool hasEvent = hasActiveEventForBusiness(business.id); // Check if affected during offline period (simplification)
          double income = business.getCurrentIncome(affectedByEvent: hasEvent) * cycles * incomeMultiplier * prestigeMultiplier;
          offlineBusinessIncome += income;
        }
      }
    }

    // Calculate offline income from real estate (continuous per second)
    double realEstateIncomePerSecond = getRealEstateIncomePerSecond(); // Already considers events
    if (realEstateIncomePerSecond > 0) {
      offlineRealEstateIncome = realEstateIncomePerSecond * cappedSeconds * incomeMultiplier * prestigeMultiplier;
    }

    // Calculate offline income from dividends
    double diversificationBonus = calculateDiversificationBonus();
    for (var investment in investments) {
      if (investment.owned > 0 && investment.hasDividends()) {
          offlineDividendIncome += investment.getDividendIncomePerSecond() * investment.owned * cappedSeconds *
                                    incomeMultiplier * prestigeMultiplier * (1 + diversificationBonus);
      }
    }

    // Add calculated offline income
    double totalOfflineEarnings = offlineBusinessIncome + offlineRealEstateIncome + offlineDividendIncome;
    money += totalOfflineEarnings;
    totalEarned += totalOfflineEarnings;
    passiveEarnings += offlineBusinessIncome; // Attribute business to passive
    realEstateEarnings += offlineRealEstateIncome;
    investmentDividendEarnings += offlineDividendIncome;

     print("   Offline Business: \$${offlineBusinessIncome.toStringAsFixed(2)}");
     print("   Offline Real Estate: \$${offlineRealEstateIncome.toStringAsFixed(2)}");
     print("   Offline Dividends: \$${offlineDividendIncome.toStringAsFixed(2)}");
     print("   Total Offline Earnings: \$${totalOfflineEarnings.toStringAsFixed(2)}");

    // Note: No need to call notifyListeners here, as it's called at the end of fromJson
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

} 