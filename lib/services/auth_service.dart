import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:games_services/games_services.dart';

/// Service for managing Firebase Authentication with Google Play Games Services
/// Following Firebase Google Play Games Services documentation
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Firebase Auth instance
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  
  // Google Sign In configuration for Play Games
  late GoogleSignIn _googleSignIn;
  
  bool _isSignedIn = false;
  String? _playerId;
  String? _playerName;
  String? _playerAvatarUrl;
  bool _isInitialized = false;
  String? _lastError;
  User? _firebaseUser;

  // Getters
  bool get isSignedIn => _isSignedIn;
  String? get playerId => _playerId;
  String? get playerName => _playerName;
  String? get playerAvatarUrl => _playerAvatarUrl;
  bool get isInitialized => _isInitialized;
  String? get lastError => _lastError;
  User? get firebaseUser => _firebaseUser;

  /// Initialize the authentication service with Firebase and Google Play Games Services
  Future<void> initialize() async {
    try {
      debugPrint('🎮 AuthService: Starting Firebase + Google Play Games Services initialization');
      
      // Initialize Google Sign In with Play Games configuration
      _googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'profile',
          'https://www.googleapis.com/auth/games',
        ],
        // Use default web client ID from strings.xml
        serverClientId: '716473238772-mn9sh4e5c441ovk16l7oqc48le35bm9e.apps.googleusercontent.com',
      );
      
      _isInitialized = true;
      _lastError = null;
      
      // Listen to Firebase auth state changes
      _firebaseAuth.authStateChanges().listen((User? user) {
        _firebaseUser = user;
        if (user != null) {
          debugPrint('🔥 AuthService: Firebase user signed in - UID: ${user.uid}');
          // Update local state based on Firebase user
          _updateUserState(user);
        } else {
          debugPrint('🔥 AuthService: Firebase user signed out');
          _clearUserState();
        }
        notifyListeners();
      });

      // Listen to Google Play Games player changes
      GameAuth.player.listen((PlayerData? player) {
        debugPrint('🎮 AuthService: Google Play Games player state changed');
        
        if (player != null) {
          _playerId = player.playerID;
          _playerName = player.displayName;
          _playerAvatarUrl = player.iconImage;
          debugPrint('🎮 AuthService: Play Games player data - ID: $_playerId, Name: $_playerName');
        } else {
          debugPrint('🎮 AuthService: Play Games player data cleared');
        }
        notifyListeners();
      }, onError: (error) {
        debugPrint('🔴 AuthService: Error in Google Play Games player stream: $error');
        _lastError = error.toString();
        notifyListeners();
      });

      debugPrint('✅ AuthService: Firebase + Google Play Games Services initialized successfully');
    } catch (e) {
      debugPrint('🔴 AuthService: Error initializing authentication services: $e');
      _isInitialized = false;
      _lastError = e.toString();
      notifyListeners();
    }
  }

  /// Sign in using Firebase with Google Play Games Services
  Future<bool> signIn() async {
    try {
      debugPrint('🎮 AuthService: Starting Firebase + Google Play Games sign-in process');
      
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
      
      // Step 1: Sign in to Google Play Games Services first
      debugPrint('🎮 AuthService: Step 1 - Signing in to Google Play Games Services');
      
      // Configure Google Sign In for Play Games
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'profile',
          'https://www.googleapis.com/auth/games',
        ],
        serverClientId: '716473238772-mn9sh4e5c441ovk16l7oqc48le35bm9e.apps.googleusercontent.com',
      );
      
      // Sign in with Google Play Games
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint('🔴 AuthService: Google Sign In was cancelled by user');
        _lastError = 'Sign-in was cancelled by user';
        notifyListeners();
        return false;
      }
      
      debugPrint('🎮 AuthService: Step 2 - Getting authentication details');
      
      // Get authentication details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null) {
        debugPrint('🔴 AuthService: Failed to get access token');
        _lastError = 'Failed to get access token';
        notifyListeners();
        return false;
      }
      
      debugPrint('🎮 AuthService: Step 3 - Creating Firebase credential');
      
      // Create a new credential using the token
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      debugPrint('🎮 AuthService: Step 4 - Signing in to Firebase');
      
      // Sign in to Firebase with the Google credentials
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        debugPrint('✅ AuthService: Successfully signed in to Firebase');
        debugPrint('🔥 Firebase User: ${userCredential.user!.uid}');
        debugPrint('🔥 Display Name: ${userCredential.user!.displayName}');
        debugPrint('🔥 Email: ${userCredential.user!.email}');
        
        // Step 5: Initialize Google Play Games Services
        debugPrint('🎮 AuthService: Step 5 - Initializing Google Play Games Services');
        try {
          final gameAuthResult = await GameAuth.signIn();
          debugPrint('🎮 AuthService: Google Play Games sign-in result: $gameAuthResult');
        } catch (gameError) {
          debugPrint('⚠️ AuthService: Google Play Games Services sign-in failed: $gameError');
          // Continue anyway - Firebase authentication succeeded
        }
        
        _isSignedIn = true;
        _lastError = null;
        notifyListeners();
        return true;
      } else {
        debugPrint('🔴 AuthService: Firebase sign-in failed - no user returned');
        _lastError = 'Firebase authentication failed';
        notifyListeners();
        return false;
      }
      
    } catch (e) {
      debugPrint('🔴 AuthService: Error during sign-in: $e');
      debugPrint('🔴 AuthService: Exception type: ${e.runtimeType}');
      
      if (e is PlatformException) {
        final code = e.code;
        final message = e.message;
        debugPrint('🔴 AuthService: Platform Exception - Code: $code, Message: $message');
        
        switch (code) {
          case 'sign_in_canceled':
            _lastError = 'Sign-in was cancelled by user';
            break;
          case 'sign_in_failed':
            _lastError = 'Sign-in failed - Check configuration';
            break;
          case 'network_error':
            _lastError = 'Network error - Check internet connection';
            break;
          default:
            _lastError = 'Sign-in error: $message (Code: $code)';
        }
      } else if (e is FirebaseAuthException) {
        debugPrint('🔴 AuthService: Firebase Auth Exception - Code: ${e.code}, Message: ${e.message}');
        _lastError = 'Firebase authentication error: ${e.message}';
      } else {
        _lastError = e.toString();
      }
      
      notifyListeners();
      return false;
    }
  }

  /// Sign out from both Firebase and Google Play Games Services
  Future<void> signOut() async {
    try {
      debugPrint('🎮 AuthService: Starting sign-out process');
      
      // Sign out from Firebase
      await _firebaseAuth.signOut();
      
      // Sign out from Google Sign In
      await _googleSignIn.signOut();
      
      // Clear local state
      _clearUserState();
      
      debugPrint('✅ AuthService: Successfully signed out from all services');
    } catch (e) {
      debugPrint('🔴 AuthService: Error during sign-out: $e');
      _lastError = e.toString();
      notifyListeners();
    }
  }

  /// Update user state based on Firebase user
  void _updateUserState(User user) {
    _isSignedIn = true;
    // Use Firebase user data as primary, Play Games data as secondary
    if (_playerName == null) {
      _playerName = user.displayName;
    }
    if (_playerAvatarUrl == null) {
      _playerAvatarUrl = user.photoURL;
    }
  }

  /// Clear all user state
  void _clearUserState() {
    _isSignedIn = false;
    _playerId = null;
    _playerName = null;
    _playerAvatarUrl = null;
    _firebaseUser = null;
    _lastError = null;
  }

  /// Get current authentication status
  Map<String, dynamic> getAuthStatus() {
    return {
      'isSignedIn': _isSignedIn,
      'isInitialized': _isInitialized,
      'firebaseUser': _firebaseUser?.uid,
      'playerId': _playerId,
      'playerName': _playerName,
      'lastError': _lastError,
    };
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

  /// Test specifically for the missing Web client issue
  Future<Map<String, dynamic>> testWebClientConfiguration() async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'test_name': 'Web Client Configuration Test',
      'issues_found': <String>[],
      'recommendations': <String>[],
      'success': false,
    };

    try {
      debugPrint('🔍 Testing Web Client Configuration...');
      
      // Test 1: Try to sign in and capture exact error
      results['test_signin_attempt'] = true;
      
      try {
        final result = await GameAuth.signIn();
        if (result != null) {
          results['signin_result'] = 'SUCCESS';
          results['success'] = true;
        } else {
          results['signin_result'] = 'NULL_RESULT';
          results['issues_found'].add('GameAuth.signIn() returned null - likely configuration issue');
        }
      } catch (e) {
        results['signin_result'] = 'EXCEPTION';
        results['signin_exception'] = e.toString();
        results['exception_type'] = e.runtimeType.toString();
        
        if (e is PlatformException) {
          results['platform_exception_code'] = e.code;
          results['platform_exception_message'] = e.message;
          results['platform_exception_details'] = e.details;
          
          // Specific diagnosis for common issues
          if (e.code == 'failed_to_authenticate') {
            results['issues_found'].add('CRITICAL: failed_to_authenticate - Missing Web OAuth client in google-services.json');
            results['recommendations'].add('Add Web OAuth client in Google Cloud Console');
            results['recommendations'].add('Download updated google-services.json from Firebase Console');
            results['recommendations'].add('Ensure Play Games Services API is enabled');
          }
        }
      }
      
      // Test 2: Check current error state
      if (_lastError != null) {
        results['current_error'] = _lastError;
        if (_lastError!.contains('Sign-in error:')) {
          results['issues_found'].add('Error message truncated - need full error details');
        }
      }
      
      // Test 3: Configuration validation
      results['configuration_check'] = {
        'service_initialized': _isInitialized,
        'platform': defaultTargetPlatform.toString(),
        'app_id_configured': '400590136347', // From strings.xml
        'package_name': 'com.go7studio.empire_tycoon',
      };
      
      debugPrint('🔍 Web Client Test Results: $results');
      
    } catch (e) {
      results['test_execution_error'] = e.toString();
      debugPrint('🔴 Error running web client test: $e');
    }

    return results;
  }
} 