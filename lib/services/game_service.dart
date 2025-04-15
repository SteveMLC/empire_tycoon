import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';
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
  
  // Offline income tracking
  double? _offlineIncomeEarned;
  Duration? _offlineDuration;
  
  // Getters for offline income notification
  double? get offlineIncomeEarned => _offlineIncomeEarned;
  Duration? get offlineDuration => _offlineDuration;
  
  // Clear offline income notification data
  void clearOfflineIncomeNotification() {
    print("📣 CLEARING OFFLINE INCOME NOTIFICATION DATA");
    print("💰 Previous values: Amount=${NumberFormatter.formatCurrency(_offlineIncomeEarned ?? 0)}, Duration=${_offlineDuration?.inMinutes ?? 0} minutes");
    
    // Set to null to prevent display
    _offlineIncomeEarned = null;
    _offlineDuration = null;
    
    print("✅ Offline income notification data cleared");
  }
  
  // Constructor takes SharedPreferences instance and GameState
  GameService(this._prefs, this._gameState);
  
  // Add a playSound method to the GameService class
  void playSound(Future<void> Function() soundFunction) {
    // This method wraps the sound function to handle errors
    try {
      soundFunction();
    } catch (e) {
      print("🔊 Error playing sound: $e");
      // Don't throw further - sound errors should not affect gameplay
    }
  }
  
  // Initialize game and sound systems with enhanced error handling
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
      
      // Cancel any existing autosave timer immediately
      if (_autoSaveTimer != null) {
        print("⏱️ INIT: Cancelling any existing auto-save timer");
        _autoSaveTimer!.cancel();
        _autoSaveTimer = null;
      }
      
      // Initialize sound systems with error handling
      try {
        await _soundManager.init();
        await GameSounds.init();
        print("🔊 Sound systems initialized successfully");
      } catch (e) {
        print("⚠️ Non-critical error initializing sound: $e");
        // Continue initialization - sound is not critical to gameplay
      }
      
      // Check if game version has changed
      final String? savedVersion = _prefs.getString(_versionKey);
      print("📊 Current game version: $_currentVersion, Saved version: $savedVersion");
      
      // If version is different or not set, clear saved data to apply new balance changes
      if (savedVersion != _currentVersion) {
        print("🔄 Game version changed from $savedVersion to $_currentVersion. Resetting game data.");
        await _prefs.remove(_saveKey);
        await _prefs.setString(_versionKey, _currentVersion);
      }
      
      // Load game data if available
      final DateTime beforeLoad = DateTime.now();
      final DateTime appStartTime = beforeLoad.subtract(const Duration(seconds: 1)); // Small buffer for timestamp comparison
      print("⏱️ Start loading game state at ${TimeUtils.formatTime(beforeLoad)}");
      await _loadGame();
      final DateTime afterLoad = DateTime.now();
      
      // Calculate time difference
      final Duration loadDuration = afterLoad.difference(beforeLoad);
      print("⏱️ Game loading took ${loadDuration.inMilliseconds}ms");
      
      // CRITICAL FIX: Thoroughly analyze timestamp for offline calculations
      // Get lastSaved time from the loaded game state
      final DateTime lastSavedTime = _gameState.lastSaved;
      print("⏱️ TIMESTAMP ANALYSIS: Last saved at ${TimeUtils.formatTime(lastSavedTime)}");
      print("⏱️ TIMESTAMP ANALYSIS: App started at ${TimeUtils.formatTime(appStartTime)}");
      
      // Check if the last saved time is in the past compared to our app start time
      // This indicates the game was closed and is now being reopened
      if (lastSavedTime.isBefore(appStartTime)) {
        // Calculate how long the app was closed
        final Duration offlineDuration = appStartTime.difference(lastSavedTime);
        
        // Format the duration nicely for logging
        final int offlineDays = offlineDuration.inDays;
        final int offlineHours = offlineDuration.inHours % 24;
        final int offlineMinutes = offlineDuration.inMinutes % 60;
        final int offlineSeconds = offlineDuration.inSeconds % 60;
        
        print("⚠️ CRITICAL FIX: OFFLINE TIME DETECTED!");
        print("⏰ Time since last save: ${offlineDays > 0 ? '$offlineDays days, ' : ''}${offlineHours > 0 ? '$offlineHours hours, ' : ''}${offlineMinutes > 0 ? '$offlineMinutes minutes, ' : ''}$offlineSeconds seconds");
        
        // Process offline income (use a very small threshold to ensure it works)
        if (offlineDuration.inSeconds > 5) { // Only apply if at least 5 seconds have passed
          print("💰 CALCULATING OFFLINE INCOME for significant time away");
          _calculateOfflineIncome(offlineDuration);
          
          // Force a state update and save immediately after applying offline income
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
      
      // Set initialization flag
      _gameState.isInitialized = true;
      
      // -----------------------------------
      // COMPLETELY REBUILD THE AUTO-SAVE SYSTEM FROM SCRATCH
      // -----------------------------------
      
      // CRITICAL FIX: We're seeing issues with the listener system
      // Instead of relying solely on the listener pattern, we'll implement a direct approach
      
      // We'll completely remove ALL listeners from the game state first
      print("🔄 CRITICAL FIX: Removing all existing listeners - complete reset");
      
      // Get the list of all current listeners (if any)
      final int listenerCount = _gameState.hasListeners ? 1 : 0;
      print("🔢 Current listener count: $listenerCount");
      
      // Forcefully remove our save game listener (if it exists)
      _gameState.removeListener(_saveGame);
      
      // DO NOT add the listener back - we'll rely solely on the timer-based approach
      print("📝 AUTO-SAVE FIX: Now using direct timer-based auto-save only instead of listener pattern");
      
      // Print information about available keys in SharedPreferences
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
      
      // Set up a dedicated auto-save timer that doesn't depend on state changes
      print("⏰ Setting up auto-save timer");
      _setupAutoSaveTimer();
      
      _isInitialized = true;
      print("✅ GameService initialized successfully at ${TimeUtils.formatTime(DateTime.now())}");
    } catch (e) {
      print("❌ Error initializing GameService: $e");
      // Handle error but don't crash the app
      _gameState.isInitialized = true; // Force initialization to allow the app to run
      print("⚠️ Game will continue with limited functionality");
      rethrow; // Rethrow to allow proper error handling upstream
    }
  }
  
  // Timer for auto-saving
  Timer? _autoSaveTimer;
  
  // Set up a dedicated auto-save timer with complete rewrite
  void _setupAutoSaveTimer() {
    print("⚙️ SETTING UP AUTO-SAVE TIMER - COMPLETE REWRITE");
    
    // 1. CLEANUP: Always cancel existing timer first
    if (_autoSaveTimer != null) {
      print("⏱️ Cancelling existing auto-save timer");
      _autoSaveTimer!.cancel();
      _autoSaveTimer = null;
    }
    
    // 2. VERIFY: Check if game state is ready for saving
    if (_gameState == null) {
      print("❌ CRITICAL ERROR: Cannot set up auto-save timer - game state is null");
      return;
    }
    
    // 3. TIMING: Auto-save timer interval
    // CHANGE: Reduced auto-save frequency to every 15 seconds instead of 10
    // This improves performance and reduces potential resource contention
    const int saveIntervalSeconds = 15; // Save every 15 seconds (was 10 seconds)
    print("⏱️ CREATING NEW AUTO-SAVE TIMER: Will save every $saveIntervalSeconds seconds");
    
    // 4. IMPLEMENT: Create a brand new timer with error handling
    try {
      _autoSaveTimer = Timer.periodic(Duration(seconds: saveIntervalSeconds), (timer) {
        final DateTime saveTime = DateTime.now();
        print("⏱️ AUTO-SAVE CYCLE STARTED at ${TimeUtils.formatTime(saveTime)}");
        
        // Use Future with try-catch for async error handling
        Future<void> performAutoSave() async {
          try {
            // Update timestamp first
            _gameState.lastSaved = saveTime;
            
            // Using the actual saveGame method (awaiting completion)
            final bool success = await saveGame();
            
            if (success) {
              print("✅ AUTO-SAVE COMPLETED SUCCESSFULLY at ${TimeUtils.formatTime(DateTime.now())}");
            } else {
              print("❌ AUTO-SAVE FAILED TO COMPLETE");
            }
          } catch (e) {
            print("❌ AUTO-SAVE ERROR: $e");
            // Print stack trace for debugging in development
            print("STACK TRACE: ${StackTrace.current}");
          }
        }
        
        // Execute the save operation
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
      
      // Execute initial save after a short delay to ensure app is fully initialized
      Future.delayed(const Duration(seconds: 2), performInitialSave);
      
    } catch (e) {
      print("❌ CRITICAL ERROR SETTING UP AUTO-SAVE TIMER: $e");
      print("📋 STACK TRACE: ${StackTrace.current}");
    }
  }
  
  // Calculate income earned while app was closed
  void _calculateOfflineIncome(Duration offlineDuration) {
    // Safety check
    if (offlineDuration.inSeconds <= 0) return;
    
    print("💰 Calculating offline income...");
    
    // Calculate the total income per second
    double incomePerSecond = _gameState.totalIncomePerSecond;
    
    // Cap offline duration to a maximum value (5 days as requested)
    // This prevents excessive income for very long offline periods while still being generous
    int offlineSeconds = offlineDuration.inSeconds;
    final int maxOfflineSeconds = 5 * 24 * 60 * 60; // 5 days
    
    // Create duration for notification display (needs to be set before potentially capping)
    Duration cappedDuration;
    
    if (offlineSeconds > maxOfflineSeconds) {
      print("⚠️ Capping offline time from ${Duration(seconds: offlineSeconds).inDays} days to ${Duration(seconds: maxOfflineSeconds).inDays} days");
      cappedDuration = Duration(seconds: maxOfflineSeconds);
      offlineSeconds = maxOfflineSeconds;
    } else {
      cappedDuration = offlineDuration;
    }
    
    // Calculate total offline income
    double offlineIncome = incomePerSecond * offlineSeconds;
    
    // Store offline income info for notification (even smaller amounts)
    print("💰 OFFLINE INCOME DEBUG: Earned ${NumberFormatter.formatCurrency(offlineIncome)} in ${cappedDuration.inMinutes} minutes");
    
    // CRITICAL FIX: Always set these values, even for small amounts
    // This ensures we can debug the notification system more easily
    _offlineIncomeEarned = offlineIncome;
    _offlineDuration = cappedDuration;
    
    // Print clear debug info for notification system
    print("📣 OFFLINE NOTIFICATION DATA SET:");
    print("💰 Amount: ${NumberFormatter.formatCurrency(_offlineIncomeEarned ?? 0)}");
    print("⏰ Duration: ${_offlineDuration?.inMinutes ?? 0} minutes");
    
    // Update player money and stats
    _gameState.money += offlineIncome;
    _gameState.totalEarned += offlineIncome;
    
    // Distribute the earnings to appropriate categories based on current ratios
    double totalActiveIncome = _gameState.passiveEarnings + 
                              _gameState.investmentDividendEarnings + 
                              _gameState.realEstateEarnings;
    
    if (totalActiveIncome > 0) {
      // Distribute proportionally
      _gameState.passiveEarnings += offlineIncome * (_gameState.passiveEarnings / totalActiveIncome);
      _gameState.investmentDividendEarnings += offlineIncome * (_gameState.investmentDividendEarnings / totalActiveIncome);
      _gameState.realEstateEarnings += offlineIncome * (_gameState.realEstateEarnings / totalActiveIncome);
    } else {
      // If no existing distribution, assign it all to passive earnings
      _gameState.passiveEarnings += offlineIncome;
    }
    
    print("💰 Earned ${NumberFormatter.formatCurrency(offlineIncome)} while offline (${offlineDuration.inMinutes} minutes)");
    _gameState.notifyListeners();
  }
  
  // Get sound manager instance
  SoundManager get soundManager => _soundManager;
  
  // Get game state
  GameState get gameState => _gameState;
  
  // Save game to SharedPreferences - private implementation
  void _saveGame() {
    saveGame(); // Call the public method
  }
  
  // Public method to manually save the game
  Future<bool> saveGame() async {
    try {
      final Map<String, dynamic> gameJson = _gameState.toJson();
      final String gameData = jsonEncode(gameJson);
      
      // On web, we're sometimes hitting size limits with SharedPreferences
      // If we're on the web, we'll print some diagnostics
      if (kIsWeb) {
        print("📊 Game data size: ${gameData.length} bytes");
        // SharedPreferences on web has a size limit, so make sure we're not exceeding it
        if (gameData.length > 500000) { // 500KB limit as a precaution
          print("⚠️ Game data is very large, might exceed storage limits on web");
        }
      }
      
      // Update the lastSaved timestamp in the game state
      _gameState.lastSaved = DateTime.now();
      
      // Use await to make sure the save completes
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
  
  // Load game from SharedPreferences
  Future<void> _loadGame() async {
    print('🔍 Attempting to load saved game data');
    final String? gameData = _prefs.getString(_saveKey);
    
    if (gameData != null && gameData.isNotEmpty) {
      try {
        print('📖 Found saved game data of size: ${gameData.length} bytes');
        final Map<String, dynamic> gameJson = jsonDecode(gameData);
        // Await the async fromJson method
        await _gameState.fromJson(gameJson); 
        print('✅ Game loaded successfully from save');
      } catch (e) {
        print('❌ Error loading game: $e');
        // Continue with new game if loading fails
        // Consider if we need to re-initialize gameState here or ensure it's in a clean state
      }
    } else {
      print('ℹ️ No saved game found, starting new game');
      // Ensure real estate is initialized even for a new game
      // Although the constructor handles this, awaiting it here ensures consistency
      // if the constructor's future hasn't completed for some reason.
      // This check might be redundant if constructor guarantees completion before service init.
      if (_gameState.realEstateInitializationFuture != null) {
          await _gameState.realEstateInitializationFuture;
      }
    }
  }
  
  // Reset game data (for prestige system or testing)
  Future<void> resetGame() async {
    try {
      // Remove saved game data
      await _prefs.remove(_saveKey);
      
      // Update version record to current version
      await _prefs.setString(_versionKey, _currentVersion);
      
      // Reset the game state to default values
      _gameState.resetToDefaults(); 
      
      // IMPORTANT: Need to re-initialize real estate upgrades after reset
      // and wait for it before potential save
      await _gameState.initializeRealEstateUpgrades();
      
      print('🔄 Game reset to defaults with version $_currentVersion');
    } catch (e) {
      print('❌ Error resetting game: $e');
    }
  }
  
  // Export game data as string
  String exportGameData() {
    final Map<String, dynamic> gameJson = _gameState.toJson();
    return jsonEncode(gameJson);
  }
  
  // Import game data from string
  Future<bool> importGameData(String data) async {
    try {
      final Map<String, dynamic> gameJson = jsonDecode(data);
      // Await the async fromJson method
      await _gameState.fromJson(gameJson);
      await saveGame(); // Save after importing
      return true;
    } catch (e) {
      print('❌ Error importing game data: $e');
      return false;
    }
  }
  
  // Clean up resources when service is disposed
  void dispose() {
    // Cancel auto-save timer
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    
    // Remove listener to prevent memory leaks
    _gameState.removeListener(_saveGame);
    
    print('🧹 GameService resources cleaned up');
  }
}
