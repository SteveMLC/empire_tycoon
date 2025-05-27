part of '../game_state.dart';

// Contains methods related to Investments and Market Events
extension InvestmentLogic on GameState {

  // Buy an investment
  bool buyInvestment(String investmentId, int quantity) {
    int index = investments.indexWhere((i) => i.id == investmentId);
    if (index == -1 || quantity <= 0) return false;

    Investment investment = investments[index];
    double cost = investment.currentPrice * quantity;

    // Check if player has enough money AND if enough shares are available
    if (money >= cost && quantity <= investment.availableShares) { // Use the availableShares getter
      money -= cost;
      investment.updatePurchasePrice(cost, quantity);
      investment.owned += quantity;

      notifyListeners();
      return true;
    }

    return false;
  }

  // Sell an investment
  bool sellInvestment(String investmentId, int quantity) {
    int index = investments.indexWhere((i) => i.id == investmentId);
    if (index == -1 || quantity <= 0) return false;

    Investment investment = investments[index];

    if (investment.owned >= quantity) {
      double saleAmount = investment.currentPrice * quantity;
      money += saleAmount;

      // Calculate profit/loss for stats using the average purchase price for the quantity sold
      double costOfSoldShares = investment.purchasePrice * quantity;
      double profitLoss = saleAmount - costOfSoldShares;
      investmentEarnings += profitLoss;

      // Adjust owned quantity
      investment.owned -= quantity;

      // If sold all, reset average purchase price to 0
      if (investment.owned == 0) {
        investment.purchasePrice = 0.0; // Reset purchase price when all shares are sold
      }

      notifyListeners();
      return true;
    }

    return false;
  }

  // Get list of investment holdings with purchase info
  List<InvestmentHolding> getInvestmentHoldings() {
    List<InvestmentHolding> holdings = [];
    for (Investment investment in investments) {
      if (investment.owned > 0) {
        holdings.add(InvestmentHolding(
          investmentId: investment.id,
          purchasePrice: investment.purchasePrice, // Average purchase price
          shares: investment.owned,
        ));
      }
    }
    return holdings;
  }

  // Get total value of investment portfolio
  double getTotalInvestmentValue() {
    double total = 0.0;
    for (Investment investment in investments) {
      if (investment.owned > 0) {
        total += investment.currentPrice * investment.owned;
      }
    }
    return total;
  }

  // Get a specific investment holding
  InvestmentHolding? getInvestmentHolding(String investmentId) {
    int index = investments.indexWhere((i) => i.id == investmentId && i.owned > 0);
    if (index >= 0) {
       final investment = investments[index];
       return InvestmentHolding(
          investmentId: investment.id,
          purchasePrice: investment.purchasePrice,
          shares: investment.owned,
        );
    }
    return null; // Return null if not found or not owned
  }

  // Update investment prices more frequently (e.g., every 30 seconds) - optimized for memory efficiency
  void _updateInvestmentPrices() {
    for (var investment in investments) {
      // Apply random price change based on volatility and trend
      double change = investment.trend * 0.2; // Base trend (reduced impact)

      // Add random component based on volatility
      change += (Random().nextDouble() * 2 - 1) * investment.volatility * 0.3;

      // Ensure price doesn't go below minimum threshold
      double newPrice = investment.currentPrice * (1 + change);
      if (newPrice < investment.basePrice * 0.1) {
        newPrice = investment.basePrice * 0.1;
      }

      // Cap maximum price to avoid excessive growth
      double maxPrice = investment.basePrice * 10;
      if (newPrice > maxPrice) {
        newPrice = maxPrice;
      }

      investment.currentPrice = newPrice;

      // Use the optimized method to add price to history
      investment.addPriceHistoryPoint(investment.currentPrice);
    }

    // Notify listeners to update UI
    notifyListeners();
  }

  // Update investment prices on new day (also handles daily market events) - optimized for memory efficiency
  void _updateInvestments() {
    // Generate market events with a small chance
    _generateMarketEvents();

    // Process auto-investments if enabled
    _processAutoInvestments();
    
    // Then update prices for all investments
    for (var investment in investments) {
      // Apply random price change based on volatility and trend
      double change = investment.trend * 0.5; // Base trend
      
      // Add random component based on volatility
      change += (Random().nextDouble() * 2 - 1) * investment.volatility;
      
      // Ensure price doesn't go below minimum threshold
      double newPrice = investment.currentPrice * (1 + change);
      if (newPrice < investment.basePrice * 0.1) {
        newPrice = investment.basePrice * 0.1;
      }
      
      // Cap maximum price to avoid excessive growth
      double maxPrice = investment.basePrice * 10;
      if (newPrice > maxPrice) {
        newPrice = maxPrice;
      }
      
      investment.currentPrice = newPrice;
      
      // Apply market event effects if any are active
      _applyMarketEventEffects(investment);
      
      // Use the optimized method to add price to history
      investment.addPriceHistoryPoint(investment.currentPrice);
    }
    // Price history and notification is handled by _updateInvestmentPrices
  }

