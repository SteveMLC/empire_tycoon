import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';
import '../utils/sound_manager.dart';

// Ad type enumeration - moved outside class
enum AdType {
  hustleBoost,
  buildSkip,
  eventClear,
  offlineincome2x,
}

/// AdMob service for handling rewarded ads across the Empire Tycoon game
/// 
/// This service manages four primary ad placements with PREDICTIVE loading:
/// 1. HustleBoost (10x earnings for 60 seconds) - Strategic preload (main screen)
/// 2. BuildingUpgradeBoost (reduce upgrade time by 15 minutes) - Context-aware loading
/// 3. EventAdSkip (resolve events immediately) - Event-based preloading  
/// 4. Offlineincome2x (2x offline income) - Lifecycle-based preloading
/// 
/// PREDICTIVE LOADING STRATEGY:
/// - Anticipates user behavior based on game state and context
/// - Loads ads before users need them for instant availability
/// - Eliminates loading delays and failures during user interactions
/// 
/// DELAYED REWARD SYSTEM:
/// - Fixes issue where multi-video ads (e.g., 2x 60-second videos) grant rewards too early
/// - AdMob calls onUserEarnedReward after first video, but there's still a second video
/// - Solution: Store reward info but only grant when onAdDismissedFullScreenContent fires
/// - Ensures rewards are only given after ALL ad content is completely finished
/// - Prevents boost timers from expiring before user finishes watching all videos
class AdMobService {
  // Singleton instance
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // Ad configuration
  static const bool _adsEnabled = true;
  
  // Test ad unit ID (works for all ad types in debug)
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  
  // Production ad unit IDs - FIXED: Using correct AdMob account ca-app-pub-1738655803893663
  static const String _prodHustleBoostAdUnitId = 'ca-app-pub-1738655803893663/5010660196';
  static const String _prodBuildSkipAdUnitId = 'ca-app-pub-1738655803893663/3789077869';
  static const String _prodEventClearAdUnitId = 'ca-app-pub-1738655803893663/4305735571';
  static const String _prodOfflineincome2xAdUnitId = 'ca-app-pub-1738655803893663/2319744212';
  
  // Test device IDs for debug mode
  static const List<String> _testDeviceIds = [
    '2CB29575077D7BB3786CB57AEB8B7C34',
  ];
  
  // PREDICTIVE LOADING: Game state tracking for intelligent loading decisions
  int _userBusinessCount = 0;
  int _firstBusinessLevel = 0;
  bool _hasActiveEvents = false;
  bool _isOnBusinessScreen = false;
  bool _isReturningFromBackground = false;
  bool _hasOfflineIncome = false;
  String _currentScreen = 'hustle'; // Default to hustle screen
  
  // DELAYED REWARD SYSTEM: Prevent early reward granting during multi-video ads
  bool _hustleBoostRewardEarned = false;
  bool _buildSkipRewardEarned = false;
  bool _eventClearRewardEarned = false;
  bool _offlineincome2xRewardEarned = false;
  Function(String)? _pendingHustleBoostCallback;
  Function(String)? _pendingBuildSkipCallback;
  Function(String)? _pendingEventClearCallback;
  Function(String)? _pendingOfflineincome2xCallback;
  
  // Ad instances and loading states
  RewardedAd? _hustleBoostAd;
  RewardedAd? _buildSkipAd;
  RewardedAd? _eventClearAd;
  RewardedAd? _offlineincome2xAd;
  
  bool _isHustleBoostAdLoading = false;
  bool _isBuildSkipAdLoading = false;
  bool _isEventClearAdLoading = false;
  bool _isOfflineincome2xAdLoading = false;
  
  DateTime? _hustleBoostAdLoadTime;
  DateTime? _buildSkipAdLoadTime;
  DateTime? _eventClearAdLoadTime;
  DateTime? _offlineincome2xAdLoadTime;
  
  // Analytics and debugging
  DateTime? _sessionStartTime;
  Map<String, int> _adRequestCounts = {};
  Map<String, int> _adShowSuccesses = {};
  Map<String, int> _adShowFailures = {};
  Map<String, List<String>> _adErrors = {};
  String? _lastAdError;
  DateTime? _lastErrorTime;
  
  // ROBUST ERROR HANDLING: Exponential backoff and failure tracking
  Map<String, int> _consecutiveFailures = {};
  Map<String, DateTime?> _lastFailureTime = {};
  Map<String, bool> _adTypeThrottled = {};
  static const int _maxConsecutiveFailures = 3;
  static const Duration _baseRetryDelay = Duration(minutes: 2);
  static const Duration _throttleResetDuration = Duration(minutes: 15);

  // PREDICTIVE LOADING: Update game state for intelligent loading decisions
  void updateGameState({
    int? businessCount,
    int? firstBusinessLevel,
    bool? hasActiveEvents,
    String? currentScreen,
    bool? isReturningFromBackground,
    bool? hasOfflineIncome,
  }) {
    bool stateChanged = false;
    
    if (businessCount != null && businessCount != _userBusinessCount) {
      _userBusinessCount = businessCount;
      stateChanged = true;
    }
    
    if (firstBusinessLevel != null && firstBusinessLevel != _firstBusinessLevel) {
      _firstBusinessLevel = firstBusinessLevel;
      stateChanged = true;
    }
    
    if (hasActiveEvents != null && hasActiveEvents != _hasActiveEvents) {
      _hasActiveEvents = hasActiveEvents;
      stateChanged = true;
    }
    
    if (currentScreen != null && currentScreen != _currentScreen) {
      _currentScreen = currentScreen;
      stateChanged = true;
    }
    
    if (isReturningFromBackground != null && isReturningFromBackground != _isReturningFromBackground) {
      _isReturningFromBackground = isReturningFromBackground;
      stateChanged = true;
    }
    
    if (hasOfflineIncome != null && hasOfflineIncome != _hasOfflineIncome) {
      _hasOfflineIncome = hasOfflineIncome;
      stateChanged = true;
    }
    
    // PREDICTIVE LOADING: Only trigger if state actually changed
    if (stateChanged) {
      if (kDebugMode) {
        print('🎯 Game state updated - triggering predictive loading');
        print('🎯 Businesses: $_userBusinessCount, Level: $_firstBusinessLevel');
        print('🎯 Events: $_hasActiveEvents, Screen: $_currentScreen');
        print('🎯 Background: $_isReturningFromBackground, Offline: $_hasOfflineIncome');
      }
      
      // Small delay to batch multiple rapid state changes
      Future.delayed(const Duration(milliseconds: 500), () {
        _performPredictiveLoading();
      });
    }
  }
  
