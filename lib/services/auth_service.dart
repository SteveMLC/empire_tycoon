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


}