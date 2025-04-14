import 'package:flutter/material.dart';

class Investment {
  final String id;
  final String name;
  final String description;
  final double basePrice;
  double currentPrice;
  double purchasePrice; // Average purchase price
  final double volatility; // 0.0 - 1.0, higher means more price movement
  final double trend; // Base trend direction (positive or negative)
  final double dividendPerSecond; // Income generated per second per share
  int owned;
  final IconData icon;
  final Color color;
  List<double> priceHistory; // Last 7 days
  final String category; // Investment category (e.g., 'Technology', 'Energy', etc.)
  bool autoInvestEnabled = false; // For auto-invest feature
  double autoInvestAmount = 0; // Amount to auto-invest
  
  // Additional fields needed for the investment detail screen
  final String riskLevel; // Risk level for display ("Low", "Medium", "High", etc.)
  final double marketCap; // Market capitalization of the investment
  final double dailyVolume; // Daily trading volume
  
  // Get price change percentage - this is now a getter to simplify access
  double get priceChangePercent => getPriceChangePercent();
  
  Investment({
    required this.id,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.currentPrice,
    required this.volatility,
    required this.trend,
    required this.owned,
    required this.icon,
    required this.color,
    required this.priceHistory,
    required this.category,
    this.purchasePrice = 0.0,
    this.autoInvestEnabled = false,
    this.autoInvestAmount = 0,
    this.dividendPerSecond = 0.0, // Default to 0 for non-dividend investments
    this.riskLevel = 'Medium', // Default risk level
    this.marketCap = 0.0, // Default market cap
    this.dailyVolume = 0.0, // Default daily volume
  });
  
  // Get current value of owned investments
  double getCurrentValue() {
    return currentPrice * owned;
  }
  
  // Calculate potential profit/loss based on current price
  double getProfitLoss() {
    if (owned <= 0 || purchasePrice <= 0) return 0.0;
    return (currentPrice - purchasePrice) * owned;
  }
  
  // Calculate profit/loss percentage
  double getProfitLossPercentage() {
    if (owned <= 0 || purchasePrice <= 0) return 0.0;
    return ((currentPrice - purchasePrice) / purchasePrice) * 100;
  }
  
  // Calculate price change from previous day
  double getPriceChangePercent() {
    if (priceHistory.length < 2) return 0.0;
    
    // Get the current price (most recent in history) and previous price
    double previousPrice = priceHistory[priceHistory.length - 2];
    double latestPrice = currentPrice; // Always use the current price, not the last history entry
    
    // Calculate the percentage change
    if (previousPrice <= 0) return 0.0; // Prevent division by zero
    return ((latestPrice - previousPrice) / previousPrice) * 100;
  }
  
  // Predict trend direction based on historical data
  bool isPriceIncreasing() {
    if (priceHistory.length < 3) return trend > 0;
    
    double sum = 0;
    for (int i = 1; i < priceHistory.length; i++) {
      sum += priceHistory[i] - priceHistory[i-1];
    }
    return sum > 0;
  }
  
  // Calculate a forecast score from -1.0 (strong sell) to 1.0 (strong buy)
  double getForecastScore() {
    // Base score on recent trend strength
    double trendStrength = 0;
    if (priceHistory.length >= 3) {
      List<double> changes = [];
      for (int i = 1; i < priceHistory.length; i++) {
        changes.add(priceHistory[i] - priceHistory[i-1]);
      }
      
      // Average the changes
      double avgChange = changes.reduce((a, b) => a + b) / changes.length;
      
      // Normalize to a -1 to 1 range (adjust multiplier as needed)
      trendStrength = (avgChange / currentPrice) * 100;
      
      // Clamp to range
      trendStrength = trendStrength.clamp(-1.0, 1.0);
    } else {
      // If not enough history, use the investment's base trend
      trendStrength = trend * 10; // Scale up the base trend
      trendStrength = trendStrength.clamp(-1.0, 1.0);
    }
    
    return trendStrength;
  }
  
  // Get forecast category for UI
  String getForecastCategory() {
    double score = getForecastScore();
    
    if (score > 0.6) return 'Strong Buy';
    if (score > 0.2) return 'Buy';
    if (score > -0.2) return 'Hold';
    if (score > -0.6) return 'Sell';
    return 'Strong Sell';
  }
  
  // Get color for forecast display
  Color getForecastColor() {
    double score = getForecastScore();
    
    if (score > 0.6) return Colors.green.shade800; // Strong Buy
    if (score > 0.2) return Colors.green.shade400; // Buy  
    if (score > -0.2) return Colors.grey.shade600; // Hold
    if (score > -0.6) return Colors.red.shade400; // Sell
    return Colors.red.shade800; // Strong Sell
  }
  
  // Update purchase price when buying more
  void updatePurchasePrice(double amount, int quantity) {
    if (owned <= 0) {
      purchasePrice = amount / quantity;
    } else {
      // Calculate weighted average
      int totalOwned = owned + quantity;
      double totalValue = (purchasePrice * owned) + amount;
      purchasePrice = totalValue / totalOwned;
    }
  }
  
  // Calculate dividend income per second
  double getDividendIncomePerSecond() {
    return dividendPerSecond * owned;
  }
  
  // Check if this is a dividend-paying investment
  bool hasDividends() {
    return dividendPerSecond > 0;
  }
  
  // Calculate dividend yield as a percentage
  double getDividendYield() {
    if (currentPrice <= 0) return 0.0;
    return (dividendPerSecond / currentPrice) * 100;
  }
  
  // Calculate ROI (Return on Investment) - dividend income per second / current price
  double getROI() {
    if (currentPrice <= 0) return 0.0;
    return (dividendPerSecond / currentPrice) * 100;
  }
  
  // Calculate trading volume based on price, market cap, and volatility
  double getDailyVolume() {
    if (currentPrice <= 0 || marketCap <= 0) return 0.0;
    
    // Calculate implied shares outstanding (Market Cap / Current Price)
    double sharesOutstanding = (marketCap * 1000000000) / currentPrice; // Convert marketCap from $billions to dollars
    
    // Daily volume is a percentage of outstanding shares, influenced by volatility
    // Higher volatility means more trading activity
    double volumePercentage = volatility * 0.8; // Base percentage (0-80%) of shares traded daily based on volatility
    
    // Add a small random component for realism (±10% variation)
    final random = 0.9 + (DateTime.now().millisecond % 20) / 100; // 0.9 to 1.1 random factor
    
    // Calculate actual volume
    double volume = sharesOutstanding * volumePercentage * random;
    
    // Calculate volume in dollars
    return volume * currentPrice;
  }
}
