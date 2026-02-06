import 'dart:async';
import 'dart:collection';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'sound_assets.dart'; // Assuming sound_assets.dart exists and is correct

// Re-export SoundPriority if needed elsewhere, though it's defined in sounds.dart
// export 'sounds.dart' show SoundPriority; 

// Constants for SharedPreferences keys (centralized)
const String _soundEnabledPrefsKey = 'sound_enabled';
const String _soundVolumePrefsKey = 'sound_volume';
const String _uiSoundsEnabledPrefsKey = 'ui_sounds_enabled';
const String _achievementSoundsEnabledPrefsKey = 'achievement_sounds_enabled';
const String _businessSoundsEnabledPrefsKey = 'business_sounds_enabled';
const String _investmentSoundsEnabledPrefsKey = 'investment_sounds_enabled';
const String _realEstateSoundsEnabledPrefsKey = 'real_estate_sounds_enabled';
const String _eventSoundsEnabledPrefsKey = 'event_sounds_enabled';
const String _feedbackSoundsEnabledPrefsKey = 'feedback_sounds_enabled';
const String _hapticsEnabledPrefsKey = 'haptics_enabled';


// Sound priority enum (ensure this matches the one in sounds.dart or remove duplication)
enum SoundPriority { low, normal, high }

// Queued sound class (ensure this matches the one in sounds.dart or remove duplication)
class _QueuedSound {
  final String path;
  final bool useCache;
  final SoundPriority priority;
  final Completer<void> completer; // To signal completion or error

  _QueuedSound(this.path, this.useCache, this.priority, this.completer);
}

/// Manages sound playback, caching, pooling, and settings with optimizations for rapid tapping and app lifecycle.
class SoundManager with WidgetsBindingObserver {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;

  SoundManager._internal(); // Private constructor for singleton

  late SharedPreferences _prefs;
  final List<AudioPlayer> _playerPool = [];
  final Map<AudioPlayer, Completer<void>> _activePlayers = {};
  final int _maxPoolSize = 8; // Regular player pool size
  final int _maxQueueSize = 10; // Reduced queue size to prevent lag

  final Queue<_QueuedSound> _soundQueue = Queue();
  bool _isProcessingQueue = false;
  bool _isInitialized = false;
  bool _isAppInBackground = false; // Track app state
  bool _needsReinitialize = false; // Track if we need to reinitialize after errors

  // Sound settings
  bool _isSoundEnabled = true;
  double _soundVolume = 1.0;
  bool _isUiSoundsEnabled = true;
  bool _isAchievementSoundsEnabled = true;
  bool _isBusinessSoundsEnabled = true;
  bool _isInvestmentSoundsEnabled = true;
  bool _isRealEstateSoundsEnabled = true;
  bool _isEventSoundsEnabled = true;
  bool _isFeedbackSoundsEnabled = true;
  bool _isHapticsEnabled = true;

  // Dedicated tap player pool for overlapping sounds
  final List<AudioPlayer> _tapPlayerPool = [];
  final int _maxTapPlayerPoolSize = 6; // Allow up to 6 overlapping tap sounds
  int _currentTapPlayerIndex = 0;

  // --- Helper Methods for Player State Management ---

  /// Safely checks if a player is in a usable state with enhanced validation
  bool _isPlayerUsable(AudioPlayer player) {
    try {
      // Enhanced state validation - check multiple conditions atomically
      final state = player.state;
      return state != PlayerState.disposed && (
             state == PlayerState.stopped ||  // Allow stopped players to be reused
             state == PlayerState.paused ||
             state == PlayerState.playing ||
             state == PlayerState.completed);
    } catch (e) {
      // If we can't even check the state, the player is unusable
      debugPrint('⚠️ Player state check failed: $e');
      return false;
    }
  }

  /// Atomically checks player state and performs operation to prevent race conditions
  Future<bool> _atomicPlayerOperation(AudioPlayer player, Future<void> Function() operation, String operationName) async {
    try {
      // Double-check pattern with immediate operation to minimize race condition window
      if (!_isPlayerUsable(player)) {
        debugPrint('⚠️ Player not usable for $operationName');
        return false;
      }
      
      // Perform operation immediately after validation
      await operation();
      return true;
    } catch (e) {
      // Handle specific MediaPlayer exceptions that cause crashes
      if (e.toString().contains('IllegalStateException') || 
          e.toString().contains('Player has not yet been created') ||
          e.toString().contains('has already been disposed')) {
        debugPrint('❌ MediaPlayer state error in $operationName: $e');
        return false;
      }
      
      debugPrint('⚠️ Failed $operationName on player: $e');
      return false;
    }
  }

  /// Safely sets volume on a player with atomic operation
  Future<bool> _safeSetVolume(AudioPlayer player, double volume) async {
    return await _atomicPlayerOperation(player, () async {
      await player.setVolume(volume);
    }, 'setVolume');
  }

  /// Safely plays a sound source with atomic operation and enhanced validation
  Future<bool> _safePlaySound(AudioPlayer player, Source source) async {
    return await _atomicPlayerOperation(player, () async {
      // For MediaPlayer stability, ensure we're in a valid state for play()
      final currentState = player.state;
      
      // Only call play if we're in a safe state
      if (currentState == PlayerState.stopped || 
          currentState == PlayerState.paused || 
          currentState == PlayerState.completed) {
        await player.play(source);
      } else if (currentState == PlayerState.playing) {
        // Already playing, restart with new source
        await player.stop();
        await Future.delayed(const Duration(milliseconds: 10)); // Brief pause for MediaPlayer
        await player.play(source);
      } else {
        throw Exception('Player in invalid state for play: $currentState');
      }
    }, 'play');
  }

