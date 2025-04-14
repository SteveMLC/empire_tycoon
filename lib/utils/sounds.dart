import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Sound System for Empire Tycoon
///
/// This file provides two complementary ways to play sounds:
/// 1. SoundManager - A singleton instance-based approach using method calls
/// 2. GameSounds - A static utility class with function references
///
/// Both systems share the same sound settings and use the SharedPreferences
/// for persistence.

// Shared constants for sound file paths
class SoundAssets {
  // SharedPreferences keys for sound settings
  static const String soundPrefsKey = 'sound_enabled';
  static const String volumePrefsKey = 'sound_volume';

  // Legacy paths (to maintain backward compatibility during transition)
  static const String legacyTapSound = 'sounds/tap.mp3';
  static const String legacyPurchaseSound = 'sounds/purchase.mp3';
  static const String legacySuccessSound = 'sounds/success.mp3';
  static const String legacyErrorSound = 'sounds/error.mp3';
  
  // UI Sounds
  static const String uiTap = 'sounds/ui/tap.mp3';
  static const String uiTapBoosted = 'sounds/ui/tap_boosted.mp3';
  static const String uiTabChange = 'sounds/ui/tap_change.mp3'; // Correct name is tap_change.mp3
  
  // Achievement Sounds
  static const String achievementBasic = 'sounds/achievements/achievement_basic.mp3';
  static const String achievementRare = 'sounds/achievements/achievement_rare.mp3';
  static const String achievementMilestone = 'sounds/achievements/achievement_milestone.mp3';
  
  // Business Sounds
  static const String businessPurchase = 'sounds/business/purchase.mp3';
  static const String businessUpgrade = 'sounds/business/upgrade.mp3';
  static const String businessMaxLevel = 'sounds/business/max_level.mp3';
  
  // Investment Sounds
  static const String investmentBuyStock = 'sounds/investment/buy_stock.mp3';
  static const String investmentSellStock = 'sounds/investment/sell_stock.mp3';
  static const String investmentMarketEvent = 'sounds/investment/market_event.mp3';
  
  // Real Estate Sounds
  static const String realEstatePurchase = 'sounds/real_estate/property_purchase.mp3';
  static const String realEstateLocaleUnlock = 'sounds/real_estate/locale_unlock.mp3';
  static const String realEstateLocaleComplete = 'sounds/real_estate/locale_complete.mp3';
  
  // Event Sounds
  static const String eventStartup = 'sounds/events/startup.mp3';
  static const String eventReincorporation = 'sounds/events/reincorporation.mp3';
  static const String eventOfflineIncome = 'sounds/events/offline_income.mp3';
  static const String eventSpecial = 'sounds/events/special_event.mp3';
  
  // Feedback Sounds
  static const String feedbackError = 'sounds/feedback/error.mp3';
  static const String feedbackSuccess = 'sounds/feedback/success.mp3';
  static const String feedbackNotification = 'sounds/feedback/notification.mp3';
}

/// Main sound manager class - Singleton instance based approach
class SoundManager {
  // Singleton instance
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();
  
  // Audio player instance - created only when needed
  AudioPlayer? _audioPlayer;
  bool _soundEnabled = true;
  bool _isInitialized = false;
  double _volume = 1.0; // Default volume level (0.0 to 1.0)
  
  // Sound category muting
  bool _uiSoundsEnabled = true;
  bool _achievementSoundsEnabled = true;
  bool _businessSoundsEnabled = true;
  bool _investmentSoundsEnabled = true;
  bool _realEstateSoundsEnabled = true;
  bool _eventSoundsEnabled = true;
  bool _feedbackSoundsEnabled = true;
  
  // Sound caching
  final Map<String, AudioPlayer> _cachedPlayers = {};
  
  /// Initialize the sound manager and load saved preferences
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      print('🔄 SoundManager: Initializing...');
      
      // Load sound settings from shared preferences
      await _loadSoundSettings();
      print('✅ SoundManager: Sound settings loaded, enabled: $_soundEnabled, volume: $_volume');
      
      // Initialize audio player if sound is enabled (for all platforms)
      if (_soundEnabled) {
        _initAudioPlayer();
      }
      
      // Share sound setting with the static GameSounds class
      GameSounds.isSoundEnabled = _soundEnabled;
      GameSounds.volume = _volume;
      
