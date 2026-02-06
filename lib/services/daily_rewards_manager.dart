import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_reward.dart';
import '../models/game_state.dart';

class DailyRewardsManager {
  static final DailyRewardsManager _instance = DailyRewardsManager._internal();
  factory DailyRewardsManager() => _instance;
  DailyRewardsManager._internal();

  static const String _prefsKeyLastClaim = 'daily_rewards_last_claim_date_utc';
  static const String _prefsKeyCurrentStreak = 'daily_rewards_current_streak';
  static const String _prefsKeyTotalClaimed = 'daily_rewards_total_claimed';
  static const String _prefsKeyCycleCount = 'daily_rewards_cycle_count';

  static const int _cycleLength = 7;
  static const double _loyaltyCashMultiplier = 1.5;
  static const int _megaBoostMinutes = 15;

  final List<DailyReward> _baseRewards = const [
    DailyReward(
      day: 1,
      type: DailyRewardType.cash,
      value: 10,
      description: 'Welcome back!',
      icon: '💰',
    ),
    DailyReward(
      day: 2,
      type: DailyRewardType.cash,
      value: 15,
      description: 'Keep the momentum going!',
      icon: '💰',
    ),
    DailyReward(
      day: 3,
      type: DailyRewardType.boost,
      value: 5,
      description: '2x income boost',
      icon: '⚡',
    ),
    DailyReward(
      day: 4,
      type: DailyRewardType.cash,
      value: 30,
      description: 'Solid progress!',
      icon: '💰',
    ),
    DailyReward(
      day: 5,
      type: DailyRewardType.boost,
      value: 10,
      description: '2x income boost',
      icon: '⚡',
    ),
    DailyReward(
      day: 6,
      type: DailyRewardType.cash,
      value: 60,
      description: 'Almost there!',
      icon: '💰',
    ),
    DailyReward(
      day: 7,
      type: DailyRewardType.mega,
      value: 120,
      description: 'Perfect Week! Mega reward',
      icon: '🌟',
    ),
  ];

  DailyRewardsState _state = DailyRewardsState();
  bool _loaded = false;
  SharedPreferences? _prefs;
  DailyRewardCheckResult? _lastCheckResult;

