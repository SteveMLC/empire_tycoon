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

  // COMPLETELY OVERHAULED: Realistic market price updates with cycles and corrections
  void _updateInvestmentPrices() {
    // Calculate market-wide sentiment (affects all investments)
    double marketSentiment = _calculateMarketSentiment();
    
    for (var investment in investments) {
      // Update trend system with enhanced realism
      investment.updateTrend();
      
      double change = 0.0;
      
      // 1. Base trend impact (reduced and neutralized over time)
      double baseTrendImpact = investment.currentTrend * 0.03; // Much reduced from 0.25
      change += baseTrendImpact;
      
      // 2. Market sentiment impact (market-wide effects)
      double sentimentImpact = marketSentiment * investment.volatility * 0.15;
      change += sentimentImpact;
      
      // 3. Individual stock volatility (pure random walk)
      double volatilityImpact = (Random().nextDouble() * 2 - 1.0) * investment.volatility * 0.08;
      change += volatilityImpact;
      
      // 4. Strong mean reversion towards base price over time
      double priceRatio = investment.currentPrice / investment.basePrice;
      double meanReversionStrength = 0.02; // Stronger reversion
      
      if (priceRatio > 1.2) {
        // Above base price - pull down
        change -= meanReversionStrength * (priceRatio - 1.0);
      } else if (priceRatio < 0.8) {
        // Below base price - pull up  
        change += meanReversionStrength * (1.0 - priceRatio);
      }
      
      // 5. Long-term economic growth (very small positive bias)
      change += 0.0005; // 0.05% positive drift per update (realistic long-term growth)
      
      // 6. Apply price boundaries with resistance
      double newPrice = investment.currentPrice * (1 + change);
      double minPrice = investment.basePrice * 0.3; // Prevent total collapse
      double maxPrice = investment.basePrice * 4.0; // Prevent extreme bubbles
      
      // Add resistance near boundaries
      if (newPrice > investment.basePrice * 3.0) {
        // Strong downward pressure near max
        change -= 0.02;
        newPrice = investment.currentPrice * (1 + change);
      } else if (newPrice < investment.basePrice * 0.5) {
        // Strong upward pressure near min
        change += 0.02;
        newPrice = investment.currentPrice * (1 + change);
      }
      
      investment.currentPrice = newPrice.clamp(minPrice, maxPrice);
      investment.addPriceHistoryPoint(investment.currentPrice);
    }
    
    notifyListeners();
  }

  // Helper function to calculate day of year
  int _getDayOfYear(DateTime date) {
    DateTime startOfYear = DateTime(date.year, 1, 1);
    return date.difference(startOfYear).inDays + 1;
  }

  // NEW: Calculate overall market sentiment
  double _calculateMarketSentiment() {
    // Create market cycles with different periods for each category
    DateTime now = DateTime.now();
    double dayOfYear = _getDayOfYear(now).toDouble();
    double hourOfDay = now.hour.toDouble();
    
    // Primary market cycle (7-14 day periods)
    double primaryCycle = sin((dayOfYear / 10.0) * 2 * pi) * 0.3;
    
    // Secondary cycle (shorter 2-3 day periods)  
    double secondaryCycle = sin((dayOfYear / 2.5) * 2 * pi) * 0.15;
    
    // Intraday cycle (daily variation)
    double intradayCycle = sin((hourOfDay / 24.0) * 2 * pi) * 0.05;
    
    // Random market shocks (5% chance of significant event)
    double marketShock = 0.0;
    if (Random().nextDouble() < 0.05) {
      marketShock = (Random().nextDouble() * 2 - 1.0) * 0.2; // ±20% shock
    }
    
    double totalSentiment = primaryCycle + secondaryCycle + intradayCycle + marketShock;
    
    // Clamp to reasonable range
    return totalSentiment.clamp(-0.5, 0.5);
  }

  // ENHANCED: More realistic daily updates with market cycles
  void _updateInvestments() {
    _generateMarketEvents();
    _processAutoInvestments();
    
    // Major market cycle check (weekly/monthly patterns)
    _applyMarketCycleEffects();
    
    for (var investment in investments) {
      investment.updateTrend();
      
      double change = 0.0;
      
      // 1. Trend impact (more balanced)
      double trendImpact = investment.currentTrend * 0.08; // Reduced from 0.5
      change += trendImpact;
      
      // 2. Category-specific cycles
      double categoryEffect = _getCategoryEffect(investment.category);
      change += categoryEffect;
      
      // 3. Daily volatility (balanced random walk)
      double dailyVolatility = (Random().nextDouble() * 2 - 1.0) * investment.volatility * 0.2;
      change += dailyVolatility;
      
      // 4. Mean reversion (stronger for daily updates)
      double priceRatio = investment.currentPrice / investment.basePrice;
      if (priceRatio > 1.5) {
        change -= 0.05 * (priceRatio - 1.0); // Pull down if too high
      } else if (priceRatio < 0.7) {
        change += 0.05 * (1.0 - priceRatio); // Pull up if too low
      }
      
      // 5. Market events (reduced frequency, bigger impact)
      if (Random().nextDouble() < 0.15) { // 15% chance
        double eventMagnitude = (Random().nextDouble() * 2 - 1.0) * 0.08; // ±8%
        change += eventMagnitude;
      }
      
      // Apply change with boundaries
      double newPrice = investment.currentPrice * (1 + change);
      double minPrice = investment.basePrice * 0.3;
      double maxPrice = investment.basePrice * 4.0;
      investment.currentPrice = newPrice.clamp(minPrice, maxPrice);
      
      _applyMarketEventEffects(investment);
      investment.addPriceHistoryPoint(investment.currentPrice);
    }
  }

  // NEW: Category-specific market effects
  double _getCategoryEffect(String category) {
    DateTime now = DateTime.now();
    double dayOfYear = _getDayOfYear(now).toDouble();
    
    // Different categories have different cycle patterns
    switch (category) {
      case 'Technology':
        return sin((dayOfYear / 8.0) * 2 * pi) * 0.05; // 8-day cycle
      case 'Energy': 
        return sin((dayOfYear / 12.0) * 2 * pi) * 0.04; // 12-day cycle
      case 'Cryptocurrency':
        return sin((dayOfYear / 3.0) * 2 * pi) * 0.08; // 3-day cycle (more volatile)
      case 'Healthcare':
        return sin((dayOfYear / 15.0) * 2 * pi) * 0.03; // 15-day cycle (more stable)
      case 'Transportation':
        return sin((dayOfYear / 10.0) * 2 * pi) * 0.04; // 10-day cycle
      case 'Fashion':
        return sin((dayOfYear / 6.0) * 2 * pi) * 0.06; // 6-day cycle (trendy)
      case 'Aerospace':
        return sin((dayOfYear / 20.0) * 2 * pi) * 0.05; // 20-day cycle
      default:
        return sin((dayOfYear / 10.0) * 2 * pi) * 0.04; // Default 10-day cycle
    }
  }

  // NEW: Apply major market cycle effects (bear/bull markets)
  void _applyMarketCycleEffects() {
    DateTime now = DateTime.now();
    double dayOfYear = _getDayOfYear(now).toDouble();
    
    // Long-term market cycle (30-90 day periods)
    double longTermCycle = sin((dayOfYear / 60.0) * 2 * pi);
    
    // If we're in a bear market phase (negative cycle)
    if (longTermCycle < -0.3) {
      // Apply market correction (10% chance per day during bear market)
      if (Random().nextDouble() < 0.1) {
        for (var investment in investments) {
          double correctionMagnitude = Random().nextDouble() * 0.15; // Up to 15% correction
          investment.currentPrice *= (1.0 - correctionMagnitude);
          
          // Ensure we don't go below minimum
          double minPrice = investment.basePrice * 0.3;
          investment.currentPrice = investment.currentPrice.clamp(minPrice, double.infinity);
        }
        print("📉 Market Correction Applied: ${(longTermCycle * 100).toStringAsFixed(1)}% market sentiment");
      }
    }
    
    // If we're in a bull market phase (positive cycle)  
    else if (longTermCycle > 0.3) {
      // Occasional market rallies (5% chance per day during bull market)
      if (Random().nextDouble() < 0.05) {
        for (var investment in investments) {
          double rallyMagnitude = Random().nextDouble() * 0.1; // Up to 10% rally
          investment.currentPrice *= (1.0 + rallyMagnitude);
          
          // Ensure we don't exceed maximum
          double maxPrice = investment.basePrice * 4.0;
          investment.currentPrice = investment.currentPrice.clamp(0, maxPrice);
        }
        print("📈 Market Rally Applied: ${(longTermCycle * 100).toStringAsFixed(1)}% market sentiment");
      }
    }
  }

  // Generate random market events
  void _generateMarketEvents() {
    // Reduced frequency for more impactful events
    if (Random().nextDouble() < 0.15) { // 15% chance per day (reduced from 25%)
      MarketEvent newEvent = _createRandomMarketEvent();
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
      print("📉 Market Event Expired: ${expiredEvents.map((e) => e.name).join(', ')}");
    }
  }

  // Apply market event effects to an investment
  void _applyMarketEventEffects(Investment investment) {
    for (MarketEvent event in activeMarketEvents) {
      if (event.categoryImpacts.containsKey(investment.category)) {
        double impact = event.categoryImpacts[investment.category]!;
        // Apply impact multiplicatively but with reduced effect
        double adjustedImpact = 1.0 + ((impact - 1.0) * 0.3); // Reduce event impact by 70%
        investment.currentPrice *= adjustedImpact;
        
        // Ensure price bounds
        double minPrice = investment.basePrice * 0.3;
        double maxPrice = investment.basePrice * 4.0;
        investment.currentPrice = investment.currentPrice.clamp(minPrice, maxPrice);
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

  // Create a market boom event (REDUCED IMPACT)
  MarketEvent _createBoomEvent() {
    List<String> categories = _getInvestmentCategories();
    if (categories.isEmpty) return _createInnovationEvent();

    int numCategories = Random().nextInt(2) + 1; // 1-2 categories
    List<String> affectedCategories = [];
    List<String> availableCategories = List.from(categories);

    for (int i = 0; i < numCategories; i++) {
      if (availableCategories.isNotEmpty) {
        int index = Random().nextInt(availableCategories.length);
        affectedCategories.add(availableCategories.removeAt(index));
      }
    }

    if (affectedCategories.isEmpty) return _createInnovationEvent();

    Map<String, double> impacts = {};
    for (String category in affectedCategories) {
      double impactValue = 1.0 + (Random().nextDouble() * 0.03 + 0.01); // 1.01 to 1.04 (reduced)
      impacts[category] = impactValue;
    }

    String primaryCategory = affectedCategories.first;
    return MarketEvent(
      name: '$primaryCategory Boom',
      description: 'A market boom is happening in the $primaryCategory sector!',
      categoryImpacts: impacts,
      durationDays: Random().nextInt(4) + 3, // 3-6 days
    );
  }

  // Create a market crash event (REDUCED IMPACT)
  MarketEvent _createCrashEvent() {
    List<String> categories = _getInvestmentCategories();
    if (categories.isEmpty) return _createRegulationEvent();

    int numCategories = Random().nextInt(2) + 1; // 1-2 categories
    List<String> affectedCategories = [];
    List<String> availableCategories = List.from(categories);

    for (int i = 0; i < numCategories; i++) {
      if (availableCategories.isNotEmpty) {
        int index = Random().nextInt(availableCategories.length);
        affectedCategories.add(availableCategories.removeAt(index));
      }
    }

    if (affectedCategories.isEmpty) return _createRegulationEvent();

    Map<String, double> impacts = {};
    for (String category in affectedCategories) {
      double impactValue = 1.0 - (Random().nextDouble() * 0.03 + 0.01); // 0.99 down to 0.96 (reduced)
      impacts[category] = impactValue;
    }

    String primaryCategory = affectedCategories.first;
    return MarketEvent(
      name: '$primaryCategory Crash',
      description: 'A market crash is affecting the $primaryCategory sector!',
      categoryImpacts: impacts,
      durationDays: Random().nextInt(4) + 3, // 3-6 days
    );
  }

  // Create a market volatility event
  MarketEvent _createVolatilityEvent() {
    List<String> categories = _getInvestmentCategories();
    if (categories.isEmpty) return _createInnovationEvent();

    String category = categories[Random().nextInt(categories.length)];

    // Volatility implies bigger daily swings, can be up or down
    double initialImpact = Random().nextBool() ? 1.05 : 0.95; // Start with +/- 5% (reduced)
    Map<String, double> impacts = { category: initialImpact };

    return MarketEvent(
      name: 'Market Volatility',
      description: 'The $category market is experiencing high volatility!',
      categoryImpacts: impacts,
      durationDays: Random().nextInt(5) + 3, // 3-7 days
    );
  }

  // Create a regulation event
  MarketEvent _createRegulationEvent() {
    List<String> categories = _getInvestmentCategories();
    if (categories.isEmpty) return _createCrashEvent();

    String category = categories[Random().nextInt(categories.length)];

    // Regulations typically cause a slight decline
    Map<String, double> impacts = { category: 0.985 }; // 1.5% decline factor (reduced)

    return MarketEvent(
      name: 'New Regulations',
      description: 'New regulations are affecting the $category sector.',
      categoryImpacts: impacts,
      durationDays: Random().nextInt(3) + 5, // 5-7 days
    );
  }

  // Create an innovation event
  MarketEvent _createInnovationEvent() {
    List<String> categories = _getInvestmentCategories();
    if (categories.isEmpty) return _createBoomEvent();

    String category = categories[Random().nextInt(categories.length)];

    // Innovation causes growth
    Map<String, double> impacts = { category: 1.025 }; // 2.5% growth factor (reduced)

    return MarketEvent(
      name: 'Technological Breakthrough',
      description: 'A breakthrough innovation is boosting the $category sector!',
      categoryImpacts: impacts,
      durationDays: Random().nextInt(5) + 3, // 3-7 days
    );
  }

  // Helper method to get the list of unique investment categories
  List<String> _getInvestmentCategories() {
    return investments.map((investment) => investment.category).toSet().toList();
  }

  // Calculate diversification bonus based on owned investments across categories
  double calculateDiversificationBonus() {
    Set<String> ownedCategories = investments
        .where((investment) => investment.owned > 0)
        .map((investment) => investment.category)
        .toSet();

    double bonusPerCategory = 0.02;
    return ownedCategories.length * bonusPerCategory;
  }

  // Process auto-investments
  void _processAutoInvestments() {
    for (var investment in investments) {
      if (investment.autoInvestEnabled && investment.autoInvestAmount > 0) {
        double amountToInvest = min(money, investment.autoInvestAmount);

        if (investment.currentPrice > 0) {
          int quantity = (amountToInvest / investment.currentPrice).floor();

          if (quantity > 0) {
            buyInvestment(investment.id, quantity);
          }
        }
      }
    }
  }

  // ENHANCED: More balanced micro-updates
  void _updateInvestmentPricesMicro() {
    bool changed = false;
    for (var investment in investments) {
      double change = 0.0;
      
      // Much smaller trend impact for micro updates
      double trendImpact = investment.currentTrend * 0.005; // Reduced from 0.02
      change += trendImpact;
      
      // Gentle mean reversion
      double meanReversion = investment.getMeanReversionFactor() * 0.05; // Reduced from 0.1
      change += meanReversion;
      
      // Minimal random walk
      double volatilityMultiplier = investment.volatility * 0.01; // Reduced from 0.05
      double randomChange = (Random().nextDouble() * 2 - 1.0) * volatilityMultiplier;
      change += randomChange;
      
      double newPrice = investment.currentPrice * (1 + change);
      
      // Apply bounds
      double minPrice = investment.basePrice * 0.3;
      double maxPrice = investment.basePrice * 4.0;
      newPrice = newPrice.clamp(minPrice, maxPrice);
      
      // Only update if significant change (use percentage-based threshold for low-priced assets)
      double threshold = investment.currentPrice * 0.001; // 0.1% change threshold
      threshold = threshold.clamp(0.0000001, 0.01); // Min threshold for very low prices, max for high prices
      if ((newPrice - investment.currentPrice).abs() > threshold) {
        investment.currentPrice = newPrice;
        changed = true;
        investment.updateLatestPricePoint(investment.currentPrice);
      }
    }
  }

  // Function to get the total investment dividend income per second
  double getDividendIncomePerSecond() {
    double total = 0.0;
    double diversificationBonus = calculateDiversificationBonus();
    double portfolioMultiplier = isPlatinumPortfolioActive ? 1.25 : 1.0;
    
    for (var investment in investments) {
      if (investment.owned > 0 && investment.hasDividends()) {
        double baseDividend = investment.getDividendIncomePerSecond();
        baseDividend *= PacingConfig.dividendMultiplierByMarketCap(investment.marketCap);
        double adjustedDividend = baseDividend * portfolioMultiplier * (1 + diversificationBonus);
        double totalDividendForInvestment = adjustedDividend;
        
        totalDividendForInvestment *= incomeMultiplier;
        
        if (isPermanentIncomeBoostActive) {
          totalDividendForInvestment *= 1.05;
        }
        
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
      final nxtIndex = investments.indexWhere((i) => i.id == 'nxt');
      if (nxtIndex >= 0) investments[nxtIndex].unlocked = true;
    }
    
    if (money >= 1000) {
      final grvIndex = investments.indexWhere((i) => i.id == 'grv');
      if (grvIndex >= 0) investments[grvIndex].unlocked = true;
    }
    
    if (money >= 2500) {
      final mftIndex = investments.indexWhere((i) => i.id == 'mft');
      if (mftIndex >= 0) investments[mftIndex].unlocked = true;
    }
    
    if (money >= 10000) {
      final lxwIndex = investments.indexWhere((i) => i.id == 'lxw');
      if (lxwIndex >= 0) investments[lxwIndex].unlocked = true;
    }
    
    if (money >= 25000) {
      final stfIndex = investments.indexWhere((i) => i.id == 'stf');
      if (stfIndex >= 0) investments[stfIndex].unlocked = true;
    }
    
    // Cryptocurrencies unlock based on higher money thresholds
    if (money >= 50000) {
      final bclIndex = investments.indexWhere((i) => i.id == 'bcl');
      if (bclIndex >= 0) investments[bclIndex].unlocked = true;
    }
    
    if (money >= 100000) {
      final etcIndex = investments.indexWhere((i) => i.id == 'etc');
      if (etcIndex >= 0) investments[etcIndex].unlocked = true;
    }
    
    if (money >= 250000) {
      final mtkIndex = investments.indexWhere((i) => i.id == 'mtk');
      if (mtkIndex >= 0) investments[mtkIndex].unlocked = true;
    }
    
    if (money >= 500000) {
      final sbxIndex = investments.indexWhere((i) => i.id == 'sbx');
      if (sbxIndex >= 0) investments[sbxIndex].unlocked = true;
    }
    
    if (money >= 1000000) {
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