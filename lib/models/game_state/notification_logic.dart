part of '../game_state.dart';

extension NotificationLogic on GameState {
  // Method to dismiss premium purchase notification
  void dismissPremiumPurchaseNotification() {
    showPremiumPurchaseNotification = false;
    notifyListeners();
  }

  // Method to enable premium features
  void enablePremium() {
    if (isPremium) return; // Already premium
    
    isPremium = true;
    // Award bonus platinum points
    platinumPoints += 1500;
    // Show premium purchase notification
    showPremiumPurchaseNotification = true;
    
    // After short delay, hide notification
    Timer(const Duration(seconds: 5), () {
      showPremiumPurchaseNotification = false;
      notifyListeners();
    });
    
    notifyListeners();
  }

  // Function to select a stats theme
  void selectStatsTheme(String? theme) {
    print("DEBUG: Selecting stats theme: $theme, Current unlock status: isExecutiveStatsThemeUnlocked=$isExecutiveStatsThemeUnlocked");
    if (theme == null || theme == 'default' || (theme == 'executive' && isExecutiveStatsThemeUnlocked)) {
      selectedStatsTheme = theme;
      notifyListeners();
    }
  }

  // Toggle platinum frame
  void togglePlatinumFrame(bool isActive) {
    // Only toggle if unlocked
    if (isPlatinumFrameUnlocked) {
      isPlatinumFrameActive = isActive;
      notifyListeners();
    }
  }

  // Queue achievements for display
  void queueAchievementsForDisplay(List<Achievement> achievements) {
    if (achievements.isEmpty) return;
    
    _pendingAchievementNotifications.addAll(achievements);
    
    // If no notification is currently displayed, show the next one
    if (!_isAchievementNotificationVisible) {
      _showNextAchievementNotification();
    }
  }

  // Show the next achievement notification
  void _showNextAchievementNotification() {
    if (_pendingAchievementNotifications.isEmpty) {
      _isAchievementNotificationVisible = false;
      _currentAchievementNotification = null;
      notifyListeners();
      return;
    }
    
    _currentAchievementNotification = _pendingAchievementNotifications.removeAt(0);
    _isAchievementNotificationVisible = true;
    notifyListeners();
    
    // Hide after a delay
    _achievementNotificationTimer?.cancel();
    _achievementNotificationTimer = Timer(const Duration(seconds: 5), () {
      _isAchievementNotificationVisible = false;
      notifyListeners();
      
      // Show next notification after a short pause
      Timer(const Duration(milliseconds: 500), () {
        _showNextAchievementNotification();
      });
    });
  }
} 