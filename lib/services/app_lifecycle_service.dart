import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import 'notification_service.dart';
import 'income_service.dart';
import 'admob_service.dart';
import 'review_manager.dart';

/// Service that handles app lifecycle changes and coordinates notifications
/// Integrates with existing SoundManager lifecycle handling
/// ENHANCED: Now handles background time as offline time for better user experience
/// ENHANCED: Integrated with AdMobService for predictive ad loading
class AppLifecycleService with WidgetsBindingObserver {
  static final AppLifecycleService _instance = AppLifecycleService._internal();
  factory AppLifecycleService() => _instance;
  AppLifecycleService._internal();

  final NotificationService _notificationService = NotificationService();
  GameState? _gameState;
  IncomeService? _incomeService;
  AdMobService? _adMobService;
  Future<void> Function()? _onSave;
  bool _isInitialized = false;
  bool _hasRequestedPermission = false;
  
  DateTime? _backgroundStartTime;
  static const int _minimumBackgroundSecondsForOfflineIncome = 30;

  /// Initialize the lifecycle service
  /// ENHANCED: Now accepts IncomeService and AdMobService for consistent coordination
  /// ENHANCED: Optional onSave callback to persist game state when app goes to background
  Future<void> initialize(GameState gameState, {IncomeService? incomeService, AdMobService? adMobService, Future<void> Function()? onSave}) async {
    if (_isInitialized) return;
    
    _gameState = gameState;
    _incomeService = incomeService;
    _adMobService = adMobService;
    _onSave = onSave;
    
    // Initialize notification service
    await _notificationService.initialize();
    
    // Register for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    
    _isInitialized = true;
    debugPrint('✅ AppLifecycleService initialized with AdMobService integration');
    await ReviewManager.instance.initialize();
    unawaited(ReviewManager.instance.onAppResumed());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized || _gameState == null) return;
    
