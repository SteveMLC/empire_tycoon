import 'package:intl/intl.dart';

class NumberFormatter {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );
  
  static final NumberFormat _compactFormat = NumberFormat.compact(
    locale: 'en_US',
  );
  
  /// Format a number as currency with dollar sign
  /// Example: formatCurrency(1234.56) => "$1,234.56"
  static String formatCurrency(double value) {
    // Always use full currency format with $ symbol, never compact
    return _currencyFormat.format(value);
  }
  
  /// Format a number in compact notation for large numbers
  /// Example: formatCompact(1234567) => "$1.2M"
  static String formatCompact(double value) {
    return _compactFormat.format(value);
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
}