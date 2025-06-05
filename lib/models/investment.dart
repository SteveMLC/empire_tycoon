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
  
  // Dynamic trend properties for better price movement
  double _currentTrend; // Current trend direction (can change over time)
  int _trendDuration = 0; // How many updates the current trend has been active
  double _targetPrice = 0.0; // Target price for mean reversion within reasonable range
  DateTime _lastTrendChange = DateTime.now(); // Track when trend last changed
  
  // Getter for current trend
  double get currentTrend => _currentTrend;
  
  // Getter for trend duration
  int get trendDuration => _trendDuration;
  
  // Setters for serialization
  set currentTrend(double value) => _currentTrend = value;
  set trendDuration(int value) => _trendDuration = value;
  void setTargetPrice(double value) => _targetPrice = value;
  
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
           : 0,
       _currentTrend = trend, // Initialize current trend with base trend
       _targetPrice = basePrice { // Initialize target price at base price
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
    _priceHistoryQueue.add(price);
    
    // Remove oldest entries if we exceed the max length
    while (_priceHistoryQueue.length > maxPriceHistoryLength) {
      _priceHistoryQueue.removeFirst();
    }
  }
  
  // Update the latest price point in history (for micro-updates)
  void updateLatestPricePoint(double price) {
    if (_priceHistoryQueue.isNotEmpty) {
      // Remove the last point and add the new one
      _priceHistoryQueue.removeLast();
    }
    _priceHistoryQueue.add(price);
  }
  
  // Method to update trend dynamically based on market conditions
  void updateTrend() {
    _trendDuration++;
    
    // Check if trend should reverse based on duration and current price
    bool shouldReverse = false;
    
    // Calculate how far from base price we are
    double priceRatio = currentPrice / basePrice;
    
    // Higher volatility = shorter trend durations (more frequent reversals)
    int maxTrendDuration = (15 / (volatility + 0.1)).round(); // Decreased from 20, making reversals more frequent
    maxTrendDuration = maxTrendDuration.clamp(3, 30); // Reduced minimum and maximum for more dynamic behavior
    
    // Enhanced trend reversal conditions for more movement
    if (_trendDuration >= maxTrendDuration) {
      shouldReverse = true;
    } else if (priceRatio > 3.5 && _currentTrend > 0) { // Trigger reversal earlier
      // Reverse upward trend if price gets too high
      shouldReverse = true;
    } else if (priceRatio < 0.5 && _currentTrend < 0) { // Trigger reversal earlier
      // Reverse downward trend if price gets too low
      shouldReverse = true;
    } else if (Random().nextDouble() < (volatility * 0.08)) { // Increased random reversal chance
      // Random reversal based on volatility (more volatile = more reversals)
      shouldReverse = true;
    } else if (_trendDuration > 5 && Random().nextDouble() < 0.1) {
      // Additional random reversal chance after minimum duration to prevent stagnation
      shouldReverse = true;
    }
    
    if (shouldReverse) {
      reverseTrend();
    }
    
    // Update target price based on current trend and volatility
    _updateTargetPrice();
  }
  
  // Reverse the current trend
  void reverseTrend() {
    _currentTrend = -_currentTrend + (Random().nextDouble() * 0.02 - 0.01); // Add some randomness
    _trendDuration = 0;
    _lastTrendChange = DateTime.now();
    
    // Set new target price in the opposite direction
    double priceRatio = currentPrice / basePrice;
    if (_currentTrend > 0) {
      // Trend is now upward - target higher price within reasonable range
      _targetPrice = basePrice * (priceRatio + 0.3 + Random().nextDouble() * 0.5);
    } else {
      // Trend is now downward - target lower price within reasonable range
      _targetPrice = basePrice * (priceRatio - 0.3 - Random().nextDouble() * 0.5);
    }
    
    // Keep target price within bounds
    _targetPrice = _targetPrice.clamp(basePrice * 0.3, basePrice * 3.0);
  }
  
  // Update target price based on current trend
  void _updateTargetPrice() {
    // Slowly drift target price to create natural cycles
    double drift = Random().nextDouble() * 0.02 - 0.01; // Small random drift
    double priceRatio = currentPrice / basePrice;
    
    if (_currentTrend > 0) {
      // Upward trend - target should be above current price
      _targetPrice = basePrice * (priceRatio + 0.1 + Random().nextDouble() * 0.3);
    } else {
      // Downward trend - target should be below current price
      _targetPrice = basePrice * (priceRatio - 0.1 - Random().nextDouble() * 0.3);
    }
    
    _targetPrice += drift;
    _targetPrice = _targetPrice.clamp(basePrice * 0.3, basePrice * 3.0);
  }
  
  // Get mean reversion factor towards target price
  double getMeanReversionFactor() {
    if (_targetPrice <= 0) return 0.0;
    
    double targetRatio = _targetPrice / currentPrice;
    
    if (targetRatio > 1.05) { // Reduced threshold for more responsive reversion
      // Target is significantly higher - stronger pull up
      return 0.04 * (targetRatio - 1.0); // Increased from 0.02
    } else if (targetRatio < 0.95) { // Reduced threshold for more responsive reversion
      // Target is significantly lower - stronger pull down
      return -0.04 * (1.0 - targetRatio); // Increased from 0.02
    }
    
    // Add small random movement even when near target to prevent complete stagnation
    return (Random().nextDouble() * 2 - 1.0) * 0.005;
  }
}