      _isInitialized = true;
    } catch (e, stackTrace) {
      print('🔴 SoundManager initialization error: $e');
      print('🔴 Stack trace: $stackTrace');
      // Don't rethrow - we can continue without sound if necessary
      _soundEnabled = false;
    }
  }
  
  /// Initialize the audio player instance
  void _initAudioPlayer() {
    try {
      if (_audioPlayer == null) {
        _audioPlayer = AudioPlayer();
        _audioPlayer!.setVolume(_volume);
        print('✅ SoundManager: Audio player initialized with volume $_volume');
      }
    } catch (e) {
      print('🔴 Error initializing audio player: $e');
      _soundEnabled = false;
    }
  }
  
  /// Load sound settings from SharedPreferences
  Future<void> _loadSoundSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool(SoundAssets.soundPrefsKey) ?? true; // Default to enabled
      _volume = prefs.getDouble(SoundAssets.volumePrefsKey) ?? 1.0; // Default to full volume
      
      // Ensure volume is in valid range
      _volume = _volume.clamp(0.0, 1.0);
    } catch (e) {
      print('🔴 Error loading sound settings: $e');
      // Keep using the defaults if there's an error
    }
  }
  
  /// Save sound settings to SharedPreferences
  Future<void> _saveSoundSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(SoundAssets.soundPrefsKey, _soundEnabled);
      await prefs.setDouble(SoundAssets.volumePrefsKey, _volume);
    } catch (e) {
      print('🔴 Error saving sound settings: $e');
      // Continue without crashing - settings just won't persist
    }
  }
  
  /// Toggle sound on/off and update both sound systems
  void toggleSound(bool enabled) {
    // Update both sound managers to stay in sync
    _soundEnabled = enabled;
    GameSounds.isSoundEnabled = enabled;
    
    // Save the setting for future app launches
    _saveSoundSettings();
    
    // Create or dispose audio player as needed
    if (enabled) {
      _initAudioPlayer();
    } else if (!enabled && _audioPlayer != null) {
      _audioPlayer!.dispose();
      _audioPlayer = null;
      
      // Also dispose any cached players
      _disposeCachedPlayers();
    }
    
    print('🔊 Sound ${enabled ? 'enabled' : 'disabled'}');
  }
  
  /// Set volume level (0.0 to 1.0) and save setting
  void setVolume(double volume) {
    // Ensure volume is in valid range
    volume = volume.clamp(0.0, 1.0);
    
    _volume = volume;
    GameSounds.volume = volume;
    
    // Update active players
    if (_audioPlayer != null) {
      _audioPlayer!.setVolume(volume);
    }
    
    // Update cached players
    for (var player in _cachedPlayers.values) {
      player.setVolume(volume);
    }
    
    // Save the setting
    _saveSoundSettings();
    print('🔊 Volume set to $_volume');
  }
  
  /// Get current sound state
  bool isSoundEnabled() => _soundEnabled;
  
  /// Get current volume level
  double getVolume() => _volume;
  
  /// Toggle specific sound category
  void toggleSoundCategory(String category, bool enabled) {
    switch (category.toLowerCase()) {
      case 'ui':
        _uiSoundsEnabled = enabled;
        break;
      case 'achievement':
      case 'achievements':
        _achievementSoundsEnabled = enabled;
        break;
      case 'business':
        _businessSoundsEnabled = enabled;
        break;
      case 'investment':
        _investmentSoundsEnabled = enabled;
        break;
      case 'realestate':
      case 'real_estate':
        _realEstateSoundsEnabled = enabled;
        break;
      case 'event':
      case 'events':
        _eventSoundsEnabled = enabled;
        break;
      case 'feedback':
        _feedbackSoundsEnabled = enabled;
        break;
      default:
        print('⚠️ Unknown sound category: $category');
    }
    print('🔊 $category sounds ${enabled ? 'enabled' : 'disabled'}');
  }
  
  /// Check if a specific sound category is enabled
  bool isSoundCategoryEnabled(String category) {
    switch (category.toLowerCase()) {
      case 'ui':
        return _uiSoundsEnabled;
      case 'achievement':
      case 'achievements':
        return _achievementSoundsEnabled;
      case 'business':
        return _businessSoundsEnabled;
      case 'investment':
        return _investmentSoundsEnabled;
      case 'realestate':
      case 'real_estate':
        return _realEstateSoundsEnabled;
      case 'event':
      case 'events':
        return _eventSoundsEnabled;
      case 'feedback':
        return _feedbackSoundsEnabled;
      default:
        print('⚠️ Unknown sound category: $category');
        return true; // Default to enabled for unknown categories
    }
  }
  
  /// Helper method to safely play sounds and handle errors
  Future<void> _safelyPlaySound(String soundPath, {bool useCache = false}) async {
    if (!_soundEnabled) return;
    
    try {
      // For frequently played sounds (like tap), we need to use a pooling approach
      if (useCache) {
        // Create a pool of AudioPlayers for this sound
        if (!_cachedPlayers.containsKey(soundPath)) {
          try {
            // Initialize with a player for this sound
            final player = AudioPlayer();
            player.setVolume(_volume);
            _cachedPlayers[soundPath] = player;
          } catch (e) {
            print('🔴 Error creating cached player for $soundPath: $e');
            useCache = false; // Fall back to non-cached approach
          }
        }
        
        if (useCache && _cachedPlayers.containsKey(soundPath)) {
          // For tap sounds, use a different approach to avoid stopping/starting rapidly
          if (soundPath == SoundAssets.uiTap || soundPath == SoundAssets.uiTapBoosted) {
            try {
              // Release the player if it's currently playing
              if (_cachedPlayers[soundPath]!.state == PlayerState.playing) {
                // For tap sounds, create a temporary player instead of stopping the current one
                final tempPlayer = AudioPlayer();
                tempPlayer.setVolume(_volume);
                await tempPlayer.play(AssetSource(soundPath));
                
                // Set up auto-disposal after sound finishes playing
                tempPlayer.onPlayerComplete.listen((_) {
                  tempPlayer.dispose();
                });
                return;
              } else {
                // If not playing, use the cached player
                await _cachedPlayers[soundPath]!.play(AssetSource(soundPath));
                return;
              }
            } catch (e) {
              print('🔴 Error with pooled tap sound player for $soundPath: $e');
              // Continue to fallback approach
            }
          } else {
            // For other cached sounds, just use the normal cached player
            await _cachedPlayers[soundPath]!.stop();
            await _cachedPlayers[soundPath]!.play(AssetSource(soundPath));
            return;
          }
        }
      }
      
      // Non-cached approach (fallback)
      // Lazy initialize audio player if needed
      if (_audioPlayer == null) {
        _initAudioPlayer();
      }
      
      if (_audioPlayer != null) {
        await _audioPlayer!.stop(); // Stop any currently playing sound
        await _audioPlayer!.play(AssetSource(soundPath));
      }
    } catch (e) {
      print('🔴 Error playing sound $soundPath: $e');
      // Continue without crashing - just log the error
    }
  }
  
  // Dispose cached players on cleanup
  void _disposeCachedPlayers() {
    for (var player in _cachedPlayers.values) {
      player.dispose();
    }
    _cachedPlayers.clear();
  }
  
  // LEGACY METHODS - For backward compatibility
  
  /// Play tap sound - for UI interactions (legacy path)
  Future<void> playTapSound() async {
    if (_uiSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.uiTap);
    }
  }
  
  /// Play purchase sound - for buying items (legacy path)
  Future<void> playPurchaseSound() async {
    if (_businessSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.businessPurchase);
    }
  }
  
  /// Play success sound - for achievements, level ups, etc. (legacy path)
  Future<void> playSuccessSound() async {
    if (_feedbackSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.feedbackSuccess);
    }
  }
  
  /// Play error sound - for invalid actions (legacy path)
  Future<void> playErrorSound() async {
    if (_feedbackSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.feedbackError);
    }
  }
  
  // UI SOUND METHODS
  
  /// Play UI tap sound
  Future<void> playUiTapSound() async {
    if (_uiSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.uiTap, useCache: true);
    }
  }
  
  /// Play UI boosted tap sound
  Future<void> playUiTapBoostedSound() async {
    if (_uiSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.uiTapBoosted, useCache: true);
    }
  }
  
  /// Play UI tab change sound
  Future<void> playUiTabChangeSound() async {
    if (_uiSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.uiTabChange, useCache: true);
    }
  }
  
  // ACHIEVEMENT SOUND METHODS
  
  /// Play achievement basic sound
  Future<void> playAchievementBasicSound() async {
    if (_achievementSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.achievementBasic);
    }
  }
  
  /// Play achievement rare sound
  Future<void> playAchievementRareSound() async {
    if (_achievementSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.achievementRare);
    }
  }
  
  /// Play achievement milestone sound
  Future<void> playAchievementMilestoneSound() async {
    if (_achievementSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.achievementMilestone);
    }
  }
  
  // BUSINESS SOUND METHODS
  
  /// Play business purchase sound
  Future<void> playBusinessPurchaseSound() async {
    if (_businessSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.businessPurchase);
    }
  }
  
  /// Play business upgrade sound
  Future<void> playBusinessUpgradeSound() async {
    if (_businessSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.businessUpgrade, useCache: true);
    }
  }
  
  /// Play business max level sound
  Future<void> playBusinessMaxLevelSound() async {
    if (_businessSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.businessMaxLevel);
    }
  }
  
  // INVESTMENT SOUND METHODS
  
  /// Play investment buy stock sound
  Future<void> playInvestmentBuyStockSound() async {
    if (_investmentSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.investmentBuyStock);
    }
  }
  
  /// Play investment sell stock sound
  Future<void> playInvestmentSellStockSound() async {
    if (_investmentSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.investmentSellStock);
    }
  }
  
  /// Play investment market event sound
  Future<void> playInvestmentMarketEventSound() async {
    if (_investmentSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.investmentMarketEvent);
    }
  }
  
  // REAL ESTATE SOUND METHODS
  
  /// Play real estate purchase sound
  Future<void> playRealEstatePurchaseSound() async {
    if (_realEstateSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.realEstatePurchase);
    }
  }
  
  /// Play real estate upgrade sound (uses business upgrade sound for now)
  Future<void> playRealEstateUpgradeSound() async {
    if (_realEstateSoundsEnabled) {
      // Use business upgrade sound but with caching enabled to prevent overlapping sounds
      await _safelyPlaySound(SoundAssets.businessUpgrade, useCache: true);
    }
  }
  
  /// Play real estate locale unlock sound
  Future<void> playRealEstateLocaleUnlockSound() async {
    if (_realEstateSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.realEstateLocaleUnlock);
    }
  }
  
  /// Play real estate locale complete sound
  Future<void> playRealEstateLocaleCompleteSound() async {
    if (_realEstateSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.realEstateLocaleComplete);
    }
  }
  
  // EVENT SOUND METHODS
  
  /// Play startup sound
  Future<void> playEventStartupSound() async {
    if (_eventSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.eventStartup);
    }
  }
  
  /// Play reincorporation sound
  Future<void> playEventReincorporationSound() async {
    if (_eventSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.eventReincorporation);
    }
  }
  
  /// Play offline income sound
  Future<void> playEventOfflineIncomeSound() async {
    if (_eventSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.eventOfflineIncome);
    }
  }
  
  /// Play special event sound
  Future<void> playEventSpecialSound() async {
    if (_eventSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.eventSpecial);
    }
  }
  
  // FEEDBACK SOUND METHODS
  
  /// Play feedback error sound
  Future<void> playFeedbackErrorSound() async {
    if (_feedbackSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.feedbackError, useCache: true);
    }
  }
  
  /// Play feedback success sound
  Future<void> playFeedbackSuccessSound() async {
    if (_feedbackSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.feedbackSuccess, useCache: true);
    }
  }
  
  /// Play feedback notification sound
  Future<void> playFeedbackNotificationSound() async {
    if (_feedbackSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.feedbackNotification);
    }
  }
  
  /// Release resources when app is closed
  void dispose() {
    if (_audioPlayer != null) {
      _audioPlayer!.dispose();
      _audioPlayer = null;
    }
    
    _disposeCachedPlayers();
  }
}

