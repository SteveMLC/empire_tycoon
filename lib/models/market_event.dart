import 'dart:math';

// Represents a market event that affects investment prices
class MarketEvent {
  final String name;
  final String description;
  final Map<String, double> categoryImpacts; // e.g., {'Technology': 1.05} for 5% boost
  int durationDays; // How many days the event lasts
  int remainingDays; // Days left for the event

  MarketEvent({
    required this.name,
    required this.description,
    required this.categoryImpacts,
    required this.durationDays,
  }) : remainingDays = durationDays; // Initialize remaining days

  // Method to simulate daily update (could be moved here if needed)
  // void updateDaily() {
  //   remainingDays--;
  // }

  // Check if the event is still active
  bool get isActive => remainingDays > 0;

  // Method to potentially serialize/deserialize if needed
  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'categoryImpacts': categoryImpacts,
        'durationDays': durationDays,
        'remainingDays': remainingDays,
      };

  factory MarketEvent.fromJson(Map<String, dynamic> json) => MarketEvent(
        name: json['name'],
        description: json['description'],
        categoryImpacts: Map<String, double>.from(json['categoryImpacts']),
        durationDays: json['durationDays'],
      )..remainingDays = json['remainingDays']; // Restore remaining days
} 