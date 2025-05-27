import 'package:flutter/material.dart';
import '../../models/game_state.dart';
import '../../themes/stats_themes.dart';
import '../../utils/number_formatter.dart';

/// Utility class for shared stats screen functionality
class StatsUtils {
  /// Builds a consistent stat row with icon across all stats components
  static Widget buildStatRowWithIcon(
    String label, 
    String value, 
    IconData icon, 
    Color iconColor, 
    StatsTheme theme
  ) {
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

  /// Calculates time played in a consistent format
  static String calculateTimePlayed(GameState gameState) {
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

  /// Builds a breakdown segment for charts
  static Widget buildBreakdownSegment(double percent, Color color, bool isExecutive) {
    // Handle zero percentage gracefully
    if (percent <= 0) return const SizedBox.shrink();
    
    return Flexible(
      flex: (percent * 100).round().clamp(1, 100), // Ensure at least 1 flex for visibility, max 100
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

  /// Builds an enhanced legend item for charts
  static Widget buildEnhancedLegendItem(Color color, String label, StatsTheme theme) {
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