/// Static helper class for game sounds with function references
/// This provides a convenient way to pass sound functions as references
class GameSounds {
  static AudioPlayer? _audioPlayer;
  static bool _isSoundEnabled = true;
  static bool _isInitialized = false;
  static double _volume = 1.0; // Default volume (0.0 to 1.0)
  
  // Sound category muting - for fine-grained control
  static bool _uiSoundsEnabled = true;
  static bool _achievementSoundsEnabled = true;
  static bool _businessSoundsEnabled = true;
  static bool _investmentSoundsEnabled = true;
  static bool _realEstateSoundsEnabled = true;
  static bool _eventSoundsEnabled = true;
  static bool _feedbackSoundsEnabled = true;

  // Legacy sound function references for backward compatibility
  static Future<void> Function() get tap => playUiTap;
  static Future<void> Function() get purchase => playBusinessPurchase;
  static Future<void> Function() get success => playFeedbackSuccess;
  static Future<void> Function() get error => playFeedbackError;
  
  // NEW FUNCTION REFERENCES
  
  // UI sounds
  static Future<void> Function() get uiTap => playUiTap;
  static Future<void> Function() get uiTapBoosted => playUiTapBoosted;
  static Future<void> Function() get uiTabChange => playUiTabChange;
  
  // Achievement sounds
  static Future<void> Function() get achievementBasic => playAchievementBasic;
  static Future<void> Function() get achievementRare => playAchievementRare;
  static Future<void> Function() get achievementMilestone => playAchievementMilestone;
  
