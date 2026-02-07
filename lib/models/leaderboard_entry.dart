import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single entry in a leaderboard category
class LeaderboardEntry {
  final String playerId;
  final String displayName;
  final String? avatarUrl;
  final double score;
  final int rank;
  final double percentile;
  final DateTime updatedAt;
  final String tier;
  final Map<String, dynamic>? metadata;

  const LeaderboardEntry({
    required this.playerId,
    required this.displayName,
    this.avatarUrl,
    required this.score,
    required this.rank,
    required this.percentile,
    required this.updatedAt,
    required this.tier,
    this.metadata,
  });

  /// Creates a LeaderboardEntry from a Firestore document
  factory LeaderboardEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeaderboardEntry(
      playerId: data['playerId'] as String? ?? doc.id,
      displayName: data['displayName'] as String? ?? 'Anonymous Tycoon',
      avatarUrl: data['avatarUrl'] as String?,
      score: (data['score'] as num?)?.toDouble() ?? 0.0,
      rank: data['rank'] as int? ?? 0,
      percentile: (data['percentile'] as num?)?.toDouble() ?? 0.0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tier: data['tier'] as String? ?? 'startup',
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Creates a LeaderboardEntry from a Cloud Function response map
  factory LeaderboardEntry.fromMap(Map<String, dynamic> data) {
    return LeaderboardEntry(
      playerId: data['playerId'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'Anonymous Tycoon',
      avatarUrl: data['avatarUrl'] as String?,
      score: (data['score'] as num?)?.toDouble() ?? 0.0,
      rank: data['rank'] as int? ?? 0,
      percentile: (data['percentile'] as num?)?.toDouble() ?? 0.0,
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'] as String)
          : DateTime.now(),
      tier: data['tier'] as String? ?? 'startup',
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Converts entry to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'playerId': playerId,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'score': score,
      'rank': rank,
      'percentile': percentile,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'tier': tier,
      'metadata': metadata,
    };
  }

  /// Get the tier badge emoji
  String get tierBadge {
    switch (tier) {
      case 'platinum':
        return '💎';
      case 'gold':
        return '🥇';
      case 'silver':
        return '🥈';
      case 'bronze':
        return '🥉';
      case 'startup':
      default:
        return '🌱';
    }
  }

  /// Get a display-friendly tier name
  String get tierDisplayName {
    switch (tier) {
      case 'platinum':
        return 'Platinum Mogul';
      case 'gold':
        return 'Gold Tycoon';
      case 'silver':
        return 'Silver Baron';
      case 'bronze':
        return 'Bronze Entrepreneur';
      case 'startup':
      default:
        return 'Startup Founder';
    }
  }
}

/// Result of submitting scores to the leaderboard
class SubmitScoresResult {
  final bool success;
  final double? tycoonRanking;
  final double? percentile;
  final Map<String, int>? ranks;
  final String? error;

  const SubmitScoresResult({
    required this.success,
    this.tycoonRanking,
    this.percentile,
    this.ranks,
    this.error,
  });

  factory SubmitScoresResult.fromMap(Map<String, dynamic> data) {
    return SubmitScoresResult(
      success: data['success'] as bool? ?? false,
      tycoonRanking: (data['tycoonRanking'] as num?)?.toDouble(),
      percentile: (data['percentile'] as num?)?.toDouble(),
      ranks: data['ranks'] != null
          ? Map<String, int>.from(data['ranks'] as Map)
          : null,
      error: data['error'] as String?,
    );
  }
}

/// Result of fetching a leaderboard
class LeaderboardResult {
  final List<LeaderboardEntry> entries;
  final int totalPlayers;
  final int? playerRank;
  final double? playerPercentile;
  final String? error;

  const LeaderboardResult({
    required this.entries,
    this.totalPlayers = 0,
    this.playerRank,
    this.playerPercentile,
    this.error,
  });

  factory LeaderboardResult.fromMap(Map<String, dynamic> data) {
    final entriesData = data['entries'] as List<dynamic>? ?? [];
    return LeaderboardResult(
      entries: entriesData
          .map((e) => LeaderboardEntry.fromMap(e as Map<String, dynamic>))
          .toList(),
      totalPlayers: data['totalPlayers'] as int? ?? 0,
      playerRank: data['playerRank'] as int?,
      playerPercentile: (data['playerPercentile'] as num?)?.toDouble(),
      error: data['error'] as String?,
    );
  }
}

/// Result of getting player rank
class PlayerRankResult {
  final int rank;
  final double percentile;
  final double score;
  final List<LeaderboardEntry> nearbyPlayers;
  final String? error;

  const PlayerRankResult({
    required this.rank,
    required this.percentile,
    this.score = 0.0,
    this.nearbyPlayers = const [],
    this.error,
  });

  factory PlayerRankResult.fromMap(Map<String, dynamic> data) {
    final nearbyData = data['nearbyPlayers'] as List<dynamic>? ?? [];
    return PlayerRankResult(
      rank: data['rank'] as int? ?? 0,
      percentile: (data['percentile'] as num?)?.toDouble() ?? 0.0,
      score: (data['score'] as num?)?.toDouble() ?? 0.0,
      nearbyPlayers: nearbyData
          .map((e) => LeaderboardEntry.fromMap(e as Map<String, dynamic>))
          .toList(),
      error: data['error'] as String?,
    );
  }
}

/// Categories for leaderboards
enum LeaderboardCategory {
  netWorth('NET_WORTH'),
  achievements('ACHIEVEMENTS_COUNT'),
  businessesOwned('BUSINESSES_OWNED'),
  upgradesPurchased('UPGRADES_PURCHASED'),
  reincarnations('REINCARNATIONS'),
  tycoonRanking('TYCOON_RANKING');

  final String id;
  const LeaderboardCategory(this.id);

  String get displayName {
    switch (this) {
      case LeaderboardCategory.netWorth:
        return 'Lifetime Net Worth';
      case LeaderboardCategory.achievements:
        return 'Total Achievements';
      case LeaderboardCategory.businessesOwned:
        return 'Businesses Owned';
      case LeaderboardCategory.upgradesPurchased:
        return 'Total Upgrades';
      case LeaderboardCategory.reincarnations:
        return 'Reincorporations';
      case LeaderboardCategory.tycoonRanking:
        return 'Tycoon Ranking';
    }
  }

  String get icon {
    switch (this) {
      case LeaderboardCategory.netWorth:
        return '💰';
      case LeaderboardCategory.achievements:
        return '🏆';
      case LeaderboardCategory.businessesOwned:
        return '🏢';
      case LeaderboardCategory.upgradesPurchased:
        return '⬆️';
      case LeaderboardCategory.reincarnations:
        return '🔄';
      case LeaderboardCategory.tycoonRanking:
        return '👑';
    }
  }
}

/// Player stats snapshot for leaderboard submission
class PlayerStatsSnapshot {
  final double netWorth;
  final int achievements;
  final int totalAchievements;
  final int businessesOwned;
  final int maxBusinesses;
  final int upgradesPurchased;
  final int reincorporations;
  final int lifetimeTaps;
  final int eventsResolved;
  final int propertiesOwned;

  const PlayerStatsSnapshot({
    required this.netWorth,
    required this.achievements,
    required this.totalAchievements,
    required this.businessesOwned,
    required this.maxBusinesses,
    required this.upgradesPurchased,
    required this.reincorporations,
    required this.lifetimeTaps,
    required this.eventsResolved,
    required this.propertiesOwned,
  });

  Map<String, dynamic> toMap() {
    return {
      'netWorth': netWorth,
      'achievements': achievements,
      'totalAchievements': totalAchievements,
      'businessesOwned': businessesOwned,
      'maxBusinesses': maxBusinesses,
      'upgradesPurchased': upgradesPurchased,
      'reincorporations': reincorporations,
      'lifetimeTaps': lifetimeTaps,
      'eventsResolved': eventsResolved,
      'propertiesOwned': propertiesOwned,
    };
  }
}
