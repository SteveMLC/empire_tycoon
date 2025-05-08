part of '../game_state.dart';

extension PlatinumLogic on GameState {
  // Methods for managing platinum points and vault items
  void awardPlatinumPoints(int amount) {
    if (amount <= 0) return;
    platinumPoints += amount;
    showPPAnimation = true; // Trigger animation
    notifyListeners();
    // Optional: Set a timer to turn off the animation flag after a short duration
    Timer(const Duration(seconds: 3), () {
      showPPAnimation = false;
      notifyListeners();
    });
  }

  bool spendPlatinumPoints(String itemId, int cost, {Map<String, dynamic>? purchaseContext}) {
    DateTime now = DateTime.now(); // Get current time for checks

    // Check if affordable
    if (platinumPoints < cost) {
        print("DEBUG: Cannot afford item $itemId. Cost: $cost, Have: $platinumPoints");
        return false; // Not enough PP
    }

    // Check ownership for one-time items (before cooldowns)
    if (ppOwnedItems.contains(itemId)) {
        print("DEBUG: Item $itemId already owned (one-time purchase).");
        return false; // Already owned
    }

    // --- Specific Cooldown/Limit/Active Checks ---
    switch (itemId) {
        case 'platinum_surge':
            if (isIncomeSurgeActive) {
                print("DEBUG: Cannot purchase $itemId: Already active.");
                return false; // Prevent purchase if already active
            }
            if (incomeSurgeCooldownEnd != null && now.isBefore(incomeSurgeCooldownEnd!)) {
                print("DEBUG: Cannot purchase $itemId: On cooldown until $incomeSurgeCooldownEnd.");
                return false; // On cooldown
            }
            break;
        case 'platinum_cache':
            if (cashCacheCooldownEnd != null && now.isBefore(cashCacheCooldownEnd!)) {
                print("DEBUG: Cannot purchase $itemId: On cooldown until $cashCacheCooldownEnd.");
                return false; // On cooldown
            }
            break;
        case 'platinum_warp':
            _checkAndResetTimeWarpLimit(now); // Ensure weekly limit is current
            if (timeWarpUsesThisPeriod >= 2) {
                print("DEBUG: Cannot purchase $itemId: Weekly limit (2) reached.");
                return false; // Limit reached
            }
            break;
        case 'platinum_shield':
            if (isDisasterShieldActive) {
                 print("DEBUG: Cannot purchase $itemId: Already active.");
                 return false; // Already active, don't allow stacking/extending for now
            }
            break;
        case 'platinum_accelerator':
            if (isCrisisAcceleratorActive) {
                 print("DEBUG: Cannot purchase $itemId: Already active.");
                 return false; // Already active, don't allow stacking/extending for now
            }
            break;
        case 'temp_boost_10x_5min':
            if (isClickFrenzyActive) {
                print("DEBUG: Cannot purchase $itemId: Already active.");
                return false; // Prevent stacking
            }
            if (isSteadyBoostActive) {
                 print("DEBUG: Cannot purchase $itemId: Another Platinum booster (Steady Boost) is active.");
                 return false; // Prevent running both simultaneously
            }
            break;
        case 'temp_boost_2x_10min':
            if (isSteadyBoostActive) {
                print("DEBUG: Cannot purchase $itemId: Already active.");
                return false; // Prevent stacking
            }
             if (isClickFrenzyActive) {
                 print("DEBUG: Cannot purchase $itemId: Another Platinum booster (Click Frenzy) is active.");
                 return false; // Prevent running both simultaneously
            }
            break;
        case 'platinum_foundation':
             // Check global limit
             if (platinumFoundationsApplied.length >= 5) {
                 print("DEBUG: Cannot apply Foundation: Maximum limit (5) reached.");
                 return false;
             }
             // Check if the specific locale (passed in context) is already boosted
             String? selectedLocaleId = purchaseContext?['selectedLocaleId'] as String?;
             if (selectedLocaleId == null) {
                  print("ERROR: No locale ID provided for Platinum Foundation purchase.");
                  return false; // Need locale context
             }
             if (platinumFoundationsApplied.containsKey(selectedLocaleId)) {
                 print("DEBUG: Cannot apply Foundation: Locale $selectedLocaleId already has one.");
                 // Assuming 1 per locale limit for now
                 return false;
             }
             break;
    }
    // --- End specific checks ---

    // If all checks passed, proceed with purchase
    platinumPoints -= cost;

    // Apply the actual effect of the item based on itemId, passing context and current time
    _applyVaultItemEffect(itemId, now, purchaseContext);

    // Track purchase - distinguish one-time vs repeatable
    var itemDefinition = getVaultItems().firstWhere((item) => item.id == itemId, orElse: () => VaultItem(id: 'unknown', name: 'Unknown', description: '', category: VaultItemCategory.cosmetics, type: VaultItemType.oneTime, cost: 0));
    // Check if one-time item
    if (itemDefinition.type == VaultItemType.oneTime) {
        ppOwnedItems.add(itemId);
        print("DEBUG: Added $itemId to owned one-time items list.");
        
        // Special case handling for specific items
        switch (itemId) {
            case 'platinum_spire':
                // This will be fully handled in the _applyVaultItemEffect method
                // which sets the platinumSpireLocaleId based on context
                break;
            // Add other special cases as needed
        }
    } else { 
        // For repeatable items, increment purchase count
        ppPurchases[itemId] = (ppPurchases[itemId] ?? 0) + 1;
        print("DEBUG: Updated ${itemId} purchase count to ${ppPurchases[itemId]}.");
    }

    notifyListeners();
    return true;
  }

