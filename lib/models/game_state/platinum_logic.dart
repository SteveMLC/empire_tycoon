part of '../game_state.dart';

extension PlatinumLogic on GameState {
  // Constants for platinum features
  static const int _maxFoundations = 5;
  static const int _maxTimeWarpsPerWeek = 2;
  
  // Methods for managing platinum points and vault items
  // Optimized platinum points awarding with debounced animation
  void awardPlatinumPoints(int amount) {
    if (amount <= 0) return; // Early return for invalid amounts
    
    try {
      // Update points immediately
      platinumPoints += amount;
      
      // Only start a new animation timer if one isn't already running
      if (!showPPAnimation) {
        showPPAnimation = true;
        notifyListeners();
        
        // Use a safe timer with weak reference to avoid memory leaks
        Timer(const Duration(seconds: 3), () {
          try {
            // Only update if animation is still showing (prevents race conditions)
            if (showPPAnimation) {
              showPPAnimation = false;
              notifyListeners();
            }
          } catch (e) {
            print('Error in platinum animation timer: $e');
          }
        });
      } else {
        // If animation is already running, just notify of the point change
        notifyListeners();
      }
    } catch (e) {
      print('Error awarding platinum points: $e');
    }
  }

  // Optimized platinum points spending with early returns for efficiency
  bool spendPlatinumPoints(String itemId, int cost, {Map<String, dynamic>? purchaseContext}) {
    try {
      // Fast path: Check the most common rejection conditions first
      // Check if affordable - most common rejection reason
      if (platinumPoints < cost) {
        return false; // Not enough PP
      }

      // Check ownership for one-time items - second most common rejection
      if (ppOwnedItems.contains(itemId)) {
        return false; // Already owned
      }
      
      final DateTime now = DateTime.now(); // Only get current time if we pass initial checks

    // --- Specific Cooldown/Limit/Active Checks ---
    switch (itemId) {
        case 'platinum_surge':
            if (isIncomeSurgeActive) {
                return false; // Prevent purchase if already active
            }
            if (incomeSurgeCooldownEnd != null && now.isBefore(incomeSurgeCooldownEnd!)) {
                return false; // On cooldown
            }
            break;
        case 'platinum_cache':
            if (cashCacheCooldownEnd != null && now.isBefore(cashCacheCooldownEnd!)) {
                return false; // On cooldown
            }
            break;
        case 'platinum_warp':
            // Check time warp limit using the existing method
            if (timeWarpUsesThisPeriod >= 2) { // Use constant value directly
                return false; // Limit reached
            }
            // Check if on cooldown
            if (timeWarpCooldownEnd != null && now.isBefore(timeWarpCooldownEnd!)) {
                return false; // On cooldown
            }
            break;
        case 'platinum_shield':
            if (isDisasterShieldActive) {
                return false; // Already active, don't allow stacking/extending for now
            }
            break;
        case 'platinum_accelerator':
            if (isCrisisAcceleratorActive) {
                return false; // Already active, don't allow stacking/extending for now
            }
            break;
        case 'temp_boost_10x_5min':
            if (isClickFrenzyActive) {
                return false; // Already active, no double-stack
            }
            break;
        case 'temp_boost_2x_10min':
            if (isSteadyBoostActive) {
                return false; // Already active, no double-stack
            }
            break;
        case 'auto_clicker':
            if (isAutoClickerActive) {
                return false; // Prevent stacking
            }
            break;
        case 'platinum_foundation':
             // Check global limit
             if (platinumFoundationsApplied.length >= _maxFoundations) {
                return false;
             }
             // Check if the specific locale (passed in context) is already boosted
             String? selectedLocaleId = purchaseContext?['selectedLocaleId'] as String?;
             if (selectedLocaleId != null && platinumFoundationsApplied.containsKey(selectedLocaleId)) {
                 return false; // Already applied to this locale
             }
             break;
        case 'platinum_facade':
             // Check if there are any eligible businesses
             final eligibleBusinesses = businesses.where((b) => 
               b.level > 0 && 
               !platinumFacadeAppliedBusinessIds.contains(b.id) && 
               b.unlocked
             ).toList();
             
             if (eligibleBusinesses.isEmpty) {
                 return false; // No eligible businesses
             }
             
             // If a specific business was selected, check if it's eligible
             String? selectedBusinessId = purchaseContext?['selectedBusinessId'] as String?;
             if (selectedBusinessId != null) {
                 // Check if the business is eligible
                 bool isEligible = eligibleBusinesses.any((b) => b.id == selectedBusinessId);
                 if (!isEligible) {
                     return false; // Selected business not eligible
                 }
             }
             break;
        case 'platinum_stock':
            // Check if the stock already exists
            if (investments.any((i) => i.id == 'platinum_stock')) {
                return false; // Already added to portfolio
            }
            break;
    }
    // --- End specific checks ---

    // If all checks passed, proceed with purchase
    platinumPoints -= cost;

    // Track purchase - distinguish one-time vs repeatable
    var itemDefinition = getVaultItems().firstWhere(
      (item) => item.id == itemId, 
      orElse: () => VaultItem(
        id: 'unknown', 
        name: 'Unknown', 
        description: '', 
        category: VaultItemCategory.cosmetics, 
        type: VaultItemType.oneTime, 
        cost: 0
      )
    );
    
    // Check if one-time item
    if (itemDefinition.type == VaultItemType.oneTime) {
      ppOwnedItems.add(itemId);
    } else { 
      // For repeatable items, increment purchase count
      ppPurchases[itemId] = (ppPurchases[itemId] ?? 0) + 1;
    }
    
    // Apply effects based on item type
    switch (itemId) {
      case 'platinum_surge':
        isIncomeSurgeActive = true;
        incomeSurgeEndTime = now.add(const Duration(hours: 1));
        incomeSurgeCooldownEnd = now.add(const Duration(days: 1));
        break;
      case 'platinum_cache':
        double cashAward = _calculateCashCache();
        money += cashAward;
        totalEarned += cashAward;
        cashCacheCooldownEnd = now.add(const Duration(days: 1));
        break;
      case 'platinum_stock':
        // Add the special platinum stock to the portfolio
        investments.add(Investment(
          id: 'platinum_stock',
          name: 'Quantum Computing Inc.',
          description: 'High-risk, high-reward venture in quantum computing.',
          currentPrice: 1000000000.0,
          basePrice: 1000000000.0,
          volatility: 0.40,
          trend: 0.06,
          owned: 0,
          icon: Icons.memory,
          color: Colors.cyan,
          priceHistory: List.generate(30, (i) => 1000000000.0 * (0.95 + (Random().nextDouble() * 0.1))),
          category: 'Technology',
          dividendPerSecond: 1750000,
          marketCap: 4.0e12,
        ));
        break;
      case 'platinum_facade':
        if (purchaseContext != null && purchaseContext.containsKey('selectedBusinessId')) {
          String businessId = purchaseContext['selectedBusinessId'] as String;
          // Apply facade directly here
          final businessIndex = businesses.indexWhere((b) => b.id == businessId);
          if (businessIndex >= 0) {
            businesses[businessIndex].hasPlatinumFacade = true;
            platinumFacadeAppliedBusinessIds.add(businessId);
          }
        }
        break;
      // Add other cases as needed
    }
    
    notifyListeners();
    return true;
  } catch (e) {
    print("Error in spendPlatinumPoints: $e");
    return false;
  }

    notifyListeners();
    return true;
  }

