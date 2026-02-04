/// Configuration and conversion for Google Play "Highest Net Worth" leaderboard.
/// Leaderboard is Currency (USD); scores are 1/1,000,000th of the main currency unit.
class LeaderboardConfig {
  static const String highestNetWorthIdAndroid = 'CgkI9ImIie0UEAIQAg';
  static const String? highestNetWorthIdIos = null; // Add when Game Center is ready

  /// Submission formula: multiply dollar amount by 1,000,000 before submitting.
  /// Examples: $1.00 → 1,000,000; $19.95 → 19,950,000.
  /// Play Games Services formats the long on the device (e.g. $ and decimals by locale).
  static int toLeaderboardScore(double dollars) {
    if (!dollars.isFinite || dollars < 0) return 0;
    final product = dollars * 1000000;
    if (!product.isFinite) return 0;
    return product.round().clamp(0, 9223372036854775807);
  }
}