  // Generate random market events
  void _generateMarketEvents() {
    // Small chance to generate a new market event
    if (Random().nextDouble() < 0.15) { // 15% chance per day
      // Create a random market event
      MarketEvent newEvent = _createRandomMarketEvent(); // Use constructor if it's a class
      activeMarketEvents.add(newEvent);
      print("📈 Market Event Generated: ${newEvent.name} (${newEvent.durationDays} days)");
    }

    // Decrease remaining days for active events and remove expired ones
    List<MarketEvent> expiredEvents = [];
    for (int i = activeMarketEvents.length - 1; i >= 0; i--) {
      activeMarketEvents[i].remainingDays--;
      if (activeMarketEvents[i].remainingDays <= 0) {
        expiredEvents.add(activeMarketEvents.removeAt(i));
      }
    }
    if (expiredEvents.isNotEmpty) {
        // Correctly access name property
        print("📉 Market Event Expired: ${expiredEvents.map((e) => e.name).join(', ')}");
    }
  }

  // Apply market event effects to an investment
  void _applyMarketEventEffects(Investment investment) {
    for (MarketEvent event in activeMarketEvents) { // Use MarketEvent type
      // Apply impact if the investment's category is affected
      if (event.categoryImpacts.containsKey(investment.category)) {
        double impact = event.categoryImpacts[investment.category]!;
        // Apply impact multiplicatively
        investment.currentPrice *= impact;
        // Ensure price doesn't drop below minimum after event impact
        if (investment.currentPrice < investment.basePrice * 0.1) {
           investment.currentPrice = investment.basePrice * 0.1;
        }
         // Cap maximum price after event impact
        double maxPrice = investment.basePrice * 10;
        if (investment.currentPrice > maxPrice) {
           investment.currentPrice = maxPrice;
        }
      }
    }
  }

  // Create a random market event
  MarketEvent _createRandomMarketEvent() {
    List<String> eventTypes = [
      'boom',
      'crash',
      'volatility',
      'regulation',
      'innovation'
    ];

    String eventType = eventTypes[Random().nextInt(eventTypes.length)];

    switch (eventType) {
      case 'boom':
        return _createBoomEvent();
      case 'crash':
        return _createCrashEvent();
      case 'volatility':
        return _createVolatilityEvent();
      case 'regulation':
        return _createRegulationEvent();
      case 'innovation':
        return _createInnovationEvent();
      default:
        return _createBoomEvent(); // Default fallback
    }
  }

  // Create a market boom event
  MarketEvent _createBoomEvent() {
    List<String> categories = _getInvestmentCategories();
    if (categories.isEmpty) return _createInnovationEvent(); // Fallback if no categories

    int numCategories = Random().nextInt(2) + 1; // 1-2 categories
    List<String> affectedCategories = [];
    List<String> availableCategories = List.from(categories); // Copy to modify

    for (int i = 0; i < numCategories; i++) {
      if (availableCategories.isNotEmpty) {
        int index = Random().nextInt(availableCategories.length);
        affectedCategories.add(availableCategories.removeAt(index));
      }
    }

    if (affectedCategories.isEmpty) return _createInnovationEvent(); // Fallback

    Map<String, double> impacts = {};
    for (String category in affectedCategories) {
      double impactValue = 1.0 + (Random().nextDouble() * 0.06 + 0.02); // 1.02 to 1.08
      impacts[category] = impactValue;
    }

    String primaryCategory = affectedCategories.first;
    return MarketEvent( // Use constructor
      name: '$primaryCategory Boom',
      description: 'A market boom is happening in the $primaryCategory sector!',
      categoryImpacts: impacts,
      durationDays: Random().nextInt(3) + 2, // 2-4 days
    );
  }