  void _checkAndResetTimeWarpLimit(DateTime now) {
    if (lastTimeWarpReset == null) {
      // First use ever, set the reset time to next week (e.g., next Monday)
      lastTimeWarpReset = TimeUtils.findNextWeekday(now, DateTime.monday);
      timeWarpUsesThisPeriod = 0;
       print("Time Warp: Initializing weekly limit. Resets on $lastTimeWarpReset");
    } else if (now.isAfter(lastTimeWarpReset!)) {
      // It's past the reset time, reset the counter and set the next reset time
      int periodsPassed = now.difference(lastTimeWarpReset!).inDays ~/ 7;
      lastTimeWarpReset = TimeUtils.findNextWeekday(lastTimeWarpReset!.add(Duration(days: (periodsPassed + 1) * 7)), DateTime.monday);
      timeWarpUsesThisPeriod = 0;
      print("Time Warp: Weekly limit reset. Uses reset to 0. Next reset: $lastTimeWarpReset");
    }
    // Otherwise, the limit is still valid for the current week
  }

  void _applyVaultItemEffect(String itemId, DateTime purchaseTime, Map<String, dynamic>? purchaseContext) {
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
            double fourHoursInSeconds = 4.0 * 60 * 60; // 4 hours in seconds
            double incomeAward = incomePerSecond * fourHoursInSeconds;
            
            if (incomeAward > 0) {
                money += incomeAward;
                totalEarned += incomeAward;
                passiveEarnings += incomeAward; // Attribute to passive
                print("INFO: Awarded ${NumberFormatter.formatCompact(incomeAward)} via Income Warp (4 hours of income).");
                // TODO: Add user-facing notification.
            } else {
                print("INFO: Income Warp: No income calculated (income/sec might be zero).");
            }
            timeWarpUsesThisPeriod++; // Increment usage count
            print("INFO: Income Warp uses this period: $timeWarpUsesThisPeriod/2");
            // notifyListeners(); // Called at the end of the method
            break;
        case 'platinum_cache':
             // Pre-check in spendPlatinumPoints ensures not on cooldown
             double cashAward = _calculateScaledCashCache(); // Use helper for scaling
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

  double _calculateScaledCashCache() {
    // Example scaling: 15 minutes of current passive income?
    // Or based on total earned, net worth, etc.
    // Let's use 15 minutes of total passive income per second for now.
    double passiveIncomePerSecond = calculateTotalIncomePerSecond(); // Use the detailed calculation
    double cashAmount = passiveIncomePerSecond * 60 * 15; // 15 minutes worth

    // Add a small floor value and potentially cap it?
    cashAmount = max(cashAmount, 1000.0); // Minimum $1k
    // Example cap: Maybe 1% of current money or net worth?
    // cashAmount = min(cashAmount, money * 0.01); // Cap at 1% of current cash (can be low)
    // cashAmount = min(cashAmount, calculateNetWorth() * 0.005); // Cap at 0.5% of net worth

    print("Calculating Cash Cache: Passive/sec=$passiveIncomePerSecond, Base Award=$cashAmount");
    return cashAmount;
  }

  void _addPlatinumStockInvestment() {
      investments.add(Investment(
          id: 'platinum_stock',
          name: 'Quantum Computing Inc.',
          description: 'High-risk, high-reward venture in quantum computing.',
          currentPrice: 1000000000.0, // 1B per share
          basePrice: 1000000000.0,
          volatility: 0.40, // High volatility
          trend: 0.06, // High potential trend
          owned: 0,
          icon: Icons.memory, // Placeholder icon
          color: Colors.cyan,
          priceHistory: List.generate(30, (i) => 1000000000.0 * (0.95 + (Random().nextDouble() * 0.1))), // Wider random range
          category: 'Technology',// Or a unique category like 'Quantum'
          dividendPerSecond: 1750000, // 1.75 million per second
          marketCap: 4.0e12, // 4 Trillion market cap
          // Potentially add a high dividend yield as well for extra reward/risk
          // dividendPerSecond: 50000.0, // Example: 50k/sec per share
      ));
  }

  // Apply platinum facade to a business
  void applyPlatinumFacade(String businessId) {
    // Find the business by ID
    final businessIndex = businesses.indexWhere((b) => b.id == businessId);
    if (businessIndex >= 0) {
      businesses[businessIndex].hasPlatinumFacade = true;
      
      // Also track this in the set for persistence
      platinumFacadeAppliedBusinessIds.add(businessId);
      
      // Notify listeners of the change
      notifyListeners();
    }
  }

  // Check if a business has platinum facade
  bool hasBusinessPlatinumFacade(String businessId) {
    return platinumFacadeAppliedBusinessIds.contains(businessId);
  }

  // Get list of businesses that can have platinum facade applied
  List<Business> getBusinessesForPlatinumFacade() {
    // Only return businesses that are owned (level > 0) and don't already have the facade
    return businesses.where((b) => b.level > 0 && !b.hasPlatinumFacade && b.unlocked).toList();
  }
} 