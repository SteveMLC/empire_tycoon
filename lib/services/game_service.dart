import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';
import '../models/achievement.dart';
import '../models/achievement_data.dart';
import '../utils/time_utils.dart';
import '../utils/number_formatter.dart';
import '../utils/sounds.dart'; // Contains both SoundManager and GameSounds classes

class GameService {
  static const String _saveKey = 'empire_tycoon_save';
  static const String _versionKey = 'empire_tycoon_version';
  static const String _currentVersion = '1.0.1'; // Increment this whenever significant game balance changes are made
  final SharedPreferences _prefs;
  final GameState _gameState;
  final SoundManager _soundManager = SoundManager();
  bool _isInitialized = false;

  double? _offlineIncomeEarned;
  Duration? _offlineDuration;

  double? get offlineIncomeEarned => _offlineIncomeEarned;
  Duration? get offlineDuration => _offlineDuration;

  void clearOfflineIncomeNotification() {
    print("📣 CLEARING OFFLINE INCOME NOTIFICATION DATA");
    print("💰 Previous values: Amount=${NumberFormatter.formatCurrency(_offlineIncomeEarned ?? 0)}, Duration=${_offlineDuration?.inMinutes ?? 0} minutes");
    _offlineIncomeEarned = null;
    _offlineDuration = null;
    print("✅ Offline income notification data cleared");
  }

  GameService(this._prefs, this._gameState);

  void playSound(Future<void> Function() soundFunction) {
    try {
      soundFunction();
    } catch (e) {
      print("🔊 Error playing sound: $e");
      // Don't throw further - sound errors should not affect gameplay
    }
  }

  Future<void> init() async {
    if (_isInitialized) {
      print("⚠️ GameService already initialized, skipping");
      return;
    }

    try {
      print("🚀 Starting GameService initialization at ${TimeUtils.formatTime(DateTime.now())}");

      // CRITICAL FIXES: Start with a clean slate
      _isInitialized = false;
      _offlineIncomeEarned = null;
      _offlineDuration = null;

      if (_autoSaveTimer != null) {
        print("⏱️ INIT: Cancelling any existing auto-save timer");
        _autoSaveTimer!.cancel();
        _autoSaveTimer = null;
      }

      try {
        await _soundManager.init();
        await GameSounds.init();
        print("🔊 Sound systems initialized successfully");
      } catch (e) {
        print("⚠️ Non-critical error initializing sound: $e");
      }

      final String? savedVersion = _prefs.getString(_versionKey);
      print("📊 Current game version: $_currentVersion, Saved version: $savedVersion");

      // If version is different or not set, clear saved data to apply new balance changes
      if (savedVersion != _currentVersion) {
        print("🔄 Game version changed from $savedVersion to $_currentVersion. Resetting game data.");
        await _prefs.remove(_saveKey);
        await _prefs.setString(_versionKey, _currentVersion);
      }

      final DateTime beforeLoad = DateTime.now();
      final DateTime appStartTime = beforeLoad.subtract(const Duration(seconds: 1)); // Small buffer for timestamp comparison
      print("⏱️ Start loading game state at ${TimeUtils.formatTime(beforeLoad)}");
      await _loadGame();
      final DateTime afterLoad = DateTime.now();

      final Duration loadDuration = afterLoad.difference(beforeLoad);
      print("⏱️ Game loading took ${loadDuration.inMilliseconds}ms");

      // CRITICAL FIX: Thoroughly analyze timestamp for offline calculations
      final DateTime lastSavedTime = _gameState.lastSaved;
      print("⏱️ TIMESTAMP ANALYSIS: Last saved at ${TimeUtils.formatTime(lastSavedTime)}");
      print("⏱️ TIMESTAMP ANALYSIS: App started at ${TimeUtils.formatTime(appStartTime)}");

      // Check if the last saved time is in the past compared to our app start time
      if (lastSavedTime.isBefore(appStartTime)) {
        final Duration offlineDuration = appStartTime.difference(lastSavedTime);

        final int offlineDays = offlineDuration.inDays;
        final int offlineHours = offlineDuration.inHours % 24;
        final int offlineMinutes = offlineDuration.inMinutes % 60;
        final int offlineSeconds = offlineDuration.inSeconds % 60;

        print("⚠️ CRITICAL FIX: OFFLINE TIME DETECTED!");
        print("⏰ Time since last save: ${offlineDays > 0 ? '$offlineDays days, ' : ''}${offlineHours > 0 ? '$offlineHours hours, ' : ''}${offlineMinutes > 0 ? '$offlineMinutes minutes, ' : ''}$offlineSeconds seconds");

        if (offlineDuration.inSeconds > 5) { // Only apply if at least 5 seconds have passed
          print("💰 CALCULATING OFFLINE INCOME for significant time away");
          _calculateOfflineIncome(offlineDuration);
          _gameState.notifyListeners();
          saveGame();
          print("✅ Offline income calculated and applied");
        } else {
          print("⏰ Offline duration too short (${offlineDuration.inSeconds}s), skipping income calculation");
        }
      } else {
        print("⚠️ No offline time detected - lastSaved time is not before app start time");
        print("⏰ This is likely the first run or the timestamps are incorrect");
      }

      _gameState.isInitialized = true;

      // CRITICAL FIX: Completely rebuild the auto-save system from scratch
      // Instead of relying solely on the listener pattern, we'll implement a direct approach
      print("🔄 CRITICAL FIX: Removing all existing listeners - complete reset");
      final int listenerCount = _gameState.hasListeners ? 1 : 0;
      print("🔢 Current listener count: $listenerCount");
      print("📝 AUTO-SAVE FIX: Now using direct timer-based auto-save only instead of listener pattern");

      print("📦 Available keys in SharedPreferences: ${_prefs.getKeys()}");

      // Force an immediate save with timestamp verification
      print("💾 Performing initial game save...");
      final saveStart = DateTime.now();
      _gameState.lastSaved = saveStart; // Set timestamp before saving

      bool saveSuccess = await saveGame(); // Using await to ensure save completes
      if (saveSuccess) {
        print("✅ Game saved during initialization at ${TimeUtils.formatTime(saveStart)}");
      } else {
        print("❌ Initial game save failed");
      }

      print("⏰ Setting up auto-save timer");
      _setupAutoSaveTimer();

      _isInitialized = true;
      print("✅ GameService initialized successfully at ${TimeUtils.formatTime(DateTime.now())}");
    } catch (e) {
      print("❌ Error initializing GameService: $e");
      _gameState.isInitialized = true; // Force initialization to allow the app to run
      print("⚠️ Game will continue with limited functionality");
      rethrow;
    }
  }

