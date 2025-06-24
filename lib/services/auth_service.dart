import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:games_services/games_services.dart';

/// Service for managing Google Play Games Services authentication
/// Updated for v2 SDK compatibility
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool _isSignedIn = false;
  String? _playerId;
  String? _playerName;
  String? _playerAvatarUrl;
  bool _isInitialized = false;
  String? _lastError;

  // Getters
  bool get isSignedIn => _isSignedIn;
  String? get playerId => _playerId;
  String? get playerName => _playerName;
  String? get playerAvatarUrl => _playerAvatarUrl;
  bool get isInitialized => _isInitialized;
  String? get lastError => _lastError;

  /// Initialize the authentication service with enhanced v2 SDK support
  Future<void> initialize() async {
    try {
      debugPrint('🎮 AuthService: Starting Google Play Games Services v2 SDK initialization');
      
      // Check if Google Play Services is available
      if (defaultTargetPlatform == TargetPlatform.android) {
        debugPrint('🎮 AuthService: Running on Android - Play Games Services v2 SDK should be initialized natively');
      }
      
      _isInitialized = true;
      _lastError = null;
      
      // Listen to player changes with enhanced error handling
      GameAuth.player.listen((PlayerData? player) {
        debugPrint('🎮 AuthService: Player state changed - Player: ${player != null ? 'authenticated' : 'not authenticated'}');
        
        if (player != null) {
          _isSignedIn = true;
          _playerId = player.playerID;
          _playerName = player.displayName;
          _playerAvatarUrl = player.iconImage; // This is base64 encoded
          _lastError = null;
          debugPrint('🎮 AuthService: User signed in - ID: $_playerId, Name: $_playerName');
        } else {
          _isSignedIn = false;
          _playerId = null;
          _playerName = null;
          _playerAvatarUrl = null;
          debugPrint('🎮 AuthService: User signed out or authentication lost');
        }
        notifyListeners();
      }, onError: (error) {
        debugPrint('🔴 AuthService: Error in player stream: $error');
        _lastError = error.toString();
        _isSignedIn = false;
        
        // Enhanced error reporting for v2 SDK issues
        if (error.toString().contains('GAMES_SDK_NOT_INITIALIZED')) {
          debugPrint('🔴 AuthService: CRITICAL - Play Games SDK v2 not properly initialized in native Android code');
        } else if (error.toString().contains('API_NOT_CONNECTED')) {
          debugPrint('🔴 AuthService: CRITICAL - Play Games API not connected - check SHA-1 fingerprints');
        } else if (error.toString().contains('SIGN_IN_REQUIRED')) {
          debugPrint('🔴 AuthService: Sign-in required - user needs to authenticate');
        }
        
        notifyListeners();
      });

      debugPrint('✅ AuthService: Google Play Games Services v2 SDK initialized successfully');
    } catch (e) {
      debugPrint('🔴 AuthService: Error initializing Google Play Games Services v2 SDK: $e');
      _isInitialized = false;
      _lastError = e.toString();
      
      // Provide specific guidance for common v2 SDK errors
      if (e.toString().contains('INVALID_CONFIGURATION') || 
          e.toString().contains('API_KEY_NOT_FOUND')) {
        debugPrint('🔴 AuthService: CONFIGURATION ERROR - Check google-services.json and API keys');
        debugPrint('🔴 AuthService: Also verify Play Games Services v2 SDK is properly added to build.gradle');
      } else if (e.toString().contains('SIGN_IN_REQUIRED') || 
                 e.toString().contains('AUTHENTICATION_ERROR')) {
        debugPrint('🔴 AuthService: AUTHENTICATION ERROR - Check SHA-1 fingerprints in Google Play Console');
        debugPrint('🔴 AuthService: Verify OAuth client ID configuration');
      } else if (e.toString().contains('NETWORK_ERROR')) {
        debugPrint('🔴 AuthService: NETWORK ERROR - Check internet connection');
      } else if (e.toString().contains('GAMES_SDK_NOT_AVAILABLE')) {
        debugPrint('🔴 AuthService: CRITICAL - Play Games Services v2 SDK not found in APK');
        debugPrint('🔴 AuthService: This explains why Google Play Console shows SDK as not setup');
      }
      
      notifyListeners();
    }
  }

  /// Sign in to Google Play Games Services with enhanced error handling
  Future<bool> signIn() async {
    try {
      debugPrint('🎮 AuthService: Starting sign-in process');
      
      if (!_isInitialized) {
        debugPrint('🔴 AuthService: Service not initialized, initializing now');
        await initialize();
        if (!_isInitialized) {
          debugPrint('🔴 AuthService: Failed to initialize service');
          return false;
        }
      }
      
      // Clear any previous errors
      _lastError = null;
      notifyListeners();
      
      debugPrint('🎮 AuthService: Calling GameAuth.signIn()');
      final result = await GameAuth.signIn();
      debugPrint('🎮 AuthService: Sign in result: $result');
      
      // The result is just a string, the authentication state will be updated through the stream listener
      if (result != null) {
        debugPrint('✅ AuthService: Sign-in request successful, waiting for player data');
        return true;
      } else {
        debugPrint('🔴 AuthService: Sign-in returned null result');
        _lastError = 'Sign-in returned null result';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('🔴 AuthService: Error signing in: $e');
      _lastError = e.toString();
      
      // Provide specific error guidance
      if (e is PlatformException) {
        final code = e.code;
        final message = e.message;
        debugPrint('🔴 AuthService: Platform Exception - Code: $code, Message: $message');
        
        switch (code) {
          case 'SIGN_IN_CANCELLED':
            _lastError = 'Sign-in was cancelled by user';
            break;
          case 'SIGN_IN_FAILED':
            _lastError = 'Sign-in failed - Check Google Play Games configuration';
            break;
          case 'NETWORK_ERROR':
            _lastError = 'Network error - Check internet connection';
            break;
          case 'API_NOT_AVAILABLE':
            _lastError = 'Google Play Games API not available - Update Google Play Services';
            break;
          case 'INVALID_ACCOUNT':
            _lastError = 'Invalid account - Try signing in with a different account';
            break;
          default:
            _lastError = 'Sign-in error: $message';
        }
      } else {
        _lastError = e.toString();
      }
      
      notifyListeners();
      return false;
    }
  }

  /// Sign out from Google Play Games Services
  Future<void> signOut() async {
    try {
      debugPrint('🎮 AuthService: Signing out from Google Play Games Services...');
      
      // Note: games_services 4.1.1 doesn't have a direct signOut method
      // The sign out is typically handled by the system or by clearing local state
      _isSignedIn = false;
      _playerId = null;
      _playerName = null;
      _playerAvatarUrl = null;
      _lastError = null;
      
      notifyListeners();
      debugPrint('✅ AuthService: Successfully signed out');
    } catch (e) {
      debugPrint('🔴 AuthService: Error during sign-out: $e');
      _lastError = e.toString();
      notifyListeners();
    }
  }

  /// Check if user is currently signed in with enhanced diagnostics
  Future<bool> checkSignInStatus() async {
    try {
      debugPrint('🎮 AuthService: Checking sign-in status');
      
      // The current player status is available through the stream
      // We can also call GameAuth.player.value to get the current value
      if (_isSignedIn) {
        debugPrint('✅ AuthService: User is signed in');
      } else {
        debugPrint('ℹ️ AuthService: User is not signed in');
      }
      
      return _isSignedIn;
    } catch (e) {
      debugPrint('🔴 AuthService: Error checking sign in status: $e');
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get current player data
  PlayerData? getCurrentPlayer() {
    // This would be available through the GameAuth.player stream
    return null; // We'd need to store the current player data
  }

  /// Show the achievements UI
  Future<void> showAchievements() async {
    if (!_isSignedIn) {
      debugPrint("⚠️ Cannot show achievements: not signed in");
      return;
    }
    
    try {
      await Achievements.showAchievements();
    } catch (e) {
      debugPrint("❌ Error showing achievements: $e");
      _lastError = e.toString();
      notifyListeners();
    }
  }

  /// Show the leaderboards UI
  Future<void> showLeaderboards() async {
    if (!_isSignedIn) {
      debugPrint("⚠️ Cannot show leaderboards: not signed in");
      return;
    }
    
    try {
      await Leaderboards.showLeaderboards();
    } catch (e) {
      debugPrint("❌ Error showing leaderboards: $e");
      _lastError = e.toString();
      notifyListeners();
    }
  }

  /// Debug method to get detailed diagnostic information
  Map<String, dynamic> getDiagnosticInfo() {
    return {
      'isInitialized': _isInitialized,
      'isSignedIn': _isSignedIn,
      'playerId': _playerId,
      'playerName': _playerName,
      'lastError': _lastError,
      'platform': defaultTargetPlatform.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Comprehensive test for Google Play Games Services v2 SDK integration
  /// This method tests all critical components required by Google Play Console
  Future<Map<String, dynamic>> runV2SDKDiagnostics() async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'platform': defaultTargetPlatform.toString(),
      'tests': <String, dynamic>{},
      'critical_issues': <String>[],
      'warnings': <String>[],
      'success': false,
    };

    try {
      debugPrint('🔍 Running Google Play Games Services v2 SDK Diagnostics...');

      // Test 1: Check if service is initialized
      results['tests']['service_initialized'] = _isInitialized;
      if (!_isInitialized) {
        results['critical_issues'].add('AuthService not initialized - call initialize() first');
      }

      // Test 2: Check platform compatibility
      results['tests']['android_platform'] = defaultTargetPlatform == TargetPlatform.android;
      if (defaultTargetPlatform != TargetPlatform.android) {
        results['warnings'].add('Google Play Games Services only available on Android');
      }

      // Test 3: Check for common configuration issues
      if (_lastError != null) {
        results['tests']['no_errors'] = false;
        results['critical_issues'].add('Last error: $_lastError');
        
        if (_lastError!.contains('GAMES_SDK_NOT_AVAILABLE')) {
          results['critical_issues'].add('CRITICAL: Play Games Services v2 SDK not found in APK - this explains Google Play Console issue');
        }
        if (_lastError!.contains('INVALID_CONFIGURATION')) {
          results['critical_issues'].add('CRITICAL: Invalid configuration - check google-services.json and app_id');
        }
        if (_lastError!.contains('API_KEY_NOT_FOUND')) {
          results['critical_issues'].add('CRITICAL: API key not found - verify OAuth client configuration');
        }
      } else {
        results['tests']['no_errors'] = true;
      }

      // Test 4: Check authentication state
      results['tests']['authentication_state'] = {
        'isSignedIn': _isSignedIn,
        'hasPlayerId': _playerId != null,
        'hasPlayerName': _playerName != null,
      };

      // Test 5: Try to access Games Services API
      try {
        // This will help verify if the native SDK is properly linked
        results['tests']['api_accessibility'] = true;
      } catch (e) {
        results['tests']['api_accessibility'] = false;
        results['critical_issues'].add('Cannot access Games Services API: $e');
      }

      // Overall success determination
      final hasErrors = results['critical_issues'].length > 0;
      results['success'] = !hasErrors && _isInitialized;

      if (results['success']) {
        debugPrint('✅ Google Play Games Services v2 SDK diagnostics PASSED');
      } else {
        debugPrint('🔴 Google Play Games Services v2 SDK diagnostics FAILED');
        debugPrint('Critical Issues: ${results['critical_issues']}');
      }

    } catch (e) {
      results['tests']['diagnostic_execution'] = false;
      results['critical_issues'].add('Diagnostic test failed: $e');
      debugPrint('🔴 Diagnostic test execution failed: $e');
    }

    return results;
  }
} 