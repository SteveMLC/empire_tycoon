import 'package:flutter/material.dart';
import 'dart:math'; // Import math for max function
import 'dart:collection'; // Import for Queue

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
  // Use a fixed-size queue for price history to avoid array shifts during pruning
  Queue<double> _priceHistoryQueue = Queue<double>();
  static const int maxPriceHistoryLength = 30; // Constant for max history length
  
  // Getter that returns price history as a List for compatibility with existing code
  List<double> get priceHistory => _priceHistoryQueue.toList();
  
  // Setter for price history - needed for serialization compatibility
  set priceHistory(List<double> history) {
    _priceHistoryQueue.clear();
    for (final price in history) {
      if (_priceHistoryQueue.length < maxPriceHistoryLength) {
        _priceHistoryQueue.add(price);
      }
    }
  }
  final String category; // Investment category (e.g., 'Technology', 'Energy', etc.)
  bool autoInvestEnabled = false; // For auto-invest feature
  double autoInvestAmount = 0; // Amount to auto-invest
  final String riskLevel; // Risk level for display ("Low", "Medium", "High", etc.)
  final double marketCap; // Market capitalization of the investment
  final double dailyVolume; // Daily trading volume
  final int maxShares; // Maximum number of shares available based on initial market cap/price
  bool unlocked; // Track if the investment is visible/purchasable
  
  // Get price change percentage - this is now a getter to simplify access
  double get priceChangePercent => getPriceChangePercent();
  
  // Get available shares (max shares - owned shares)
  int get availableShares => max(0, maxShares - owned); // Ensure it doesn't go below 0
  
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
    required List<double> priceHistory,
    required this.category,
    this.purchasePrice = 0.0,
    this.autoInvestEnabled = false,
    this.autoInvestAmount = 0,
    this.dividendPerSecond = 0.0, // Default to 0 for non-dividend investments
    this.riskLevel = 'Medium', // Default risk level
    this.marketCap = 0.0, // Default market cap (in billions)
    this.dailyVolume = 0.0, // Default daily volume
    this.unlocked = false, // Default to locked
  }) : // Calculate maxShares based on initial marketCap and basePrice
       maxShares = (basePrice > 0 && marketCap > 0)
           ? ((marketCap * 1e9) / basePrice).floor() // Convert marketCap from billions
           : 0 {
    // Initialize the price history queue with the provided list
    // Ensure we don't exceed the maximum length
    if (priceHistory.isNotEmpty) {
      // If we have more entries than the max, take only the most recent ones
      final startIndex = max(0, priceHistory.length - maxPriceHistoryLength);
      for (int i = startIndex; i < priceHistory.length; i++) {
        _priceHistoryQueue.add(priceHistory[i]);
      }
    }
  }
  
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
  
  // Calculate price change from previous day - optimized for the queue implementation
  double getPriceChangePercent() {
    final history = priceHistory; // Get the list via the getter
    if (history.length < 2) return 0.0;
    
    // Get the current price and previous price
    double previousPrice = history[history.length - 2];
    double latestPrice = currentPrice; // Always use the current price, not the last history entry
    
    // Calculate the percentage change
    if (previousPrice <= 0) return 0.0; // Prevent division by zero
    return ((latestPrice - previousPrice) / previousPrice) * 100;
  }
  
  // Predict trend direction based on historical data - optimized for memory efficiency
  bool isPriceIncreasing() {
    final history = priceHistory; // Get the list via the getter
    if (history.length < 3) return trend > 0;
    
    // Calculate the sum of price changes more efficiently
    double sum = 0;
    for (int i = 1; i < history.length; i++) {
      sum += history[i] - history[i-1];
    }
    return sum > 0;
  }
  
  // Calculate a forecast score from -1.0 (strong sell) to 1.0 (strong buy) - optimized for memory efficiency
  double getForecastScore() {
    // Base score on recent trend strength
    double trendStrength = 0;
    final history = priceHistory; // Get the list via the getter
    
    if (history.length >= 3) {
      // Calculate the average change directly without creating a new list
      double sumChanges = 0;
      for (int i = 1; i < history.length; i++) {
        sumChanges += history[i] - history[i-1];
      }
      double avgChange = sumChanges / (history.length - 1);
      
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
  
  // Calculate trading volume based on price, market cap, and volatility - optimized for consistency
  double getDailyVolume() {
    if (currentPrice <= 0 || marketCap <= 0) return 0.0;
    
    // Calculate implied shares outstanding (Market Cap / Current Price)
    double sharesOutstanding = (marketCap * 1000000000) / currentPrice; // Convert marketCap from $billions to dollars
    
    // Daily volume is a percentage of outstanding shares, influenced by volatility
    // Higher volatility means more trading activity
    double volumePercentage = volatility * 0.8; // Base percentage (0-80%) of shares traded daily based on volatility
    
    // Use a more deterministic approach for the random component to reduce object creation
    // Based on investment ID hash and current day to ensure consistency within a day
    final int dayOfYear = DateTime.now().day + (DateTime.now().month * 31);
    final int seed = id.hashCode + dayOfYear;
    final random = 0.9 + ((seed % 20) / 100); // 0.9 to 1.1 deterministic factor
    
    // Calculate actual volume
    double volume = sharesOutstanding * volumePercentage * random;
    
    // Calculate volume in dollars
    return volume * currentPrice;
  }
  
  // Add and remove price history points efficiently
  void addPriceHistoryPoint(double price) {
    // Add the new price point
    _priceHistoryQueue.add(price);
    
    // Remove oldest entry if we exceed the maximum length
    if (_priceHistoryQueue.length > maxPriceHistoryLength) {
      _priceHistoryQueue.removeFirst();
    }
  }
  
  // Update the most recent price point (used for micro-updates)
  void updateLatestPricePoint(double price) {
    if (_priceHistoryQueue.isEmpty) {
      _priceHistoryQueue.add(price);
      return;
    }
    
    // Remove the last item and add the updated one
    // This is more efficient than creating a new list and replacing an element
    _priceHistoryQueue.removeLast();
    _priceHistoryQueue.add(price);
  }
}
