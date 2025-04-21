import 'package:flutter/material.dart';

/// Represents an active gameplay challenge.
class Challenge {
  final String itemId; // ID of the vault item that triggered the challenge
  final DateTime startTime;
  final Duration duration;
  final double goalEarnedAmount; // Amount of money that needs to be earned during the challenge
  final double startTotalEarned; // totalEarned value when the challenge started
  final int rewardPP;

  Challenge({
    required this.itemId,
    required this.startTime,
    required this.duration,
    required this.goalEarnedAmount,
    required this.startTotalEarned,
    required this.rewardPP,
  });

  /// Checks if the challenge is still active based on the current time.
  bool isActive(DateTime currentTime) {
    return currentTime.difference(startTime) <= duration;
  }

  /// Calculates the remaining time for the challenge.
  Duration remainingTime(DateTime currentTime) {
    final elapsed = currentTime.difference(startTime);
    if (elapsed >= duration) {
      return Duration.zero;
    }
    return duration - elapsed;
  }

  /// Checks if the challenge goal was met based on the totalEarned amount at the end.
  bool wasSuccessful(double endTotalEarned) {
     final earnedDuringChallenge = endTotalEarned - startTotalEarned;
     return earnedDuringChallenge >= goalEarnedAmount;
  }

  // Potential future additions:
  // - Visual progress tracking (e.g., currentEarned / goalEarnedAmount)
  // - Specific challenge type enum if more challenges are added
  // - Serialization methods (toJson/fromJson) if needed for persistence
} 