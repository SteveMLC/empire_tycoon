import 'dart:async';
import '../../models/game_state.dart';
import '../../utils/time_utils.dart';

/// Diagnostic component for GameService
class DiagnosticService {
  final GameState _gameState;
  final Function _cancelAllTimers;
  final Function _setupAllTimers;
  final Function _setLastGameUpdateTime;
  
  DiagnosticService(
    this._gameState, 
    this._cancelAllTimers, 
    this._setupAllTimers,
    this._setLastGameUpdateTime
  );
  
  // Enhanced diagnostic method to detect timer issues
  void runTimerDiagnostics() {
    print("🔍 [DIAGNOSTICS] Running timer diagnostics check");
    
    final startMoney = _gameState.money;
    final startTime = DateTime.now();
    final startIncomeRate = _gameState.calculateTotalIncomePerSecond();
    
    // FIXED: Log the current income rate sign to help diagnose sign issues
    print("🔍 [DIAGNOSTICS] Current income rate: ${startIncomeRate.toStringAsFixed(2)}/sec (${startIncomeRate >= 0 ? 'positive' : 'negative'})");
    
    // Wait for 5 seconds and check the money change
    Future.delayed(const Duration(seconds: 5), () {
      final endMoney = _gameState.money;
      final endTime = DateTime.now();
      final elapsedSeconds = endTime.difference(startTime).inMilliseconds / 1000;
      final moneyChange = endMoney - startMoney;
      final moneyChangeDirection = moneyChange >= 0 ? 'increased' : 'decreased';
      
      // Calculate expected income based on income rate
      final incomeRate = startIncomeRate; // Use the rate from the start of the test
      final expectedIncome = incomeRate * elapsedSeconds;
      final expectedDirection = expectedIncome >= 0 ? 'increase' : 'decrease';
      final tolerance = expectedIncome.abs() * 0.1; // 10% tolerance, use absolute value
      
      print("🔍 [DIAGNOSTICS] Money $moneyChangeDirection by ${moneyChange.abs().toStringAsFixed(2)} over ${elapsedSeconds.toStringAsFixed(2)} seconds");
      print("🔍 [DIAGNOSTICS] Income rate: ${incomeRate.toStringAsFixed(2)}/sec");
      print("🔍 [DIAGNOSTICS] Expected ~${expectedIncome.abs().toStringAsFixed(2)} $expectedDirection based on income rate");
      
      // FIXED: Check for both magnitude discrepancy AND sign discrepancy
      bool magnitudeIssue = moneyChange.abs() > expectedIncome.abs() + tolerance;
      bool signIssue = (moneyChange >= 0) != (expectedIncome >= 0) && expectedIncome != 0;
      
      if (magnitudeIssue || signIssue) {
        if (magnitudeIssue) {
          print("⚠️ [DIAGNOSTICS] POTENTIAL DUPLICATE INCOME DETECTED! Money changing faster than expected");
          print("⚠️ [DIAGNOSTICS] This may indicate multiple timers are running simultaneously");
        }
        
        if (signIssue) {
          print("⚠️ [DIAGNOSTICS] INCOME SIGN MISMATCH DETECTED! Money ${moneyChangeDirection} when it should ${expectedDirection}");
          print("⚠️ [DIAGNOSTICS] This indicates a sign error in income application");
        }
        
        // Force timer cleanup and reset as a failsafe
        print("🔄 [DIAGNOSTICS] Performing emergency timer cleanup and reset");
        
        // ENHANCED RESET: First ensure GameState timers are cancelled
        try {
          _gameState.cancelAllTimers();
          print("✅ [DIAGNOSTICS] GameState timers cancelled");
        } catch (e) {
          print("⚠️ [DIAGNOSTICS] Error cancelling GameState timers: $e");
        }
        
        // Cancel all timers in GameService
        _cancelAllTimers();
        
        // Reset the last update time to prevent immediate updates
        _setLastGameUpdateTime(DateTime.now());
        
        // FIXED: Add a longer delay to ensure complete reset
        print("🛑 CENTRAL TIMER SYSTEM: Cancelling all timers");
        
        // Delay timer setup to ensure complete reset
        Future.delayed(const Duration(milliseconds: 1000), () {
          // Restart the centralized timer system
          print("⏱️ CENTRAL TIMER SYSTEM: Setting up all game timers");
          _setupAllTimers();
          print("✅ CENTRAL TIMER SYSTEM: All timers successfully initialized");
        });
      } else {
        print("✅ [DIAGNOSTICS] Timer function appears to be working correctly");
      }
    });
  }
}
