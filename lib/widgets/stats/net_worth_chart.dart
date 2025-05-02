import 'package:flutter/material.dart';

import '../../models/game_state.dart';
import '../../themes/stats_themes.dart';
import '../../widgets/chart_painter.dart';

class NetWorthChart extends StatelessWidget {
  final GameState gameState;
  final StatsTheme theme;

  const NetWorthChart({
    Key? key,
    required this.gameState,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isExecutive = theme.id == 'executive';
    Map<int, double> historyMap = gameState.persistentNetWorthHistory;

    // Sort by timestamp (key)
    List<int> sortedTimestamps = historyMap.keys.toList()..sort();
    List<double> history = sortedTimestamps.map((ts) => historyMap[ts]!).toList();

    // Removed dynamic timeframe logic
    String timeframeText = 'Net Worth History';

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
                      Icons.area_chart,
                      color: isExecutive ? theme.titleColor : Colors.blue.shade700,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      timeframeText,
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
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isExecutive 
                        ? const Color(0xFF242C3B)
                        : theme.backgroundColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isExecutive
                          ? const Color(0xFF2A3142)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Persistent',
                    style: TextStyle(
                      color: isExecutive
                          ? const Color(0xFFE5B100)
                          : theme.primaryChartColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
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

            SizedBox(
              height: 200,
              child: history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.show_chart,
                            color: theme.textColor.withOpacity(0.5),
                            size: 40,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No net worth history available yet',
                            style: TextStyle(
                              color: theme.textColor.withOpacity(0.7),
                              fontWeight: isExecutive ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your net worth will be tracked as you play',
                            style: TextStyle(
                              color: theme.textColor.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildLineChart(history, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List<double> data, StatsTheme theme) {
    if (data.length < 2) {
      return Center(child: Text('Not enough data for chart', style: TextStyle(color: theme.textColor)));
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
        theme: theme,
      ),
    );
  }
} 