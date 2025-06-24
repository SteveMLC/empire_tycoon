import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';

/// AdMob service for handling rewarded ads across the Empire Tycoon game
/// 
/// This service manages four primary ad placements with proper reward validation:
/// 1. HustleBoost (10x earnings for 60 seconds) - Reward: 'HustleBoost'
/// 2. BuildingUpgradeBoost (reduce upgrade time by 15 minutes) - Reward: 'BuildingUpgradeBoost'
/// 3. EventAdSkip (resolve events immediately) - Reward: 'EventAdSkip'
/// 4. OfflineIncomeBoost (2x offline income) - Reward: 'OfflineIncomeBoost'
/// 
/// Each reward ad provides the adtype and rewardtype matching the ad name.
/// The reward for watching an ad is the adname itself.
class AdMobService {
  static AdMobService? _instance;
  static AdMobService get instance => _instance ??= AdMobService._internal();
  
  AdMobService._internal();

  // ⚠️ PLAY STORE SUBMISSION FLAG ⚠️
  // Set this to FALSE when submitting to Google Play Store
  // Set this to TRUE after approval with production ad unit IDs
  static const bool _adsEnabled = true;

  // Test Ad Unit IDs (use these during development/testing)
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  
  // Production Ad Unit IDs (updated with actual AdMob ad unit IDs)
  static const String _prodHustleBoostAdUnitId = 'ca-app-pub-1738655803893663/5010660196';
  static const String _prodBuildSkipAdUnitId = 'ca-app-pub-1738655803893663/3789077869';
  static const String _prodEventClearAdUnitId = 'ca-app-pub-1738655803893663/4305735571';
  static const String _prodOfflineIncomeBoostAdUnitId = 'ca-app-pub-1738655803893663/2711799918';

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
  bool get isHustleBoostAdReady => _adsEnabled ? _hustleBoostAd != null : true;
  bool get isBuildSkipAdReady => _adsEnabled ? _buildSkipAd != null : true;
  bool get isEventClearAdReady => _adsEnabled ? _eventClearAd != null : true;
  bool get isOfflineIncomeBoostAdReady => _adsEnabled ? _offlineIncomeBoostAd != null : true;

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
    if (!_adsEnabled) return; // Skip loading if ads are disabled
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
    if (!_adsEnabled) return; // Skip loading if ads are disabled
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
    if (!_adsEnabled) return; // Skip loading if ads are disabled
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
    if (!_adsEnabled) return; // Skip loading if ads are disabled
    if (_isOfflineIncomeBoostAdLoading || _offlineIncomeBoostAd != null) return;
    _isOfflineIncomeBoostAdLoading = true;
    
    if (kDebugMode) {
      print('🎯 Loading Offline Income Boost Ad...');
      print('🎯 Ad Unit ID: ${_getAdUnitId(AdType.offlineIncomeBoost)}');
    }
    
