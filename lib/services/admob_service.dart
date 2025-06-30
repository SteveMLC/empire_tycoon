import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';

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
class AdMobService {
  // Singleton instance
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // Ad configuration
  static const bool _adsEnabled = true;
  
  // Test ad unit ID (works for all ad types in debug)
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  
  // Production ad unit IDs
  static const String _prodHustleBoostAdUnitId = 'ca-app-pub-6244589384499050/6240031806';
  static const String _prodBuildSkipAdUnitId = 'ca-app-pub-6244589384499050/5369509827';
  static const String _prodEventClearAdUnitId = 'ca-app-pub-6244589384499050/4905753152';
  static const String _prodOfflineincome2xAdUnitId = 'ca-app-pub-6244589384499050/4433996478';
  
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
      if (kDebugMode) {
        print('🎯 Game state updated: User owns $_userBusinessCount businesses');
      }
    }
    
    if (firstBusinessLevel != null && firstBusinessLevel != _firstBusinessLevel) {
      _firstBusinessLevel = firstBusinessLevel;
      stateChanged = true;
      if (kDebugMode) {
        print('🎯 Game state updated: First business level $_firstBusinessLevel');
      }
    }
    
    if (hasActiveEvents != null && hasActiveEvents != _hasActiveEvents) {
      _hasActiveEvents = hasActiveEvents;
      stateChanged = true;
      if (kDebugMode) {
        print('🎯 Game state updated: Active events = $_hasActiveEvents');
      }
    }
    
    if (currentScreen != null && currentScreen != _currentScreen) {
      _currentScreen = currentScreen;
      stateChanged = true;
      if (kDebugMode) {
        print('🎯 Screen changed: $_currentScreen');
      }
    }
    
    if (isReturningFromBackground != null) {
      _isReturningFromBackground = isReturningFromBackground;
      stateChanged = true;
      if (kDebugMode) {
        print('🎯 Background return: $_isReturningFromBackground');
      }
    }
    
    if (hasOfflineIncome != null && hasOfflineIncome != _hasOfflineIncome) {
      _hasOfflineIncome = hasOfflineIncome;
      stateChanged = true;
      if (kDebugMode) {
        print('🎯 Offline income available: $_hasOfflineIncome');
      }
    }
    
    // Trigger predictive loading based on state changes
    if (stateChanged) {
      _performPredictiveLoading();
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
    }
    
    // 1. HustleBoost: Always preload (main screen accessible anytime)
    if (!_isAdValid(_hustleBoostAd, _hustleBoostAdLoadTime) && !_isHustleBoostAdLoading) {
      if (kDebugMode) print('🎯 Loading HustleBoost (always available)');
      _loadHustleBoostAd();
    }
    
    // 2. BuildSkip: Context-aware loading
    bool shouldLoadBuildSkip = _userBusinessCount >= 2 || 
                              _currentScreen == 'business' ||
                              _firstBusinessLevel >= 3;
    
    if (shouldLoadBuildSkip && !_isAdValid(_buildSkipAd, _buildSkipAdLoadTime) && !_isBuildSkipAdLoading) {
      if (kDebugMode) print('🎯 Loading BuildSkip (context-aware)');
      if (kDebugMode) print('🎯 Loading BuildSkip ad (context-aware: $_userBusinessCount businesses, level $_firstBusinessLevel)...');
      _loadBuildSkipAd();
    }
    
    // 3. EventClear: Event-based preloading
    if (_hasActiveEvents && !_isAdValid(_eventClearAd, _eventClearAdLoadTime) && !_isEventClearAdLoading) {
      if (kDebugMode) print('🎯 Loading EventClear (events active)');
      _loadEventClearAd();
    }
    
    // 4. Offlineincome2x: ENHANCED - Preload when offline income is available OR returning from background
    // CRITICAL FIX: Check for active offline income, not just background return
    bool shouldLoadOfflineIncomeAd = _isReturningFromBackground || _hasOfflineIncome;
    
    if (shouldLoadOfflineIncomeAd && !_isAdValid(_offlineincome2xAd, _offlineincome2xAdLoadTime) && !_isOfflineincome2xAdLoading) {
      if (kDebugMode) {
        String reason = _isReturningFromBackground ? 'background return' : 'offline income available';
        print('🎯 Loading Offlineincome2x ($reason)');
        print('🎯 Loading Offlineincome2x ad ($reason)...');
      }
      _loadOfflineincome2xAd();
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

  // Ad readiness checking
  bool get isHustleBoostAdReady => _isAdValid(_hustleBoostAd, _hustleBoostAdLoadTime);
  bool get isBuildSkipAdReady => _isAdValid(_buildSkipAd, _buildSkipAdLoadTime);
  bool get isEventClearAdReady => _isAdValid(_eventClearAd, _eventClearAdLoadTime);
  bool get isOfflineincome2xAdReady => _isAdValid(_offlineincome2xAd, _offlineincome2xAdLoadTime);

  // Check if an ad is valid and not expired (50-minute window for safety)
  bool _isAdValid(RewardedAd? ad, DateTime? loadTime) {
    if (ad == null || loadTime == null) return false;
    final ageInMinutes = DateTime.now().difference(loadTime).inMinutes;
    return ageInMinutes < 50; // 10-minute safety buffer before 1-hour expiration
  }

  // ENHANCED: Debug status with comprehensive revenue analytics
  void printDebugStatus() {
    if (kDebugMode) {
      final analytics = getRevenueAnalytics();
      print('🎯 === AdMob Predictive Loading Analytics ===');
      print('🎯 Session Duration: ${analytics['sessionDurationMinutes']} minutes');
      print('🎯 Total Requests: ${analytics['totalRequests']}');
      print('🎯 Total Successes: ${analytics['totalShowSuccesses']}');
      print('🎯 Total Failures: ${analytics['totalShowFailures']}');
      print('🎯 Impression Loss Rate: ${analytics['impressionLossRate'].toStringAsFixed(1)}%');
      
      print('🎯 Predictive Loading Status:');
      
      // HustleBoost - Always ready
      final hustleReady = isHustleBoostAdReady;
      final hustleAge = _hustleBoostAdLoadTime != null 
          ? DateTime.now().difference(_hustleBoostAdLoadTime!).inMinutes 
          : null;
      print('   ✨ HustleBoost: ${hustleReady ? "✅ Ready" : "❌ Not Ready"} (Loading: $_isHustleBoostAdLoading)');
      if (hustleAge != null) {
        print('     Strategy: ALWAYS READY (Age: ${hustleAge}min, ${hustleAge < 50 ? "Fresh" : "Near Expiry"})');
      }
      
      // BuildSkip - Context-aware
      final buildReady = isBuildSkipAdReady;
      final shouldLoad = _shouldLoadBuildSkipAd();
      print('   🏢 BuildSkip: ${buildReady ? "✅ Ready" : "❌ Not Ready"} (Loading: $_isBuildSkipAdLoading)');
      print('     Strategy: CONTEXT-AWARE (Should load: $shouldLoad)');
      print('     Context: $_userBusinessCount businesses, level $_firstBusinessLevel, screen: $_currentScreen');
      
      // EventClear - Event-based
      print('   ⚡ EventClear: ${isEventClearAdReady ? "✅ Ready" : "❌ Not Ready"} (Loading: $_isEventClearAdLoading)');
      print('     Strategy: EVENT-BASED (Events active: $_hasActiveEvents)');
      
      // Offlineincome2x - Lifecycle-based
      print('   💰 Offlineincome2x: ${isOfflineincome2xAdReady ? "✅ Ready" : "❌ Not Ready"} (Loading: $_isOfflineincome2xAdLoading)');
      print('     Strategy: LIFECYCLE-BASED (Background return: $_isReturningFromBackground)');
      
      // Show recent errors for each ad type
      for (String adType in ['hustleBoost', 'buildSkip', 'eventClear', 'offlineincome2x']) {
        final errors = analytics['byAdType'][adType]['errors'] as List;
        if (errors.isNotEmpty) {
          print('🎯 Recent $adType errors: ${errors.take(2).join(', ')}');
        }
      }
      
      if (_lastAdError != null) {
        print('🎯 Last Error: $_lastAdError (${_lastErrorTime})');
      }
      print('🎯 === End Predictive Analytics ===');
    }
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
          if (kDebugMode) {
            print('✅ HustleBoost ad loaded - Ready for instant use');
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isHustleBoostAdLoading = false;
          _logAdError('hustleBoost', 'Load failed: ${error.code} - ${error.message}');
          if (kDebugMode) {
            print('❌ HustleBoost ad load failed: ${error.code} - ${error.message}');
          }
          // Retry after delay
          Future.delayed(const Duration(seconds: 30), () {
            if (!_isHustleBoostAdLoading && !_isAdValid(_hustleBoostAd, _hustleBoostAdLoadTime)) {
              _loadHustleBoostAd();
            }
          });
        },
      ),
    );
  }

  // PREDICTIVE: BuildSkip ad loading (context-aware)
  Future<void> _loadBuildSkipAd() async {
    if (!_adsEnabled) return;
    if (_isBuildSkipAdLoading || _isAdValid(_buildSkipAd, _buildSkipAdLoadTime)) return;
    
    _isBuildSkipAdLoading = true;
    _adRequestCounts['buildSkip'] = (_adRequestCounts['buildSkip'] ?? 0) + 1;
    
    if (kDebugMode) {
      print('🎯 Loading BuildSkip ad (context-aware: ${_userBusinessCount} businesses, level ${_firstBusinessLevel})...');
    }
    
    await RewardedAd.load(
      adUnitId: _getAdUnitId(AdType.buildSkip),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _buildSkipAd = ad;
          _isBuildSkipAdLoading = false;
          _buildSkipAdLoadTime = DateTime.now();
          if (kDebugMode) {
            print('✅ BuildSkip ad loaded - Ready for instant business upgrades');
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isBuildSkipAdLoading = false;
          _logAdError('buildSkip', 'Load failed: ${error.code} - ${error.message}');
          if (kDebugMode) {
            print('❌ BuildSkip ad load failed: ${error.code} - ${error.message}');
          }
          // Retry after delay
          Future.delayed(const Duration(seconds: 30), () {
            if (!_isBuildSkipAdLoading && !_isAdValid(_buildSkipAd, _buildSkipAdLoadTime)) {
              _loadBuildSkipAd();
            }
          });
        },
      ),
    );
  }

  // PREDICTIVE: EventClear ad loading (event-based)
  Future<void> _loadEventClearAd() async {
    if (!_adsEnabled) return;
    if (_isEventClearAdLoading || _isAdValid(_eventClearAd, _eventClearAdLoadTime)) return;
    
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
          // Retry after delay
          Future.delayed(const Duration(seconds: 30), () {
            if (!_isEventClearAdLoading && !_isAdValid(_eventClearAd, _eventClearAdLoadTime)) {
              _loadEventClearAd();
            }
          });
        },
      ),
    );
  }

  // PREDICTIVE: Offlineincome2x ad loading (lifecycle-based)
  Future<void> _loadOfflineincome2xAd() async {
    if (!_adsEnabled) return;
    if (_isOfflineincome2xAdLoading || _isAdValid(_offlineincome2xAd, _offlineincome2xAdLoadTime)) return;
    
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
          // Retry after delay
          Future.delayed(const Duration(seconds: 30), () {
            if (!_isOfflineincome2xAdLoading && !_isAdValid(_offlineincome2xAd, _offlineincome2xAdLoadTime)) {
              _loadOfflineincome2xAd();
            }
          });
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
        ad.dispose();
        _hustleBoostAd = null;
        _hustleBoostAdLoadTime = null;
        
        // Immediately reload for next use (predictive)
        _loadHustleBoostAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        _logAdError('hustleBoost', 'Show failed: ${error.code} - ${error.message}');
        if (kDebugMode) print('❌ HustleBoost ad failed to show: ${error.code} - ${error.message}');
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
      if (kDebugMode) print('🎁 User earned HustleBoost reward: ${reward.amount} ${reward.type}');
      onRewardEarned('HustleBoost');
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

    _buildSkipAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        if (kDebugMode) print('🎯 BuildSkip ad displayed');
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        if (kDebugMode) print('🎯 BuildSkip ad dismissed (user closed ad)');
        ad.dispose();
        _buildSkipAd = null;
        _buildSkipAdLoadTime = null;
        
        // Intelligently reload based on context
        if (_shouldLoadBuildSkipAd()) {
          _loadBuildSkipAd();
        }
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        _logAdError('buildSkip', 'Show failed: ${error.code} - ${error.message}');
        if (kDebugMode) print('❌ BuildSkip ad failed to show: ${error.code} - ${error.message}');
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
      if (kDebugMode) print('🎁 User earned BuildingUpgradeBoost reward: ${reward.amount} ${reward.type}');
      onRewardEarned('BuildingUpgradeBoost');
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

    _eventClearAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        if (kDebugMode) print('🎯 EventClear ad displayed');
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        if (kDebugMode) print('🎯 EventClear ad dismissed (user closed ad)');
        ad.dispose();
        _eventClearAd = null;
        _eventClearAdLoadTime = null;
        
        // Reload if events are still active
        if (_hasActiveEvents) {
          _loadEventClearAd();
        }
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        _logAdError('eventClear', 'Show failed: ${error.code} - ${error.message}');
        if (kDebugMode) print('❌ EventClear ad failed to show: ${error.code} - ${error.message}');
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
      if (kDebugMode) print('🎁 User earned EventAdSkip reward: ${reward.amount} ${reward.type}');
      onRewardEarned('EventAdSkip');
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

    _offlineincome2xAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        if (kDebugMode) print('🎯 Offlineincome2x ad displayed');
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        if (kDebugMode) print('🎯 Offlineincome2x ad dismissed (user closed ad)');
        ad.dispose();
        _offlineincome2xAd = null;
        _offlineincome2xAdLoadTime = null;
        
        // Reset background return flag and don't immediately reload
        // (user may not need another offline income boost soon)
        _isReturningFromBackground = false;
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        _logAdError('offlineincome2x', 'Show failed: ${error.code} - ${error.message}');
        if (kDebugMode) print('❌ Offlineincome2x ad failed to show: ${error.code} - ${error.message}');
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
      if (kDebugMode) print('🎁 User earned Offlineincome2x reward: ${reward.amount} ${reward.type}');
      onRewardEarned('Offlineincome2x');
    });
  }

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
    
    if (kDebugMode) {
      print('🧹 AdMob service disposed');
    }
  }
} 