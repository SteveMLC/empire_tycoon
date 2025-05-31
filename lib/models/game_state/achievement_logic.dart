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
      _showNextPendingAchievement();
    }
  }

  /// Internal method to display the next achievement from the queue.
  void _showNextPendingAchievement() {
    if (_pendingAchievementNotifications.isEmpty) return; // Safety check

    _currentAchievementNotification = _pendingAchievementNotifications.removeAt(0);
    _isAchievementNotificationVisible = true;
    _isAchievementAnimationInProgress = true; // Set animation in progress flag
    print("🔔 Displaying achievement: ${_currentAchievementNotification!.name}");
    notifyListeners(); // Notify UI to show the current achievement
  }

  /// Called when the currently displayed achievement notification is dismissed by the user or timer.
  void dismissCurrentAchievementNotification() {
    if (_currentAchievementNotification != null) {
       print("✅ Dismissed achievement notification: ${_currentAchievementNotification!.name}");
    }
    _currentAchievementNotification = null;
    _isAchievementNotificationVisible = false;
    notifyListeners(); // Notify UI to hide the notification

    // Reset animation flag after a short delay to ensure smooth transitions
    Future.delayed(Duration(milliseconds: 300), () {
      _isAchievementAnimationInProgress = false;
      
      // Try showing the next achievement after the animation completes
      tryShowingNextAchievement();
    });
  }
  
  /// Called when an achievement animation has completed (entry or exit)
  void notifyAchievementAnimationCompleted() {
    _isAchievementAnimationInProgress = false;
  }
}