import 'dart:async'; // Import dart:async for Timer
import 'dart:math'; // Import dart:math for Random, pi, cos, sin
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../models/event.dart';
import '../models/game_state_events.dart';
import '../utils/number_formatter.dart';
import '../services/game_service.dart';
import '../utils/sounds.dart';
import 'business_screen.dart';
import 'investment_screen.dart';
import 'stats_screen.dart';
import 'hustle_screen.dart';
import 'real_estate_screen.dart';
import 'user_profile_screen.dart';
import '../widgets/money_display.dart';
import '../widgets/achievement_notification.dart';
import '../widgets/event_notification.dart';
import '../widgets/offline_income_notification.dart';
import '../widgets/premium_purchase_notification.dart';
import '../widgets/challenge_notification.dart';

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
  
  // Add overlayEntry as a class field
  OverlayEntry? _offlineIncomeOverlay;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    
    // Load dependencies
    _gameState = Provider.of<GameState>(context, listen: false);
    _gameService = Provider.of<GameService>(context, listen: false);
    
    // >> START NEW: Initialize boost timer and try showing initial achievement <<
    _initializeBoostTimer();
    
    // Use WidgetsBinding to ensure the first frame is built before potentially showing a notification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { // Check if the widget is still in the tree
        _gameState.tryShowingNextAchievement();
        print("🔔 Initial achievement check triggered.");

        // Check for offline income notification
        _checkAndDisplayOfflineIncome();
        
        // Add a safety check after a short delay in case initial check fails
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            // Try again if it wasn't shown the first time
            if (_offlineIncomeOverlay == null) {
              print("⚠️ Running secondary offline income check after delay...");
              _checkAndDisplayOfflineIncome();
            }
          }
        });
      }
    });
    // >> END NEW <<
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _boostTimer?.cancel(); // Cancel timer on dispose
    // Remove overlay if it exists
    _offlineIncomeOverlay?.remove();
    // Remove listener to avoid memory leaks
    Provider.of<GameState>(context, listen: false).removeListener(_handleGameStateChange);
    super.dispose();
  }

  // FIX: Re-add missing _initializeBoostTimer method
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
              // Top panel with money display
              _buildTopPanel(gameState),
              
              // Display achievement/event notifications
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    _buildAchievementNotifications(gameState),
                    _buildEventNotifications(gameState),
                    _buildChallengeNotification(gameState),
                  ],
                ),
              ),
              
              // ADDED: Premium Purchase Notification (Removed AnimatedSize temporarily)
              // AnimatedSize(
              //  duration: const Duration(milliseconds: 300),
              //  curve: Curves.easeInOut,
                _buildPremiumNotification(gameState), // Directly build
              // ),
              
              // Tab bar for navigation
              _buildTabBar(),
              
              // Main content area with tab views
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
  
  Widget _buildAchievementNotifications(GameState gameState) {
    // NEW LOGIC: Check if there is a current achievement notification to display
    if (gameState.currentAchievementNotification == null) {
      return const SizedBox.shrink(); // Return an empty, zero-sized box
    }
    
    // Use the current achievement from GameState
    final achievement = gameState.currentAchievementNotification!;
    
    return AchievementNotification(
      achievement: achievement,
      gameService: Provider.of<GameService>(context, listen: false),
      // NEW: Use the dismiss method from GameState
      onDismiss: () {
        // No need to call setState here as GameState's notifyListeners will handle the rebuild
        gameState.dismissCurrentAchievementNotification();
      },
    );
  }
  
  Widget _buildEventNotifications(GameState gameState) {
    // If no active events, return empty widget
    if (gameState.activeEvents.isEmpty) {
      return const SizedBox();
    }
    
    // Create a list for event notifications
    List<Widget> eventNotifications = [];
    
    // Only show up to 3 active events at a time
    for (var event in gameState.activeEvents) {
      if (event.isResolved) continue;
      
      eventNotifications.add(EventNotification(
        event: event,
        gameState: gameState,
        onResolved: () {
          // Called when the event is resolved
          setState(() {});
        },
        onTap: event.resolution.type == EventResolutionType.tapChallenge ? () {
          // Process tap for tap challenge events
          gameState.processTapForEvent(event);
          setState(() {});
        } : null,
      ));
      
      // Limit to 3 notifications max
      if (eventNotifications.length >= 3) break;
    }
    
    if (eventNotifications.isEmpty) {
      return const SizedBox();
    }
    
    return Column(
      children: eventNotifications,
    );
  }
  
  Widget _buildChallengeNotification(GameState gameState) {
    // If no active challenge, return empty widget
    if (gameState.activeChallenge == null) {
      return const SizedBox();
    }
    
    return ChallengeNotification(
      challenge: gameState.activeChallenge!,
      gameState: gameState,
    );
  }
  
  Widget _buildTabBar() {
    // Check if platinum frame is active
    final bool isPlatinumFrameActive = Provider.of<GameState>(context, listen: false).isPlatinumFrameUnlocked && 
                                      Provider.of<GameState>(context, listen: false).isPlatinumFrameActive;
    
    return Container(
      decoration: BoxDecoration(
        gradient: isPlatinumFrameActive
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF3D2B5B),  // Deep royal purple
                  Color(0xFF34385E),  // Rich royal blue
                ],
              )
            : null,
        color: isPlatinumFrameActive ? null : Colors.white,
        border: Border(
          top: BorderSide(
            color: isPlatinumFrameActive ? const Color(0xFFFFD700) : Colors.grey.shade300,
            width: isPlatinumFrameActive ? 2.0 : 1.0,
          ),
          bottom: BorderSide(
            color: isPlatinumFrameActive ? const Color(0xFFFFD700) : Colors.grey.shade300,
            width: isPlatinumFrameActive ? 0.5 : 1.0,
          ),
        ),
        boxShadow: isPlatinumFrameActive
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: -4,
                  offset: const Offset(0, -2),
                ),
              ]
            : null,
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: isPlatinumFrameActive ? const Color(0xFFFFD700) : Colors.blue,
        unselectedLabelColor: isPlatinumFrameActive ? Colors.grey.shade400 : Colors.grey,
        indicatorWeight: 3,
        indicatorColor: isPlatinumFrameActive ? const Color(0xFFFFD700) : Colors.blue,
        indicatorPadding: isPlatinumFrameActive ? const EdgeInsets.symmetric(horizontal: 10) : EdgeInsets.zero,
        isScrollable: false,
        labelPadding: EdgeInsets.zero,
        labelStyle: TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.bold,
          shadows: isPlatinumFrameActive
              ? [
                  Shadow(
                    color: const Color(0xFFFFD700).withOpacity(0.5),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        tabs: const [
          Tab(icon: Icon(Icons.touch_app), text: 'Hustle'),
          Tab(icon: Icon(Icons.business), text: 'Biz'),
          Tab(icon: Icon(Icons.trending_up), text: 'Invest'),
          Tab(icon: Icon(Icons.home), text: 'Estate'),
          Tab(icon: Icon(Icons.bar_chart), text: 'Stats'),
          Tab(icon: Icon(Icons.person), text: 'Profile'),
        ],
      ),
    );
  }
  
  Widget _buildTopPanel(GameState gameState) {
    // Get screen width to make panel full width
    final screenWidth = MediaQuery.of(context).size.width;
    final mediaQuery = MediaQuery.of(context);
    
    // Determine if boost is currently active based on GameState
    final bool isBoostCurrentlyActive = gameState.clickMultiplier > 1.0 && 
                                       gameState.clickBoostEndTime != null && 
                                       gameState.clickBoostEndTime!.isAfter(DateTime.now());

    // Check if platinum frame is active
    final bool isPlatinumFrameActive = gameState.isPlatinumFrameUnlocked && gameState.isPlatinumFrameActive;

    return Container(
      width: screenWidth,
      // Reduce overall padding, especially top padding to account for status bar
      padding: EdgeInsets.fromLTRB(
        12, 
        // Add mediaQuery.padding.top to ensure we account for status bar in both modes
        mediaQuery.padding.top + (isPlatinumFrameActive ? 8 : 12), 
        12, 
        isPlatinumFrameActive ? 10 : 12
      ),
      decoration: isPlatinumFrameActive
          ? BoxDecoration(
              // Rich luxury platinum gradient with depth and dimension
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2A1D47),  // Deeper royal purple for contrast
                  Color(0xFF2E2A5A),  // Rich royal blue, slightly darker
                  Color(0xFF34305E),  // Indigo with purple hints
                ],
                stops: [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.7), // More intense golden glow
                  blurRadius: 16,
                  spreadRadius: -2,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 10,
                  spreadRadius: -1,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border(
                bottom: const BorderSide(
                  color: Color(0xFFFFD700), // Pure gold color
                  width: 2.0,
                ),
                top: const BorderSide(
                  color: Color(0xFFFFD700), // Pure gold color
                  width: 0.75,
                ),
                left: BorderSide(
                  color: const Color(0xFFFFD700).withOpacity(0.6), // Gold side accents
                  width: 0.75,
                ),
                right: BorderSide(
                  color: const Color(0xFFFFD700).withOpacity(0.6), // Gold side accents
                  width: 0.75,
                ),
              ),
            )
          : BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1.0,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
      child: Stack(
        children: [
          // Enhanced luxury background pattern for platinum frame (only if active)
          if (isPlatinumFrameActive)
            Positioned.fill(
              child: CustomPaint(
                painter: LuxuryPatternPainter(),
              ),
            ),
          
          // Main content with enhanced visual design
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Account Label and PP Display - More compact for Platinum
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Elevated account label with premium styling
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: isPlatinumFrameActive ? BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFD700), Color(0xFFFDB833)], // Richer gold gradient
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.3),
                          blurRadius: 6,
                          spreadRadius: 0,
                          offset: const Offset(0, -1),
                        ),
                      ],
                    ) : null,
                    child: Row(
                      children: [
                        if (isPlatinumFrameActive)
                          const Icon(
                            Icons.account_balance,
                            color: Color(0xFF241B38),
                            size: 16,
                          ),
                        if (isPlatinumFrameActive)
                          const SizedBox(width: 4),
                        Text(
                          'INVESTMENT ACCOUNT',
                          style: TextStyle(
                            color: isPlatinumFrameActive ? const Color(0xFF241B38) : Colors.grey.shade700,
                            fontSize: 15, // Reduced from 14
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            shadows: isPlatinumFrameActive 
                                ? [
                                    Shadow(
                                      color: Colors.white.withOpacity(0.6),
                                      blurRadius: 2,
                                      offset: const Offset(0, 0.5),
                                    ),
                                  ] 
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // PP display with enhanced glow
                  _buildPPDisplay(gameState),
                ],
              ),
              
              // Tighter spacing for both modes
              SizedBox(height: isPlatinumFrameActive ? 8 : 10),
              
              // Enhanced money container with platinum theme - more depth and dimension
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: isPlatinumFrameActive ? BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1B1E36).withOpacity(0.9),  // Dark base
                      const Color(0xFF262A4F).withOpacity(0.9),  // Rich indigo
                      const Color(0xFF1F2142).withOpacity(0.9),  // Deeper indigo-purple
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.8),
                    width: 1.75,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: -2,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: -2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ) : null,
                child: Column(
                  children: [
                    // Money display with improved styling, reduced size, and better overflow handling
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center, // Vertically align items
                      children: [
                        // Label with iconic platinum money sign - Wrap in Expanded
                        Expanded(
                          flex: 2, // Give label reasonable space
                          child: Row(
                            mainAxisSize: MainAxisSize.min, // Don't expand horizontally
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: isPlatinumFrameActive
                                    ? BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFFFD700), Color(0xFFFFC107)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFFD700).withOpacity(0.6),
                                            blurRadius: 8,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 1),
                                          ),
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.4),
                                            blurRadius: 4,
                                            spreadRadius: -1,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      )
                                    : null,
                                child: Icon(
                                  Icons.attach_money,
                                  color: isPlatinumFrameActive ? Colors.white : Colors.grey.shade800,
                                  size: 18, // Reduced from 20
                                ),
                              ),
                              const SizedBox(width: 8), // Reduced from 10
                              Text(
                                'Cash:',
                                style: TextStyle(
                                  color: isPlatinumFrameActive ? Colors.white : Colors.grey.shade800,
                                  fontSize: 16, // Reduced from 18
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: isPlatinumFrameActive ? 0.5 : 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Value - Wrap in Expanded
                        Expanded(
                          flex: 3, // Give value more space
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: MoneyDisplay(
                              money: gameState.money,
                              fontColor: isPlatinumFrameActive ? Colors.white : Colors.black,
                              fontSize: 18, // Match the income rate size
                              fontWeight: FontWeight.bold,
                              isPlatinumStyle: isPlatinumFrameActive,
                              textAlign: TextAlign.right,
                              shadows: isPlatinumFrameActive
                                  ? [
                                      Shadow(
                                        color: const Color(0xFFFFD700).withOpacity(0.6),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                      Shadow(
                                        color: Colors.black.withOpacity(0.4),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    if (isPlatinumFrameActive) 
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 6), // Reduced from 10
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0x00FFD700), Color(0xFFFFD700), Color(0x00FFD700)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.3),
                              blurRadius: 3,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      )
                    else 
                      const SizedBox(height: 8), // Reduced from 12
                    
                    // Income per second with improved styling - more clear and vibrant, smaller size
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center, // Vertically align items
                      children: [
                        // Label with glowing icon - Wrap in Expanded
                        Expanded(
                          flex: 2, // Give label reasonable space
                          child: Row(
                            mainAxisSize: MainAxisSize.min, // Don't expand horizontally
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: isPlatinumFrameActive
                                    ? BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF4CEA5C), Color(0xFF36C745)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF4CEA5C).withOpacity(0.5),
                                            blurRadius: 8,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 1),
                                          ),
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 4,
                                            spreadRadius: -1,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      )
                                    : null,
                                child: Icon(
                                  Icons.trending_up,
                                  color: isPlatinumFrameActive ? Colors.white : Colors.grey.shade800,
                                  size: 18, // Reduced from 20
                                ),
                              ),
                              const SizedBox(width: 8), // Reduced from 10
                              Text(
                                'Income Rate:',
                                style: TextStyle(
                                  color: isPlatinumFrameActive ? Colors.white : Colors.grey.shade800,
                                  fontSize: 16, // Reduced from 18
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: isPlatinumFrameActive ? 0.5 : 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Value - Wrap in Expanded
                        Expanded(
                          flex: 3, // Give value more space
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${NumberFormatter.formatCurrency(_calculateIncomePerSecond(gameState))}/sec',
                              style: TextStyle(
                                color: isPlatinumFrameActive
                                    ? const Color(0xFF4CEA5C)  // Brighter green for platinum theme
                                    : Colors.green.shade700,
                                fontSize: 18, // Reduced from 24
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                shadows: isPlatinumFrameActive
                                    ? [
                                        Shadow(
                                          color: const Color(0xFF4CEA5C).withOpacity(0.6),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                        Shadow(
                                          color: Colors.black.withOpacity(0.5),
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Active boost timer with premium styling
              if (isBoostCurrentlyActive)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: isPlatinumFrameActive
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF1F2769),  // Deep blue
                              Color(0xFF1A3480),  // Rich blue
                            ],
                          )
                        : null,
                    color: isPlatinumFrameActive ? null : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isPlatinumFrameActive
                          ? const Color(0xFF70C4FF).withOpacity(0.8)
                          : Colors.blue.shade200,
                      width: isPlatinumFrameActive ? 1.5 : 1.0,
                    ),
                    boxShadow: isPlatinumFrameActive
                        ? [
                            BoxShadow(
                              color: const Color(0xFF70C4FF).withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: -2,
                              offset: const Offset(0, 2),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 6,
                              spreadRadius: -2,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isPlatinumFrameActive
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF70A4FF),
                                    Color(0xFF2D78FF),
                                  ],
                                )
                              : null,
                          color: isPlatinumFrameActive ? null : Colors.blue.shade100,
                          boxShadow: isPlatinumFrameActive
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF70C4FF).withOpacity(0.6),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    spreadRadius: -1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          Icons.grid_view,
                          color: isPlatinumFrameActive
                              ? Colors.white
                              : Colors.blue.shade700,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Platinum UI Frame',
                                  style: TextStyle(
                                    color: isPlatinumFrameActive
                                        ? Colors.white
                                        : Colors.blue.shade900,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    letterSpacing: 0.3,
                                    shadows: isPlatinumFrameActive
                                        ? [
                                            Shadow(
                                              color: Colors.black.withOpacity(0.5),
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD700),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'PREMIUM',
                                    style: TextStyle(
                                      color: Color(0xFF1F2769),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Luxury UI active',
                              style: TextStyle(
                                color: isPlatinumFrameActive
                                    ? Colors.blue.shade100
                                    : Colors.blue.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: gameState.isPlatinumFrameActive,
                        onChanged: (bool value) {
                          gameState.togglePlatinumFrame(value);
                        },
                        activeColor: const Color(0xFFFFD700),
                        activeTrackColor: const Color(0xFF70C4FF).withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          // Enhanced corner accents (only if platinum frame active)
          if (isPlatinumFrameActive) ...[
            // Top left corner accent
            Positioned(
              top: 0,
              left: 0,
              child: _buildCornerAccent(),
            ),
            // Top right corner accent
            Positioned(
              top: 0,
              right: 0,
              child: Transform.flip(
                flipX: true,
                child: _buildCornerAccent(),
              ),
            ),
            // Bottom left corner accent
            Positioned(
              bottom: 0,
              left: 0,
              child: Transform.flip(
                flipY: true,
                child: _buildCornerAccent(),
              ),
            ),
            // Bottom right corner accent
            Positioned(
              bottom: 0,
              right: 0,
              child: Transform.flip(
                flipX: true,
                flipY: true,
                child: _buildCornerAccent(),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  // Helper method to build luxury corner accents
  Widget _buildCornerAccent() {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: CornerAccentPainter(),
      ),
    );
  }

  // Helper to calculate total income per second FOR DISPLAY, mirroring _updateGameState logic
  double _calculateIncomePerSecond(GameState gameState) {
    // --- DEBUG START ---
    print("--- Calculating Display Income --- ");
    print("  Global Multipliers: income=${gameState.incomeMultiplier.toStringAsFixed(2)}, prestige=${gameState.prestigeMultiplier.toStringAsFixed(2)}");
    print("  Permanent Boosts: income=${gameState.isPermanentIncomeBoostActive}, efficiency=${gameState.isPlatinumEfficiencyActive}, portfolio=${gameState.isPlatinumPortfolioActive}");
    double totalBusinessIncome = 0;
    double totalRealEstateIncome = 0;
    double totalDividendIncome = 0;
    // --- DEBUG END ---
    
    double total = 0.0;
    
    // Define multipliers (matching _updateGameState)
    double businessEfficiencyMultiplier = gameState.isPlatinumEfficiencyActive ? 1.05 : 1.0;
    double permanentIncomeBoostMultiplier = gameState.isPermanentIncomeBoostActive ? 1.05 : 1.0;
    double portfolioMultiplier = gameState.isPlatinumPortfolioActive ? 1.25 : 1.0;
    double diversificationBonus = gameState.calculateDiversificationBonus();

    // Business Income (with event check)
    for (var business in gameState.businesses) {
      if (business.level > 0) {
        double baseIncome = business.getCurrentIncome(isResilienceActive: gameState.isPlatinumResilienceActive); // Use getCurrentIncome
        double incomeWithEfficiency = baseIncome * businessEfficiencyMultiplier;
        double finalIncome = incomeWithEfficiency * gameState.incomeMultiplier * gameState.prestigeMultiplier;
        finalIncome *= permanentIncomeBoostMultiplier;
        if (gameState.isIncomeSurgeActive) finalIncome *= 2.0;

        bool hasEvent = gameState.hasActiveEventForBusiness(business.id);
        if (hasEvent) {
          finalIncome *= GameStateEvents.NEGATIVE_EVENT_MULTIPLIER;
        }
        // --- DEBUG START ---
        // print("    Business '${business.name}': Base=$baseIncome, Final=$finalIncome (Event: $hasEvent)");
        totalBusinessIncome += finalIncome;
        // --- DEBUG END ---
        total += finalIncome;
      }
    }
    // --- DEBUG START ---
    print("  Subtotal Business: ${totalBusinessIncome.toStringAsFixed(2)}");
    // --- DEBUG END ---
    
    // Real Estate Income (with event check per locale/property)
    for (var locale in gameState.realEstateLocales) {
        if (locale.unlocked) {
          bool isLocaleAffectedByEvent = gameState.hasActiveEventForLocale(locale.id);
          bool isFoundationApplied = gameState.platinumFoundationsApplied.containsKey(locale.id);
          bool isYachtDocked = gameState.platinumYachtDockedLocaleId == locale.id;
          double foundationMultiplier = isFoundationApplied ? 1.05 : 1.0;
          double yachtMultiplier = isYachtDocked ? 1.05 : 1.0;

          for (var property in locale.properties) {
            if (property.owned > 0) {
              double basePropertyIncome = property.getTotalIncomePerSecond(isResilienceActive: gameState.isPlatinumResilienceActive);
              double incomeWithLocaleBoosts = basePropertyIncome * foundationMultiplier * yachtMultiplier;
              double finalPropertyIncome = incomeWithLocaleBoosts * gameState.incomeMultiplier * gameState.prestigeMultiplier;
              finalPropertyIncome *= permanentIncomeBoostMultiplier;
              if (gameState.isIncomeSurgeActive) finalPropertyIncome *= 2.0;

              if (isLocaleAffectedByEvent) {
                finalPropertyIncome *= GameStateEvents.NEGATIVE_EVENT_MULTIPLIER;
              }
              // --- DEBUG START ---
              // print("    Locale '${locale.name}' Property '${property.name}': Base=$basePropertyIncome, Final=$finalPropertyIncome (Event: $isLocaleAffectedByEvent)");
              totalRealEstateIncome += finalPropertyIncome;
              // --- DEBUG END ---
              total += finalPropertyIncome;
            }
          }
        }
      }
    // --- DEBUG START ---
    print("  Subtotal Real Estate: ${totalRealEstateIncome.toStringAsFixed(2)}");
    // --- DEBUG END ---
    
    // Dividend Income (Events don't affect dividends)
    for (var investment in gameState.investments) {
      if (investment.owned > 0 && investment.hasDividends()) {
        // Get total dividend income for this investment (already includes owned shares)
        double baseTotalDividend = investment.getDividendIncomePerSecond();
        
        // Apply portfolio and diversification bonus
        // Note: Diversification bonus conceptually applies to the portfolio, 
        // but applying it per investment like this is simpler and achieves a similar effect.
        double dividendWithBonuses = baseTotalDividend * portfolioMultiplier * (1 + diversificationBonus);
        
        // Apply standard global multipliers 
        double finalInvestmentDividend = dividendWithBonuses *
                                           gameState.incomeMultiplier *
                                           gameState.prestigeMultiplier;
                                           
        // Apply permanent income boost
        finalInvestmentDividend *= permanentIncomeBoostMultiplier;
        
        // Apply Income Surge (if applicable)
        if (gameState.isIncomeSurgeActive) finalInvestmentDividend *= 2.0;
        
        // --- DEBUG START ---
        // print("    Investment '${investment.name}': BaseTotal=$baseTotalDividend, Final=$finalInvestmentDividend");
        totalDividendIncome += finalInvestmentDividend;
        // --- DEBUG END ---
        total += finalInvestmentDividend;
      }
    }
    // --- DEBUG START ---
    print("  Subtotal Dividends: ${totalDividendIncome.toStringAsFixed(2)}");
    print("  TOTAL Display Income: ${total.toStringAsFixed(2)}");
    print("--- End Calculating Display Income --- ");
    // --- DEBUG END ---
    
    return total;
  }
  
  // Format remaining boost time - now takes a Duration
  String _formatBoostTimeRemaining(Duration remaining) {
    if (remaining <= Duration.zero) return 'Expired';

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // Rich UI component for PP display with animation
  Widget _buildPPDisplay(GameState gameState) {
    return InkWell(
      onTap: () {
        // TODO: Add check if vault is unlocked (e.g., gameState.platinumPoints > 0 || gameState.vaultUnlocked)
        Navigator.pushNamed(context, '/platinumVault');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated PP Icon
            AnimatedPPIcon(showAnimation: gameState.showPPAnimation),
            const SizedBox(width: 8),
            // PP Amount with improved styling - sharper text
            Text(
              '${gameState.platinumPoints}',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: Color(0xFF000000),
                    blurRadius: 1,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ADDED: Method to build premium notification
  Widget _buildPremiumNotification(GameState gameState) {
    if (!gameState.showPremiumPurchaseNotification) {
      return const SizedBox.shrink(); // Return empty if flag is false
    }

    // Return the actual notification widget
    return PremiumPurchaseNotification(
      onDismiss: gameState.dismissPremiumPurchaseNotification, // Pass dismiss callback
    );
  }

  // Extract offline income notification to a dedicated method for better maintainability
  void _checkAndDisplayOfflineIncome() {
    print("🔍 MainScreen checking for offline income...");
    
    // Explicitly check for non-zero values before even testing flags
    final earningsData = _gameState.getOfflineEarningsData();
    final double amount = (earningsData['amount'] as num?)?.toDouble() ?? 0.0;
    final Duration duration = earningsData['duration'] as Duration? ?? Duration.zero;
    
    print("📊 PRE-CHECK: amount=$amount, duration=${duration.inSeconds}s, shouldShow=${_gameState.shouldShowOfflineEarnings}");
    
    // If we have valid data, we might want to show it even if flag is not set
    bool hasValidEarnings = amount > 0 && amount.isFinite && duration.inSeconds > 0;
    
    if (hasValidEarnings && !_gameState.shouldShowOfflineEarnings) {
      print("⚠️ Found valid earnings ($amount) but flag is not set! Forcing display...");
      // Force the flag to be set
      _gameState.shouldShowOfflineEarnings = true;
    }
    
    if (_gameState.checkAndClearOfflineEarnings()) {
      print("💰 Displaying offline income notification");
      try {
        // Remove any existing overlay first
        _offlineIncomeOverlay?.remove();
        _offlineIncomeOverlay = null;
        
        // IMPROVED ERROR HANDLING: Validate data before creating notification
        final double verifiedAmount = (earningsData['amount'] as num?)?.toDouble() ?? 0.0;
        final Duration verifiedDuration = earningsData['duration'] as Duration? ?? Duration.zero;
        
        print("🎯 VERIFIED VALUES: amount=$verifiedAmount, duration=${verifiedDuration.inSeconds}s");
        
        // Only show notification if we have meaningful values
        if (verifiedAmount > 0 && verifiedDuration.inSeconds > 0) {
          // Create and insert the notification overlay
          _offlineIncomeOverlay = OverlayEntry(
            builder: (context) => OfflineIncomeNotification(
              amount: verifiedAmount,
              offlineDuration: verifiedDuration,
              onDismiss: () {
                print("💰 Dismissing offline income notification");
                if (_offlineIncomeOverlay != null) {
                  _offlineIncomeOverlay!.remove();
                  _offlineIncomeOverlay = null;
                }
                // Clear the notification state
                _gameState.clearOfflineNotification();
              },
            ),
          );
          
          // Safely insert the overlay
          final overlay = Overlay.of(context);
          if (overlay != null) {
            overlay.insert(_offlineIncomeOverlay!);
            print("✅ Offline income notification displayed successfully");
          } else {
            print("❌ Error: Overlay context is null");
          }
        } else {
          print("❌ Not showing notification: Invalid amount ($verifiedAmount) or duration (${verifiedDuration.inSeconds}s)");
          // Clean up if we're not showing the notification
          _gameState.clearOfflineNotification();
        }
      } catch (e) {
        print("❌ Error displaying offline income notification: $e");
        // Clean up in case of error
        _offlineIncomeOverlay?.remove();
        _offlineIncomeOverlay = null;
        _gameState.clearOfflineNotification();
      }
    } else {
      if (hasValidEarnings) {
        print("⚠️ CheckAndClearOfflineEarnings returned false despite valid data: $amount for ${duration.inSeconds}s");
      } else {
        print("ℹ️ No offline income to display");
      }
    }
  }
}

// Animated PP Icon as a separate widget for better encapsulation
class AnimatedPPIcon extends StatefulWidget {
  final bool showAnimation;
  
  const AnimatedPPIcon({
    Key? key,
    required this.showAnimation,
  }) : super(key: key);
  
  @override
  _AnimatedPPIconState createState() => _AnimatedPPIconState();
}

// Custom painter for luxury background pattern in Platinum UI
class LuxuryPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Create richer luxury patterns with depth and dimension
    final Paint goldStrokePaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    
    final Paint subtlePatternPaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    
    // Create a gradient shader for luxury glow effects
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final goldGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFFFFD700).withOpacity(0.15),
        const Color(0xFFFFF4B8).withOpacity(0.08),
      ],
    );
    
    final Paint sparkleGradientPaint = Paint()
      ..shader = goldGradient.createShader(rect)
      ..style = PaintingStyle.fill;
    
    // Draw high-end subtle diamond pattern background
    final double diamondSize = 32;
    
    // Draw luxury diamond grid pattern
    final Path primaryDiamondPath = Path();
    for (double x = -diamondSize; x < size.width + diamondSize; x += diamondSize * 2) {
      for (double y = -diamondSize; y < size.height + diamondSize; y += diamondSize * 2) {
        primaryDiamondPath.moveTo(x + diamondSize / 2, y);
        primaryDiamondPath.lineTo(x + diamondSize, y + diamondSize / 2);
        primaryDiamondPath.lineTo(x + diamondSize / 2, y + diamondSize);
        primaryDiamondPath.lineTo(x, y + diamondSize / 2);
        primaryDiamondPath.close();
      }
    }
    
    // Draw subtle secondary diamond grid (offset for layered effect)
    final Path secondaryDiamondPath = Path();
    for (double x = -diamondSize + diamondSize; x < size.width + diamondSize; x += diamondSize * 2) {
      for (double y = -diamondSize + diamondSize; y < size.height + diamondSize; y += diamondSize * 2) {
        secondaryDiamondPath.moveTo(x + diamondSize / 2, y);
        secondaryDiamondPath.lineTo(x + diamondSize, y + diamondSize / 2);
        secondaryDiamondPath.lineTo(x + diamondSize / 2, y + diamondSize);
        secondaryDiamondPath.lineTo(x, y + diamondSize / 2);
        secondaryDiamondPath.close();
      }
    }
    
    // Apply base pattern with subtle fill
    canvas.drawPath(
      primaryDiamondPath, 
      Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.03)
        ..style = PaintingStyle.fill,
    );
    
    // Apply strokes for primary grid with more opacity
    canvas.drawPath(
      primaryDiamondPath, 
      Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    
    // Apply strokes for secondary grid with different opacity
    canvas.drawPath(
      secondaryDiamondPath, 
      Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
    
    // Add diagonal pinstripes for texture and depth
    for (double i = -size.height; i < size.width + size.height; i += 40) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        goldStrokePaint,
      );
    }
    
    // Add subtle crosshatch for visual richness
    for (double i = -size.height; i < size.width + size.height; i += 120) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        subtlePatternPaint,
      );
    }
    
    // Add reverse diagonal lines for a woven effect
    for (double i = -size.height; i < size.width + size.height; i += 120) {
      canvas.drawLine(
        Offset(i + size.width, 0),
        Offset(i, size.height),
        subtlePatternPaint..strokeWidth = 0.7,
      );
    }
    
    // Create premium corner highlights
    _drawCornerHighlight(canvas, size, Offset(0, 0), false, false);
    _drawCornerHighlight(canvas, size, Offset(size.width, 0), true, false);
    _drawCornerHighlight(canvas, size, Offset(0, size.height), false, true);
    _drawCornerHighlight(canvas, size, Offset(size.width, size.height), true, true);
    
    // Add premium sparkles with varying sizes for luxury effect
    final Random random = Random(42); // Fixed seed for consistent pattern
    for (int i = 0; i < 80; i++) {
      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height;
      
      // Create varying sized sparkles with emphasis on corners and edges
      double radius;
      
      // Create some larger sparkles at key positions for emphasis
      if (i < 10) {
        // Key positions get larger sparkles
        radius = 1.5 + random.nextDouble() * 2.5;
      } else {
        // Standard sparkles
        radius = 0.8 + random.nextDouble() * 1.2;
      }
      
      // Apply sparkle with glow effect
      final Paint sparklePaint = Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.2 + random.nextDouble() * 0.2)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8); // Soft glow
      
      canvas.drawCircle(
        Offset(x, y),
        radius,
        sparklePaint,
      );
      
      // Add tiny center highlight for selected sparkles
      if (random.nextDouble() > 0.7) {
        canvas.drawCircle(
          Offset(x, y),
          radius * 0.3,
          Paint()..color = Colors.white.withOpacity(0.4),
        );
      }
    }
  }
  
  // Helper method to draw elegant corner highlight accents
  void _drawCornerHighlight(Canvas canvas, Size size, Offset position, bool flipX, bool flipY) {
    final cornerSize = size.width * 0.15;
    
    final Paint cornerGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD700).withOpacity(0.15),
          const Color(0xFFFFD700).withOpacity(0),
        ],
      ).createShader(Rect.fromCircle(center: position, radius: cornerSize));
    
    canvas.drawCircle(position, cornerSize, cornerGlowPaint);
    
    // Draw subtle corner rays
    final Paint rayPaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    
    final double rayLength = cornerSize * 0.7;
    final int rayCount = 5;
    
    for (int i = 0; i < rayCount; i++) {
      double angle = (i * (pi / (rayCount * 2)));
      
      if (flipX && !flipY) angle = pi - angle;
      if (!flipX && flipY) angle = 2 * pi - angle;
      if (flipX && flipY) angle = pi + angle;
      
      final double x2 = position.dx + cos(angle) * rayLength;
      final double y2 = position.dy + sin(angle) * rayLength;
      
      canvas.drawLine(
        position,
        Offset(x2, y2),
        rayPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Custom painter for luxury corner accents
class CornerAccentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Main gold color for elegant accents
    final Paint goldPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    
    // Secondary accent colors with varying opacities for layered effect
    final Paint accentPaint1 = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    
    final Paint accentPaint2 = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    
    // Premium gold fill with subtle gradient
    final Paint goldFillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFFFD700).withOpacity(0.15),
          const Color(0xFFFFE866).withOpacity(0.03),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    
    // Draw primary elegant corner accent - sweeping curve
    final Path primaryPath = Path()
      ..moveTo(0, size.height * 0.8)
      ..cubicTo(
        size.width * 0.1, size.height * 0.25, 
        size.width * 0.25, size.width * 0.1, 
        size.width * 0.8, 0
      );
    
    // Draw a parallel accent line for depth
    final Path secondaryPath = Path()
      ..moveTo(0, size.height * 0.65)
      ..cubicTo(
        size.width * 0.15, size.height * 0.2, 
        size.width * 0.2, size.width * 0.15, 
        size.width * 0.65, 0
      );
    
    canvas.drawPath(primaryPath, goldPaint);
    canvas.drawPath(secondaryPath, accentPaint1);
    
    // Draw decorative luxury motif
    final Path decorativePath = Path();
    
    // Create diamond-shaped accent in corner area
    decorativePath.moveTo(size.width * 0.25, size.height * 0.25);
    decorativePath.lineTo(size.width * 0.4, size.height * 0.1);
    decorativePath.lineTo(size.width * 0.55, size.height * 0.25);
    decorativePath.lineTo(size.width * 0.4, size.height * 0.4);
    decorativePath.close();
    
    // Add inner accent for layered effect
    final Path innerAccentPath = Path();
    innerAccentPath.moveTo(size.width * 0.32, size.height * 0.25);
    innerAccentPath.lineTo(size.width * 0.4, size.height * 0.17);
    innerAccentPath.lineTo(size.width * 0.48, size.height * 0.25);
    innerAccentPath.lineTo(size.width * 0.4, size.height * 0.33);
    innerAccentPath.close();
    
    // Apply gold gradient fill to main motif
    canvas.drawPath(
      decorativePath,
      goldFillPaint,
    );
    
    // Apply gold stroke with higher opacity
    canvas.drawPath(
      decorativePath,
      Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    
    // Apply fill to inner accent
    canvas.drawPath(
      innerAccentPath,
      Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.3)
        ..style = PaintingStyle.fill,
    );
    
    // Apply stroke to inner accent
    canvas.drawPath(
      innerAccentPath,
      Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
    
    // Draw central gold dot with glow effect
    final Paint centerDotPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);
    
    canvas.drawCircle(
      Offset(size.width * 0.4, size.height * 0.25),
      2.0,
      centerDotPaint,
    );
    
    // Add tiny bright center for sparkle effect
    canvas.drawCircle(
      Offset(size.width * 0.4, size.height * 0.25),
      0.8,
      Paint()..color = Colors.white.withOpacity(0.9),
    );
    
    // Draw additional accent lines for framing effect
    // Top edge accent
    canvas.drawLine(
      Offset(size.width * 0.75, 0),
      Offset(size.width, 0),
      accentPaint2..strokeWidth = 1.2,
    );
    
    // Left edge accent
    canvas.drawLine(
      Offset(0, size.height * 0.75),
      Offset(0, size.height),
      accentPaint2..strokeWidth = 1.2,
    );
    
    // Draw subtle corner rays for light effect
    final Paint rayPaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..strokeCap = StrokeCap.round;
    
    // Draw subtle gold rays from center
    for (int i = 0; i < 4; i++) {
      double angle = i * pi / 8;
      double length = size.width * 0.12;
      double startX = size.width * 0.4;
      double startY = size.height * 0.25;
      double endX = startX + cos(angle) * length;
      double endY = startY + sin(angle) * length;
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        rayPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _AnimatedPPIconState extends State<AnimatedPPIcon> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  
  // For the random glitter effect
  List<Map<String, dynamic>> _glitters = [];
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2)
          .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
          .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 60,
      ),
    ]).animate(_animationController);
    
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );
    
    // Generate random glitters
    _generateGlitters();
    
    // Add listener to restart animation when prop changes
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.showAnimation) {
          _animationController.reset();
          _generateGlitters(); // Regenerate glitters for variety
          _animationController.forward();
        }
      }
    });
  }
  
  @override
  void didUpdateWidget(AnimatedPPIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.showAnimation && !oldWidget.showAnimation) {
      _animationController.reset();
      _generateGlitters();
      _animationController.forward();
    }
  }
  
  void _generateGlitters() {
    final random = Random();
    _glitters = List.generate(15, (index) {
      return {
        'size': 1.5 + random.nextDouble() * 2.0,
        'offsetX': -12.0 + random.nextDouble() * 24.0,
        'offsetY': -12.0 + random.nextDouble() * 24.0,
        'delay': random.nextDouble() * 0.7,
        'duration': 0.3 + random.nextDouble() * 0.7,
      };
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: 30,
          height: 30,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Base coin with scale and slight rotation
              Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotateAnimation.value,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFE566), Color(0xFFFFD700)],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFFFFD700),
                          blurRadius: 1,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Color(0xFFFFD700),
                          blurRadius: 6,
                          spreadRadius: -1,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white,
                        width: 0.8,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '✦',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Glitter particles with staggered appearance
              if (widget.showAnimation)
                ...List.generate(_glitters.length, (index) {
                  final glitter = _glitters[index];
                  final delay = glitter['delay'] as double;
                  final duration = glitter['duration'] as double;
                  
                  // Calculate the opacity based on animation progress and delay
                  double opacity = 0.0;
                  if (_animationController.value > delay) {
                    final relativeProgress = (_animationController.value - delay) / duration;
                    // Create a fade in/out effect
                    if (relativeProgress < 0.5) {
                      opacity = relativeProgress * 2.0;
                    } else {
                      opacity = (1.0 - relativeProgress) * 2.0;
                    }
                    // Clamp to valid range
                    opacity = opacity.clamp(0.0, 1.0);
                  }
                  
                  return Positioned(
                    left: 12 + (glitter['offsetX'] as double),
                    top: 12 + (glitter['offsetY'] as double),
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: glitter['size'] as double,
                        height: glitter['size'] as double,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFFFFD700),
                              blurRadius: 4,
                              spreadRadius: 0.5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}