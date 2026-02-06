import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/game_state.dart';
import '../../utils/time_utils.dart';
import '../../services/income_service.dart';

/// Timer management component for GameService
/// Centralized timer system to prevent race conditions and duplicate updates
class TimerService {
  // CENTRALIZED TIMER SYSTEM
  Timer? _gameUpdateTimer; // Main game update timer (1 second)
  Timer? _autoSaveTimer;   // Auto-save timer (1 minute)
  Timer? _investmentUpdateTimer; // Investment price update timer (30 seconds)
  Timer? _diagnosticTimer; // Optional diagnostic timer
  
  // Timer tracking variables
  DateTime _lastGameUpdateTime = DateTime.now();
  
  // Flag to track if timers are active
  bool _timersActive = false;
  
  // Flag to prevent duplicate timer setup
  bool _isSettingUpTimers = false;
  
  // Mutex lock for critical operations to prevent race conditions
  bool _isUpdatingGameState = false;
  
  // Registered callbacks for synchronized updates
  final List<void Function(DateTime)> _updateCallbacks = [];
  
  final GameState _gameState;
  final Function _performAutoSave;
  void Function(DateTime)? _incomeUpdateCallback;
  final Map<String, _ScheduledTask> _scheduledTasks = {};
  DateTime? _lastCentralTimerUpdate;
  
  TimerService(this._gameState, this._performAutoSave) {
    registerUpdateCallback(_handleCentralTimers);
  }
  
  void cancelAllTimers() {
    if (kDebugMode) print("⏱️ CENTRAL TIMER SYSTEM: Cancelling all timers");

    if (_gameUpdateTimer != null) {
      _gameUpdateTimer!.cancel();
      _gameUpdateTimer = null;
      if (kDebugMode) print("⏱️ Cancelled game update timer");
    }

    if (_autoSaveTimer != null) {
      _autoSaveTimer!.cancel();
      _autoSaveTimer = null;
      if (kDebugMode) print("⏱️ Cancelled auto-save timer");
    }

    if (_investmentUpdateTimer != null) {
      _investmentUpdateTimer!.cancel();
      _investmentUpdateTimer = null;
      if (kDebugMode) print("⏱️ Cancelled investment update timer");
    }

    if (_diagnosticTimer != null) {
      _diagnosticTimer!.cancel();
      _diagnosticTimer = null;
      if (kDebugMode) print("⏱️ Cancelled diagnostic timer");
    }
    _scheduledTasks.clear();
    _lastCentralTimerUpdate = null;
    _timersActive = false;
  }
  
  void setupAllTimers() {
    // Prevent duplicate timer setup
    if (_isSettingUpTimers) {
      if (kDebugMode) print("⚠️ CENTRAL TIMER SYSTEM: Already setting up timers, skipping");
      return;
    }
    
    // Cancel any existing timers first
    cancelAllTimers();
    
    // Set flag to prevent duplicate setup
    _isSettingUpTimers = true;
    
    try {
      if (kDebugMode) print("⏱️ CENTRAL TIMER SYSTEM: Setting up all game timers");

      // Set up the main game update timer (1 second)
      _gameUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final now = DateTime.now();
        final elapsed = now.difference(_lastGameUpdateTime);
        
        // Skip if less than 0.5 seconds have passed (debounce)
        if (elapsed.inMilliseconds < 500) {
          return;
        }
        
        // Update the last update time
        _lastGameUpdateTime = now;
        
        // Use mutex lock to prevent race conditions
        if (!_isUpdatingGameState) {
          _isUpdatingGameState = true;
          try {
            // Update the game state
            _gameState.updateGameState();
            
            // Notify all registered callbacks
            for (var callback in _updateCallbacks) {
              try {
                callback(now);
              } catch (e) {
                if (kDebugMode) print("⚠️ Timer callback error: $e");
              }
            }
          } finally {
            _isUpdatingGameState = false;
          }
        } else {
          if (kDebugMode) print("⚠️ Skipped game state update due to ongoing update");
        }
      });
      if (kDebugMode) print("⏱️ Set up game update timer (1 second)");
      