  /// Safely stops a player with atomic operation
  Future<bool> _safeStopPlayer(AudioPlayer player) async {
    return await _atomicPlayerOperation(player, () async {
      final currentState = player.state;
      // Only stop if actually playing or paused
      if (currentState == PlayerState.playing || currentState == PlayerState.paused) {
        await player.stop();
      }
    }, 'stop');
  }

  /// Safely disposes a player with enhanced error handling
  void _safeDisposePlayer(AudioPlayer player) {
    try {
      final currentState = player.state;
      if (currentState != PlayerState.disposed) {
        player.dispose();
      }
    } catch (e) {
      // Even if dispose fails, we consider it disposed for our purposes
      debugPrint('⚠️ Error disposing player (continuing anyway): $e');
    }
  }

  /// Creates a new player with proper configuration
  AudioPlayer _createNewPlayer() {
    try {
      final player = AudioPlayer();
      player.setReleaseMode(ReleaseMode.stop);
      _safeSetVolume(player, _soundVolume); // Use safe method
      return player;
    } catch (e) {
      debugPrint('❌ Failed to create new player: $e');
      rethrow;
    }
  }

  // --- Initialization & Disposal ---

  Future<void> init() async {
    if (_isInitialized) return;
    debugPrint('🔊 Initializing SoundManager...');
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSettings();
      await _initPlayerPool();
      await _initDedicatedTapPlayer();
      
      // Register for app lifecycle changes
      WidgetsBinding.instance.addObserver(this);
      
      _isInitialized = true;
      _needsReinitialize = false;
      debugPrint('🔊 SoundManager Initialized Successfully.');
      debugPrint('   Sound Enabled: $_isSoundEnabled, Volume: $_soundVolume');
    } catch (e) {
      debugPrint('❌ Error initializing SoundManager: $e');
      // Defaults will be used if loading fails
      _isSoundEnabled = true;
      _soundVolume = 1.0;
    }
  }

  // Initialize dedicated tap player for better performance
  Future<void> _initDedicatedTapPlayer() async {
    // Safely dispose existing players
    for (final player in _tapPlayerPool) {
      _safeDisposePlayer(player);
    }
    _tapPlayerPool.clear();
    
    for (int i = 0; i < _maxTapPlayerPoolSize; i++) {
      try {
        final player = _createNewPlayer();
        _tapPlayerPool.add(player);
      } catch (e) {
        debugPrint('⚠️ Failed to create tap player $i: $e');
        // Continue with fewer players if needed
      }
    }
    debugPrint('🔊 Dedicated tap player pool initialized with ${_tapPlayerPool.length} players.');
  }

  Future<void> _initPlayerPool() async {
    // Safely dispose existing players
    for (final player in _playerPool) {
      _safeDisposePlayer(player);
    }
    _playerPool.clear();
    
    for (int i = 0; i < _maxPoolSize; i++) {
      try {
        final player = _createNewPlayer();
        _playerPool.add(player);
      } catch (e) {
        debugPrint('⚠️ Failed to create player $i: $e');
        // Continue with fewer players if needed
      }
    }
    debugPrint('🔊 AudioPlayer pool initialized with ${_playerPool.length} players.');
  }

  // App lifecycle management
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _isAppInBackground = true;
        stopAllSounds();
        debugPrint('🔊 App backgrounded - stopped all sounds');
        break;
      case AppLifecycleState.resumed:
        _isAppInBackground = false;
        // Always check audio system health on resume (ads can break audio)
        _checkAndRecoverAudioSystem();
        debugPrint('🔊 App resumed - sounds re-enabled');
        break;
      case AppLifecycleState.inactive:
        // Don't stop sounds on inactive (brief interruptions)
        break;
    }
  }

  /// Checks audio system health and recovers if needed
  Future<void> _checkAndRecoverAudioSystem() async {
    if (!_isInitialized) {
      debugPrint('🔊 Audio system not initialized, skipping health check');
      return;
    }

    try {
      // Check if we need full reinitialize
      if (_needsReinitialize) {
        await _reinitializeAudioSystem();
        return;
      }

      // Quick health check - test a player from each pool
      bool needsRecovery = false;

      // Check tap player pool health
      if (_tapPlayerPool.isNotEmpty) {
        final testPlayer = _tapPlayerPool.first;
        if (!_isPlayerUsable(testPlayer)) {
          debugPrint('🔊 Tap player pool unhealthy, marking for recovery');
          needsRecovery = true;
        }
      }

      // Check main player pool health
      if (_playerPool.isNotEmpty) {
        final testPlayer = _playerPool.first;
        if (!_isPlayerUsable(testPlayer)) {
          debugPrint('🔊 Main player pool unhealthy, marking for recovery');
          needsRecovery = true;
        }
      }

      // Check if pools are empty (they shouldn't be)
      if (_playerPool.isEmpty || _tapPlayerPool.isEmpty) {
        debugPrint('🔊 Player pools empty, marking for recovery');
        needsRecovery = true;
      }

      if (needsRecovery) {
        debugPrint('🔄 Audio system needs recovery after app resume');
        await _reinitializeAudioSystem();
      } else {
        debugPrint('✅ Audio system healthy after app resume');
      }

    } catch (e) {
      debugPrint('❌ Error during audio system health check: $e');
      _needsReinitialize = true;
    }
  }

  /// Reinitializes the entire audio system after critical errors
  Future<void> _reinitializeAudioSystem() async {
    debugPrint('🔄 Reinitializing audio system due to errors...');
    
    try {
      // Stop and clear everything
      _soundQueue.clear();
      _isProcessingQueue = false;
      _activePlayers.clear();
      
      // Reinitialize player pools
      await _initPlayerPool();
      await _initDedicatedTapPlayer();
      
      _needsReinitialize = false;
      debugPrint('✅ Audio system reinitialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to reinitialize audio system: $e');
      // Mark for retry on next lifecycle change
      _needsReinitialize = true;
    }
  }

  /// Public method to recover audio system after ads or other interruptions
  /// Call this when returning from ad display or other audio interruptions
  Future<void> recoverFromAudioInterruption() async {
    debugPrint('🔊 Recovering audio system after interruption (ad/etc)...');
    
    // Simple but effective recovery: clear any stuck operations and validate pools
    _soundQueue.clear(); // Clear any queued sounds that might be stuck
    _isProcessingQueue = false; // Reset processing flag
    
    await _checkAndRecoverAudioSystem();
  }

  /// Emergency recovery method for when multiple audio errors occur
  /// This completely rebuilds the audio system from scratch
  Future<void> emergencyAudioRecovery() async {
    debugPrint('🚨 EMERGENCY: Performing complete audio system recovery...');
    
    try {
      // Stop all current operations
      _isProcessingQueue = false;
      _soundQueue.clear();
      
      // Dispose all existing players safely
      for (final player in List.from(_playerPool)) {
        _safeDisposePlayer(player);
      }
      _playerPool.clear();
      
      for (final player in List.from(_tapPlayerPool)) {
        _safeDisposePlayer(player);
      }
      _tapPlayerPool.clear();
      
      for (final player in List.from(_activePlayers.keys)) {
        final completer = _activePlayers[player];
        if (completer != null && !completer.isCompleted) {
          completer.completeError('Emergency audio recovery');
        }
        _safeDisposePlayer(player);
      }
      _activePlayers.clear();
      
      // Wait a moment for disposal to complete
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Rebuild everything from scratch
      await _initPlayerPool();
      await _initDedicatedTapPlayer();
      
      _needsReinitialize = false;
      debugPrint('✅ Emergency audio recovery completed successfully');
      
    } catch (e) {
      debugPrint('❌ Emergency audio recovery failed: $e');
      // Mark for retry on next app resume
      _needsReinitialize = true;
         }
   }

  /// Comprehensive audio system diagnostic method
  /// Returns true if system is healthy, false if emergency recovery is needed
  Future<bool> performAudioDiagnostic({bool verbose = false}) async {
    if (!_isInitialized) {
      debugPrint('🔊 Audio system not initialized');
      return false;
    }

    debugPrint('🔍 === AUDIO SYSTEM DIAGNOSTIC ===');
    
    int healthyPlayers = 0;
    int unhealthyPlayers = 0;
    int healthyTapPlayers = 0;
    int unhealthyTapPlayers = 0;
    
    // Check main player pool
    debugPrint('🔍 Main Player Pool: ${_playerPool.length}/$_maxPoolSize');
    for (int i = 0; i < _playerPool.length; i++) {
      final player = _playerPool[i];
      if (_isPlayerUsable(player)) {
        healthyPlayers++;
        if (verbose) debugPrint('  Player $i: ✅ Healthy');
      } else {
        unhealthyPlayers++;
        if (verbose) debugPrint('  Player $i: ❌ Unhealthy');
      }
    }
    
    // Check tap player pool
    debugPrint('🔍 Tap Player Pool: ${_tapPlayerPool.length}/$_maxTapPlayerPoolSize');
    for (int i = 0; i < _tapPlayerPool.length; i++) {
      final player = _tapPlayerPool[i];
      if (_isPlayerUsable(player)) {
        healthyTapPlayers++;
        if (verbose) debugPrint('  Tap Player $i: ✅ Healthy');
      } else {
        unhealthyTapPlayers++;
        if (verbose) debugPrint('  Tap Player $i: ❌ Unhealthy');
      }
    }
    
    // Check active players
    debugPrint('🔍 Active Players: ${_activePlayers.length}');
    int healthyActivePlayer = 0;
    int unhealthyActivePlayer = 0;
    for (final player in _activePlayers.keys) {
      if (_isPlayerUsable(player)) {
        healthyActivePlayer++;
      } else {
        unhealthyActivePlayer++;
      }
    }
    
    debugPrint('🔍 Queue Status: ${_soundQueue.length} sounds queued, processing: $_isProcessingQueue');
    debugPrint('🔍 App Background: $_isAppInBackground, Needs Reinit: $_needsReinitialize');
    debugPrint('🔍 Settings: Enabled=$_isSoundEnabled, Volume=$_soundVolume');
    
    // Health summary
    final totalPlayers = _playerPool.length + _tapPlayerPool.length;
    final totalHealthy = healthyPlayers + healthyTapPlayers;
    final totalUnhealthy = unhealthyPlayers + unhealthyTapPlayers;
    final healthPercentage = totalPlayers > 0 ? (totalHealthy / totalPlayers * 100) : 0;
    
    debugPrint('🔍 === HEALTH SUMMARY ===');
    debugPrint('🔍 Total Players: $totalPlayers');
    debugPrint('🔍 Healthy: $totalHealthy (${healthPercentage.toStringAsFixed(1)}%)');
    debugPrint('🔍 Unhealthy: $totalUnhealthy');
    debugPrint('🔍 Active Healthy: $healthyActivePlayer');
    debugPrint('🔍 Active Unhealthy: $unhealthyActivePlayer');
    
    // Determine if emergency recovery is needed
    final needsEmergencyRecovery = 
        (_playerPool.isEmpty && _tapPlayerPool.isEmpty) || // No players at all
        (healthPercentage < 50) || // Less than 50% healthy
        (_needsReinitialize) || // Marked for reinit
        (unhealthyActivePlayer > 0); // Active players are unhealthy
    
    if (needsEmergencyRecovery) {
      debugPrint('🚨 Audio system needs EMERGENCY RECOVERY');
      return false;
    } else {
      debugPrint('✅ Audio system is healthy');
      return true;
    }
  }
  
    void dispose() {
    debugPrint('🔊 Disposing SoundManager...');
    
    // Remove app lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    _soundQueue.clear();
    _isProcessingQueue = false;
    
    // Dispose dedicated tap players
    for (var player in _tapPlayerPool) {
      _safeDisposePlayer(player);
    }
    _tapPlayerPool.clear();
    
    // Release all players in the pool
    for (var player in _playerPool) {
      _safeDisposePlayer(player);
    }
    _playerPool.clear();
    
    // Cancel any active playback completers and dispose active players
    _activePlayers.forEach((player, completer) {
      if (!completer.isCompleted) {
        completer.completeError('SoundManager disposed during playback');
      }
      _safeDisposePlayer(player);
    });
    _activePlayers.clear();
    _isInitialized = false;
    debugPrint('🔊 SoundManager Disposed.');
  }

  // --- Settings ---

  Future<void> _loadSettings() async {
    _isSoundEnabled = _prefs.getBool(_soundEnabledPrefsKey) ?? true;
    _soundVolume = _prefs.getDouble(_soundVolumePrefsKey) ?? 1.0;
    _isUiSoundsEnabled = _prefs.getBool(_uiSoundsEnabledPrefsKey) ?? true;
    _isAchievementSoundsEnabled = _prefs.getBool(_achievementSoundsEnabledPrefsKey) ?? true;
    _isBusinessSoundsEnabled = _prefs.getBool(_businessSoundsEnabledPrefsKey) ?? true;
    _isInvestmentSoundsEnabled = _prefs.getBool(_investmentSoundsEnabledPrefsKey) ?? true;
    _isRealEstateSoundsEnabled = _prefs.getBool(_realEstateSoundsEnabledPrefsKey) ?? true;
    _isEventSoundsEnabled = _prefs.getBool(_eventSoundsEnabledPrefsKey) ?? true;
    _isFeedbackSoundsEnabled = _prefs.getBool(_feedbackSoundsEnabledPrefsKey) ?? true;
    _isHapticsEnabled = _prefs.getBool(_hapticsEnabledPrefsKey) ?? true;
    
    // Apply initial volume to pool (using safe method)
    for (var player in _playerPool) {
      _safeSetVolume(player, _soundVolume);
    }
    // Set volume on dedicated tap players
    for (var player in _tapPlayerPool) {
      _safeSetVolume(player, _soundVolume);
    }
  }

  Future<void> _saveSettings() async {
    await _prefs.setBool(_soundEnabledPrefsKey, _isSoundEnabled);
    await _prefs.setDouble(_soundVolumePrefsKey, _soundVolume);
    await _prefs.setBool(_uiSoundsEnabledPrefsKey, _isUiSoundsEnabled);
    await _prefs.setBool(_achievementSoundsEnabledPrefsKey, _isAchievementSoundsEnabled);
    await _prefs.setBool(_businessSoundsEnabledPrefsKey, _isBusinessSoundsEnabled);
    await _prefs.setBool(_investmentSoundsEnabledPrefsKey, _isInvestmentSoundsEnabled);
    await _prefs.setBool(_realEstateSoundsEnabledPrefsKey, _isRealEstateSoundsEnabled);
    await _prefs.setBool(_eventSoundsEnabledPrefsKey, _isEventSoundsEnabled);
    await _prefs.setBool(_feedbackSoundsEnabledPrefsKey, _isFeedbackSoundsEnabled);
    await _prefs.setBool(_hapticsEnabledPrefsKey, _isHapticsEnabled);
  }

  // Getters for settings
  bool get isSoundEnabled => _isSoundEnabled;
  double get soundVolume => _soundVolume;
  bool get isUiSoundsEnabled => _isUiSoundsEnabled;
  bool get isAchievementSoundsEnabled => _isAchievementSoundsEnabled;
  bool get isBusinessSoundsEnabled => _isBusinessSoundsEnabled;
  bool get isInvestmentSoundsEnabled => _isInvestmentSoundsEnabled;
  bool get isRealEstateSoundsEnabled => _isRealEstateSoundsEnabled;
  bool get isEventSoundsEnabled => _isEventSoundsEnabled;
  bool get isFeedbackSoundsEnabled => _isFeedbackSoundsEnabled;
  bool get isHapticsEnabled => _isHapticsEnabled;

  // Setters for settings
  Future<void> setSoundEnabled(bool enabled) async {
    if (_isSoundEnabled == enabled) return;
    _isSoundEnabled = enabled;
    await _saveSettings();
    if (!enabled) {
      stopAllSounds(); // Stop sounds immediately if disabled
    }
  }

  Future<void> setSoundVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    if (_soundVolume == clampedVolume) return;
    _soundVolume = clampedVolume;
    
    // Apply volume to all current and future players (using safe method)
    for (var player in _playerPool) {
      await _safeSetVolume(player, _soundVolume);
    }
    for (var player in _activePlayers.keys) {
      await _safeSetVolume(player, _soundVolume);
    }
    // Update dedicated tap players
    for (var player in _tapPlayerPool) {
      await _safeSetVolume(player, _soundVolume);
    }
    await _saveSettings();
  }

  Future<void> setUiSoundsEnabled(bool enabled) async {
    if (_isUiSoundsEnabled == enabled) return;
    _isUiSoundsEnabled = enabled;
    await _saveSettings();
  }
    Future<void> setAchievementSoundsEnabled(bool enabled) async {
    if (_isAchievementSoundsEnabled == enabled) return;
    _isAchievementSoundsEnabled = enabled;
    await _saveSettings();
  }
    Future<void> setBusinessSoundsEnabled(bool enabled) async {
    if (_isBusinessSoundsEnabled == enabled) return;
    _isBusinessSoundsEnabled = enabled;
    await _saveSettings();
  }
  Future<void> setInvestmentSoundsEnabled(bool enabled) async {
    if (_isInvestmentSoundsEnabled == enabled) return;
    _isInvestmentSoundsEnabled = enabled;
    await _saveSettings();
  }
  Future<void> setRealEstateSoundsEnabled(bool enabled) async {
    if (_isRealEstateSoundsEnabled == enabled) return;
    _isRealEstateSoundsEnabled = enabled;
    await _saveSettings();
  }
    Future<void> setEventSoundsEnabled(bool enabled) async {
    if (_isEventSoundsEnabled == enabled) return;
    _isEventSoundsEnabled = enabled;
    await _saveSettings();
  }
  Future<void> setFeedbackSoundsEnabled(bool enabled) async {
    if (_isFeedbackSoundsEnabled == enabled) return;
    _isFeedbackSoundsEnabled = enabled;
    await _saveSettings();
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    if (_isHapticsEnabled == enabled) return;
    _isHapticsEnabled = enabled;
    await _saveSettings();
  }

  // --- Haptics helpers ---

  Future<void> playLightHaptic() async {
    if (!_isHapticsEnabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {
      // Ignore platform haptics errors
    }
  }

  Future<void> playMediumHaptic() async {
    if (!_isHapticsEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {
      // Ignore platform haptics errors
    }
  }

  Future<void> playHeavyHaptic() async {
    if (!_isHapticsEnabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {
      // Ignore platform haptics errors
    }
  }

  Future<void> playSelectionHaptic() async {
    if (!_isHapticsEnabled) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {
      // Ignore platform haptics errors
    }
  }

  Future<void> toggleSound(bool enabled) async {
      await setSoundEnabled(enabled);
  }

  // --- Sound Playback Logic ---

  /// Plays a sound effect with optimizations for rapid tapping.
  /// Returns a Future that completes when the sound finishes playing or fails.
  Future<void> playSound(
    String path, {
    bool useCache = true, // Generally recommended
    SoundPriority priority = SoundPriority.normal,
  }) async {
    if (!_isInitialized || !_isSoundEnabled || _isAppInBackground) {
      //debugPrint('🔊 SoundManager not ready, sounds disabled, or app in background, skipping $path');
      return; // Don't queue if disabled or app is in background
    }

    // --- Optimized Overlapping Sound Handling for Gameplay ---
    // Handle rapid tap sounds and business upgrade sounds with dedicated players
    if (path == SoundAssets.uiTap || path == SoundAssets.uiTapBoosted ||
        path.contains('business') || path.contains('real_estate')) {
      return _playTapSoundOverlapping(path);
    }

    // Auto-prioritize achievement and event sounds for better gameplay experience
    SoundPriority finalPriority = priority;
    if (path.contains('achievement') || path.contains('event') || path.contains('platinum')) {
      finalPriority = SoundPriority.high;
    }
    
    final completer = Completer<void>();
    final queuedSound = _QueuedSound(path, useCache, finalPriority, completer);

    // --- Aggressive Queue Management for Responsiveness ---
    if (_soundQueue.length >= _maxQueueSize) {
        // Clear older sounds of same or lower priority to make room
        if (priority == SoundPriority.high) {
          // High priority sounds can clear normal and low priority sounds
          _soundQueue.removeWhere((s) => s.priority != SoundPriority.high);
        } else if (priority == SoundPriority.normal) {
          // Normal priority sounds can clear low priority sounds
          _soundQueue.removeWhere((s) => s.priority == SoundPriority.low);
        }
        
        // If still full after cleanup, drop the current sound if it's low priority
        if (_soundQueue.length >= _maxQueueSize && priority == SoundPriority.low) {
            debugPrint('🔊 Sound queue full, dropping low priority sound: $path');
            completer.completeError('Queue full, sound dropped');
            return;
        }
    }

    _soundQueue.add(queuedSound);
    _triggerQueueProcessing(); // Ensure the queue processor runs

    return completer.future; // Return the future for callers to await if needed
  }

  /// Optimized rapid sound playback with overlapping support using dedicated player pool
  /// Designed for rapid gameplay scenarios: tapping, business upgrades, real estate purchases
  Future<void> _playTapSoundOverlapping(String path) async {
    if (_tapPlayerPool.isEmpty) {
      // Graceful degradation: use regular queue but with higher priority
      final completer = Completer<void>();
      final queuedSound = _QueuedSound(path, true, SoundPriority.high, completer);
      _soundQueue.add(queuedSound);
      _triggerQueueProcessing();
      return;
    }

    // Get the next available tap player in round-robin fashion
    AudioPlayer player = _tapPlayerPool[_currentTapPlayerIndex];
    _currentTapPlayerIndex = (_currentTapPlayerIndex + 1) % _maxTapPlayerPoolSize;

    // Simple validation with immediate fallback
    if (!_isPlayerUsable(player)) {
      _recreateTapPlayer(_currentTapPlayerIndex - 1);
      return; // Skip this attempt, next call will use new player
    }

    try {
      // Streamlined playback for responsiveness
      final volumeSet = await _safeSetVolume(player, _soundVolume);
      if (!volumeSet) {
        _recreateTapPlayer(_currentTapPlayerIndex - 1);
        return;
      }
      
      String processedPath = path.replaceFirst('assets/', '');
      Source source = AssetSource(processedPath);
      
      // Allow overlapping sounds for rapid tap gameplay
      final playSuccess = await _safePlaySound(player, source);
      if (!playSuccess) {
        _recreateTapPlayer(_currentTapPlayerIndex - 1);
        return;
      }
      
    } catch (e) {
      debugPrint('❌ Error playing tap sound: $e');
      _recreateTapPlayer(_currentTapPlayerIndex - 1);
    }
  }

  /// Safely recreates a tap player at the given index
  void _recreateTapPlayer(int index) {
    try {
      final validIndex = index % _maxTapPlayerPoolSize;
      final oldPlayer = _tapPlayerPool[validIndex];
      
      // Safely dispose old player
      _safeDisposePlayer(oldPlayer);
      
      // Create new player
      final newPlayer = _createNewPlayer();
      _tapPlayerPool[validIndex] = newPlayer;
      
      debugPrint('🔊 Recreated tap player at index $validIndex');
    } catch (e) {
      debugPrint('❌ Failed to recreate tap player: $e');
      _needsReinitialize = true;
    }
  }

  /// Internal method to process the sound queue with optimizations.
  void _triggerQueueProcessing() async {
    if (_isProcessingQueue || _soundQueue.isEmpty || _isAppInBackground) {
      return;
    }

    _isProcessingQueue = true;

    while (_soundQueue.isNotEmpty && _isInitialized && !_isAppInBackground) {
        // Find an available player
        AudioPlayer? player = _getAvailablePlayer();

        if (player == null) {
            // Wait briefly before checking again
            await Future.delayed(const Duration(milliseconds: 10));
            continue;
        }

        // Dequeue the highest priority sound
        _QueuedSound soundToPlay = _soundQueue.first; // Default to FIFO
        if (_soundQueue.any((s) => s.priority == SoundPriority.high)) {
            soundToPlay = _soundQueue.firstWhere((s) => s.priority == SoundPriority.high);
        } else if (_soundQueue.any((s) => s.priority == SoundPriority.normal)) {
            soundToPlay = _soundQueue.firstWhere((s) => s.priority == SoundPriority.normal);
        }

        _soundQueue.remove(soundToPlay);
        _activePlayers[player] = soundToPlay.completer;

        // --- Play the sound with robust error handling ---
        try {
            // Check if player is still usable before operations
            if (!_isPlayerUsable(player)) {
                debugPrint('❌ Player unusable before playback: ${soundToPlay.path}');
                throw Exception('Player not usable');
            }

            // Set volume using safe method
            final volumeSet = await _safeSetVolume(player, _soundVolume);
            if (!volumeSet) {
                debugPrint('❌ Failed to set volume for: ${soundToPlay.path}');
                throw Exception('Failed to set volume');
            }
            
            String processedPath = soundToPlay.path.replaceFirst('assets/', '');
            debugPrint('🔊 Attempting to play sound: ${soundToPlay.path} (processed as $processedPath)');
            
            Source source = AssetSource(processedPath);
            
            // Start playback using safe method
            final playSuccess = await _safePlaySound(player, source);
            if (!playSuccess) {
                throw Exception('Failed to play sound safely');
            }
            _handlePlaybackCompletion(player, soundToPlay);

        } catch (e) {
            debugPrint('❌ Error playing sound ${soundToPlay.path}: $e');
            
            // Mark for potential system reinitialize if errors persist
            _needsReinitialize = true;
            
            if (!soundToPlay.completer.isCompleted) {
                soundToPlay.completer.completeError(e);
            }
            _releasePlayer(player);
        }
        
        // Brief pause to prevent tight loop
         await Future.delayed(const Duration(milliseconds: 2));
    }

    _isProcessingQueue = false;
  }

  /// Handles the completion of a sound playback asynchronously.
  void _handlePlaybackCompletion(AudioPlayer player, _QueuedSound playedSound) async {
        StreamSubscription? subscription;
        subscription = player.onPlayerComplete.listen((_) {
            if (!playedSound.completer.isCompleted) {
                playedSound.completer.complete();
            }
             _releasePlayer(player);
            subscription?.cancel();
        }, onError: (error) {
             debugPrint('❌ Player stream error for ${playedSound.path}: $error');
             if (!playedSound.completer.isCompleted) {
                playedSound.completer.completeError(error);
            }
            _releasePlayer(player);
            subscription?.cancel();
        });

        // Safety timeout: reduced to 5 seconds for better responsiveness
        Future.delayed(const Duration(seconds: 5), () {
             if (_activePlayers.containsKey(player) && !playedSound.completer.isCompleted) {
                  debugPrint('🔊 Playback timeout for ${playedSound.path}, releasing player.');
                  playedSound.completer.completeError('Playback timeout');
                  // Use safe stop method for timeout scenario
                  _safeStopPlayer(player);
                  _releasePlayer(player);
                  subscription?.cancel();
             }
        });
  }

  /// Gets an available player from the pool with better fallback handling.
  AudioPlayer? _getAvailablePlayer() {
    // Clean up any unusable players from the pool first
    _playerPool.removeWhere((player) => !_isPlayerUsable(player));
    
    if (_playerPool.isEmpty) {
        debugPrint('🔊 Player pool empty!');
        // Check for finished players that can be released
        var finishedPlayers = _activePlayers.entries.where((entry) {
          try {
            return entry.key.state == PlayerState.completed || 
                   entry.key.state == PlayerState.stopped ||
                   !_isPlayerUsable(entry.key);
          } catch (e) {
            return true; // If we can't check state, consider it finished
          }
        }).toList();
         
         for(var entry in finishedPlayers) {
             debugPrint("🔊 Found finished/unusable player, releasing.");
             _releasePlayer(entry.key);
         }
         
         // Try getting from pool again
         if(_playerPool.isNotEmpty) return _playerPool.removeLast();
         
         // Create temporary player if absolutely necessary
         if (_activePlayers.length < _maxPoolSize * 2) {
           debugPrint("🔊 Creating temporary player due to high demand.");
           try {
             var tempPlayer = _createNewPlayer();
             return tempPlayer;
           } catch (e) {
             debugPrint('❌ Failed to create temporary player: $e');
             _needsReinitialize = true;
             return null;
           }
         }
         
         return null;
    }
    return _playerPool.removeLast();
  }

  /// Returns a player to the pool and triggers queue processing.
  void _releasePlayer(AudioPlayer player) {
     // First remove from active players
     _activePlayers.remove(player);
     
     if (_playerPool.length < _maxPoolSize && _isPlayerUsable(player)) {
         try {
             // Try to safely stop the player before returning to pool
             _safeStopPlayer(player);
             _playerPool.add(player);
             debugPrint("🔊 Player returned to pool");
         } catch (e) {
             debugPrint("❌ Error resetting player for pool: $e");
             // If we can't reset it, dispose it and create a new one
             _safeDisposePlayer(player);
             try {
               final newPlayer = _createNewPlayer();
               _playerPool.add(newPlayer);
               debugPrint("🔊 Created replacement player for pool");
             } catch (createError) {
               debugPrint("❌ Failed to create replacement player: $createError");
               _needsReinitialize = true;
             }
         }
     } else {
         // Pool is full or player is unusable, dispose it
         debugPrint("🔊 Disposing player (pool full or player unusable)");
         _safeDisposePlayer(player);
     }

      // Only trigger queue processing if not in background
      if (!_isAppInBackground) {
        _triggerQueueProcessing();
      }
  }

  /// Stops all currently playing and queued sounds.
  void stopAllSounds() {
    debugPrint('🔊 Stopping all sounds...');
    _soundQueue.clear();

    // Stop all dedicated tap players using safe method
    for (var player in _tapPlayerPool) {
      _safeStopPlayer(player);
    }

    // Stop active players using safe method
    final List<AudioPlayer> playersToStop = _activePlayers.keys.toList();
    for (var player in playersToStop) {
      // Complete any pending operations first
      final completer = _activePlayers[player];
      if (completer != null && !completer.isCompleted) {
         completer.completeError('Playback stopped by user/system');
      }
      
      // Safely stop the player
      _safeStopPlayer(player);
       _releasePlayer(player);
    }
     _activePlayers.clear();
     debugPrint('🔊 All sounds stopped.');
  }

  // --- Legacy/Compatibility Methods (Called by LegacySoundManager/GameSounds) ---
  // These often delegate to the main playSound method. Ensure parameters match.

   Future<void> playTapSound() async {
      if (!isUiSoundsEnabled) return;
      await playSound(SoundAssets.uiTap, priority: SoundPriority.normal);
   }

   Future<void> playUiTapSound() async => playTapSound(); // Alias

   Future<void> playUiTapBoostedSound() async {
      if (!isUiSoundsEnabled) return;
      await playSound(SoundAssets.uiTapBoosted, priority: SoundPriority.normal);
   }

   Future<void> playUiTabChangeSound() async {
      if (!isUiSoundsEnabled) return;
      await playSound(SoundAssets.uiTabChange, priority: SoundPriority.normal);
   }

   Future<void> playAchievementBasicSound() async {
      if (!isAchievementSoundsEnabled) return;
      await playSound(SoundAssets.achievementBasic, priority: SoundPriority.high);
   }
    Future<void> playAchievementRareSound() async {
      if (!isAchievementSoundsEnabled) return;
      await playSound(SoundAssets.achievementRare, priority: SoundPriority.high);
   }
   Future<void> playAchievementMilestoneSound() async {
      if (!isAchievementSoundsEnabled) return;
      await playSound(SoundAssets.achievementMilestone, priority: SoundPriority.high);
   }

   Future<void> playBusinessPurchaseSound() async {
      if (!isBusinessSoundsEnabled) return;
      await playSound(SoundAssets.businessPurchase, priority: SoundPriority.normal);
   }
   Future<void> playBusinessUpgradeSound() async {
      if (!isBusinessSoundsEnabled) return;
      await playSound(SoundAssets.businessUpgrade, priority: SoundPriority.normal);
   }
   Future<void> playBusinessMaxLevelSound() async {
      if (!isBusinessSoundsEnabled) return;
      await playSound(SoundAssets.businessMaxLevel, priority: SoundPriority.high);
   }

   Future<void> playInvestmentBuyStockSound() async {
      if (!isInvestmentSoundsEnabled) return;
      await playSound(SoundAssets.investmentBuyStock, priority: SoundPriority.normal);
   }
   Future<void> playInvestmentSellStockSound() async {
      if (!isInvestmentSoundsEnabled) return;
      await playSound(SoundAssets.investmentSellStock, priority: SoundPriority.normal);
   }
   Future<void> playInvestmentMarketEventSound() async {
      if (!isInvestmentSoundsEnabled) return;
      await playSound(SoundAssets.investmentMarketEvent, priority: SoundPriority.high);
   }

   Future<void> playRealEstatePurchaseSound() async {
      if (!isRealEstateSoundsEnabled) return;
      await playSound(SoundAssets.realEstatePurchase, priority: SoundPriority.normal);
   }
   // Assuming real estate upgrade uses the same sound as business upgrade
   Future<void> playRealEstateUpgradeSound() async {
      if (!isRealEstateSoundsEnabled) return;
      await playSound(SoundAssets.businessUpgrade, priority: SoundPriority.normal);
   }
   Future<void> playRealEstateLocaleUnlockSound() async {
      if (!isRealEstateSoundsEnabled) return;
      await playSound(SoundAssets.realEstateLocaleUnlock, priority: SoundPriority.high);
   }
   Future<void> playRealEstateLocaleCompleteSound() async {
      if (!isRealEstateSoundsEnabled) return;
      await playSound(SoundAssets.realEstateLocaleComplete, priority: SoundPriority.high);
   }

   Future<void> playEventStartupSound() async {
      if (!isEventSoundsEnabled) return;
      await playSound(SoundAssets.eventStartup, priority: SoundPriority.high);
   }
   Future<void> playEventReincorporationSound() async {
      if (!_isInitialized || !_isSoundEnabled || !_isEventSoundsEnabled) return;
      await playSound(SoundAssets.eventReincorporation, priority: SoundPriority.high);
   }
   Future<void> playEventSpecialSound() async {
      if (!isEventSoundsEnabled) return;
      await playSound(SoundAssets.eventSpecial, priority: SoundPriority.high);
   }

   Future<void> playFeedbackErrorSound() async {
      if (!isFeedbackSoundsEnabled) return;
      // Use the specific method to ensure correct asset path is used
      await playSound(SoundAssets.feedbackError, priority: SoundPriority.normal);
   }
    Future<void> playFeedbackSuccessSound() async {
      if (!isFeedbackSoundsEnabled) return;
      await playSound(SoundAssets.feedbackSuccess, priority: SoundPriority.normal);
   }
   Future<void> playFeedbackNotificationSound() async {
      if (!isFeedbackSoundsEnabled) return;
      await playSound(SoundAssets.feedbackNotification, priority: SoundPriority.normal);
   }

    // Special case for platinum purchase - uses a different path format
   Future<void> playPlatinumPurchaseSound() async {
      // Platinum sound might bypass category checks or use feedback category? Assuming feedback for now.
      if (!isFeedbackSoundsEnabled) return;
      // Use the constant from SoundAssets 
      await playSound(SoundAssets.platinumPurchase, priority: SoundPriority.high);
   }

   Future<void> playEventTriggeredSound() async {
     await playSound(SoundAssets.eventTriggered, priority: SoundPriority.high);
   }

   Future<void> playOfflineIncomeSound() async {
     if (!_isInitialized || !_isSoundEnabled || !_isEventSoundsEnabled) return;
     await playSound(SoundAssets.offlineIncome, priority: SoundPriority.high);
   }

   Future<void> playOfflineIncomeCollectSound() async {
     if (!_isInitialized || !_isSoundEnabled || !_isEventSoundsEnabled) return;
     await playSound(SoundAssets.offlineIncomeCollect, priority: SoundPriority.high);
   }

   /// Plays only when user claims offline income with 2x bonus (after watching ad).
   Future<void> playOfflineIncomeBonusSound() async {
     if (!_isInitialized || !_isSoundEnabled || !_isEventSoundsEnabled) return;
     await playSound(SoundAssets.offlineIncomeBonus, priority: SoundPriority.high);
   }

} 