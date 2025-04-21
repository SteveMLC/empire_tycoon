import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class SoundAssets {
  static const String soundPrefsKey = 'sound_enabled';
  static const String volumePrefsKey = 'sound_volume';

  static const String legacyTapSound = 'sounds/tap.mp3';
  static const String legacyPurchaseSound = 'sounds/purchase.mp3';
  static const String legacySuccessSound = 'sounds/success.mp3';
  static const String legacyErrorSound = 'sounds/error.mp3';
  
  static const String uiTap = 'sounds/ui/tap.mp3';
  static const String uiTapBoosted = 'sounds/ui/tap_boosted.mp3';
  static const String uiTabChange = 'sounds/ui/tap_change.mp3';
  
  static const String achievementBasic = 'sounds/achievements/achievement_basic.mp3';
  static const String achievementRare = 'sounds/achievements/achievement_rare.mp3';
  static const String achievementMilestone = 'sounds/achievements/achievement_milestone.mp3';
  
  static const String businessPurchase = 'sounds/business/purchase.mp3';
  static const String businessUpgrade = 'sounds/business/upgrade.mp3';
  static const String businessMaxLevel = 'sounds/business/max_level.mp3';
  
  static const String investmentBuyStock = 'sounds/investment/buy_stock.mp3';
  static const String investmentSellStock = 'sounds/investment/sell_stock.mp3';
  static const String investmentMarketEvent = 'sounds/investment/market_event.mp3';
  
  static const String realEstatePurchase = 'sounds/real_estate/property_purchase.mp3';
  static const String realEstateLocaleUnlock = 'sounds/real_estate/locale_unlock.mp3';
  static const String realEstateLocaleComplete = 'sounds/real_estate/locale_complete.mp3';
  
  static const String eventStartup = 'sounds/events/startup.mp3';
  static const String eventReincorporation = 'sounds/events/reincorporation.mp3';
  static const String eventOfflineIncome = 'sounds/events/offline_income.mp3';
  static const String eventSpecial = 'sounds/events/special_event.mp3';
  
  static const String feedbackError = 'sounds/feedback/error.mp3';
  static const String feedbackSuccess = 'sounds/feedback/success.mp3';
  static const String feedbackNotification = 'sounds/feedback/notification.mp3';
}

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();
  
  AudioPlayer? _audioPlayer;
  bool _soundEnabled = true;
  bool _isInitialized = false;
  double _volume = 1.0;
  
  bool _uiSoundsEnabled = true;
  bool _achievementSoundsEnabled = true;
  bool _businessSoundsEnabled = true;
  bool _investmentSoundsEnabled = true;
  bool _realEstateSoundsEnabled = true;
  bool _eventSoundsEnabled = true;
  bool _feedbackSoundsEnabled = true;
  
  final Map<String, AudioPlayer> _cachedPlayers = {};
  
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      print('🔄 SoundManager: Initializing...');
      
      await _loadSoundSettings();
      print('✅ SoundManager: Sound settings loaded, enabled: $_soundEnabled, volume: $_volume');
      
      if (_soundEnabled) {
        _initAudioPlayer();
      }
      
      GameSounds.isSoundEnabled = _soundEnabled;
      GameSounds.volume = _volume;
      
      _isInitialized = true;
    } catch (e, stackTrace) {
      print('🔴 SoundManager initialization error: $e');
      print('🔴 Stack trace: $stackTrace');
      _soundEnabled = false;
    }
  }
  
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
  
  Future<void> _loadSoundSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool(SoundAssets.soundPrefsKey) ?? true;
      _volume = prefs.getDouble(SoundAssets.volumePrefsKey) ?? 1.0;
      
      _volume = _volume.clamp(0.0, 1.0);
    } catch (e) {
      print('🔴 Error loading sound settings: $e');
    }
  }
  
  Future<void> _saveSoundSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(SoundAssets.soundPrefsKey, _soundEnabled);
      await prefs.setDouble(SoundAssets.volumePrefsKey, _volume);
    } catch (e) {
      print('🔴 Error saving sound settings: $e');
    }
  }
  
  void toggleSound(bool enabled) {
    _soundEnabled = enabled;
    GameSounds.isSoundEnabled = enabled;
    
    _saveSoundSettings();
    
    if (enabled) {
      _initAudioPlayer();
    } else if (!enabled && _audioPlayer != null) {
      _audioPlayer!.dispose();
      _audioPlayer = null;
      
      _disposeCachedPlayers();
    }
    
    print('🔊 Sound ${enabled ? 'enabled' : 'disabled'}');
  }
  
  void setVolume(double volume) {
    volume = volume.clamp(0.0, 1.0);
    
    _volume = volume;
    GameSounds.volume = volume;
    
    if (_audioPlayer != null) {
      _audioPlayer!.setVolume(volume);
    }
    
    for (var player in _cachedPlayers.values) {
      player.setVolume(volume);
    }
    
    _saveSoundSettings();
    print('🔊 Volume set to $_volume');
  }
  
  bool isSoundEnabled() => _soundEnabled;
  
  double getVolume() => _volume;
  
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
        return true;
    }
  }
  
  Future<void> _safelyPlaySound(String soundPath, {bool useCache = false}) async {
    if (!_soundEnabled) return;
    
    try {
      if (useCache) {
        if (!_cachedPlayers.containsKey(soundPath)) {
          try {
            final player = AudioPlayer();
            player.setVolume(_volume);
            _cachedPlayers[soundPath] = player;
          } catch (e) {
            print('🔴 Error creating cached player for $soundPath: $e');
            useCache = false;
          }
        }
        
        if (useCache && _cachedPlayers.containsKey(soundPath)) {
          if (soundPath == SoundAssets.uiTap || soundPath == SoundAssets.uiTapBoosted) {
            try {
              if (_cachedPlayers[soundPath]!.state == PlayerState.playing) {
                final tempPlayer = AudioPlayer();
                tempPlayer.setVolume(_volume);
                await tempPlayer.play(AssetSource(soundPath));
                
                tempPlayer.onPlayerComplete.listen((_) {
                  tempPlayer.dispose();
                });
                return;
              } else {
                await _cachedPlayers[soundPath]!.play(AssetSource(soundPath));
                return;
              }
            } catch (e) {
              print('🔴 Error with pooled tap sound player for $soundPath: $e');
            }
          } else {
            await _cachedPlayers[soundPath]!.stop();
            await _cachedPlayers[soundPath]!.play(AssetSource(soundPath));
            return;
          }
        }
      }
      
      if (_audioPlayer == null) {
        _initAudioPlayer();
      }
      
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
        await _audioPlayer!.play(AssetSource(soundPath));
      }
    } catch (e) {
      print('🔴 Error playing sound $soundPath: $e');
    }
  }
  
  void _disposeCachedPlayers() {
    for (var player in _cachedPlayers.values) {
      player.dispose();
    }
    _cachedPlayers.clear();
  }
  
  Future<void> playTapSound() async {
    if (_uiSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.uiTap);
    }
  }
  
  Future<void> playPurchaseSound() async {
    if (_businessSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.businessPurchase);
    }
  }
  
  Future<void> playSuccessSound() async {
    if (_feedbackSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.feedbackSuccess);
    }
  }
  
  Future<void> playErrorSound() async {
    if (_feedbackSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.feedbackError);
    }
  }
  
  Future<void> playUiTapSound() async {
    if (_uiSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.uiTap, useCache: true);
    }
  }
  
  Future<void> playUiTapBoostedSound() async {
    if (_uiSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.uiTapBoosted, useCache: true);
    }
  }
  
  Future<void> playUiTabChangeSound() async {
    if (_uiSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.uiTabChange, useCache: true);
    }
  }
  
  Future<void> playAchievementBasicSound() async {
    if (_achievementSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.achievementBasic);
    }
  }
  
  Future<void> playAchievementRareSound() async {
    if (_achievementSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.achievementRare);
    }
  }
  
  Future<void> playAchievementMilestoneSound() async {
    if (_achievementSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.achievementMilestone);
    }
  }
  
  Future<void> playBusinessPurchaseSound() async {
    if (_businessSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.businessPurchase);
    }
  }
  
  Future<void> playBusinessUpgradeSound() async {
    if (_businessSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.businessUpgrade, useCache: true);
    }
  }
  
  Future<void> playBusinessMaxLevelSound() async {
    if (_businessSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.businessMaxLevel);
    }
  }
  
  Future<void> playInvestmentBuyStockSound() async {
    if (_investmentSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.investmentBuyStock);
    }
  }
  
  Future<void> playInvestmentSellStockSound() async {
    if (_investmentSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.investmentSellStock);
    }
  }
  
  Future<void> playInvestmentMarketEventSound() async {
    if (_investmentSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.investmentMarketEvent);
    }
  }
  
  Future<void> playRealEstatePurchaseSound() async {
    if (_realEstateSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.realEstatePurchase);
    }
  }
  
  Future<void> playRealEstateUpgradeSound() async {
    if (_realEstateSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.businessUpgrade, useCache: true);
    }
  }
  
  Future<void> playRealEstateLocaleUnlockSound() async {
    if (_realEstateSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.realEstateLocaleUnlock);
    }
  }
  
  Future<void> playRealEstateLocaleCompleteSound() async {
    if (_realEstateSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.realEstateLocaleComplete);
    }
  }
  
  Future<void> playEventStartupSound() async {
    if (_eventSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.eventStartup);
    }
  }
  
  Future<void> playEventReincorporationSound() async {
    if (_eventSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.eventReincorporation);
    }
  }
  
  Future<void> playEventOfflineIncomeSound() async {
    if (_eventSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.eventOfflineIncome);
    }
  }
  
  Future<void> playEventSpecialSound() async {
    if (_eventSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.eventSpecial);
    }
  }
  
  Future<void> playFeedbackErrorSound() async {
    if (_feedbackSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.feedbackError, useCache: true);
    }
  }
  
  Future<void> playFeedbackSuccessSound() async {
    if (_feedbackSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.feedbackSuccess, useCache: true);
    }
  }
  
  Future<void> playFeedbackNotificationSound() async {
    if (_feedbackSoundsEnabled) {
      await _safelyPlaySound(SoundAssets.feedbackNotification);
    }
  }
  
  void dispose() {
    if (_audioPlayer != null) {
      _audioPlayer!.dispose();
      _audioPlayer = null;
    }
    
    _disposeCachedPlayers();
  }

  // ADDED: Sound for Premium Purchase
  void playPremiumPurchaseSound() {
    if (_eventSoundsEnabled) { // Group with event sounds for now
      _safelyPlaySound(SoundAssets.achievementMilestone); // Use the milestone sound as requested
    }
  }
}

