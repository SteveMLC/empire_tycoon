import 'package:flutter/material.dart';
import 'game_state_events.dart';

// Class to represent a property upgrade
class RealEstateUpgrade {
  final String id; // Unique identifier for the upgrade
  final String description; // Description/name of the upgrade
  final double cost; // Cost to purchase the upgrade
  final double newIncomePerSecond; // New income after applying the upgrade
  bool purchased; // Whether the upgrade has been purchased

  RealEstateUpgrade({
    required this.id,
    required this.description,
    required this.cost,
    required this.newIncomePerSecond,
    this.purchased = false,
  });

  // For serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'cost': cost,
      'newIncomePerSecond': newIncomePerSecond,
      'purchased': purchased,
    };
  }

  // For deserialization
  factory RealEstateUpgrade.fromJson(Map<String, dynamic> json) {
    return RealEstateUpgrade(
      id: json['id'],
      description: json['description'],
      cost: json['cost'],
      newIncomePerSecond: json['newIncomePerSecond'],
      purchased: json['purchased'] ?? false,
    );
  }
}

class RealEstateProperty {
  final String id;
  final String name;
  final double purchasePrice;
  final double baseCashFlowPerSecond; // Renamed from cashFlowPerSecond
  bool unlocked;
  int owned;
  List<RealEstateUpgrade> upgrades; // Changed from final to allow modification
  
  // Current active income per second (affected by upgrades)
  double get cashFlowPerSecond {
    if (upgrades.isEmpty || !upgrades.any((u) => u.purchased)) {
      return baseCashFlowPerSecond;
    }
    
    // Return the income from the highest purchased upgrade
    var purchasedUpgrades = upgrades.where((u) => u.purchased).toList();
    if (purchasedUpgrades.isEmpty) return baseCashFlowPerSecond;
    
    // Sort by newIncomePerSecond (descending) and take the highest
    purchasedUpgrades.sort((a, b) => b.newIncomePerSecond.compareTo(a.newIncomePerSecond));
    return purchasedUpgrades.first.newIncomePerSecond;
  }

  // Calculate the total value including purchased upgrades
  double get totalValue {
    double value = purchasePrice;
    for (var upgrade in upgrades) {
      if (upgrade.purchased) {
        value += upgrade.cost;
      }
    }
    return value;
  }

  // NEW: Calculate the total value for ALL owned units of this property, including upgrades
  double get getCurrentTotalValue {
    return totalValue * owned;
  }

  RealEstateProperty({
    required this.id,
    required this.name,
    required this.purchasePrice,
    required this.baseCashFlowPerSecond,
    this.unlocked = true,
    this.owned = 0,
    List<RealEstateUpgrade>? upgrades,
  }) : this.upgrades = upgrades ?? [];

  // Return the total income per second for this property based on how many are owned
  double getTotalIncomePerSecond({bool isResilienceActive = false}) {
    double baseIncome = cashFlowPerSecond * owned;
    
    return baseIncome;
  }

  // Calculate ROI (Return on Investment) as a percentage
  double getROI() {
    // Return on investment calculated as income per second divided by purchase price * 100
    return (cashFlowPerSecond / purchasePrice) * 100;
  }
  
  // Get next available upgrade
  RealEstateUpgrade? getNextAvailableUpgrade() {
    if (owned <= 0) return null; // Can't upgrade unowned properties
    
    // Find first unpurchased upgrade
    for (var upgrade in upgrades) {
      if (!upgrade.purchased) {
        return upgrade;
      }
    }
    return null; // All upgrades purchased
  }
  
  // Check if all upgrades are purchased
  bool get allUpgradesPurchased {
    if (upgrades.isEmpty) return true;
    return upgrades.every((upgrade) => upgrade.purchased);
  }
  
  // JSON conversion methods
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'purchasePrice': purchasePrice,
      'baseCashFlowPerSecond': baseCashFlowPerSecond,
      'unlocked': unlocked,
      'owned': owned,
      'upgrades': upgrades.map((u) => u.toJson()).toList(),
    };
  }

  factory RealEstateProperty.fromJson(Map<String, dynamic> json) {
    return RealEstateProperty(
      id: json['id'],
      name: json['name'],
      purchasePrice: json['purchasePrice'],
      baseCashFlowPerSecond: json['baseCashFlowPerSecond'] ?? json['cashFlowPerSecond'], // Handle legacy data
      unlocked: json['unlocked'] ?? true,
      owned: json['owned'] ?? 0,
      upgrades: (json['upgrades'] as List<dynamic>?)
          ?.map((u) => RealEstateUpgrade.fromJson(u))
          ?.toList() ?? [],
    );
  }
}

class RealEstateLocale {
  final String id;
  final String name;
  final String theme;
  bool unlocked;
  final IconData icon;
  final List<RealEstateProperty> properties;

  RealEstateLocale({
    required this.id,
    required this.name,
    required this.theme,
    required this.unlocked,
    required this.icon,
    required this.properties,
  });

  // Get the total value of owned properties in this locale (NOW CORRECTED)
  double getTotalValue() {
    double total = 0.0;
    if (properties.isEmpty) return total;
    
    for (var property in properties) {
      // Use the new getter that includes purchase price, upgrades, and owned count
      total += property.getCurrentTotalValue;
    }
    return total;
  }
  
  // Get the total number of properties owned in this locale
  int getTotalPropertiesOwned() {
    int total = 0;
    if (properties.isEmpty) return total;
    
    for (var property in properties) {
      total += property.owned;
    }
    return total;
  }

  // Get the total income from this locale per second
  double getTotalIncomePerSecond() {
    double total = 0.0;
    if (properties.isEmpty) return total;
    
    for (var property in properties) {
      total += property.getTotalIncomePerSecond();
    }
    
    return total;
  }
  
  // Get the income with event penalty applied (if affected)
  double getIncomeWithEventPenalty(bool isAffectedByEvent) {
    double baseIncome = getTotalIncomePerSecond();
    
    // Apply event penalty if this locale is affected by an active event
    if (isAffectedByEvent) {
      // Apply the negative event multiplier (hardcoded as -0.25 or -25%)
      baseIncome += baseIncome * -0.25;
    }
    
    return baseIncome;
  }

  // Check if any properties are owned in this locale
  bool hasOwnedProperties() {
    if (properties.isEmpty) return false;
    return properties.any((property) => property.owned > 0);
  }
}