  // ROBUST ERROR HANDLING: Check if ad type should be retried
  bool _shouldRetryAdType(String adType) {
    // Reset throttle if enough time has passed
    final lastFailure = _lastFailureTime[adType];
    if (lastFailure != null && DateTime.now().difference(lastFailure) > _throttleResetDuration) {
      _consecutiveFailures[adType] = 0;
      _adTypeThrottled[adType] = false;
      if (kDebugMode) {
        print('🔄 Reset throttle for $adType after ${_throttleResetDuration.inMinutes} minutes');
      }
    }
    
    // Don't retry if throttled
    if (_adTypeThrottled[adType] == true) {
      if (kDebugMode) {
        print('⏸️ Skipping $adType - throttled due to consecutive failures');
      }
      return false;
    }
    
    return true;
  }
  
  // ROBUST ERROR HANDLING: Calculate exponential backoff delay
  Duration _getRetryDelay(String adType) {
    final failures = _consecutiveFailures[adType] ?? 0;
    final multiplier = math.pow(2, failures).toInt().clamp(1, 8); // Max 8x base delay
    return Duration(milliseconds: _baseRetryDelay.inMilliseconds * multiplier);
  }
  
  // ROBUST ERROR HANDLING: Handle ad load failure with exponential backoff
  void _handleAdLoadFailure(String adType, LoadAdError error) {
    _consecutiveFailures[adType] = (_consecutiveFailures[adType] ?? 0) + 1;
    _lastFailureTime[adType] = DateTime.now();
    
    final failures = _consecutiveFailures[adType]!;
    
    // Throttle ad type if too many consecutive failures
    if (failures >= _maxConsecutiveFailures) {
      _adTypeThrottled[adType] = true;
      if (kDebugMode) {
        print('🚫 Throttling $adType after $failures consecutive failures');
        print('🚫 Will retry after ${_throttleResetDuration.inMinutes} minutes');
      }
      return;
    }
    
    // Schedule retry with exponential backoff
    final retryDelay = _getRetryDelay(adType);
    if (kDebugMode) {
      print('🔄 Scheduling $adType retry in ${retryDelay.inSeconds} seconds (attempt ${failures + 1})');
    }
    
    Future.delayed(retryDelay, () {
      if (_shouldRetryAdType(adType)) {
        switch (adType) {
          case 'hustleBoost':
            if (!_isHustleBoostAdLoading && !_isAdValid(_hustleBoostAd, _hustleBoostAdLoadTime)) {
              _loadHustleBoostAd();
            }
            break;
          case 'buildSkip':
            if (!_isBuildSkipAdLoading && !_isAdValid(_buildSkipAd, _buildSkipAdLoadTime)) {
              _loadBuildSkipAd();
            }
            break;
          case 'eventClear':
            if (!_isEventClearAdLoading && !_isAdValid(_eventClearAd, _eventClearAdLoadTime)) {
              _loadEventClearAd();
            }
            break;
          case 'offlineincome2x':
            if (!_isOfflineincome2xAdLoading && !_isAdValid(_offlineincome2xAd, _offlineincome2xAdLoadTime)) {
              _loadOfflineincome2xAd();
            }
            break;
        }
      }
    });
  }
  
  // ROBUST ERROR HANDLING: Handle successful ad load
  void _handleAdLoadSuccess(String adType) {
    _consecutiveFailures[adType] = 0;
    _adTypeThrottled[adType] = false;
    if (kDebugMode) {
      print('✅ $adType loaded successfully - reset failure count');
    }
  }
  
  // PREDICTIVE LOADING: Main intelligence engine
  void _performPredictiveLoading() {
    if (!_adsEnabled) return;
    
    if (kDebugMode) {
      print('🎯 === PREDICTIVE AD LOADING ===');
      print('🎯 Businesses: $_userBusinessCount, First Level: $_firstBusinessLevel');
      print('🎯 Events: $_hasActiveEvents, Screen: $_currentScreen');
      print('🎯 Background Return: $_isReturningFromBackground');
      print('🎯 Offline Income Available: $_hasOfflineIncome');
      
      // Show throttling status
      final throttledTypes = _adTypeThrottled.entries.where((e) => e.value == true).map((e) => e.key).toList();
      if (throttledTypes.isNotEmpty) {
        print('⏸️ Throttled ad types: ${throttledTypes.join(", ")}');
      }
    }
    
    // 1. HustleBoost: Always preload (main screen accessible anytime)
    if (!_isAdValid(_hustleBoostAd, _hustleBoostAdLoadTime) && !_isHustleBoostAdLoading) {
      if (_shouldRetryAdType('hustleBoost')) {
        if (kDebugMode) print('🎯 Loading HustleBoost (always available)');
        _loadHustleBoostAd();
      }
    }
    
    // 2. BuildSkip: Context-aware loading
    bool shouldLoadBuildSkip = _userBusinessCount >= 2 || 
                              _currentScreen == 'business' ||
                              _firstBusinessLevel >= 3;
    
    if (shouldLoadBuildSkip && !_isAdValid(_buildSkipAd, _buildSkipAdLoadTime) && !_isBuildSkipAdLoading) {
      if (_shouldRetryAdType('buildSkip')) {
        if (kDebugMode) print('🎯 Loading BuildSkip (context-aware: $_userBusinessCount businesses, level $_firstBusinessLevel)');
        _loadBuildSkipAd();
      }
    }
    
    // 3. EventClear: Event-based preloading
    if (_hasActiveEvents && !_isAdValid(_eventClearAd, _eventClearAdLoadTime) && !_isEventClearAdLoading) {
      if (_shouldRetryAdType('eventClear')) {
        if (kDebugMode) print('🎯 Loading EventClear (events active)');
        _loadEventClearAd();
      }
    }
    
    // 4. Offlineincome2x: ENHANCED - Preload when offline income is available OR returning from background
    bool shouldLoadOfflineIncomeAd = _isReturningFromBackground || _hasOfflineIncome;
    
    if (shouldLoadOfflineIncomeAd && !_isAdValid(_offlineincome2xAd, _offlineincome2xAdLoadTime) && !_isOfflineincome2xAdLoading) {
      if (_shouldRetryAdType('offlineincome2x')) {
        if (kDebugMode) {
          String reason = _isReturningFromBackground ? 'background return' : 'offline income available';
          print('🎯 Loading Offlineincome2x ($reason)');
        }
        _loadOfflineincome2xAd();
      }
    }
  }
  
  // PREDICTIVE LOGIC: Determine when to load BuildSkip ads
  bool _shouldLoadBuildSkipAd() {
    // If user owns 2+ businesses, they can upgrade anytime
    if (_userBusinessCount >= 2) {
      return true;
    }
    
    // If user is on business screen with upgradeable business
    if (_currentScreen == 'business' && _firstBusinessLevel > 1) {
      return true;
    }
    
    // If first business is high level (likely to upgrade soon)
    if (_firstBusinessLevel >= 3) {
      return true;
    }
    
    return false;
  }

