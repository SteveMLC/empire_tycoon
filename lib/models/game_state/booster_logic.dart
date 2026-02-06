part of '../game_state.dart';

extension BoosterLogic on GameState {
  // Start the standard 2x boost (5 minutes)
  void startBoost() {
    if (!isBoostActive) {
      boostRemainingSeconds = 300; // 5 minutes
      notifyListeners();
    }
  }

  // Start or extend the standard boost for a specific duration.
  void startBoostForDuration(Duration duration) {
    final int nextSeconds = duration.inSeconds;
    if (nextSeconds <= 0) return;
    if (boostRemainingSeconds < nextSeconds) {
      boostRemainingSeconds = nextSeconds;
      notifyListeners();
    }
  }

  // Start the ad boost (10x for 60 seconds)
  void startAdBoost() {
    adBoostRemainingSeconds = 60; // 60 seconds
    notifyListeners();
  }

  // Public method to cancel the standard boost timer
  void cancelBoostTimer() {
    if (boostRemainingSeconds > 0) {
      boostRemainingSeconds = 0;
      notifyListeners();
    }
  }

  // Public method to cancel the ad boost timer
  void cancelAdBoostTimer() {
    if (adBoostRemainingSeconds > 0) {
      adBoostRemainingSeconds = 0;
      notifyListeners();
    }
  }

  void _cancelPlatinumTimers() {
    if (platinumClickFrenzyRemainingSeconds > 0 ||
        platinumSteadyBoostRemainingSeconds > 0 ||
        platinumClickFrenzyEndTime != null ||
        platinumSteadyBoostEndTime != null) {
      platinumClickFrenzyRemainingSeconds = 0;
      platinumSteadyBoostRemainingSeconds = 0;
      platinumClickFrenzyEndTime = null;
      platinumSteadyBoostEndTime = null;
      notifyListeners();
    }
  }
} 
