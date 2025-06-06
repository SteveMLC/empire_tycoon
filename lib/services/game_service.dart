import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';
import '../utils/time_utils.dart';
import '../utils/sound_manager.dart';

// Import component services
import 'components/sound_service.dart';
import 'components/timer_service.dart';
import 'components/persistence_service.dart';
import 'components/diagnostic_service.dart';
import 'income_service.dart'; // ADDED: Import IncomeService

class GameService {
  final SharedPreferences _prefs;
  final GameState _gameState;
  bool _isInitialized = false;
  
  // Component services
  late final SoundService _soundService;
  late final TimerService _timerService;
  late final PersistenceService _persistenceService;
  late final DiagnosticService _diagnosticService;
  late final IncomeService _incomeService; // ADDED: IncomeService for consistent income calculation
  
  // Expose soundManager for backward compatibility
  // This will be removed once all direct soundManager references are updated
  SoundManager get soundManager => SoundManager();

  GameService(this._prefs, this._gameState) {
    // Initialize component services
    _soundService = SoundService();
    _incomeService = IncomeService(); // ADDED: Initialize IncomeService
    _timerService = TimerService(_gameState, _performAutoSave);
    _persistenceService = PersistenceService(_prefs, _gameState, incomeService: _incomeService); // UPDATED: Pass IncomeService
    _diagnosticService = DiagnosticService(
      _gameState, 
      _cancelAllTimers, 
      _setupAllTimers,
      _setLastGameUpdateTime
    );
  }

  void playSound(Future<void> Function() soundFunction) {
    _soundService.playSound(soundFunction);
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

      // CRITICAL FIX: Cancel all timers in GameService first
      _cancelAllTimers();
      
      // CRITICAL FIX: Ensure GameState timers are cancelled before initialization
      try {
        print("⏱️ INIT: Ensuring all GameState timers are cancelled");
        // Always cancel timers to be safe, regardless of the timersActive flag
        _gameState.cancelAllTimers();
        print("⏱️ INIT: GameState timers cancelled successfully");
      } catch (e) {
        print("⚠️ INIT: Warning cancelling GameState timers: $e");
      }

      // Initialize sound service
      await _soundService.init();
      
      // Check game version and clear data if needed
      await _persistenceService.checkVersion();

      final DateTime beforeLoad = DateTime.now();
      final DateTime appStartTime = beforeLoad.subtract(const Duration(seconds: 1)); // Small buffer for timestamp comparison
      print("⏱️ Start loading game state at ${TimeUtils.formatTime(beforeLoad)}");
      await _persistenceService.loadGame();
      final DateTime afterLoad = DateTime.now();

      final Duration loadDuration = afterLoad.difference(beforeLoad);
      print("⏱️ Game loading took ${loadDuration.inMilliseconds}ms");

      // CRITICAL FIX: Timestamp analysis (keep for logging, but remove redundant calculation)
      final DateTime lastSavedTime = _gameState.lastSaved;
      print("⏱️ TIMESTAMP ANALYSIS: Last saved at ${TimeUtils.formatTime(lastSavedTime)}");
      print("⏱️ TIMESTAMP ANALYSIS: App started at ${TimeUtils.formatTime(appStartTime)}");
      print("⏱️ TIMESTAMP ANALYSIS: Current time is ${TimeUtils.formatTime(afterLoad)}");

      // CRITICAL FIX: Set up all timers after loading is complete
      _setupAllTimers();
      
      // Perform initial save to ensure we have a valid save file
      await _persistenceService.performInitialSave();
      
      // Mark as initialized
      _isInitialized = true;
      print("✅ GameService initialization completed successfully");
      
      // Run diagnostics to verify timer system is working correctly
      _runTimerDiagnostics();
      
      return;
    } catch (e) {
      print("⚠️ Error during GameService initialization: $e");
      throw Exception("Failed to initialize GameService: $e");
    }
  }

  void _cancelAllTimers() {
    _timerService.cancelAllTimers();
  }

  void _setupAllTimers() {
    _timerService.setupAllTimers();
  }

  Future<void> _performAutoSave() async {
    await _persistenceService.performAutoSave();
  }

  Future<void> performAutoSave() async {
    await _persistenceService.performAutoSave();
  }

  Future<void> performInitialSave() async {
    await _persistenceService.performInitialSave();
  }
  
  Future<void> saveGame() async {
    await _persistenceService.saveGame();
  }

  Future<void> resetGame() async {
    await _persistenceService.resetGame();
  }

  String exportGameData() {
    return _persistenceService.exportGameData();
  }

  Future<void> importGameData(String data) async {
    await _persistenceService.importGameData(data);
  }

  void dispose() {
    print("🧹 Disposing GameService");
    _cancelAllTimers();
  }

  // Sound methods delegated to SoundService
  void playBusinessSound() {
    _soundService.playBusinessSound();
  }

  void playInvestmentSound() {
    _soundService.playInvestmentSound();
  }

  void playRealEstateSound() {
    _soundService.playRealEstateSound();
  }

  void playTapSound() {
    _soundService.playTapSound();
  }

  void playBoostedTapSound() {
    _soundService.playBoostedTapSound();
  }

  void playAchievementSound() {
    _soundService.playAchievementSound();
  }

  void playEventSound() {
    _soundService.playEventSound();
  }

  void playOfflineIncomeSound() {
    _soundService.playOfflineIncomeSound();
  }

  void playFeedbackSound() {
    _soundService.playFeedbackSound();
  }
  
  // Additional sound methods delegated to SoundService
  void playPlatinumPurchaseSound() {
    _soundService.playPlatinumPurchaseSound();
  }
  
  void playBusinessPurchaseSound() {
    _soundService.playBusinessPurchaseSound();
  }
  
  void playAchievementMilestoneSound() {
    _soundService.playAchievementMilestoneSound();
  }
  
  void playAchievementRareSound() {
    _soundService.playAchievementRareSound();
  }
  
  void playFeedbackSuccessSound() {
    _soundService.playFeedbackSuccessSound();
  }
  
  void playFeedbackErrorSound() {
    _soundService.playFeedbackErrorSound();
  }
  
  void playInvestmentBuyStockSound() {
    _soundService.playInvestmentBuyStockSound();
  }
  
  void playInvestmentSellStockSound() {
    _soundService.playInvestmentSellStockSound();
  }
  
  // Delegate direct sound playing to SoundService
  Future<void> playSoundAsset(String path, {bool useCache = true, SoundPriority priority = SoundPriority.normal}) async {
    return _soundService.playSoundAsset(path, useCache: useCache, priority: priority);
  }

  void _runTimerDiagnostics() {
    _diagnosticService.runTimerDiagnostics();
  }
  
  // Public method to access the timer diagnostic function
  void runDiagnostics() {
    _runTimerDiagnostics();
  }
  
  // Helper method for DiagnosticService
  void _setLastGameUpdateTime(DateTime time) {
    _timerService.setLastGameUpdateTime(time);
  }
}