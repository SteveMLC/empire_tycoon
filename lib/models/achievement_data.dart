import 'package:flutter/material.dart';

enum AchievementCategory {
  progress,
  wealth,
  regional,
}

enum AchievementRarity {
  basic,    // Common achievements, relatively easy to obtain
  rare,     // More challenging achievements that require significant progress
  milestone // Major game milestones that represent significant accomplishments
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final int ppReward;
  bool completed;
  final DateTime? completedTimestamp;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.ppReward,
    this.rarity = AchievementRarity.basic,
    this.completed = false,
    this.completedTimestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'completed': completed,
      'completedTimestamp': completedTimestamp?.toIso8601String(),
    };
  }
} 