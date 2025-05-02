import 'package:flutter/material.dart';

import '../../models/game_state.dart';
import '../../themes/stats_themes.dart';
import '../../utils/time_utils.dart';

class HourlyEarningsChart extends StatelessWidget {
  final GameState gameState;
  final StatsTheme theme;

  const HourlyEarningsChart({
    Key? key,
    required this.gameState,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isExecutive = theme.id == 'executive';
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
                  Icons.timeline,
                  color: isExecutive ? theme.titleColor : Colors.blue.shade700,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Hourly Earnings (Last 24h)',
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

            SizedBox(
              height: 200,
              child: hourlyData.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            color: theme.textColor.withOpacity(0.5),
                            size: 40,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No earnings data available yet',
                            style: TextStyle(
                              color: theme.textColor.withOpacity(0.7),
                              fontWeight: isExecutive ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Earnings will be tracked hourly as you play',
                            style: TextStyle(
                              color: theme.textColor.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildBarChart(hourlyData, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<MapEntry<String, double>> data, StatsTheme theme) {
    final bool isExecutive = theme.id == 'executive';
    double maxValue = 0;
    for (var entry in data) {
      if (entry.value > maxValue) {
        maxValue = entry.value;
      }
    }

    maxValue = maxValue == 0 ? 1 : maxValue;

    // Add subtle grid lines for executive theme
    return Stack(
      children: [
        // Background grid for executive theme
        if (isExecutive)
          Column(
            children: List.generate(5, (i) {
              return Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: i < 4 ? BorderSide(
                        color: const Color(0xFF2A3142).withOpacity(0.5),
                        width: 0.5,
                      ) : BorderSide.none,
                    ),
                  ),
                ),
              );
            }),
          ),
        
        // Bars
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: data.map((entry) {
            double heightPercent = entry.value / maxValue;
            
            // Make very small values still visible
            if (heightPercent > 0 && heightPercent < 0.02) {
              heightPercent = 0.02;
            }
    
            String hour = entry.key.substring(entry.key.length - 2);
    
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: 160 * heightPercent,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isExecutive
                              ? [
                                  theme.primaryChartColor,
                                  theme.primaryChartColor.withOpacity(0.7),
                                ]
                              : [
                                  theme.primaryChartColor,
                                  theme.primaryChartColor.withOpacity(0.8),
                                ],
                        ),
                        borderRadius: theme.barChartBorderRadius,
                        boxShadow: isExecutive
                            ? [
                                BoxShadow(
                                  color: theme.primaryChartColor.withOpacity(0.2),
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Hour label with better styling
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: isExecutive
                          ? BoxDecoration(
                              color: const Color(0xFF1E2430),
                              borderRadius: BorderRadius.circular(4),
                            )
                          : null,
                      child: Text(
                        hour,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isExecutive ? FontWeight.bold : FontWeight.normal,
                          color: theme.textColor.withOpacity(isExecutive ? 0.9 : 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
} 