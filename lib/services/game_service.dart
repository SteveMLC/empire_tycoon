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

      // CRITICAL FIX: Timestamp analysis (keep for logging, but remove redundant calculation)
      final DateTime lastSavedTime = _gameState.lastSaved;
      print("⏱️ TIMESTAMP ANALYSIS: Last saved at ${TimeUtils.formatTime(lastSavedTime)}");
      print("⏱️ TIMESTAMP ANALYSIS: App started at ${TimeUtils.formatTime(appStartTime)}");

      // Check if the last saved time is potentially old (informational)
      if (lastSavedTime.isBefore(appStartTime)) {
          final Duration offlineDurationCheck = appStartTime.difference(lastSavedTime);
          print("⏰ Informational: Time since last save vs app start: ${offlineDurationCheck.inSeconds} seconds. Actual offline calculation occurs during GameState.fromJson based on loaded lastOpened time.");
      } else {
          print("⏰ Informational: lastSaved time is not before app start time. Likely first run or clock issue. Actual offline calculation occurs during GameState.fromJson.");
      }

      _gameState.isInitialized = true;

      // CRITICAL FIX: Auto-save system setup
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

  SoundManager get soundManager => _soundManager;
  GameState get gameState => _gameState;

  // Private save implementation (now redundant due to public method)
  // void _saveGame() {
  //   saveGame();
  // }

  Future<bool> saveGame() async {
    DateTime saveStartTime = DateTime.now();
    print('💾 [${TimeUtils.formatTime(saveStartTime)}] saveGame initiated...');
    try {
      // Log the lastOpened timestamp BEFORE creating JSON
      print('💾 [SAVE] GameState.lastOpened timestamp before toJson: ${_gameState.lastOpened.toIso8601String()}');

      final Map<String, dynamic> gameJson = _gameState.toJson();
      final String gameData = jsonEncode(gameJson);
      final int dataLength = gameData.length;

      // Print diagnostics for web platform due to potential size limits
      if (kIsWeb) {
        print("📊 [SAVE] Game data size: $dataLength bytes");
        if (dataLength > 500000) { // 500KB precaution
          print("⚠️ [SAVE] Game data is very large, might exceed storage limits on web");
        }
      }

      // Log snippet of data being saved
      String dataSnippet = dataLength > 200 ? '${gameData.substring(0, 100)}...${gameData.substring(dataLength - 100)}' : gameData;
      print('💾 [SAVE] Preparing to save data snippet: $dataSnippet');

      _gameState.lastSaved = DateTime.now(); // Update timestamp *just* before saving

      print('💾 [SAVE] Calling SharedPreferences.setString for key: $_saveKey');
      bool success = await _prefs.setString(_saveKey, gameData);
      DateTime saveEndTime = DateTime.now();
      Duration saveDuration = saveEndTime.difference(saveStartTime);
      print('💾 [SAVE] SharedPreferences.setString completed in ${saveDuration.inMilliseconds}ms. Success: $success');

      if (success) {
        print('✅ Game saved successfully at ${TimeUtils.formatTime(DateTime.now())}');
      } else {
        print('❌ Failed to save game data (SharedPreferences.setString returned false)');
      }
      return success;
    } catch (e, stackTrace) {
      print('❌ Error preparing or executing game save: $e');
      print('❌ StackTrace: $stackTrace'); // Print stack trace for save errors
      return false;
    }
  }

  Future<void> _loadGame() async {
    DateTime loadStartTime = DateTime.now();
    print('🔍 [${TimeUtils.formatTime(loadStartTime)}] Attempting to load saved game data for key: $_saveKey');
    final String? gameData = _prefs.getString(_saveKey);

    if (gameData != null && gameData.isNotEmpty) {
      final int dataLength = gameData.length;
      print('📖 [LOAD] Found saved game data of size: $dataLength bytes');
      // Log snippet of data being loaded
      String dataSnippet = dataLength > 200 ? '${gameData.substring(0, 100)}...${gameData.substring(dataLength - 100)}' : gameData;
      print('📖 [LOAD] Retrieved data snippet: $dataSnippet');
      try {
        print('📖 [LOAD] Attempting jsonDecode...');
        final Map<String, dynamic> gameJson = jsonDecode(gameData);
        print('📖 [LOAD] jsonDecode successful. Calling GameState.fromJson...');
        await _gameState.fromJson(gameJson); // ADDED await - fromJson is ASYNCHRONOUS
        DateTime loadEndTime = DateTime.now();
        Duration loadDuration = loadEndTime.difference(loadStartTime);
        print('✅ Game loaded successfully from save in ${loadDuration.inMilliseconds}ms');
      } catch (e, stackTrace) {
        print('❌ Error loading/parsing game data: $e');
        print('❌ StackTrace: $stackTrace'); // Print stack trace for load errors
        print('⚠️ Proceeding with default/new game state due to load error.');
        // Ensure real estate is initialized even if load fails
        if (_gameState.realEstateInitializationFuture != null) {
           print('⏳ [LOAD_ERROR] Ensuring real estate upgrades are initialized...');
           await _gameState.realEstateInitializationFuture;
        }
        // Optionally: Clear the corrupted save data?
        // await _prefs.remove(_saveKey);
        // print('🗑️ Removed potentially corrupted save data after load error.');
      }
    } else {
      if (gameData == null) {
        print('ℹ️ No saved game found (key: $_saveKey not found). Starting new game.');
      } else { // gameData is empty string
         print('ℹ️ Saved game data is empty string. Starting new game.');
         // Optionally remove the empty key
         // await _prefs.remove(_saveKey);
      }
      // Ensure real estate is initialized even for a new game
      if (_gameState.realEstateInitializationFuture != null) {
          print('⏳ [NEW_GAME] Ensuring real estate upgrades are initialized...');
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