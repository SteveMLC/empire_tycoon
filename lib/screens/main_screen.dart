import 'dart:async'; // Import dart:async for Timer
import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../services/game_service.dart';
import '../services/income_service.dart';
import 'business_screen.dart';
import 'investment_screen.dart';
import 'stats_screen.dart';
import 'hustle_screen.dart';
import 'real_estate_screen.dart';
import 'user_profile_screen.dart';
import '../widgets/main_screen/top_panel.dart';
import '../widgets/main_screen/main_tab_bar.dart';
import '../widgets/main_screen/notification_section.dart';

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
  
  // We'll access these services through Provider instead of storing local references
  // This helps avoid memory leaks and ensures consistent access patterns
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    
    // Initialize boost timer after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Initialize boost timer
        _initializeBoostTimer();
        
        // Trigger initial achievement check
        final gameState = Provider.of<GameState>(context, listen: false);
        gameState.tryShowingNextAchievement();
        // Only log in debug mode to reduce production spam
        if (kDebugMode) {
          print("🔔 Initial achievement check triggered.");
        }
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _boostTimer?.cancel(); // Cancel timer on dispose
    
    // Remove listener to avoid memory leaks - safely check if context is still valid
    if (mounted) {
      Provider.of<GameState>(context, listen: false).removeListener(_handleGameStateChange);
    }
    super.dispose();
  }

  void _initializeBoostTimer() {
    // Get GameState through Provider to ensure consistent access pattern
    final gameState = Provider.of<GameState>(context, listen: false);
    
    // Initial check
    _updateBoostTimer(gameState);
    
    // Add listener for future changes - safely add only if mounted
    if (mounted) {
      gameState.addListener(_handleGameStateChange);
    }
  }

  // Listen to GameState changes to start/stop the timer
  void _handleGameStateChange() {
    // Early return if widget is no longer mounted to prevent memory leaks
    if (!mounted) {
      // If not mounted, we should also remove the listener to prevent memory leaks
      try {
        Provider.of<GameState>(context, listen: false).removeListener(_handleGameStateChange);
      } catch (e) {
        // Ignore errors if context is no longer valid
      }
      return;
    }
    
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
          if (mounted) {
            setState(() {
              _boostTimeRemaining = Duration.zero; // Reset remaining time
            });
          }
          // Optionally trigger a final GameState check/update here if needed
        } else {
          final newRemaining = endTime.difference(now);
          // OPTIMIZED: Only call setState if the seconds value actually changed
          if (mounted && _boostTimeRemaining.inSeconds != newRemaining.inSeconds) {
            setState(() {
              _boostTimeRemaining = newRemaining;
            });
          }
        }
      });
      // Initial update
       if (gameState.clickBoostEndTime != null) {
         final newRemaining = gameState.clickBoostEndTime!.difference(DateTime.now());
         if (mounted && _boostTimeRemaining.inSeconds != newRemaining.inSeconds) {
           setState(() {
             _boostTimeRemaining = newRemaining.isNegative ? Duration.zero : newRemaining;
           });
         }
       }
    } else if (!isBoostActive && (_boostTimer != null && _boostTimer!.isActive)) {
      // Stop the timer if boost is not active and timer is running
      _boostTimer?.cancel();
      if (mounted) {
        setState(() {
           _boostTimeRemaining = Duration.zero; // Ensure UI updates if boost ends early
        });
      }
    } else if (isBoostActive) {
       // Ensure remaining time is updated if the boost end time changes while active
       final endTime = gameState.clickBoostEndTime!;
       final remaining = endTime.difference(DateTime.now());
       // OPTIMIZED: Only call setState if the seconds value actually changed
       if (mounted && _boostTimeRemaining.inSeconds != remaining.inSeconds) {
         setState(() {
           _boostTimeRemaining = remaining.isNegative ? Duration.zero : remaining;
         });
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use a more selective approach to rebuilds by using a Selector instead of Consumer
    // This will only rebuild when specific properties change, not on every GameState change
    return Selector<GameState, List<dynamic>>(
      // Only select the properties we actually need for this screen
      selector: (_, gameState) => [
        gameState.isInitialized,
        gameState.showPPAnimation,
        gameState.showPremiumPurchaseNotification,
        // Add any other properties that should trigger a rebuild
      ],
      builder: (context, data, child) {
        // Get the current gameState without listening to all changes
        final gameState = Provider.of<GameState>(context, listen: false);
        
        // REMOVED: Excessive debug logging that was causing log spam
        // Only log rebuilds in debug mode and less frequently
        if (kDebugMode && DateTime.now().second % 30 == 0) {
          print("🔄 MainScreen Selector rebuilding (periodic check)");
        }

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
              // Top Panel always at the top - no longer passing functions
              // The TopPanel will access IncomeService directly through Provider
              const TopPanel(),

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