  // Business sounds
  static Future<void> Function() get businessPurchase => playBusinessPurchase;
  static Future<void> Function() get businessUpgrade => playBusinessUpgrade;
  static Future<void> Function() get businessMaxLevel => playBusinessMaxLevel;
  
  // Investment sounds
  static Future<void> Function() get investmentBuyStock => playInvestmentBuyStock;
  static Future<void> Function() get investmentSellStock => playInvestmentSellStock;
  static Future<void> Function() get investmentMarketEvent => playInvestmentMarketEvent;
  
  // Real estate sounds
  static Future<void> Function() get realEstatePurchase => playRealEstatePurchase;
  static Future<void> Function() get realEstateUpgrade => playRealEstateUpgrade;
  static Future<void> Function() get realEstateLocaleUnlock => playRealEstateLocaleUnlock;
  static Future<void> Function() get realEstateLocaleComplete => playRealEstateLocaleComplete;
  
  // Event sounds
  static Future<void> Function() get eventStartup => playEventStartup;
  static Future<void> Function() get eventReincorporation => playEventReincorporation;
  static Future<void> Function() get eventOfflineIncome => playEventOfflineIncome;
  static Future<void> Function() get eventSpecial => playEventSpecial;
  
  // Feedback sounds
  static Future<void> Function() get feedbackError => playFeedbackError;
  static Future<void> Function() get feedbackSuccess => playFeedbackSuccess;
  static Future<void> Function() get feedbackNotification => playFeedbackNotification;
  
