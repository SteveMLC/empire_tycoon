part of '../game_state.dart';

// Contains methods related to platinum challenges and challenge management
extension ChallengeLogic on GameState {
  // Check the current active challenge in the update loop
  void _checkActiveChallenge(DateTime now) {
    if (activeChallenge == null) return;

    // Check for success FIRST, even if time hasn't expired
    if (activeChallenge!.wasSuccessful(totalEarned)) {
      // Award PP for successful challenge
      platinumPoints += activeChallenge!.rewardPP;
      showPPAnimation = true; // Trigger UI animation
      print("SUCCESS: Platinum Challenge completed! Awarded ${activeChallenge!.rewardPP} PP");
      
      // Create a temporary achievement-like notification for display
      Achievement challengeComplete = Achievement(
        id: 'temp_challenge_complete_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Challenge Completed!', 
        description: 'Successfully doubled your hourly income rate within the time limit!',
        icon: Icons.emoji_events,
        rarity: AchievementRarity.rare, // Use rare style for fancy display
        ppReward: activeChallenge!.rewardPP,
        category: AchievementCategory.progress, // Added category
      );
      
      // Queue the notification - sound will play through the achievement notification system
      queueAchievementsForDisplay([challengeComplete]);
      
      // Clear the completed challenge
      activeChallenge = null;
      notifyListeners();
      return; // Exit early since it's completed
    }

    // If not successful yet, check if the time has expired
    if (!activeChallenge!.isActive(now)) {
      print("FAILED: Platinum Challenge expired without reaching the goal.");
      // Clear the expired challenge
      activeChallenge = null;
      notifyListeners();
    }
  }

  // Method to manage platinum challenge daily limits
  void checkAndResetPlatinumChallengeLimit(DateTime now) {
    // If never used before, initialize
    if (lastPlatinumChallengeDayTracked == null) {
      lastPlatinumChallengeDayTracked = DateTime(now.year, now.month, now.day);
      platinumChallengeUsesToday = 0;
      return;
    }
    
    // Check if it's a new day
    DateTime currentDay = DateTime(now.year, now.month, now.day);
    if (currentDay.isAfter(lastPlatinumChallengeDayTracked!)) {
      // Reset the limit for the new day
      lastPlatinumChallengeDayTracked = currentDay;
      platinumChallengeUsesToday = 0;
      print("INFO: Platinum Challenge daily limit reset (0/2)");
    }
  }

  // Method to check platinum challenge eligibility
  bool canStartPlatinumChallenge(DateTime now) {
    checkAndResetPlatinumChallengeLimit(now);
    
    // Check if there's already an active challenge
    if (activeChallenge != null && activeChallenge!.isActive(now)) {
      print("DEBUG: Cannot start Platinum Challenge: Already active.");
      return false;
    }
    
    // Check if we've reached the daily limit (2x per day)
    if (platinumChallengeUsesToday >= 2) {
      print("DEBUG: Cannot start Platinum Challenge: Daily limit (2) reached.");
      return false;
    }
    
    return true;
  }
} 