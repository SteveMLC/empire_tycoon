import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/game_state.dart';
import '../../themes/stats_themes.dart';
import '../../utils/number_formatter.dart';
import 'stats_utils.dart';

class OverviewCard extends StatelessWidget {
  final GameState gameState;
  final StatsTheme theme;
  final Function(BuildContext) showReincorporateConfirmation;
  final Function(BuildContext) showReincorporateInfo;
  final Function(BuildContext, GameState, StatsTheme) buildThemeToggle;

  const OverviewCard({
    Key? key,
    required this.gameState,
    required this.theme,
    required this.showReincorporateConfirmation,
    required this.showReincorporateInfo,
    required this.buildThemeToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double netWorth = gameState.calculateNetWorth();
    double minNetWorthRequired = gameState.getMinimumNetWorthForReincorporation();
    final bool isExecutive = theme.id == 'executive';

    // Can reincorporate only if there are uses available AND we meet the net worth requirement
    bool canReincorporate = gameState.reincorporationUsesAvailable > 0 && netWorth >= minNetWorthRequired;

    return Card(
      elevation: theme.elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.borderRadius),
        side: BorderSide(
          color: isExecutive 
              ? const Color(0xFF2A3142)
              : theme.cardBorderColor,
        ),
      ),
      color: theme.cardBackgroundColor,
      shadowColor: theme.cardShadow?.color ?? Colors.black26,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: isExecutive ? theme.titleColor : Colors.blue.shade700,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Overview',
                      style: isExecutive 
                          ? theme.cardTitleStyle
                          : TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                    ),
                  ],
                ),
                
                // Move theme toggle button inline with Overview header
                if (gameState.isExecutiveStatsThemeUnlocked)
                  buildThemeToggle(context, gameState, theme),
              ],
            ),

            Divider(
              height: 30,
              thickness: 1,
              color: isExecutive
                  ? const Color(0xFF2A3142)
                  : Colors.blue.withOpacity(0.2),
            ),

            // Enhanced stat rows with icons
            StatsUtils.buildStatRowWithIcon(
              'Net Worth', 
              NumberFormatter.formatCurrency(netWorth),
              Icons.account_balance_wallet,
              isExecutive ? theme.primaryChartColor : Colors.blue.shade500,
              theme
            ),

            if (gameState.incomeMultiplier > 1.0)
              Builder(builder: (context) {
                // Calculate the current prestige level using the same formula as in _showReincorporateConfirmation
                int currentPrestigeLevel = 0;
                if (gameState.networkWorth > 0) {
                  currentPrestigeLevel = (log(gameState.networkWorth * 100 + 1) / log(10)).floor();
                }
                return StatsUtils.buildStatRowWithIcon(
                  'Prestige Multiplier', 
                  '+${((gameState.incomeMultiplier - 1) * 100).toStringAsFixed(0)}%',
                  Icons.star,
                  isExecutive ? Colors.amber : Colors.amber.shade600,
                  theme
                );
              }),

            // Show network worth as lifetime stat with icon
            StatsUtils.buildStatRowWithIcon(
              'Lifetime Network Worth', 
              NumberFormatter.formatCurrency(gameState.networkWorth * 100000000 + gameState.calculateNetWorth()),
              Icons.show_chart,
              isExecutive ? theme.tertiaryChartColor : Colors.green.shade600,
              theme
            ),

            StatsUtils.buildStatRowWithIcon(
              'Total Money Earned', 
              NumberFormatter.formatCurrency(gameState.totalEarned),
              Icons.monetization_on,
              isExecutive ? theme.primaryChartColor : Colors.orange.shade600,
              theme
            ),
            
            StatsUtils.buildStatRowWithIcon(
              'Platinum Points', 
              '${gameState.platinumPoints} PP',
              Icons.diamond,
              isExecutive ? Colors.purple.shade300 : Colors.purple.shade600,
              theme
            ),
            
            StatsUtils.buildStatRowWithIcon(
              'Time Played', 
              StatsUtils.calculateTimePlayed(gameState),
              Icons.access_time,
              isExecutive ? Colors.green.shade300 : Colors.green.shade600,
              theme
            ),

            const SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isExecutive 
                    ? const Color(0xFF242C3B)
                    : Colors.blue.withOpacity(0.05),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: canReincorporate
                          ? () => showReincorporateConfirmation(context)
                          : null,
                      icon: Icon(
                        Icons.refresh,
                        color: canReincorporate ? Colors.white : Colors.grey[400],
                        size: 18,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isExecutive 
                            ? const Color(0xFF1A56DB) // Rich blue for executive theme
                            : Colors.indigo,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: isExecutive 
                            ? const Color(0xFF1E2430) 
                            : Colors.grey[300],
                        disabledForegroundColor: isExecutive 
                            ? Colors.grey[600] 
                            : Colors.grey[600],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: isExecutive ? 2 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isExecutive 
                          ? const Color(0xFF1E2430) 
                          : Colors.white,
                      border: Border.all(
                        color: isExecutive
                            ? theme.cardBorderColor
                            : Colors.blue.shade100,
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.info_outline,
                        color: isExecutive ? Colors.blue.shade300 : Colors.blue,
                        size: 22,
                      ),
                      onPressed: () => showReincorporateInfo(context),
                      tooltip: 'About Re-Incorporation',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}