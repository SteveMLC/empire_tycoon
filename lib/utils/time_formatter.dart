class TimeFormatter {
  // Formats a Duration into a human-readable string like "1h 15m 30s" or "45m 10s" or "25s"
  static String formatDuration(Duration duration) {
    if (duration.inSeconds <= 0) {
      return "0s";
    }

    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);

    List<String> parts = [];
    if (hours > 0) {
      parts.add('${hours}h');
    }
    if (minutes > 0 || (hours > 0 && seconds == 0)) { // Show minutes if > 0, or if hours exist and seconds are 0
      parts.add('${minutes}m');
    }
    if (seconds > 0 || (hours == 0 && minutes == 0)) { // Show seconds if > 0, or if it's the only unit
      parts.add('${seconds}s');
    }

    return parts.join(' ');
  }
} 