part of '../game_state.dart';

// Contains methods related to the game's update loop and timers
extension UpdateLogic on GameState {
  // Constants for update frequencies - static constants are allowed in extensions
  static const int _investmentMicroUpdateIntervalSeconds = 5;
  static const int _netWorthUpdateIntervalMinutes = 30;
  static const int _maxHistoryEntries = 50; // Limit for history entries
  static const int _pruneHistoryThreshold = 45; // Prune when we reach this many entries
  
  // Tracking variables for income diagnostics

  // Timer setup is handled by TimerService.
  void _setupTimers() {
    // No-op. TimerService drives the update loop.
  }

  void _cancelAllTimers() {
    // No-op. TimerService cancels timers centrally.
  }

  // Update game state every tick (second) - Optimized with frequency-based updates
  void _updateGameState() {
    if (!isInitialized) return; // Early return if not ready
    
    final DateTime now = DateTime.now();

    // ENHANCED SAFEGUARD: More aggressive debounce to prevent duplicate updates
    if (_lastUpdateTime != null) {
      final int msSinceLastUpdate = now.difference(_lastUpdateTime!).inMilliseconds;
      if (msSinceLastUpdate < 950) { // Almost a full second to prevent edge cases
        print("⚠️ Skipping update: Too soon (${msSinceLastUpdate}ms since last update)");
        return; // Skip update silently if too soon
      }
    }
    
    // CRITICAL: Add a global update ID to track this specific update cycle
    // FIXED: Use a more precise update ID that includes milliseconds
    final String updateId = "${now.millisecondsSinceEpoch}";
    if (_lastProcessedUpdateId == updateId) {
      print("🛑 DUPLICATE UPDATE DETECTED: Update ID $updateId already processed");
      return; // Absolutely prevent duplicate processing of the same update cycle
    }
    _lastProcessedUpdateId = updateId;
  
    // FIXED: Add additional safeguard against updates that are too close together
    if (_lastUpdateTime != null) {
      final int msSinceLastUpdate = now.difference(_lastUpdateTime!).inMilliseconds;
      if (msSinceLastUpdate < 800) { // Even more aggressive debounce
        print("🛑 CRITICAL SAFEGUARD: Updates too close together (${msSinceLastUpdate}ms). Skipping.");
        return;
      }
    }

    try {
      // Record the time of this update attempt
      _lastUpdateTime = now; 

      final String hourKey = TimeUtils.getHourKey(now);
      bool stateChanged = false; // Track if notifyListeners is needed
      final double previousMoney = money; // Track money at the start of the tick

      // --- [0] Check/Reset Timed Effects & Limits First --- 
      // Using a more efficient approach to check all timed effects
      stateChanged |= _checkTimedEffects(now);
      
      // Time Warp Weekly Reset
      _checkAndResetTimeWarpLimit(now); // Check/handle weekly reset (may update state internally)

      // --- [1] Event System --- 
      checkAndTriggerEvents(); // From game_state_events.dart extension

      // --- ADDED [1.6]: Periodic Event State Tracking for AdMobService ---
      // Check every 30 seconds to ensure AdMobService has correct event state
      if (_lastEventStateCheckTime == null || now.difference(_lastEventStateCheckTime!).inSeconds >= 30) {
        notifyAdMobServiceOfEventStateChange();
        _lastEventStateCheckTime = now;
      }
      // --- END ADDED [1.6] ---

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
      // CRITICAL: Enhanced timestamp tracking for income to prevent duplicate calculations
      final String incomeTimestampKey = "${now.hour}:${now.minute}:${now.second}:${now.millisecond ~/ 100}";
      final bool alreadyProcessedThisSecond = _processedIncomeTimestamps.contains(incomeTimestampKey);
      
      // CRITICAL: Add a calculation lock to prevent concurrent income calculations
      if (_isCalculatingIncome) {
        print("🛑 INCOME SAFEGUARD: Income calculation already in progress, skipping");
        return; // Exit the entire update method if we're already calculating income
      }
      
      // Initialize income variables
      double totalIncomeThisTick = 0;
      double businessIncomeThisTick = 0;
      double realEstateIncomeThisTick = 0;
      double dividendIncomeThisTick = 0;
      double permanentIncomeBoostMultiplier = isPermanentIncomeBoostActive ? 1.05 : 1.0;
      
      // Skip income calculation if we've already processed this second
      if (alreadyProcessedThisSecond) {
        print("🔔 INCOME SAFEGUARD: Already processed income for timestamp $incomeTimestampKey, skipping");
      } else {
        // Set the calculation lock
        _isCalculatingIncome = true;
        
        try {
          // Record this timestamp to prevent duplicate processing
          _processedIncomeTimestamps.add(incomeTimestampKey);
          // Keep a limited history to prevent memory leaks
          if (_processedIncomeTimestamps.length > 10) {
            _processedIncomeTimestamps.removeAt(0);
          }
      
        // DEBUG: Track income calculation frequency
        DateTime incomeCalculationStartTime = DateTime.now();
        
        print("DEBUG: Starting business income calculation at ${DateTime.now().millisecondsSinceEpoch}");
        
        // Define business efficiency multiplier
        double businessEfficiencyMultiplier = isPlatinumEfficiencyActive ? 1.05 : 1.0;
      
        // CRITICAL FIX: Use the same per-second income calculation as in getBusinessIncomePerSecond()
        // This ensures the accrual matches the displayed income rate
        double businessIncomeThisTick = 0.0;
        for (var business in businesses) {
          if (business.level > 0) {
            print("DEBUG: Processing business ${business.name} - Level: ${business.level}");
            
            // Get base income with efficiency multiplier if active
            double baseIncome = business.getCurrentIncome(isResilienceActive: isPlatinumResilienceActive);
            print("DEBUG: Business '${business.name}' baseIncome: $baseIncome at ${DateTime.now().millisecondsSinceEpoch}");
            
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
            
            // DEBUG: Log final income
            print("DEBUG: Business '${business.name}' finalIncome: $finalIncome");
            
            businessIncomeThisTick += finalIncome;
          }
        }
      
        // DEBUG: Log calculation time
        Duration incomeCalculationDuration = DateTime.now().difference(incomeCalculationStartTime);
        print("DEBUG: Business income calculation duration: ${incomeCalculationDuration.inMilliseconds}ms");
        print("DEBUG: Total business income this tick: $businessIncomeThisTick");
        
        // Add business income to total (only tracking, not applying to money yet)
        totalIncomeThisTick += businessIncomeThisTick;
        if (businessIncomeThisTick > 0) {
          passiveEarnings += businessIncomeThisTick; // Track net passive earnings
        }

        // CRITICAL FIX: Use the same per-second real estate income calculation as in getRealEstateIncomePerSecond()
        // This ensures the accrual matches the displayed income rate
        double realEstateIncomeThisTick = 0.0;
        print("DEBUG: Starting real estate income calculation");
        
        for (var locale in realEstateLocales) {
          if (locale.unlocked) {
            // Get locale-specific multipliers
            bool isLocaleAffectedByEvent = hasActiveEventForLocale(locale.id);
            bool isFoundationApplied = platinumFoundationsApplied.containsKey(locale.id);
            bool isYachtDocked = platinumYachtDockedLocaleId == locale.id;
            double foundationMultiplier = isFoundationApplied ? 1.05 : 1.0;
            double yachtMultiplier = isYachtDocked ? 1.05 : 1.0;
            
            print("DEBUG: Processing locale ${locale.name} - Event: $isLocaleAffectedByEvent, Foundation: $isFoundationApplied, Yacht: $isYachtDocked");

            for (var property in locale.properties) {
              if (property.owned > 0) {
                // Get base income per property (already includes owned count)
                double basePropertyIncome = property.getTotalIncomePerSecond(isResilienceActive: isPlatinumResilienceActive); 
                print("DEBUG: Property '${property.name}' baseIncome: $basePropertyIncome");
                
                // Apply locale-specific multipliers (Foundation, Yacht)
                double incomeWithLocaleBoosts = basePropertyIncome * foundationMultiplier * yachtMultiplier;
                print("DEBUG: Property '${property.name}' after locale boosts: $incomeWithLocaleBoosts");

                // Apply standard global multipliers
                double finalPropertyIncome = incomeWithLocaleBoosts * incomeMultiplier;
                print("DEBUG: Property '${property.name}' after global multiplier: $finalPropertyIncome");

                // Apply the overall permanent boost
                finalPropertyIncome *= permanentIncomeBoostMultiplier;
                print("DEBUG: Property '${property.name}' after permanent boost: $finalPropertyIncome");
                
                // Apply Income Surge (if applicable)
                if (isIncomeSurgeActive) {
                  finalPropertyIncome *= 2.0;
                  print("DEBUG: Property '${property.name}' after income surge: $finalPropertyIncome");
                }

                // Check for negative event affecting the LOCALE and apply multiplier AFTER all bonuses
                if (isLocaleAffectedByEvent) {
                  finalPropertyIncome *= GameStateEvents.NEGATIVE_EVENT_MULTIPLIER; // Apply -0.25
                  print("DEBUG: Property '${property.name}' after event penalty: $finalPropertyIncome");
                }
                
                print("DEBUG: Property '${property.name}' final income: $finalPropertyIncome");
                realEstateIncomeThisTick += finalPropertyIncome;
              }
            }
          }
        }
        
        print("DEBUG: Total real estate income this tick: $realEstateIncomeThisTick");
        // Add real estate income to total (only tracking, not applying to money yet)
        totalIncomeThisTick += realEstateIncomeThisTick;
        // FIXED: Always track real estate earnings regardless of sign
        realEstateEarnings += realEstateIncomeThisTick;

        // CRITICAL FIX: Use the same per-second dividend income calculation as in getDividendIncomePerSecond()
        // This ensures the accrual matches the displayed income rate
        double dividendIncomeThisTick = 0.0;
        print("DEBUG: Starting dividend income calculation");
        
        double diversificationBonus = calculateDiversificationBonus(); // Calculate once for efficiency
        double portfolioMultiplier = isPlatinumPortfolioActive ? 1.25 : 1.0;
        
        for (var investment in investments) {
          if (investment.owned > 0 && investment.hasDividends()) {
            // Get base dividend per second for this investment (already includes owned count)
            double baseDividend = investment.getDividendIncomePerSecond();
            print("DEBUG: Investment '${investment.name}' base dividend: $baseDividend");
            
            // Apply portfolio multiplier and diversification bonus
            double adjustedDividend = baseDividend * portfolioMultiplier * (1 + diversificationBonus);
            print("DEBUG: Investment '${investment.name}' after portfolio/diversification: $adjustedDividend");
            
            // FIXED: Removed duplicate multiplication by investment.owned
            // investment.getDividendIncomePerSecond() already multiplies by owned
            double totalDividendForInvestment = adjustedDividend;
            print("DEBUG: Investment '${investment.name}' after removing duplicate owned multiplication: $totalDividendForInvestment");
            
            // Apply global income multiplier
            totalDividendForInvestment *= incomeMultiplier;
            print("DEBUG: Investment '${investment.name}' after global multiplier: $totalDividendForInvestment");
            
            // Apply the overall permanent boost
            totalDividendForInvestment *= permanentIncomeBoostMultiplier;
            print("DEBUG: Investment '${investment.name}' after permanent boost: $totalDividendForInvestment");

            // Apply Income Surge (if applicable)
            if (isIncomeSurgeActive) {
              totalDividendForInvestment *= 2.0;
              print("DEBUG: Investment '${investment.name}' after income surge: $totalDividendForInvestment");
            }

            print("DEBUG: Investment '${investment.name}' final dividend: $totalDividendForInvestment");
            dividendIncomeThisTick += totalDividendForInvestment;
          }
        }
        
        print("DEBUG: Total dividend income this tick: $dividendIncomeThisTick");
        // Add dividend income to total (only tracking, not applying to money yet)
        totalIncomeThisTick += dividendIncomeThisTick;
        // FIXED: Always track dividend earnings regardless of sign
        investmentDividendEarnings += dividendIncomeThisTick;

        // Calculate income for diagnostic purposes only
        // This is used to display income rate and verify it matches what's being applied
        double incomePerSecond = calculateTotalIncomePerSecond();
        
        // Log income calculation for diagnostic purposes
        if (now.second % 10 == 0) {
          // Calculate the breakdown of income sources for diagnostics
          double businessIncome = 0.0;
          for (var business in businesses) {
            if (business.level > 0) {
              double cyclesPerSecond = 1 / business.incomeInterval;
              businessIncome += business.getCurrentIncome(isResilienceActive: isPlatinumResilienceActive) * 
                               cyclesPerSecond * 
                               (isPlatinumEfficiencyActive ? 1.05 : 1.0);
            }
          }
          
          double realEstateIncome = 0.0;
          for (var locale in realEstateLocales) {
            if (locale.unlocked) {
              bool isFoundationApplied = platinumFoundationsApplied.containsKey(locale.id);
              bool isYachtDocked = platinumYachtDockedLocaleId == locale.id;
              double foundationMultiplier = isFoundationApplied ? 1.05 : 1.0;
              double yachtMultiplier = isYachtDocked ? 1.05 : 1.0;
              
              for (var property in locale.properties) {
                if (property.owned > 0) {
                  realEstateIncome += property.getTotalIncomePerSecond(isResilienceActive: isPlatinumResilienceActive) * 
                                      foundationMultiplier * 
                                      yachtMultiplier;
                }
              }
            }
          }
          
          double dividendIncome = 0.0;
          double diversificationBonus = calculateDiversificationBonus();
          double portfolioMultiplier = isPlatinumPortfolioActive ? 1.25 : 1.0;
          
          for (var investment in investments) {
            if (investment.owned > 0 && investment.hasDividends()) {
              dividendIncome += investment.getDividendIncomePerSecond() * 
                               portfolioMultiplier * 
                               (1 + diversificationBonus);
            }
          }
          
          // Log detailed income breakdown
          print("💰 [INCOME DIAGNOSTICS] Rate: ${incomePerSecond.toStringAsFixed(2)}/sec, Money: ${money.toStringAsFixed(2)}");
          print("💰 [INCOME DIAGNOSTICS] Breakdown - Business: ${businessIncome.toStringAsFixed(2)}, Real Estate: ${realEstateIncome.toStringAsFixed(2)}, Dividends: ${dividendIncome.toStringAsFixed(2)}");
        }

        // Update lastCalculatedIncomePerSecond for consistent UI display
        // This should match what _calculateIncomePerSecond in main_screen would compute
        lastCalculatedIncomePerSecond = calculateTotalIncomePerSecond();
        
        // CRITICAL FIX: Apply the full income (positive or negative) to the player's cash balance
        // This ensures events properly impact the player's finances
        money += totalIncomeThisTick;
        totalEarned += totalIncomeThisTick; // Track all earnings, positive or negative
        } finally {
          // Always reset the calculation lock, even if an error occurs
          _isCalculatingIncome = false;
        }
      } // End of the income safeguard conditional block
      
      // --- [5] Investment Micro-Updates (every 5 seconds) --- 
      if (_lastInvestmentMicroUpdateTime == null || 
          now.difference(_lastInvestmentMicroUpdateTime!).inSeconds >= _investmentMicroUpdateIntervalSeconds) {
        _updateInvestmentPricesMicro();
        _lastInvestmentMicroUpdateTime = now;
      }

      // --- [6] Daily Investment Update Check --- 
      final int todayDay = now.weekday; // 1-7 (Monday-Sunday)
      if (_lastDailyCheckTime == null || todayDay != currentDay) {
        currentDay = todayDay;
        _updateInvestments(); // Perform daily investment updates & market events
        _updateInvestmentPrices(); // Perform a full price update/history push on day change
        _lastDailyCheckTime = now;
      }

      // --- [7] Persistent Net Worth Tracking (Every 30 mins) --- 
      if (_lastNetWorthUpdateTime == null || 
          now.difference(_lastNetWorthUpdateTime!).inMinutes >= _netWorthUpdateIntervalMinutes) {
        final int timestampMs = now.millisecondsSinceEpoch;
        final double currentNetWorth = calculateNetWorth();
        persistentNetWorthHistory[timestampMs] = currentNetWorth;
        _prunePersistentNetWorthHistory();
        _lastNetWorthUpdateTime = now;
      }

      // --- [8] Final Notification --- 
      if (money != previousMoney) {
         stateChanged = true; // Money changed, need notification
      }

      // Only notify listeners if state actually changed
      if (stateChanged) {
        notifyListeners();
      }

    } catch (e, stackTrace) {
      print("❌ ERROR in _updateGameState: $e");
      print(stackTrace);
    }
  }

