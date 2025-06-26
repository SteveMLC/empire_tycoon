import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/game_state.dart';
import '../../models/event.dart';
import '../../services/game_service.dart';
import '../achievement_notification.dart';
import '../event_notification.dart';
import '../challenge_notification.dart';
import '../premium_purchase_notification.dart';
import '../offline_income_notification.dart';

/// Notification section for displaying achievements, events, and challenges
class NotificationSection extends StatelessWidget {
  const NotificationSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _hasActiveNotifications(gameState) ? null : 0,
      // Only set clipBehavior when there are notifications
      clipBehavior: _hasActiveNotifications(gameState) ? Clip.antiAlias : Clip.none,
      decoration: _hasActiveNotifications(gameState) ? BoxDecoration(
        gradient: gameState.isPlatinumFrameActive 
          ? LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF2E2A5A).withOpacity(0.95),  // Rich royal blue
                const Color(0xFF2E2A5A).withOpacity(0.85),
              ],
            )
          : LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.85),
              ],
            ),
        boxShadow: [
          BoxShadow(
            color: gameState.isPlatinumFrameActive
              ? const Color(0xFFFFD700).withOpacity(0.2)
              : Colors.black.withOpacity(0.05),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: gameState.isPlatinumFrameActive
              ? const Color(0xFFFFD700).withOpacity(0.3)
              : Colors.grey.shade300,
            width: gameState.isPlatinumFrameActive ? 1.0 : 0.5,
          ),
        ),
      ) : null,
      // Add padding when there are notifications to display
      padding: EdgeInsets.only(
        top: _hasActiveNotifications(gameState) ? 8.0 : 0,
        bottom: _hasActiveNotifications(gameState) ? 8.0 : 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAchievementNotifications(gameState, context),
          _buildChallengeNotification(gameState),
          _buildOfflineIncomeNotification(gameState),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _buildPremiumNotification(gameState),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAchievementNotifications(GameState gameState, BuildContext context) {
    // Check if there is a current achievement notification to display
    if (gameState.currentAchievementNotification == null) {
      return const SizedBox.shrink(); // Return an empty, zero-sized box
    }
    
    // Use the current achievement from GameState
    final achievement = gameState.currentAchievementNotification!;
    
    return AchievementNotification(
      achievement: achievement,
      gameService: Provider.of<GameService>(context, listen: false),
      // Use the dismiss method from GameState
      onDismiss: () {
        // No need to call setState here as GameState's notifyListeners will handle the rebuild
        gameState.dismissCurrentAchievementNotification();
      },
      // Add animation completion callback
      onAnimationComplete: () {
        // Notify GameState when animation completes
        gameState.notifyAchievementAnimationCompleted();
      },
    );
  }
  

  
  Widget _buildChallengeNotification(GameState gameState) {
    // If no active challenge, return empty widget
    if (gameState.activeChallenge == null) {
      return const SizedBox();
    }
    
    return ChallengeNotification(
      challenge: gameState.activeChallenge!,
      gameState: gameState,
    );
  }

  Widget _buildOfflineIncomeNotification(GameState gameState) {
    // If no offline income to show, return empty widget
    if (!gameState.showOfflineIncomeNotification) {
      return const SizedBox();
    }
    
    return const OfflineIncomeNotification();
  }
  
  Widget _buildPremiumNotification(GameState gameState) {
    if (!gameState.showPremiumPurchaseNotification) {
      return const SizedBox.shrink(); // Return empty if flag is false
    }

    // Return the actual notification widget
    return PremiumPurchaseNotification(
      onDismiss: gameState.dismissPremiumPurchaseNotification, // Pass dismiss callback
    );
  }
  
  // Helper method to check if there are any active notifications
  bool _hasActiveNotifications(GameState gameState) {
    return gameState.currentAchievementNotification != null || 
           gameState.activeChallenge != null ||
           gameState.showPremiumPurchaseNotification ||
           gameState.showOfflineIncomeNotification;
  }
} 