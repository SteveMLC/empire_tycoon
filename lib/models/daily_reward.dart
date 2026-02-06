import 'package:flutter/foundation.dart';

enum DailyRewardType { cash, boost, mega, pp }

class DailyReward {
  final int day;
  final DailyRewardType type;
  final double value;
  final String description;
  final String icon;

  const DailyReward({
    required this.day,
    required this.type,
    required this.value,
    required this.description,
    required this.icon,
  });
}

class DailyRewardsState {
  DateTime? lastClaimDate;
  int currentStreak;
  int totalDaysClaimed;
  int cycleCount;

  DailyRewardsState({
    this.lastClaimDate,
    this.currentStreak = 1,
    this.totalDaysClaimed = 0,
    this.cycleCount = 0,
  });

  DailyRewardsState copy() {
    return DailyRewardsState(
      lastClaimDate: lastClaimDate,
      currentStreak: currentStreak,
      totalDaysClaimed: totalDaysClaimed,
      cycleCount: cycleCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lastClaimDate': lastClaimDate?.toIso8601String(),
      'currentStreak': currentStreak,
      'totalDaysClaimed': totalDaysClaimed,
      'cycleCount': cycleCount,
    };
  }

  factory DailyRewardsState.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['lastClaimDate'] != null) {
      try {
        parsedDate = DateTime.parse(json['lastClaimDate']);
      } catch (_) {
        parsedDate = null;
      }
    }

    int streak = json['currentStreak'] ?? 1;
    if (streak < 1) {
      streak = 1;
    }

    int totalClaimed = json['totalDaysClaimed'] ?? 0;
    if (totalClaimed < 0) {
      totalClaimed = 0;
    }

    int cycles = json['cycleCount'] ?? 0;
    if (cycles < 0) {
      cycles = 0;
    }

    return DailyRewardsState(
      lastClaimDate: parsedDate,
      currentStreak: streak,
      totalDaysClaimed: totalClaimed,
      cycleCount: cycles,
    );
  }

  @override
  String toString() {
    return 'DailyRewardsState(lastClaimDate: $lastClaimDate, currentStreak: $currentStreak, totalDaysClaimed: $totalDaysClaimed, cycleCount: $cycleCount)';
  }

  @visibleForTesting
  void normalize() {
    if (currentStreak < 1) {
      currentStreak = 1;
    }
    if (currentStreak > 7) {
      currentStreak = 7;
    }
    if (totalDaysClaimed < 0) {
      totalDaysClaimed = 0;
    }
    if (cycleCount < 0) {
      cycleCount = 0;
    }
  }
}

class DailyRewardCheckResult {
  final DailyReward reward;
  final bool streakBroken;
  final int? previousStreak;

  const DailyRewardCheckResult({
    required this.reward,
    required this.streakBroken,
    this.previousStreak,
  });
}
