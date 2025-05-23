part of '../game_state.dart';

// Contains methods related to the game's update loop and timers
extension UpdateLogic on GameState {

  // Setup game timers
  void _setupTimers() {
    // Cancel existing timers before creating new ones to prevent duplicates
    if (timersActive) {
      print("⚠️ Timers already active, ensuring proper cleanup before setup");
      _cancelAllTimers();
    }

    print("⏱️ Setting up game timers...");

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
    
    timersActive = true;
    print("⏱️ Timers setup complete.");
  }

  // Helper method to cancel all timers
  void _cancelAllTimers() {
    print("🛑 Cancelling all game timers");
    _saveTimer?.cancel();
    _saveTimer = null;
    
    _updateTimer?.cancel();
    _updateTimer = null;
    
    _investmentUpdateTimer?.cancel();
    _investmentUpdateTimer = null;
    
    // Reset the timer flag
    timersActive = false;
    print("✅ All game timers cancelled");
  }

  // Update game state every tick (second)
  void _updateGameState() {
    if (!isInitialized) return; // Don't update if not fully initialized
    
    // CRITICAL FIX: Guard against multiple update cycles
    if (!timersActive) {
      print("⚠️ [UPDATE] Update called with inactive timers, skipping to prevent duplicate calculation");
      return;
    }

    DateTime now = DateTime.now();

    // ENHANCED Debounce Check: Use a higher threshold (975ms) to be even safer
    if (_lastUpdateTime != null) {
      final int msSinceLastUpdate = now.difference(_lastUpdateTime!).inMilliseconds;
      if (msSinceLastUpdate < 975) {
        print("🔄 [UPDATE] Skipping update - only ${msSinceLastUpdate}ms since last update (need 975+ms)");
        return; // Skip this update call
      }
    }

    try {
      // Record the time of this update attempt *before* potential errors
      _lastUpdateTime = now; 

      String hourKey = TimeUtils.getHourKey(now);
      bool stateChanged = false; // Track if notifyListeners is needed
      double previousMoney = money; // Track money at the start of the tick

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
      // DEBUG: Log event system entry
      print("DEBUG: Entering event system at ${DateTime.now().millisecondsSinceEpoch}");
      checkAndTriggerEvents(); // From game_state_events.dart extension
      print("DEBUG: Exiting event system at ${DateTime.now().millisecondsSinceEpoch}");

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
      // DEBUG: Log booster check
      print("DEBUG: Checking boosters at ${DateTime.now().millisecondsSinceEpoch}");
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
      double totalIncomeThisTick = 0;

      // Business Income
      double businessIncomeThisTick = 0;
      // Define multipliers used across income sources
      double businessEfficiencyMultiplier = isPlatinumEfficiencyActive ? 1.05 : 1.0;
      double permanentIncomeBoostMultiplier = isPermanentIncomeBoostActive ? 1.05 : 1.0;
      
      // DEBUG: Track income calculation frequency
      int incomeCalculationsThisTick = 0;
      DateTime incomeCalculationStartTime = DateTime.now();
      
      print("DEBUG: Starting business income calculation at ${DateTime.now().millisecondsSinceEpoch}");
      print("DEBUG: Current multipliers - Efficiency: $businessEfficiencyMultiplier, Permanent: $permanentIncomeBoostMultiplier");
      
      for (var business in businesses) {
        if (business.level > 0) {
          print("DEBUG: Processing business ${business.name} - Level: ${business.level}, Interval: ${business.incomeInterval}, SecondsSinceLast: ${business.secondsSinceLastIncome}");
          
          business.secondsSinceLastIncome++;
          if (business.secondsSinceLastIncome >= business.incomeInterval) {
            incomeCalculationsThisTick++; // DEBUG: Increment counter
            
            // DEBUG: Log raw base income
            double baseIncome = business.getCurrentIncome(isResilienceActive: isPlatinumResilienceActive);
            print("DEBUG: Business '${business.name}' baseIncome: $baseIncome at ${DateTime.now().millisecondsSinceEpoch}");
            print("DEBUG: Business '${business.name}' state - Level: ${business.level}, Resilience: $isPlatinumResilienceActive");
            
            // Apply Platinum Efficiency first
            double incomeWithEfficiency = baseIncome * businessEfficiencyMultiplier;
            print("DEBUG: Business '${business.name}' after efficiency: $incomeWithEfficiency");

            // Apply standard multipliers
            double finalIncome = incomeWithEfficiency * incomeMultiplier;
            print("DEBUG: Business '${business.name}' after income multiplier: $finalIncome");
            
            // Apply the overall permanent boost
            finalIncome *= permanentIncomeBoostMultiplier;
            print("DEBUG: Business '${business.name}' after permanent boost: $finalIncome");

            // Apply Income Surge (if applicable)
            if (isIncomeSurgeActive) {
              finalIncome *= 2.0;
              print("DEBUG: Business '${business.name}' after income surge: $finalIncome");
            }

            // Check for negative event and apply multiplier AFTER all bonuses
            bool hasEvent = hasActiveEventForBusiness(business.id);
            if (hasEvent) {
              finalIncome *= GameStateEvents.NEGATIVE_EVENT_MULTIPLIER;
              print("DEBUG: Business '${business.name}' after event penalty: $finalIncome");
            }
            
            // DEBUG: Log final income and calculation count
            print("DEBUG: Business '${business.name}' finalIncome: $finalIncome (Calculation #$incomeCalculationsThisTick)");
            
            businessIncomeThisTick += finalIncome;
            business.secondsSinceLastIncome = 0;
            print("DEBUG: Business '${business.name}' secondsSinceLastIncome reset to 0");
          }
        }
      }
      
      // DEBUG: Log total calculations and time elapsed
      Duration incomeCalculationDuration = DateTime.now().difference(incomeCalculationStartTime);
      print("DEBUG: Total business income calculations this tick: $incomeCalculationsThisTick (Duration: ${incomeCalculationDuration.inMilliseconds}ms)");
      print("DEBUG: Total business income this tick: $businessIncomeThisTick");
      
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
              double finalPropertyIncome = incomeWithLocaleBoosts * incomeMultiplier;

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
          double finalInvestmentDividend = effectiveDividendPerShare * investment.owned;
          
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
          updateHourlyEarnings(hourKey, totalIncomeThisTick);
          
          // CRITICAL FIX: Log current income rate for debugging
          final double currentIncomeRate = calculateTotalIncomePerSecond();
          print("💰 [INCOME] Applied ${totalIncomeThisTick.toStringAsFixed(2)} this tick");
          print("💰 [INCOME] Current income rate: ${currentIncomeRate.toStringAsFixed(2)}/sec");
          
          // Track current money value to help detect issues
          print("💰 [INCOME] Money now: ${money.toStringAsFixed(2)}");
      }

      // Update lastCalculatedIncomePerSecond for consistent UI display
      // This should match what _calculateIncomePerSecond in main_screen would compute
      lastCalculatedIncomePerSecond = calculateTotalIncomePerSecond();
      
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
      // DEBUG: Log final money state
      print("DEBUG: Final money state - Previous: $previousMoney, Current: $money, Change: ${money - previousMoney}");
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

  // Helper to update hourly earnings (e.g., older than 7 days)
  void updateHourlyEarnings(String hourKey, double amount) {
    // CRITICAL FIX: Safeguard against potential rapid, duplicate income entries 
    // by using last update time as a reference
    if (_lastUpdateTime != null) {
      final timeSinceLastUpdate = DateTime.now().difference(_lastUpdateTime!).inMilliseconds;
      
      // Only process if we haven't updated too recently
      if (timeSinceLastUpdate < 900) {
        print("⚠️ Skipping hourly earning update - too soon since last update (${timeSinceLastUpdate}ms)");
        return;
      }
    }

    print("💰 Updating hourly earnings for $hourKey with amount: $amount");
    hourlyEarnings[hourKey] = (hourlyEarnings[hourKey] ?? 0) + amount;
    _pruneHourlyEarnings(); // Use the hourly pruning logic
  }
} 