  /// Initialize sound system
  static Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      print('🔄 GameSounds: Initializing...');
      
      // Initialize audio player for all platforms
      _initAudioPlayer();
      
      // Try to load sound settings from SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        _isSoundEnabled = prefs.getBool(SoundAssets.soundPrefsKey) ?? true;
        _volume = prefs.getDouble(SoundAssets.volumePrefsKey) ?? 1.0;
        
        // Ensure volume is in valid range
        _volume = _volume.clamp(0.0, 1.0);
        
        // Apply volume setting
        if (_audioPlayer != null) {
          _audioPlayer!.setVolume(_volume);
        }
      } catch (e) {
        // Fall back to default if can't load
        print('⚠️ GameSounds: Could not load sound settings: $e');
        _isSoundEnabled = true;
        _volume = 1.0;
      }
      
      _isInitialized = true;
      print('✅ GameSounds initialized successfully');
    } catch (e) {
      print('🔴 Error initializing GameSounds: $e');
      _isSoundEnabled = false;
    }
  }
  
  /// Initialize audio player instance
  static void _initAudioPlayer() {
    try {
      if (_audioPlayer == null) {
        _audioPlayer = AudioPlayer();
        _audioPlayer!.setVolume(_volume);
        print('✅ GameSounds: Audio player initialized with volume $_volume');
      }
    } catch (e) {
      print('🔴 Error initializing static audio player: $e');
      _isSoundEnabled = false;
    }
  }
  
  /// Sound enabled status getter
  static bool get isSoundEnabled => _isSoundEnabled;
  
  /// Sound enabled status setter
  static set isSoundEnabled(bool value) {
    _isSoundEnabled = value;
    
    // Create or dispose audio player as needed
    if (value) {
      _initAudioPlayer();
    } else if (!value && _audioPlayer != null) {
      _audioPlayer!.dispose();
      _audioPlayer = null;
    }
  }
  
  /// Volume getter
  static double get volume => _volume;
  
  /// Volume setter
  static set volume(double value) {
    // Ensure volume is within valid range
    value = value.clamp(0.0, 1.0);
    
    _volume = value;
    if (_audioPlayer != null) {
      _audioPlayer!.setVolume(value);
    }
  }
  
  /// Toggle specific sound category
  static void toggleSoundCategory(String category, bool enabled) {
    switch (category.toLowerCase()) {
      case 'ui':
        _uiSoundsEnabled = enabled;
        break;
      case 'achievement':
      case 'achievements':
        _achievementSoundsEnabled = enabled;
        break;
      case 'business':
        _businessSoundsEnabled = enabled;
        break;
      case 'investment':
        _investmentSoundsEnabled = enabled;
        break;
      case 'realestate':
      case 'real_estate':
        _realEstateSoundsEnabled = enabled;
        break;
      case 'event':
      case 'events':
        _eventSoundsEnabled = enabled;
        break;
      case 'feedback':
        _feedbackSoundsEnabled = enabled;
        break;
      default:
        print('⚠️ Unknown sound category: $category');
    }
  }
  
  // A pool of temporary players for rapid sound playback (like taps)
  static final Map<String, AudioPlayer> _soundPlayerPool = {};
  static const int _maxPoolSize = 5;

  /// Helper method to safely play sounds with error handling
  static Future<void> _safelyPlaySound(String soundPath) async {
    if (!_isSoundEnabled) return;
    
    try {
      // Special handling for tap sounds to prevent conflicts 
      // with rapid successive playback
      if (soundPath == SoundAssets.uiTap || soundPath == SoundAssets.uiTapBoosted) {
        try {
          // For tap sounds, use a pool of temporary players
          final tempPlayer = AudioPlayer();
          tempPlayer.setVolume(_volume);
          await tempPlayer.play(AssetSource(soundPath));
          
          // Set up auto-disposal after sound finishes playing
          tempPlayer.onPlayerComplete.listen((_) {
            tempPlayer.dispose();
          });
          
          // Manage pool size - keep it from growing too large
          if (_soundPlayerPool.length > _maxPoolSize) {
            try {
              final oldestKey = _soundPlayerPool.keys.first;
              final oldestPlayer = _soundPlayerPool.remove(oldestKey);
              await oldestPlayer?.dispose();
            } catch (e) {
              print('🔴 Error disposing oldest pooled player: $e');
            }
          }
          
          // Add to pool with timestamp as key
          _soundPlayerPool['${DateTime.now().millisecondsSinceEpoch}'] = tempPlayer;
          return;
        } catch (e) {
          print('🔴 Error with pooled tap sound player for $soundPath: $e');
          // Fall back to standard player
        }
      }
      
      // For non-tap sounds, use the standard player
      // Lazy initialize
      if (_audioPlayer == null) {
        _initAudioPlayer();
      }
      
      if (_audioPlayer != null) {
        await _audioPlayer!.stop(); // Stop any currently playing sound
        await _audioPlayer!.play(AssetSource(soundPath));
      }
    } catch (e) {
      print('🔴 Error playing sound $soundPath: $e');
      // Continue without crashing
    }
  }
  
  // UI SOUND METHODS
  
  /// Play UI tap sound
  static Future<void> playUiTap() async {
    if (!_isSoundEnabled || !_uiSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.uiTap);
  }
  
  /// Play UI boosted tap sound
  static Future<void> playUiTapBoosted() async {
    if (!_isSoundEnabled || !_uiSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.uiTapBoosted);
  }
  
  /// Play UI tab change sound
  static Future<void> playUiTabChange() async {
    if (!_isSoundEnabled || !_uiSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.uiTabChange);
  }
  
  // ACHIEVEMENT SOUND METHODS
  
  /// Play achievement basic sound
  static Future<void> playAchievementBasic() async {
    if (!_isSoundEnabled || !_achievementSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.achievementBasic);
  }
  
  /// Play achievement rare sound
  static Future<void> playAchievementRare() async {
    if (!_isSoundEnabled || !_achievementSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.achievementRare);
  }
  
  /// Play achievement milestone sound
  static Future<void> playAchievementMilestone() async {
    if (!_isSoundEnabled || !_achievementSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.achievementMilestone);
  }
  
  // BUSINESS SOUND METHODS
  
  /// Play business purchase sound
  static Future<void> playBusinessPurchase() async {
    if (!_isSoundEnabled || !_businessSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.businessPurchase);
  }
  
  /// Play business upgrade sound
  static Future<void> playBusinessUpgrade() async {
    if (!_isSoundEnabled || !_businessSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.businessUpgrade);
  }
  
  /// Play business max level sound
  static Future<void> playBusinessMaxLevel() async {
    if (!_isSoundEnabled || !_businessSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.businessMaxLevel);
  }
  
  // INVESTMENT SOUND METHODS
  
  /// Play investment buy stock sound
  static Future<void> playInvestmentBuyStock() async {
    if (!_isSoundEnabled || !_investmentSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.investmentBuyStock);
  }
  
  /// Play investment sell stock sound
  static Future<void> playInvestmentSellStock() async {
    if (!_isSoundEnabled || !_investmentSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.investmentSellStock);
  }
  
  /// Play investment market event sound
  static Future<void> playInvestmentMarketEvent() async {
    if (!_isSoundEnabled || !_investmentSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.investmentMarketEvent);
  }
  
  // REAL ESTATE SOUND METHODS
  
  /// Play real estate purchase sound
  static Future<void> playRealEstatePurchase() async {
    if (!_isSoundEnabled || !_realEstateSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.realEstatePurchase);
  }
  
  /// Play real estate locale unlock sound
  static Future<void> playRealEstateLocaleUnlock() async {
    if (!_isSoundEnabled || !_realEstateSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.realEstateLocaleUnlock);
  }
  
  /// Play real estate upgrade sound
  static Future<void> playRealEstateUpgrade() async {
    if (!_isSoundEnabled || !_realEstateSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.businessUpgrade); // Reuse business upgrade sound with proper pooling
  }
  
  /// Play real estate locale complete sound
  static Future<void> playRealEstateLocaleComplete() async {
    if (!_isSoundEnabled || !_realEstateSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.realEstateLocaleComplete);
  }
  
  // EVENT SOUND METHODS
  
  /// Play startup sound
  static Future<void> playEventStartup() async {
    if (!_isSoundEnabled || !_eventSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.eventStartup);
  }
  
  /// Play reincorporation sound
  static Future<void> playEventReincorporation() async {
    if (!_isSoundEnabled || !_eventSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.eventReincorporation);
  }
  
  /// Play offline income sound
  static Future<void> playEventOfflineIncome() async {
    if (!_isSoundEnabled || !_eventSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.eventOfflineIncome);
  }
  
  /// Play special event sound
  static Future<void> playEventSpecial() async {
    if (!_isSoundEnabled || !_eventSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.eventSpecial);
  }
  
  // FEEDBACK SOUND METHODS
  
  /// Play feedback error sound
  static Future<void> playFeedbackError() async {
    if (!_isSoundEnabled || !_feedbackSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.feedbackError);
  }
  
  /// Play feedback success sound
  static Future<void> playFeedbackSuccess() async {
    if (!_isSoundEnabled || !_feedbackSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.feedbackSuccess);
  }
  
  /// Play feedback notification sound
  static Future<void> playFeedbackNotification() async {
    if (!_isSoundEnabled || !_feedbackSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.feedbackNotification);
  }
  
  /// Release resources
  static void dispose() {
    try {
      // Dispose main audio player
      if (_audioPlayer != null) {
        _audioPlayer!.dispose();
        _audioPlayer = null;
      }
      
      // Dispose all pooled players
      for (final player in _soundPlayerPool.values) {
        try {
          player.dispose();
        } catch (e) {
          print('🔴 Error disposing pooled player: $e');
        }
      }
      _soundPlayerPool.clear();
      
      print('✅ GameSounds: All resources disposed');
    } catch (e) {
      print('🔴 Error disposing audio players: $e');
    }
  }
}