  DailyRewardsState get state => _state;
  DailyRewardCheckResult? get lastCheckResult => _lastCheckResult;
  List<DailyReward> get rewards => List.unmodifiable(_baseRewards);

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _prefs = await SharedPreferences.getInstance();
    _state = _loadFromPrefs();
    _state.normalize();
    _loaded = true;
  }

  DailyRewardsState _loadFromPrefs() {
    final prefs = _prefs;
    if (prefs == null) {
      return DailyRewardsState();
    }

    DateTime? lastClaimDate;
    final String? rawDate = prefs.getString(_prefsKeyLastClaim);
    if (rawDate != null) {
      try {
        lastClaimDate = DateTime.parse(rawDate);
      } catch (_) {
        lastClaimDate = null;
      }
    }

    return DailyRewardsState(
      lastClaimDate: lastClaimDate,
      currentStreak: prefs.getInt(_prefsKeyCurrentStreak) ?? 1,
      totalDaysClaimed: prefs.getInt(_prefsKeyTotalClaimed) ?? 0,
      cycleCount: prefs.getInt(_prefsKeyCycleCount) ?? 0,
    );
  }

  Future<void> _saveToPrefs() async {
    final prefs = _prefs;
    if (prefs == null) return;

    if (_state.lastClaimDate != null) {
      await prefs.setString(_prefsKeyLastClaim, _state.lastClaimDate!.toIso8601String());
    } else {
      await prefs.remove(_prefsKeyLastClaim);
    }
    await prefs.setInt(_prefsKeyCurrentStreak, _state.currentStreak);
    await prefs.setInt(_prefsKeyTotalClaimed, _state.totalDaysClaimed);
    await prefs.setInt(_prefsKeyCycleCount, _state.cycleCount);
  }

  Future<void> hydrateFromGameState(GameState gameState) async {
    await _ensureLoaded();
    final DailyRewardsState fromGameState = gameState.dailyRewardsState;
    final DateTime? prefsDate = _state.lastClaimDate;
    final DateTime? gameDate = fromGameState.lastClaimDate;
    final bool shouldAdoptGameState = gameDate != null &&
        (prefsDate == null || gameDate.isAfter(prefsDate));

    if (shouldAdoptGameState) {
      _state = fromGameState.copy();
      _state.normalize();
      await _saveToPrefs();
    }
    gameState.dailyRewardsState = _state;
  }

  Future<DailyReward?> checkDailyReward() async {
    await _ensureLoaded();

    final DateTime now = DateTime.now().toUtc();
    final DateTime? lastClaim = _state.lastClaimDate?.toUtc();

    if (lastClaim == null) {
      final DailyReward reward = _getRewardForDay(1);
      _lastCheckResult = DailyRewardCheckResult(
        reward: reward,
        streakBroken: false,
        previousStreak: null,
      );
      return reward;
    }

    if (_isSameUtcDay(now, lastClaim)) {
      _lastCheckResult = null;
      return null;
    }

    if (_isYesterdayUtc(lastClaim, now)) {
      final int nextDay = (_state.currentStreak % _cycleLength) + 1;
      final DailyReward reward = _getRewardForDay(nextDay);
      _lastCheckResult = DailyRewardCheckResult(
        reward: reward,
        streakBroken: false,
        previousStreak: _state.currentStreak,
      );
      return reward;
    }

    final DailyReward reward = _getRewardForDay(1);
    _lastCheckResult = DailyRewardCheckResult(
      reward: reward,
      streakBroken: true,
      previousStreak: _state.currentStreak,
    );
    return reward;
  }

  Future<void> claimReward(DailyReward reward, GameState gameState) async {
    await _ensureLoaded();

    final double cashMultiplier = _state.cycleCount > 0 ? _loyaltyCashMultiplier : 1.0;

    switch (reward.type) {
      case DailyRewardType.cash:
        _applyCashReward(gameState, reward.value, cashMultiplier);
        break;
      case DailyRewardType.boost:
        gameState.startBoostForDuration(Duration(minutes: reward.value.round()));
        break;
      case DailyRewardType.mega:
        _applyCashReward(gameState, reward.value, cashMultiplier);
        gameState.startBoostForDuration(const Duration(minutes: _megaBoostMinutes));
        break;
    }

    _state.lastClaimDate = DateTime.now().toUtc();
    _state.currentStreak = reward.day;
    _state.totalDaysClaimed = max(0, _state.totalDaysClaimed + 1);
    if (reward.day == _cycleLength) {
      _state.cycleCount = max(0, _state.cycleCount + 1);
    }

    gameState.dailyRewardsState = _state;
    gameState.onRequestSave?.call();

    await _saveToPrefs();
  }

  DailyReward _getRewardForDay(int day) {
    return _baseRewards.firstWhere((reward) => reward.day == day);
  }

  void _applyCashReward(GameState gameState, double minutes, double multiplier) {
    final double incomePerSecond = gameState.calculateTotalIncomePerSecond();
    final double seconds = minutes * 60;
    final double amount = incomePerSecond * seconds * multiplier;
    if (amount > 0) {
      gameState.addMoney(amount, asPassive: true);
    }
  }

  DateTime _utcDateOnly(DateTime dateTime) {
    return DateTime.utc(dateTime.year, dateTime.month, dateTime.day);
  }

  bool _isSameUtcDay(DateTime a, DateTime b) {
    return _utcDateOnly(a) == _utcDateOnly(b);
  }

  bool _isYesterdayUtc(DateTime last, DateTime now) {
    final DateTime lastDay = _utcDateOnly(last);
    final DateTime nowDay = _utcDateOnly(now);
    return nowDay.difference(lastDay).inDays == 1;
  }
}