  // Check if an ad is valid and not expired (50-minute window for safety)
  bool _isAdValid(RewardedAd? ad, DateTime? loadTime) {
    if (ad == null || loadTime == null) return false;
    final ageInMinutes = DateTime.now().difference(loadTime).inMinutes;
    return ageInMinutes < 50; // 10-minute safety buffer before 1-hour expiration
  }

  // ENHANCED: Debug status with comprehensive revenue analytics (works in release mode)
  void printDebugStatus() {
    final analytics = getRevenueAnalytics();
    
    // Core analytics (always available)
    debugPrint('🎯 === AdMob Production Diagnostics ===');
    debugPrint('🎯 Build Mode: ${kDebugMode ? "DEBUG" : "RELEASE"}');
    debugPrint('🎯 Ad Unit Account: ${_prodHustleBoostAdUnitId.substring(0, 30)}...');
    debugPrint('🎯 Session Duration: ${analytics['sessionDurationMinutes']} minutes');
    debugPrint('🎯 Total Requests: ${analytics['totalRequests']}');
    debugPrint('🎯 Total Successes: ${analytics['totalShowSuccesses']}');
    debugPrint('🎯 Total Failures: ${analytics['totalShowFailures']}');
    debugPrint('🎯 Impression Loss Rate: ${analytics['impressionLossRate'].toStringAsFixed(1)}%');
    
    debugPrint('🎯 Predictive Loading Status:');
    
    // HustleBoost - Always ready
    final hustleReady = isHustleBoostAdReady;
    final hustleAge = _hustleBoostAdLoadTime != null 
        ? DateTime.now().difference(_hustleBoostAdLoadTime!).inMinutes 
        : null;
    debugPrint('   ✨ HustleBoost: ${hustleReady ? "✅ Ready" : "❌ Not Ready"} (Loading: $_isHustleBoostAdLoading)');
    if (hustleAge != null) {
      debugPrint('     Strategy: ALWAYS READY (Age: ${hustleAge}min, ${hustleAge < 50 ? "Fresh" : "Near Expiry"})');
    }
    
    // BuildSkip - Context-aware
    final buildReady = isBuildSkipAdReady;
    final shouldLoad = _shouldLoadBuildSkipAd();
    debugPrint('   🏢 BuildSkip: ${buildReady ? "✅ Ready" : "❌ Not Ready"} (Loading: $_isBuildSkipAdLoading)');
    debugPrint('     Strategy: CONTEXT-AWARE (Should load: $shouldLoad)');
    debugPrint('     Context: $_userBusinessCount businesses, level $_firstBusinessLevel, screen: $_currentScreen');
    
    // EventClear - Event-based
    debugPrint('   ⚡ EventClear: ${isEventClearAdReady ? "✅ Ready" : "❌ Not Ready"} (Loading: $_isEventClearAdLoading)');
    debugPrint('     Strategy: EVENT-BASED (Events active: $_hasActiveEvents)');
    
    // Offlineincome2x - Lifecycle-based
    debugPrint('   💰 Offlineincome2x: ${isOfflineincome2xAdReady ? "✅ Ready" : "❌ Not Ready"} (Loading: $_isOfflineincome2xAdLoading)');
    debugPrint('     Strategy: LIFECYCLE-BASED (Background return: $_isReturningFromBackground)');
    
    // Show recent errors for each ad type
    for (String adType in ['hustleBoost', 'buildSkip', 'eventClear', 'offlineincome2x']) {
      final errors = analytics['byAdType'][adType]['errors'] as List;
      if (errors.isNotEmpty) {
        debugPrint('🎯 Recent $adType errors: ${errors.take(2).join(', ')}');
      }
    }
    
    if (_lastAdError != null) {
      debugPrint('🎯 Last Error: $_lastAdError (${_lastErrorTime})');
    }
    debugPrint('🎯 === End Production Diagnostics ===');
  }

  // ENHANCED: Revenue analytics with predictive loading insights
  Map<String, dynamic> getRevenueAnalytics() {
    final sessionDuration = _sessionStartTime != null 
        ? DateTime.now().difference(_sessionStartTime!).inMinutes 
        : 0;
    
    final totalRequests = _adRequestCounts.values.fold(0, (sum, count) => sum + count);
    final totalSuccesses = _adShowSuccesses.values.fold(0, (sum, count) => sum + count);
    final totalFailures = _adShowFailures.values.fold(0, (sum, count) => sum + count);
    
    final impressionLossRate = totalRequests > 0 
        ? ((totalRequests - totalSuccesses) / totalRequests * 100) 
        : 0.0;
    
    // Per-ad-type analytics
    Map<String, Map<String, dynamic>> byAdType = {};
    for (String adType in ['hustleBoost', 'buildSkip', 'eventClear', 'offlineincome2x']) {
      final requests = _adRequestCounts[adType] ?? 0;
      final successes = _adShowSuccesses[adType] ?? 0;
      final failures = _adShowFailures[adType] ?? 0;
      final errors = _adErrors[adType] ?? [];
      
      byAdType[adType] = {
        'requests': requests,
        'successes': successes,
        'failures': failures,
        'successRate': requests > 0 ? (successes / requests * 100) : 0.0,
        'errors': errors,
      };
    }
    
    return {
      'sessionDurationMinutes': sessionDuration,
      'totalRequests': totalRequests,
      'totalShowSuccesses': totalSuccesses,
      'totalShowFailures': totalFailures,
      'impressionLossRate': impressionLossRate,
      'byAdType': byAdType,
      'predictiveLoadingEnabled': true,
      'gameState': {
        'businessCount': _userBusinessCount,
        'firstBusinessLevel': _firstBusinessLevel,
        'hasActiveEvents': _hasActiveEvents,
        'currentScreen': _currentScreen,
        'isReturningFromBackground': _isReturningFromBackground,
      }
    };
  }