class GameSounds {
  static AudioPlayer? _audioPlayer;
  static bool _isSoundEnabled = true;
  static bool _isInitialized = false;
  static double _volume = 1.0;
  
  static bool _uiSoundsEnabled = true;
  static bool _achievementSoundsEnabled = true;
  static bool _businessSoundsEnabled = true;
  static bool _investmentSoundsEnabled = true;
  static bool _realEstateSoundsEnabled = true;
  static bool _eventSoundsEnabled = true;
  static bool _feedbackSoundsEnabled = true;

  static Future<void> Function() get tap => playUiTap;
  static Future<void> Function() get purchase => playBusinessPurchase;
  static Future<void> Function() get success => playFeedbackSuccess;
  static Future<void> Function() get error => playFeedbackError;
  
  static Future<void> Function() get uiTap => playUiTap;
  static Future<void> Function() get uiTapBoosted => playUiTapBoosted;
  static Future<void> Function() get uiTabChange => playUiTabChange;
  
  static Future<void> Function() get achievementBasic => playAchievementBasic;
  static Future<void> Function() get achievementRare => playAchievementRare;
  static Future<void> Function() get achievementMilestone => playAchievementMilestone;
  
  static Future<void> Function() get businessPurchase => playBusinessPurchase;
  static Future<void> Function() get businessUpgrade => playBusinessUpgrade;
  static Future<void> Function() get businessMaxLevel => playBusinessMaxLevel;
  
