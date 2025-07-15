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
      child: MaterialApp(
        title: 'Investment Account',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.grey[100],
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.grey[100],
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          fontFamily: kIsWeb ? null : 'Roboto',
          iconTheme: const IconThemeData(
            color: Colors.blue,
            size: 24.0,
          ),
          textTheme: kIsWeb 
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
              ),
        ),
        home: AppInitializer(onInitialized: _markInitialized),
        routes: {
          '/platinum_vault': (context) => const PlatinumVaultScreen(),
        },
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
      
      setState(() {
        _loadingText = 'Setting up advertisements...';
      });
      print('Game initializer: Starting AdMob initialization');
      await adMobService.initialize();
      print('Game initializer: Finished AdMob initialization');
      
      // ENHANCED: Set up AdMobService integration with GameState for predictive ad loading
      gameState.setAdMobService(adMobService);
      print('Game initializer: AdMobService integrated with GameState');
      
      // PREDICTIVE LOADING: Enable comprehensive revenue analytics and monitoring
      if (kDebugMode) {
        print('Game initializer: Enabling AdMob predictive loading analytics');
        // Set up periodic analytics reporting every 5 minutes in debug mode
        Timer.periodic(const Duration(minutes: 5), (_) {
          adMobService.printDebugStatus();
          print('💰 Quick Revenue Status: ${adMobService.getQuickRevenueDiagnostic()}');
        });
        
        // Set up immediate game state update to trigger predictive loading
        Future.delayed(const Duration(seconds: 2), () {
          // Get actual game state for more accurate predictions
          final businessCount = gameState.businesses.length;
          final firstBusinessLevel = gameState.businesses.isNotEmpty ? gameState.businesses.first.level : 1;
          final hasActiveEvents = gameState.activeEvents.isNotEmpty;
          
          adMobService.updateGameState(
            businessCount: businessCount,
            firstBusinessLevel: firstBusinessLevel,
            hasActiveEvents: hasActiveEvents,
            currentScreen: 'hustle',
            isReturningFromBackground: false,
            hasOfflineIncome: gameState.showOfflineIncomeNotification,
          );
          
          if (hasActiveEvents) {
            print('Game initializer: ✅ Found ${gameState.activeEvents.length} active events - EventClear ads will be preloaded');
          } else {
            print('Game initializer: ℹ️ No active events found - EventClear ads will not be preloaded');
          }
        });
      }
      
      setState(() {
        _loadingText = 'Finalizing setup...';
      });
      
      // DISABLED: Automatic premium check to prevent false activation
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
