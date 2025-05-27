import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/game_state.dart';
import 'screens/main_screen.dart';
import 'services/game_service.dart';
import 'services/income_service.dart';
import 'screens/platinum_vault_screen.dart';

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
    final bool isWeb = kIsWeb;
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => GameState()),
        Provider(create: (context) {
          final gameState = context.read<GameState>();
          final gameService = GameService(prefs, gameState);
          print('Created GameService with prefs: ${prefs.getKeys()}');
          return gameService;
        }),
        // Add IncomeService to the provider tree for consistent dependency injection
        ChangeNotifierProvider(create: (context) => IncomeService()),
      ],
      child: MaterialApp(
        title: 'Investment Account',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.grey[100],
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue[800],
            elevation: 0,
          ),
          fontFamily: isWeb ? null : 'Roboto',
          iconTheme: const IconThemeData(
            color: Colors.blue,
            size: 24.0,
          ),
          textTheme: isWeb 
            ? const TextTheme() 
            : const TextTheme(
                bodyLarge: TextStyle(fontFamily: 'Roboto'),
                bodyMedium: TextStyle(fontFamily: 'Roboto'),
                bodySmall: TextStyle(fontFamily: 'Roboto'),
              ),
        ),
        home: const GameInitializer(),
        routes: {
          '/platinumVault': (context) => const PlatinumVaultScreen(),
        },
      ),
    );
  }
}

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
    if (!_isInitialized) {
      _initializeGame();
    }
  }
  
  @override
  void dispose() {
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
    if (!_isInitialized) {
      if (_errorMessage != null) {
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
    
    return const MainScreen();
  }
}
