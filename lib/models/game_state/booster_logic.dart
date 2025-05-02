part of '../game_state.dart';

extension BoosterLogic on GameState {
  // Start the standard 2x boost (5 minutes)
  void startBoost() {
    if (!isBoostActive) {
      boostRemainingSeconds = 300; // 5 minutes
      _startBoostTimer();
      notifyListeners();
    }
  }

  // Start the ad boost (10x for 60 seconds)
  void startAdBoost() {
    adBoostRemainingSeconds = 60; // 60 seconds
    _startAdBoostTimer();
    notifyListeners();
  }

  // Helper method to start the boost timer
  void _startBoostTimer() {
    _boostTimer?.cancel();
    _boostTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (boostRemainingSeconds > 0) {
        boostRemainingSeconds--;
      } else {
        timer.cancel();
        _boostTimer = null;
      }
      notifyListeners();
    });
  }

  // Helper method to start the ad boost timer
  void _startAdBoostTimer() {
    _adBoostTimer?.cancel();
    _adBoostTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (adBoostRemainingSeconds > 0) {
        adBoostRemainingSeconds--;
      } else {
        timer.cancel();
        _adBoostTimer = null;
      }
      notifyListeners();
    });
  }

  // Public method to cancel the standard boost timer
  void cancelBoostTimer() {
    _boostTimer?.cancel();
    _boostTimer = null;
  }

  // Public method to cancel the ad boost timer
  void cancelAdBoostTimer() {
    _adBoostTimer?.cancel();
    _adBoostTimer = null;
  }

  // Helper methods for Platinum Booster Timers
  void _startPlatinumClickFrenzyTimer() {
    _platinumClickFrenzyTimer?.cancel(); // Cancel existing timer if any
    _platinumClickFrenzyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (platinumClickFrenzyRemainingSeconds > 0) {
        platinumClickFrenzyRemainingSeconds--;
        notifyListeners(); // Notify UI about remaining time change
      } else {
        timer.cancel();
        _platinumClickFrenzyTimer = null;
        platinumClickFrenzyEndTime = null; // Clear end time when timer finishes
        print("INFO: Click Frenzy boost expired.");
        notifyListeners(); // Notify UI that boost is no longer active
      }
    });
  }

  void _startPlatinumSteadyBoostTimer() {
    _platinumSteadyBoostTimer?.cancel(); // Cancel existing timer if any
    _platinumSteadyBoostTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (platinumSteadyBoostRemainingSeconds > 0) {
        platinumSteadyBoostRemainingSeconds--;
        notifyListeners(); // Notify UI about remaining time change
      } else {
        timer.cancel();
        _platinumSteadyBoostTimer = null;
        platinumSteadyBoostEndTime = null; // Clear end time when timer finishes
        print("INFO: Steady Boost expired.");
        notifyListeners(); // Notify UI that boost is no longer active
      }
    });
  }

  void _cancelPlatinumTimers() {
    _platinumClickFrenzyTimer?.cancel();
    _platinumSteadyBoostTimer?.cancel();
    _platinumClickFrenzyTimer = null;
    _platinumSteadyBoostTimer = null;
  }
} 