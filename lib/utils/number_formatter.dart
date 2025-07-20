import 'package:intl/intl.dart';

/// Centralized formatting utility for all number and time formatting in the app
/// This eliminates duplication of formatting logic across the codebase
class NumberFormatter {
  // Static formatters for consistent formatting across the app
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );
  
  static final NumberFormat _compactFormat = NumberFormat.compact(
    locale: 'en_US',
  );
  
  static final NumberFormat _intFormat = NumberFormat.decimalPattern('en_US');
  
  /// Format a number as currency with dollar sign
  /// Example: formatCurrency(1234.56) => "$1,234.56"
  static String formatCurrency(double amount) {
    if (amount == 0) {
      return "\$0.00";
    }
    
    // Handle negative numbers
    bool isNegative = amount < 0;
    amount = amount.abs();
    
    // Always use full number format with commas
    String formattedAmount = _currencyFormat.format(amount);
    
    // Add negative sign if needed
    return isNegative ? "-$formattedAmount" : formattedAmount;
  }
  
  /// Format a number as currency with more precision for low-priced investments
  /// Shows up to 6 decimal places for amounts less than $1
  /// Example: formatCurrencyPrecise(0.001234) => "$0.001234"
  static String formatCurrencyPrecise(double amount) {
    if (amount == 0) {
      return "\$0.00";
    }
    
    // Handle negative numbers
    bool isNegative = amount < 0;
    amount = amount.abs();
    
    String formattedAmount;
    
    if (amount < 1.0) {
      // For amounts less than $1, show up to 6 decimal places, removing trailing zeros
      formattedAmount = "\$${amount.toStringAsFixed(6)}";
      // Remove trailing zeros after the decimal point
      formattedAmount = formattedAmount.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '.00');
    } else {
      // For amounts $1 and above, use standard currency formatting
      formattedAmount = _currencyFormat.format(amount);
    }
    
    // Add negative sign if needed
    return isNegative ? "-$formattedAmount" : formattedAmount;
  }
  
  /// Format a number in compact notation for large numbers
  /// Example: formatCompact(1234567) => "$1.2M"
  static String formatCompact(double value) {
    return _compactFormat.format(value);
  }
  
  /// Format an integer with commas
  /// Example: formatInt(1234567) => "1,234,567"
  static String formatInt(int value) {
    return _intFormat.format(value);
  }
  
  /// Format a percentage value with % sign
  /// Example: formatPercent(0.123) => "12.3%"
  static String formatPercent(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }
  
  /// Format a time duration in days, hours, minutes, or seconds
  /// Example: formatTime(3665) => "1h 1m 5s"
  static String formatTime(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      int minutes = seconds ~/ 60;
      int remainingSeconds = seconds % 60;
      return '${minutes}m ${remainingSeconds}s';
    } else if (seconds < 86400) {
      int hours = seconds ~/ 3600;
      int minutes = (seconds % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    } else {
      int days = seconds ~/ 86400;
      int hours = (seconds % 86400) ~/ 3600;
      return '${days}d ${hours}h';
    }
  }
  
  /// Format a boost time remaining (for UI display)
  /// Example: formatBoostTimeRemaining(Duration(minutes: 5, seconds: 30)) => "5m 30s"
  static String formatBoostTimeRemaining(Duration remaining) {
    final seconds = remaining.inSeconds;
    return formatTime(seconds);
  }
  
  /// Format a large number with appropriate suffix (K, M, B, T)
  /// Consolidates the duplicate formatLargeNumber implementations
  /// Example: formatLargeNumber(1234567) => "$1.2M"
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
  
  /// Format a multiplier value with 'x' suffix
  /// Example: formatMultiplier(1.25) => "1.25x"
  static String formatMultiplier(double value, {int decimalPlaces = 2}) {
    return '${value.toStringAsFixed(decimalPlaces)}x';
  }
  
  /// Format a time interval for display
  /// Consolidates duplicate _formatTimeInterval implementations
  static String formatTimeInterval(int seconds) {
    return formatTime(seconds);
  }
}