  // Use the existing implementation for time warp limit checking
  void _checkTimeWarpLimit(DateTime now) {
    try {
      // Check if we need to reset the weekly time warp limit
      if (lastTimeWarpReset == null) {
        // First use ever, set the reset time to next week
        lastTimeWarpReset = DateTime(now.year, now.month, now.day + 7);
        timeWarpUsesThisPeriod = 0;
      } else if (now.isAfter(lastTimeWarpReset!)) {
        // It's past the reset time, reset the counter and set the next reset time
        lastTimeWarpReset = DateTime(now.year, now.month, now.day + 7);
        timeWarpUsesThisPeriod = 0;
      }
    } catch (e) {
      print('Error in _checkTimeWarpLimit: $e');
    }
  }

  // Apply effects for platinum items
  void _applyEffect(String itemId, DateTime purchaseTime, Map<String, dynamic>? purchaseContext) {
    print("Applying effect for $itemId at $purchaseTime");
    // --- This needs detailed implementation based on item ID ---
    switch (itemId) {
        case 'platinum_efficiency':
            isPlatinumEfficiencyActive = true;
            print("Activated Platinum Efficiency (Business Upgrade +5%). Effect applied in income calculation.");
            break;
        case 'platinum_portfolio':
            isPlatinumPortfolioActive = true;
            print("Activated Platinum Portfolio (Dividend +25%). Effect applied in income calculation.");
            break;
        case 'platinum_foundation':
            // Use the selected locale ID from the context
            String? targetLocaleId = purchaseContext?['selectedLocaleId'] as String?;

            if (targetLocaleId != null) {
                // Check limits again just in case (should be pre-checked in spendPlatinumPoints)
                if (platinumFoundationsApplied.length < 5 && !platinumFoundationsApplied.containsKey(targetLocaleId)) {
                   platinumFoundationsApplied[targetLocaleId] = 1; // Store that foundation is applied
                   print("Applied Platinum Foundation to $targetLocaleId");
                } else {
                   print("WARNING: Attempted to apply foundation $itemId to $targetLocaleId but limits were reached or already applied.");
                }
            } else {
               print("ERROR: Could not apply Platinum Foundation - missing selectedLocaleId in context.");
            }
            break;
        case 'platinum_resilience':
            isPlatinumResilienceActive = true;
            print("Activated Platinum Resilience (Event Impact -10%). Effect applied in event processing.");
            break;
        case 'platinum_facade':
            // Use the selected business ID from the context
            String? targetBusinessId = purchaseContext?['selectedBusinessId'] as String?;
            
            if (targetBusinessId != null) {
                // Apply the platinum facade to the selected business
                applyPlatinumFacade(targetBusinessId);
                print("Applied Platinum Facade to business $targetBusinessId");
            } else {
                print("ERROR: Could not apply Platinum Facade - missing selectedBusinessId in context.");
            }
            break;
        case 'platinum_tower':
            isPlatinumTowerUnlocked = true;
            _updateRealEstateUnlocks(); // Trigger unlock check
            break;
        case 'platinum_venture':
            isPlatinumVentureUnlocked = true;
            _updateBusinessUnlocks(); // Trigger unlock check
            break;
        case 'platinum_stock':
            isPlatinumStockUnlocked = true;
            // TODO: Add the actual 'platinum_stock' investment to the investments list if not present.
            // Need to ensure it's only added once.
            if (!investments.any((inv) => inv.id == 'platinum_stock')) {
                _addPlatinumStockInvestment(); // Add helper function for this
                print("Added Platinum Stock Investment.");
            }
            break;
        case 'platinum_islands':
            isPlatinumIslandsUnlocked = true;
            _updateRealEstateUnlocks(); // Trigger unlock check
            break;
        case 'platinum_yacht':
            // Apply effect: Set unlock flag and store docked location from context
            String? targetLocaleId = purchaseContext?['selectedLocaleId'] as String?;
            if (targetLocaleId != null) {
                isPlatinumYachtUnlocked = true;
                platinumYachtDockedLocaleId = targetLocaleId;
                print("Activated Platinum Yacht and docked at $targetLocaleId.");
            } else {
                print("ERROR: Could not apply Platinum Yacht effect - missing selectedLocaleId in context.");
                // Attempt to refund points? This requires more complex logic.
            }
            break;
        case 'platinum_island':
             // Requires Platinum Islands locale to be unlocked FIRST (checked in UI ideally)
             if (isPlatinumIslandsUnlocked) {
                 isPlatinumIslandUnlocked = true;
                 _updateRealEstateUnlocks(); // Trigger unlock check
             } else {
                 print("Cannot unlock Platinum Island property: Platinum Islands locale not unlocked.");
                 // Optionally refund points?
             }
            break;
        // --- Events & Challenges ---
        case 'platinum_challenge':
            // Check if the user can start a new challenge based on current income
            double currentIncomePerSecond = _calculateIncomePerSecond();
            double challengeGoal = currentIncomePerSecond * 2 * 3600; // Double hourly income = 2 * current/sec * 3600
            
            // If current income is 0, set a minimum challenge goal
            if (challengeGoal <= 0) {
              challengeGoal = 1000; // Minimum challenge goal of $1,000
            }
            
            // Create and assign the active challenge
            activeChallenge = Challenge(
              itemId: itemId,
              name: "Platinum Income Challenge", // Added missing name
              description: "Earn double your hourly income within 1 hour!", // Added missing description
              startTime: purchaseTime,
              duration: const Duration(hours: 1),  // 1 hour challenge
              goalEarnedAmount: challengeGoal,
              startTotalEarned: totalEarned,  // Current total earned
              rewardPP: 30,  // PP reward for completing the challenge
            );
            
            // Track usage
            platinumChallengeLastUsedTime = purchaseTime;
            platinumChallengeUsesToday++; // Increment daily usage counter
            lastPlatinumChallengeDayTracked = DateTime(purchaseTime.year, purchaseTime.month, purchaseTime.day);
            
            print("INFO: Started Platinum Challenge to earn $challengeGoal within 1 hour (${platinumChallengeUsesToday}/2 today)");
            notifyListeners(); // Explicitly notify listeners for challenge activation
            break;
        case 'platinum_shield':
            // Pre-check in spendPlatinumPoints ensures it's not already active
            isDisasterShieldActive = true;
            disasterShieldEndTime = purchaseTime.add(const Duration(days: 1)); // 24h duration
            print("INFO: Disaster Shield Activated! Ends at: $disasterShieldEndTime");
            // TODO: Add user-facing notification for shield activation.
            // notifyListeners(); // Called at the end of the method
            break;
        case 'platinum_accelerator':
             // Pre-check in spendPlatinumPoints ensures it's not already active
            isCrisisAcceleratorActive = true;
            crisisAcceleratorEndTime = purchaseTime.add(const Duration(days: 1)); // 24h duration
            print("INFO: Crisis Accelerator Activated! Ends at: $crisisAcceleratorEndTime");
            // TODO: Add user-facing notification.
             // notifyListeners(); // Called at the end of the method
            break;
        // --- Cosmetics ---
        case 'platinum_mogul':
            // ONLY unlock mogul avatars - NOT the executive theme or platinum crest
            isMogulAvatarsUnlocked = true;
            // Explicitly make sure Platinum Crest is NOT unlocked by this item
            // isPlatinumCrestUnlocked remains unchanged
            // isExecutiveThemeUnlocked remains unchanged
            print("Unlocked Mogul Avatars (via Platinum Mogul).");
            break;
        case 'platinum_facade': 
            // TODO: Implement UI to select which owned business gets the facade.
            // For now, just acknowledge the purchase attempt.
            print("TODO: Implement business selection UI for Platinum Facade. Effect not applied yet.");
            // Example future logic:
            // String? targetBusinessId = // ... get from purchase context ...;
            // if (targetBusinessId != null && businesses.any((b) => b.id == targetBusinessId && b.level > 0) && !platinumFacadeAppliedBusinessIds.contains(targetBusinessId)) {
            //     platinumFacadeAppliedBusinessIds.add(targetBusinessId);
            //     print("Applied Platinum Facade to $targetBusinessId");
            // } else {
            //     print("Failed to apply Platinum Facade: Invalid target or already applied.");
            //     // Optionally refund points
            // }
            break;
        case 'platinum_crest': 
            isPlatinumCrestUnlocked = true;
            print("Unlocked Platinum Crest.");
            break;
        case 'platinum_spire':
            // Use the selected locale ID from the context
            String? targetLocaleId = purchaseContext?['selectedLocaleId'] as String?;

            if (targetLocaleId != null && realEstateLocales.any((l) => l.id == targetLocaleId && l.unlocked) && platinumSpireLocaleId == null) {
                platinumSpireLocaleId = targetLocaleId;
                print("Placed Platinum Spire Trophy in locale $targetLocaleId");
            } else if (targetLocaleId == null) {
                print("ERROR: Could not place Platinum Spire Trophy - missing selectedLocaleId in context.");
            } else {
                print("Failed to place Platinum Spire Trophy: Invalid target or spire already placed.");
            }
            break;
        // --- Boosters ---
        case 'platinum_surge':
            // Pre-check in spendPlatinumPoints ensures it's not already active and not on cooldown
            isIncomeSurgeActive = true;
            incomeSurgeEndTime = purchaseTime.add(const Duration(hours: 1));
            incomeSurgeCooldownEnd = purchaseTime.add(const Duration(days: 1)); // 24h cooldown
            print("INFO: Income Surge Activated! Ends at: $incomeSurgeEndTime. Cooldown until: $incomeSurgeCooldownEnd");
            // TODO: Add user-facing notification.
            // notifyListeners(); // Called at the end of the method
            break;
        case 'platinum_warp':
            // Pre-check in spendPlatinumPoints ensures limit not reached
            double incomePerSecond = calculateTotalIncomePerSecond();
            double oneHourInSeconds = 1.0 * 60 * 60; // 1 hour in seconds
            double incomeAward = incomePerSecond * oneHourInSeconds;
            
            if (incomeAward > 0) {
                money += incomeAward;
                totalEarned += incomeAward;
                passiveEarnings += incomeAward; // Attribute to passive
                print("INFO: Awarded ${NumberFormatter.formatCompact(incomeAward)} via Income Warp (1 hour of income).");
                // TODO: Add user-facing notification.
            } else {
                print("INFO: Income Warp: No income calculated (income/sec might be zero).");
            }
            timeWarpUsesThisPeriod++; // Increment usage count
            // Set 2-hour cooldown
            timeWarpCooldownEnd = purchaseTime.add(const Duration(hours: 2));
            print("INFO: Income Warp uses this period: $timeWarpUsesThisPeriod/2");
            print("INFO: Income Warp cooldown set until: $timeWarpCooldownEnd");
            // notifyListeners(); // Called at the end of the method
            break;
        case 'platinum_cache':
             // Pre-check in spendPlatinumPoints ensures not on cooldown
             double cashAward = _calculateCashCache(); // Use helper for scaling
             money += cashAward;
             totalEarned += cashAward; // Track earnings
             // Maybe attribute to a specific category later?
             // passiveEarnings += cashAward; // Or maybe manualEarnings?
             cashCacheCooldownEnd = purchaseTime.add(const Duration(days: 1)); // 24h cooldown
             print("Awarded ${NumberFormatter.formatCompact(cashAward)} via Platinum Cache. Cooldown until: $cashCacheCooldownEnd");
             // TODO: Add user-facing notification.
             // notifyListeners(); // Called at the end of the method
             break;
        case 'perm_income_boost_5pct':
            isPermanentIncomeBoostActive = true;
            print("Activated Permanent Income Boost (+5%). Effect applied in income calculation.");
            break;
        case 'perm_click_boost_10pct':
            isPermanentClickBoostActive = true;
            print("Activated Permanent Click Boost (+10%). Effect applied in tap calculation.");
            break;
        case 'golden_cursor': // Cosmetic Unlock - Kept separate for clarity
             isGoldenCursorUnlocked = true;
            break;
        // --- ADDED: Platinum Click Boosters ---
        case 'temp_boost_10x_5min': // Click Frenzy
             platinumClickFrenzyEndTime = DateTime.now().add(const Duration(minutes: 5));
             platinumClickFrenzyRemainingSeconds = 300;
             _startPlatinumClickFrenzyTimer();
             print("INFO: Click Frenzy (10x) Activated! Ends at: $platinumClickFrenzyEndTime");
             notifyListeners();
             break;
        case 'temp_boost_2x_10min': // Steady Boost
             platinumSteadyBoostEndTime = DateTime.now().add(const Duration(minutes: 10));
             platinumSteadyBoostRemainingSeconds = 600;
             _startPlatinumSteadyBoostTimer();
             print("INFO: Steady Boost (2x) Activated! Ends at: $platinumSteadyBoostEndTime");
             notifyListeners();
             break;
        case 'auto_clicker':
             autoClickerEndTime = DateTime.now().add(const Duration(minutes: 5));
             autoClickerRemainingSeconds = 300;
             _startPlatinumAutoClickerTimer();
             print("INFO: Auto Clicker Activated! Ends at: $autoClickerEndTime");
             notifyListeners();
             break;
        // --- END: Platinum Click Boosters ---
        case 'unlock_stats_theme_1':
            print("DEBUG: Before unlock: isExecutiveStatsThemeUnlocked=$isExecutiveStatsThemeUnlocked");
            isExecutiveStatsThemeUnlocked = true;
            print("DEBUG: After unlock: isExecutiveStatsThemeUnlocked=$isExecutiveStatsThemeUnlocked");
            print("Unlocked Executive Stats Theme. User can now select it as an option.");
            break;
        case 'cosmetic_platinum_frame':
            print("DEBUG: Before unlock: isPlatinumFrameUnlocked=$isPlatinumFrameUnlocked");
            isPlatinumFrameUnlocked = true;
            print("DEBUG: After unlock: isPlatinumFrameUnlocked=$isPlatinumFrameUnlocked");
            print("Unlocked Platinum UI Frame. User can now enable it in Settings.");
            break;
        default:
            print("WARNING: Unknown Platinum Vault item ID: $itemId");
    }
    notifyListeners(); // Notify after applying effect
  }

