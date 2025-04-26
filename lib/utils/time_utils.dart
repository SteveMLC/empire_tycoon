import 'package:intl/intl.dart';

/// Utility class for date and time operations
class TimeUtils {
  /// Format time for display (e.g., "3:45 PM")
  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }
  
  /// Format date for display (e.g., "Jan 15, 2025")
  static String formatDate(DateTime dateTime) {
    return DateFormat('MMM d, y').format(dateTime);
  }
  
  /// Format date and time for display (e.g., "Jan 15, 2025 at 3:45 PM")
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, y \'at\' h:mm a').format(dateTime);
  }
  
  /// Calculate the time difference between two dates in a human-readable format
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'just now';
    }
  }
  
  /// Get the remaining time as a formatted string (e.g., "3h 45m")
  static String remainingTime(DateTime endTime) {
    final now = DateTime.now();
    final difference = endTime.difference(now);
    
    if (difference.isNegative) {
      return 'expired';
    }
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ${difference.inSeconds % 60}s';
    } else {
      return '${difference.inSeconds}s';
    }
  }
  
  /// Get a standardized day key in the format 'yyyy-MM-dd' for storing daily data
  static String getDayKey(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  /// Get hour key in YYYY-MM-DD-HH format
  static String getHourKey(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd-HH').format(dateTime);
  }

  /// Finds the next occurrence of a specific weekday starting from the given date.
  /// Example: findNextWeekday(DateTime.now(), DateTime.monday) finds the next Monday.
  static DateTime findNextWeekday(DateTime startDate, int targetWeekday) {
    // Normalize targetWeekday to be between 1 (Monday) and 7 (Sunday)
    if (targetWeekday < 1 || targetWeekday > 7) {
      throw ArgumentError('targetWeekday must be between 1 and 7');
    }

    DateTime currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    int daysToAdd = targetWeekday - currentDate.weekday;
    if (daysToAdd <= 0) { // If it's today or already passed this week
      daysToAdd += 7;
    }
    return currentDate.add(Duration(days: daysToAdd));
  }
}