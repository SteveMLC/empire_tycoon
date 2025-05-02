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
    if (!_isAchievementNotificationVisible && _pendingAchievementNotifications.isNotEmpty) {
      _showNextPendingAchievement();
    }
  }

  /// Internal method to display the next achievement from the queue.
  void _showNextPendingAchievement() {
    if (_pendingAchievementNotifications.isEmpty) return; // Safety check

    _currentAchievementNotification = _pendingAchievementNotifications.removeAt(0);
    _isAchievementNotificationVisible = true;
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

    // Important: Immediately try to show the next one after dismissal
    // Use a short delay to prevent immediate re-triggering if dismissal was rapid
    Future.delayed(Duration(milliseconds: 100), () {
       tryShowingNextAchievement();
    });
  }
} 