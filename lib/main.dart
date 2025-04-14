import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/game_state.dart';
import 'screens/main_screen.dart';
import 'services/game_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  
  const MyApp({Key? key, required this.prefs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine if we're running on web platform to choose different font strategy
    final bool isWeb = kIsWeb;
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => GameState()),
        Provider(create: (context) {
          final gameState = context.read<GameState>();
          final gameService = GameService(prefs, gameState);
          // Add print statements to debug initialization and saving
          print('Created GameService with prefs: ${prefs.getKeys()}');
          return gameService;
        }),
      ],
      child: MaterialApp(
        title: 'Empire Tycoon',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.grey[100],
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue[800],
            elevation: 0,
          ),
          // For web, use system default fonts for faster loading
          // For Android/iOS, continue using Roboto
          fontFamily: isWeb ? null : 'Roboto',
          // Make sure Material Icons font is loaded properly
          iconTheme: const IconThemeData(
            color: Colors.blue,
            size: 24.0,
          ),
          // Conditionally set text theme based on platform
          textTheme: isWeb 
            ? const TextTheme() // Use system defaults on web
            : const TextTheme(
                bodyLarge: TextStyle(fontFamily: 'Roboto'),
                bodyMedium: TextStyle(fontFamily: 'Roboto'),
                bodySmall: TextStyle(fontFamily: 'Roboto'),
              ),
        ),
        home: const GameInitializer(),
      ),
    );
  }
}

// GameInitializer widget with improved initialization
class GameInitializer extends StatefulWidget {
  const GameInitializer({Key? key}) : super(key: key);

  @override
  State<GameInitializer> createState() => _GameInitializerState();
}

class _GameInitializerState extends State<GameInitializer> {
  bool _isInitialized = false;
  String? _errorMessage;
  GameService? _gameService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize when dependencies are ready
    if (!_isInitialized) {
      _initializeGame();
    }
  }
  
  @override
  void dispose() {
    // Make sure to dispose the GameService when this widget is disposed
    if (_gameService != null) {
      print('Game initializer: Disposing gameService');
      _gameService!.dispose();
    }
    super.dispose();
  }
  
  Future<void> _initializeGame() async {
    try {
      _gameService = Provider.of<GameService>(context, listen: false);
      print('Game initializer: Starting gameService.init()');
      await _gameService!.init();
      print('Game initializer: Finished gameService.init()');
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Game initializer: Error during initialization: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen until initialization is complete
    if (!_isInitialized) {
      if (_errorMessage != null) {
        // Error state
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 20),
                const Text(
                  'Error loading game',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                      _initializeGame();
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }
      
      // Loading state
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Loading game...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }
    
    // Once initialization is complete, show the main screen
    return const MainScreen();
  }
}
