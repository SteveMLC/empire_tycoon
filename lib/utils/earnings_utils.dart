import '../models/game_state.dart';

/// Utility class to handle earnings updates to avoid extension conflicts
class EarningsUtils {
  /// Update hourly earnings in the game state
  static void updateHourlyEarnings(GameState gameState, String hourKey, double amount) {
    gameState.hourlyEarnings[hourKey] = (gameState.hourlyEarnings[hourKey] ?? 0) + amount;
    // Pruning is now done periodically or on load, not every update
  }
} 