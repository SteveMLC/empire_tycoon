import 'package:flutter/material.dart';
import 'business.dart';

/// Enum representing the type/archetype of a business branch
enum BusinessBranchType {
  speed,      // Fast service, high volume, lower margins (e.g., Taco Stand)
  balanced,   // Baseline progression, familiar feel (e.g., Burger Bar)
  premium,    // High quality, high margins, slower upgrades (e.g., Smoke BBQ)
  innovation, // Unique mechanics, variable timers
  scaling,    // Network effects, exponential growth
}

/// Represents a specialization branch for a business
class BusinessBranch {
  final String id;                    // e.g., "taco_stand", "burger_bar", "smoke_bbq"
  final String name;                  // e.g., "Taco Stand"
  final String description;           // Branch-specific description
  final IconData icon;                // Unique icon for this branch
  final List<BusinessLevel> levels;   // Levels 4-10 for this branch (indices 0-6)
  final BusinessBranchType type;      // Categorization enum
  final Color themeColor;             // UI color for this branch
  
  // Branch-specific economic characteristics (relative to baseline)
  final double costMultiplier;        // Upgrade cost modifier (1.0 = baseline)
  final double incomeMultiplier;      // Income modifier (1.0 = baseline)
  final double speedMultiplier;       // Timer modifier (< 1.0 = faster, > 1.0 = slower)
  
  // Optional metadata for future mechanics
  final Map<String, dynamic>? metadata;

  const BusinessBranch({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.levels,
    required this.type,
    required this.themeColor,
    this.costMultiplier = 1.0,
    this.incomeMultiplier = 1.0,
    this.speedMultiplier = 1.0,
    this.metadata,
  });

  /// Get a short summary of the branch characteristics for UI display
  String get characteristicsSummary {
    switch (type) {
      case BusinessBranchType.speed:
        return 'Fast upgrades, lower income';
      case BusinessBranchType.balanced:
        return 'Balanced growth';
      case BusinessBranchType.premium:
        return 'Slow upgrades, high income';
      case BusinessBranchType.innovation:
        return 'Variable progression';
      case BusinessBranchType.scaling:
        return 'Exponential growth';
    }
  }

  /// Get the level at a specific branch level index (0-6 maps to game levels 4-10)
  BusinessLevel? getLevelAt(int branchLevelIndex) {
    if (branchLevelIndex < 0 || branchLevelIndex >= levels.length) return null;
    return levels[branchLevelIndex];
  }

  /// Factory constructor for JSON deserialization
  factory BusinessBranch.fromJson(Map<String, dynamic> json) {
    // Parse levels
    List<BusinessLevel> parsedLevels = [];
    if (json['levels'] != null && json['levels'] is List) {
      parsedLevels = (json['levels'] as List)
          .map((levelJson) => BusinessLevel.fromJson(levelJson as Map<String, dynamic>))
          .toList();
    }

    // Parse branch type
    BusinessBranchType branchType = BusinessBranchType.balanced;
    if (json['type'] != null) {
      final typeStr = json['type'] as String;
      branchType = BusinessBranchType.values.firstWhere(
        (t) => t.name == typeStr,
        orElse: () => BusinessBranchType.balanced,
      );
    }

    // Parse theme color
    Color themeColor = Colors.blue;
    if (json['themeColor'] != null) {
      themeColor = Color(json['themeColor'] as int);
    }

    return BusinessBranch(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      icon: Icons.store, // Default icon, actual icon resolved elsewhere
      levels: parsedLevels,
      type: branchType,
      themeColor: themeColor,
      costMultiplier: (json['costMultiplier'] as num?)?.toDouble() ?? 1.0,
      incomeMultiplier: (json['incomeMultiplier'] as num?)?.toDouble() ?? 1.0,
      speedMultiplier: (json['speedMultiplier'] as num?)?.toDouble() ?? 1.0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Method for JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'levels': levels.map((level) => level.toJson()).toList(),
      'type': type.name,
      'themeColor': themeColor.value,
      'costMultiplier': costMultiplier,
      'incomeMultiplier': incomeMultiplier,
      'speedMultiplier': speedMultiplier,
      'metadata': metadata,
    };
  }
}