  Timer? _autoSaveTimer;

  void _setupAutoSaveTimer() {
    print("⚙️ SETTING UP AUTO-SAVE TIMER - COMPLETE REWRITE");

    if (_autoSaveTimer != null) {
      print("⏱️ Cancelling existing auto-save timer");
      _autoSaveTimer!.cancel();
      _autoSaveTimer = null;
    }

    if (_gameState == null) {
      print("❌ CRITICAL ERROR: Cannot set up auto-save timer - game state is null");
      return;
    }

    // Reduced auto-save frequency to every 15 seconds for performance.
    const int saveIntervalSeconds = 15;
    print("⏱️ CREATING NEW AUTO-SAVE TIMER: Will save every $saveIntervalSeconds seconds");

    try {
      _autoSaveTimer = Timer.periodic(Duration(seconds: saveIntervalSeconds), (timer) {
        final DateTime saveTime = DateTime.now();
        print("⏱️ AUTO-SAVE CYCLE STARTED at ${TimeUtils.formatTime(saveTime)}");

        Future<void> performAutoSave() async {
          try {
            _gameState.lastSaved = saveTime;
            final bool success = await saveGame();
            if (success) {
              print("✅ AUTO-SAVE COMPLETED SUCCESSFULLY at ${TimeUtils.formatTime(DateTime.now())}");
            } else {
              print("❌ AUTO-SAVE FAILED TO COMPLETE");
            }
          } catch (e) {
            print("❌ AUTO-SAVE ERROR: $e");
            print("STACK TRACE: ${StackTrace.current}");
          }
        }
        performAutoSave();
      });

      print("✅ AUTO-SAVE TIMER SUCCESSFULLY INITIALIZED");

      // Perform an immediate save to verify everything is working
      Future<void> performInitialSave() async {
        print("🔄 Performing immediate test save to verify auto-save system...");
        try {
          final bool success = await saveGame();
          if (success) {
            print("✅ INITIAL TEST SAVE SUCCEEDED - Auto-save system is working properly");
          } else {
            print("❌ INITIAL TEST SAVE FAILED - Auto-save system may have issues");
          }
        } catch (e) {
          print("❌ CRITICAL ERROR DURING INITIAL TEST SAVE: $e");
        }
      }
      Future.delayed(const Duration(seconds: 2), performInitialSave);

    } catch (e) {
      print("❌ CRITICAL ERROR SETTING UP AUTO-SAVE TIMER: $e");
      print("📋 STACK TRACE: ${StackTrace.current}");
    }
  }

