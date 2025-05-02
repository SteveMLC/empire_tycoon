import 'dart:math';
import 'package:flutter/material.dart';

import '../../models/game_state.dart';
import '../../themes/stats_themes.dart';
import '../../utils/number_formatter.dart';

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
            _buildStatRowWithIcon(
              'Hustle Earnings',
              '${NumberFormatter.formatCurrency(gameState.manualEarnings)} (${manualPercent.toStringAsFixed(1)}%)', 
              Icons.touch_app,
              isExecutive ? theme.primaryChartColor : Colors.blue.shade500,
              theme
            ),
            
            _buildStatRowWithIcon(
              'Business Earnings',
              '${NumberFormatter.formatCurrency(gameState.passiveEarnings)} (${passivePercent.toStringAsFixed(1)}%)', 
              Icons.business,
              isExecutive ? theme.secondaryChartColor : Colors.amber.shade600,
              theme
            ),
            
            _buildStatRowWithIcon(
              'Investment Earnings',
              '${NumberFormatter.formatCurrency(gameState.investmentEarnings + gameState.investmentDividendEarnings)} (${investmentPercent.toStringAsFixed(1)}%)', 
              Icons.trending_up,
              isExecutive ? theme.tertiaryChartColor : Colors.green.shade600,
              theme
            ),
            
            _buildStatRowWithIcon(
              'Real Estate Earnings',
              '${NumberFormatter.formatCurrency(gameState.realEstateEarnings)} (${realEstatePercent.toStringAsFixed(1)}%)', 
              Icons.home,
              isExecutive ? theme.quaternaryChartColor : Colors.indigo.shade500,
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
                    _buildBreakdownSegment(manualPercent, theme.primaryChartColor, isExecutive),
                    _buildBreakdownSegment(passivePercent, theme.secondaryChartColor, isExecutive),
                    _buildBreakdownSegment(investmentPercent, theme.tertiaryChartColor, isExecutive),
                    _buildBreakdownSegment(realEstatePercent, theme.quaternaryChartColor, isExecutive),
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
                _buildEnhancedLegendItem(theme.primaryChartColor, 'Hustle', theme),
                _buildEnhancedLegendItem(theme.secondaryChartColor, 'Business', theme),
                _buildEnhancedLegendItem(theme.tertiaryChartColor, 'Investment', theme),
                _buildEnhancedLegendItem(theme.quaternaryChartColor, 'Real Estate', theme),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatRowWithIcon(String label, String value, IconData icon, Color iconColor, StatsTheme theme) {
    final bool isExecutive = theme.id == 'executive';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isExecutive 
                  ? iconColor.withOpacity(0.1)
                  : iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Icon(
                icon,
                color: iconColor,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: isExecutive
                  ? theme.statLabelStyle
                  : TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isExecutive 
                  ? const Color(0xFF242C3B) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isExecutive 
                    ? theme.cardBorderColor 
                    : Colors.transparent,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              value,
              style: isExecutive
                  ? theme.statValueStyle.copyWith(
                      letterSpacing: 0.3,
                    )
                  : TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 0.3,
                    ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBreakdownSegment(double percent, Color color, bool isExecutive) {
    // Handle zero percentage gracefully
    if (percent <= 0) return const SizedBox.shrink();
    
    return Flexible(
      flex: max((percent * 100).round(), 1), // Ensure at least 1 flex for visibility
      child: Container(
        decoration: BoxDecoration(
          color: color,
          boxShadow: isExecutive ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ] : null,
        ),
      ),
    );
  }
  
  Widget _buildEnhancedLegendItem(Color color, String label, StatsTheme theme) {
    final bool isExecutive = theme.id == 'executive';
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: isExecutive ? [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ] : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isExecutive ? FontWeight.w500 : FontWeight.normal,
            color: theme.textColor.withOpacity(isExecutive ? 0.9 : 0.7),
          ),
        ),
      ],
    );
  }
} 