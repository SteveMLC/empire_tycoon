import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/game_state.dart';

/// Service that handles local notifications for offline income and business upgrades
/// Implements granular user controls and notification grouping as per design requirements
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  late SharedPreferences _prefs;
  bool _isInitialized = false;
  bool _permissionRequested = false;

  // Notification IDs
  static const int _offlineIncomeNotificationId = 0;
  static const int _businessUpgradeNotificationIdBase = 1000;

  // Settings keys
  static const String _offlineIncomeEnabledKey = 'notifications_offline_income_enabled';
  static const String _businessUpgradesEnabledKey = 'notifications_business_upgrades_enabled';
  static const String _permissionRequestedKey = 'notifications_permission_requested';

  // Notification settings (default to ON as per requirements)
  bool _offlineIncomeNotificationsEnabled = true;
  bool _businessUpgradeNotificationsEnabled = true;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get offlineIncomeNotificationsEnabled => _offlineIncomeNotificationsEnabled;
  bool get businessUpgradeNotificationsEnabled => _businessUpgradeNotificationsEnabled;
  bool get permissionRequested => _permissionRequested;

  /// Initialize the notification service
  Future<bool> initialize() async {
    try {
      debugPrint('🔔 NotificationService: Starting initialization...');
      
      // Initialize timezone data
      tz_data.initializeTimeZones();
      debugPrint('🔔 Timezone data initialized');
      
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      _prefs = await SharedPreferences.getInstance();
      debugPrint('🔔 SharedPreferences loaded');
      
      // Load settings
      await _loadSettings();
      
      // Initialize platform-specific settings
      await _initializePlatformSettings();
      
      _isInitialized = true;
      debugPrint('✅ NotificationService: Initialized successfully with industry-standard approach');
      debugPrint('📊 Current settings: OfflineIncome=$_offlineIncomeNotificationsEnabled, BusinessUpgrade=$_businessUpgradeNotificationsEnabled');
      return true;
      
    } catch (e) {
      debugPrint('❌ NotificationService: Initialization failed: $e');
      return false;
    }
  }

  /// Initialize platform-specific notification settings
  Future<void> _initializePlatformSettings() async {
    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization  
    const DarwinInitializationSettings initializationSettingsiOS = DarwinInitializationSettings(
      requestAlertPermission: false, // We'll request permission manually
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    // Combined initialization settings
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsiOS,
    );

    // Initialize the plugin
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    debugPrint('🔔 Platform-specific notification settings initialized');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    debugPrint('🔔 Notification tapped: ${notificationResponse.id}');
    // The app will automatically come to foreground
    // Additional handling can be added here if needed
  }

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    _offlineIncomeNotificationsEnabled = _prefs.getBool(_offlineIncomeEnabledKey) ?? true;
    _businessUpgradeNotificationsEnabled = _prefs.getBool(_businessUpgradesEnabledKey) ?? true;
    _permissionRequested = _prefs.getBool(_permissionRequestedKey) ?? false;
    
    debugPrint('🔔 Loaded notification settings:');
    debugPrint('   - Offline Income: $_offlineIncomeNotificationsEnabled');
    debugPrint('   - Business Upgrades: $_businessUpgradeNotificationsEnabled');
    debugPrint('   - Permission Requested: $_permissionRequested');
  }

  /// Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    await _prefs.setBool(_offlineIncomeEnabledKey, _offlineIncomeNotificationsEnabled);
    await _prefs.setBool(_businessUpgradesEnabledKey, _businessUpgradeNotificationsEnabled);
    await _prefs.setBool(_permissionRequestedKey, _permissionRequested);
    debugPrint('💾 Notification settings saved');
  }

  /// Request notification permissions (call after user reaches milestone)
  Future<bool> requestPermissions() async {
    if (!_isInitialized) {
      debugPrint('❌ NotificationService not initialized');
      return false;
    }

    if (_permissionRequested) {
      debugPrint('ℹ️ Permission already requested, checking current status');
      return await _checkPermissionStatus();
    }

    try {
      debugPrint('🔔 Requesting notification permissions...');
      debugPrint('🔔 Platform: ${Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : 'Other'}');
      
      bool? granted;
      
      if (Platform.isAndroid) {
        debugPrint('🔔 Requesting Android notification permissions...');
        granted = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
        debugPrint('🔔 Android notification permission result: $granted');
        
        // INDUSTRY STANDARD: Only need POST_NOTIFICATIONS permission
        // Using inexact scheduling - no exact alarm permissions needed
        if (granted == true) {
          debugPrint('🔔 ✅ Perfect! Only standard notification permission needed');
          debugPrint('🔔 📱 Using approximate scheduling - industry standard for games');
          debugPrint('🔔 🔋 No battery-draining exact alarms required');
        }
      } else if (Platform.isIOS) {
        debugPrint('🔔 Requesting iOS notification permissions...');
        granted = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        debugPrint('🔔 iOS permission result: $granted');
      }

      _permissionRequested = true;
      await _saveSettings();

      debugPrint('🔔 Final permission request result: $granted');
      return granted ?? false;
      
    } catch (e) {
      debugPrint('❌ Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Check current permission status
  Future<bool> _checkPermissionStatus() async {
    try {
      if (Platform.isAndroid) {
        final permission = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.areNotificationsEnabled();
        return permission ?? false;
      } else if (Platform.isIOS) {
        // For iOS, we'll assume permission is granted if we reach this point
        // since we can't easily check the current status without additional permissions
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error checking permission status: $e');
      return false;
    }
  }

  /// Schedule offline income notification (4 hours) using industry-standard approach
  /// INDUSTRY STANDARD: Uses approximate scheduling - battery-friendly and no exact alarm permissions needed
  Future<void> scheduleOfflineIncomeNotification() async {
    if (!_isInitialized || !_offlineIncomeNotificationsEnabled) {
      debugPrint('🔔 Offline income notifications disabled or service not initialized');
      return;
    }

    try {
      // Cancel any existing offline income notification
      await cancelOfflineIncomeNotification();

      final scheduledDate = DateTime.now().add(const Duration(hours: 4)); // PRODUCTION: 4 hours for offline income
      
      // ENHANCED DIAGNOSTICS: Check current permission status before scheduling
      if (Platform.isAndroid) {
        final android = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final enabled = await android?.areNotificationsEnabled();
        debugPrint('🔔 Pre-schedule notification status check: ${enabled ?? false}');
        
        if (enabled != true) {
          debugPrint('⚠️ WARNING: Notifications not enabled - scheduling may fail');
          return; // Don't schedule if notifications aren't enabled
        }
      }
      
      // Android notification details
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'offline_income',
        'Offline Income Alerts',
        channelDescription: 'Notifications when your offline income capacity is full',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );

      // iOS notification details
      const DarwinNotificationDetails iosPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        threadIdentifier: 'offline-income',
      );

      // Combined notification details
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosPlatformChannelSpecifics,
      );

      // INDUSTRY STANDARD: Use standard scheduling without exact alarms
      // This is battery-friendly, user-friendly, and Google Play compliant
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        _offlineIncomeNotificationId,
        'Income Maxed Out!',
        'Your vaults are full! Tap to collect your offline earnings and keep your empire growing.',
        tz.TZDateTime.now(tz.local).add(const Duration(hours: 4)), // PRODUCTION: 4 hours for offline income
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, // NO EXACT ALARMS - Industry standard for games
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('🔔 ✅ PRODUCTION: Offline income notification scheduled (approximate timing) for: $scheduledDate');
      debugPrint('🔔 📱 BATTERY FRIENDLY: Using inexact scheduling - no special permissions needed!');
      debugPrint('🔔 🎯 USER FRIENDLY: Only requires standard notification permission');
      debugPrint('🔔 ⏰ PRODUCTION: ~4 hours ± system optimization');
      
    } catch (e) {
      debugPrint('❌ Error scheduling offline income notification: $e');
    }
  }

  /// Cancel offline income notification
  Future<void> cancelOfflineIncomeNotification() async {
    if (!_isInitialized) return;
    
    try {
      await _flutterLocalNotificationsPlugin.cancel(_offlineIncomeNotificationId);
      debugPrint('🔔 Cancelled offline income notification');
    } catch (e) {
      debugPrint('❌ Error cancelling offline income notification: $e');
    }
  }

  /// Schedule business upgrade completion notification using industry-standard approach
  /// INDUSTRY STANDARD: Uses approximate scheduling - battery-friendly and no exact alarm permissions needed
  Future<void> scheduleBusinessUpgradeNotification(
    String businessId,
    String businessName,
    Duration upgradeTime,
  ) async {
    if (!_isInitialized || !_businessUpgradeNotificationsEnabled) {
      debugPrint('🔔 Business upgrade notifications disabled or service not initialized');
      return;
    }

    // Only schedule for upgrades longer than 15 minutes (as requested)
    if (upgradeTime.inMinutes <= 15) {
      debugPrint('🔔 Upgrade duration too short (${upgradeTime.inMinutes} min), not scheduling notification');
      return;
    }

    try {
      final notificationId = _businessUpgradeNotificationIdBase + businessId.hashCode.abs() % 9000;
      final scheduledDate = DateTime.now().add(upgradeTime);
      
      // Check permission status
      if (Platform.isAndroid) {
        final android = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final enabled = await android?.areNotificationsEnabled();
        
        if (enabled != true) {
          debugPrint('⚠️ WARNING: Notifications not enabled - not scheduling business upgrade');
          return;
        }
      }
      
      // Android notification details with grouping
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'business_upgrades',
        'Business Upgrade Alerts',
        channelDescription: 'Notifications when business upgrades are complete',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        groupKey: 'com.empiretycoon.BUSINESS_UPGRADES',
        setAsGroupSummary: false,
      );

      // iOS notification details with thread identifier for grouping
      const DarwinNotificationDetails iosPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        threadIdentifier: 'business-upgrades',
      );

      // Combined notification details
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosPlatformChannelSpecifics,
      );

      // INDUSTRY STANDARD: Use standard scheduling without exact alarms
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Upgrade Complete!',
        'Your $businessName has been upgraded. Put it to work!',
        tz.TZDateTime.now(tz.local).add(upgradeTime),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, // NO EXACT ALARMS - Industry standard for games
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('🔔 ✅ INDUSTRY STANDARD: Business upgrade notification scheduled (approximate timing) for $businessName: $scheduledDate');
      debugPrint('🔔 📱 BATTERY FRIENDLY: Using inexact scheduling - no special permissions needed!');
      
      // Schedule or update group summary notification for Android
      if (Platform.isAndroid) {
        await _scheduleGroupSummaryNotification();
      }
      
    } catch (e) {
      debugPrint('❌ Error scheduling business upgrade notification: $e');
    }
  }

  /// Schedule group summary notification for Android
  Future<void> _scheduleGroupSummaryNotification() async {
    const int groupSummaryId = 999999;
    
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'business_upgrades',
        'Business Upgrade Alerts',
        channelDescription: 'Notifications when business upgrades are complete',
        importance: Importance.high,
        priority: Priority.high,
        groupKey: 'com.empiretycoon.BUSINESS_UPGRADES',
        setAsGroupSummary: true,
        groupAlertBehavior: GroupAlertBehavior.children,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      // Show summary notification immediately (it will only show when there are other notifications in the group)
      await _flutterLocalNotificationsPlugin.show(
        groupSummaryId,
        'Upgrades Finished!',
        'Multiple businesses have finished their upgrades. Come back to manage your empire!',
        platformChannelSpecifics,
      );
      
    } catch (e) {
      debugPrint('❌ Error scheduling group summary notification: $e');
    }
  }

  /// Cancel business upgrade notification
  Future<void> cancelBusinessUpgradeNotification(String businessId) async {
    if (!_isInitialized) return;
    
    try {
      final notificationId = _businessUpgradeNotificationIdBase + businessId.hashCode.abs() % 9000;
      await _flutterLocalNotificationsPlugin.cancel(notificationId);
      debugPrint('🔔 Cancelled business upgrade notification for: $businessId');
    } catch (e) {
      debugPrint('❌ Error cancelling business upgrade notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;
    
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('🔔 Cancelled all notifications');
    } catch (e) {
      debugPrint('❌ Error cancelling all notifications: $e');
    }
  }

  /// Enable/disable offline income notifications
  Future<void> setOfflineIncomeNotificationsEnabled(bool enabled) async {
    if (_offlineIncomeNotificationsEnabled == enabled) return;
    
    _offlineIncomeNotificationsEnabled = enabled;
    await _saveSettings();
    
    // Cancel existing notification if disabling
    if (!enabled) {
      await cancelOfflineIncomeNotification();
    }
    
    debugPrint('🔔 Offline income notifications ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Enable/disable business upgrade notifications
  Future<void> setBusinessUpgradeNotificationsEnabled(bool enabled) async {
    if (_businessUpgradeNotificationsEnabled == enabled) return;
    
    _businessUpgradeNotificationsEnabled = enabled;
    await _saveSettings();
    
    // Cancel existing business upgrade notifications if disabling
    if (!enabled) {
      // Cancel all business upgrade notifications (we can't easily track individual ones)
      final pendingNotifications = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      for (final notification in pendingNotifications) {
        if (notification.id >= _businessUpgradeNotificationIdBase && notification.id < _businessUpgradeNotificationIdBase + 10000) {
          await _flutterLocalNotificationsPlugin.cancel(notification.id);
        }
      }
    }
    
    debugPrint('🔔 Business upgrade notifications ${enabled ? 'enabled' : 'disabled'}');
  }



  /// Show in-game permission dialog before requesting system permission
  Future<bool> showPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enable Notifications'),
          content: const Text(
            'Enable notifications to get helpful alerts when your offline income is full or your business upgrades are complete! You can manage these settings anytime.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Enable'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// Get pending notifications count for debugging
  Future<int> getPendingNotificationsCount() async {
    if (!_isInitialized) return 0;
    
    try {
      final List<PendingNotificationRequest> pendingNotifications = 
          await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      
      debugPrint('🔔 Pending notifications: ${pendingNotifications.length}');
      
      // Debug: List all pending notifications
      for (final notification in pendingNotifications) {
        debugPrint('   - ID: ${notification.id}, Title: ${notification.title}');
      }
      
      return pendingNotifications.length;
    } catch (e) {
      debugPrint('❌ Error getting pending notifications: $e');
      return 0;
    }
  }



  /// Dispose resources
  void dispose() {
    debugPrint('🔔 NotificationService disposed');
  }
} 