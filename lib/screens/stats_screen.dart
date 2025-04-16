import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../services/game_service.dart';
import '../utils/number_formatter.dart';
import '../utils/time_utils.dart';
import '../utils/sounds.dart';
import '../widgets/achievements_section.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String formatLargeNumber(double value) {
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
  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewCard(gameState),

                const SizedBox(height: 20),

                _buildEarningsBreakdown(gameState),

                const SizedBox(height: 20),

                _buildAssetsBreakdown(gameState),

                const SizedBox(height: 20),

                _buildHourlyEarningsChart(gameState),

                const SizedBox(height: 20),

                _buildNetWorthChart(gameState),

                const SizedBox(height: 20),

                const AchievementsSection(),

                const SizedBox(height: 20),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Game Controls',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Consumer<GameService>(
                          builder: (context, gameService, child) {
                            bool soundEnabled = gameService.soundManager.isSoundEnabled();
                            return SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  gameService.soundManager.toggleSound(!soundEnabled);
                                  // Force rebuild to update icon
                                  setState(() {});
                                },
                                icon: Icon(
                                  soundEnabled ? Icons.volume_up : Icons.volume_off,
                                  color: soundEnabled ? Colors.green : Colors.grey,
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: BorderSide(
                                    color: soundEnabled ? Colors.green : Colors.grey,
                                  ),
                                ),
                                label: Text(
                                  soundEnabled ? 'Sound: ON' : 'Sound: OFF',
                                  style: TextStyle(
                                    color: soundEnabled ? Colors.green : Colors.grey,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        Consumer<GameService>(
                          builder: (context, gameService, child) {
                            return SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Saving game...'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );

                                  bool success = await gameService.saveGame();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(success
                                          ? 'Game saved successfully!'
                                          : 'Failed to save game.'),
                                      backgroundColor: success ? Colors.green : Colors.red,
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.save,
                                  color: Colors.blue,
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(
                                    color: Colors.blue,
                                  ),
                                ),
                                label: const Text(
                                  'Save Game',
                                  style: TextStyle(
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Platinum Vault Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                               // TODO: Add check if vault is unlocked?
                               Navigator.pushNamed(context, '/platinumVault');
                            },
                            icon: Icon(Icons.star, color: Colors.white), // Use star icon for consistency
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade600, // Theme color
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            label: const Text('Platinum Vault'),
                          ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _showResetConfirmation(context, gameState),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Reset Game'),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Consumer<GameState>(
                          builder: (context, gameState, child) {
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: gameState.isPremium
                                    ? null // Disable if already premium
                                    : () => _showPremiumPurchaseDialog(context, gameState),
                                icon: const Icon(Icons.star),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  disabledBackgroundColor: Colors.grey[300],
                                  disabledForegroundColor: Colors.grey[600],
                                ),
                                label: Text(gameState.isPremium
                                    ? 'Premium Enabled'
                                    : 'Get Premium (\$4.99)'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard(GameState gameState) {
    double netWorth = gameState.calculateNetWorth();
    double minNetWorthRequired = gameState.getMinimumNetWorthForReincorporation();

    // Can reincorporate only if there are uses available AND we meet the net worth requirement
    bool canReincorporate = gameState.reincorporationUsesAvailable > 0 && netWorth >= minNetWorthRequired;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            _buildStatRow('Net Worth', NumberFormatter.formatCurrency(netWorth)),

            if (gameState.incomeMultiplier > 1.0)
              Builder(builder: (context) {
                // Calculate the current prestige level using the same formula as in _showReincorporateConfirmation
                int currentPrestigeLevel = 0;
                if (gameState.networkWorth > 0) {
                  currentPrestigeLevel = (log(gameState.networkWorth * 100 + 1) / log(10)).floor();
                }
                return _buildStatRow('Prestige Multiplier', '${gameState.incomeMultiplier.toStringAsFixed(2)}x (1.2 compounded ${currentPrestigeLevel}x)');
              }),

            // Show network worth as lifetime stat (doesn't reset with reincorporation)
            _buildStatRow('Lifetime Network Worth', NumberFormatter.formatCurrency(gameState.networkWorth * 100000000 + gameState.calculateNetWorth())),

            _buildStatRow('Total Money Earned', NumberFormatter.formatCurrency(gameState.totalEarned)),
            _buildStatRow('Lifetime Taps', gameState.lifetimeTaps.toString()),
            _buildStatRow('Time Playing', _calculateTimePlayed(gameState)),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canReincorporate
                        ? () => _showReincorporateConfirmation(context, gameState)
                        : null,
                    icon: const Icon(Icons.refresh),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      disabledForegroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    label: Text(
                        gameState.reincorporationUsesAvailable > 0
                          ? 'Re-Incorporate (${gameState.reincorporationUsesAvailable} use${gameState.reincorporationUsesAvailable > 1 ? 's' : ''} available)'
                          : gameState.totalReincorporations >= 9
                            ? 'Re-Incorporate (Maxed Out)'
                            : netWorth >= minNetWorthRequired
                              ? 'Re-Incorporate (No uses available)'
                              : 'Re-Incorporate (${NumberFormatter.formatCurrency(minNetWorthRequired)} needed)'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.blue),
                  onPressed: () => _showReincorporateInfo(context),
                  tooltip: 'About Re-Incorporation',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsBreakdown(GameState gameState) {
    double totalEarned = gameState.manualEarnings +
                         gameState.passiveEarnings +
                         gameState.investmentEarnings +
                         gameState.investmentDividendEarnings +
                         gameState.realEstateEarnings;

    double manualPercent = totalEarned > 0 ? (gameState.manualEarnings / totalEarned) * 100 : 0;
    double passivePercent = totalEarned > 0 ? (gameState.passiveEarnings / totalEarned) * 100 : 0;
    double investmentPercent = totalEarned > 0 ? ((gameState.investmentEarnings + gameState.investmentDividendEarnings) / totalEarned) * 100 : 0;
    double realEstatePercent = totalEarned > 0 ? (gameState.realEstateEarnings / totalEarned) * 100 : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Earnings Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            _buildStatRow('Hustle Earnings',
                '${NumberFormatter.formatCurrency(gameState.manualEarnings)} (${manualPercent.toStringAsFixed(1)}%)'),
            _buildStatRow('Business Earnings',
                '${NumberFormatter.formatCurrency(gameState.passiveEarnings)} (${passivePercent.toStringAsFixed(1)}%)'),
            _buildStatRow('Investment Earnings',
                '${NumberFormatter.formatCurrency(gameState.investmentEarnings + gameState.investmentDividendEarnings)} (${investmentPercent.toStringAsFixed(1)}%)'),
            _buildStatRow('Real Estate Earnings',
                '${NumberFormatter.formatCurrency(gameState.realEstateEarnings)} (${realEstatePercent.toStringAsFixed(1)}%)'),

            const SizedBox(height: 10),

            Container(
              height: 20,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[200],
              ),
              child: Row(
                children: [
                  Flexible(
                    flex: (manualPercent * 100).round(),
                    child: Container(color: Colors.blue),
                  ),
                  Flexible(
                    flex: (passivePercent * 100).round(),
                    child: Container(color: Colors.green),
                  ),
                  Flexible(
                    flex: (investmentPercent * 100).round(),
                    child: Container(color: Colors.orange),
                  ),
                  Flexible(
                    flex: (realEstatePercent * 100).round(),
                    child: Container(color: Colors.red),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.blue, 'Hustle'),
                const SizedBox(width: 10),
                _buildLegendItem(Colors.green, 'Business'),
                const SizedBox(width: 10),
                _buildLegendItem(Colors.orange, 'Investment'),
                const SizedBox(width: 10),
                _buildLegendItem(Colors.red, 'Real Estate'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetsBreakdown(GameState gameState) {
    double cash = gameState.money;
    double businessValue = gameState.businesses.fold(0.0, (sum, business) => sum + business.getCurrentValue());
    double investmentValue = gameState.investments.fold(0.0, (sum, investment) => sum + investment.getCurrentValue());

    // Calculate real estate value using the corrected locale method
    double realEstateValue = 0.0;
    for (var locale in gameState.realEstateLocales) {
      realEstateValue += locale.getTotalValue(); // Use corrected method
    }

    double totalAssets = cash + businessValue + investmentValue + realEstateValue;

    double cashPercent = totalAssets > 0 ? (cash / totalAssets) * 100 : 0;
    double businessPercent = totalAssets > 0 ? (businessValue / totalAssets) * 100 : 0;
    double investmentPercent = totalAssets > 0 ? (investmentValue / totalAssets) * 100 : 0;
    double realEstatePercent = totalAssets > 0 ? (realEstateValue / totalAssets) * 100 : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assets Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            _buildStatRow('Cash',
                '${NumberFormatter.formatCurrency(cash)} (${cashPercent.toStringAsFixed(1)}%)'),
            _buildStatRow('Business Value',
                '${NumberFormatter.formatCurrency(businessValue)} (${businessPercent.toStringAsFixed(1)}%)'),
            _buildStatRow('Investment Value',
                '${NumberFormatter.formatCurrency(investmentValue)} (${investmentPercent.toStringAsFixed(1)}%)'),
            _buildStatRow('Real Estate Value',
                '${NumberFormatter.formatCurrency(realEstateValue)} (${realEstatePercent.toStringAsFixed(1)}%)'),

            const SizedBox(height: 10),

            Container(
              height: 20,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[200],
              ),
              child: Row(
                children: [
                  Flexible(
                    flex: (cashPercent * 100).round(),
                    child: Container(color: Colors.blue),
                  ),
                  Flexible(
                    flex: (businessPercent * 100).round(),
                    child: Container(color: Colors.green),
                  ),
                  Flexible(
                    flex: (investmentPercent * 100).round(),
                    child: Container(color: Colors.orange),
                  ),
                  Flexible(
                    flex: (realEstatePercent * 100).round(),
                    child: Container(color: Colors.red),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.blue, 'Cash'),
                const SizedBox(width: 10),
                _buildLegendItem(Colors.green, 'Business'),
                const SizedBox(width: 10),
                _buildLegendItem(Colors.orange, 'Investment'),
                const SizedBox(width: 10),
                _buildLegendItem(Colors.red, 'Real Estate'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyEarningsChart(GameState gameState) {
    final now = DateTime.now();
    Map<String, double> hourlyDataMap = {};

    for (int i = 23; i >= 0; i--) {
      final hour = now.subtract(Duration(hours: i));
      final hourKey = TimeUtils.getHourKey(hour);
      final earnings = gameState.hourlyEarnings[hourKey] ?? 0.0;
      hourlyDataMap[hourKey] = earnings;
    }

    // Sort keys chronologically (YYYY-MM-DD-HH)
    List<String> sortedKeys = hourlyDataMap.keys.toList()..sort();
    List<MapEntry<String, double>> hourlyData = sortedKeys
        .map((key) => MapEntry(key, hourlyDataMap[key]!))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hourly Earnings (Last 24h)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 200,
              child: hourlyData.isEmpty
                  ? const Center(child: Text('No earnings data available'))
                  : _buildBarChart(hourlyData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetWorthChart(GameState gameState) {
    Map<int, double> historyMap = gameState.persistentNetWorthHistory;

    // Sort by timestamp (key)
    List<int> sortedTimestamps = historyMap.keys.toList()..sort();
    List<double> history = sortedTimestamps.map((ts) => historyMap[ts]!).toList();

    // Removed dynamic timeframe logic
    String timeframeText = 'Net Worth History (Persistent)';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              timeframeText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 200,
              child: history.isEmpty
                  ? const Center(child: Text('No net worth history available'))
                  : _buildLineChart(history),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<MapEntry<String, double>> data) {
    double maxValue = 0;
    for (var entry in data) {
      if (entry.value > maxValue) {
        maxValue = entry.value;
      }
    }

    maxValue = maxValue == 0 ? 1 : maxValue;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((entry) {
        double heightPercent = entry.value / maxValue;

        String hour = entry.key.substring(entry.key.length - 2);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: 160 * heightPercent,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(hour, style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLineChart(List<double> data) {
    if (data.length < 2) {
      return const Center(child: Text('Not enough data for chart'));
    }

    double maxValue = data.reduce((a, b) => a > b ? a : b);
    double minValue = data.reduce((a, b) => a < b ? a : b);

    double range = maxValue - minValue;
    if (range <= 0) range = maxValue > 0 ? maxValue : 1;

    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: ChartPainter(
        data: data,
        minValue: minValue,
        maxValue: maxValue,
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _calculateTimePlayed(GameState gameState) {
    // Use gameStartTime for persistent time tracking across reincorporations
    final firstStart = gameState.gameStartTime;
    final playTime = DateTime.now().difference(firstStart);

    final days = playTime.inDays;
    final hours = playTime.inHours % 24;
    final minutes = playTime.inMinutes % 60;

    if (days > 0) {
      return '$days days, $hours hours';
    } else if (hours > 0) {
      return '$hours hours, $minutes mins';
    } else {
      return '${playTime.inMinutes} mins';
    }
  }

  void _showResetConfirmation(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Game?'),
        content: const Text(
          'Are you sure you want to reset your game? All progress will be lost!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<GameService>(context, listen: false).resetGame();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showPremiumPurchaseDialog(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Purchase Premium'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'For \$4.99, you will get lifetime access to premium features:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Remove all ads from the game'),
            const Text('• More features coming soon!'),
            const SizedBox(height: 16),
            const Text(
              'This is a one-time purchase and will remain active even if you reset your game progress.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement actual purchase logic with Google Play Store
              // For now, just enable premium immediately
              gameState.enablePremium();
              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Premium features activated!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.purple),
            child: const Text('Purchase \$4.99'),
          ),
        ],
      ),
    );
  }

  void _showReincorporateConfirmation(BuildContext context, GameState gameState) {
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

  void _showReincorporateInfo(BuildContext context) {
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
}

// Chart painter for line charts
class ChartPainter extends CustomPainter {
  final List<double> data;
  final double minValue;
  final double maxValue;

  ChartPainter({
    required this.data,
    required this.minValue,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final textStyle = TextStyle(
      color: Colors.grey[600],
      fontSize: 10,
    );
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final path = Path();
    final width = size.width;
    final height = size.height - 20; // Reserve space for labels at bottom

    final double xStep = width / (data.length - 1);

    final range = (maxValue - minValue) == 0 ? 1 : maxValue - minValue;

    for (int i = 0; i < data.length; i++) {
      final x = i * xStep;
      final y = height - ((data[i] - minValue) / range * height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    final pointPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final x = i * xStep;
      final y = height - ((data[i] - minValue) / range * height);

      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }

    // Draw min and max value labels on y-axis
    if (maxValue > minValue) {
      String maxLabel = _formatValue(maxValue);
      textPainter.text = TextSpan(text: maxLabel, style: textStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, 0));

      String midLabel = _formatValue(minValue + range / 2);
      textPainter.text = TextSpan(text: midLabel, style: textStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, height / 2 - textPainter.height / 2));

      String minLabel = _formatValue(minValue);
      textPainter.text = TextSpan(text: minLabel, style: textStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, height - textPainter.height));
    }
  }

  String _formatValue(double value) {
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}