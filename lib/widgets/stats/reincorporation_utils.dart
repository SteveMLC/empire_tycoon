import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/game_state.dart';
import '../../services/game_service.dart';
import '../../services/review_manager.dart';
import '../../utils/number_formatter.dart';

/// Utility class for reincorporation dialog and related functions
class ReincorporationUtils {
  /// Show the reincorporation confirmation dialog
  static void showReincorporateConfirmation(BuildContext context, GameState gameState) {
    double currentNetWorth = gameState.calculateNetWorth();

    // Calculate passive income bonus (20% compounding per prestige level)
    double passiveBonus = 1.0;
    int currentPrestigeLevels = 0;

    // Count how many threshold levels we've currently used based on networkWorth
    if (gameState.networkWorth > 0) {
      // $1M threshold
      if (gameState.networkWorth >= 0.01) currentPrestigeLevels++;
      // $10M threshold
      if (gameState.networkWorth >= 0.1) currentPrestigeLevels++;
      // $100M threshold
      if (gameState.networkWorth >= 1.0) currentPrestigeLevels++;
      // $1B threshold
      if (gameState.networkWorth >= 10.0) currentPrestigeLevels++;
      // $10B threshold
      if (gameState.networkWorth >= 100.0) currentPrestigeLevels++;
      // $100B threshold
      if (gameState.networkWorth >= 1000.0) currentPrestigeLevels++;
      // $1T threshold
      if (gameState.networkWorth >= 10000.0) currentPrestigeLevels++;
      // $10T threshold
      if (gameState.networkWorth >= 100000.0) currentPrestigeLevels++;
      // $100T threshold
      if (gameState.networkWorth >= 1000000.0) currentPrestigeLevels++;

      // Calculate passive bonus with 20% compounding per prestige level
      passiveBonus = pow(1.2, currentPrestigeLevels).toDouble();
    }

    // MODIFIED: Only use the next level after currently achieved levels
    int nextLevel = currentPrestigeLevels + 1;
    
    // Calculate the expected new network worth after this reincorporation
    // Only increment by one level, not skipping any levels
    double networkWorthIncrement = nextLevel > 0 ? pow(10, nextLevel - 1).toDouble() / 100 : 0;
    double newNetworkWorth = gameState.networkWorth + networkWorthIncrement;

    // Count how many threshold levels we'll have used after this reincorporation
    // Will be exactly one more than current level
    int newTotalPrestigeLevels = currentPrestigeLevels + 1;

    // Calculate new passive bonus with 20% compounding per prestige level
    double newPassiveBonus = pow(1.2, newTotalPrestigeLevels).toDouble();

    // Calculate the new click multiplier (1.0 + 0.1 per level)
    double newClickMultiplier = 1.0 + (0.1 * newTotalPrestigeLevels);
    if (newTotalPrestigeLevels > 0 && newClickMultiplier < 1.2) {
      newClickMultiplier = 1.2; // First level should be 1.2x instead of 1.1x
    }

    // Determine the threshold name for next level being used
    String thresholdName = "";
    switch(nextLevel) {
      case 1: thresholdName = "\$1M"; break;
      case 2: thresholdName = "\$10M"; break;
      case 3: thresholdName = "\$100M"; break;
      case 4: thresholdName = "\$1B"; break;
      case 5: thresholdName = "\$10B"; break;
      case 6: thresholdName = "\$100B"; break;
      case 7: thresholdName = "\$1T"; break;
      case 8: thresholdName = "\$10T"; break;
      case 9: thresholdName = "\$100T"; break;
      default: thresholdName = "next level";
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Re-Incorporate Business?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Re-incorporating will reset most of your progress but grants permanent multipliers to income and clicks.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Available Re-Incorporation uses: ${gameState.reincorporationUsesAvailable}'),
            Text('Your net worth: ${NumberFormatter.formatCurrency(currentNetWorth)}'),
            const SizedBox(height: 8),
            Text('Current click multiplier: ${gameState.prestigeMultiplier.toStringAsFixed(2)}x'),
            Text('Current passive bonus: ${passiveBonus.toStringAsFixed(2)}x'),
            const SizedBox(height: 8),
            Text('Next level to use: $thresholdName threshold', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('New click multiplier: ${newClickMultiplier.toStringAsFixed(2)}x'),
            Text('New passive bonus: ${newPassiveBonus.toStringAsFixed(2)}x (+${(newPassiveBonus - passiveBonus).toStringAsFixed(2)}x)',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 8),
            const Text('NOTE: Your tap progress will be preserved with this reincorporation.', 
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blue)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              bool success = gameState.reincorporate();
              Navigator.of(context).pop();

              if (success) {
                unawaited(Provider.of<GameService>(context, listen: false).saveGame());
                ReviewManager.instance.onIncomeMultiplier(
                  context,
                  multiplier: gameState.incomeMultiplier,
                );
                // ScaffoldMessenger.of(context).showSnackBar(
                //   SnackBar(
                //     content: Text('Successfully re-incorporated! New passive bonus: ${gameState.incomeMultiplier.toStringAsFixed(2)}x'),
                //     backgroundColor: Colors.green,
                //   ),
                // );

                Provider.of<GameService>(context, listen: false).playSound(() => Provider.of<GameService>(context, listen: false).soundManager.playEventReincorporationSound());
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Re-Incorporate'),
          ),
        ],
      ),
    );
  }

  /// Show information about reincorporation
  static void showReincorporateInfo(BuildContext context) {
    final gameState = Provider.of<GameState>(context, listen: false);
    double nextThreshold = gameState.getMinimumNetWorthForReincorporation();

    String formattedThreshold = formatLargeNumber(nextThreshold);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Re-Incorporation'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Re-Incorporation is a prestige system that allows you to:'),
              const SizedBox(height: 8),
              const Text('• Reset your progress for permanent bonuses'),
              const Text('• Earn tap multipliers based on your net worth'),
              const Text('• Gain 20% compounding bonus to passive income'),
              const Text('• Start over with boosted earnings'),
              const SizedBox(height: 16),
              const Text('How it works:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('1. Re-Incorporation uses unlock at \$1M, \$10M, \$100M, \$1B up to \$100T (9 total)'),
              Text('2. You can only use ONE re-incorporation level at a time, starting from the lowest'),
              Text('3. You have ${gameState.reincorporationUsesAvailable} use(s) available now'),
              Text('4. Next unlock at $formattedThreshold net worth'),
              const Text('5. Each use provides permanent 20% passive income bonus'),
              const Text('6. Tap value increases with each prestige level'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Text(
                  'NOTE: Even if your net worth meets multiple thresholds, you must re-incorporate once for each threshold level, starting with the lowest.',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Text(
                  'Your prestige level and multipliers are kept forever, even if you reset your game!',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 20), // Extra space before actions
            ],
          ),
        ),
        actions: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Got it',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to format large numbers
  static String formatLargeNumber(double value) {
    if (value >= 1000000000000) {
      return '\$${(value / 1000000000000).toStringAsFixed(1)}T';
    } else if (value >= 1000000000) {
      return '\$${(value / 1000000000).toStringAsFixed(1)}B';
    } else if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$${value.toStringAsFixed(0)}';
    }
  }
} 
