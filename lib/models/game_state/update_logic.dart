part of '../game_state.dart';

// Contains methods related to the game's update loop and timers
extension UpdateLogic on GameState {

  // Setup game timers
  void _setupTimers() {
    // Cancel existing timers before creating new ones to prevent duplicates
    _saveTimer?.cancel();
    _updateTimer?.cancel();
    _investmentUpdateTimer?.cancel();

    // Setup timer for auto-saving every minute
    // Note: Saving is typically triggered by GameService listening to changes
    _saveTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      // notifyListeners(); // No longer needed if GameService handles save on notify
      // print("💾 Autosave timer tick (will trigger save via listener)");
      // Explicitly trigger save or ensure listener mechanism is robust
    });

    // Setup timer for updating game state every second
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateGameState();
    });

    // Timer for updating investment prices (every 30 seconds)
    _investmentUpdateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isInitialized) {
        // _updateInvestmentPrices(); // Now called within _updateGameState for micro-updates
      }
    });
     print("⏱️ Timers setup complete.");
  }

  // Update game state every tick (second)
  void _updateGameState() {
    if (!isInitialized) return; // Don't update if not fully initialized

    try {
      DateTime now = DateTime.now();
      String hourKey = TimeUtils.getHourKey(now);

      // --- [1] Event System --- 
      checkAndTriggerEvents(); // From game_state_events.dart extension

      // --- [2] Boosters --- 
      if (clickBoostEndTime != null && now.isAfter(clickBoostEndTime!)) {
        clickMultiplier = 1.0;
        clickBoostEndTime = null;
        notifyListeners();
      }

      // --- [3] Unlocks & Checks --- 
      // Check for achievement completions
      List<Achievement> newlyCompleted = achievementManager.evaluateAchievements(this);
      if (newlyCompleted.isNotEmpty) {
        queueAchievementsForDisplay(newlyCompleted); // From achievement_logic.dart
      }
      updateReincorporationUses(); // Check if new prestige levels are available
      _updateBusinessUnlocks(); // Update based on current money
      _updateRealEstateUnlocks(); // Update based on current money

      // --- [4] Live Income Calculation & Application --- 
      double previousMoney = money;
      double totalIncomeThisTick = 0;

      // Business Income
      double businessIncomeThisTick = 0;
      for (var business in businesses) {
        if (business.level > 0) {
          // Check for events affecting this specific business
          bool hasEvent = hasActiveEventForBusiness(business.id);
          // Calculate income applying multipliers and event status
          businessIncomeThisTick += business.getCurrentIncome(affectedByEvent: hasEvent) * incomeMultiplier * prestigeMultiplier;
        }
      }
      if (businessIncomeThisTick > 0) {
        totalIncomeThisTick += businessIncomeThisTick;
        passiveEarnings += businessIncomeThisTick; // Track source
        // print("DEBUG: Business Income Tick: $businessIncomeThisTick");
      }

      // Real Estate Income
      double realEstateIncomePerSecond = getRealEstateIncomePerSecond(); // Already considers events
      double realEstateIncomeThisTick = realEstateIncomePerSecond * incomeMultiplier * prestigeMultiplier;
      if (realEstateIncomeThisTick > 0) {
        totalIncomeThisTick += realEstateIncomeThisTick;
        realEstateEarnings += realEstateIncomeThisTick; // Track source
        // print("DEBUG: RE Income Tick: $realEstateIncomeThisTick");
      }

      // Dividend Income
      double dividendIncomePerSecond = getTotalDividendIncomePerSecond(); // Base income per sec
      double diversificationBonus = calculateDiversificationBonus();
      double dividendIncomeThisTick = dividendIncomePerSecond * incomeMultiplier * prestigeMultiplier * (1 + diversificationBonus);
      if (dividendIncomeThisTick > 0) {
        totalIncomeThisTick += dividendIncomeThisTick;
        investmentDividendEarnings += dividendIncomeThisTick; // Track source
        // print("DEBUG: Dividend Income Tick: $dividendIncomeThisTick");
      }

      // Apply total income for the tick
      if (totalIncomeThisTick > 0) {
          money += totalIncomeThisTick;
          totalEarned += totalIncomeThisTick;
          // Update hourly earnings (aggregate for the hour)
          _updateHourlyEarnings(hourKey, totalIncomeThisTick);
      }

      // --- [5] Investment Micro-Updates --- 
      _updateInvestmentPricesMicro(); // More frequent small price changes for charts

      // --- [6] Daily Investment Update Check --- 
      int todayDay = now.weekday; // 1-7 (Monday-Sunday)
      if (todayDay != currentDay) {
        print("☀️ New Day detected! ($currentDay -> $todayDay)");
        currentDay = todayDay;
        _updateInvestments(); // Perform daily investment updates & market events
         _updateInvestmentPrices(); // Perform a full price update/history push on day change
      }

      // --- [7] Persistent Net Worth Tracking (Every 30 mins) --- 
      if (now.minute % 30 == 0 && now.second == 0) { // Check exactly at the start of the minute
        int timestampMs = now.millisecondsSinceEpoch;
        double currentNetWorth = calculateNetWorth();
        persistentNetWorthHistory[timestampMs] = currentNetWorth;
        print("📈 Recorded Net Worth: $currentNetWorth at $timestampMs");
        _prunePersistentNetWorthHistory(); // Prune old entries
      }

      // --- [8] Final Notification --- 
      // Notify if money actually changed during the tick
      if (money != previousMoney) {
         notifyListeners();
      }

    } catch (e, stackTrace) {
      print("❌❌❌ CRITICAL ERROR in _updateGameState: $e");
      print(stackTrace);
      // Consider adding more robust error handling, like disabling timers temporarily
    }
  }

  // -----[ STATS HELPERS ]-----

  // Helper to update daily earnings (now aggregated hourly) and prune old entries
  void _updateDailyEarnings(String dayKey, double amount) {
     // This method is deprecated in favor of _updateHourlyEarnings
     // hourlyEarnings[dayKey] = (hourlyEarnings[dayKey] ?? 0) + amount;
     // _pruneHourlyEarnings(); // Use the hourly pruning logic
  }

  // Helper function to update hourly earnings and prune old entries
  void _updateHourlyEarnings(String hourKey, double earnings) {
    hourlyEarnings[hourKey] = (hourlyEarnings[hourKey] ?? 0) + earnings;
    // Pruning is now done periodically or on load, not every update
    // _pruneHourlyEarnings(); 
  }
} 