  // ENHANCED: Revenue loss summary with predictive loading insights
  String getRevenueLossSummary() {
    final analytics = getRevenueAnalytics();
    final lossRate = analytics['impressionLossRate'] as double;
    final totalRequests = analytics['totalRequests'] as int;
    final totalSuccesses = analytics['totalShowSuccesses'] as int;
    final totalFailures = analytics['totalShowFailures'] as int;
    
    if (totalRequests == 0) {
      return "No ad requests yet - predictive loading is ready!\n" +
             "🎯 HustleBoost: Always loaded for instant use\n" +
             "🎯 BuildSkip: Loads when you own 2+ businesses or upgrade context\n" +
             "🎯 EventClear: Loads when events are active\n" +
             "🎯 Offline2x: Loads when returning from background";
    }
    
    String summary = "PREDICTIVE LOADING REVENUE ANALYSIS:\n";
    summary += "• Total Requests: $totalRequests\n";
    summary += "• Successful Shows: $totalSuccesses\n";
    summary += "• Failed Shows: $totalFailures\n";
    summary += "• Impression Loss: ${lossRate.toStringAsFixed(1)}%\n\n";
    
    summary += "PREDICTIVE LOADING STATUS:\n";
    summary += "• HustleBoost: Always ready (${isHustleBoostAdReady ? "✅" : "❌"})\n";
    summary += "• BuildSkip: Context-aware (${isBuildSkipAdReady ? "✅" : "❌"}, should load: ${_shouldLoadBuildSkipAd()})\n";
    summary += "• EventClear: Event-based (${isEventClearAdReady ? "✅" : "❌"}, events: $_hasActiveEvents)\n";
    summary += "• Offline2x: Lifecycle-based (${isOfflineincome2xAdReady ? "✅" : "❌"}, bg return: $_isReturningFromBackground)\n\n";
    
    if (lossRate > 15) {
      summary += "🚨 CRITICAL REVENUE LOSS!\n";
      summary += "Potential lost revenue per day: \$${(lossRate * 0.90).toStringAsFixed(2)}\n";
      summary += "• Check predictive loading logic - ads should be ready instantly\n";
      summary += "• Verify game state updates are being called correctly\n";
    } else if (lossRate > 8) {
      summary += "⚠️ MODERATE REVENUE LOSS (8-15%)\n";
      summary += "• Predictive loading is working but needs optimization\n";
      summary += "• Monitor game state update frequency\n";
    } else if (lossRate > 3) {
      summary += "✅ GOOD PERFORMANCE (3-8% loss)\n";
      summary += "• Predictive loading is working effectively\n";
      summary += "• Normal range for mobile ads with intelligent loading\n";
    } else {
      summary += "🎉 EXCELLENT PERFORMANCE! (<3% loss)\n";
      summary += "• Predictive loading is working perfectly!\n";
      summary += "• Users getting instant ad availability\n";
    }
    
    return summary;
  }

  // Error logging
  void _logError(String message) {
    _lastAdError = message;
    _lastErrorTime = DateTime.now();
    if (kDebugMode) {
      print('❌ AdMob Error: $message');
    }
  }

  void _logAdError(String adType, String error) {
    final timestamp = DateTime.now().toIso8601String();
    final errorWithTimestamp = '$timestamp: $error';
    
    _adErrors.putIfAbsent(adType, () => []);
    _adErrors[adType]!.add(errorWithTimestamp);
    
    // Keep only last 5 errors per type
    if (_adErrors[adType]!.length > 5) {
      _adErrors[adType]!.removeAt(0);
    }
    
    _lastAdError = '$adType: $error';
    _lastErrorTime = DateTime.now();
  }

  // ENHANCED: Get simple revenue diagnostics
  String getQuickRevenueDiagnostic() {
    final analytics = getRevenueAnalytics();
    final lossRate = analytics['impressionLossRate'] as double;
    final totalRequests = analytics['totalRequests'] as int;
    
    if (totalRequests == 0) {
      return "Predictive loading ready - no requests yet";
    }
    
    if (lossRate > 15) {
      return "🚨 Critical revenue loss: ${lossRate.toStringAsFixed(1)}% - Check predictive loading";
    } else if (lossRate > 8) {
      return "⚠️ Moderate revenue loss: ${lossRate.toStringAsFixed(1)}% - Optimize predictions";
    } else if (lossRate > 3) {
      return "✅ Good performance: ${lossRate.toStringAsFixed(1)}% loss - Predictive loading working";
    } else {
      return "🎉 Excellent: ${lossRate.toStringAsFixed(1)}% loss - Perfect predictive loading!";
    }
  }

  // Initialize the AdMob SDK - PREDICTIVE: Intelligent loading based on user context
  Future<void> initialize() async {
    try {
      _sessionStartTime = DateTime.now();
      
      if (kDebugMode) {
        print('🎯 Starting AdMob SDK initialization...');
        print('🎯 Ads Enabled: $_adsEnabled');
      }
      
      // Skip AdMob initialization if ads are disabled
      if (!_adsEnabled) {
        if (kDebugMode) {
          print('🎯 AdMob disabled for Play Store submission - skipping initialization');
        }
        return;
      }
      
      await MobileAds.instance.initialize();
      
      // Configure test devices in debug mode
      if (kDebugMode && _testDeviceIds.isNotEmpty) {
        final requestConfiguration = RequestConfiguration(
          testDeviceIds: _testDeviceIds,
        );
        MobileAds.instance.updateRequestConfiguration(requestConfiguration);
        if (kDebugMode) {
          print('🎯 Test device configuration updated');
        }
      }
      
      if (kDebugMode) {
        print('🎯 AdMob SDK initialized successfully');
        print('🎯 PREDICTIVE LOADING: Intelligent ad loading based on user behavior');
      }
      
      // Start with HustleBoost (always needed on main screen)
      _loadHustleBoostAd();
      
      // Trigger initial predictive loading assessment
      _performPredictiveLoading();
      
    } catch (e, stackTrace) {
      _logError('AdMob initialization failed: $e');
      if (kDebugMode) {
        print('❌ AdMob initialization failed: $e');
        print('❌ Stack trace: $stackTrace');
      }
      // Continue app execution even if AdMob fails
    }
  }

  // Get the appropriate ad unit ID
  String _getAdUnitId(AdType adType) {
    if (kDebugMode) {
      return _testRewardedAdUnitId;
    }
    
    switch (adType) {
      case AdType.hustleBoost:
        return _prodHustleBoostAdUnitId;
      case AdType.buildSkip:
        return _prodBuildSkipAdUnitId;
      case AdType.eventClear:
        return _prodEventClearAdUnitId;
      case AdType.offlineincome2x:
        return _prodOfflineincome2xAdUnitId;
    }
  }

