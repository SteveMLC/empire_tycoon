import 'package:flutter/material.dart';
import 'game_state_events.dart';

class BusinessLevel {
  final double cost;
  final double incomePerSecond;
  final String description;
  
  BusinessLevel({
    required this.cost,
    required this.incomePerSecond,
    required this.description,
  });
}

class Business {
  final String id;
  final String name;
  final String description;
  final double basePrice;
  final double baseIncome;
  final int incomeInterval; // in seconds
  int level; // Current level (0 = not owned, 1-10 = owned levels)
  bool unlocked;
  int secondsSinceLastIncome;
  final IconData icon;
  final List<BusinessLevel> levels;
  final int maxLevel;
  
  Business({
    required this.id,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.baseIncome,
    required this.level,
    required this.incomeInterval,
    required this.unlocked,
    required this.icon,
    required this.levels,
    this.maxLevel = 10,
    this.secondsSinceLastIncome = 0,
  });
  
  // Calculate cost for next level upgrade
  double getNextUpgradeCost() {
    if (level >= maxLevel) return 0.0; // Already at max level
    return levels[level].cost; // Current level is 0-based index
  }
  
  // Check if at max level
  bool isMaxLevel() {
    return level >= maxLevel;
  }
  
  // Calculate current income per second based on level
  double getCurrentIncome({bool isResilienceActive = false}) {
    if (level <= 0) return 0.0; // Not owned yet
    double baseIncome = levels[level-1].incomePerSecond * incomeInterval;
    
    return baseIncome;
  }
  
  // Get current income per second
  double getIncomePerSecond({bool isResilienceActive = false}) {
    if (level <= 0) return 0.0; // Not owned yet
    double baseIncome = levels[level-1].incomePerSecond;
    
    return baseIncome;
  }
  
  // Get next level's income per second
  double getNextLevelIncomePerSecond() {
    if (level >= maxLevel) return getIncomePerSecond(); // Already at max
    return levels[level].incomePerSecond;
  }
  
  // Get current level description
  String getCurrentLevelDescription() {
    if (level <= 0) return description; // Not owned yet
    return levels[level-1].description;
  }
  
  // Get next level description
  String getNextLevelDescription() {
    if (level >= maxLevel) return getCurrentLevelDescription(); // Already at max
    return levels[level].description;
  }
  
  // Calculate current value of the business
  double getCurrentValue() {
    if (level <= 0) return 0.0;
    
    // Sum up the costs of all purchased levels
    double totalValue = 0.0;
    for (int i = 0; i < level; i++) {
      totalValue += levels[i].cost;
    }
    
    return totalValue;
  }
  
  // Time to next income in seconds
  int getTimeToNextIncome() {
    return incomeInterval - secondsSinceLastIncome;
  }
  
  // Progress percentage to next income
  double getIncomeProgress() {
    return secondsSinceLastIncome / incomeInterval;
  }
  
  // Calculate ROI (Return on Investment) - income per second / cost of next level
  double getROI() {
    double nextCost = getNextUpgradeCost();
    if (nextCost <= 0) return 0.0;
    
    // Calculate the income increase from the upgrade
    double currentIncome = getIncomePerSecond();
    double nextIncome = getNextLevelIncomePerSecond();
    double incomeIncrease = nextIncome - currentIncome;
    
    return (incomeIncrease / nextCost) * 100;
  }
}