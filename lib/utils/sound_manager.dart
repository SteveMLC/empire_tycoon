import 'dart:async';
import 'dart:collection';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // Dedicated tap player pool for overlapping sounds
  final List<AudioPlayer> _tapPlayerPool = [];
  final int _maxTapPlayerPoolSize = 6; // Allow up to 6 overlapping tap sounds
  int _currentTapPlayerIndex = 0;

  // --- Initialization & Disposal ---

  Future<void> init() async {
    if (_isInitialized) return;
    debugPrint('🔊 Initializing SoundManager...');
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSettings();
      _initPlayerPool();
      _initDedicatedTapPlayer();
      
      // Register for app lifecycle changes
      WidgetsBinding.instance.addObserver(this);
      
      _isInitialized = true;
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
  void _initDedicatedTapPlayer() {
    _tapPlayerPool.clear();
    for (int i = 0; i < _maxTapPlayerPoolSize; i++) {
      AudioPlayer player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      player.setVolume(_soundVolume);
      _tapPlayerPool.add(player);
    }
    debugPrint('🔊 Dedicated tap player pool initialized with ${_tapPlayerPool.length} players.');
  }

  void _initPlayerPool() {
    _playerPool.clear(); // Ensure pool is empty
    for (int i = 0; i < _maxPoolSize; i++) {
      _playerPool.add(AudioPlayer()..setReleaseMode(ReleaseMode.stop)); // Use STOP for faster reuse
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
        debugPrint('🔊 App resumed - sounds re-enabled');
        break;
      case AppLifecycleState.inactive:
        // Don't stop sounds on inactive (brief interruptions)
        break;
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
      try {
        player.dispose();
      } catch (e) {
        debugPrint('Error disposing tap player: $e');
      }
    }
    _tapPlayerPool.clear();
    
    // Release all players in the pool
    for (var player in _playerPool) {
      try {
        player.dispose();
      } catch (e) {
        debugPrint('Error disposing player: $e');
      }
    }
    _playerPool.clear();
    // Cancel any active playback completers
    _activePlayers.forEach((player, completer) {
      if (!completer.isCompleted) {
        completer.completeError('SoundManager disposed during playback');
      }
      try {
         player.dispose(); // Ensure active players are also disposed
      } catch (e) {
         debugPrint('Error disposing active player: $e');
      }
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
    // Apply initial volume to pool (new players might need volume set)
    for (var player in _playerPool) {
        try {
            await player.setVolume(_soundVolume);
        } catch (e) { debugPrint("Error setting initial volume: $e"); }
    }
    // Set volume on dedicated tap players
    for (var player in _tapPlayerPool) {
      try {
        player.setVolume(_soundVolume);
      } catch (e) { debugPrint("Error setting initial tap player volume: $e"); }
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
    // Apply volume to all current and future players
    for (var player in _playerPool) {
      try {
          await player.setVolume(_soundVolume);
      } catch (e) { debugPrint("Error setting volume on pooled player: $e"); }
    }
    for (var player in _activePlayers.keys) {
       try {
          await player.setVolume(_soundVolume);
      } catch (e) { debugPrint("Error setting volume on active player: $e"); }
    }
    // Update dedicated tap players
    for (var player in _tapPlayerPool) {
      player.setVolume(_soundVolume);
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

    // --- Optimized Overlapping Tap Sound Handling ---
    if (path == SoundAssets.uiTap || path == SoundAssets.uiTapBoosted) {
      return _playTapSoundOverlapping(path);
    }

    final completer = Completer<void>();
    final queuedSound = _QueuedSound(path, useCache, priority, completer);

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

  /// Optimized tap sound playback with overlapping support using dedicated player pool
  Future<void> _playTapSoundOverlapping(String path) async {
    if (_tapPlayerPool.isEmpty) {
      debugPrint('🔊 Tap player pool not initialized, falling back to regular queue');
      // Fallback to regular sound system
      final completer = Completer<void>();
      final queuedSound = _QueuedSound(path, true, SoundPriority.normal, completer);
      _soundQueue.add(queuedSound);
      _triggerQueueProcessing();
      return;
    }

    // Get the next available tap player in round-robin fashion
    AudioPlayer player = _tapPlayerPool[_currentTapPlayerIndex];
    _currentTapPlayerIndex = (_currentTapPlayerIndex + 1) % _maxTapPlayerPoolSize;

    try {
      // Ensure volume is set correctly
      await player.setVolume(_soundVolume);
      
      String processedPath = path.replaceFirst('assets/', '');
      Source source = AssetSource(processedPath);
      
      // Don't stop the current player - allow overlapping!
      // Just start the new sound on this player
      await player.play(source);
      
      debugPrint('🔊 Playing overlapping tap sound on player ${_currentTapPlayerIndex}');
      
    } catch (e) {
      debugPrint('❌ Error playing overlapping tap sound: $e');
      // If there's an error, try to reinitialize this player
      try {
        player.dispose();
        _tapPlayerPool[(_currentTapPlayerIndex - 1) % _maxTapPlayerPoolSize] = AudioPlayer()
          ..setReleaseMode(ReleaseMode.stop)
          ..setVolume(_soundVolume);
        debugPrint('🔊 Reinitializeed tap player due to error');
      } catch (reinitError) {
        debugPrint('❌ Failed to reinitialize tap player: $reinitError');
      }
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
            await player.setVolume(_soundVolume);
            
            String processedPath = soundToPlay.path.replaceFirst('assets/', '');
            debugPrint('🔊 Attempting to play sound: ${soundToPlay.path} (processed as $processedPath)');
            
            Source source = AssetSource(processedPath);
            
            // Start playback
            await player.play(source);
            _handlePlaybackCompletion(player, soundToPlay);

        } catch (e) {
            debugPrint('❌ Error playing sound ${soundToPlay.path}: $e');
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
                   try { player.stop(); } catch (_) {}
                  _releasePlayer(player);
                   subscription?.cancel();
             }
        });
  }

  /// Gets an available player from the pool with better fallback handling.
  AudioPlayer? _getAvailablePlayer() {
    if (_playerPool.isEmpty) {
        debugPrint('🔊 Player pool empty!');
        // Check for finished players that can be released
         var finishedPlayers = _activePlayers.entries.where((entry) => 
           entry.key.state == PlayerState.completed || 
           entry.key.state == PlayerState.stopped).toList();
         
         for(var entry in finishedPlayers) {
             debugPrint("🔊 Found finished player, releasing.");
             _releasePlayer(entry.key);
         }
         
         // Try getting from pool again
         if(_playerPool.isNotEmpty) return _playerPool.removeLast();
         
         // Create temporary player if absolutely necessary
         if (_activePlayers.length < _maxPoolSize * 2) {
           debugPrint("🔊 Creating temporary player due to high demand.");
           var tempPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
           tempPlayer.setVolume(_soundVolume);
           return tempPlayer;
         }
         
         return null;
    }
    return _playerPool.removeLast();
  }

  /// Returns a player to the pool and triggers queue processing.
  void _releasePlayer(AudioPlayer player) {
     if (_playerPool.length < _maxPoolSize) {
         try {
             // Quick reset without complex operations
         } catch (e) {
             debugPrint("Error resetting player: $e");
              try { player.dispose(); } catch (_) {}
              player = AudioPlayer()..setReleaseMode(ReleaseMode.stop)..setVolume(_soundVolume);
         }
         _playerPool.add(player);
     } else {
         // Pool is full, dispose extra player
         try {
             player.dispose();
         } catch (e) { debugPrint("Error disposing extra player: $e"); }
     }

      _activePlayers.remove(player);
      // Only trigger queue processing if not in background
      if (!_isAppInBackground) {
        _triggerQueueProcessing();
      }
  }

  /// Stops all currently playing and queued sounds.
  void stopAllSounds() {
    debugPrint('🔊 Stopping all sounds...');
    _soundQueue.clear();

    // Stop all dedicated tap players
    for (var player in _tapPlayerPool) {
      try {
        if (player.state != PlayerState.stopped && player.state != PlayerState.disposed) {
          player.stop();
        }
      } catch (e) {
        debugPrint('Error stopping tap player: $e');
      }
    }

    // Stop active players
    final List<AudioPlayer> playersToStop = _activePlayers.keys.toList();
    for (var player in playersToStop) {
      try {
          if (player.state != PlayerState.stopped && player.state != PlayerState.disposed) {
             player.stop();
          }
        final completer = _activePlayers[player];
        if (completer != null && !completer.isCompleted) {
           completer.completeError('Playback stopped by user/system');
        }
      } catch (e) {
        debugPrint('Error stopping player: $e');
      }
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

} 