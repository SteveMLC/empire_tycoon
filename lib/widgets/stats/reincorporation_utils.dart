import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/game_state.dart';
import '../../services/game_service.dart';
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

    // Calculate the new prestige level after this reincorporation
    double baseRequirement = 1000000.0; // $1 million
    int newThresholdLevel = 0;

    if (currentNetWorth >= baseRequirement) {
      newThresholdLevel = (log(currentNetWorth / baseRequirement) / log(10)).floor() + 1;
    }

    // Calculate the expected new network worth after this reincorporation
    double networkWorthIncrement = newThresholdLevel > 0 ? pow(10, newThresholdLevel - 1).toDouble() / 100 : 0;
    double newNetworkWorth = gameState.networkWorth + networkWorthIncrement;

    // Count how many threshold levels we'll have used after this reincorporation
    int newTotalPrestigeLevels = 0;
    if (newNetworkWorth > 0) {
      if (newNetworkWorth >= 0.01) newTotalPrestigeLevels++;  // $1M threshold
      if (newNetworkWorth >= 0.1) newTotalPrestigeLevels++;   // $10M threshold
      if (newNetworkWorth >= 1.0) newTotalPrestigeLevels++;   // $100M threshold
      if (newNetworkWorth >= 10.0) newTotalPrestigeLevels++;  // $1B threshold
      if (newNetworkWorth >= 100.0) newTotalPrestigeLevels++; // $10B threshold
      if (newNetworkWorth >= 1000.0) newTotalPrestigeLevels++; // $100B threshold
      if (newNetworkWorth >= 10000.0) newTotalPrestigeLevels++; // $1T threshold
      if (newNetworkWorth >= 100000.0) newTotalPrestigeLevels++; // $10T threshold
      if (newNetworkWorth >= 1000000.0) newTotalPrestigeLevels++; // $100T threshold
    }

    // Calculate new passive bonus with 20% compounding per prestige level
    double newPassiveBonus = pow(1.2, newTotalPrestigeLevels).toDouble();

    // We already calculated these values above, so we can use them for the click multiplier calculation
    double newNetworkValue = newNetworkWorth; // Reuse value from passive calculation

    // Count total prestige levels that will be used, which determines the multiplier
    int totalPrestigeLevels = 0;
    if (newNetworkValue > 0) {
      if (newNetworkValue >= 0.01) totalPrestigeLevels++;  // $1M threshold
      if (newNetworkValue >= 0.1) totalPrestigeLevels++;   // $10M threshold
      if (newNetworkValue >= 1.0) totalPrestigeLevels++;   // $100M threshold
      if (newNetworkValue >= 10.0) totalPrestigeLevels++;  // $1B threshold
      if (newNetworkValue >= 100.0) totalPrestigeLevels++; // $10B threshold
      if (newNetworkValue >= 1000.0) totalPrestigeLevels++; // $100B threshold
      if (newNetworkValue >= 10000.0) totalPrestigeLevels++; // $1T threshold
      if (newNetworkValue >= 100000.0) totalPrestigeLevels++; // $10T threshold
      if (newNetworkValue >= 1000000.0) totalPrestigeLevels++; // $100T threshold
    }

    // Calculate the new click multiplier (1.0 + 0.1 per level)
    double newClickMultiplier = 1.0 + (0.1 * totalPrestigeLevels);
    if (totalPrestigeLevels > 0 && newClickMultiplier < 1.2) {
      newClickMultiplier = 1.2; // First level should be 1.2x instead of 1.1x
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
            Text('New click multiplier: ${newClickMultiplier.toStringAsFixed(2)}x'),
            Text('New passive bonus: ${newPassiveBonus.toStringAsFixed(2)}x (+${(newPassiveBonus - passiveBonus).toStringAsFixed(2)}x)',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Successfully re-incorporated! New passive bonus: ${gameState.incomeMultiplier.toStringAsFixed(2)}x'),
                    backgroundColor: Colors.green,
                  ),
                );

                Provider.of<GameService>(context, listen: false).soundManager.playEventReincorporationSound();
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
        content: Column(
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
            const Text('How it works:'),
            Text('1. Re-Incorporation uses unlock at \$1M, \$10M, \$100M, \$1B up to \$100T (9 total)'),
            Text('2. You have ${gameState.reincorporationUsesAvailable} use(s) available now'),
            Text('3. Next unlock at $formattedThreshold net worth'),
            const Text('4. Each use provides permanent 20% passive income bonus'),
            const Text('5. Tap value increases with each prestige level'),
            const SizedBox(height: 16),
            const Text('Your prestige level and multipliers are kept forever, even if you reset your game!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
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