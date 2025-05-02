import 'dart:async'; // Import dart:async for Timer
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../services/game_service.dart';
import 'business_screen.dart';
import 'investment_screen.dart';
import 'stats_screen.dart';
import 'hustle_screen.dart';
import 'real_estate_screen.dart';
import 'user_profile_screen.dart';
import '../widgets/main_screen/top_panel.dart';
import '../widgets/main_screen/main_tab_bar.dart';
import '../widgets/main_screen/notification_section.dart';
import '../widgets/main_screen/income_calculator.dart';

/// Main screen of the app, refactored to use smaller, more maintainable component files.
/// Components extracted include:
/// - AnimatedPPIcon
/// - TopPanel
/// - MainTabBar
/// - NotificationSection
/// - IncomeCalculator
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _boostTimer; // Timer for boost UI updates
  Duration _boostTimeRemaining = Duration.zero; // State variable for remaining time
  late GameState _gameState;
  late GameService _gameService;
  late IncomeCalculator _incomeCalculator;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    
    // Initialize utility classes
    _incomeCalculator = IncomeCalculator();
    
    // Load dependencies
    _gameState = Provider.of<GameState>(context, listen: false);
    _gameService = Provider.of<GameService>(context, listen: false);
    
    // Initialize boost timer
    _initializeBoostTimer();
    
    // Use WidgetsBinding to ensure the first frame is built before potentially showing a notification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { // Check if the widget is still in the tree
        _gameState.tryShowingNextAchievement();
        print("🔔 Initial achievement check triggered.");
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _boostTimer?.cancel(); // Cancel timer on dispose
    // Remove listener to avoid memory leaks
    Provider.of<GameState>(context, listen: false).removeListener(_handleGameStateChange);
    super.dispose();
  }

  void _initializeBoostTimer() {
    // Initial check
    _updateBoostTimer(_gameState);
    // Add listener for future changes
    _gameState.addListener(_handleGameStateChange);
  }

  // Listen to GameState changes to start/stop the timer
  void _handleGameStateChange() {
    if (!mounted) return; // Avoid calling if widget is disposed
    final gameState = Provider.of<GameState>(context, listen: false);
    _updateBoostTimer(gameState);
  }

  // Start or stop the timer based on GameState
  void _updateBoostTimer(GameState gameState) {
    final bool isBoostActive = gameState.clickMultiplier > 1.0 && 
                               gameState.clickBoostEndTime != null && 
                               gameState.clickBoostEndTime!.isAfter(DateTime.now());

    if (isBoostActive && (_boostTimer == null || !_boostTimer!.isActive)) {
      // Start the timer if boost is active and timer isn't running
      _boostTimer?.cancel(); // Cancel any existing timer just in case
      _boostTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        final now = DateTime.now();
        final endTime = Provider.of<GameState>(context, listen: false).clickBoostEndTime;
        if (endTime == null || now.isAfter(endTime)) {
          timer.cancel();
          setState(() {
            _boostTimeRemaining = Duration.zero; // Reset remaining time
          });
          // Optionally trigger a final GameState check/update here if needed
        } else {
          setState(() {
            _boostTimeRemaining = endTime.difference(now);
          });
        }
      });
      // Initial update
       if (gameState.clickBoostEndTime != null) {
         setState(() {
           _boostTimeRemaining = gameState.clickBoostEndTime!.difference(DateTime.now());
           if (_boostTimeRemaining.isNegative) _boostTimeRemaining = Duration.zero;
         });
       }
    } else if (!isBoostActive && (_boostTimer != null && _boostTimer!.isActive)) {
      // Stop the timer if boost is not active and timer is running
      _boostTimer?.cancel();
      setState(() {
         _boostTimeRemaining = Duration.zero; // Ensure UI updates if boost ends early
      });
    } else if (isBoostActive) {
       // Ensure remaining time is updated if the boost end time changes while active
       final endTime = gameState.clickBoostEndTime!;
       final remaining = endTime.difference(DateTime.now());
       if (_boostTimeRemaining.inSeconds != remaining.inSeconds && mounted) {
         setState(() {
           _boostTimeRemaining = remaining.isNegative ? Duration.zero : remaining;
         });
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        // ADDED: Logging inside Consumer builder
        print("🔄 MainScreen Consumer rebuilding...");
        print("  -> gameState hashCode: ${gameState.hashCode}"); // Log hashCode
        print("  -> PP: ${gameState.platinumPoints}");
        print("  -> showPPAnimation: ${gameState.showPPAnimation}");
        print("  -> showPremiumNotification: ${gameState.showPremiumPurchaseNotification}");

        if (!gameState.isInitialized) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
        
        return Scaffold(
          body: Column(
            children: [
              // Top Panel always at the top
              TopPanel(
                formatBoostTimeRemaining: _incomeCalculator.formatBoostTimeRemaining,
                calculateIncomePerSecond: _incomeCalculator.calculateIncomePerSecond,
              ),

              // Notification section - pushes down the menu
              const NotificationSection(),

              // TabBar below notifications
              MainTabBar(tabController: _tabController),

              // TabView for main content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    HustleScreen(),
                    BusinessScreen(),
                    InvestmentScreen(),
                    RealEstateScreen(),
                    StatsScreen(),
                    UserProfileScreen(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}