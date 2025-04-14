import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../models/event.dart';
import '../utils/number_formatter.dart';
import '../services/game_service.dart';
import '../utils/sounds.dart';
import 'business_screen.dart';
import 'investment_screen.dart';
import 'stats_screen.dart';
import 'hustle_screen.dart';
import 'real_estate_screen.dart';
import '../widgets/money_display.dart';
import '../widgets/achievement_notification.dart';
import '../widgets/event_notification.dart';
import '../widgets/offline_income_notification.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Build offline income notification with improved error handling
  Widget _buildOfflineIncomeNotification() {
    try {
      print("🔄 Attempting to build offline income notification");
      
      // Get the GameService instance - check for null first
      final GameService? gameService = Provider.of<GameService>(context, listen: false);
      if (gameService == null) {
        print("❌ CRITICAL ERROR: GameService is null - cannot build offline income notification");
        return const SizedBox();
      }
      
      // Get the values with null safety
      final double? earnedAmount = gameService.offlineIncomeEarned;
      final Duration? awayDuration = gameService.offlineDuration;
      
      // Comprehensive logging for debugging
      print("📊 NOTIFICATION DATA CHECK:");
      print("💰 Offline income amount: ${earnedAmount != null ? NumberFormatter.formatCurrency(earnedAmount) : 'null'}");
      print("⏰ Offline duration: ${awayDuration != null ? '${awayDuration.inMinutes} minutes' : 'null'}");
      
      // Check for all required conditions
      if (earnedAmount == null || awayDuration == null) {
        print("ℹ️ Missing offline income data - not showing notification");
        return const SizedBox();
      }
      
      // Further validation
      if (earnedAmount <= 0) {
        print("ℹ️ Offline income is zero or negative (${NumberFormatter.formatCurrency(earnedAmount)}) - not showing notification");
        return const SizedBox();
      }
      
      // Extra safeguard against unreasonable values
      if (awayDuration.inSeconds <= 0) {
        print("⚠️ Invalid offline duration (${awayDuration.inSeconds}s) - not showing notification");
        return const SizedBox();
      }
      
      // Everything validated - log and build the notification
      print("✅ SHOWING OFFLINE INCOME NOTIFICATION:");
      print("💰 Amount: ${NumberFormatter.formatCurrency(earnedAmount)}");
      print("⏰ Duration: ${awayDuration.inMinutes} minutes");
      
      // Return the notification widget with safe values
      return OfflineIncomeNotification(
        amount: earnedAmount,
        offlineDuration: awayDuration,
        onDismiss: () {
          print("🔄 Dismissing offline income notification");
          // Clear the notification data in the service
          gameService.clearOfflineIncomeNotification();
          // Force UI refresh
          setState(() {});
        },
      );
    } catch (e, stackTrace) {
      // Enhanced error logging with stack trace
      print("❌ ERROR BUILDING OFFLINE INCOME NOTIFICATION: $e");
      print("📋 STACK TRACE: $stackTrace");
      return const SizedBox(); // Return empty widget on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
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
              
              // Offline Income notification (if available)
              _buildOfflineIncomeNotification(),
              
              // Achievement notifications
              _buildAchievementNotifications(gameState),
              
              // Event notifications
              _buildEventNotifications(gameState),
              
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
    if (gameState.recentlyCompletedAchievements.isEmpty) {
      return const SizedBox();
    }
    
    final achievement = gameState.recentlyCompletedAchievements.last;
    return AchievementNotification(
      achievement: achievement,
      gameService: Provider.of<GameService>(context, listen: false),
      onDismiss: () {
        gameState.recentlyCompletedAchievements.removeLast();
        gameState.notifyListeners();
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
  
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1),
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
        indicatorWeight: 3,
        indicatorColor: Colors.blue,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        tabs: const [
          Tab(icon: Icon(Icons.touch_app), text: 'Hustle'),
          Tab(icon: Icon(Icons.business), text: 'Biz'),
          Tab(icon: Icon(Icons.trending_up), text: 'Invest'),
          Tab(icon: Icon(Icons.home), text: 'Estate'),
          Tab(icon: Icon(Icons.bar_chart), text: 'Stats'),
        ],
      ),
    );
  }
  
  Widget _buildTopPanel(GameState gameState) {
    // Get screen width to make panel full width
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      width: screenWidth,
      padding: const EdgeInsets.fromLTRB(20, 35, 20, 20),
      decoration: BoxDecoration(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account label
          Text(
            'INVESTMENT ACCOUNT',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
            ),
          ),
          
          const SizedBox(height: 10),
          
          // Money display with improved styling
          Row(
            children: [
              Text(
                'Cash:',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              MoneyDisplay(
                money: gameState.money,
                fontColor: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Income per second with improved styling
          Row(
            children: [
              Text(
                'Income Rate:',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${NumberFormatter.formatCurrency(_calculateIncomePerSecond(gameState))}/sec',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          // Active boost timer
          if (gameState.clickMultiplier > 1.0 && gameState.clickBoostEndTime != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bolt, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '10x Boost Active! Expires in ${_formatBoostTimeRemaining(gameState)}',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // Helper to calculate total income per second
  double _calculateIncomePerSecond(GameState gameState) {
    double total = 0.0;
    
    // Add business income - include both incomeMultiplier and prestigeMultiplier
    for (var business in gameState.businesses) {
      if (business.level > 0) {
        // Check if business is affected by an event
        bool hasEvent = gameState.hasActiveEventForBusiness(business.id);
        
        // Get income with event effect if applicable
        total += business.getIncomePerSecond(affectedByEvent: hasEvent) * 
                 gameState.incomeMultiplier * 
                 gameState.prestigeMultiplier;
      }
    }
    
    // Add real estate income - include both incomeMultiplier and prestigeMultiplier
    total += gameState.getRealEstateIncomePerSecond() * gameState.incomeMultiplier * gameState.prestigeMultiplier;
    
    // Add dividend income from investments - include both incomeMultiplier and prestigeMultiplier
    double dividendIncome = 0.0;
    for (var investment in gameState.investments) {
      if (investment.owned > 0 && investment.hasDividends()) {
        dividendIncome += investment.getDividendIncomePerSecond();
      }
    }
    total += dividendIncome * gameState.incomeMultiplier * gameState.prestigeMultiplier;
    
    return total;
  }
  
  // Format remaining boost time
  String _formatBoostTimeRemaining(GameState gameState) {
    if (gameState.clickBoostEndTime == null) return '';
    
    final now = DateTime.now();
    final end = gameState.clickBoostEndTime!;
    
    if (now.isAfter(end)) return 'Expired';
    
    final remaining = end.difference(now);
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}