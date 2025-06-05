import '../../models/game_state.dart';
import '../../services/income_service.dart';

/// Helper class for income calculations - now delegates to IncomeService
class IncomeCalculator {
  final IncomeService _incomeService;
  
  IncomeCalculator(this._incomeService);
  
  /// Calculate total income per second for display purposes
  double calculateIncomePerSecond(GameState gameState) {
    return _incomeService.calculateIncomePerSecond(gameState);
  }

  /// Format remaining boost time for display
  String formatBoostTimeRemaining(Duration remaining) {
    return _incomeService.formatBoostTimeRemaining(remaining);
  }
} 