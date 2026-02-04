import '../../utils/sounds.dart';
import '../../utils/sound_manager.dart';
import '../../utils/sound_assets.dart'; // Added for direct access to sound asset paths

/// Sound management component for GameService
class SoundService {
  final SoundManager _soundManager = SoundManager();
  
  SoundService();
  
  Future<void> init() async {
    try {
      await _soundManager.init();
      print("🔊 Sound systems initialized successfully");
    } catch (e) {
      print("⚠️ Non-critical error initializing sound: $e");
    }
  }
  
  void playSound(Future<void> Function() soundFunction) {
    try {
      soundFunction();
    } catch (e) {
      print("🔊 Error playing sound: $e");
      // Don't throw further - sound errors should not affect gameplay
    }
  }
  
  void playBusinessSound() {
    _soundManager.playBusinessUpgradeSound();
  }

  void playInvestmentSound() {
    _soundManager.playInvestmentMarketEventSound();
  }

  void playRealEstateSound() {
    _soundManager.playRealEstatePurchaseSound();
  }

  void playTapSound() {
    _soundManager.playTapSound();
  }

  void playBoostedTapSound() {
    _soundManager.playUiTapBoostedSound();
  }

  void playAchievementSound() {
    _soundManager.playAchievementBasicSound();
  }

  void playEventSound() {
    _soundManager.playEventSpecialSound();
  }

  void playOfflineIncomeSound() {
    _soundManager.playOfflineIncomeSound();
  }

  void playOfflineIncomeCollectSound() {
    _soundManager.playOfflineIncomeCollectSound();
  }

  void playOfflineIncomeBonusSound() {
    _soundManager.playOfflineIncomeBonusSound();
  }

  void playFeedbackSound() {
    _soundManager.playFeedbackNotificationSound();
  }
  
  // Additional sound methods needed for direct access in the codebase
  void playPlatinumPurchaseSound() {
    _soundManager.playPlatinumPurchaseSound();
  }
  
  void playBusinessPurchaseSound() {
    _soundManager.playBusinessPurchaseSound();
  }
  
  void playAchievementMilestoneSound() {
    _soundManager.playAchievementMilestoneSound();
  }
  
  void playAchievementRareSound() {
    _soundManager.playAchievementRareSound();
  }
  
  void playFeedbackSuccessSound() {
    _soundManager.playFeedbackSuccessSound();
  }
  
  void playFeedbackErrorSound() {
    _soundManager.playFeedbackErrorSound();
  }
  
  void playInvestmentBuyStockSound() {
    _soundManager.playInvestmentBuyStockSound();
  }
  
  void playInvestmentSellStockSound() {
    _soundManager.playInvestmentSellStockSound();
  }
  
  // Direct sound asset playing method
  Future<void> playSoundAsset(String path, {bool useCache = true, SoundPriority priority = SoundPriority.normal}) async {
    return _soundManager.playSound(path, useCache: useCache, priority: priority);
  }
  
  // Expose sound manager for direct access when needed
  SoundManager get soundManager => _soundManager;
  
  // Add method to stop all sounds (useful for app lifecycle management)
  void stopAllSounds() {
    _soundManager.stopAllSounds();
  }
  
  // Add method to check if sounds are enabled
  bool get isSoundEnabled => _soundManager.isSoundEnabled;
  
  void dispose() {
    _soundManager.dispose();
  }
}
