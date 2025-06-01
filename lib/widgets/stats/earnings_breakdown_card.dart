import 'dart:math';
import 'package:flutter/material.dart';

import '../../models/game_state.dart';
import '../../themes/stats_themes.dart';
import '../../utils/number_formatter.dart';
import 'stats_utils.dart';

class EarningsBreakdownCard extends StatelessWidget {
  final GameState gameState;
  final StatsTheme theme;

  const EarningsBreakdownCard({
    Key? key,
    required this.gameState,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isExecutive = theme.id == 'executive';
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
              children: [
                Icon(
                  Icons.bar_chart,
                  color: isExecutive ? theme.titleColor : Colors.blue.shade700,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Earnings Breakdown',
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

            Divider(
              height: 30,
              thickness: 1,
              color: isExecutive
                  ? const Color(0xFF2A3142)
                  : Colors.blue.withOpacity(0.2),
            ),

            // Enhanced earnings breakdown with icons
            StatsUtils.buildStatRowWithIcon(
              'Hustle Earnings',
              '${NumberFormatter.formatCurrency(gameState.manualEarnings)} (${manualPercent.toStringAsFixed(1)}%)', 
              Icons.touch_app,
              isExecutive ? theme.primaryChartColor : Colors.blue.shade500,
              theme
            ),
            
            StatsUtils.buildStatRowWithIcon(
              'Business Earnings',
              '${NumberFormatter.formatCurrency(gameState.passiveEarnings)} (${passivePercent.toStringAsFixed(1)}%)', 
              Icons.business,
              isExecutive ? theme.secondaryChartColor : Colors.amber.shade600,
              theme
            ),
            
            StatsUtils.buildStatRowWithIcon(
              'Investment Earnings',
              '${NumberFormatter.formatCurrency(gameState.investmentEarnings + gameState.investmentDividendEarnings)} (${investmentPercent.toStringAsFixed(1)}%)', 
              Icons.trending_up,
              isExecutive ? theme.tertiaryChartColor : Colors.green.shade600,
              theme
            ),
            
            StatsUtils.buildStatRowWithIcon(
              'Real Estate Earnings',
              '${NumberFormatter.formatCurrency(gameState.realEstateEarnings)} (${realEstatePercent.toStringAsFixed(1)}%)', 
              Icons.home,
              isExecutive ? theme.quaternaryChartColor : Colors.red.shade600,
              theme
            ),

            const SizedBox(height: 16),

            // Enhanced bar chart visualization
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  color: isExecutive
                      ? const Color(0xFF242C3B)
                      : theme.backgroundColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    StatsUtils.buildBreakdownSegment(manualPercent / 100, isExecutive ? theme.primaryChartColor : Colors.blue.shade500, isExecutive),
                    StatsUtils.buildBreakdownSegment(passivePercent / 100, isExecutive ? theme.secondaryChartColor : Colors.amber.shade600, isExecutive),
                    StatsUtils.buildBreakdownSegment(investmentPercent / 100, isExecutive ? theme.tertiaryChartColor : Colors.green.shade600, isExecutive),
                    StatsUtils.buildBreakdownSegment(realEstatePercent / 100, isExecutive ? theme.quaternaryChartColor : Colors.red.shade600, isExecutive),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Legend with better styling
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                StatsUtils.buildEnhancedLegendItem(theme.primaryChartColor, 'Hustle', theme),
                StatsUtils.buildEnhancedLegendItem(theme.secondaryChartColor, 'Business', theme),
                StatsUtils.buildEnhancedLegendItem(theme.tertiaryChartColor, 'Investment', theme),
                StatsUtils.buildEnhancedLegendItem(theme.quaternaryChartColor, 'Real Estate', theme),
              ],
            ),
          ],
        ),
      ),
    );
  }
}