  static Future<void> Function() get investmentBuyStock => playInvestmentBuyStock;
  static Future<void> Function() get investmentSellStock => playInvestmentSellStock;
  static Future<void> Function() get investmentMarketEvent => playInvestmentMarketEvent;
  
  static Future<void> Function() get realEstatePurchase => playRealEstatePurchase;
  static Future<void> Function() get realEstateUpgrade => playRealEstateUpgrade;
  static Future<void> Function() get realEstateLocaleUnlock => playRealEstateLocaleUnlock;
  static Future<void> Function() get realEstateLocaleComplete => playRealEstateLocaleComplete;
  
  static Future<void> Function() get eventStartup => playEventStartup;
  static Future<void> Function() get eventReincorporation => playEventReincorporation;
  static Future<void> Function() get eventOfflineIncome => playEventOfflineIncome;
  static Future<void> Function() get eventSpecial => playEventSpecial;
  
  static Future<void> Function() get feedbackError => playFeedbackError;
  static Future<void> Function() get feedbackSuccess => playFeedbackSuccess;
  static Future<void> Function() get feedbackNotification => playFeedbackNotification;
  
  static Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      print('🔄 GameSounds: Initializing...');
      
      _initAudioPlayer();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        _isSoundEnabled = prefs.getBool(SoundAssets.soundPrefsKey) ?? true;
        _volume = prefs.getDouble(SoundAssets.volumePrefsKey) ?? 1.0;
        
