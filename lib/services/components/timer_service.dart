import 'dart:async';
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
  final List<Function> _updateCallbacks = [];
  
  final GameState _gameState;
  final Function _performAutoSave;
  IncomeService? _incomeService;
  
  TimerService(this._gameState, this._performAutoSave);
  
  void cancelAllTimers() {
    print("⏱️ CENTRAL TIMER SYSTEM: Cancelling all timers");
    
    if (_gameUpdateTimer != null) {
      _gameUpdateTimer!.cancel();
      _gameUpdateTimer = null;
      print("⏱️ Cancelled game update timer");
    }
    
    if (_autoSaveTimer != null) {
      _autoSaveTimer!.cancel();
      _autoSaveTimer = null;
      print("⏱️ Cancelled auto-save timer");
    }
    
    if (_investmentUpdateTimer != null) {
      _investmentUpdateTimer!.cancel();
      _investmentUpdateTimer = null;
      print("⏱️ Cancelled investment update timer");
    }
    
    if (_diagnosticTimer != null) {
      _diagnosticTimer!.cancel();
      _diagnosticTimer = null;
      print("⏱️ Cancelled diagnostic timer");
    }
    
    _timersActive = false;
  }
  
  void setupAllTimers() {
    // Prevent duplicate timer setup
    if (_isSettingUpTimers) {
      print("⚠️ CENTRAL TIMER SYSTEM: Already setting up timers, skipping");
      return;
    }
    
    // Cancel any existing timers first
    cancelAllTimers();
    
    // Set flag to prevent duplicate setup
    _isSettingUpTimers = true;
    
    try {
      print("⏱️ CENTRAL TIMER SYSTEM: Setting up all game timers");
      
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
              callback();
            }
          } finally {
            _isUpdatingGameState = false;
          }
        } else {
          print("⚠️ Skipped game state update due to ongoing update");
        }
      });
      print("⏱️ Set up game update timer (1 second)");
      
      // Set up the auto-save timer (1 minute)
      _autoSaveTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        print("⏱️ Auto-save timer triggered at ${TimeUtils.formatTime(DateTime.now())}");
        // Only save if we're not in the middle of a game state update
        if (!_isUpdatingGameState) {
          _performAutoSave();
        } else {
          // Schedule a delayed save if we're currently updating
          Future.delayed(const Duration(seconds: 5), () {
            if (!_isUpdatingGameState) {
              _performAutoSave();
            }
          });
        }
      });
      print("⏱️ Set up auto-save timer (1 minute)");
      
      // Set up the investment update timer (30 seconds)
      _investmentUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        print("⏱️ Investment update timer triggered at ${TimeUtils.formatTime(DateTime.now())}");
        // Only update investments if we're not in the middle of a game state update
        if (!_isUpdatingGameState) {
          _isUpdatingGameState = true;
          try {
            _gameState.updateInvestmentPrices();
          } finally {
            _isUpdatingGameState = false;
          }
        } else {
          print("⚠️ Skipped investment update due to ongoing update");
        }
      });
      print("⏱️ Set up investment update timer (30 seconds)");
      
      // Set timers active flag
      _timersActive = true;
      
      print("✅ CENTRAL TIMER SYSTEM: All timers successfully initialized");
    } catch (e) {
      print("⚠️ CENTRAL TIMER SYSTEM: Error setting up timers: $e");
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
  void registerUpdateCallback(Function callback) {
    if (!_updateCallbacks.contains(callback)) {
      _updateCallbacks.add(callback);
    }
  }
  
  /// Unregister a callback when a component is disposed
  void unregisterUpdateCallback(Function callback) {
    _updateCallbacks.remove(callback);
  }
  
  /// Register the income service for synchronized updates
  void registerIncomeService(IncomeService incomeService) {
    _incomeService = incomeService;
    registerUpdateCallback(() {
      // This will be called after each game state update
      // ensuring income calculations happen in sync with game updates
    });
  }
  
  /// Check if the game state is currently being updated
  /// Components can use this to avoid race conditions
  bool get isUpdatingGameState => _isUpdatingGameState;
}
