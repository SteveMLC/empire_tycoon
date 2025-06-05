import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';

/// AdMob service for handling rewarded ads across the Empire Tycoon game
/// 
/// This service manages four primary ad placements:
/// 1. Hustle Boost (10x earnings for 60 seconds)
/// 2. Build Upgrade Skip (reduce upgrade time by 15 minutes)
/// 3. Event Clear (resolve events immediately)
/// 4. Offline Income Boost (2x offline income)
class AdMobService {
  static AdMobService? _instance;
  static AdMobService get instance => _instance ??= AdMobService._internal();
  
  AdMobService._internal();

  // Test Ad Unit IDs (use these during development/testing)
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  
  // Production Ad Unit IDs (replace these with your actual AdMob ad unit IDs)
  static const String _prodHustleBoostAdUnitId = 'ca-app-pub-1738655803893663/HUSTLE_BOOST_AD_UNIT';
  static const String _prodBuildSkipAdUnitId = 'ca-app-pub-1738655803893663/BUILD_SKIP_AD_UNIT';
  static const String _prodEventClearAdUnitId = 'ca-app-pub-1738655803893663/EVENT_CLEAR_AD_UNIT';
  static const String _prodOfflineIncomeBoostAdUnitId = 'ca-app-pub-1738655803893663/OFFLINE_INCOME_BOOST_AD_UNIT';

  // Test device IDs for development (add your device IDs here)
  static const List<String> _testDeviceIds = [
    'YOUR_DEVICE_ID_HERE', // Replace with actual test device IDs
    // Add more test device IDs as needed
  ];

  // Current ad instances
  RewardedAd? _hustleBoostAd;
  RewardedAd? _buildSkipAd;
  RewardedAd? _eventClearAd;
  RewardedAd? _offlineIncomeBoostAd;

  // Simple loading states
  bool _isHustleBoostAdLoading = false;
  bool _isBuildSkipAdLoading = false;
  bool _isEventClearAdLoading = false;
  bool _isOfflineIncomeBoostAdLoading = false;

  // Error tracking for better debugging
  String? _lastAdError;
  DateTime? _lastErrorTime;

  // Performance tracking
  int _totalAdsShown = 0;
  int _totalAdsClicked = 0;
  int _totalAdFailures = 0;
  DateTime? _sessionStartTime;

  // Ad availability states
  bool get isHustleBoostAdReady => _hustleBoostAd != null;
  bool get isBuildSkipAdReady => _buildSkipAd != null;
  bool get isEventClearAdReady => _eventClearAd != null;
  bool get isOfflineIncomeBoostAdReady => _offlineIncomeBoostAd != null;

  // Get last error for debugging
  String? get lastAdError => _lastAdError;
  DateTime? get lastErrorTime => _lastErrorTime;

  // Performance metrics getters
  int get totalAdsShown => _totalAdsShown;
  int get totalAdFailures => _totalAdFailures;
  double get adSuccessRate => _totalAdsShown + _totalAdFailures > 0 
      ? _totalAdsShown / (_totalAdsShown + _totalAdFailures) 
      : 0.0;

  // Initialize the AdMob SDK
  Future<void> initialize() async {
    try {
      _sessionStartTime = DateTime.now();
      
      if (kDebugMode) {
        print('🎯 Starting AdMob SDK initialization...');
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
        print('🎯 Starting ad preloading...');
      }
      
      // Staggered loading to prevent rate limiting
      _loadHustleBoostAd();
      await Future.delayed(const Duration(seconds: 2));
      
      _loadBuildSkipAd();
      await Future.delayed(const Duration(seconds: 2));
      
      _loadEventClearAd();
      await Future.delayed(const Duration(seconds: 2));
      
      _loadOfflineIncomeBoostAd();
      
      if (kDebugMode) {
        print('🎯 AdMob initialization complete');
        print('🎯 Ad readiness status:');
        print('   - Hustle Boost: ${isHustleBoostAdReady}');
        print('   - Build Skip: ${isBuildSkipAdReady}');
        print('   - Event Clear: ${isEventClearAdReady}');
        print('   - Offline Income Boost: ${isOfflineIncomeBoostAdReady}');
      }
      
    } catch (e, stackTrace) {
      _logError('AdMob initialization failed: $e');
      if (kDebugMode) {
        print('❌ AdMob initialization failed: $e');
        print('❌ Stack trace: $stackTrace');
      }
      // Continue app execution even if AdMob fails
    }
  }

  // Helper method to log errors with timestamp
  void _logError(String error) {
    _lastAdError = error;
    _lastErrorTime = DateTime.now();
    _totalAdFailures++;
  }

