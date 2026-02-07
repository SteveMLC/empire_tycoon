import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/review_prompt_dialog.dart';
import '../widgets/star_rating_dialog.dart';
import '../widgets/feedback_dialog.dart';

class ReviewManager {
  static final ReviewManager instance = ReviewManager._internal();
  factory ReviewManager() => instance;
  ReviewManager._internal();

  // Timing constraints
  static const Duration _minDelayBetweenPrompts = Duration(days: 30);
  static const int _minSessions = 3;
  static const int _minPlaytimeSeconds = 10 * 60;
  static const int _maxLifetimePrompts = 3;
  static const int _maxDismisses = 2;
  static const int _maxSessionSeconds = 6 * 60 * 60;

  // Level milestones that trigger review prompt consideration
  static const List<int> _levelMilestones = [10, 25, 50, 100];

  // Preference keys
  static const String _reviewLastAskedKey = 'review_last_asked';
  static const String _reviewTimesAskedKey = 'review_times_asked';
  static const String _reviewDismissedCountKey = 'review_dismissed_count';
  static const String _reviewCompletedKey = 'review_completed';
  static const String _reviewVersionAskedKey = 'review_version_asked';
  static const String _totalSessionsKey = 'review_total_sessions';
  static const String _totalPlaytimeSecondsKey = 'review_total_playtime_seconds';
  static const String _sessionStartKey = 'review_session_start_ms';
  static const String _neverShowAgainKey = 'review_never_show_again';
  static const String _lastMilestoneTriggeredKey = 'review_last_milestone_triggered';
  
  // Analytics keys
  static const String _analyticsReviewPromptedKey = 'analytics_review_prompted_count';
  static const String _analyticsReviewCompletedKey = 'analytics_review_completed_count';
  static const String _analyticsReviewRatingKey = 'analytics_review_last_rating';
  static const String _analyticsFeedbackSubmittedKey = 'analytics_feedback_submitted_count';

  static const String _currentVersionKey = 'empire_tycoon_version';

  bool _isShowing = false;
  Future<SharedPreferences>? _prefsFuture;

  Future<SharedPreferences> _prefs() {
    _prefsFuture ??= SharedPreferences.getInstance();
    return _prefsFuture!;
  }

  Future<void> initialize() async {
    await _prefs();
  }

  Future<void> onAppResumed() async {
    final prefs = await _prefs();
    final DateTime now = DateTime.now();
    final int? startMs = prefs.getInt(_sessionStartKey);
    if (startMs != null) {
      final DateTime start = DateTime.fromMillisecondsSinceEpoch(startMs);
      if (now.difference(start).inSeconds < 10) {
        return;
      }
      await _finalizeSessionIfActive(prefs, now);
    }

    final int sessions = prefs.getInt(_totalSessionsKey) ?? 0;
    await prefs.setInt(_totalSessionsKey, sessions + 1);
    await prefs.setInt(_sessionStartKey, now.millisecondsSinceEpoch);
  }

  Future<void> onAppPaused() async {
    final prefs = await _prefs();
    final DateTime now = DateTime.now();
    await _finalizeSessionIfActive(prefs, now);
  }

  Future<void> _finalizeSessionIfActive(SharedPreferences prefs, DateTime now) async {
    final int? startMs = prefs.getInt(_sessionStartKey);
    if (startMs == null) return;

    final DateTime start = DateTime.fromMillisecondsSinceEpoch(startMs);
    if (now.isBefore(start)) {
      await prefs.remove(_sessionStartKey);
      return;
    }

    int durationSeconds = now.difference(start).inSeconds;
    if (durationSeconds > _maxSessionSeconds) {
      durationSeconds = _maxSessionSeconds;
    }

    final int totalPlaytime = prefs.getInt(_totalPlaytimeSecondsKey) ?? 0;
    await prefs.setInt(_totalPlaytimeSecondsKey, totalPlaytime + durationSeconds);
    await prefs.remove(_sessionStartKey);
  }

