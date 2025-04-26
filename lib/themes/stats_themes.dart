import 'package:flutter/material.dart';

/// Class defining a theme for the stats screen
class StatsTheme {
  final String id;
  final String name;
  final bool premium;
  
  // Colors
  final Color backgroundColor;
  final Color cardBackgroundColor;
  final Color cardBorderColor;
  final Color textColor;
  final Color titleColor;
  final Color valueColor;
  
  // Chart colors
  final Color primaryChartColor;
  final Color secondaryChartColor;
  final Color tertiaryChartColor;
  final Color quaternaryChartColor;
  final List<Color> chartGradient;
  
  // Style properties
  final double borderRadius;
  final EdgeInsets padding;
  final double elevation;
  final BorderRadius barChartBorderRadius;
  final BoxShadow? cardShadow;
  final TextStyle titleStyle;
  final TextStyle cardTitleStyle;
  final TextStyle statLabelStyle;
  final TextStyle statValueStyle;
  
  const StatsTheme({
    required this.id,
    required this.name,
    this.premium = false,
    required this.backgroundColor,
    required this.cardBackgroundColor,
    required this.cardBorderColor,
    required this.textColor,
    required this.titleColor,
    required this.valueColor,
    required this.primaryChartColor,
    required this.secondaryChartColor,
    required this.tertiaryChartColor,
    required this.quaternaryChartColor,
    required this.chartGradient,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16.0),
    this.elevation = 4.0,
    this.barChartBorderRadius = const BorderRadius.only(
      topLeft: Radius.circular(4),
      topRight: Radius.circular(4),
    ),
    this.cardShadow,
    required this.titleStyle,
    required this.cardTitleStyle,
    required this.statLabelStyle,
    required this.statValueStyle,
  });
}

/// Default theme matching the existing app style
final defaultStatsTheme = StatsTheme(
  id: 'default',
  name: 'Default',
  premium: false,
  backgroundColor: Colors.grey[100]!,
  cardBackgroundColor: Colors.white,
  cardBorderColor: Colors.transparent,
  textColor: Colors.black87,
  titleColor: Colors.black,
  valueColor: Colors.black87,
  
  primaryChartColor: Colors.blue,
  secondaryChartColor: Colors.green,
  tertiaryChartColor: Colors.orange,
  quaternaryChartColor: Colors.red,
  chartGradient: [Colors.blue.shade700, Colors.blue.shade300],
  
  titleStyle: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
  cardTitleStyle: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
  statLabelStyle: const TextStyle(),
  statValueStyle: const TextStyle(
    fontWeight: FontWeight.bold,
  ),
);

/// Executive theme with premium look and feel
final executiveStatsTheme = StatsTheme(
  id: 'executive',
  name: 'Executive',
  premium: true,
  backgroundColor: const Color(0xFF151822), // Darker, more premium background
  cardBackgroundColor: const Color(0xFF1E2430), // Richer dark card background
  cardBorderColor: const Color(0xFF2A3142), // Subtle border for depth
  textColor: Colors.white,
  titleColor: const Color(0xFFE5B100), // Slightly warmer gold for better readability
  valueColor: Colors.white,
  
  // Enhanced chart colors with better contrast
  primaryChartColor: const Color(0xFF4B9FFF), // Brighter blue
  secondaryChartColor: const Color(0xFF4CD97B), // Vibrant green
  tertiaryChartColor: const Color(0xFFFFB648), // Warm orange
  quaternaryChartColor: const Color(0xFFFF5D73), // Bold red
  chartGradient: [
    const Color(0xFF4B9FFF), 
    const Color(0xFF7B5BFF).withOpacity(0.8) // Rich purple gradient with slight transparency
  ],
  
  borderRadius: 16.0, // Slightly reduced for a more modern look
  padding: const EdgeInsets.all(20.0),
  elevation: 6.0, // Slight reduction in elevation
  barChartBorderRadius: const BorderRadius.only(
    topLeft: Radius.circular(6),
    topRight: Radius.circular(6),
  ),
  cardShadow: BoxShadow(
    color: Colors.black.withOpacity(0.25),
    blurRadius: 12,
    offset: const Offset(0, 4),
  ),
  
  titleStyle: const TextStyle(
    fontSize: 24, // Larger title for better hierarchy
    fontWeight: FontWeight.bold,
    color: Color(0xFFE5B100), // Match title color
    letterSpacing: 0.5,
  ),
  cardTitleStyle: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Color(0xFFE5B100), // Match title color
    letterSpacing: 0.5,
  ),
  statLabelStyle: const TextStyle(
    color: Color(0xFFCCCCDD), // Lighter gray with slight blue tint for better readability
    fontSize: 14,
  ),
  statValueStyle: const TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.white,
    fontSize: 16, // Slightly larger for better readability
  ),
);

/// Map of available themes
final Map<String, StatsTheme> statsThemes = {
  'default': defaultStatsTheme,
  'executive': executiveStatsTheme,
};

/// Get the current theme based on selection and unlock status
StatsTheme getStatsTheme(String? selectedTheme, bool isExecutiveThemeUnlocked) {
  if (selectedTheme == 'executive' && isExecutiveThemeUnlocked) {
    return executiveStatsTheme;
  }
  return defaultStatsTheme;
} 