  // Helper method to track successful ad shows
  void _trackAdShown(String adType) {
    _totalAdsShown++;
    if (kDebugMode) {
      print('📊 Ad shown: $adType (Total: $_totalAdsShown, Success Rate: ${(adSuccessRate * 100).toStringAsFixed(1)}%)');
    }
  }

  // Generate performance report
  Map<String, dynamic> getPerformanceReport() {
    final now = DateTime.now();
    final sessionDuration = _sessionStartTime != null 
        ? now.difference(_sessionStartTime!).inMinutes 
        : 0;
    
    return {
      'sessionDurationMinutes': sessionDuration,
      'totalAdsShown': _totalAdsShown,
      'totalAdFailures': _totalAdFailures,
      'successRate': adSuccessRate,
      'adsReadyCount': [
        isHustleBoostAdReady,
        isBuildSkipAdReady,
        isEventClearAdReady,
        isOfflineIncomeBoostAdReady,
      ].where((ready) => ready).length,
      'lastError': _lastAdError,
      'lastErrorTime': _lastErrorTime?.toIso8601String(),
    };
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
      case AdType.offlineIncomeBoost:
        return _prodOfflineIncomeBoostAdUnitId;
    }
  }

  // Simplified ad loading methods
  Future<void> _loadHustleBoostAd() async {
    if (_isHustleBoostAdLoading || _hustleBoostAd != null) return;
    _isHustleBoostAdLoading = true;
    
    await RewardedAd.load(
      adUnitId: _getAdUnitId(AdType.hustleBoost),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _hustleBoostAd = ad;
          _isHustleBoostAdLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isHustleBoostAdLoading = false;
          // Simple retry after delay
          Future.delayed(const Duration(seconds: 30), () {
            if (!_isHustleBoostAdLoading && _hustleBoostAd == null) {
              _loadHustleBoostAd();
            }
          });
        },
      ),
    );
  }

  Future<void> _loadBuildSkipAd() async {
    if (_isBuildSkipAdLoading || _buildSkipAd != null) return;
    _isBuildSkipAdLoading = true;
    
    await RewardedAd.load(
      adUnitId: _getAdUnitId(AdType.buildSkip),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _buildSkipAd = ad;
          _isBuildSkipAdLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isBuildSkipAdLoading = false;
          Future.delayed(const Duration(seconds: 30), () {
            if (!_isBuildSkipAdLoading && _buildSkipAd == null) {
              _loadBuildSkipAd();
            }
          });
        },
      ),
    );
  }

  Future<void> _loadEventClearAd() async {
    if (_isEventClearAdLoading || _eventClearAd != null) return;
    _isEventClearAdLoading = true;
    
    await RewardedAd.load(
      adUnitId: _getAdUnitId(AdType.eventClear),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _eventClearAd = ad;
          _isEventClearAdLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isEventClearAdLoading = false;
          Future.delayed(const Duration(seconds: 30), () {
            if (!_isEventClearAdLoading && _eventClearAd == null) {
              _loadEventClearAd();
            }
          });
        },
      ),
    );
  }

  Future<void> _loadOfflineIncomeBoostAd() async {
    if (_isOfflineIncomeBoostAdLoading || _offlineIncomeBoostAd != null) return;
    _isOfflineIncomeBoostAdLoading = true;
    
    await RewardedAd.load(
      adUnitId: _getAdUnitId(AdType.offlineIncomeBoost),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _offlineIncomeBoostAd = ad;
          _isOfflineIncomeBoostAdLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isOfflineIncomeBoostAdLoading = false;
          Future.delayed(const Duration(seconds: 30), () {
            if (!_isOfflineIncomeBoostAdLoading && _offlineIncomeBoostAd == null) {
              _loadOfflineIncomeBoostAd();
            }
          });
        },
      ),
    );
  }

  // Simplified show methods
  Future<void> showHustleBoostAd({
    required Function() onRewardEarned,
    Function()? onAdFailure,
  }) async {
    if (_hustleBoostAd == null) {
      await _loadHustleBoostAd();
      if (_hustleBoostAd == null) {
        onAdFailure?.call();
        return;
      }
    }

    _hustleBoostAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        _hustleBoostAd = null;
        _loadHustleBoostAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        ad.dispose();
        _hustleBoostAd = null;
        _loadHustleBoostAd();
        onAdFailure?.call();
      },
    );

    await _hustleBoostAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        _trackAdShown('Hustle Boost');
        if (kDebugMode) {
          print('🎁 User earned Hustle Boost reward: ${reward.amount} ${reward.type}');
        }
        onRewardEarned();
      },
    );
  }

  Future<void> showBuildSkipAd({
    required Function() onRewardEarned,
    Function()? onAdFailure,
  }) async {
    if (_buildSkipAd == null) {
      await _loadBuildSkipAd();
      if (_buildSkipAd == null) {
        onAdFailure?.call();
        return;
      }
    }

    _buildSkipAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        _buildSkipAd = null;
        // Staggered reload to prevent conflicts
        Future.delayed(const Duration(seconds: 1), () => _loadBuildSkipAd());
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        ad.dispose();
        _buildSkipAd = null;
        Future.delayed(const Duration(seconds: 1), () => _loadBuildSkipAd());
        onAdFailure?.call();
      },
    );

    await _buildSkipAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        _trackAdShown('Build Skip');
        if (kDebugMode) {
          print('🎁 User earned Build Skip reward: ${reward.amount} ${reward.type}');
        }
        onRewardEarned();
      },
    );
  }

  Future<void> showEventClearAd({
    required Function() onRewardEarned,
    Function()? onAdFailure,
  }) async {
    if (_eventClearAd == null) {
      await _loadEventClearAd();
      if (_eventClearAd == null) {
        onAdFailure?.call();
        return;
      }
    }

    _eventClearAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        _eventClearAd = null;
        Future.delayed(const Duration(seconds: 1), () => _loadEventClearAd());
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        ad.dispose();
        _eventClearAd = null;
        Future.delayed(const Duration(seconds: 1), () => _loadEventClearAd());
        onAdFailure?.call();
      },
    );

    await _eventClearAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        _trackAdShown('Event Clear');
        if (kDebugMode) {
          print('🎁 User earned Event Clear reward: ${reward.amount} ${reward.type}');
        }
        onRewardEarned();
      },
    );
  }

  Future<void> showOfflineIncomeBoostAd({
    required Function() onRewardEarned,
    Function()? onAdFailure,
  }) async {
    if (_offlineIncomeBoostAd == null) {
      await _loadOfflineIncomeBoostAd();
      if (_offlineIncomeBoostAd == null) {
        onAdFailure?.call();
        return;
      }
    }

    _offlineIncomeBoostAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        _offlineIncomeBoostAd = null;
        Future.delayed(const Duration(seconds: 1), () => _loadOfflineIncomeBoostAd());
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        ad.dispose();
        _offlineIncomeBoostAd = null;
        Future.delayed(const Duration(seconds: 1), () => _loadOfflineIncomeBoostAd());
        onAdFailure?.call();
      },
    );

    await _offlineIncomeBoostAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        _trackAdShown('Offline Income Boost');
        if (kDebugMode) {
          print('🎁 User earned Offline Income Boost reward: ${reward.amount} ${reward.type}');
        }
        onRewardEarned();
      },
    );
  }

  // Debug status for troubleshooting
  void printDebugStatus() {
    if (kDebugMode) {
      final report = getPerformanceReport();
      print('🎯 === AdMob Debug Status ===');
      print('🎯 Session Duration: ${report['sessionDurationMinutes']} minutes');
      print('🎯 Ads Shown: ${report['totalAdsShown']} | Failures: ${report['totalAdFailures']} | Success Rate: ${(report['successRate'] * 100).toStringAsFixed(1)}%');
      print('🎯 Hustle Boost Ad: ${isHustleBoostAdReady ? "✅ Ready" : "❌ Not Ready"} (Loading: $_isHustleBoostAdLoading)');
      print('🎯 Build Skip Ad: ${isBuildSkipAdReady ? "✅ Ready" : "❌ Not Ready"} (Loading: $_isBuildSkipAdLoading)');
      print('🎯 Event Clear Ad: ${isEventClearAdReady ? "✅ Ready" : "❌ Not Ready"} (Loading: $_isEventClearAdLoading)');
      print('🎯 Offline Income Boost Ad: ${isOfflineIncomeBoostAdReady ? "✅ Ready" : "❌ Not Ready"} (Loading: $_isOfflineIncomeBoostAdLoading)');
      print('🎯 Ready Ads Count: ${report['adsReadyCount']}/4');
      print('🎯 Test Ad Unit ID: $_testRewardedAdUnitId');
      print('🎯 Debug Mode: ${kDebugMode}');
      if (_lastAdError != null) {
        print('🎯 Last Error: $_lastAdError (${_lastErrorTime})');
      }
      print('🎯 === End Debug Status ===');
    }
  }

  // Dispose all ads
  void dispose() {
    _hustleBoostAd?.dispose();
    _buildSkipAd?.dispose();
    _eventClearAd?.dispose();
    _offlineIncomeBoostAd?.dispose();
    
    _hustleBoostAd = null;
    _buildSkipAd = null;
    _eventClearAd = null;
    _offlineIncomeBoostAd = null;
    
    if (kDebugMode) {
      print('🧹 AdMob service disposed');
    }
  }
}

// Enum to identify different ad types
enum AdType {
  hustleBoost,
  buildSkip,
  eventClear,
  offlineIncomeBoost,
} 