  Future<bool> shouldShowReview() async {
    final prefs = await _prefs();

    // Check "Never show again" first
    if (prefs.getBool(_neverShowAgainKey) ?? false) return false;

    if (prefs.getBool(_reviewCompletedKey) ?? false) return false;

    final int dismissCount = prefs.getInt(_reviewDismissedCountKey) ?? 0;
    if (dismissCount >= _maxDismisses) return false;

    final int timesAsked = prefs.getInt(_reviewTimesAskedKey) ?? 0;
    if (timesAsked >= _maxLifetimePrompts) return false;

    final int? lastAskedMs = prefs.getInt(_reviewLastAskedKey);
    if (lastAskedMs != null) {
      final DateTime lastAsked = DateTime.fromMillisecondsSinceEpoch(lastAskedMs);
      if (DateTime.now().difference(lastAsked) < _minDelayBetweenPrompts) return false;
    }

    final String currentVersion = prefs.getString(_currentVersionKey) ?? 'unknown';
    final String? versionAsked = prefs.getString(_reviewVersionAskedKey);
    if (versionAsked == currentVersion) return false;

    final int sessions = prefs.getInt(_totalSessionsKey) ?? 0;
    if (sessions < _minSessions) return false;

    final int playtimeSeconds = prefs.getInt(_totalPlaytimeSecondsKey) ?? 0;
    if (playtimeSeconds < _minPlaytimeSeconds) return false;

    try {
      final bool available = await InAppReview.instance.isAvailable();
      if (!available) return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Review availability check failed: $e');
      }
      return false;
    }

