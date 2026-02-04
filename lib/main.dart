import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';

import 'models/game_state.dart';
import 'screens/main_screen.dart';
import 'services/game_service.dart';
import 'services/income_service.dart';
import 'services/auth_service.dart';
import 'services/admob_service.dart';
import 'screens/platinum_vault_screen.dart';
import 'widgets/empire_loading_screen.dart';
import 'utils/responsive_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with fallback for missing config
  try {
    // Try to initialize with default options first
    await Firebase.initializeApp();
  } catch (e) {
    if (kDebugMode) {
      print('Firebase initialization using default config: $e');
    }
  }

  // Initialize app settings
  final prefs = await SharedPreferences.getInstance();
  
  // Run the app
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatefulWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _markInitialized() {
    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => GameState()),
        Provider(create: (context) {
          final gameState = context.read<GameState>();
          final gameService = GameService(widget.prefs, gameState);
          print('Created GameService with prefs: ${widget.prefs.getKeys()}');
          return gameService;
        }),
        // Add IncomeService to the provider tree for consistent dependency injection
        ChangeNotifierProvider(create: (context) => IncomeService()),
        // Add AuthService for Google Play Games Services
        ChangeNotifierProvider(create: (context) => AuthService()),
        // Add AdMobService for ad integration (singleton)
        Provider<AdMobService>.value(value: AdMobService()),
      ],
      child: Builder(
        builder: (context) {
          // Get responsive utilities for theme adaptation
          final responsive = ResponsiveUtils.of(context);
          
          // Create adaptive theme based on device characteristics
          final baseTextTheme = kIsWeb 
            ? const TextTheme() 
            : const TextTheme(
                displayLarge: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                  color: Colors.black87,
                ),
                displayMedium: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                  color: Colors.black87,
                ),
                displaySmall: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                  fontSize: 20,
                  color: Colors.black87,
                ),
                headlineLarge: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: Colors.black87,
                ),
                headlineMedium: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                  color: Colors.black87,
                ),
                headlineSmall: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Colors.black87,
                ),
                titleLarge: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Colors.black87,
                ),
                titleMedium: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: Colors.black87,
                ),
                titleSmall: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Colors.black87,
                ),
                bodyLarge: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                  color: Colors.black87,
                ),
                bodyMedium: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                  color: Colors.black87,
                ),
                bodySmall: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.normal,
                  fontSize: 12,
                  color: Colors.black54,
                ),
                labelLarge: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Colors.black87,
                ),
                labelMedium: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: Colors.black87,
                ),
                labelSmall: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  color: Colors.black54,
                ),
              );
          
          // Get adaptive text theme based on device
          final adaptiveTextTheme = responsive.getAdaptiveTextTheme(baseTextTheme);
          
          return MaterialApp(
            title: 'Empire Tycoon',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              scaffoldBackgroundColor: Colors.grey[100],
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.grey[100],
                foregroundColor: Colors.black,
                elevation: 0,
              ),
              fontFamily: kIsWeb ? null : 'Roboto',
              iconTheme: IconThemeData(
                color: Colors.blue,
                size: responsive.iconSize(24.0),
              ),
              // RESPONSIVE TEXT THEME: Adapts to device size and density
              textTheme: adaptiveTextTheme,
              
              // RESPONSIVE BUTTON THEME: Ensure minimum tap targets
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(
                    responsive.layoutConstraints.minimumTapTarget * 2,
                    responsive.layoutConstraints.buttonHeight,
                  ),
                  padding: responsive.padding(horizontal: 16, vertical: 8),
                  textStyle: TextStyle(
                    fontSize: responsive.fontSize(14),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              // RESPONSIVE CARD THEME: Adaptive padding and margins
              cardTheme: CardThemeData(
                margin: responsive.margin(all: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(responsive.spacing(12)),
                ),
                elevation: 4,
              ),
              
              // RESPONSIVE LIST TILE THEME: Proper spacing and sizes
              listTileTheme: ListTileThemeData(
                contentPadding: responsive.padding(horizontal: 16, vertical: 8),
                minVerticalPadding: responsive.spacing(4),
                iconColor: Colors.blue,
                titleTextStyle: TextStyle(
                  fontSize: responsive.fontSize(16),
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                subtitleTextStyle: TextStyle(
                  fontSize: responsive.fontSize(14),
                  color: Colors.black54,
                ),
              ),
              
              // RESPONSIVE TAB BAR THEME: Proper sizing for different devices
              tabBarTheme: TabBarThemeData(
                labelStyle: TextStyle(
                  fontSize: responsive.fontSize(12),
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: responsive.fontSize(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
              ),
            ),
            home: AppInitializer(onInitialized: _markInitialized),
            routes: {
              '/platinum_vault': (context) => const PlatinumVaultScreen(),
            },
          );
        }
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  final VoidCallback onInitialized;

  const AppInitializer({super.key, required this.onInitialized});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _initialized = false;
  String _loadingText = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Allow providers to settle
      
      final gameState = Provider.of<GameState>(context, listen: false);
      final gameService = Provider.of<GameService>(context, listen: false);
      final incomeService = Provider.of<IncomeService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final adMobService = Provider.of<AdMobService>(context, listen: false);
      
      setState(() {
        _loadingText = 'Starting game service...';
      });
      print('Game initializer: Starting gameService.init()');
      await gameService.init();
      print('Game initializer: Finished gameService.init()');
      
      setState(() {
        _loadingText = 'Initializing authentication...';
      });
      print('Game initializer: Starting authService.initialize()');
      await authService.initialize();
      print('Game initializer: Finished authService.initialize()');

      // Throttled leaderboard submit: when net worth is updated (every 30 mins), submit if signed in
      gameState.onThrottledLeaderboardSubmit = (state) {
        if (authService.isSignedIn && authService.hasGamesPermission) {
          authService.submitHighestNetWorth(state.totalLifetimeNetWorth);
        }
      };

      setState(() {
        _loadingText = 'Setting up advertisements...';
      });
      print('Game initializer: Starting AdMob initialization');
      await adMobService.initialize();
      print('Game initializer: Finished AdMob initialization');
      
      setState(() {
        _loadingText = 'Finalizing setup...';
      });
      
      // Update AdMob service with initial game state for predictive loading
      int businessCount = gameState.businesses.where((b) => b.level > 0).length;
      int firstBusinessLevel = gameState.businesses.isNotEmpty ? gameState.businesses.first.level : 0;
      bool hasActiveEvents = gameState.activeEvents.isNotEmpty;
      
      adMobService.updateGameState(
        businessCount: businessCount,
        firstBusinessLevel: firstBusinessLevel,
        hasActiveEvents: hasActiveEvents,
        currentScreen: 'hustle', // Default starting screen
      );
      print('Game initializer: AdMob service updated with initial game state');
      
      // Check AdMob state and configuration
      print('Game initializer: AdMob final check - ads enabled: true');
      
      // REMOVED automatic premium check to prevent false activation
      print('Game initializer: Skipped automatic premium check to prevent false activation');
      
      await Future.delayed(const Duration(milliseconds: 500)); // Brief pause before showing main screen
      
      setState(() {
        _initialized = true;
      });
      
      widget.onInitialized();
      
    } catch (e) {
      print('Game initializer: Error during initialization: $e');
      setState(() {
        _loadingText = 'Initialization failed. Retrying...';
      });
      // Retry after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        _initializeApp();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return EmpireLoadingScreen(
        loadingText: 'EMPIRE TYCOON',
        subText: _loadingText,
      );
    }
    
    return const MainScreen();
  }
}
