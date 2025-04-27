import 'package:intl/intl.dart';

class NumberFormatter {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );
  
  static final NumberFormat _compactFormat = NumberFormat.compact(
    locale: 'en_US',
  );
  
  // Added: Format for integers with commas
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
  
  /// Format a number in compact notation for large numbers
  /// Example: formatCompact(1234567) => "$1.2M"
  static String formatCompact(double value) {
    return _compactFormat.format(value);
  }
  
  /// Added: Format an integer with commas
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
}