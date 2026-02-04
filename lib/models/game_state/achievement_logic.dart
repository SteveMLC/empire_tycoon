part of '../game_state.dart';

// Removed incorrect imports
// import 'package:empire_tycoon/models/achievement.dart';
// import 'package:empire_tycoon/models/achievement_data.dart';

// Contains methods related to achievement checking and management.
extension AchievementLogic on GameState {
  // Check achievements based on the current game state

  /// Checks if a notification can be shown and triggers the display of the next one if conditions are met.
  void tryShowingNextAchievement() {
    // Can only show if nothing is currently visible and the queue is not empty
    // Also check that we're not in the middle of an animation transition
    if (!_isAchievementNotificationVisible && 
        !_isAchievementAnimationInProgress && 
        _pendingAchievementNotifications.isNotEmpty) {
      // Use the proper notification system from NotificationLogic
      _showNextAchievementNotification();
    }
  }

  /// Called when the currently displayed achievement notification is dismissed by the user or timer.
  void dismissCurrentAchievementNotification() {
    if (_currentAchievementNotification != null) {
       print("✅ Dismissed achievement notification: ${_currentAchievementNotification!.name}");
    }
    
    // Cancel any active auto-dismiss timer
    cancelScheduledTimer('achievementAutoDismiss');
    cancelScheduledTimer('achievementAnimationComplete');
    
    _currentAchievementNotification = null;
    _isAchievementNotificationVisible = false;
    notifyListeners(); // Notify UI to hide the notification

    // Reset animation flag after a short delay to ensure smooth transitions
    scheduleTimer('achievementAnimationComplete', const Duration(milliseconds: 500), () {
      _isAchievementAnimationInProgress = false;
      
      // Try showing the next achievement after the animation completes
      tryShowingNextAchievement();
    });
  }
  
  /// Called when an achievement animation has completed (entry or exit)
  void notifyAchievementAnimationCompleted() {
    _isAchievementAnimationInProgress = false;
    
    // If this was an exit animation and there are more achievements, show the next one
    if (!_isAchievementNotificationVisible && _pendingAchievementNotifications.isNotEmpty) {
      tryShowingNextAchievement();
    }
  }
}