  // Create a market crash event
  MarketEvent _createCrashEvent() {
    List<String> categories = _getInvestmentCategories();
    if (categories.isEmpty) return _createRegulationEvent(); // Fallback

    int numCategories = Random().nextInt(2) + 1; // 1-2 categories
    List<String> affectedCategories = [];
     List<String> availableCategories = List.from(categories); // Copy to modify

    for (int i = 0; i < numCategories; i++) {
      if (availableCategories.isNotEmpty) {
        int index = Random().nextInt(availableCategories.length);
        affectedCategories.add(availableCategories.removeAt(index));
      }
    }

     if (affectedCategories.isEmpty) return _createRegulationEvent(); // Fallback

    Map<String, double> impacts = {};
    for (String category in affectedCategories) {
      double impactValue = 1.0 - (Random().nextDouble() * 0.06 + 0.02); // 0.98 down to 0.92
      impacts[category] = impactValue;
    }

    String primaryCategory = affectedCategories.first;
    return MarketEvent( // Use constructor
      name: '$primaryCategory Crash',
      description: 'A market crash is affecting the $primaryCategory sector!',
      categoryImpacts: impacts,
      durationDays: Random().nextInt(3) + 2, // 2-4 days
    );
  }

  // Create a market volatility event
  MarketEvent _createVolatilityEvent() {
    List<String> categories = _getInvestmentCategories();
    if (categories.isEmpty) return _createInnovationEvent(); // Fallback

    String category = categories[Random().nextInt(categories.length)];

    // Volatility implies bigger daily swings, can be up or down
    double initialImpact = Random().nextBool() ? 1.1 : 0.9; // Start with +/- 10%
    Map<String, double> impacts = { category: initialImpact };

    return MarketEvent( // Use constructor
      name: 'Market Volatility',
      description: 'The $category market is experiencing high volatility!',
      categoryImpacts: impacts, // Initial impact, real effect is daily random swing
      durationDays: Random().nextInt(5) + 3, // 3-7 days
    );
  }

  // Create a regulation event
  MarketEvent _createRegulationEvent() {
     List<String> categories = _getInvestmentCategories();
     if (categories.isEmpty) return _createCrashEvent(); // Fallback

    String category = categories[Random().nextInt(categories.length)];

    // Regulations typically cause a slight decline
    Map<String, double> impacts = { category: 0.97 }; // 3% decline factor daily

    return MarketEvent( // Use constructor
      name: 'New Regulations',
      description: 'New regulations are affecting the $category sector.',
      categoryImpacts: impacts,
      durationDays: Random().nextInt(3) + 5, // 5-7 days (longer impact)
    );
  }

  // Create an innovation event
  MarketEvent _createInnovationEvent() {
    List<String> categories = _getInvestmentCategories();
    if (categories.isEmpty) return _createBoomEvent(); // Fallback

    String category = categories[Random().nextInt(categories.length)];

    // Innovation causes growth
    Map<String, double> impacts = { category: 1.05 }; // 5% growth factor daily

    return MarketEvent( // Use constructor
      name: 'Technological Breakthrough',
      description: 'A breakthrough innovation is boosting the $category sector!',
      categoryImpacts: impacts,
      durationDays: Random().nextInt(5) + 3, // 3-7 days
    );
  }

  // Helper method to get the list of unique investment categories
  List<String> _getInvestmentCategories() {
    // Use a Set to automatically handle uniqueness
    return investments.map((investment) => investment.category).toSet().toList();
  }

  // Calculate diversification bonus based on owned investments across categories
  double calculateDiversificationBonus() {
    // Count unique categories among owned investments
    Set<String> ownedCategories = investments
        .where((investment) => investment.owned > 0)
        .map((investment) => investment.category)
        .toSet();

    // Calculate bonus (e.g., 2% per unique category owned)
    double bonusPerCategory = 0.02;
    return ownedCategories.length * bonusPerCategory;
  }

  // Process auto-investments
  void _processAutoInvestments() {
    for (var investment in investments) {
      if (investment.autoInvestEnabled && investment.autoInvestAmount > 0) {
        // Ensure we don't try to invest more than we have
        double amountToInvest = min(money, investment.autoInvestAmount);

        // Calculate how many shares can be purchased with the available amount
        if (investment.currentPrice > 0) { // Avoid division by zero
          int quantity = (amountToInvest / investment.currentPrice).floor();

          // Purchase if possible (quantity > 0)
          if (quantity > 0) {
            buyInvestment(investment.id, quantity);
          }
        }
      }
    }
  }

  // Add micro-updates to investment prices for more dynamic chart movement - optimized for memory efficiency
  void _updateInvestmentPricesMicro() {
    bool changed = false;
    for (var investment in investments) {
      // Apply smaller random price change based on volatility and trend
      double change = investment.trend * 0.05; // Reduced base trend impact

      // Add smaller random component based on volatility
      change += (Random().nextDouble() * 2 - 1) * investment.volatility * 0.1;

      // Apply the change to current price
      double newPrice = investment.currentPrice * (1 + change);
      
      // Apply min/max bounds
      double minPrice = investment.basePrice * 0.1;
      double maxPrice = investment.basePrice * 10;
      newPrice = newPrice.clamp(minPrice, maxPrice);

      // Only update if the price change is significant enough
      if ((newPrice - investment.currentPrice).abs() > 0.001) {
          investment.currentPrice = newPrice;
          changed = true;

          // Use the optimized method to update the latest price point
          investment.updateLatestPricePoint(investment.currentPrice);
      }
    }
    // Notify only if any price actually changed - This might be too frequent, handled in main update loop
    // if (changed) {
    //    notifyListeners();
    // }
  }

