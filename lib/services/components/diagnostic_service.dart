import 'dart:async';
import 'package:flutter/foundation.dart';
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
    if (!kDebugMode) return;
    print("🔍 [DIAGNOSTICS] Running timer diagnostics check");

    final startMoney = _gameState.money;
    final startTime = DateTime.now();
    final startIncomeRate = _gameState.calculateTotalIncomePerSecond();

    print("🔍 [DIAGNOSTICS] Current income rate: ${startIncomeRate.toStringAsFixed(2)}/sec (${startIncomeRate >= 0 ? 'positive' : 'negative'})");

    // Wait for 5 seconds and check the money change
    Future.delayed(const Duration(seconds: 5), () {
      if (!kDebugMode) return;
      final endMoney = _gameState.money;
      final endTime = DateTime.now();
      final elapsedSeconds = endTime.difference(startTime).inMilliseconds / 1000;
      final moneyChange = endMoney - startMoney;
      final moneyChangeDirection = moneyChange >= 0 ? 'increased' : 'decreased';

      final incomeRate = startIncomeRate;
      final expectedIncome = incomeRate * elapsedSeconds;
      final expectedDirection = expectedIncome >= 0 ? 'increase' : 'decrease';
      final tolerance = expectedIncome.abs() * 0.1;

      print("🔍 [DIAGNOSTICS] Money $moneyChangeDirection by ${moneyChange.abs().toStringAsFixed(2)} over ${elapsedSeconds.toStringAsFixed(2)} seconds");
      print("🔍 [DIAGNOSTICS] Income rate: ${incomeRate.toStringAsFixed(2)}/sec");
      print("🔍 [DIAGNOSTICS] Expected ~${expectedIncome.abs().toStringAsFixed(2)} $expectedDirection based on income rate");

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

        print("🔄 [DIAGNOSTICS] Performing emergency timer cleanup and reset");

        try {
          _gameState.cancelAllTimers();
          print("✅ [DIAGNOSTICS] GameState timers cancelled");
        } catch (e) {
          print("⚠️ [DIAGNOSTICS] Error cancelling GameState timers: $e");
        }

        _cancelAllTimers();
        _setLastGameUpdateTime(DateTime.now());

        print("🛑 CENTRAL TIMER SYSTEM: Cancelling all timers");

        Future.delayed(const Duration(milliseconds: 1000), () {
          if (!kDebugMode) return;
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