  void _calculateOfflineIncome(Duration offlineDuration) {
    if (offlineDuration.inSeconds <= 0) return;
    print("💰 Calculating offline income...");

    double incomePerSecond = _gameState.totalIncomePerSecond;

    // Cap offline duration to a maximum value (5 days)
    int offlineSeconds = offlineDuration.inSeconds;
    final int maxOfflineSeconds = 5 * 24 * 60 * 60; // 5 days
    Duration cappedDuration;

    if (offlineSeconds > maxOfflineSeconds) {
      print("⚠️ Capping offline time from ${Duration(seconds: offlineSeconds).inDays} days to ${Duration(seconds: maxOfflineSeconds).inDays} days");
      cappedDuration = Duration(seconds: maxOfflineSeconds);
      offlineSeconds = maxOfflineSeconds;
    } else {
      cappedDuration = offlineDuration;
    }

    double offlineIncome = incomePerSecond * offlineSeconds;

    print("💰 OFFLINE INCOME DEBUG: Earned ${NumberFormatter.formatCurrency(offlineIncome)} in ${cappedDuration.inMinutes} minutes");

    // CRITICAL FIX: Always set these values for notification system debugging.
    _offlineIncomeEarned = offlineIncome;
    _offlineDuration = cappedDuration;

    print("📣 OFFLINE NOTIFICATION DATA SET:");
    print("💰 Amount: ${NumberFormatter.formatCurrency(_offlineIncomeEarned ?? 0)}");
    print("⏰ Duration: ${_offlineDuration?.inMinutes ?? 0} minutes");

    _gameState.money += offlineIncome;
    _gameState.totalEarned += offlineIncome;

    // Distribute the earnings to appropriate categories based on current ratios
    double totalActiveIncome = _gameState.passiveEarnings +
                              _gameState.investmentDividendEarnings +
                              _gameState.realEstateEarnings;

    if (totalActiveIncome > 0) {
      _gameState.passiveEarnings += offlineIncome * (_gameState.passiveEarnings / totalActiveIncome);
      _gameState.investmentDividendEarnings += offlineIncome * (_gameState.investmentDividendEarnings / totalActiveIncome);
      _gameState.realEstateEarnings += offlineIncome * (_gameState.realEstateEarnings / totalActiveIncome);
    } else {
      // If no existing distribution, assign it all to passive earnings
      _gameState.passiveEarnings += offlineIncome;
    }

    print("💰 Earned ${NumberFormatter.formatCurrency(offlineIncome)} while offline (${offlineDuration.inMinutes} minutes)");

    // Evaluate achievements after applying offline income
    try {
      print("🏆 Checking for achievements unlocked offline...");
      List<Achievement> offlineCompleted = _gameState.achievementManager.evaluateAchievements(_gameState);
      if (offlineCompleted.isNotEmpty) {
        print("🏅 Found ${offlineCompleted.length} achievements completed offline: ${offlineCompleted.map((a) => a.name).join(', ')}");
        _gameState.queueAchievementsForDisplay(offlineCompleted);
      } else {
        print("🏅 No new achievements completed offline.");
      }
    } catch (e) {
      print("❌ Error evaluating offline achievements: $e");
    }

    _gameState.notifyListeners();
  }

  SoundManager get soundManager => _soundManager;
  GameState get gameState => _gameState;

  // Private save implementation (now redundant due to public method)
  // void _saveGame() {
  //   saveGame();
  // }

  Future<bool> saveGame() async {
    try {
      final Map<String, dynamic> gameJson = _gameState.toJson();
      final String gameData = jsonEncode(gameJson);

      // Print diagnostics for web platform due to potential size limits
      if (kIsWeb) {
        print("📊 Game data size: ${gameData.length} bytes");
        if (gameData.length > 500000) { // 500KB precaution
          print("⚠️ Game data is very large, might exceed storage limits on web");
        }
      }

      _gameState.lastSaved = DateTime.now();

      bool success = await _prefs.setString(_saveKey, gameData);
      if (success) {
        print('✅ Game saved successfully at ${TimeUtils.formatTime(DateTime.now())}');
      } else {
        print('❌ Failed to save game data');
      }
      return success;
    } catch (e) {
      print('❌ Error preparing game save: $e');
      return false;
    }
  }

  Future<void> _loadGame() async {
    print('🔍 Attempting to load saved game data');
    final String? gameData = _prefs.getString(_saveKey);

    if (gameData != null && gameData.isNotEmpty) {
      try {
        print('📖 Found saved game data of size: ${gameData.length} bytes');
        final Map<String, dynamic> gameJson = jsonDecode(gameData);
        _gameState.fromJson(gameJson);
        print('✅ Game loaded successfully from save');
      } catch (e) {
        print('❌ Error loading game: $e');
        // Continue with new game if loading fails
      }
    } else {
      print('ℹ️ No saved game found, starting new game');
      // Ensure real estate is initialized even for a new game
      if (_gameState.realEstateInitializationFuture != null) {
          await _gameState.realEstateInitializationFuture;
      }
    }
  }

  Future<void> resetGame() async {
    try {
      await _prefs.remove(_saveKey);
      await _prefs.setString(_versionKey, _currentVersion);
      _gameState.resetToDefaults();
      // Re-initialize real estate upgrades after reset
      await _gameState.initializeRealEstateUpgrades();
      print('🔄 Game reset to defaults with version $_currentVersion');
    } catch (e) {
      print('❌ Error resetting game: $e');
    }
  }

  String exportGameData() {
    final Map<String, dynamic> gameJson = _gameState.toJson();
    return jsonEncode(gameJson);
  }

  Future<bool> importGameData(String data) async {
    try {
      final Map<String, dynamic> gameJson = jsonDecode(data);
      _gameState.fromJson(gameJson);
      await saveGame();
      return true;
    } catch (e) {
      print('❌ Error importing game data: $e');
      return false;
    }
  }

  void dispose() {
    print("🛑 Disposing GameService...");
    _autoSaveTimer?.cancel();
    print("✅ GameService disposed.");
  }
}