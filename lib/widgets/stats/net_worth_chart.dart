import 'package:flutter/material.dart';

import '../../models/game_state.dart';
import '../../themes/stats_themes.dart';
import '../../widgets/chart_painter.dart';

enum NetWorthViewMode {
  lifetime,
  currentRun,
}

class NetWorthChart extends StatefulWidget {
  final GameState gameState;
  final StatsTheme theme;

  const NetWorthChart({
    Key? key,
    required this.gameState,
    required this.theme,
  }) : super(key: key);

  @override
  State<NetWorthChart> createState() => _NetWorthChartState();
}

class _NetWorthChartState extends State<NetWorthChart> {
  NetWorthViewMode _viewMode = NetWorthViewMode.lifetime;

  @override
  Widget build(BuildContext context) {
    final gameState = widget.gameState;
    final theme = widget.theme;
    final bool isExecutive = theme.id == 'executive';

    final Map<int, double> sourceMap = _viewMode == NetWorthViewMode.lifetime
        ? gameState.persistentNetWorthHistory
        : gameState.runNetWorthHistory;

    final List<int> sortedTimestamps = sourceMap.keys.toList()..sort();
    final List<double> history = sortedTimestamps.map((ts) => sourceMap[ts]!).toList();

    final String titleText = _viewMode == NetWorthViewMode.lifetime
        ? 'Net Worth – Lifetime'
        : 'Net Worth – Current Run';

    return Card(
      elevation: theme.elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.borderRadius),
        side: BorderSide(
          color: isExecutive ? const Color(0xFF2A3142) : theme.cardBorderColor,
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
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.area_chart,
                        color: isExecutive ? theme.titleColor : Colors.blue.shade700,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          titleText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: isExecutive
                              ? theme.cardTitleStyle
                              : TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildViewToggle(isExecutive, theme),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _viewMode == NetWorthViewMode.lifetime
                  ? 'Includes all progress, even across reincorporations.'
                  : 'Only shows net worth growth since your last reincorporation.',
              style: TextStyle(
                fontSize: 11,
                color: theme.textColor.withOpacity(0.65),
              ),
            ),
            Divider(
              height: 30,
              thickness: 1,
              color: isExecutive ? const Color(0xFF2A3142) : Colors.blue.withOpacity(0.2),
            ),
            SizedBox(
              height: 200,
              child: history.isEmpty
                  ? _buildEmptyState(isExecutive, theme)
                  : _buildLineChart(history, theme),
            ),
            if (history.length >= 2) ...[
              const SizedBox(height: 8),
              _buildTimeAxisLabels(sortedTimestamps, theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle(bool isExecutive, StatsTheme theme) {
    Color _pillColor(bool active) {
      if (isExecutive) {
        return active ? const Color(0xFFE5B100) : const Color(0xFF242C3B);
      }
      return active ? theme.primaryChartColor : theme.backgroundColor.withOpacity(0.2);
    }

    Color _textColor(bool active) {
      if (isExecutive) {
        return active ? Colors.black : theme.textColor.withOpacity(0.8);
      }
      return active ? Colors.white : theme.textColor.withOpacity(0.9);
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isExecutive ? const Color(0xFF242C3B) : theme.backgroundColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExecutive ? const Color(0xFF2A3142) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTogglePill(
            label: 'Lifetime',
            isActive: _viewMode == NetWorthViewMode.lifetime,
            pillColor: _pillColor(_viewMode == NetWorthViewMode.lifetime),
            textColor: _textColor(_viewMode == NetWorthViewMode.lifetime),
            onTap: () {
              if (_viewMode != NetWorthViewMode.lifetime) {
                setState(() => _viewMode = NetWorthViewMode.lifetime);
              }
            },
          ),
          _buildTogglePill(
            label: 'Current Run',
            isActive: _viewMode == NetWorthViewMode.currentRun,
            pillColor: _pillColor(_viewMode == NetWorthViewMode.currentRun),
            textColor: _textColor(_viewMode == NetWorthViewMode.currentRun),
            onTap: () {
              if (_viewMode != NetWorthViewMode.currentRun) {
                setState(() => _viewMode = NetWorthViewMode.currentRun);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTogglePill({
    required String label,
    required bool isActive,
    required Color pillColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: pillColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isExecutive, StatsTheme theme) {
    return Center(
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
    );
  }

  Widget _buildTimeAxisLabels(List<int> timestamps, StatsTheme theme) {
    if (timestamps.length < 2) return const SizedBox.shrink();

    final DateTime start = DateTime.fromMillisecondsSinceEpoch(timestamps.first);
    final DateTime end = DateTime.fromMillisecondsSinceEpoch(timestamps.last);
    final Duration span = end.difference(start);

    String formatLabel(DateTime dt) {
      if (span.inDays >= 2) {
        return '${dt.month}/${dt.day}';
      }
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          formatLabel(start),
          style: TextStyle(
            fontSize: 10,
            color: theme.textColor.withOpacity(0.6),
          ),
        ),
        Text(
          formatLabel(end),
          style: TextStyle(
            fontSize: 10,
            color: theme.textColor.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart(List<double> data, StatsTheme theme) {
    if (data.length < 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Tracking started',
              style: TextStyle(
                color: theme.textColor.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Keep playing to see your net worth trend over time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
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