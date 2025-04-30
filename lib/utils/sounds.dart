import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:collection';
import 'dart:async';
import 'sound_manager.dart';
import 'sound_assets.dart';

// Re-export the new sound manager and assets
export 'sound_manager.dart';
export 'sound_assets.dart';

// Legacy SoundAssets class for backward compatibility
class LegacySoundAssets {
  static const String soundPrefsKey = 'sound_enabled';
  static const String volumePrefsKey = 'sound_volume';

  static const String legacyTapSound = 'sounds/ui/tap.mp3';
  static const String legacyPurchaseSound = 'sounds/business/purchase.mp3';
  static const String legacySuccessSound = 'sounds/feedback/success.mp3';
  static const String legacyErrorSound = 'sounds/feedback/error.mp3';
  
  static const String uiTap = SoundAssets.uiTap;
  static const String uiTapBoosted = SoundAssets.uiTapBoosted;
  static const String uiTabChange = SoundAssets.uiTabChange;
  
  static const String achievementBasic = SoundAssets.achievementBasic;
  static const String achievementRare = SoundAssets.achievementRare;
  static const String achievementMilestone = SoundAssets.achievementMilestone;
  
  static const String businessPurchase = SoundAssets.businessPurchase;
  static const String businessUpgrade = SoundAssets.businessUpgrade;
  static const String businessMaxLevel = SoundAssets.businessMaxLevel;
  
  static const String investmentBuyStock = SoundAssets.investmentBuyStock;
  static const String investmentSellStock = SoundAssets.investmentSellStock;
  static const String investmentMarketEvent = SoundAssets.investmentMarketEvent;
  
  static const String realEstatePurchase = SoundAssets.realEstatePurchase;
  static const String realEstateLocaleUnlock = SoundAssets.realEstateLocaleUnlock;
  static const String realEstateLocaleComplete = SoundAssets.realEstateLocaleComplete;
  
  static const String eventStartup = SoundAssets.eventStartup;
  static const String eventReincorporation = SoundAssets.eventReincorporation;
  static const String eventOfflineIncome = SoundAssets.eventOfflineIncome;
  static const String eventSpecial = SoundAssets.eventSpecial;
  
  static const String feedbackError = SoundAssets.feedbackError;
  static const String feedbackSuccess = SoundAssets.feedbackSuccess;
  static const String feedbackNotification = SoundAssets.feedbackNotification;
  
  static const String platinumPurchase = SoundAssets.platinumPurchase;
}

// Legacy GameSounds class for backward compatibility
class GameSounds {
  static final SoundManager _soundManager = SoundManager();
  
  static Future<void> init() async {
    await _soundManager.init();
        }
  
  static bool get isSoundEnabled => _soundManager.isSoundEnabled;
  static set isSoundEnabled(bool value) => _soundManager.setSoundEnabled(value);
  
  static double get volume => _soundManager.soundVolume;
  static set volume(double value) => _soundManager.setSoundVolume(value);
  
  static void toggleSoundCategory(String category, bool enabled) {
    switch (category.toLowerCase()) {
      case 'ui':
        _soundManager.setUiSoundsEnabled(enabled);
        break;
      case 'achievement':
      case 'achievements':
        _soundManager.setAchievementSoundsEnabled(enabled);
        break;
      case 'business':
        _soundManager.setBusinessSoundsEnabled(enabled);
        break;
      case 'investment':
        _soundManager.setInvestmentSoundsEnabled(enabled);
        break;
      case 'realestate':
      case 'real_estate':
        _soundManager.setRealEstateSoundsEnabled(enabled);
        break;
      case 'event':
      case 'events':
        _soundManager.setEventSoundsEnabled(enabled);
        break;
      case 'feedback':
        _soundManager.setFeedbackSoundsEnabled(enabled);
        break;
      default:
        debugPrint('⚠️ Unknown sound category: $category');
    }
  }
  
  static void dispose() {
    debugPrint("GameSounds dispose called, but SoundManager disposal is handled elsewhere.");
  }
}