    debugPrint('🔄 App lifecycle state changed: $state');
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _handleAppGoingToBackground();
        break;
      case AppLifecycleState.resumed:
        _handleAppReturningToForeground();
        break;
      case AppLifecycleState.inactive:
        // Don't handle inactive state (brief interruptions)
        break;
    }
  }

  /// Handle app going to background
  /// ENHANCED: Now records background start time for offline income calculation
  void _handleAppGoingToBackground() {
    debugPrint('📱 App going to background - recording time and scheduling notifications');

    unawaited(_onSave?.call());
    unawaited(ReviewManager.instance.onAppPaused());

    _backgroundStartTime = DateTime.now();
    debugPrint('🕒 Background start time recorded: $_backgroundStartTime');
    
    // Schedule offline income notification if enabled
    if (_notificationService.offlineIncomeNotificationsEnabled) {
      _notificationService.scheduleOfflineIncomeNotification();
    }
  }

  /// Handle app returning to foreground
  /// ENHANCED: Now calculates offline income for background time if significant
  /// ENHANCED: Notifies AdMobService for predictive ad loading
  /// MITIGATION: Defer heavy work by ~300ms to reduce EGL/GPU stress during
  /// resume on MediaTek/PowerVR devices (avoids IMGeglMakeCurrent SIGSEGV).
  void _handleAppReturningToForeground() {
    debugPrint('📱 App returning to foreground');
    
    _notificationService.cancelOfflineIncomeNotification();
    unawaited(ReviewManager.instance.onAppResumed());
    
    // Defer heavy work so the EGL/surface can settle after resume (reduces
    // chance of IMGeglMakeCurrent crash on MediaTek/PowerVR devices).
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!_isInitialized || _gameState == null) return;
      _handleAppReturningToForegroundDeferred();
    });
  }

  void _handleAppReturningToForegroundDeferred() {
    // Clear Platinum Challenge if it expired or completed while app was in background
    if (_gameState != null) {
      _gameState!.checkAndClearExpiredPlatinumChallenge();
    }
    if (_backgroundStartTime != null && _gameState != null) {
      final DateTime now = DateTime.now();
      final Duration backgroundDuration = now.difference(_backgroundStartTime!);
      final int backgroundSeconds = backgroundDuration.inSeconds;
      
      debugPrint('🕒 App was in background for $backgroundSeconds seconds');
      
      if (backgroundSeconds >= _minimumBackgroundSecondsForOfflineIncome) {
        debugPrint('💰 Processing offline income for background time: ${backgroundSeconds}s');
        
        // ENHANCED: Notify AdMobService BEFORE processing offline income
        // This ensures the 2x ad is preloaded when the offline income notification appears
        if (_adMobService != null) {
          debugPrint('🎯 Notifying AdMobService of background return for predictive ad loading');
          _adMobService!.updateGameState(
            isReturningFromBackground: true,
            currentScreen: 'hustle', // User returning to main screen
            hasOfflineIncome: true, // About to create offline income
          );
        }
        
        _gameState!.processOfflineIncome(_backgroundStartTime!, incomeService: _incomeService);
        
        // ENHANCED: Notify AdMobService again after processing offline income to confirm availability
        if (_adMobService != null && _gameState!.showOfflineIncomeNotification) {
          _adMobService!.updateGameState(
            hasOfflineIncome: true, // Offline income now available
          );
        }
        
        debugPrint('✅ Background offline income processed with predictive ad loading');
      } else {
        debugPrint('⏭️ Background time too short for offline income (${backgroundSeconds}s < ${_minimumBackgroundSecondsForOfflineIncome}s)');
        
        // Still notify AdMobService of background return (without offline income context)
        if (_adMobService != null) {
          _adMobService!.updateGameState(
            isReturningFromBackground: false, // No offline income this time
            currentScreen: 'hustle',
            hasOfflineIncome: _gameState?.showOfflineIncomeNotification ?? false,
          );
        }
      }
    } else {
      debugPrint('ℹ️ No background start time recorded or game state unavailable');
      
      // Reset AdMobService background state if available
      if (_adMobService != null) {
        _adMobService!.updateGameState(
          isReturningFromBackground: false,
          currentScreen: 'hustle',
          hasOfflineIncome: _gameState?.showOfflineIncomeNotification ?? false,
        );
      }
    }
    
    _backgroundStartTime = null;
  }

  /// Request notification permissions after user milestone
  /// Call this when user completes their first business upgrade
  Future<void> requestNotificationPermissions(BuildContext context, {bool forceRequest = false}) async {
    if (!forceRequest && _hasRequestedPermission || !_isInitialized) return;
    
    // Show in-game permission dialog first
    final bool userWantsNotifications = await _notificationService.showPermissionDialog(context);
    
    if (userWantsNotifications) {
      // Request system permission
      final bool granted = await _notificationService.requestPermissions();
      debugPrint('🔔 Notification permissions ${granted ? 'granted' : 'denied'}');
    }
    
    _hasRequestedPermission = true;
  }

  /// Schedule business upgrade notification
  /// Called when a business upgrade starts
  Future<void> scheduleBusinessUpgradeNotification(
    String businessId,
    String businessName,
    Duration upgradeTime,
  ) async {
    if (!_isInitialized) return;
    
    await _notificationService.scheduleBusinessUpgradeNotification(
      businessId,
      businessName,
      upgradeTime,
    );
  }

  /// Cancel business upgrade notification
  /// Called when a business upgrade is rushed/completed early
  Future<void> cancelBusinessUpgradeNotification(String businessId) async {
    if (!_isInitialized) return;
    
    await _notificationService.cancelBusinessUpgradeNotification(businessId);
  }

  /// Enable/disable offline income notifications
  Future<void> setOfflineIncomeNotificationsEnabled(bool enabled) async {
    if (!_isInitialized) return;
    await _notificationService.setOfflineIncomeNotificationsEnabled(enabled);
  }

  /// Enable/disable business upgrade notifications
  Future<void> setBusinessUpgradeNotificationsEnabled(bool enabled) async {
    if (!_isInitialized) return;
    await _notificationService.setBusinessUpgradeNotificationsEnabled(enabled);
  }

  /// Get current notification settings
  bool get offlineIncomeNotificationsEnabled => 
      _notificationService.offlineIncomeNotificationsEnabled;
  
  bool get businessUpgradeNotificationsEnabled => 
      _notificationService.businessUpgradeNotificationsEnabled;

  /// Get pending notifications count (for debugging)
  Future<int> getPendingNotificationsCount() async {
    if (!_isInitialized) return 0;
    return await _notificationService.getPendingNotificationsCount();
  }



  /// Dispose resources
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationService.dispose();
    debugPrint('🔔 AppLifecycleService disposed');
  }
} 