    return true;
  }

  /// Check if a cumulative level is a milestone we should trigger on
  bool _isMilestone(int totalLevel) {
    return _levelMilestones.contains(totalLevel);
  }

  /// Called when any business levels up. Pass the total cumulative level across all businesses.
  void onTotalLevelMilestone(BuildContext context, {required int totalLevel}) {
    if (_isMilestone(totalLevel)) {
      unawaited(maybeShowReview(context: context, trigger: 'milestone_$totalLevel'));
    }
  }

  // Legacy method - kept for backward compatibility
  void onBusinessLevelUp(BuildContext context, {required int level, required String businessId}) {
    // Only trigger at business level 10 (max level achievement)
    if (level == 10) {
      unawaited(maybeShowReview(context: context, trigger: 'level_10:$businessId'));
    }
  }

  void onBusinessUnlocked(BuildContext context, {required int totalBusinesses}) {
    if (totalBusinesses == 5) {
      unawaited(maybeShowReview(context: context, trigger: 'unlock_5'));
    }
  }

  void onIncomeMultiplier(BuildContext context, {required double multiplier}) {
    if (multiplier >= 100.0) {
      unawaited(maybeShowReview(context: context, trigger: 'multiplier_100x'));
    }
  }

  Future<void> maybeShowReview({required BuildContext context, required String trigger}) async {
    if (_isShowing) return;
    if (!await shouldShowReview()) return;

    // Check if we've already triggered on this milestone
    final prefs = await _prefs();
    final int? lastMilestone = prefs.getInt(_lastMilestoneTriggeredKey);
    if (trigger.startsWith('milestone_')) {
      final int currentMilestone = int.tryParse(trigger.replaceFirst('milestone_', '')) ?? 0;
      if (lastMilestone != null && currentMilestone <= lastMilestone) {
        return; // Already triggered at this or higher milestone
      }
      await prefs.setInt(_lastMilestoneTriggeredKey, currentMilestone);
    }

    if (kDebugMode) {
      debugPrint('Review prompt trigger: $trigger');
    }
    _isShowing = true;
    final DateTime now = DateTime.now();
    final String currentVersion = prefs.getString(_currentVersionKey) ?? 'unknown';

    await prefs.setInt(_reviewLastAskedKey, now.millisecondsSinceEpoch);
    await prefs.setInt(_reviewTimesAskedKey, (prefs.getInt(_reviewTimesAskedKey) ?? 0) + 1);
    await prefs.setString(_reviewVersionAskedKey, currentVersion);

    // Track analytics: review prompted
    await _trackReviewPrompted();

    bool? result;
    try {
      result = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return ReviewPromptDialog(
            onLoveIt: () => Navigator.of(dialogContext).pop(true),
            onNotReally: () => Navigator.of(dialogContext).pop(false),
            onNeverShowAgain: () {
              _setNeverShowAgain();
              Navigator.of(dialogContext).pop(null);
            },
          );
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Review dialog failed to show: $e');
      }
    }

    if (result == true) {
      // User said they love it - now show star rating
      await _showStarRatingDialog(context);
    } else if (result == false) {
      // User said "Not Really" - show feedback form
      await _showFeedbackDialog(context);
      await _incrementDismiss();
    }
    // result == null means "Never show again" was clicked

    _isShowing = false;
  }

  Future<void> _showStarRatingDialog(BuildContext context) async {
    int? rating;
    try {
      rating = await showDialog<int>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return StarRatingDialog(
            onRatingSelected: (stars) => Navigator.of(dialogContext).pop(stars),
            onCancel: () => Navigator.of(dialogContext).pop(null),
          );
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Star rating dialog failed: $e');
      }
      return;
    }

    if (rating == null) {
      await _incrementDismiss();
      return;
    }

    // Track the rating
    await _trackRating(rating);

    if (rating >= 3) {
      // 3+ stars: redirect to app store
      await _handlePositiveResponse();
    } else {
      // < 3 stars: show feedback form instead
      if (context.mounted) {
        await _showFeedbackDialog(context);
      }
      await _incrementDismiss();
    }
  }

  Future<void> _showFeedbackDialog(BuildContext context) async {
    String? feedback;
    try {
      feedback = await showDialog<String>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return FeedbackDialog(
            onSubmit: (text) => Navigator.of(dialogContext).pop(text),
            onCancel: () => Navigator.of(dialogContext).pop(null),
          );
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Feedback dialog failed: $e');
      }
      return;
    }

    if (feedback != null && feedback.isNotEmpty) {
      await _trackFeedbackSubmitted();
      // Store feedback locally for now (could be sent to server later)
      final prefs = await _prefs();
      final List<String> feedbackList = prefs.getStringList('user_feedback') ?? [];
      feedbackList.add('${DateTime.now().toIso8601String()}: $feedback');
      await prefs.setStringList('user_feedback', feedbackList);
      
      if (kDebugMode) {
        debugPrint('User feedback stored: $feedback');
      }
    }
  }

  Future<void> _handlePositiveResponse() async {
    final prefs = await _prefs();
    try {
      await InAppReview.instance.requestReview();
      await prefs.setBool(_reviewCompletedKey, true);
      await _trackReviewCompleted();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Review request failed: $e');
      }
    }
  }

  Future<void> _incrementDismiss() async {
    final prefs = await _prefs();
    final int dismissCount = prefs.getInt(_reviewDismissedCountKey) ?? 0;
    await prefs.setInt(_reviewDismissedCountKey, dismissCount + 1);
  }

  Future<void> _setNeverShowAgain() async {
    final prefs = await _prefs();
    await prefs.setBool(_neverShowAgainKey, true);
  }

  // Analytics tracking methods
  Future<void> _trackReviewPrompted() async {
    final prefs = await _prefs();
    final int count = prefs.getInt(_analyticsReviewPromptedKey) ?? 0;
    await prefs.setInt(_analyticsReviewPromptedKey, count + 1);
    if (kDebugMode) {
      debugPrint('📊 Analytics: review_prompted (total: ${count + 1})');
    }
  }

  Future<void> _trackReviewCompleted() async {
    final prefs = await _prefs();
    final int count = prefs.getInt(_analyticsReviewCompletedKey) ?? 0;
    await prefs.setInt(_analyticsReviewCompletedKey, count + 1);
    if (kDebugMode) {
      debugPrint('📊 Analytics: review_completed (total: ${count + 1})');
    }
  }

  Future<void> _trackRating(int rating) async {
    final prefs = await _prefs();
    await prefs.setInt(_analyticsReviewRatingKey, rating);
    if (kDebugMode) {
      debugPrint('📊 Analytics: review_rating = $rating stars');
    }
  }

  Future<void> _trackFeedbackSubmitted() async {
    final prefs = await _prefs();
    final int count = prefs.getInt(_analyticsFeedbackSubmittedKey) ?? 0;
    await prefs.setInt(_analyticsFeedbackSubmittedKey, count + 1);
    if (kDebugMode) {
      debugPrint('📊 Analytics: feedback_submitted (total: ${count + 1})');
    }
  }

  /// Get review analytics for debugging/reporting
  Future<Map<String, dynamic>> getReviewAnalytics() async {
    final prefs = await _prefs();
    return {
      'review_prompted_count': prefs.getInt(_analyticsReviewPromptedKey) ?? 0,
      'review_completed_count': prefs.getInt(_analyticsReviewCompletedKey) ?? 0,
      'last_rating': prefs.getInt(_analyticsReviewRatingKey),
      'feedback_submitted_count': prefs.getInt(_analyticsFeedbackSubmittedKey) ?? 0,
      'never_show_again': prefs.getBool(_neverShowAgainKey) ?? false,
      'times_asked': prefs.getInt(_reviewTimesAskedKey) ?? 0,
      'times_dismissed': prefs.getInt(_reviewDismissedCountKey) ?? 0,
      'review_completed': prefs.getBool(_reviewCompletedKey) ?? false,
    };
  }
}