  // Function to get the total investment dividend income per second
  double getDividendIncomePerSecond() {
    double total = 0.0;
    double diversificationBonus = calculateDiversificationBonus(); // Calculate once
    double portfolioMultiplier = isPlatinumPortfolioActive ? 1.25 : 1.0;
    
    for (var investment in investments) {
      if (investment.owned > 0 && investment.hasDividends()) {
        // Get base dividend per second for this investment
        double baseDividend = investment.getDividendIncomePerSecond();
        
        // Apply portfolio multiplier and diversification bonus
        double adjustedDividend = baseDividend * portfolioMultiplier * (1 + diversificationBonus);
        
        // Apply owned count
        double totalDividendForInvestment = adjustedDividend * investment.owned;
        
        // Apply global income multiplier
        totalDividendForInvestment *= incomeMultiplier;
        
        // Apply permanent income boost if active
        if (isPermanentIncomeBoostActive) {
          totalDividendForInvestment *= 1.05;
        }
        
        // Apply income surge if active
        if (isIncomeSurgeActive) {
          totalDividendForInvestment *= 2.0;
        }
        
        total += totalDividendForInvestment;
      }
    }
    
    return total;
  }

  // Method to update investment unlocks based on money, prestige level, and platinum unlocks
  void _updateInvestmentUnlocks() {
    // First, make sure all investments are initially locked
    for (var investment in investments) {
      investment.unlocked = false;
    }

    // Stocks unlock progressively with money
    if (money >= 250) {
      // Unlock first stock - NexTech
      final nxtIndex = investments.indexWhere((i) => i.id == 'nxt');
      if (nxtIndex >= 0) investments[nxtIndex].unlocked = true;
    }
    
    if (money >= 1000) {
      // Unlock second stock - GreenVolt
      final grvIndex = investments.indexWhere((i) => i.id == 'grv');
      if (grvIndex >= 0) investments[grvIndex].unlocked = true;
    }
    
    if (money >= 2500) {
      // Unlock third stock - MegaFreight
      final mftIndex = investments.indexWhere((i) => i.id == 'mft');
      if (mftIndex >= 0) investments[mftIndex].unlocked = true;
    }
    
    if (money >= 10000) {
      // Unlock fourth stock - LuxWear
      final lxwIndex = investments.indexWhere((i) => i.id == 'lxw');
      if (lxwIndex >= 0) investments[lxwIndex].unlocked = true;
    }
    
    if (money >= 25000) {
      // Unlock fifth stock - StarForge
      final stfIndex = investments.indexWhere((i) => i.id == 'stf');
      if (stfIndex >= 0) investments[stfIndex].unlocked = true;
    }
    
    // Cryptocurrencies unlock based on higher money thresholds
    if (money >= 50000) {
      // Unlock first crypto - BitCoinLite
      final bclIndex = investments.indexWhere((i) => i.id == 'bcl');
      if (bclIndex >= 0) investments[bclIndex].unlocked = true;
    }
    
    if (money >= 100000) {
      // Unlock second crypto - EtherCore
      final etcIndex = investments.indexWhere((i) => i.id == 'etc');
      if (etcIndex >= 0) investments[etcIndex].unlocked = true;
    }
    
    if (money >= 250000) {
      // Unlock third crypto - MoonToken
      final mtkIndex = investments.indexWhere((i) => i.id == 'mtk');
      if (mtkIndex >= 0) investments[mtkIndex].unlocked = true;
    }
    
    if (money >= 500000) {
      // Unlock fourth crypto - StableX
      final sbxIndex = investments.indexWhere((i) => i.id == 'sbx');
      if (sbxIndex >= 0) investments[sbxIndex].unlocked = true;
    }
    
    if (money >= 1000000) {
      // Unlock fifth crypto - QuantumBit
      final qbtIndex = investments.indexWhere((i) => i.id == 'qbt');
      if (qbtIndex >= 0) investments[qbtIndex].unlocked = true;
    }
    
    // If platinum stock is unlocked, ensure it's available
    if (isPlatinumStockUnlocked) {
      final platIndex = investments.indexWhere((i) => i.id == 'plt');
      if (platIndex >= 0) investments[platIndex].unlocked = true;
    }
  }
} 