        _volume = _volume.clamp(0.0, 1.0);
        
        if (_audioPlayer != null) {
          _audioPlayer!.setVolume(_volume);
        }
      } catch (e) {
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
  
  static bool get isSoundEnabled => _isSoundEnabled;
  
  static set isSoundEnabled(bool value) {
    _isSoundEnabled = value;
    
    if (value) {
      _initAudioPlayer();
    } else if (!value && _audioPlayer != null) {
      _audioPlayer!.dispose();
      _audioPlayer = null;
    }
  }
  
  static double get volume => _volume;
  
  static set volume(double value) {
    value = value.clamp(0.0, 1.0);
    
    _volume = value;
    if (_audioPlayer != null) {
      _audioPlayer!.setVolume(value);
    }
  }
  
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
  
  static final Map<String, AudioPlayer> _soundPlayerPool = {};
  static const int _maxPoolSize = 5;

  static Future<void> _safelyPlaySound(String soundPath) async {
    if (!_isSoundEnabled) return;
    
    try {
      if (soundPath == SoundAssets.uiTap || soundPath == SoundAssets.uiTapBoosted) {
        try {
          final tempPlayer = AudioPlayer();
          tempPlayer.setVolume(_volume);
          await tempPlayer.play(AssetSource(soundPath));
          
          tempPlayer.onPlayerComplete.listen((_) {
            tempPlayer.dispose();
          });
          
          if (_soundPlayerPool.length > _maxPoolSize) {
            try {
              final oldestKey = _soundPlayerPool.keys.first;
              final oldestPlayer = _soundPlayerPool.remove(oldestKey);
              await oldestPlayer?.dispose();
            } catch (e) {
              print('🔴 Error disposing oldest pooled player: $e');
            }
          }
          
          _soundPlayerPool['${DateTime.now().millisecondsSinceEpoch}'] = tempPlayer;
          return;
        } catch (e) {
          print('🔴 Error with pooled tap sound player for $soundPath: $e');
        }
      }
      
      if (_audioPlayer == null) {
        _initAudioPlayer();
      }
      
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
        await _audioPlayer!.play(AssetSource(soundPath));
      }
    } catch (e) {
      print('🔴 Error playing sound $soundPath: $e');
    }
  }
  
  static Future<void> playUiTap() async {
    if (!_isSoundEnabled || !_uiSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.uiTap);
  }
  
  static Future<void> playUiTapBoosted() async {
    if (!_isSoundEnabled || !_uiSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.uiTapBoosted);
  }
  
  static Future<void> playUiTabChange() async {
    if (!_isSoundEnabled || !_uiSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.uiTabChange);
  }
  
  static Future<void> playAchievementBasic() async {
    if (!_isSoundEnabled || !_achievementSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.achievementBasic);
  }
  
  static Future<void> playAchievementRare() async {
    if (!_isSoundEnabled || !_achievementSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.achievementRare);
  }
  
  static Future<void> playAchievementMilestone() async {
    if (!_isSoundEnabled || !_achievementSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.achievementMilestone);
  }
  
  static Future<void> playBusinessPurchase() async {
    if (!_isSoundEnabled || !_businessSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.businessPurchase);
  }
  
  static Future<void> playBusinessUpgrade() async {
    if (!_isSoundEnabled || !_businessSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.businessUpgrade);
  }
  
  static Future<void> playBusinessMaxLevel() async {
    if (!_isSoundEnabled || !_businessSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.businessMaxLevel);
  }
  
  static Future<void> playInvestmentBuyStock() async {
    if (!_isSoundEnabled || !_investmentSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.investmentBuyStock);
  }
  
  static Future<void> playInvestmentSellStock() async {
    if (!_isSoundEnabled || !_investmentSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.investmentSellStock);
  }
  
  static Future<void> playInvestmentMarketEvent() async {
    if (!_isSoundEnabled || !_investmentSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.investmentMarketEvent);
  }
  
  static Future<void> playRealEstatePurchase() async {
    if (!_isSoundEnabled || !_realEstateSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.realEstatePurchase);
  }
  
  static Future<void> playRealEstateLocaleUnlock() async {
    if (!_isSoundEnabled || !_realEstateSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.realEstateLocaleUnlock);
  }
  
  static Future<void> playRealEstateUpgrade() async {
    if (!_isSoundEnabled || !_realEstateSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.businessUpgrade);
  }
  
  static Future<void> playRealEstateLocaleComplete() async {
    if (!_isSoundEnabled || !_realEstateSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.realEstateLocaleComplete);
  }
  
  static Future<void> playEventStartup() async {
    if (!_isSoundEnabled || !_eventSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.eventStartup);
  }
  
  static Future<void> playEventReincorporation() async {
    if (!_isSoundEnabled || !_eventSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.eventReincorporation);
  }
  
  static Future<void> playEventOfflineIncome() async {
    if (!_isSoundEnabled || !_eventSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.eventOfflineIncome);
  }
  
  static Future<void> playEventSpecial() async {
    if (!_isSoundEnabled || !_eventSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.eventSpecial);
  }
  
  static Future<void> playFeedbackError() async {
    if (!_isSoundEnabled || !_feedbackSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.feedbackError);
  }
  
  static Future<void> playFeedbackSuccess() async {
    if (!_isSoundEnabled || !_feedbackSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.feedbackSuccess);
  }
  
  static Future<void> playFeedbackNotification() async {
    if (!_isSoundEnabled || !_feedbackSoundsEnabled) return;
    await _safelyPlaySound(SoundAssets.feedbackNotification);
  }
  
  static void dispose() {
    try {
      if (_audioPlayer != null) {
        _audioPlayer!.dispose();
        _audioPlayer = null;
      }
      
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