    await RewardedAd.load(
      adUnitId: _getAdUnitId(AdType.offlineIncomeBoost),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          if (kDebugMode) {
            print('✅ Offline Income Boost Ad loaded successfully');
          }
          _offlineIncomeBoostAd = ad;
          _isOfflineIncomeBoostAdLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          if (kDebugMode) {
            print('❌ Offline Income Boost Ad failed to load:');
            print('   Error Code: ${error.code}');
            print('   Error Message: ${error.message}');
            print('   Error Domain: ${error.domain}');
          }
          _logError('Offline Income Boost Ad Load Failed: ${error.message} (Code: ${error.code})');
          _isOfflineIncomeBoostAdLoading = false;
          Future.delayed(const Duration(seconds: 30), () {
            if (!_isOfflineIncomeBoostAdLoading && _offlineIncomeBoostAd == null) {
              if (kDebugMode) {
                print('🔄 Retrying Offline Income Boost Ad load after 30 seconds...');
              }
              _loadOfflineIncomeBoostAd();
            }
          });
        },
      ),
    );
  }

  // Simplified show methods with proper reward type validation
  Future<void> showHustleBoostAd({
    required Function(String rewardType) onRewardEarned,
    Function()? onAdFailure,
  }) async {
    // If ads are disabled, immediately grant reward (for Play Store submission)
    if (!_adsEnabled) {
      if (kDebugMode) {
        print('🎯 Ads disabled - granting HustleBoost reward directly');
      }
      onRewardEarned('HustleBoost');
      return;
    }
    
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
        _trackAdShown('HustleBoost');
        if (kDebugMode) {
          print('🎁 User earned HustleBoost reward: ${reward.amount} ${reward.type}');
        }
        // Provide HustleBoost as the reward type
        onRewardEarned('HustleBoost');
      },
    );
  }

  Future<void> showBuildSkipAd({
    required Function(String rewardType) onRewardEarned,
    Function()? onAdFailure,
  }) async {
    // If ads are disabled, immediately grant reward (for Play Store submission)
    if (!_adsEnabled) {
      if (kDebugMode) {
        print('🎯 Ads disabled - granting BuildingUpgradeBoost reward directly');
      }
      onRewardEarned('BuildingUpgradeBoost');
      return;
    }
    
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
        _trackAdShown('BuildingUpgradeBoost');
        if (kDebugMode) {
          print('🎁 User earned BuildingUpgradeBoost reward: ${reward.amount} ${reward.type}');
        }
        // Provide BuildingUpgradeBoost as the reward type
        onRewardEarned('BuildingUpgradeBoost');
      },
    );
  }

  Future<void> showEventClearAd({
    required Function(String rewardType) onRewardEarned,
    Function()? onAdFailure,
  }) async {
    if (kDebugMode) {
      print('🎯 === EventAdSkip Ad Request ===');
      print('🎯 Ads Enabled: $_adsEnabled');
      print('🎯 Event Clear Ad Ready: $_eventClearAd != null');
    }
    
    // If ads are disabled, immediately grant reward (for Play Store submission)
    if (!_adsEnabled) {
      if (kDebugMode) {
        print('🎯 Ads disabled - granting EventAdSkip reward directly');
      }
      onRewardEarned('EventAdSkip');
      return;
    }
    
    if (_eventClearAd == null) {
      if (kDebugMode) {
        print('🎯 Event Clear Ad not loaded, attempting to load...');
      }
      await _loadEventClearAd();
      if (_eventClearAd == null) {
        if (kDebugMode) {
          print('❌ Event Clear Ad failed to load');
        }
        onAdFailure?.call();
        return;
      }
    }

    if (kDebugMode) {
      print('🎯 Event Clear Ad loaded successfully, setting up callbacks...');
    }

    _eventClearAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        if (kDebugMode) {
          print('🎯 Event Clear Ad dismissed (user closed ad)');
        }
        ad.dispose();
        _eventClearAd = null;
        Future.delayed(const Duration(seconds: 1), () => _loadEventClearAd());
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        if (kDebugMode) {
          print('❌ Event Clear Ad failed to show: ${error.message}');
        }
        ad.dispose();
        _eventClearAd = null;
        Future.delayed(const Duration(seconds: 1), () => _loadEventClearAd());
        onAdFailure?.call();
      },
    );

    if (kDebugMode) {
      print('🎯 Showing Event Clear Ad...');
    }

    await _eventClearAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        _trackAdShown('EventAdSkip');
        if (kDebugMode) {
          print('🎁 === EVENT AD REWARD EARNED ===');
          print('🎁 Reward Amount: ${reward.amount}');
          print('🎁 Reward Type: ${reward.type}');
          print('🎁 Calling onRewardEarned with EventAdSkip...');
        }
        
        // Use a delayed callback to ensure UI has time to process
        Future.microtask(() {
          if (kDebugMode) {
            print('🎁 Executing EventAdSkip reward callback NOW');
          }
          onRewardEarned('EventAdSkip');
        });
      },
    );
    
    if (kDebugMode) {
      print('🎯 Event Clear Ad show() method completed');
    }
  }

  Future<void> showOfflineIncomeBoostAd({
    required Function(String rewardType) onRewardEarned,
    Function()? onAdFailure,
  }) async {
    if (kDebugMode) {
      print('🎯 === OfflineIncomeBoost Ad Request ===');
      print('🎯 Ads Enabled: $_adsEnabled');
      print('🎯 Offline Income Boost Ad Ready: $_offlineIncomeBoostAd != null');
    }
    
    // If ads are disabled, immediately grant reward (for Play Store submission)
    if (!_adsEnabled) {
      if (kDebugMode) {
        print('🎯 Ads disabled - granting OfflineIncomeBoost reward directly');
      }
      onRewardEarned('OfflineIncomeBoost');
      return;
    }
    
    if (_offlineIncomeBoostAd == null) {
      if (kDebugMode) {
        print('🎯 Offline Income Boost Ad not loaded, attempting to load...');
      }
      await _loadOfflineIncomeBoostAd();
      if (_offlineIncomeBoostAd == null) {
        if (kDebugMode) {
          print('❌ Offline Income Boost Ad failed to load');
        }
        onAdFailure?.call();
        return;
      }
    }

    if (kDebugMode) {
      print('🎯 Offline Income Boost Ad loaded successfully, setting up callbacks...');
    }

    _offlineIncomeBoostAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        if (kDebugMode) {
          print('🎯 Offline Income Boost Ad dismissed (user closed ad)');
        }
        ad.dispose();
        _offlineIncomeBoostAd = null;
        Future.delayed(const Duration(seconds: 1), () => _loadOfflineIncomeBoostAd());
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        if (kDebugMode) {
          print('❌ Offline Income Boost Ad failed to show: ${error.message}');
        }
        ad.dispose();
        _offlineIncomeBoostAd = null;
        Future.delayed(const Duration(seconds: 1), () => _loadOfflineIncomeBoostAd());
        onAdFailure?.call();
      },
    );

    if (kDebugMode) {
      print('🎯 Showing Offline Income Boost Ad...');
    }

    await _offlineIncomeBoostAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        _trackAdShown('OfflineIncomeBoost');
        if (kDebugMode) {
          print('🎁 === OFFLINE INCOME BOOST AD REWARD EARNED ===');
          print('🎁 Reward Amount: ${reward.amount}');
          print('🎁 Reward Type: ${reward.type}');
          print('🎁 Calling onRewardEarned with OfflineIncomeBoost...');
        }
        
        // Use a delayed callback to ensure UI has time to process
        Future.microtask(() {
          if (kDebugMode) {
            print('🎁 Executing OfflineIncomeBoost reward callback NOW');
          }
          onRewardEarned('OfflineIncomeBoost');
        });
      },
    );
    
    if (kDebugMode) {
      print('🎯 Offline Income Boost Ad show() method completed');
    }
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

  // Debug method specifically for offline income ads
  void debugOfflineIncomeAd() {
    if (kDebugMode) {
      print('🔍 === OFFLINE INCOME AD DEBUG ===');
      print('🔍 Ads Enabled: $_adsEnabled');
      print('🔍 Ad Instance: $_offlineIncomeBoostAd');
      print('🔍 Is Loading: $_isOfflineIncomeBoostAdLoading');
      print('🔍 Is Ready: $isOfflineIncomeBoostAdReady');
      print('🔍 Ad Unit ID: ${_getAdUnitId(AdType.offlineIncomeBoost)}');
      print('🔍 Last Error: $_lastAdError');
      print('🔍 Last Error Time: $_lastErrorTime');
      print('🔍 === END OFFLINE INCOME AD DEBUG ===');
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