  // PREDICTIVE: HustleBoost ad loading (always available)
  Future<void> _loadHustleBoostAd() async {
    if (!_adsEnabled) return;
    if (_isHustleBoostAdLoading || _isAdValid(_hustleBoostAd, _hustleBoostAdLoadTime)) return;
    
    // Check if this ad type should be retried
    if (!_shouldRetryAdType('hustleBoost')) return;
    
    _isHustleBoostAdLoading = true;
    _adRequestCounts['hustleBoost'] = (_adRequestCounts['hustleBoost'] ?? 0) + 1;
    
    if (kDebugMode) {
      print('🎯 Loading HustleBoost ad (always available)...');
    }
    
    await RewardedAd.load(
      adUnitId: _getAdUnitId(AdType.hustleBoost),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _hustleBoostAd = ad;
          _isHustleBoostAdLoading = false;
          _hustleBoostAdLoadTime = DateTime.now();
          _handleAdLoadSuccess('hustleBoost');
          if (kDebugMode) {
            print('✅ HustleBoost ad loaded - Ready for instant use');
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isHustleBoostAdLoading = false;
          _logAdError('hustleBoost', 'Load failed: ${error.code} - ${error.message}');
          
          // PRODUCTION DEBUG: Enhanced error logging for release mode
          debugPrint('❌ HustleBoost ad load failed:');
          debugPrint('   Error Code: ${error.code}');
          debugPrint('   Error Message: ${error.message}');
          debugPrint('   Error Domain: ${error.domain}');
          debugPrint('   Build Mode: ${kDebugMode ? "DEBUG" : "RELEASE"}');
          debugPrint('   Ad Unit: ${_getAdUnitId(AdType.hustleBoost)}');
          
          // Use robust error handling with exponential backoff
          _handleAdLoadFailure('hustleBoost', error);
        },
      ),
    );
  }

  // PREDICTIVE: BuildSkip ad loading (context-aware)
  Future<void> _loadBuildSkipAd() async {
    if (!_adsEnabled) return;
    if (_isBuildSkipAdLoading || _isAdValid(_buildSkipAd, _buildSkipAdLoadTime)) return;
    
    // Check if this ad type should be retried
    if (!_shouldRetryAdType('buildSkip')) return;
    
    _isBuildSkipAdLoading = true;
    _adRequestCounts['buildSkip'] = (_adRequestCounts['buildSkip'] ?? 0) + 1;
    
    if (kDebugMode) {
      print('🎯 Loading BuildSkip ad (context-aware: $_userBusinessCount businesses, level $_firstBusinessLevel)...');
    }
    
    await RewardedAd.load(
      adUnitId: _getAdUnitId(AdType.buildSkip),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _buildSkipAd = ad;
          _isBuildSkipAdLoading = false;
          _buildSkipAdLoadTime = DateTime.now();
          _handleAdLoadSuccess('buildSkip');
          if (kDebugMode) {
            print('✅ BuildSkip ad loaded - Ready for instant use');
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isBuildSkipAdLoading = false;
          _logAdError('buildSkip', 'Load failed: ${error.code} - ${error.message}');
          if (kDebugMode) {
            print('❌ BuildSkip ad load failed: ${error.code} - ${error.message}');
          }
          // Use robust error handling with exponential backoff
          _handleAdLoadFailure('buildSkip', error);
        },
      ),
    );
  }

  // PREDICTIVE: EventClear ad loading (event-based)
  Future<void> _loadEventClearAd() async {
    if (!_adsEnabled) return;
    if (_isEventClearAdLoading || _isAdValid(_eventClearAd, _eventClearAdLoadTime)) return;
    
    // Check if this ad type should be retried
    if (!_shouldRetryAdType('eventClear')) return;
    
    _isEventClearAdLoading = true;
    _adRequestCounts['eventClear'] = (_adRequestCounts['eventClear'] ?? 0) + 1;
    
    if (kDebugMode) {
      print('🎯 Loading EventClear ad (events active: $_hasActiveEvents)...');
    }
    
    await RewardedAd.load(
      adUnitId: _getAdUnitId(AdType.eventClear),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _eventClearAd = ad;
          _isEventClearAdLoading = false;
          _eventClearAdLoadTime = DateTime.now();
          _handleAdLoadSuccess('eventClear');
          if (kDebugMode) {
            print('✅ EventClear ad loaded - Ready for instant event resolution');
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isEventClearAdLoading = false;
          _logAdError('eventClear', 'Load failed: ${error.code} - ${error.message}');
          if (kDebugMode) {
            print('❌ EventClear ad load failed: ${error.code} - ${error.message}');
          }
          
          // Use robust error handling with exponential backoff
          _handleAdLoadFailure('eventClear', error);
        },
      ),
    );
  }

  // PREDICTIVE: Offlineincome2x ad loading (lifecycle-based)
  Future<void> _loadOfflineincome2xAd() async {
    if (!_adsEnabled) return;
    if (_isOfflineincome2xAdLoading || _isAdValid(_offlineincome2xAd, _offlineincome2xAdLoadTime)) return;
    
    // Check if this ad type should be retried
    if (!_shouldRetryAdType('offlineincome2x')) return;
    
    _isOfflineincome2xAdLoading = true;
    _adRequestCounts['offlineincome2x'] = (_adRequestCounts['offlineincome2x'] ?? 0) + 1;
    
    if (kDebugMode) {
      print('🎯 Loading Offlineincome2x ad (background return: $_isReturningFromBackground)...');
    }
    
    await RewardedAd.load(
      adUnitId: _getAdUnitId(AdType.offlineincome2x),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _offlineincome2xAd = ad;
          _isOfflineincome2xAdLoading = false;
          _offlineincome2xAdLoadTime = DateTime.now();
          _handleAdLoadSuccess('offlineincome2x');
          if (kDebugMode) {
            print('✅ Offlineincome2x ad loaded - Ready for instant offline income boost');
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isOfflineincome2xAdLoading = false;
          _logAdError('offlineincome2x', 'Load failed: ${error.code} - ${error.message}');
          if (kDebugMode) {
            print('❌ Offlineincome2x ad load failed: ${error.code} - ${error.message}');
          }
          
          // Use robust error handling with exponential backoff
          _handleAdLoadFailure('offlineincome2x', error);
        },
      ),
    );
  }

  // INSTANT: Show HustleBoost ad (should always be ready)
  Future<void> showHustleBoostAd({
    required Function(String rewardType) onRewardEarned,
    Function()? onAdFailure,
  }) async {
    if (!_adsEnabled) {
      if (kDebugMode) print('🎯 Ads disabled, simulating HustleBoost reward');
      onRewardEarned('HustleBoost');
      return;
    }

    if (kDebugMode) {
      print('🎯 === HustleBoost Ad Request ===');
      print('🎯 Ad valid: ${_isAdValid(_hustleBoostAd, _hustleBoostAdLoadTime)}');
    }

    if (!_isAdValid(_hustleBoostAd, _hustleBoostAdLoadTime)) {
      if (kDebugMode) print('🎯 HustleBoost ad not ready - this should rarely happen with predictive loading');
      _logAdError('hustleBoost', 'Show failed: Ad not ready (predictive loading issue)');
      _adShowFailures['hustleBoost'] = (_adShowFailures['hustleBoost'] ?? 0) + 1;
      
      // Emergency load as fallback
      if (!_isHustleBoostAdLoading) {
        _loadHustleBoostAd();
      }
      onAdFailure?.call();
      return;
    }

    // Reset delayed reward state for this ad session
    _hustleBoostRewardEarned = false;
    _pendingHustleBoostCallback = null;

    _adShowSuccesses['hustleBoost'] = (_adShowSuccesses['hustleBoost'] ?? 0) + 1;
    final totalRequests = (_adRequestCounts['hustleBoost'] ?? 0);
    final successRate = totalRequests > 0 ? ((_adShowSuccesses['hustleBoost'] ?? 0) / totalRequests * 100) : 0;
    
    if (kDebugMode) {
      print('📊 Ad shown: hustleBoost (Total: $totalRequests, Success Rate: ${successRate.toStringAsFixed(1)}%)');
    }

    _hustleBoostAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        if (kDebugMode) print('🎯 HustleBoost ad displayed');
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        if (kDebugMode) print('🎯 HustleBoost ad dismissed (user closed ad)');
        
        // DELAYED REWARD: Only grant reward when ad is fully dismissed (all videos completed)
        if (_hustleBoostRewardEarned && _pendingHustleBoostCallback != null) {
          if (kDebugMode) print('🎁 Granting delayed HustleBoost reward after full ad completion');
          _pendingHustleBoostCallback!('HustleBoost');
        } else if (kDebugMode) {
          print('⚠️ HustleBoost ad dismissed but no reward was earned (user closed early)');
        }
        
        // Clean up delayed reward state
        _hustleBoostRewardEarned = false;
        _pendingHustleBoostCallback = null;
        
        ad.dispose();
        _hustleBoostAd = null;
        _hustleBoostAdLoadTime = null;
        
        // Recover audio system after ad interruption
        SoundManager().recoverFromAudioInterruption();
        
        // Immediately reload for next use (predictive)
        _loadHustleBoostAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        _logAdError('hustleBoost', 'Show failed: ${error.code} - ${error.message}');
        if (kDebugMode) print('❌ HustleBoost ad failed to show: ${error.code} - ${error.message}');
        
        // Clean up delayed reward state on failure
        _hustleBoostRewardEarned = false;
        _pendingHustleBoostCallback = null;
        
        ad.dispose();
        _hustleBoostAd = null;
        _hustleBoostAdLoadTime = null;
        _adShowFailures['hustleBoost'] = (_adShowFailures['hustleBoost'] ?? 0) + 1;
        
        // Reload after failure
        _loadHustleBoostAd();
        onAdFailure?.call();
      },
    );

    await _hustleBoostAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      if (kDebugMode) print('🎁 User earned HustleBoost reward: ${reward.amount} ${reward.type} - DELAYING until ad fully completes');
      
      // DELAYED REWARD: Store reward info but don't grant yet (prevents multi-video early rewards)
      _hustleBoostRewardEarned = true;
      _pendingHustleBoostCallback = onRewardEarned;
    });
  }

  // INSTANT: Show BuildSkip ad (should be ready when user has upgradeable businesses)
  Future<void> showBuildSkipAd({
    required Function(String rewardType) onRewardEarned,
    Function()? onAdFailure,
  }) async {
    if (!_adsEnabled) {
      if (kDebugMode) print('🎯 Ads disabled, simulating BuildingUpgradeBoost reward');
      onRewardEarned('BuildingUpgradeBoost');
      return;
    }

    if (kDebugMode) {
      print('🎯 === BuildSkip Ad Request ===');
      print('🎯 Ad valid: ${_isAdValid(_buildSkipAd, _buildSkipAdLoadTime)}');
      print('🎯 User context: $_userBusinessCount businesses, level $_firstBusinessLevel');
    }

    if (!_isAdValid(_buildSkipAd, _buildSkipAdLoadTime)) {
      if (kDebugMode) print('🎯 BuildSkip ad not ready - triggering emergency load');
      _logAdError('buildSkip', 'Show failed: Ad not ready when user needed it (predictive system needs improvement)');
      _adShowFailures['buildSkip'] = (_adShowFailures['buildSkip'] ?? 0) + 1;
      
      // Emergency load and update game state to improve predictions
      if (!_isBuildSkipAdLoading) {
        _loadBuildSkipAd();
      }
      
      // Trigger predictive loading reassessment
      _performPredictiveLoading();
      onAdFailure?.call();
      return;
    }

    _adShowSuccesses['buildSkip'] = (_adShowSuccesses['buildSkip'] ?? 0) + 1;
    final totalRequests = (_adRequestCounts['buildSkip'] ?? 0);
    final successRate = totalRequests > 0 ? ((_adShowSuccesses['buildSkip'] ?? 0) / totalRequests * 100) : 0;
    
    if (kDebugMode) {
      print('📊 Ad shown: buildSkip (Total: $totalRequests, Success Rate: ${successRate.toStringAsFixed(1)}%)');
    }

    // Reset delayed reward state for this ad session
    _buildSkipRewardEarned = false;
    _pendingBuildSkipCallback = null;

    _buildSkipAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        if (kDebugMode) print('🎯 BuildSkip ad displayed');
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        if (kDebugMode) print('🎯 BuildSkip ad dismissed (user closed ad)');
        
        // DELAYED REWARD: Only grant reward when ad is fully dismissed (all videos completed)
        if (_buildSkipRewardEarned && _pendingBuildSkipCallback != null) {
          if (kDebugMode) print('🎁 Granting delayed BuildingUpgradeBoost reward after full ad completion');
          _pendingBuildSkipCallback!('BuildingUpgradeBoost');
        } else if (kDebugMode) {
          print('⚠️ BuildSkip ad dismissed but no reward was earned (user closed early)');
        }
        
        // Clean up delayed reward state
        _buildSkipRewardEarned = false;
        _pendingBuildSkipCallback = null;
        
        ad.dispose();
        _buildSkipAd = null;
        _buildSkipAdLoadTime = null;
        
        // Recover audio system after ad interruption
        SoundManager().recoverFromAudioInterruption();
        
        // Intelligently reload based on context
        if (_shouldLoadBuildSkipAd()) {
          _loadBuildSkipAd();
        }
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        _logAdError('buildSkip', 'Show failed: ${error.code} - ${error.message}');
        if (kDebugMode) print('❌ BuildSkip ad failed to show: ${error.code} - ${error.message}');
        
        // Clean up delayed reward state on failure
        _buildSkipRewardEarned = false;
        _pendingBuildSkipCallback = null;
        
        ad.dispose();
        _buildSkipAd = null;
        _buildSkipAdLoadTime = null;
        _adShowFailures['buildSkip'] = (_adShowFailures['buildSkip'] ?? 0) + 1;
        
        // Reload after failure if still needed
        if (_shouldLoadBuildSkipAd()) {
          _loadBuildSkipAd();
        }
        onAdFailure?.call();
      },
    );

    await _buildSkipAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      if (kDebugMode) print('🎁 User earned BuildingUpgradeBoost reward: ${reward.amount} ${reward.type} - DELAYING until ad fully completes');
      
      // DELAYED REWARD: Store reward info but don't grant yet (prevents multi-video early rewards)
      _buildSkipRewardEarned = true;
      _pendingBuildSkipCallback = onRewardEarned;
    });
  }

  // INSTANT: Show EventClear ad (should be ready when events are active)
  Future<void> showEventClearAd({
    required Function(String rewardType) onRewardEarned,
    Function()? onAdFailure,
  }) async {
    if (!_adsEnabled) {
      if (kDebugMode) print('🎯 Ads disabled, simulating EventAdSkip reward');
      onRewardEarned('EventAdSkip');
      return;
    }

    if (kDebugMode) {
      print('🎯 === EventClear Ad Request ===');
      print('🎯 Ad valid: ${_isAdValid(_eventClearAd, _eventClearAdLoadTime)}');
      print('🎯 Events active: $_hasActiveEvents');
    }

    if (!_isAdValid(_eventClearAd, _eventClearAdLoadTime)) {
      if (kDebugMode) print('🎯 EventClear ad not ready - emergency loading');
      _logAdError('eventClear', 'Show failed: Ad not ready when event needed clearing');
      _adShowFailures['eventClear'] = (_adShowFailures['eventClear'] ?? 0) + 1;
      
      // Emergency load
      if (!_isEventClearAdLoading) {
        _loadEventClearAd();
      }
      onAdFailure?.call();
      return;
    }

    _adShowSuccesses['eventClear'] = (_adShowSuccesses['eventClear'] ?? 0) + 1;
    final totalRequests = (_adRequestCounts['eventClear'] ?? 0);
    final successRate = totalRequests > 0 ? ((_adShowSuccesses['eventClear'] ?? 0) / totalRequests * 100) : 0;
    
    if (kDebugMode) {
      print('📊 Ad shown: eventClear (Total: $totalRequests, Success Rate: ${successRate.toStringAsFixed(1)}%)');
    }

    // Reset delayed reward state for this ad session
    _eventClearRewardEarned = false;
    _pendingEventClearCallback = null;

    _eventClearAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        if (kDebugMode) print('🎯 EventClear ad displayed');
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        if (kDebugMode) print('🎯 EventClear ad dismissed (user closed ad)');
        
        // DELAYED REWARD: Only grant reward when ad is fully dismissed (all videos completed)
        if (_eventClearRewardEarned && _pendingEventClearCallback != null) {
          if (kDebugMode) print('🎁 Granting delayed EventAdSkip reward after full ad completion');
          _pendingEventClearCallback!('EventAdSkip');
        } else if (kDebugMode) {
          print('⚠️ EventClear ad dismissed but no reward was earned (user closed early)');
        }
        
        // Clean up delayed reward state
        _eventClearRewardEarned = false;
        _pendingEventClearCallback = null;
        
        ad.dispose();
        _eventClearAd = null;
        _eventClearAdLoadTime = null;
        
        // Recover audio system after ad interruption
        SoundManager().recoverFromAudioInterruption();
        
        // Reload if events are still active
        if (_hasActiveEvents) {
          _loadEventClearAd();
        }
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        _logAdError('eventClear', 'Show failed: ${error.code} - ${error.message}');
        if (kDebugMode) print('❌ EventClear ad failed to show: ${error.code} - ${error.message}');
        
        // Clean up delayed reward state on failure
        _eventClearRewardEarned = false;
        _pendingEventClearCallback = null;
        
        ad.dispose();
        _eventClearAd = null;
        _eventClearAdLoadTime = null;
        _adShowFailures['eventClear'] = (_adShowFailures['eventClear'] ?? 0) + 1;
        
        // Reload if events are still active
        if (_hasActiveEvents) {
          _loadEventClearAd();
        }
        onAdFailure?.call();
      },
    );

    await _eventClearAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      if (kDebugMode) print('🎁 User earned EventAdSkip reward: ${reward.amount} ${reward.type} - DELAYING until ad fully completes');
      
      // DELAYED REWARD: Store reward info but don't grant yet (prevents multi-video early rewards)
      _eventClearRewardEarned = true;
      _pendingEventClearCallback = onRewardEarned;
    });
  }

  // INSTANT: Show Offlineincome2x ad (should be ready when returning from background)
  Future<void> showOfflineincome2xAd({
    required Function(String rewardType) onRewardEarned,
    Function()? onAdFailure,
  }) async {
    if (!_adsEnabled) {
      if (kDebugMode) print('🎯 Ads disabled, simulating Offlineincome2x reward');
      onRewardEarned('Offlineincome2x');
      return;
    }

    if (kDebugMode) {
      print('🎯 === Offlineincome2x Ad Request ===');
      print('🎯 Ad valid: ${_isAdValid(_offlineincome2xAd, _offlineincome2xAdLoadTime)}');
      print('🎯 Background return: $_isReturningFromBackground');
    }

    if (!_isAdValid(_offlineincome2xAd, _offlineincome2xAdLoadTime)) {
      if (kDebugMode) print('🎯 Offlineincome2x ad not ready - emergency loading');
      _logAdError('offlineincome2x', 'Show failed: Ad not ready for offline income boost');
      _adShowFailures['offlineincome2x'] = (_adShowFailures['offlineincome2x'] ?? 0) + 1;
      
      // Emergency load
      if (!_isOfflineincome2xAdLoading) {
        _loadOfflineincome2xAd();
      }
      onAdFailure?.call();
      return;
    }

    _adShowSuccesses['offlineincome2x'] = (_adShowSuccesses['offlineincome2x'] ?? 0) + 1;
    final totalRequests = (_adRequestCounts['offlineincome2x'] ?? 0);
    final successRate = totalRequests > 0 ? ((_adShowSuccesses['offlineincome2x'] ?? 0) / totalRequests * 100) : 0;
    
    if (kDebugMode) {
      print('📊 Ad shown: offlineincome2x (Total: $totalRequests, Success Rate: ${successRate.toStringAsFixed(1)}%)');
    }

    // Reset delayed reward state for this ad session
    _offlineincome2xRewardEarned = false;
    _pendingOfflineincome2xCallback = null;

    _offlineincome2xAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        if (kDebugMode) print('🎯 Offlineincome2x ad displayed');
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        if (kDebugMode) print('🎯 Offlineincome2x ad dismissed (user closed ad)');
        
        // DELAYED REWARD: Only grant reward when ad is fully dismissed (all videos completed)
        if (_offlineincome2xRewardEarned && _pendingOfflineincome2xCallback != null) {
          if (kDebugMode) print('🎁 Granting delayed Offlineincome2x reward after full ad completion');
          _pendingOfflineincome2xCallback!('Offlineincome2x');
        } else if (kDebugMode) {
          print('⚠️ Offlineincome2x ad dismissed but no reward was earned (user closed early)');
        }
        
        // Clean up delayed reward state
        _offlineincome2xRewardEarned = false;
        _pendingOfflineincome2xCallback = null;
        
        ad.dispose();
        _offlineincome2xAd = null;
        _offlineincome2xAdLoadTime = null;
        
        // Recover audio system after ad interruption
        SoundManager().recoverFromAudioInterruption();
        
        // Reset background return flag and don't immediately reload
        // (user may not need another offline income boost soon)
        _isReturningFromBackground = false;
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        _logAdError('offlineincome2x', 'Show failed: ${error.code} - ${error.message}');
        if (kDebugMode) print('❌ Offlineincome2x ad failed to show: ${error.code} - ${error.message}');
        
        // Clean up delayed reward state on failure
        _offlineincome2xRewardEarned = false;
        _pendingOfflineincome2xCallback = null;
        
        ad.dispose();
        _offlineincome2xAd = null;
        _offlineincome2xAdLoadTime = null;
        _adShowFailures['offlineincome2x'] = (_adShowFailures['offlineincome2x'] ?? 0) + 1;
        
        // Reset background return flag
        _isReturningFromBackground = false;
        onAdFailure?.call();
      },
    );

    await _offlineincome2xAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      if (kDebugMode) print('🎁 User earned Offlineincome2x reward: ${reward.amount} ${reward.type} - DELAYING until ad fully completes');
      
      // DELAYED REWARD: Store reward info but don't grant yet (prevents multi-video early rewards)
      _offlineincome2xRewardEarned = true;
      _pendingOfflineincome2xCallback = onRewardEarned;
    });
  }

  // PRODUCTION DIAGNOSTIC: Quick status check for immediate debugging
  String getQuickDiagnostic() {
    final analytics = getRevenueAnalytics();
    final buildMode = kDebugMode ? "DEBUG" : "RELEASE";
    final accountId = _prodHustleBoostAdUnitId.substring(11, 27); // Extract account ID
    
    String status = "🎯 AdMob Quick Status ($buildMode)\n";
    status += "Account: ca-app-pub-$accountId\n";
    status += "Requests: ${analytics['totalRequests']} | ";
    status += "Success: ${analytics['totalShowSuccesses']} | ";
    status += "Failures: ${analytics['totalShowFailures']}\n";
    
    // Ad readiness with throttling info
    status += "HustleBoost: ${_getAdStatusWithThrottling('hustleBoost', isHustleBoostAdReady)} | ";
    status += "BuildSkip: ${_getAdStatusWithThrottling('buildSkip', isBuildSkipAdReady)} | ";
    status += "EventClear: ${_getAdStatusWithThrottling('eventClear', isEventClearAdReady)} | ";
    status += "OfflineIncome: ${_getAdStatusWithThrottling('offlineincome2x', isOfflineincome2xAdReady)}\n";
    
    // Show throttled ad types
    final throttledTypes = _adTypeThrottled.entries.where((e) => e.value == true).map((e) => e.key).toList();
    if (throttledTypes.isNotEmpty) {
      status += "⏸️ Throttled: ${throttledTypes.join(", ")}\n";
    }
    
    // Show consecutive failures
    final failingTypes = _consecutiveFailures.entries.where((e) => e.value > 0).toList();
    if (failingTypes.isNotEmpty) {
      status += "🔄 Failures: ";
      for (final entry in failingTypes) {
        status += "${entry.key}(${entry.value}) ";
      }
      status += "\n";
    }
    
    if (_lastAdError != null) {
      status += "Last Error: $_lastAdError\n";
    }
    
    return status;
  }
  
  // Helper function to show ad status with throttling information
  String _getAdStatusWithThrottling(String adType, bool isReady) {
    if (_adTypeThrottled[adType] == true) {
      return "⏸️";
    }
    return isReady ? "✅" : "❌";
  }
  
  // MANUAL RECOVERY: Reset throttling for a specific ad type
  void resetAdTypeThrottling(String adType) {
    _consecutiveFailures[adType] = 0;
    _adTypeThrottled[adType] = false;
    _lastFailureTime[adType] = null;
    if (kDebugMode) {
      print('🔄 Manually reset throttling for $adType');
    }
  }
  
  // MANUAL RECOVERY: Reset throttling for all ad types
  void resetAllAdThrottling() {
    _consecutiveFailures.clear();
    _adTypeThrottled.clear();
    _lastFailureTime.clear();
    if (kDebugMode) {
      print('🔄 Manually reset throttling for all ad types');
    }
    
    // Trigger predictive loading after reset
    Future.delayed(const Duration(milliseconds: 500), () {
      _performPredictiveLoading();
    });
  }
  
  // Getter methods for ad readiness (useful for UI)
  bool get isHustleBoostAdReady => _isAdValid(_hustleBoostAd, _hustleBoostAdLoadTime) && (_adTypeThrottled['hustleBoost'] ?? false) == false;
  bool get isBuildSkipAdReady => _isAdValid(_buildSkipAd, _buildSkipAdLoadTime) && (_adTypeThrottled['buildSkip'] ?? false) == false;
  bool get isEventClearAdReady => _isAdValid(_eventClearAd, _eventClearAdLoadTime) && (_adTypeThrottled['eventClear'] ?? false) == false;
  bool get isOfflineincome2xAdReady => _isAdValid(_offlineincome2xAd, _offlineincome2xAdLoadTime) && (_adTypeThrottled['offlineincome2x'] ?? false) == false;

  // Dispose all ads
  void dispose() {
    _hustleBoostAd?.dispose();
    _buildSkipAd?.dispose();
    _eventClearAd?.dispose();
    _offlineincome2xAd?.dispose();
    
    _hustleBoostAd = null;
    _buildSkipAd = null;
    _eventClearAd = null;
    _offlineincome2xAd = null;
    
    // Clean up delayed reward state
    _hustleBoostRewardEarned = false;
    _buildSkipRewardEarned = false;
    _eventClearRewardEarned = false;
    _offlineincome2xRewardEarned = false;
    _pendingHustleBoostCallback = null;
    _pendingBuildSkipCallback = null;
    _pendingEventClearCallback = null;
    _pendingOfflineincome2xCallback = null;
    
    debugPrint('🧹 AdMob service disposed');
  }
} 