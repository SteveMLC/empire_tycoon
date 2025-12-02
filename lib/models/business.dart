import 'package:flutter/material.dart';
import 'dart:convert'; // Import for jsonEncode/Decode
import 'dart:math'; // Import for max function
import 'game_state_events.dart';
import 'business_branch.dart';

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
  
  // ADDED: Platinum Facade
  bool hasPlatinumFacade;
  
  // ADDED: Upgrade Timer State
  bool isUpgrading;
  DateTime? upgradeEndTime;
  int? initialUpgradeDurationSeconds; // Store initial duration for progress calculation
  
  // ADDED: Business Branching System
  List<BusinessBranch>? branches;          // Available specialization paths (null = no branching)
  String? selectedBranchId;                // Currently selected branch ID (null = no choice made)
  int branchSelectionLevel;                // Level at which branching becomes available (default: 0 = no branching)
  bool hasMadeBranchChoice;                // Whether player has selected a branch
  DateTime? branchSelectionTime;           // When the branch choice was made (for analytics)
  
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
    // ADDED: Initialize platinum facade
    this.hasPlatinumFacade = false,
    // ADDED: Initialize upgrade state
    this.isUpgrading = false,
    this.upgradeEndTime,
    this.initialUpgradeDurationSeconds,
    // ADDED: Initialize branching fields
    this.branches,
    this.selectedBranchId,
    this.branchSelectionLevel = 0,
    this.hasMadeBranchChoice = false,
    this.branchSelectionTime,
  });
  
  // --- ADDED: Business Branching Methods ---
  
  /// Check if this business supports branching
  bool get hasBranching => branches != null && branches!.isNotEmpty && branchSelectionLevel > 0;
  
  /// Check if player can currently select a branch (at branch level, hasn't chosen yet)
  bool canSelectBranch() {
    return hasBranching && 
           level >= branchSelectionLevel && 
           !hasMadeBranchChoice;
  }
  
  /// Check if upgrades are blocked pending branch selection
  bool get isBlockedForBranchSelection {
    return canSelectBranch() && !isUpgrading;
  }
  
  /// Get the list of available branches for selection
  List<BusinessBranch> getAvailableBranches() {
    return branches ?? [];
  }
  
  /// Get the currently selected branch (null if none selected)
  BusinessBranch? getCurrentBranch() {
    if (selectedBranchId == null || branches == null) return null;
    return branches!.firstWhere(
      (b) => b.id == selectedBranchId,
      orElse: () => branches!.first, // Fallback to first branch
    );
  }
  
  /// Select a branch for this business
  bool selectBranch(String branchId) {
    if (!canSelectBranch()) return false;
    if (branches == null || !branches!.any((b) => b.id == branchId)) return false;
    
    selectedBranchId = branchId;
    hasMadeBranchChoice = true;
    branchSelectionTime = DateTime.now();
    return true;
  }
  
  /// Get the effective BusinessLevel for a given game level (1-10)
  /// This handles the branch transition at branchSelectionLevel
  BusinessLevel? _getEffectiveLevelData(int gameLevel) {
    if (gameLevel <= 0 || gameLevel > maxLevel) return null;
    
    // Pre-branch levels (1 to branchSelectionLevel-1) use base levels list
    if (!hasBranching || gameLevel < branchSelectionLevel) {
      final index = gameLevel - 1;
      if (index >= 0 && index < levels.length) {
        return levels[index];
      }
      return null;
    }
    
    // At or after branch selection level
    final branch = getCurrentBranch();
    if (branch == null) {
      // No branch selected yet, use base levels as fallback
      final index = gameLevel - 1;
      if (index >= 0 && index < levels.length) {
        return levels[index];
      }
      return null;
    }
    
    // Branch levels: gameLevel 3 -> branch index 0, gameLevel 4 -> branch index 1, etc.
    final branchIndex = gameLevel - branchSelectionLevel;
    if (branchIndex >= 0 && branchIndex < branch.levels.length) {
      return branch.levels[branchIndex];
    }
    
    return null;
  }
  
  /// Get the display name including branch suffix if applicable
  String getDisplayName() {
    if (hasMadeBranchChoice && selectedBranchId != null) {
      final branch = getCurrentBranch();
      if (branch != null) {
        return '$name – ${branch.name}';
      }
    }
    return name;
  }
  
  // --- END: Business Branching Methods ---
  
  // Calculate cost for next level upgrade (BRANCH-AWARE)
  double getNextUpgradeCost() {
    if (level >= maxLevel) return 0.0; // Already at max level
    // If currently upgrading, prevent showing cost for the *next* level
    if (isUpgrading) return 0.0;
    // Block if branch selection is pending
    if (isBlockedForBranchSelection) return 0.0;
    
    final levelData = _getEffectiveLevelData(level + 1);
    return levelData?.cost ?? levels[level].cost;
  }
  
  // ADDED: Get timer duration for the next upgrade (BRANCH-AWARE)
  int getNextUpgradeTimerSeconds() {
    if (level >= maxLevel) return 0;
    if (isUpgrading) return 0; // No timer if already upgrading
    if (isBlockedForBranchSelection) return 0;
    
    final levelData = _getEffectiveLevelData(level + 1);
    return levelData?.timerSeconds ?? levels[level].timerSeconds;
  }
  
  // Check if at max level
  bool isMaxLevel() {
    return level >= maxLevel;
  }
  
  // Calculate current income per second based on level (BRANCH-AWARE)
  double getCurrentIncome({bool isResilienceActive = false}) {
    if (level <= 0) return 0.0; // Not owned yet
    
    final levelData = _getEffectiveLevelData(level);
    double baseIncomeValue = (levelData?.incomePerSecond ?? levels[level - 1].incomePerSecond) * incomeInterval;
    
    return baseIncomeValue;
  }
  
  // Get current income per second (BRANCH-AWARE)
  double getIncomePerSecond({bool isResilienceActive = false}) {
    if (level <= 0) return 0.0; // Not owned yet
    
    final levelData = _getEffectiveLevelData(level);
    return levelData?.incomePerSecond ?? levels[level - 1].incomePerSecond;
  }
  
  // Get expected income after purchase (for unpurchased businesses)
  double getExpectedIncomeAfterPurchase() {
    // For unpurchased businesses (level 0), return the income of the first level
    if (level == 0 && levels.isNotEmpty) {
      return levels[0].incomePerSecond;
    }
    // For already owned businesses, return current income
    return getIncomePerSecond();
  }

  // Get next level's income per second (BRANCH-AWARE)
  double getNextLevelIncomePerSecond() {
    int targetLevel = level + 1;
    if (targetLevel > maxLevel) return getIncomePerSecond(); // Already at max
    
    final levelData = _getEffectiveLevelData(targetLevel);
    return levelData?.incomePerSecond ?? levels[min(level, levels.length - 1)].incomePerSecond;
  }
  
  // Get current level description (BRANCH-AWARE)
  String getCurrentLevelDescription() {
    if (level <= 0) return description; // Not owned yet
    
    final levelData = _getEffectiveLevelData(level);
    return levelData?.description ?? levels[level - 1].description;
  }
  
  // Get next level description (BRANCH-AWARE)
  String getNextLevelDescription() {
    int targetLevel = level + 1;
    if (targetLevel > maxLevel) return getCurrentLevelDescription(); // Already at max
    
    final levelData = _getEffectiveLevelData(targetLevel);
    return levelData?.description ?? levels[min(level, levels.length - 1)].description;
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
      // ADDED: Deserialize platinum facade
      hasPlatinumFacade: json['hasPlatinumFacade'] as bool? ?? false,
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
      // ADDED: Serialize platinum facade
      'hasPlatinumFacade': hasPlatinumFacade,
      // Serialize upgrade state
      'isUpgrading': isUpgrading,
      'upgradeEndTime': upgradeEndTime?.toIso8601String(),
      'initialUpgradeDurationSeconds': initialUpgradeDurationSeconds,
    };
  }

  // --- END: JSON Serialization/Deserialization ---
}