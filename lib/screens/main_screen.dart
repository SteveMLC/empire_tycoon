import 'dart:async'; // Import dart:async for Timer
import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:in_app_review/in_app_review.dart';
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
import '../widgets/main_screen/event_corner_badge.dart';
import '../widgets/empire_loading_screen.dart';
import '../widgets/net_worth_ticker.dart';
import '../services/daily_rewards_manager.dart';
import '../widgets/daily_reward_popup.dart';

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
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _deepLinkSubscription;
  final Set<String> _processedDeepLinks = <String>{};
  bool _isRateUsRequestInProgress = false;
  bool _dailyRewardCheckInProgress = false;
  bool _dailyRewardChecked = false;
  
  // We'll access these services through Provider instead of storing local references
  // This helps avoid memory leaks and ensures consistent access patterns
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _appLinks = AppLinks();
    
    // Initialize boost timer after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Initialize boost timer
        _initializeBoostTimer();
        _initializeDeepLinks();
        
        // Trigger initial achievement check
        final gameState = Provider.of<GameState>(context, listen: false);
        gameState.tryShowingNextAchievement();
        _checkAndShowRateUsDialog(gameState);
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
    _deepLinkSubscription?.cancel();
    
    // Remove listener to avoid memory leaks - safely check if context is still valid
    if (mounted) {
      Provider.of<GameState>(context, listen: false).removeListener(_handleGameStateChange);
    }
    super.dispose();
  }

  Future<void> _initializeDeepLinks() async {
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _handlePromoDeepLink(initialUri);
      }

      _deepLinkSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
        _handlePromoDeepLink(uri);
      });
    } catch (e) {
      if (kDebugMode) {
        print("⚠️ Deep link initialization failed: $e");
      }
    }
  }

  Future<void> _handlePromoDeepLink(Uri uri) async {
    if (!mounted) {
      return;
    }

    final String scheme = uri.scheme.toLowerCase();
    final String host = uri.host.toLowerCase();
    final String path = uri.path.toLowerCase();
    final bool isBonusLink = host == 'bonus' || path == '/bonus';
    if (scheme != 'empiretycoon' || !isBonusLink) {
      return;
    }

    final String linkKey = uri.toString();
    if (_processedDeepLinks.contains(linkKey)) {
      return;
    }
    _processedDeepLinks.add(linkKey);

    final String? promoCode = uri.queryParameters['code']?.trim();
    if (promoCode == null || promoCode.isEmpty) {
      _showPromoMessage('Bonus link missing promo code.', success: false);
      return;
    }

    final gameState = Provider.of<GameState>(context, listen: false);
    final gameService = Provider.of<GameService>(context, listen: false);
    final PromoRedemptionResult result = gameState.redeemPromoCode(promoCode);

    if (result.success) {
      try {
        await gameService.saveGame();
      } catch (e) {
        if (kDebugMode) {
          print("⚠️ Failed to save promo redemption: $e");
        }
      }
    }
    _showPromoMessage(result.message, success: result.success);
  }

  void _showPromoMessage(String message, {required bool success}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? Colors.green[700] : Colors.red[700],
        ),
      );
    });
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
    
    // ADDED: Check if notification permissions should be requested
    _checkNotificationPermissionRequest(gameState);
    _checkAndShowRateUsDialog(gameState);
  }

  Future<void> _checkAndShowDailyReward(GameState gameState) async {
    if (_dailyRewardCheckInProgress || _dailyRewardChecked) return;

    _dailyRewardCheckInProgress = true;
    final DailyRewardsManager manager = DailyRewardsManager();

    await manager.hydrateFromGameState(gameState);
    final reward = await manager.checkDailyReward();
    if (!mounted) return;

    if (reward != null) {
      await DailyRewardPopup.show(
        context,
        reward: reward,
        allRewards: manager.rewards,
        streakBroken: manager.lastCheckResult?.streakBroken ?? false,
        currentDay: reward.day,
        onClaim: () => manager.claimReward(reward, gameState),
      );
    }

    _dailyRewardChecked = true;
    _dailyRewardCheckInProgress = false;
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

  // ADDED: Check if notification permissions should be requested
  void _checkNotificationPermissionRequest(GameState gameState) {
    if (gameState.shouldRequestNotificationPermissions) {
      // Reset the flag immediately to prevent multiple requests
      gameState.resetNotificationPermissionRequest();
      
      // Request permission through GameService after a brief delay for UI stability
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (mounted) {
          try {
            final gameService = Provider.of<GameService>(context, listen: false);
            await gameService.requestNotificationPermissions(context);
          } catch (e) {
            print("⚠️ Error requesting notification permissions: $e");
          }
        }
      });
    }
  }

  Future<void> _checkAndShowRateUsDialog(GameState gameState) async {
    if (!mounted || _isRateUsRequestInProgress) {
      return;
    }
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    if (!gameState.shouldShowRateUsDialog()) {
      return;
    }

    _isRateUsRequestInProgress = true;
    final InAppReview inAppReview = InAppReview.instance;
    try {
      final bool isAvailable = await inAppReview.isAvailable();
      if (!isAvailable) {
        return;
      }

      await inAppReview.requestReview();
      gameState.markRateUsDialogShown();
      final gameService = Provider.of<GameService>(context, listen: false);
      await gameService.saveGame();
    } catch (e) {
      if (kDebugMode) {
        print("⚠️ Failed to request in-app review: $e");
      }
    } finally {
      _isRateUsRequestInProgress = false;
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
        // Listen to GameState so UI reacts to settings like showNetWorthTicker
        final gameState = Provider.of<GameState>(context);
        
        // REMOVED: Excessive debug logging that was causing log spam
        // Only log rebuilds in debug mode and less frequently
        if (kDebugMode && DateTime.now().second % 30 == 0) {
          print("🔄 MainScreen Selector rebuilding (periodic check)");
        }

        if (!gameState.isInitialized) {
          return const EmpireLoadingScreen(
            loadingText: 'EMPIRE TYCOON',
            subText: 'Finalizing your business empire...',
          );
        }
        if (!_dailyRewardChecked && !_dailyRewardCheckInProgress) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkAndShowDailyReward(gameState);
          });
        }
        
        return Scaffold(
          body: Stack(
            children: [
              // Main content
              Column(
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
              
              // Ultra-minimal corner badge for events
              const EventCornerBadge(),
              
              // Net Worth Ticker - draggable crown/earnings display
              if (gameState.showNetWorthTicker)
                const NetWorthTicker(),
            ],
          ),
        );
      },
    );
  }
}
