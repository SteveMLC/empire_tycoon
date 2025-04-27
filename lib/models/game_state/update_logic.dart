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
      bool stateChanged = false; // Track if notifyListeners is needed

      // --- [0] Check/Reset Timed Effects & Limits First --- 
      // Income Surge
      if (isIncomeSurgeActive && incomeSurgeEndTime != null && now.isAfter(incomeSurgeEndTime!)) {
        print("INFO: Income Surge expired.");
        isIncomeSurgeActive = false;
        incomeSurgeEndTime = null;
        stateChanged = true;
      }
      // Disaster Shield
      if (isDisasterShieldActive && disasterShieldEndTime != null && now.isAfter(disasterShieldEndTime!)) {
        print("INFO: Disaster Shield expired.");
        isDisasterShieldActive = false;
        disasterShieldEndTime = null;
        stateChanged = true;
      }
       // Crisis Accelerator
      if (isCrisisAcceleratorActive && crisisAcceleratorEndTime != null && now.isAfter(crisisAcceleratorEndTime!)) {
        print("INFO: Crisis Accelerator expired.");
        isCrisisAcceleratorActive = false;
        crisisAcceleratorEndTime = null;
        stateChanged = true;
      }
      // Time Warp Weekly Reset
      _checkAndResetTimeWarpLimit(now); // Check/handle weekly reset (may update state internally)

      // --- [1] Event System --- 
      checkAndTriggerEvents(); // From game_state_events.dart extension

      // --- ADDED [1.5]: Check for Completed Business Upgrades ---
      for (var business in List.from(businesses)) { // Iterate over a copy in case list changes
          if (business.isUpgrading && business.upgradeEndTime != null && now.isAfter(business.upgradeEndTime!)) {
              print("⏲️ Detected completed upgrade for ${business.name} in update loop.");
              completeBusinessUpgrade(business.id); // This will handle logic and notifyListeners
              stateChanged = true; // Ensure notifyListeners is called if not already handled
          }
      }
      // --- END ADDED [1.5] ---

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
      // Define multipliers used across income sources
      double businessEfficiencyMultiplier = isPlatinumEfficiencyActive ? 1.05 : 1.0;
      double permanentIncomeBoostMultiplier = isPermanentIncomeBoostActive ? 1.05 : 1.0;
      
      for (var business in businesses) {
        if (business.level > 0) {
          business.secondsSinceLastIncome++;
          if (business.secondsSinceLastIncome >= business.incomeInterval) {
            // Get base income (already includes interval factor)
            // Note: isResilienceActive might be needed if other effects use it
            double baseIncome = business.getCurrentIncome(isResilienceActive: isPlatinumResilienceActive); 
            
            // Apply Platinum Efficiency first
            double incomeWithEfficiency = baseIncome * businessEfficiencyMultiplier;

            // Apply standard multipliers
            double finalIncome = incomeWithEfficiency * incomeMultiplier * prestigeMultiplier;
            
            // Apply the overall permanent boost
            finalIncome *= permanentIncomeBoostMultiplier;

            // Apply Income Surge (if applicable)
            if (isIncomeSurgeActive) finalIncome *= 2.0;

            // Check for negative event and apply multiplier AFTER all bonuses
            bool hasEvent = hasActiveEventForBusiness(business.id);
            if (hasEvent) {
              finalIncome *= GameStateEvents.NEGATIVE_EVENT_MULTIPLIER; // Apply -0.25
            }
            
            businessIncomeThisTick += finalIncome;
            business.secondsSinceLastIncome = 0;
          }
        }
      }
      // Add business income to total (can be negative now)
      totalIncomeThisTick += businessIncomeThisTick;
      passiveEarnings += businessIncomeThisTick; // Track net passive earnings

      // Real Estate Income (Process per property for event checks)
      double realEstateIncomeThisTick = 0.0;
      for (var locale in realEstateLocales) {
        if (locale.unlocked) {
          bool isLocaleAffectedByEvent = hasActiveEventForLocale(locale.id);
          bool isFoundationApplied = platinumFoundationsApplied.containsKey(locale.id);
          bool isYachtDocked = platinumYachtDockedLocaleId == locale.id;
          double foundationMultiplier = isFoundationApplied ? 1.05 : 1.0;
          double yachtMultiplier = isYachtDocked ? 1.05 : 1.0;

          for (var property in locale.properties) {
            if (property.owned > 0) {
              // Get base income per property (already includes owned count)
              // Note: isResilienceActive might be needed if other effects use it
              double basePropertyIncome = property.getTotalIncomePerSecond(isResilienceActive: isPlatinumResilienceActive); 
              
              // Apply locale-specific multipliers (Foundation, Yacht)
              double incomeWithLocaleBoosts = basePropertyIncome * foundationMultiplier * yachtMultiplier;

              // Apply standard global multipliers
              double finalPropertyIncome = incomeWithLocaleBoosts * incomeMultiplier * prestigeMultiplier;

              // Apply the overall permanent boost
              finalPropertyIncome *= permanentIncomeBoostMultiplier;
              
              // Apply Income Surge (if applicable)
              if (isIncomeSurgeActive) finalPropertyIncome *= 2.0;

              // Check for negative event affecting the LOCALE and apply multiplier AFTER all bonuses
              if (isLocaleAffectedByEvent) {
                finalPropertyIncome *= GameStateEvents.NEGATIVE_EVENT_MULTIPLIER; // Apply -0.25
              }
              
              realEstateIncomeThisTick += finalPropertyIncome;
            }
          }
        }
      }
      // Add real estate income to total (can be negative now)
      totalIncomeThisTick += realEstateIncomeThisTick;
      realEstateEarnings += realEstateIncomeThisTick; // Track net real estate earnings

      // Dividend Income (Events don't affect dividends directly - Reverted to simpler calculation)
      double dividendIncomeThisTick = 0.0;
      double diversificationBonus = calculateDiversificationBonus();
      double portfolioMultiplier = isPlatinumPortfolioActive ? 1.25 : 1.0; // Platinum portfolio boost
      
      for (var investment in investments) {
        if (investment.owned > 0 && investment.hasDividends()) {
          double baseDividend = investment.getDividendIncomePerSecond(); 
          
          // Calculate effective dividend per share considering portfolio/diversification
          double effectiveDividendPerShare = baseDividend * portfolioMultiplier * (1 + diversificationBonus);
          
          // Apply global multipliers and owned count
          double finalInvestmentDividend = effectiveDividendPerShare * investment.owned *
                                             incomeMultiplier *
                                             prestigeMultiplier;
                                             
           // Apply the overall permanent boost
           finalInvestmentDividend *= permanentIncomeBoostMultiplier;

           // Apply Income Surge (if applicable)
           if (isIncomeSurgeActive) finalInvestmentDividend *= 2.0; 

          dividendIncomeThisTick += finalInvestmentDividend;
        }
      }
      // Add dividend income to total
      totalIncomeThisTick += dividendIncomeThisTick;
      investmentDividendEarnings += dividendIncomeThisTick; // Track net dividend earnings

      // Apply total NET income for the tick (can be negative)
      if (totalIncomeThisTick != 0) { // Add or subtract based on the final value
          money += totalIncomeThisTick;
          totalEarned += totalIncomeThisTick; // totalEarned can now decrease if income is negative
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
      if (money != previousMoney) {
         stateChanged = true; // Money changed, need notification
      }

      // --- [8] Final Notification --- 
      if (stateChanged) {
        notifyListeners(); // Notify if any relevant state changed during the tick
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