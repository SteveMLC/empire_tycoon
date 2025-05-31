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
    // Unlock premium avatars
    isPremiumAvatarsUnlocked = true;
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
    
    // If no notification is currently displayed and no animation is in progress, show the next one
    if (!_isAchievementNotificationVisible && !_isAchievementAnimationInProgress) {
      _showNextAchievementNotification();
    }
  }

  // Show the next achievement notification
  void _showNextAchievementNotification() {
    if (_pendingAchievementNotifications.isEmpty) {
      _isAchievementNotificationVisible = false;
      _currentAchievementNotification = null;
      _isAchievementAnimationInProgress = false; // Reset animation flag
      notifyListeners();
      return;
    }
    
    // Set animation in progress flag
    _isAchievementAnimationInProgress = true;
    
    // Display the next achievement
    _currentAchievementNotification = _pendingAchievementNotifications.removeAt(0);
    _isAchievementNotificationVisible = true;
    print("🏆 Showing achievement: ${_currentAchievementNotification!.name}");
    notifyListeners();
    
    // Cancel any existing timer
    _achievementNotificationTimer?.cancel();
    
    // Set a timer to auto-dismiss the notification after 5 seconds
    // Note: This timer will be canceled if the user manually dismisses the notification
    _achievementNotificationTimer = Timer(const Duration(seconds: 5), () {
      print("⏱️ Auto-dismissing achievement: ${_currentAchievementNotification?.name}");
      _isAchievementNotificationVisible = false;
      _currentAchievementNotification = null;
      notifyListeners();
      
      // Wait for exit animation to complete before showing next notification
      // This delay should match the exit animation duration
      Timer(const Duration(milliseconds: 500), () {
        _isAchievementAnimationInProgress = false; // Reset animation flag
        
        // Check if there are more achievements to show
        if (_pendingAchievementNotifications.isNotEmpty) {
          _showNextAchievementNotification();
        }
      });
    });
  }
} 