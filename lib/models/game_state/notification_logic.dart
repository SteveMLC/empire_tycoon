part of '../game_state.dart';

extension NotificationLogic on GameState {
  // Method to dismiss premium purchase notification
  void dismissPremiumPurchaseNotification() {
    showPremiumPurchaseNotification = false;
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
    
    print("📬 Queuing ${achievements.length} achievements for display");
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
    
    // Set animation in progress flag to prevent overlap
    _isAchievementAnimationInProgress = true;
    
    // Display the next achievement
    _currentAchievementNotification = _pendingAchievementNotifications.removeAt(0);
    _isAchievementNotificationVisible = true;
    print("🏆 Showing achievement: ${_currentAchievementNotification!.name} (${_pendingAchievementNotifications.length} remaining in queue)");
    notifyListeners();
    
    // Cancel any existing timer
    _achievementNotificationTimer?.cancel();
    
    // Set a timer to auto-dismiss the notification after 5 seconds (reduced from 6)
    // This serves as a fallback in case animation completion doesn't trigger properly
    _achievementNotificationTimer = Timer(const Duration(seconds: 5), () {
      print("⏱️ Auto-dismissing achievement: ${_currentAchievementNotification?.name}");
      
      // Don't auto-dismiss if user is interacting (we'll keep this simple for now)
      _isAchievementNotificationVisible = false;
      _currentAchievementNotification = null;
      notifyListeners();
      
      // Wait for exit animation to complete before showing next notification
      // Increased delay to ensure smooth transitions and prevent overlap
      Timer(const Duration(milliseconds: 800), () {
        _isAchievementAnimationInProgress = false; // Reset animation flag
        
        print("🎬 Achievement animation complete, checking for next in queue...");
        
        // Check if there are more achievements to show
        if (_pendingAchievementNotifications.isNotEmpty) {
          print("📋 Showing next achievement from queue (${_pendingAchievementNotifications.length} remaining)");
          _showNextAchievementNotification();
        } else {
          print("📭 Achievement queue is now empty");
        }
      });
    });
  }
} 