      // Set up the auto-save timer (30 seconds)
      _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (kDebugMode) print("⏱️ Auto-save timer triggered at ${TimeUtils.formatTime(DateTime.now())}");
        // Only save if we're not in the middle of a game state update
        if (!_isUpdatingGameState) {
          _performAutoSave();
        } else {
          // Schedule a delayed save if we're currently updating
          Future.delayed(const Duration(seconds: 2), () {
            if (!_isUpdatingGameState) {
              _performAutoSave();
            }
          });
        }
      });
      if (kDebugMode) print("⏱️ Set up auto-save timer (30 seconds)");

      // Set up the investment update timer (30 seconds)
      _investmentUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (kDebugMode) print("⏱️ Investment update timer triggered at ${TimeUtils.formatTime(DateTime.now())}");
        // Only update investments if we're not in the middle of a game state update
        if (!_isUpdatingGameState) {
          _isUpdatingGameState = true;
          try {
            _gameState.updateInvestmentPrices();
          } finally {
            _isUpdatingGameState = false;
          }
        } else {
          if (kDebugMode) print("⚠️ Skipped investment update due to ongoing update");
        }
      });
      if (kDebugMode) print("⏱️ Set up investment update timer (30 seconds)");

      // Set timers active flag
      _timersActive = true;

      if (kDebugMode) print("✅ CENTRAL TIMER SYSTEM: All timers successfully initialized");
    } catch (e) {
      if (kDebugMode) print("⚠️ CENTRAL TIMER SYSTEM: Error setting up timers: $e");
    } finally {
      // Reset the flag regardless of success or failure
      _isSettingUpTimers = false;
    }
  }
  
  bool get timersActive => _timersActive;
  
  void setLastGameUpdateTime(DateTime time) {
    _lastGameUpdateTime = time;
  }
  
  DateTime getLastGameUpdateTime() {
    return _lastGameUpdateTime;
  }
  
  /// Register a callback to be notified when the game state updates
  /// This ensures components are updated in sync with the game state
  void registerUpdateCallback(void Function(DateTime) callback) {
    if (!_updateCallbacks.contains(callback)) {
      _updateCallbacks.add(callback);
    }
  }
  
  /// Unregister a callback when a component is disposed
  void unregisterUpdateCallback(void Function(DateTime) callback) {
    _updateCallbacks.remove(callback);
  }
  
  /// Register the income service for synchronized updates
  void registerIncomeService(IncomeService incomeService) {
    if (_incomeUpdateCallback != null) {
      unregisterUpdateCallback(_incomeUpdateCallback!);
    }

    _incomeUpdateCallback = (DateTime now) {
      // Called after each game state update to keep income in sync.
      final income = incomeService.calculateIncomePerSecond(_gameState);
      _gameState.lastCalculatedIncomePerSecond = income;
      incomeService.notifyListeners();
    };

    registerUpdateCallback(_incomeUpdateCallback!);
  }
  
  /// Check if the game state is currently being updated
  /// Components can use this to avoid race conditions
  bool get isUpdatingGameState => _isUpdatingGameState;

  void scheduleOneShot(String id, Duration delay, void Function() action) {
    _scheduledTasks[id] = _ScheduledTask(DateTime.now().add(delay), action);
  }

  void cancelScheduled(String id) {
    _scheduledTasks.remove(id);
  }

  void _handleCentralTimers(DateTime now) {
    _runScheduledTasks(now);
    _updateBoostTimers(now);
  }

  void _runScheduledTasks(DateTime now) {
    if (_scheduledTasks.isEmpty) {
      return;
    }

    final List<String> dueTaskIds = [];
    _scheduledTasks.forEach((id, task) {
      if (!task.runAt.isAfter(now)) {
        dueTaskIds.add(id);
      }
    });

    for (final id in dueTaskIds) {
      final task = _scheduledTasks.remove(id);
      if (task == null) {
        continue;
      }
      try {
        task.action();
      } catch (e) {
        if (kDebugMode) print("⚠️ Scheduled task error ($id): $e");
      }
    }
  }

  void _updateBoostTimers(DateTime now) {
    if (_lastCentralTimerUpdate == null) {
      _lastCentralTimerUpdate = now;
      return;
    }
    final DateTime lastUpdate = _lastCentralTimerUpdate!;
    final int elapsedSeconds = now.difference(lastUpdate).inSeconds;
    if (elapsedSeconds <= 0) {
      return;
    }
    _lastCentralTimerUpdate = now;

    bool shouldNotify = false;

    final int previousBoostSeconds = _gameState.boostRemainingSeconds;
    if (previousBoostSeconds > 0) {
      final int nextBoostSeconds =
          previousBoostSeconds > elapsedSeconds ? (previousBoostSeconds - elapsedSeconds) : 0;
      if (nextBoostSeconds != previousBoostSeconds) {
        _gameState.boostRemainingSeconds = nextBoostSeconds;
        if (_crossedInterval(previousBoostSeconds, nextBoostSeconds, 5) || nextBoostSeconds == 0) {
          shouldNotify = true;
        }
      }
    }

    final int previousAdBoostSeconds = _gameState.adBoostRemainingSeconds;
    if (previousAdBoostSeconds > 0) {
      final int nextAdBoostSeconds =
          previousAdBoostSeconds > elapsedSeconds ? (previousAdBoostSeconds - elapsedSeconds) : 0;
      if (nextAdBoostSeconds != previousAdBoostSeconds) {
        _gameState.adBoostRemainingSeconds = nextAdBoostSeconds;
        shouldNotify = true;
      }
    }

    final int previousClickFrenzySeconds = _gameState.platinumClickFrenzyRemainingSeconds;
    if (previousClickFrenzySeconds > 0) {
      final int nextClickFrenzySeconds = previousClickFrenzySeconds > elapsedSeconds
          ? (previousClickFrenzySeconds - elapsedSeconds)
          : 0;
      if (nextClickFrenzySeconds != previousClickFrenzySeconds) {
        _gameState.platinumClickFrenzyRemainingSeconds = nextClickFrenzySeconds;
        if (_crossedInterval(previousClickFrenzySeconds, nextClickFrenzySeconds, 10) ||
            nextClickFrenzySeconds == 0) {
          shouldNotify = true;
        }
        if (nextClickFrenzySeconds == 0) {
          _gameState.platinumClickFrenzyEndTime = null;
          if (kDebugMode) print("INFO: Click Frenzy boost expired.");
        }
      }
    }

    final int previousSteadyBoostSeconds = _gameState.platinumSteadyBoostRemainingSeconds;
    if (previousSteadyBoostSeconds > 0) {
      final int nextSteadyBoostSeconds = previousSteadyBoostSeconds > elapsedSeconds
          ? (previousSteadyBoostSeconds - elapsedSeconds)
          : 0;
      if (nextSteadyBoostSeconds != previousSteadyBoostSeconds) {
        _gameState.platinumSteadyBoostRemainingSeconds = nextSteadyBoostSeconds;
        if (_crossedInterval(previousSteadyBoostSeconds, nextSteadyBoostSeconds, 10) ||
            nextSteadyBoostSeconds == 0) {
          shouldNotify = true;
        }
        if (nextSteadyBoostSeconds == 0) {
          _gameState.platinumSteadyBoostEndTime = null;
          if (kDebugMode) print("INFO: Steady Boost expired.");
        }
      }
    }

    if (shouldNotify) {
      _gameState.notifyListeners();
    }
  }

  bool _crossedInterval(int previous, int next, int interval) {
    if (previous == next) {
      return false;
    }
    for (int value = previous; value >= next; value--) {
      if (value % interval == 0) {
        return true;
      }
    }
    return false;
  }
}

class _ScheduledTask {
  final DateTime runAt;
  final void Function() action;

  _ScheduledTask(this.runAt, this.action);
}
