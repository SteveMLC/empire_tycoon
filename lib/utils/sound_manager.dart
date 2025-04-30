import 'dart:async';
import 'dart:collection';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
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

/// Manages sound playback, caching, pooling, and settings.
class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;

  SoundManager._internal(); // Private constructor for singleton

  late SharedPreferences _prefs;
  final AudioCache _audioCache = AudioCache(prefix: ''); // Use AudioCache for efficiency
  final List<AudioPlayer> _playerPool = [];
  final Map<AudioPlayer, Completer<void>> _activePlayers = {};
  final int _maxPoolSize = 5; // Limit concurrent players to prevent resource exhaustion
  final int _maxQueueSize = 20; // Limit queued sounds

  final Queue<_QueuedSound> _soundQueue = Queue();
  bool _isProcessingQueue = false;
  bool _isInitialized = false;

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

  // Throttling for tap sounds
  DateTime _lastTapSoundTime = DateTime.now();
  final Duration _tapThrottleDuration = const Duration(milliseconds: 50); // Only allow tap sound every 50ms

  // --- Initialization & Disposal ---

  Future<void> init() async {
    if (_isInitialized) return;
    debugPrint('🔊 Initializing SoundManager...');
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSettings();
      _initPlayerPool();
      _isInitialized = true;
      debugPrint('🔊 SoundManager Initialized Successfully.');
      debugPrint('   Sound Enabled: $_isSoundEnabled, Volume: $_soundVolume');
      // Preload common sounds (optional, AssetLoader might handle this)
      // Consider preloading UI sounds here if AssetLoader doesn't
      // await _audioCache.loadAll([SoundAssets.uiTap]); // Example
    } catch (e) {
      debugPrint('❌ Error initializing SoundManager: $e');
      // Defaults will be used if loading fails
      _isSoundEnabled = true;
      _soundVolume = 1.0;
    }
  }

  void _initPlayerPool() {
    _playerPool.clear(); // Ensure pool is empty
    for (int i = 0; i < _maxPoolSize; i++) {
      _playerPool.add(AudioPlayer()..setReleaseMode(ReleaseMode.stop)); // Use STOP for faster reuse
    }
    debugPrint('🔊 AudioPlayer pool initialized with ${_playerPool.length} players.');
  }

  void dispose() {
    debugPrint('🔊 Disposing SoundManager...');
    _soundQueue.clear();
    _isProcessingQueue = false;
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
     // Set volume on the cache instance as well? (Check audioplayers docs if needed)
    // await _audioCache.fixedPlayer?.setVolume(_soundVolume); ?? Might not be needed
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
    // await _audioCache.fixedPlayer?.setVolume(_soundVolume); ?? Might not be needed
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

  /// Plays a sound effect.
  /// Returns a Future that completes when the sound finishes playing or fails.
  Future<void> playSound(
    String path, {
    bool useCache = true, // Generally recommended
    SoundPriority priority = SoundPriority.normal,
  }) async {
    if (!_isInitialized || !_isSoundEnabled) {
      //debugPrint('🔊 SoundManager not ready or sounds disabled, skipping $path');
      return; // Don't queue if disabled
    }

    // --- Tap Sound Throttling ---
    if (path == SoundAssets.uiTap) {
        final now = DateTime.now();
        if (now.difference(_lastTapSoundTime) < _tapThrottleDuration) {
           //debugPrint('🔊 Tap sound throttled, skipping.');
            return; // Skip playing if throttled
        }
        _lastTapSoundTime = now;
    }

    final completer = Completer<void>();
    final queuedSound = _QueuedSound(path, useCache, priority, completer);

    // --- Queue Management ---
    if (_soundQueue.length >= _maxQueueSize) {
        // If queue is full, consider dropping low priority sounds
        if (priority == SoundPriority.low) {
            debugPrint('🔊 Sound queue full, dropping low priority sound: $path');
            completer.completeError('Queue full, sound dropped');
            return;
        } else {
             debugPrint('🔊 Sound queue full, trying to make space...');
             // Attempt to remove the oldest low-priority sound
             try {
                 final removed = _soundQueue.firstWhere((s) => s.priority == SoundPriority.low);
                 _soundQueue.remove(removed);
                 removed.completer.completeError('Queue full, sound dropped');
                 debugPrint('🔊 Removed low priority sound ${removed.path} to make space.');
             } catch (e) {
                // No low priority sound found, drop the current sound if it's normal prio
                 if (priority == SoundPriority.normal) {
                     debugPrint('🔊 Sound queue full, no low prio found, dropping normal priority sound: $path');
                     completer.completeError('Queue full, sound dropped');
                     return;
                 }
                 // High priority sounds might wait longer or have different handling if needed
                 // For now, add high priority even if slightly over limit (or implement smarter eviction)
                 debugPrint('🔊 Sound queue full, but adding high priority sound: $path');
             }
        }
    }

    _soundQueue.add(queuedSound);
    //debugPrint('🔊 Queued sound: $path (Priority: $priority, Queue size: ${_soundQueue.length})');
    _triggerQueueProcessing(); // Ensure the queue processor runs

    return completer.future; // Return the future for callers to await if needed
  }

  /// Internal method to process the sound queue.
  void _triggerQueueProcessing() async {
    if (_isProcessingQueue || _soundQueue.isEmpty) {
      return;
    }

    _isProcessingQueue = true;
    //debugPrint('🔊 Starting queue processing...');

    while (_soundQueue.isNotEmpty && _isInitialized) { // Check initialization status in loop
        // Find an available player
        AudioPlayer? player = _getAvailablePlayer();

        if (player == null) {
           // debugPrint('🔊 No available players, waiting...');
            // Optional: Wait a short duration before checking again, or rely on player release to re-trigger
            await Future.delayed(const Duration(milliseconds: 20)); // Small delay
            continue; // Re-check for available player in the next loop iteration
        }

        // Dequeue the highest priority sound
        // Simple priority: High > Normal > Low. If equal priority, FIFO.
        _QueuedSound soundToPlay = _soundQueue.first; // Default to FIFO
        if (_soundQueue.any((s) => s.priority == SoundPriority.high)) {
            soundToPlay = _soundQueue.firstWhere((s) => s.priority == SoundPriority.high);
        } else if (_soundQueue.any((s) => s.priority == SoundPriority.normal)) {
            soundToPlay = _soundQueue.firstWhere((s) => s.priority == SoundPriority.normal);
        } // Low priority is handled by default FIFO if no higher ones exist

        _soundQueue.remove(soundToPlay); // Remove the chosen sound from queue

       // debugPrint('🔊 Playing sound: ${soundToPlay.path} (Priority: ${soundToPlay.priority}) on player ${player.playerId}');
        _activePlayers[player] = soundToPlay.completer; // Track active player

        // --- Play the sound with robust error handling ---
        try {
            // Ensure volume is set correctly before playing
            await player.setVolume(_soundVolume);
            
            String processedPath = soundToPlay.path.replaceFirst('assets/', '');
            debugPrint('🔊 Attempting to play sound: ${soundToPlay.path} (processed as $processedPath)');
            
            Source source;
            if (soundToPlay.useCache) {
                // For AssetSource, we need to strip the 'assets/' prefix
                // The path in SoundAssets is 'assets/sounds/ui/tap.mp3' but AssetSource needs 'sounds/ui/tap.mp3'
                source = AssetSource(processedPath); 
            } else {
                // Same for direct loading
                source = AssetSource(processedPath);
                 // Note: Playing directly without cache might be less performant
            }
            
            // Start playback
            await player.play(source);

            // --- Asynchronous wait for completion ---
             // Use a separate async function to handle completion without blocking queue processing
            _handlePlaybackCompletion(player, soundToPlay);


        } catch (e) {
            debugPrint('❌ Error playing sound ${soundToPlay.path}: $e');
            // More detailed error information
            if (e.toString().contains('NotSupportedError')) {
                debugPrint('❌ File not found or format not supported. Check if file exists at: ${soundToPlay.path}');
            }
            if (!soundToPlay.completer.isCompleted) {
                soundToPlay.completer.completeError(e); // Signal error
            }
            _releasePlayer(player); // Release player immediately on error
        }
        // Brief pause to prevent tight loop hammering in case of rapid errors/empty queue checks
         await Future.delayed(const Duration(milliseconds: 5));
    }

    _isProcessingQueue = false;
   // debugPrint('🔊 Queue processing finished.');
  }


  /// Handles the completion of a sound playback asynchronously.
  void _handlePlaybackCompletion(AudioPlayer player, _QueuedSound playedSound) async {
        // Wait for the player to complete
        // We rely on the stream rather than a potentially long await player.play()
        StreamSubscription? subscription;
        subscription = player.onPlayerComplete.listen((_) {
           // debugPrint('🔊 Playback complete: ${playedSound.path} on player ${player.playerId}');
            if (!playedSound.completer.isCompleted) {
                playedSound.completer.complete(); // Signal successful completion
            }
             _releasePlayer(player);
            subscription?.cancel(); // Clean up listener
        }, onError: (error) {
             debugPrint('❌ Player stream error for ${playedSound.path}: $error');
             if (!playedSound.completer.isCompleted) {
                playedSound.completer.completeError(error); // Signal error
            }
            _releasePlayer(player);
            subscription?.cancel();
        });

        // Safety timeout: If a sound hangs, release the player after a max duration
        Future.delayed(const Duration(seconds: 10), () {
             if (_activePlayers.containsKey(player) && !playedSound.completer.isCompleted) {
                  debugPrint('🔊 Playback timeout for ${playedSound.path}, releasing player ${player.playerId}.');
                  playedSound.completer.completeError('Playback timeout');
                   try { player.stop(); } catch (_) {} // Attempt to stop hanging player
                  _releasePlayer(player);
                   subscription?.cancel();
             }
        });
  }


  /// Gets an available player from the pool.
  AudioPlayer? _getAvailablePlayer() {
    if (_playerPool.isEmpty) {
        // Pool exhausted, potentially log or handle this case
        // Could dynamically create a temporary player if needed, but riskier
        debugPrint('🔊 Player pool empty!');
        // Check if any active players are actually finished but not yet released
        // (This shouldn't happen with the stream listener, but as a fallback)
         var finishedPlayers = _activePlayers.entries.where((entry) => entry.key.state == PlayerState.completed).toList();
         for(var entry in finishedPlayers) {
             debugPrint("🔊 Found finished player ${entry.key.playerId} stuck in active list. Releasing.");
             _releasePlayer(entry.key);
         }
         // Try getting from pool again after potential cleanup
         if(_playerPool.isNotEmpty) return _playerPool.removeLast();
         else return null; // Still no player

    }
    return _playerPool.removeLast(); // Get player from end of list
  }

  /// Returns a player to the pool and triggers queue processing.
  void _releasePlayer(AudioPlayer player) {
     // Only put back if pool isn't over capacity (e.g., due to errors/re-init)
     if (_playerPool.length < _maxPoolSize) {
         // Reset player state before returning to pool (optional but good practice)
         try {
             // player.stop(); // STOP release mode handles this mostly
             // player.seek(Duration.zero); // Reset position if needed
         } catch (e) {
             debugPrint("Error resetting player ${player.playerId}: $e");
             // If reset fails, consider disposing and creating a new one
              try { player.dispose(); } catch (_) {}
              player = AudioPlayer()..setReleaseMode(ReleaseMode.stop)..setVolume(_soundVolume);
         }
         _playerPool.add(player);
         //debugPrint('🔊 Player ${player.playerId} released. Pool size: ${_playerPool.length}');
     } else {
         // Pool is full or over capacity, just dispose the player
         debugPrint('🔊 Player pool full/over capacity. Disposing extra player ${player.playerId}.');
          try {
             player.dispose();
         } catch (e) { debugPrint("Error disposing extra player: $e"); }
     }

      _activePlayers.remove(player); // Remove from active tracking
      _triggerQueueProcessing(); // Check if more sounds are waiting
  }

  /// Stops all currently playing and queued sounds.
  void stopAllSounds() {
    debugPrint('🔊 Stopping all sounds...');
    _soundQueue.clear(); // Clear the queue

    // Stop active players
    final List<AudioPlayer> playersToStop = _activePlayers.keys.toList();
    for (var player in playersToStop) {
      try {
          if (player.state != PlayerState.stopped && player.state != PlayerState.disposed) {
             player.stop(); // Request stop
          }
        // Signal error/cancel to waiting futures
        final completer = _activePlayers[player];
        if (completer != null && !completer.isCompleted) {
           completer.completeError('Playback stopped by user/system');
        }
      } catch (e) {
        debugPrint('Error stopping player ${player.playerId}: $e');
      }
       _releasePlayer(player); // Release player immediately after stopping
    }
     _activePlayers.clear(); // Ensure active list is clear
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
      if (!isEventSoundsEnabled) return;
      await playSound(SoundAssets.eventReincorporation, priority: SoundPriority.high);
   }
   Future<void> playEventOfflineIncomeSound() async {
      if (!isEventSoundsEnabled) return;
      await playSound(SoundAssets.eventOfflineIncome, priority: SoundPriority.normal);
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

} 