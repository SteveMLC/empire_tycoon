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

  // Getters
  bool get isSignedIn => _isSignedIn;
  String? get playerId => _playerId;
  String? get playerName => _playerName;
  String? get playerAvatarUrl => _playerAvatarUrl;
  bool get isInitialized => _isInitialized;

  /// Initialize the authentication service
  Future<void> initialize() async {
    try {
      _isInitialized = true;
      
      // Listen to player changes
      GameAuth.player.listen((PlayerData? player) {
        if (player != null) {
          _isSignedIn = true;
          _playerId = player.playerID;
          _playerName = player.displayName;
          _playerAvatarUrl = player.iconImage; // This is base64 encoded
        } else {
          _isSignedIn = false;
          _playerId = null;
          _playerName = null;
          _playerAvatarUrl = null;
        }
        notifyListeners();
      });

      debugPrint('AuthService: Google Play Games Services initialized successfully');
    } catch (e) {
      debugPrint('AuthService: Error initializing Google Play Games Services: $e');
      _isInitialized = false;
    }
  }

  /// Sign in to Google Play Games Services
  Future<bool> signIn() async {
    try {
      final result = await GameAuth.signIn();
      debugPrint('AuthService: Sign in result: $result');
      // The result is just a string, the authentication state will be updated through the stream listener
      return result != null;
    } catch (e) {
      debugPrint('AuthService: Error signing in: $e');
      return false;
    }
  }

  /// Sign out from Google Play Games Services
  Future<void> signOut() async {
    try {
      debugPrint('AuthService: Signing out from Google Play Games Services...');
      
      // Note: games_services 4.1.1 doesn't have a direct signOut method
      // The sign out is typically handled by the system or by clearing local state
      _isSignedIn = false;
      _playerId = null;
      _playerName = null;
      _playerAvatarUrl = null;
      
      notifyListeners();
      debugPrint('AuthService: Successfully signed out');
    } catch (e) {
      debugPrint('AuthService: Error during sign-out: $e');
    }
  }

  /// Check if user is currently signed in
  Future<bool> checkSignInStatus() async {
    try {
      // The current player status is available through the stream
      // We can also call GameAuth.player.value to get the current value
      return _isSignedIn;
    } catch (e) {
      debugPrint('AuthService: Error checking sign in status: $e');
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
    }
  }
} 