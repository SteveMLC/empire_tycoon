import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/game_state.dart';
import '../models/leaderboard_entry.dart';

/// Service for managing global leaderboard submissions and queries.
/// 
/// Uses Firebase Firestore for data storage and Cloud Functions for
/// server-side validation and ranking calculations.
class LeaderboardService {
  static final LeaderboardService _instance = LeaderboardService._internal();
  factory LeaderboardService() => _instance;
  LeaderboardService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Throttle submissions to prevent spam
  DateTime? _lastSubmission;
  static const _submissionCooldown = Duration(minutes: 1);

  // Periodic submission interval during gameplay
  static const _periodicSubmissionInterval = Duration(minutes: 5);
  DateTime? _lastPeriodicSubmission;

  // Cache for player rank to avoid excessive reads
  final Map<String, PlayerRankResult> _rankCache = {};
  DateTime? _rankCacheTime;
  static const _rankCacheDuration = Duration(minutes: 2);

  /// Get the current player's ID (Firebase UID or generated anonymous ID)
  String? get currentPlayerId => _auth.currentUser?.uid;

  /// Check if the user is authenticated and can submit scores
  bool get canSubmitScores => _auth.currentUser != null;

  /// Submit current game scores to the leaderboard.
  /// 
  /// Performs validation and submits to Firebase Cloud Functions for
  /// server-side verification before writing to Firestore.
  Future<SubmitScoresResult> submitScores(GameState gameState) async {
    // Check authentication
    if (!canSubmitScores) {
      return const SubmitScoresResult(
        success: false,
        error: 'Not authenticated. Please sign in to submit scores.',
      );
    }

    // Throttle check
    if (_lastSubmission != null &&
        DateTime.now().difference(_lastSubmission!) < _submissionCooldown) {
      final remaining = _submissionCooldown - DateTime.now().difference(_lastSubmission!);
      return SubmitScoresResult(
        success: false,
        error: 'Please wait ${remaining.inSeconds}s before submitting again.',
      );
    }

    try {
      // Extract stats from game state
      final stats = _extractStats(gameState);
      final tycoonRanking = calculateTycoonRanking(stats);

      // Build display name
      final displayName = gameState.googlePlayDisplayName ??
          gameState.username ??
          'Tycoon#${currentPlayerId.hashCode.abs() % 100000}';

      final callable = _functions.httpsCallable('submitLeaderboardScores');
      final result = await callable.call({
        'playerId': currentPlayerId,
        'displayName': displayName,
        'avatarUrl': gameState.googlePlayAvatarUrl ?? gameState.userAvatar,
        'scores': {
          'netWorth': stats.netWorth,
          'achievements': stats.achievements,
          'businesses': stats.businessesOwned,
          'upgrades': stats.upgradesPurchased,
          'reincorporations': stats.reincorporations,
          'tycoonRanking': tycoonRanking,
        },
        'stats': {
          'lifetimeTaps': stats.lifetimeTaps,
          'eventsResolved': stats.eventsResolved,
          'propertiesOwned': stats.propertiesOwned,
        },
        'gameVersion': '1.0.1', // TODO: Get from package_info
        'checksum': _generateChecksum(stats),
      });

      _lastSubmission = DateTime.now();
      _invalidateRankCache();

      return SubmitScoresResult.fromMap(Map<String, dynamic>.from(result.data));
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Leaderboard submission error: ${e.code} - ${e.message}');
      return SubmitScoresResult(
        success: false,
        error: e.message ?? 'Failed to submit scores. Please try again.',
      );
    } catch (e) {
      debugPrint('Leaderboard submission error: $e');
      return const SubmitScoresResult(
        success: false,
        error: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Submit score for a specific category (used for event triggers)
  Future<SubmitScoresResult> submitScore({
    required LeaderboardCategory category,
    required double score,
    required String playerId,
    String? displayName,
  }) async {
    if (!canSubmitScores) {
      return const SubmitScoresResult(
        success: false,
        error: 'Not authenticated.',
      );
    }

    try {
      final callable = _functions.httpsCallable('submitCategoryScore');
      final result = await callable.call({
        'category': category.id,
        'score': score,
        'playerId': playerId,
        'displayName': displayName ?? 'Tycoon#${playerId.hashCode.abs() % 100000}',
      });

      _invalidateRankCache();
      return SubmitScoresResult.fromMap(Map<String, dynamic>.from(result.data));
    } catch (e) {
      debugPrint('Category score submission error: $e');
      return const SubmitScoresResult(
        success: false,
        error: 'Failed to submit score.',
      );
    }
  }

  /// Get leaderboard entries for a category.
  Future<LeaderboardResult> getTopScores({
    required LeaderboardCategory category,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // For simple reads, we can query Firestore directly
      final snapshot = await _firestore
          .collection('leaderboards')
          .doc(category.id)
          .collection('entries')
          .orderBy('score', descending: true)
          .limit(limit)
          .get();

      final entries = snapshot.docs
          .asMap()
          .entries
          .map((e) {
            final entry = LeaderboardEntry.fromFirestore(e.value);
            // Calculate rank based on position if not set
            return LeaderboardEntry(
              playerId: entry.playerId,
              displayName: entry.displayName,
              avatarUrl: entry.avatarUrl,
              score: entry.score,
              rank: entry.rank > 0 ? entry.rank : offset + e.key + 1,
              percentile: entry.percentile,
              updatedAt: entry.updatedAt,
              tier: entry.tier,
              metadata: entry.metadata,
            );
          })
          .toList();

      // Get current player's rank if authenticated
      int? playerRank;
      double? playerPercentile;
      if (canSubmitScores) {
        final rankResult = await getPlayerRank(category);
        playerRank = rankResult.rank;
        playerPercentile = rankResult.percentile;
      }

      return LeaderboardResult(
        entries: entries,
        totalPlayers: snapshot.docs.length,
        playerRank: playerRank,
        playerPercentile: playerPercentile,
      );
    } catch (e) {
      debugPrint('Get leaderboard error: $e');
      return const LeaderboardResult(
        entries: [],
        error: 'Failed to load leaderboard. Please try again.',
      );
    }
  }

  /// Get the current player's rank in a category.
  Future<PlayerRankResult> getPlayerRank(LeaderboardCategory category) async {
    if (!canSubmitScores) {
      return const PlayerRankResult(
        rank: 0,
        percentile: 0,
        error: 'Not authenticated.',
      );
    }

    // Check cache
    final cacheKey = '${category.id}_$currentPlayerId';
    if (_rankCacheTime != null &&
        DateTime.now().difference(_rankCacheTime!) < _rankCacheDuration &&
        _rankCache.containsKey(cacheKey)) {
      return _rankCache[cacheKey]!;
    }

    try {
      final callable = _functions.httpsCallable('getPlayerRank');
      final result = await callable.call({
        'category': category.id,
        'playerId': currentPlayerId,
      });

      final rankResult = PlayerRankResult.fromMap(
        Map<String, dynamic>.from(result.data),
      );

      // Update cache
      _rankCache[cacheKey] = rankResult;
      _rankCacheTime = DateTime.now();

      return rankResult;
    } catch (e) {
      debugPrint('Get player rank error: $e');
      return const PlayerRankResult(
        rank: 0,
        percentile: 0.0,
        error: 'Failed to get rank.',
      );
    }
  }

  /// Get comprehensive player stats across all categories
  Future<Map<String, PlayerRankResult>> getPlayerStats(String playerId) async {
    final results = <String, PlayerRankResult>{};

    for (final category in LeaderboardCategory.values) {
      results[category.id] = await getPlayerRank(category);
    }

    return results;
  }

  /// Subscribe to real-time leaderboard updates (top N players)
  Stream<List<LeaderboardEntry>> watchTopPlayers({
    required LeaderboardCategory category,
    int limit = 10,
  }) {
    return _firestore
        .collection('leaderboards')
        .doc(category.id)
        .collection('entries')
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.asMap().entries.map((e) {
            final entry = LeaderboardEntry.fromFirestore(e.value);
            return LeaderboardEntry(
              playerId: entry.playerId,
              displayName: entry.displayName,
              avatarUrl: entry.avatarUrl,
              score: entry.score,
              rank: entry.rank > 0 ? entry.rank : e.key + 1,
              percentile: entry.percentile,
              updatedAt: entry.updatedAt,
              tier: entry.tier,
              metadata: entry.metadata,
            );
          }).toList();
        });
  }

  /// Check if periodic submission is due and submit if needed.
  /// 
  /// Should be called during game loop update. Handles throttling internally.
  Future<void> maybeSubmitPeriodic(GameState gameState) async {
    if (!canSubmitScores) return;

    final now = DateTime.now();
    if (_lastPeriodicSubmission != null &&
        now.difference(_lastPeriodicSubmission!) < _periodicSubmissionInterval) {
      return;
    }

    _lastPeriodicSubmission = now;
    await submitScores(gameState);
  }

  /// Submit scores immediately on significant events.
  /// 
  /// Bypasses the periodic throttle but still respects the minimum cooldown.
  Future<SubmitScoresResult> submitOnEvent(GameState gameState) async {
    return submitScores(gameState);
  }

  /// Calculate the composite Tycoon Ranking score.
  /// 
  /// Uses a weighted formula that rewards balanced progression across
  /// all game aspects.
  double calculateTycoonRanking(PlayerStatsSnapshot stats) {
    // Normalize each stat to 0-100 scale
    final netWorthScore = _normalizeLogScale(
      stats.netWorth,
      min: 1000,
      max: 1e15, // $1K to $1 Quadrillion
    );

    final achievementScore = stats.totalAchievements > 0
        ? (stats.achievements / stats.totalAchievements) * 100
        : 0.0;

    final businessScore = stats.maxBusinesses > 0
        ? (stats.businessesOwned / stats.maxBusinesses) * 100
        : 0.0;

    final upgradeScore = _normalizeLogScale(
      stats.upgradesPurchased.toDouble(),
      min: 1,
      max: 2000,
    );

    final reincorporationScore = (stats.reincorporations / 9) * 100; // 9 max levels

    final propertyScore = _normalizeLogScale(
      stats.propertiesOwned.toDouble(),
      min: 1,
      max: 200,
    );

    final eventScore = _normalizeLogScale(
      stats.eventsResolved.toDouble(),
      min: 1,
      max: 1000,
    );

    // Weighted composite (total = 100%)
    return (netWorthScore * 0.30) + // 30% - Primary metric
        (achievementScore * 0.20) + // 20% - Completionist
        (reincorporationScore * 0.15) + // 15% - Prestige
        (businessScore * 0.10) + // 10% - Business empire
        (upgradeScore * 0.10) + // 10% - Property improvements
        (propertyScore * 0.10) + // 10% - Real estate
        (eventScore * 0.05); // 5%  - Crisis management
  }

  /// Get tier based on Tycoon Ranking score
  String getTierFromScore(double score) {
    if (score >= 90) return 'platinum';
    if (score >= 75) return 'gold';
    if (score >= 50) return 'silver';
    if (score >= 25) return 'bronze';
    return 'startup';
  }

  /// Extract stats from GameState into a snapshot
  PlayerStatsSnapshot _extractStats(GameState gameState) {
    return PlayerStatsSnapshot(
      netWorth: gameState.totalLifetimeNetWorth,
      achievements: gameState.achievementManager.getCompletedAchievements().length,
      totalAchievements: 50, // TODO: Get from achievement definitions
      businessesOwned: gameState.businesses.where((b) => b.level > 0).length,
      maxBusinesses: 11, // 10 standard + Platinum Venture
      upgradesPurchased: gameState.totalRealEstateUpgradesPurchased,
      reincorporations: gameState.totalReincorporations,
      lifetimeTaps: gameState.lifetimeTaps,
      eventsResolved: gameState.totalEventsResolved,
      propertiesOwned: gameState.getTotalOwnedProperties(),
    );
  }

  /// Normalize value to 0-100 using logarithmic scale
  double _normalizeLogScale(double value, {required double min, required double max}) {
    if (value <= min) return 0;
    if (value >= max) return 100;
    return (log(value) - log(min)) / (log(max) - log(min)) * 100;
  }

  /// Generate a simple checksum for basic client-side validation
  String _generateChecksum(PlayerStatsSnapshot stats) {
    // Simple checksum - real validation happens server-side
    final data = '${stats.netWorth.toInt()}'
        '${stats.reincorporations}'
        '${stats.lifetimeTaps}'
        '${stats.achievements}';
    return data.hashCode.toRadixString(16);
  }

  /// Invalidate the rank cache
  void _invalidateRankCache() {
    _rankCache.clear();
    _rankCacheTime = null;
  }
}
