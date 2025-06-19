import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:games_services/games_services.dart';

/// Service for managing Google Play Games Services authentication
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

  /// Initialize the authentication service
  Future<void> initialize() async {
    try {
      debugPrint('🎮 AuthService: Starting Google Play Games Services initialization');
      
      // Check if Google Play Services is available
      if (defaultTargetPlatform == TargetPlatform.android) {
        debugPrint('🎮 AuthService: Running on Android - checking Play Services availability');
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
        notifyListeners();
      });

      debugPrint('✅ AuthService: Google Play Games Services initialized successfully');
    } catch (e) {
      debugPrint('🔴 AuthService: Error initializing Google Play Games Services: $e');
      _isInitialized = false;
      _lastError = e.toString();
      
      // Provide specific guidance for common errors
      if (e.toString().contains('INVALID_CONFIGURATION') || 
          e.toString().contains('API_KEY_NOT_FOUND')) {
        debugPrint('🔴 AuthService: CONFIGURATION ERROR - Check google-services.json and API keys');
      } else if (e.toString().contains('SIGN_IN_REQUIRED') || 
                 e.toString().contains('AUTHENTICATION_ERROR')) {
        debugPrint('🔴 AuthService: AUTHENTICATION ERROR - Check SHA-1 fingerprints in Google Play Console');
      } else if (e.toString().contains('NETWORK_ERROR')) {
        debugPrint('🔴 AuthService: NETWORK ERROR - Check internet connection');
      }
      
      notifyListeners();
    }
  }

  /// Sign in to Google Play Games Services with enhanced error handling
  Future<bool> signIn() async {
    try {
      debugPrint('🎮 AuthService: Starting sign-in process');
      debugPrint('🎮 AuthService: Running diagnostic checks...');
      await runDiagnostics();
      
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
          case 'failed_to_authenticate':
            _lastError = 'Authentication failed - Check SHA-1 fingerprints and test account';
            debugPrint('🔴 CRITICAL: failed_to_authenticate error suggests:');
            debugPrint('  1. SHA-1 fingerprint mismatch between keystore and Google Cloud Console');
            debugPrint('  2. Test account not added to Google Play Console testers');
            debugPrint('  3. Google Play Games Services not properly configured');
            debugPrint('  4. App not published to internal testing track');
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
  PlayerData? get currentPlayer {
    // Note: In games_services 4.1.1, we access current player through the stream
    return null; // This would be updated through the stream listener
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

  /// Diagnostic method to check Google Play Games Services configuration
  Future<void> runDiagnostics() async {
    debugPrint('🔍 Running Google Play Games Services Diagnostics...');
    debugPrint('🔍 Package: com.go7studio.empire_tycoon');
    debugPrint('🔍 App ID: 400590136347');
    debugPrint('🔍 Expected SHA-1: C0:E6:EB:20:DC:8F:D3:DF:E1:F0:EB:DA:9F:02:5E:76:72:45:85:BF');
    debugPrint('🔍 Is Initialized: $_isInitialized');
    debugPrint('🔍 Is Signed In: $_isSignedIn');
    debugPrint('🔍 Last Error: $_lastError');
    debugPrint('🔍 Platform: ${defaultTargetPlatform.toString()}');
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      debugPrint('🔍 Android-specific checks:');
      debugPrint('  - Ensure Google Play Services is updated');
      debugPrint('  - Ensure test account is added to Google Play Console');
      debugPrint('  - Ensure SHA-1 fingerprint matches in Google Cloud Console');
      debugPrint('  - Ensure Play Games Services setup is complete (5 of 5 steps)');
    }
  }
} 