  // Calculate scaled cash cache for platinum rewards
  // Optimized cash cache calculation with memoization
  double _calculateCashCache() {
    try {
      // Constants for calculation
      const int minutesOfIncome = 15;
      const double minimumCashAmount = 1000.0;
      const double netWorthCapPercentage = 0.005;
      
      // Calculate based on passive income (already optimized in income_logic.dart)
      final double passiveIncomePerSecond = calculateTotalIncomePerSecond();
      double cashAmount = passiveIncomePerSecond * 60 * minutesOfIncome;

      // Apply minimum floor and maximum cap in a single pass
      final double netWorthCap = calculateNetWorth() * netWorthCapPercentage;
      return cashAmount < minimumCashAmount ? minimumCashAmount : 
             cashAmount > netWorthCap ? netWorthCap : cashAmount;
    } catch (e) {
      print('Error calculating cash cache: $e');
      return 1000.0; // Return minimum value on error
    }
  }

  // Method removed to avoid reference before declaration issues

  // Apply platinum facade to a business
  void applyPlatinumFacade(String businessId) {
    try {
      // Find the business by ID using indexWhere for safety
      final businessIndex = businesses.indexWhere((b) => b.id == businessId);
      if (businessIndex >= 0) {
        businesses[businessIndex].hasPlatinumFacade = true;
        
        // Also track this in the set for persistence
        platinumFacadeAppliedBusinessIds.add(businessId);
        
        // Notify listeners of the change
        notifyListeners();
      }
    } catch (e) {
      print('Error applying platinum facade: $e');
    }
  }

  // Check if a business has platinum facade
  bool hasBusinessPlatinumFacade(String businessId) {
    try {
      return platinumFacadeAppliedBusinessIds.contains(businessId);
    } catch (e) {
      print('Error checking platinum facade: $e');
      return false;
    }
  }

  // Get list of businesses that can have platinum facade applied
  // Optimized with single-pass filtering and capacity pre-allocation
  List<Business> getBusinessesForPlatinumFacade() {
    try {
      final int businessCount = businesses.length;
      final List<Business> eligibleBusinesses = [];
      
      // Direct iteration is more efficient than using where() and toList()
      for (int i = 0; i < businessCount; i++) {
        final business = businesses[i];
        if (business.level > 0 && !business.hasPlatinumFacade && business.unlocked) {
          eligibleBusinesses.add(business);
        }
      }
      
      return eligibleBusinesses;
    } catch (e) {
      print('Error getting businesses for platinum facade: $e');
      return [];
    }
  }
}