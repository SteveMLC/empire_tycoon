import 'package:flutter/material.dart';
import 'dart:convert'; // Import for jsonEncode/Decode
import 'dart:math'; // Import for max function
import 'game_state_events.dart';

class BusinessLevel {
  final double cost;
  final double incomePerSecond;
  final String description;
  final int timerSeconds; // ADDED: Upgrade timer duration
  
  BusinessLevel({
    required this.cost,
    required this.incomePerSecond,
    required this.description,
    required this.timerSeconds, // ADDED
  });

  // ADDED: Factory constructor for JSON deserialization
  factory BusinessLevel.fromJson(Map<String, dynamic> json) {
    return BusinessLevel(
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      incomePerSecond: (json['incomePerSecond'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      timerSeconds: json['timerSeconds'] as int? ?? 0,
    );
  }

  // ADDED: Method for JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'cost': cost,
      'incomePerSecond': incomePerSecond,
      'description': description,
      'timerSeconds': timerSeconds,
    };
  }
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
  
  // ADDED: Upgrade Timer State
  bool isUpgrading;
  DateTime? upgradeEndTime;
  int? initialUpgradeDurationSeconds; // Store initial duration for progress calculation
  
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
    // ADDED: Initialize upgrade state
    this.isUpgrading = false,
    this.upgradeEndTime,
    this.initialUpgradeDurationSeconds,
  });
  
  // Calculate cost for next level upgrade
  double getNextUpgradeCost() {
    if (level >= maxLevel) return 0.0; // Already at max level
    // If currently upgrading, prevent showing cost for the *next* level
    if (isUpgrading) return 0.0;
    return levels[level].cost; // Current level is 0-based index for the *next* upgrade
  }
  
  // ADDED: Get timer duration for the next upgrade
  int getNextUpgradeTimerSeconds() {
    if (level >= maxLevel) return 0;
    if (isUpgrading) return 0; // No timer if already upgrading
    // Ensure level index is valid for levels list
    if (level < 0 || level >= levels.length) return 0; 
    return levels[level].timerSeconds;
  }
  
  // Check if at max level
  bool isMaxLevel() {
    return level >= maxLevel;
  }
  
  // Calculate current income per second based on level
  double getCurrentIncome({bool isResilienceActive = false}) {
    if (level <= 0) return 0.0; // Not owned yet
    // Use level-1 index because level is 1-based for owned levels
    double baseIncome = levels[level - 1].incomePerSecond * incomeInterval;
    
    return baseIncome;
  }
  
  // Get current income per second
  double getIncomePerSecond({bool isResilienceActive = false}) {
    if (level <= 0) return 0.0; // Not owned yet
    // Use level-1 index because level is 1-based for owned levels
    double baseIncome = levels[level - 1].incomePerSecond;
    
    return baseIncome;
  }
  
  // Get next level's income per second
  double getNextLevelIncomePerSecond() {
    // Return income of the level currently being upgraded TO, or the next level if not upgrading
    int targetLevelIndex = isUpgrading ? level : level; // Index for levels list
    if (targetLevelIndex >= maxLevel) return getIncomePerSecond(); // Already at max or upgrading to max
    return levels[targetLevelIndex].incomePerSecond;
  }
  
  // Get current level description
  String getCurrentLevelDescription() {
    if (level <= 0) return description; // Not owned yet
    // Use level-1 index
    return levels[level - 1].description;
  }
  
  // Get next level description
  String getNextLevelDescription() {
    // Return description of the level currently being upgraded TO, or the next level if not upgrading
    int targetLevelIndex = isUpgrading ? level : level; // Index for levels list
    if (targetLevelIndex >= maxLevel) return getCurrentLevelDescription(); // Already at max or upgrading to max
    return levels[targetLevelIndex].description;
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
    if (isUpgrading) return 0.0; // Can't calculate ROI while upgrading
    double nextCost = getNextUpgradeCost();
    if (nextCost <= 0) return 0.0;
    
    // Calculate the income increase from the upgrade
    double currentIncome = getIncomePerSecond();
    double nextIncome = getNextLevelIncomePerSecond();
    double incomeIncrease = nextIncome - currentIncome;
    
    // Prevent division by zero if cost is somehow zero
    if (nextCost == 0) return double.infinity; // Or handle as appropriate
    
    return (incomeIncrease / nextCost) * 100;
  }

  // --- ADDED: Upgrade Timer Methods ---

  // Start the upgrade timer
  void startUpgrade(int durationSeconds) {
    if (isUpgrading || level >= maxLevel) return; // Don't start if already upgrading or max level

    isUpgrading = true;
    initialUpgradeDurationSeconds = durationSeconds;
    upgradeEndTime = DateTime.now().add(Duration(seconds: durationSeconds));
  }

  // Complete the upgrade
  void completeUpgrade() {
    if (!isUpgrading) return;

    level++; // Increment level AFTER upgrade finishes
    isUpgrading = false;
    upgradeEndTime = null;
    initialUpgradeDurationSeconds = null;
    // Note: secondsSinceLastIncome reset might happen elsewhere if needed
  }

  // Reduce remaining upgrade time (e.g., by watching an ad)
  void reduceUpgradeTime(Duration reduction) {
    if (!isUpgrading || upgradeEndTime == null) return;

    upgradeEndTime = upgradeEndTime!.subtract(reduction);
    // Ensure end time doesn't go into the past beyond 'now'
    if (upgradeEndTime!.isBefore(DateTime.now())) {
      upgradeEndTime = DateTime.now();
    }
  }

  // Get remaining upgrade time
  Duration getRemainingUpgradeTime() {
    if (!isUpgrading || upgradeEndTime == null) {
      return Duration.zero;
    }
    final now = DateTime.now();
    if (now.isAfter(upgradeEndTime!)) {
      return Duration.zero;
    }
    return upgradeEndTime!.difference(now);
  }

  // Get upgrade progress (0.0 to 1.0)
  double getUpgradeProgress() {
    if (!isUpgrading || upgradeEndTime == null || initialUpgradeDurationSeconds == null || initialUpgradeDurationSeconds == 0) {
      return 0.0;
    }
    final remaining = getRemainingUpgradeTime().inSeconds;
    final total = initialUpgradeDurationSeconds!;
    final elapsed = total - remaining;
    return max(0.0, min(1.0, elapsed / total)); // Clamp between 0 and 1
  }

  // --- END: Upgrade Timer Methods ---


  // --- ADDED: JSON Serialization/Deserialization ---

  factory Business.fromJson(Map<String, dynamic> json) {
    // Handle IconData deserialization - This is tricky, typically store a key and map back
    // For simplicity here, we might need to pass icons during initialization elsewhere
    // or use a simpler representation like a string key. Using a default for now.
    IconData iconData = Icons.business; // Default icon

    // Deserialize BusinessLevel list
    List<BusinessLevel> parsedLevels = [];
    if (json['levels'] != null && json['levels'] is List) {
      parsedLevels = (json['levels'] as List)
          .map((levelJson) => BusinessLevel.fromJson(levelJson as Map<String, dynamic>))
          .toList();
    }

    return Business(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0.0,
      baseIncome: (json['baseIncome'] as num?)?.toDouble() ?? 0.0,
      level: json['level'] as int? ?? 0,
      incomeInterval: json['incomeInterval'] as int? ?? 1,
      unlocked: json['unlocked'] as bool? ?? false,
      icon: iconData, // Use the determined icon
      levels: parsedLevels, // Use parsed levels
      maxLevel: json['maxLevel'] as int? ?? 10,
      secondsSinceLastIncome: json['secondsSinceLastIncome'] as int? ?? 0,
      // Deserialize upgrade state
      isUpgrading: json['isUpgrading'] as bool? ?? false,
      upgradeEndTime: json['upgradeEndTime'] != null
          ? DateTime.parse(json['upgradeEndTime'] as String)
          : null,
      initialUpgradeDurationSeconds: json['initialUpgradeDurationSeconds'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    // Handle IconData serialization - Store a key or identifier instead of the object
    String iconKey = 'business'; // Example key

    return {
      'id': id,
      'name': name,
      'description': description,
      'basePrice': basePrice,
      'baseIncome': baseIncome,
      'level': level,
      'incomeInterval': incomeInterval,
      'unlocked': unlocked,
      'iconKey': iconKey, // Store the key
      'levels': levels.map((level) => level.toJson()).toList(), // Serialize levels
      'maxLevel': maxLevel,
      'secondsSinceLastIncome': secondsSinceLastIncome,
      // Serialize upgrade state
      'isUpgrading': isUpgrading,
      'upgradeEndTime': upgradeEndTime?.toIso8601String(),
      'initialUpgradeDurationSeconds': initialUpgradeDurationSeconds,
    };
  }

  // --- END: JSON Serialization/Deserialization ---
}