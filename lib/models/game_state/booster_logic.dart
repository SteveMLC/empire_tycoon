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
        // OPTIMIZED: Only notify listeners every 5 seconds or when boost expires
        // This reduces excessive UI rebuilds while keeping functionality
        if (boostRemainingSeconds == 0 || boostRemainingSeconds % 5 == 0) {
          notifyListeners();
        }
      } else {
        timer.cancel();
        _boostTimer = null;
        notifyListeners(); // Always notify when timer ends
      }
    });
  }

  // Helper method to start the ad boost timer
  void _startAdBoostTimer() {
    _adBoostTimer?.cancel();
    _adBoostTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (adBoostRemainingSeconds > 0) {
        adBoostRemainingSeconds--;
        // OPTIMIZED: Only notify listeners every 5 seconds or when boost expires
        // This reduces excessive UI rebuilds while keeping functionality
        if (adBoostRemainingSeconds == 0 || adBoostRemainingSeconds % 5 == 0) {
          notifyListeners();
        }
      } else {
        timer.cancel();
        _adBoostTimer = null;
        notifyListeners(); // Always notify when timer ends
      }
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
        // OPTIMIZED: Only notify listeners every 10 seconds or when boost expires
        // This reduces excessive UI rebuilds while keeping functionality
        if (platinumClickFrenzyRemainingSeconds == 0 || platinumClickFrenzyRemainingSeconds % 10 == 0) {
          notifyListeners(); // Notify UI about remaining time change
        }
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
        // OPTIMIZED: Only notify listeners every 10 seconds or when boost expires
        // This reduces excessive UI rebuilds while keeping functionality
        if (platinumSteadyBoostRemainingSeconds == 0 || platinumSteadyBoostRemainingSeconds % 10 == 0) {
          notifyListeners(); // Notify UI about remaining time change
        }
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