  // -----[ STATS HELPERS ]-----

  // Helper to update daily earnings (now aggregated hourly) and prune old entries
  void _updateDailyEarnings(String dayKey, double amount) {
     // This method is deprecated in favor of _updateHourlyEarnings
     // hourlyEarnings[dayKey] = (hourlyEarnings[dayKey] ?? 0) + amount;
     // _pruneHourlyEarnings(); // Use the hourly pruning logic
  }

  // Helper to update hourly earnings with optimized pruning
  void updateHourlyEarnings(String hourKey, double amount) {
    // Skip if we're updating too frequently (possible duplicate)
    if (_lastUpdateTime != null && 
        DateTime.now().difference(_lastUpdateTime!).inMilliseconds < 900) {
      return;
    }

    // Update the earnings value
    hourlyEarnings[hourKey] = (hourlyEarnings[hourKey] ?? 0) + amount;
    
    // Only prune periodically to reduce overhead - start pruning earlier to avoid large pruning operations
    if (hourlyEarnings.length > _pruneHistoryThreshold) {
      _pruneHourlyEarnings();
    }
  }
  
  // Helper method to check all timed effects at once
  bool _checkTimedEffects(DateTime now) {
    bool stateChanged = false;
    
    // Income Surge
    if (isIncomeSurgeActive && incomeSurgeEndTime != null && now.isAfter(incomeSurgeEndTime!)) {
      isIncomeSurgeActive = false;
      incomeSurgeEndTime = null;
      stateChanged = true;
    }
    
    // Disaster Shield
    if (isDisasterShieldActive && disasterShieldEndTime != null && now.isAfter(disasterShieldEndTime!)) {
      isDisasterShieldActive = false;
      disasterShieldEndTime = null;
      stateChanged = true;
    }
    
    // Crisis Accelerator
    if (isCrisisAcceleratorActive && crisisAcceleratorEndTime != null && now.isAfter(crisisAcceleratorEndTime!)) {
      isCrisisAcceleratorActive = false;
      crisisAcceleratorEndTime = null;
      stateChanged = true;
    }
    
    // Only check these if they exist in the GameState class
    // If these properties don't exist yet, you'll need to add them to the GameState class
    
    return stateChanged;
  }
} 
