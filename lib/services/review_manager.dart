import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/review_prompt_dialog.dart';

class ReviewManager {
  static final ReviewManager instance = ReviewManager._internal();
  factory ReviewManager() => instance;
  ReviewManager._internal();

  static const Duration _minDelayBetweenPrompts = Duration(days: 30);
  static const int _minSessions = 3;
  static const int _minPlaytimeSeconds = 10 * 60;
  static const int _maxLifetimePrompts = 3;
  static const int _maxDismisses = 2;
  static const int _maxSessionSeconds = 6 * 60 * 60;

  static const String _reviewLastAskedKey = 'review_last_asked';
  static const String _reviewTimesAskedKey = 'review_times_asked';
  static const String _reviewDismissedCountKey = 'review_dismissed_count';
  static const String _reviewCompletedKey = 'review_completed';
  static const String _reviewVersionAskedKey = 'review_version_asked';
  static const String _totalSessionsKey = 'review_total_sessions';
  static const String _totalPlaytimeSecondsKey = 'review_total_playtime_seconds';
  static const String _sessionStartKey = 'review_session_start_ms';

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

  void onBusinessLevelUp(BuildContext context, {required int level, required String businessId}) {
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

    if (kDebugMode) {
      debugPrint('Review prompt trigger: $trigger');
    }
    _isShowing = true;
    final prefs = await _prefs();
    final DateTime now = DateTime.now();
    final String currentVersion = prefs.getString(_currentVersionKey) ?? 'unknown';

    await prefs.setInt(_reviewLastAskedKey, now.millisecondsSinceEpoch);
    await prefs.setInt(_reviewTimesAskedKey, (prefs.getInt(_reviewTimesAskedKey) ?? 0) + 1);
    await prefs.setString(_reviewVersionAskedKey, currentVersion);

    bool? result;
    try {
      result = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return ReviewPromptDialog(
            onLoveIt: () => Navigator.of(dialogContext).pop(true),
            onNotReally: () => Navigator.of(dialogContext).pop(false),
          );
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Review dialog failed to show: $e');
      }
    }

    if (result == true) {
      await _handlePositiveResponse();
    } else {
      await _incrementDismiss();
    }

    _isShowing = false;
  }

  Future<void> _handlePositiveResponse() async {
    final prefs = await _prefs();
    try {
      await InAppReview.instance.requestReview();
      await prefs.setBool(_reviewCompletedKey, true);
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
}
