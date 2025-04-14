import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'business.dart';
import 'investment.dart';
import 'real_estate.dart';
import 'event.dart';
import 'game_state_events.dart';
import 'achievement.dart';
import '../utils/time_utils.dart';
import 'investment_holding.dart';
import '../data/real_estate_data_loader.dart';

// Market Event definition
class MarketEvent {
  final String name;
  final String description;
  final Map<String, double> categoryImpacts; // Map of category to impact multiplier
  final int durationDays;
  int remainingDays;
  
  MarketEvent({
    required this.name,
    required this.description,
    required this.categoryImpacts,
    required this.durationDays,
    this.remainingDays = 0,
  }) {
    // Set initial remaining days equal to duration
    if (remainingDays == 0) {
      remainingDays = durationDays;
    }
  }
}

class GameState with ChangeNotifier {
  // Basic player stats
  double money = 500.0;
  double totalEarned = 500.0;
  double manualEarnings = 0.0;
  double passiveEarnings = 0.0;
  double investmentEarnings = 0.0;
  double investmentDividendEarnings = 0.0; // New field to track dividend income
  double realEstateEarnings = 0.0;
  double clickValue = 1.5;
  int taps = 0;
  int clickLevel = 1;
  int totalRealEstateUpgradesPurchased = 0; // Track total upgrades purchased
  
  // >> START: Add Achievement Tracking Fields Declaration <<
  double totalUpgradeSpending = 0.0;
  double luxuryUpgradeSpending = 0.0;
  Set<String> fullyUpgradedPropertyIds = {};
  Map<String, int> fullyUpgradedPropertiesPerLocale = {};
  Set<String> localesWithOneFullyUpgradedProperty = {};
  Set<String> fullyUpgradedLocales = {};
  // >> END: Add Achievement Tracking Fields Declaration <<
  
  // Premium features
  bool isPremium = false; // Whether the user has purchased premium
  
  // Lifetime stats (persist across reincorporation)
  int lifetimeTaps = 0;
  DateTime gameStartTime = DateTime.now(); // Tracks when the game was first started
  
  // Achievement tracking
  late AchievementManager achievementManager;
  List<Achievement> recentlyCompletedAchievements = [];
  
  // Game time tracking - CRITICAL FIX: ensure these are always initialized
  DateTime lastSaved = DateTime.now(); // When the game was last saved
  DateTime lastOpened = DateTime.now(); // When the game was last opened

  // Day cycle for market (0-6 representing days of week)
  int currentDay = 0;
  bool isInitialized = false;
  
  // Game assets
  List<Business> businesses = [];
  List<Investment> investments = [];
  List<RealEstateLocale> realEstateLocales = [];
  
  // Market Events System
  List<MarketEvent> activeMarketEvents = [];
  
  // Game Events System
  List<GameEvent> activeEvents = [];           // Currently active events
  DateTime? lastEventTime;                     // When the last event occurred
  bool eventsUnlocked = false;                 // Whether events are unlocked 
  List<DateTime> recentEventTimes = [];        // Timestamps of events in the last hour
  int businessesOwnedCount = 0;                // Track number of businesses owned
  int localesWithPropertiesCount = 0;          // Track number of locales with properties
  
  // Event achievement tracking
  int totalEventsResolved = 0;                 // Total events resolved (any method)
  int eventsResolvedByTapping = 0;             // Events resolved via tap challenge
  int eventsResolvedByFee = 0;                 // Events resolved by paying a fee
  double eventFeesSpent = 0.0;                 // Total money spent on event fees
  int eventsResolvedByAd = 0;                  // Events resolved by watching ads
  Map<String, int> eventsResolvedByLocale = {}; // Events by locale ID
  DateTime? lastEventResolvedTime;             // Timestamp of the last resolved event
  List<GameEvent> resolvedEvents = [];         // History of resolved events (limited to last 25)
  
  // Required methods for the event system
  
  // Check if a business is affected by an active event
  bool hasActiveEventForBusiness(String businessId) {
    for (var event in activeEvents) {
      if (!event.isResolved && event.affectedBusinessIds.contains(businessId)) {
        return true;
      }
    }
    return false;
  }
  
  // Check if a locale is affected by an active event
  bool hasActiveEventForLocale(String localeId) {
    for (var event in activeEvents) {
      if (!event.isResolved && event.affectedLocaleIds.contains(localeId)) {
        return true;
      }
    }
    return false;
  }
  
  // Process tap for tap challenge events
  void processTapForEvent(GameEvent event) {
    if (event.resolution.type != EventResolutionType.tapChallenge) return;
    
    // Get current and required taps
    Map<String, dynamic> tapData = event.resolution.value as Map<String, dynamic>;
    int current = tapData['current'] ?? 0;
    int required = tapData['required'] ?? 0;
    
    // Increment taps and check if complete
    current++;
    tapData['current'] = current;
    
    // Increment lifetime taps to track event taps as well
    lifetimeTaps++; 
    
    if (current >= required) {
      event.resolve();
      
      // Update event achievement tracking
      totalEventsResolved++;
      eventsResolvedByTapping++;
      trackEventResolution(event, "tap");
    }
    
    notifyListeners();
  }
  
  // Track event resolution for achievement tracking
  void trackEventResolution(GameEvent event, String method) {
    // Track resolution time
    lastEventResolvedTime = DateTime.now();
    
    // Track resolution by locale
    for (String localeId in event.affectedLocaleIds) {
      eventsResolvedByLocale[localeId] = (eventsResolvedByLocale[localeId] ?? 0) + 1;
    }
    
    // Store resolved event history
    resolvedEvents.add(event);
    if (resolvedEvents.length > 25) { // Keep only the last 25 events
      resolvedEvents.removeAt(0);
    }
    
    // Notify listeners of state change
    notifyListeners();
  }
  
  // Property for getting total income per second (used for event system)
  double get totalIncomePerSecond {
    double total = 0.0;
    
    // Add business income
    for (var business in businesses) {
      if (business.level > 0) {
        total += business.getIncomePerSecond();
      }
    }
    
    // Add real estate income
    total += getRealEstateIncomePerSecond();
    
    // Add dividend income from investments
    for (var investment in investments) {
      if (investment.owned > 0 && investment.hasDividends()) {
        total += investment.getDividendIncomePerSecond();
      }
    }
    
    return total;
  }
  
  // Multipliers and boosters
  double incomeMultiplier = 1.0;
  double clickMultiplier = 1.0;
  DateTime? clickBoostEndTime;

  // Prestige system
  double prestigeMultiplier = 1.0;
  double networkWorth = 0.0; // Accumulates with each reincorporation
  int reincorporationUsesAvailable = 0; // Available uses of reincorporation
  int totalReincorporations = 0; // Total number of reincorporations performed
  
  // Stats tracking
  Map<String, double> dailyEarnings = {};
  List<double> netWorthHistory = [];
  
  // Timer for autosave
  Timer? _saveTimer;
  Timer? _updateTimer;
  
  // Future for tracking real estate initialization (made public)
  Future<void>? realEstateInitializationFuture;
  
  // Constructor initializes with default values or loaded state
  GameState() {
    _initializeDefaultBusinesses();
    _initializeDefaultInvestments();
    _initializeRealEstateLocales(); // Initializes locales and properties
    _setupTimers();

    // >> NEW: Initialize achievement tracking fields
    totalUpgradeSpending = 0.0;
    luxuryUpgradeSpending = 0.0;
    fullyUpgradedPropertyIds = {};
    fullyUpgradedPropertiesPerLocale = {};
    localesWithOneFullyUpgradedProperty = {};
    fullyUpgradedLocales = {};
    // Ensure totalRealEstateUpgradesPurchased is also initialized if not done elsewhere
    totalRealEstateUpgradesPurchased = 0; 
    // << END NEW

    // Make sure to set this first
    isInitialized = true;
    
    // Run once after initialization to update unlocks based on starting money
    _updateBusinessUnlocks();
    _updateRealEstateUnlocks();
    
    // Load real estate upgrades and store the future (now public)
    realEstateInitializationFuture = initializeRealEstateUpgrades();
    
    // Initialize achievements after game state is ready
    achievementManager = AchievementManager(this);
  }
  
  // Initialize the real estate upgrades from CSV data
  Future<void> initializeRealEstateUpgrades() async {
    try {
      final upgradesByPropertyId = await RealEstateDataLoader.loadUpgradesFromCSV();
      RealEstateDataLoader.applyUpgradesToProperties(realEstateLocales, upgradesByPropertyId);
      
      // Notify listeners that state has changed
      notifyListeners();
    } catch (e) {
      print('Failed to initialize real estate upgrades: $e');
    }
  }
  
  // Initialize with default businesses based on the 10-level upgrade system
  void _initializeDefaultBusinesses() {
    businesses = [
      // 1. Mobile Car Wash
      Business(
        id: 'mobile_car_wash',
        name: 'Mobile Car Wash',
        description: 'A van-based car wash service with direct customer service',
        basePrice: 250.0,
        baseIncome: 0.51, // 15% reduction from 0.6
        level: 0,
        incomeInterval: 1, // Income per second
        unlocked: true,
        icon: Icons.local_car_wash,
        levels: [
          // Level 1
          BusinessLevel(
            cost: 250.0,
            incomePerSecond: 0.51, // 15% reduction from 0.6
            description: 'Better van and supplies',
          ),
          // Level 2
          BusinessLevel(
            cost: 500.0,
            incomePerSecond: 1.28, // 15% reduction from 1.5
            description: 'Pressure washer',
          ),
          // Level 3
          BusinessLevel(
            cost: 1000.0,
            incomePerSecond: 3.06, // 15% reduction from 3.6
            description: 'Extra staff',
          ),
          // Level 4
          BusinessLevel(
            cost: 2000.0,
            incomePerSecond: 7.65, // 15% reduction from 9.0
            description: 'Second van',
          ),
          // Level 5
          BusinessLevel(
            cost: 4000.0,
            incomePerSecond: 20.4, // 15% reduction from 24.0
            description: 'Eco-friendly soap',
          ),
          // Level 6
          BusinessLevel(
            cost: 8000.0,
            incomePerSecond: 51.0, // 15% reduction from 60.0
            description: 'Mobile app rollout',
          ),
          // Level 7
          BusinessLevel(
            cost: 16000.0,
            incomePerSecond: 127.5, // 15% reduction from 150.0
            description: 'Franchise model',
          ),
          // Level 8
          BusinessLevel(
            cost: 32000.0,
            incomePerSecond: 306.0, // 15% reduction from 360.0
            description: 'Fleet expansion',
          ),
          // Level 9
          BusinessLevel(
            cost: 64000.0,
            incomePerSecond: 765.0, // 15% reduction from 900.0
            description: 'VIP detailing',
          ),
          // Level 10
          BusinessLevel(
            cost: 128000.0,
            incomePerSecond: 1912.5, // 15% reduction from 2250.0
            description: 'Citywide coverage',
          ),
        ],
      ),
      
      // 2. Pop-Up Food Stall
      Business(
        id: 'food_stall',
        name: 'Pop-Up Food Stall',
        description: 'A street stall selling food like burgers or tacos',
        basePrice: 1000.0,
        baseIncome: 2.55, // 15% reduction from 3.0
        level: 0,
        incomeInterval: 1,
        unlocked: true,
        icon: Icons.fastfood,
        levels: [
          // Level 1
          BusinessLevel(
            cost: 1000.0,
            incomePerSecond: 2.55, // 15% reduction from 3.0
            description: 'Basic stall',
          ),
          // Level 2
          BusinessLevel(
            cost: 2000.0,
            incomePerSecond: 6.12, // 15% reduction from 7.2
            description: 'Better grill',
          ),
          // Level 3
          BusinessLevel(
            cost: 4000.0,
            incomePerSecond: 15.3, // 15% reduction from 18.0
            description: 'Menu expansion',
          ),
          // Level 4
          BusinessLevel(
            cost: 8000.0,
            incomePerSecond: 38.25, // 15% reduction from 45.0
            description: 'More staff',
          ),
          // Level 5
          BusinessLevel(
            cost: 16000.0,
            incomePerSecond: 96.9, // 15% reduction from 114.0
            description: 'Branded tent',
          ),
          // Level 6
          BusinessLevel(
            cost: 32000.0,
            incomePerSecond: 242.25, // 15% reduction from 285.0
            description: 'Weekend markets',
          ),
          // Level 7
          BusinessLevel(
            cost: 64000.0,
            incomePerSecond: 612.0, // 15% reduction from 720.0
            description: 'Food truck expansion',
          ),
          // Level 8
          BusinessLevel(
            cost: 128000.0,
            incomePerSecond: 1530.0, // 15% reduction from 1800.0
            description: 'Multi-city stalls',
          ),
          // Level 9
          BusinessLevel(
            cost: 256000.0,
            incomePerSecond: 3825.0, // 15% reduction from 4500.0
            description: 'Catering gigs',
          ),
          // Level 10
          BusinessLevel(
            cost: 512000.0,
            incomePerSecond: 9562.5, // 15% reduction from 11250.0
            description: 'Chain operation',
          ),
        ],
      ),
      
      // 3. Boutique Coffee Roaster
      Business(
        id: 'coffee_roaster',
        name: 'Boutique Coffee Roaster',
        description: 'A small-batch coffee roasting and retail business',
        basePrice: 5000.0,
        baseIncome: 10.2, // 15% reduction from 12.0
        level: 0,
        incomeInterval: 1,
        unlocked: true,
        icon: Icons.coffee,
        levels: [
          // Level 1
          BusinessLevel(
            cost: 5000.0,
            incomePerSecond: 10.2, // 15% reduction from 12.0
            description: 'Home roaster offering',
          ),
          // Level 2
          BusinessLevel(
            cost: 10000.0,
            incomePerSecond: 25.5, // 15% reduction from 30.0
            description: 'Premium beans',
          ),
          // Level 3
          BusinessLevel(
            cost: 20000.0,
            incomePerSecond: 63.75, // 15% reduction from 75.0
            description: 'Cafe counter',
          ),
          // Level 4
          BusinessLevel(
            cost: 40000.0,
            incomePerSecond: 153.0, // 15% reduction from 180.0
            description: 'Wholesale deals',
          ),
          // Level 5
          BusinessLevel(
            cost: 80000.0,
            incomePerSecond: 382.5, // 15% reduction from 450.0
            description: 'Efficient Roasting machines',
          ),
          // Level 6
          BusinessLevel(
            cost: 160000.0,
            incomePerSecond: 956.25, // 15% reduction from 1125.0
            description: 'Local chain',
          ),
          // Level 7
          BusinessLevel(
            cost: 320000.0,
            incomePerSecond: 2397.0, // 15% reduction from 2820.0
            description: 'Online store launch',
          ),
          // Level 8
          BusinessLevel(
            cost: 640000.0,
            incomePerSecond: 5992.5, // 15% reduction from 7050.0
            description: 'Brand licensing',
          ),
          // Level 9
          BusinessLevel(
            cost: 1280000.0,
            incomePerSecond: 14981.25, // 15% reduction from 17625.0
            description: 'Export market',
          ),
          // Level 10
          BusinessLevel(
            cost: 2560000.0,
            incomePerSecond: 37485.0, // 15% reduction from 44100.0
            description: 'Global supplier',
          ),
        ],
      ),
      
      // 4. Fitness Studio
      Business(
        id: 'fitness_studio',
        name: 'Fitness Studio',
        description: 'A gym offering classes and personal training',
        basePrice: 20000.0,
        baseIncome: 45.0, // 25% reduction from 60.0
        level: 0,
        incomeInterval: 1,
        unlocked: false,
        icon: Icons.fitness_center,
        levels: [
          // Level 1
          BusinessLevel(
            cost: 20000.0,
            incomePerSecond: 45.0, // 25% reduction from 60.0
            description: 'Small space upgrade',
          ),
          // Level 2
          BusinessLevel(
            cost: 40000.0,
            incomePerSecond: 112.5, // 25% reduction from 150.0
            description: 'New equipment',
          ),
          // Level 3
          BusinessLevel(
            cost: 80000.0,
            incomePerSecond: 281.25, // 25% reduction from 375.0
            description: 'Group classes',
          ),
          // Level 4
          BusinessLevel(
            cost: 160000.0,
            incomePerSecond: 675.0, // 25% reduction from 900.0
            description: 'Hire more trainers',
          ),
          // Level 5
          BusinessLevel(
            cost: 320000.0,
            incomePerSecond: 1687.5, // 25% reduction from 2250.0
            description: 'Acquire expanded space',
          ),
          // Level 6
          BusinessLevel(
            cost: 640000.0,
            incomePerSecond: 4218.75, // 25% reduction from 5625.0
            description: 'App membership',
          ),
          // Level 7
          BusinessLevel(
            cost: 1280000.0,
            incomePerSecond: 10575.0, // 25% reduction from 14100.0
            description: 'Second location',
          ),
          // Level 8
          BusinessLevel(
            cost: 2560000.0,
            incomePerSecond: 26437.5, // 25% reduction from 35250.0
            description: 'Franchise rights',
          ),
          // Level 9
          BusinessLevel(
            cost: 5120000.0,
            incomePerSecond: 66150.0, // 25% reduction from 88200.0
            description: 'Influencer endorsements',
          ),
          // Level 10
          BusinessLevel(
            cost: 10240000.0,
            incomePerSecond: 165375.0, // 25% reduction from 220500.0
            description: 'National chain',
          ),
        ],
      ),
      
      // 5. E-Commerce Store
      Business(
        id: 'ecommerce_store',
        name: 'E-Commerce Store',
        description: 'An online shop selling niche products like gadgets or apparel',
        basePrice: 100000.0,
        baseIncome: 300.0,
        level: 0,
        incomeInterval: 1,
        unlocked: false,
        icon: Icons.shopping_basket,
        levels: [
          // Level 1
          BusinessLevel(
            cost: 100000.0,
            incomePerSecond: 300.0,
            description: 'Basic website',
          ),
          // Level 2
          BusinessLevel(
            cost: 200000.0,
            incomePerSecond: 750.0,
            description: 'SEO boost',
          ),
          // Level 3
          BusinessLevel(
            cost: 400000.0,
            incomePerSecond: 1875.0,
            description: 'Expanded inventory offering',
          ),
          // Level 4
          BusinessLevel(
            cost: 800000.0,
            incomePerSecond: 4680.0,
            description: 'Faster shipping processes',
          ),
          // Level 5
          BusinessLevel(
            cost: 1600000.0,
            incomePerSecond: 11700.0,
            description: 'Ad campaigns',
          ),
          // Level 6
          BusinessLevel(
            cost: 3200000.0,
            incomePerSecond: 29250.0,
            description: 'Mobile app',
          ),
          // Level 7
          BusinessLevel(
            cost: 6400000.0,
            incomePerSecond: 73200.0,
            description: 'Warehouse expansion',
          ),
          // Level 8
          BusinessLevel(
            cost: 12800000.0,
            incomePerSecond: 183000.0,
            description: 'Multi-brand',
          ),
          // Level 9
          BusinessLevel(
            cost: 25600000.0,
            incomePerSecond: 457500.0,
            description: 'Global reach',
          ),
          // Level 10
          BusinessLevel(
            cost: 51200000.0,
            incomePerSecond: 1140000.0,
            description: 'Market leader',
          ),
        ],
      ),
      
      // 6. Craft Brewery
      Business(
        id: 'craft_brewery',
        name: 'Craft Brewery',
        description: 'A brewery producing artisanal beers for local and regional sale',
        basePrice: 500000.0,
        baseIncome: 900.0, // 25% reduction from 1200.0
        level: 0,
        incomeInterval: 1,
        unlocked: false,
        icon: Icons.sports_bar,
        levels: [
          // Level 1
          BusinessLevel(
            cost: 500000.0,
            incomePerSecond: 900.0, // 25% reduction from 1200.0
            description: 'Small batch production',
          ),
          // Level 2
          BusinessLevel(
            cost: 1000000.0,
            incomePerSecond: 2250.0, // 25% reduction from 3000.0
            description: 'Tasting room at brewery',
          ),
          // Level 3
          BusinessLevel(
            cost: 2000000.0,
            incomePerSecond: 5625.0, // 25% reduction from 7500.0
            description: 'New flavors',
          ),
          // Level 4
          BusinessLevel(
            cost: 4000000.0,
            incomePerSecond: 14062.5, // 25% reduction from 18750.0
            description: 'Bigger tanks',
          ),
          // Level 5
          BusinessLevel(
            cost: 8000000.0,
            incomePerSecond: 35156.25, // 25% reduction from 46875.0
            description: 'Distribution agreements',
          ),
          // Level 6
          BusinessLevel(
            cost: 16000000.0,
            incomePerSecond: 87750.0, // 25% reduction from 117000.0
            description: 'Pub chain',
          ),
          // Level 7
          BusinessLevel(
            cost: 32000000.0,
            incomePerSecond: 219375.0, // 25% reduction from 292500.0
            description: 'Canning line',
          ),
          // Level 8
          BusinessLevel(
            cost: 64000000.0,
            incomePerSecond: 549000.0, // 25% reduction from 732000.0
            description: 'National sales team',
          ),
          // Level 9
          BusinessLevel(
            cost: 128000000.0,
            incomePerSecond: 1372500.0, // 25% reduction from 1830000.0
            description: 'Export deals',
          ),
          // Level 10
          BusinessLevel(
            cost: 256000000.0,
            incomePerSecond: 3429000.0, // 25% reduction from 4572000.0
            description: 'Industry giant',
          ),
        ],
      ),
      
      // 7. Boutique Hotel
      Business(
        id: 'boutique_hotel',
        name: 'Boutique Hotel',
        description: 'A stylish hotel catering to travelers and locals',
        basePrice: 2000000.0,
        baseIncome: 4500.0, // 25% reduction from 6000.0
        level: 0,
        incomeInterval: 1,
        unlocked: false,
        icon: Icons.hotel,
        levels: [
          // Level 1
          BusinessLevel(
            cost: 2000000.0,
            incomePerSecond: 4500.0, // 25% reduction from 6000.0
            description: 'Small property',
          ),
          // Level 2
          BusinessLevel(
            cost: 4000000.0,
            incomePerSecond: 11250.0, // 25% reduction from 15000.0
            description: 'More rooms',
          ),
          // Level 3
          BusinessLevel(
            cost: 8000000.0,
            incomePerSecond: 28125.0, // 25% reduction from 37500.0
            description: 'Restaurant opening',
          ),
          // Level 4
          BusinessLevel(
            cost: 16000000.0,
            incomePerSecond: 70312.5, // 25% reduction from 93750.0
            description: 'Spa add-on',
          ),
          // Level 5
          BusinessLevel(
            cost: 32000000.0,
            incomePerSecond: 175781.25, // 25% reduction from 234375.0
            description: 'Luxury suites',
          ),
          // Level 6
          BusinessLevel(
            cost: 64000000.0,
            incomePerSecond: 439200.0, // 25% reduction from 585600.0
            description: 'Event and convention space',
          ),
          // Level 7
          BusinessLevel(
            cost: 128000000.0,
            incomePerSecond: 1098000.0, // 25% reduction from 1464000.0
            description: 'Second location',
          ),
          // Level 8
          BusinessLevel(
            cost: 256000000.0,
            incomePerSecond: 2745000.0, // 25% reduction from 3660000.0
            description: 'Chain branding',
          ),
          // Level 9
          BusinessLevel(
            cost: 512000000.0,
            incomePerSecond: 6862500.0, // 25% reduction from 9150000.0
            description: 'Global presence',
          ),
          // Level 10
          BusinessLevel(
            cost: 1000000000.0,
            incomePerSecond: 17145000.0, // 25% reduction from 22860000.0
            description: 'Luxury empire',
          ),
        ],
      ),
      
      // 8. Film Production Studio
      Business(
        id: 'film_studio',
        name: 'Film Production Studio',
        description: 'A studio making indie films and streaming content',
        basePrice: 10000000.0,
        baseIncome: 22500.0, // 25% reduction from 30000.0
        level: 0,
        incomeInterval: 1,
        unlocked: false,
        icon: Icons.movie,
        levels: [
          // Level 1
          BusinessLevel(
            cost: 10000000.0,
            incomePerSecond: 22500.0, // 25% reduction from 30000.0
            description: 'Small crew',
          ),
          // Level 2
          BusinessLevel(
            cost: 20000000.0,
            incomePerSecond: 56250.0, // 25% reduction from 75000.0
            description: 'Better film and studio gear',
          ),
          // Level 3
          BusinessLevel(
            cost: 40000000.0,
            incomePerSecond: 140625.0, // 25% reduction from 187500.0
            description: 'Bigger castings',
          ),
          // Level 4
          BusinessLevel(
            cost: 80000000.0,
            incomePerSecond: 351562.5, // 25% reduction from 468750.0
            description: 'Studio lot acquired',
          ),
          // Level 5
          BusinessLevel(
            cost: 160000000.0,
            incomePerSecond: 877500.0, // 25% reduction from 1170000.0
            description: 'Streaming deal with major brand',
          ),
          // Level 6
          BusinessLevel(
            cost: 320000000.0,
            incomePerSecond: 2196000.0, // 25% reduction from 2928000.0
            description: 'Blockbuster releases',
          ),
          // Level 7
          BusinessLevel(
            cost: 640000000.0,
            incomePerSecond: 5490000.0, // 25% reduction from 7320000.0
            description: 'Franchise IP',
          ),
          // Level 8
          BusinessLevel(
            cost: 1280000000.0,
            incomePerSecond: 13725000.0, // 25% reduction from 18300000.0
            description: 'Global releases',
          ),
          // Level 9
          BusinessLevel(
            cost: 2560000000.0,
            incomePerSecond: 34312500.0, // 25% reduction from 45750000.0
            description: 'Awards buzz',
          ),
          // Level 10
          BusinessLevel(
            cost: 5120000000.0,
            incomePerSecond: 85500000.0, // 25% reduction from 114000000.0
            description: 'Media titan',
          ),
        ],
      ),
      
      // 9. Logistics Company
      Business(
        id: 'logistics_company',
        name: 'Logistics Company',
        description: 'A freight and delivery service for businesses',
        basePrice: 50000000.0,
        baseIncome: 112500.0, // 25% reduction from 150000.0
        level: 0,
        incomeInterval: 1,
        unlocked: false,
        icon: Icons.local_shipping,
        levels: [
          // Level 1
          BusinessLevel(
            cost: 50000000.0,
            incomePerSecond: 112500.0, // 25% reduction from 150000.0
            description: 'Additional trucks',
          ),
          // Level 2
          BusinessLevel(
            cost: 100000000.0,
            incomePerSecond: 281250.0, // 25% reduction from 375000.0
            description: 'Strategic route expansion',
          ),
          // Level 3
          BusinessLevel(
            cost: 200000000.0,
            incomePerSecond: 702000.0, // 25% reduction from 936000.0
            description: 'Multiple warehouses acquired',
          ),
          // Level 4
          BusinessLevel(
            cost: 400000000.0,
            incomePerSecond: 1755000.0, // 25% reduction from 2340000.0
            description: 'Fleet upgrade with high tech truck and trailers',
          ),
          // Level 5
          BusinessLevel(
            cost: 800000000.0,
            incomePerSecond: 4387500.0, // 25% reduction from 5850000.0
            description: 'Air shipping',
          ),
          // Level 6
          BusinessLevel(
            cost: 1600000000.0,
            incomePerSecond: 10980000.0, // 25% reduction from 14640000.0
            description: 'Automation with robotics',
          ),
          // Level 7
          BusinessLevel(
            cost: 3200000000.0,
            incomePerSecond: 27450000.0, // 25% reduction from 36600000.0
            description: 'Regional hub expansion',
          ),
          // Level 8
          BusinessLevel(
            cost: 6400000000.0,
            incomePerSecond: 68625000.0, // 25% reduction from 91500000.0
            description: 'National scale',
          ),
          // Level 9
          BusinessLevel(
            cost: 12800000000.0,
            incomePerSecond: 171450000.0, // 25% reduction from 228600000.0
            description: 'Global network with tanker shipping',
          ),
          // Level 10
          BusinessLevel(
            cost: 25600000000.0,
            incomePerSecond: 428400000.0, // 25% reduction from 571200000.0
            description: 'Industry leader',
          ),
        ],
      ),
      
      // 10. Luxury Real Estate Developer
      Business(
        id: 'real_estate_developer',
        name: 'Luxury Real Estate Developer',
        description: 'Builds and sells high-end homes and condos',
        basePrice: 250000000.0,
        baseIncome: 450000.0, // 25% reduction from 600000.0
        level: 0,
        incomeInterval: 1,
        unlocked: false,
        icon: Icons.apartment,
        levels: [
          // Level 1
          BusinessLevel(
            cost: 250000000.0,
            incomePerSecond: 450000.0, // 25% reduction from 600000.0
            description: 'Single high end project',
          ),
          // Level 2
          BusinessLevel(
            cost: 500000000.0,
            incomePerSecond: 1125000.0, // 25% reduction from 1500000.0
            description: 'Multiple gated community projects',
          ),
          // Level 3
          BusinessLevel(
            cost: 1000000000.0,
            incomePerSecond: 2812500.0, // 25% reduction from 3750000.0
            description: 'Luxury towers',
          ),
          // Level 4
          BusinessLevel(
            cost: 2000000000.0,
            incomePerSecond: 7020000.0, // 25% reduction from 9360000.0
            description: 'Beachfront high rises',
          ),
          // Level 5
          BusinessLevel(
            cost: 4000000000.0,
            incomePerSecond: 17550000.0, // 25% reduction from 23400000.0
            description: 'Smart homes for ultra rich',
          ),
          // Level 6
          BusinessLevel(
            cost: 8000000000.0,
            incomePerSecond: 43875000.0, // 25% reduction from 58500000.0
            description: 'City expansion projects',
          ),
          // Level 7
          BusinessLevel(
            cost: 16000000000.0,
            incomePerSecond: 109800000.0, // 25% reduction from 146400000.0
            description: 'Resort chain development deals',
          ),
          // Level 8
          BusinessLevel(
            cost: 32000000000.0,
            incomePerSecond: 274500000.0, // 25% reduction from 366000000.0
            description: 'Global brand',
          ),
          // Level 9
          BusinessLevel(
            cost: 64000000000.0,
            incomePerSecond: 684000000.0, // 25% reduction from 912000000.0
            description: 'Billionaire clients',
          ),
          // Level 10
          BusinessLevel(
            cost: 128000000000.0,
            incomePerSecond: 1714500000.0, // 25% reduction from 2286000000.0
            description: 'Real estate empire',
          ),
        ],
      ),
    ];
  }
  
  // Initialize with default investments
  void _initializeDefaultInvestments() {
    investments = [
      // STOCKS
      
      // NexTech - NXT - $10 - ($8-$15)
      Investment(
        id: 'nxt',
        name: 'NexTech',
        description: 'A tech firm specializing in AI software.',
        currentPrice: 10.0,
        basePrice: 10.0,
        volatility: 0.15, // Based on range of $8-$15
        trend: 0.02, // Slight positive trend
        owned: 0,
        icon: Icons.computer,
        color: Colors.blue,
        priceHistory: List.generate(30, (i) {
          // Create slight variations in the initial price history
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04); // 0.98 to 1.02
          return 10.0 * randomFactor;
        }),
        category: 'Technology',
        marketCap: 2.5, // Small-cap tech firm, moderate volatility
      ),
      
      // GreenVolt - GRV - $25 - ($20-$35)
      Investment(
        id: 'grv',
        name: 'GreenVolt',
        description: 'Renewable energy company with steady growth.',
        currentPrice: 25.0,
        basePrice: 25.0,
        volatility: 0.12, // Based on range of $20-$35
        trend: 0.03, // Good steady trend
        owned: 0,
        icon: Icons.eco,
        color: Colors.green,
        priceHistory: List.generate(30, (i) {
          // Create slight variations in the initial price history
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04); // 0.98 to 1.02
          return 25.0 * randomFactor;
        }),
        category: 'Energy',
        marketCap: 5.0, // Mid-size energy firm, stable growth
      ),
      
      // MegaFreight - MFT - $50 - ($40-$70)
      Investment(
        id: 'mft',
        name: 'MegaFreight',
        description: 'Logistics and shipping giant.',
        currentPrice: 50.0,
        basePrice: 50.0,
        volatility: 0.15, // Based on range of $40-$70
        trend: 0.01, // Modest trend
        owned: 0,
        icon: Icons.local_shipping,
        color: Colors.blueGrey,
        priceHistory: List.generate(30, (i) {
          // Create slight variations in the initial price history
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04); // 0.98 to 1.02
          return 50.0 * randomFactor;
        }),
        category: 'Transportation',
        marketCap: 12.0, // Large shipping corporation
      ),
      
      // LuxWear - LXW - $100 - ($80-$130)
      Investment(
        id: 'lxw',
        name: 'LuxWear',
        description: 'High-end fashion brand with trendy spikes.',
        currentPrice: 100.0,
        basePrice: 100.0,
        volatility: 0.20, // Based on range and "trendy spikes"
        trend: 0.02, // Fashion trends come and go
        owned: 0,
        icon: Icons.diamond_outlined,
        color: Colors.pink,
        priceHistory: List.generate(30, (i) {
          // Create slight variations in the initial price history
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04); // 0.98 to 1.02
          return 100.0 * randomFactor;
        }),
        category: 'Fashion',
        marketCap: 3.2, // Boutique fashion company
      ),
      
      // StarForge - STF - $500 - ($400-$700)
      Investment(
        id: 'stf',
        name: 'StarForge',
        description: 'Space exploration company with high risk/reward.',
        currentPrice: 500.0,
        basePrice: 500.0,
        volatility: 0.25, // High risk/reward profile
        trend: 0.04, // Strong growth potential
        owned: 0,
        icon: Icons.rocket_launch,
        color: Colors.deepPurple,
        priceHistory: List.generate(30, (i) {
          // Create slight variations in the initial price history
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04); // 0.98 to 1.02
          return 500.0 * randomFactor;
        }),
        category: 'Aerospace',
        marketCap: 20.0, // High-growth aerospace company
      ),
      
      // CRYPTOCURRENCIES
      
      // BitCoinLite - BCL - $50 - ($30-$80)
      Investment(
        id: 'bcl',
        name: 'BitCoinLite',
        description: 'A beginner-friendly crypto with moderate swings.',
        currentPrice: 50.0,
        basePrice: 50.0,
        volatility: 0.30, // Moderate crypto swings
        trend: 0.02, // Modest trend
        owned: 0,
        icon: Icons.currency_bitcoin,
        color: Colors.amber,
        priceHistory: List.generate(30, (i) {
          // Create slight variations in the initial price history
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04); // 0.98 to 1.02
          return 50.0 * randomFactor;
        }),
        category: 'Cryptocurrency',
        marketCap: 0.85, // Small crypto market cap
      ),
      
      // EtherCore - ETC - $200 - ($150-$300)
      Investment(
        id: 'etc',
        name: 'EtherCore',
        description: 'A blockchain platform with growing adoption.',
        currentPrice: 200.0,
        basePrice: 200.0,
        volatility: 0.25, // Based on price range
        trend: 0.03, // Growing adoption implies positive trend
        owned: 0,
        icon: Icons.hub,
        color: Colors.blue.shade800,
        priceHistory: List.generate(30, (i) {
          // Create slight variations in the initial price history
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04); // 0.98 to 1.02
          return 200.0 * randomFactor;
        }),
        category: 'Cryptocurrency',
        marketCap: 2.4, // Medium-sized blockchain platform
      ),
      
      // MoonToken - MTK - $10 - ($5-$20)
      Investment(
        id: 'mtk',
        name: 'MoonToken',
        description: 'A meme coin with wild volatility.',
        currentPrice: 10.0,
        basePrice: 10.0,
        volatility: 0.50, // Wild volatility as described
        trend: -0.01, // Slight negative trend overall due to meme status
        owned: 0,
        icon: Icons.nightlight_round,
        color: Colors.purple.shade300,
        priceHistory: List.generate(30, (i) {
          // Create slight variations in the initial price history
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04); // 0.98 to 1.02
          return 10.0 * randomFactor;
        }),
        category: 'Cryptocurrency',
        marketCap: 0.25, // Small meme coin market cap
      ),
      
      // StableX - SBX - $100 - ($95-$105)
      Investment(
        id: 'sbx',
        name: 'StableX',
        description: 'A low-risk crypto pegged to real-world value.',
        currentPrice: 100.0,
        basePrice: 100.0,
        volatility: 0.03, // Very low volatility (stablecoin)
        trend: 0.001, // Minimal trend (near zero)
        owned: 0,
        icon: Icons.lock,
        color: Colors.teal,
        priceHistory: List.generate(30, (i) {
          // Create slight variations in the initial price history
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04); // 0.98 to 1.02
          return 100.0 * randomFactor;
        }),
        category: 'Cryptocurrency',
        marketCap: 5.7, // Stablecoin with large adoption
      ),
      
      // QuantumBit - QBT - $1,000 - ($700-$1,500)
      Investment(
        id: 'qbt',
        name: 'QuantumBit',
        description: 'Cutting-edge crypto tied to quantum computing.',
        currentPrice: 1000.0,
        basePrice: 1000.0,
        volatility: 0.35, // High volatility based on range
        trend: 0.05, // Strong positive trend (cutting-edge tech)
        owned: 0,
        icon: Icons.pending,
        color: Colors.cyan.shade700,
        priceHistory: List.generate(30, (i) {
          // Create slight variations in the initial price history
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04); // 0.98 to 1.02
          return 1000.0 * randomFactor;
        }),
        category: 'Cryptocurrency',
        marketCap: 3.2, // Emerging tech with promising growth
      ),
      
      // DIVIDEND INVESTMENTS
      
      // BioTech Innovators Fund - $500 - ($400-$600) - $0.63/sec
      Investment(
        id: 'btf',
        name: 'BioTech Innovators Fund',
        description: 'Fund for biotech startups in gene therapy and vaccines.',
        currentPrice: 500.0,
        basePrice: 500.0,
        volatility: 0.20, // Based on price range $400-$600
        trend: 0.03, // Positive trend for biotech
        owned: 0,
        icon: Icons.healing,
        color: Colors.lightBlue.shade700,
        priceHistory: List.generate(30, (i) {
          // Create slight variations in the initial price history
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04); // 0.98 to 1.02
          return 500.0 * randomFactor;
        }),
        category: 'Healthcare',
        dividendPerSecond: 1.89, // Income per second per share
        marketCap: 12.5, // Fund with multiple biotech companies
      ),
      
      // Streaming Media ETF - $2,000 - ($1,600-$2,400) - $2.52/sec
      Investment(
        id: 'sme',
        name: 'Streaming Media ETF',
        description: 'ETF of streaming platforms and content creators.',
        currentPrice: 2000.0,
        basePrice: 2000.0,
        volatility: 0.20, // Based on price range
        trend: 0.04, // Strong trend for streaming
        owned: 0,
        icon: Icons.live_tv,
        color: Colors.red.shade700,
        priceHistory: List.generate(30, (i) {
          // Create slight variations in the initial price history
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04); // 0.98 to 1.02
          return 2000.0 * randomFactor;
        }),
        category: 'Entertainment',
        dividendPerSecond: 7.56,
        marketCap: 35.8, // Large ETF covering streaming industry
      ),
      
      // Sustainable Agriculture Bonds - $10,000 - ($9,000-$11,000) - $12.6/sec
      Investment(
        id: 'sab',
        name: 'Sustainable Agriculture Bonds',
        description: 'Bonds for organic farming and sustainable food production.',
        currentPrice: 10000.0,
        basePrice: 10000.0,
        volatility: 0.10, // Bonds are relatively stable
        trend: 0.02, // Modest trend
        owned: 0,
        icon: Icons.agriculture,
        color: Colors.green.shade800,
        priceHistory: List.generate(30, (i) {
          // Create slight variations in the initial price history
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04); // 0.98 to 1.02
          return 10000.0 * randomFactor;
        }),
        category: 'Agriculture',
        dividendPerSecond: 39,
        marketCap: 22.7, // Bond portfolio for agricultural investments
      ),
      
      // Global Tourism Index - $50,000 - ($40,000-$60,000) - $63/sec
      Investment(
        id: 'gti',
        name: 'Global Tourism Index',
        description: 'Index fund of major tourism companies.',
        currentPrice: 50000.0,
        basePrice: 50000.0,
        volatility: 0.20, // Based on price range
        trend: 0.03, // Modest positive trend
        owned: 0,
        icon: Icons.flight,
        color: Colors.amber.shade800,
        priceHistory: List.generate(30, (i) {
          // Create slight variations in the initial price history
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04); // 0.98 to 1.02
          return 50000.0 * randomFactor;
        }),
        category: 'Tourism',
        dividendPerSecond: 191,
        marketCap: 86.5, // Global index of tourism companies
      ),
      
      // Urban REIT - $200,000 - ($180,000-$220,000) - $252/sec
      Investment(
        id: 'urt',
        name: 'Urban REIT',
        description: 'REIT for urban commercial properties.',
        currentPrice: 200000.0,
        basePrice: 200000.0,
        volatility: 0.10, // REITs tend to be more stable
        trend: 0.02, // Modest trend
        owned: 0,
        icon: Icons.business,
        color: Colors.brown.shade600,
        priceHistory: List.generate(30, (i) {
          // Create slight variations in the initial price history
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04); // 0.98 to 1.02
          return 200000.0 * randomFactor;
        }),
        category: 'REITs',
        dividendPerSecond: 762,
        marketCap: 125.8, // Urban commercial real estate trust
      ),
      
      // Virtual Reality Ventures - $1M - ($700,000-$1,300,000) - $1,260/sec
      Investment(
        id: 'vrv',
        name: 'Virtual Reality Ventures',
        description: 'Stocks in VR gaming and entertainment companies.',
        currentPrice: 1000000.0,
        basePrice: 1000000.0,
        volatility: 0.30, // High volatility based on range
        trend: 0.05, // Strong trend for emerging tech
        owned: 0,
        icon: Icons.vrpano,
        color: Colors.deepPurple.shade600,
        priceHistory: List.generate(30, (i) {
          // Create slight variations in the initial price history
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04); // 0.98 to 1.02
          return 1000000.0 * randomFactor;
        }),
        category: 'Entertainment',
        dividendPerSecond: 3900,
        marketCap: 75.2, // Emerging technology sector companies
      ),
      
      // Medical Robotics Corp - $5M - ($4M-$6M) - $6,300/sec
      Investment(
        id: 'mrc',
        name: 'Medical Robotics Corp',
        description: 'Company producing robotic surgery and AI diagnostics.',
        currentPrice: 5000000.0,
        basePrice: 5000000.0,
        volatility: 0.20, // Based on price range
        trend: 0.04, // Strong trend for medical tech
        owned: 0,
        icon: Icons.biotech,
        color: Colors.blue.shade800,
        priceHistory: List.generate(30, (i) {
          // Create slight variations in the initial price history
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04); // 0.98 to 1.02
          return 5000000.0 * randomFactor;
        }),
        category: 'Healthcare',
        dividendPerSecond: 19500.0,
        marketCap: 120.7, // Medical technology multinational
      ),
      
      // AgroTech Futures - $20M - ($14M-$26M) - $25,200/sec
      Investment(
        id: 'atf',
        name: 'AgroTech Futures',
        description: 'Futures on agrotech firms in vertical farming.',
        currentPrice: 20000000.0,
        basePrice: 20000000.0,
        volatility: 0.30, // High volatility for futures
        trend: 0.03, // Positive trend
        owned: 0,
        icon: Icons.eco,
        color: Colors.lightGreen.shade800,
        priceHistory: List.generate(30, (i) {
          // Create slight variations in the initial price history
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04); // 0.98 to 1.02
          return 20000000.0 * randomFactor;
        }),
        category: 'Agriculture',
        dividendPerSecond: 83000,
        marketCap: 195.3, // Agricultural technology conglomerate
      ),
      
      // Luxury Resort REIT - $100M - ($90M-$110M) - $126,000/sec
      Investment(
        id: 'lrr',
        name: 'Luxury Resort REIT',
        description: 'REIT for luxury resorts and vacation properties.',
        currentPrice: 100000000.0,
        basePrice: 100000000.0,
        volatility: 0.10, // REITs tend to be more stable
        trend: 0.02, // Modest trend
        owned: 0,
        icon: Icons.beach_access,
        color: Colors.teal.shade600,
        priceHistory: List.generate(30, (i) {
          // Create slight variations in the initial price history
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04); // 0.98 to 1.02
          return 100000000.0 * randomFactor;
        }),
        category: 'REITs',
        dividendPerSecond: 385000,
        marketCap: 580.6, // Global luxury hospitality properties trust
      ),
      
      // Adventure Travel Holdings - $500M - ($400M-$600M) - $630,000/sec
      Investment(
        id: 'ath',
        name: 'Adventure Travel Holdings',
        description: 'Holdings in adventure travel and eco-tourism operators.',
        currentPrice: 500000000.0,
        basePrice: 500000000.0,
        volatility: 0.20, // Based on price range
        trend: 0.03, // Modest trend
        owned: 0,
        icon: Icons.terrain,
        color: Colors.orange.shade800,
        priceHistory: List.generate(30, (i) {
          // Create slight variations in the initial price history
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04); // 0.98 to 1.02
          return 500000000.0 * randomFactor;
        }),
        category: 'Tourism',
        dividendPerSecond: 1900000,
        marketCap: 1250.0, // Global adventure travel conglomerate
      ),
    ];
  }
  
  // Setup game timers
  // Helper method to format time intervals in a human-readable way
  String _formatTimeInterval(int seconds) {
    final int days = seconds ~/ 86400;
    final int hours = (seconds % 86400) ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    final int remainingSeconds = seconds % 60;
    
    if (days > 0) {
      return '$days days, $hours hours';
    } else if (hours > 0) {
      return '$hours hours, $minutes minutes';
    } else if (minutes > 0) {
      return '$minutes minutes, $remainingSeconds seconds';
    } else {
      return '$remainingSeconds seconds';
    }
  }
  
  // Enable premium features (called when purchase is successful)
  void enablePremium() {
    isPremium = true;
    notifyListeners();
    print("Premium status enabled");
  }
  
  void _setupTimers() {
    // Setup timer for auto-saving every minute
    _saveTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      notifyListeners(); // This will trigger the save in GameService
    });
    
    // Setup timer for updating game state every second
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateGameState();
    });
    
    // Timer for updating investment prices (every 30 seconds)
    Timer.periodic(const Duration(seconds: 30), (_) {
      if (isInitialized) {
        _updateInvestmentPrices();
      }
    });
  }
  
  // Update investment prices more frequently
  void _updateInvestmentPrices() {
    // Skip full market events - those still happen only on day change
    for (var investment in investments) {
      // Apply random price change based on volatility and trend
      double change = investment.trend * 0.2; // Base trend (reduced impact)
      
      // Add random component based on volatility
      change += (Random().nextDouble() * 2 - 1) * investment.volatility * 0.3;
      
      // Ensure price doesn't go below minimum threshold
      double newPrice = investment.currentPrice * (1 + change);
      if (newPrice < investment.basePrice * 0.1) {
        newPrice = investment.basePrice * 0.1;
      }
      
      // Cap maximum price to avoid excessive growth
      double maxPrice = investment.basePrice * 10;
      if (newPrice > maxPrice) {
        newPrice = maxPrice;
      }
      
      investment.currentPrice = newPrice;
      
      // Update the price history for chart display
      // This ensures the chart always shows the current price
      if (investment.priceHistory.isNotEmpty) {
        // Replace the last price in history with the current price
        // This keeps the history reflecting the current price without adding extra entries
        investment.priceHistory[investment.priceHistory.length - 1] = investment.currentPrice;
      }
    }
    
    // Notify listeners to update UI
    notifyListeners();
  }
  
  // Update game state every tick
  void _updateGameState() {
    DateTime now = DateTime.now();
    
    // Process event system
    checkAndTriggerEvents();
    
    // Check if click boost has expired
    if (clickBoostEndTime != null && now.isAfter(clickBoostEndTime!)) {
      clickMultiplier = 1.0;
      clickBoostEndTime = null;
      notifyListeners();
    }
    
    // Add micro-updates to investment prices for more dynamic charts
    _updateInvestmentPricesMicro();
    
    // Check for achievement completions
    if (isInitialized && achievementManager != null) {
      List<Achievement> newlyCompleted = achievementManager.evaluateAchievements(this);
      
      // If any new achievements were completed, add them to recently completed list
      if (newlyCompleted.isNotEmpty) {
        recentlyCompletedAchievements.addAll(newlyCompleted);
        notifyListeners();
      }
    }
    
    // Check for reincorporation unlocks
    updateReincorporationUses();
    
    // Update real estate unlocks based on current money
    _updateRealEstateUnlocks();
    
    // Note: Event checking is now handled by the checkAndTriggerEvents() method at the beginning of _updateGameState
    
    // Update businesses income
    for (var business in businesses) {
      if (business.level > 0) {
        business.secondsSinceLastIncome++;
        
        if (business.secondsSinceLastIncome >= business.incomeInterval) {
          // Check if business is affected by an event
          bool hasEvent = hasActiveEventForBusiness(business.id);
          
          // Include both incomeMultiplier and prestigeMultiplier for business income
          double income = business.getCurrentIncome(affectedByEvent: hasEvent) * incomeMultiplier * prestigeMultiplier;
          money += income;
          totalEarned += income;
          passiveEarnings += income;
          
          // Reset timer
          business.secondsSinceLastIncome = 0;
          
          // Record earnings for stats
          String today = TimeUtils.getDayKey(now);
          dailyEarnings[today] = (dailyEarnings[today] ?? 0) + income;
          
          notifyListeners();
        }
      }
    }
    
    // Generate real estate income (per second)
    // Include both incomeMultiplier and prestigeMultiplier for real estate income
    double realEstateIncome = getRealEstateIncomePerSecond() * incomeMultiplier * prestigeMultiplier;
    if (realEstateIncome > 0) {
      money += realEstateIncome;
      totalEarned += realEstateIncome;
      realEstateEarnings += realEstateIncome; // Track real estate earnings separately
      
      // Record earnings for stats
      String today = TimeUtils.getDayKey(now);
      dailyEarnings[today] = (dailyEarnings[today] ?? 0) + realEstateIncome;
      
      notifyListeners();
    }
    
    // Generate dividend income from investments (per second)
    double dividendIncome = 0.0;
    
    // Get the diversification bonus
    double diversificationBonus = calculateDiversificationBonus();
    
    for (var investment in investments) {
      if (investment.owned > 0 && investment.hasDividends()) {
        // Apply income multipliers and diversification bonus to dividend income
        double investmentDividend = investment.getDividendIncomePerSecond() * 
                                   incomeMultiplier * 
                                   prestigeMultiplier * 
                                   (1 + diversificationBonus); // Add diversification bonus
        dividendIncome += investmentDividend;
      }
    }
    
    if (dividendIncome > 0) {
      money += dividendIncome;
      totalEarned += dividendIncome;
      investmentDividendEarnings += dividendIncome; // Track dividend earnings separately
      
      // Record earnings for stats
      String today = TimeUtils.getDayKey(now);
      dailyEarnings[today] = (dailyEarnings[today] ?? 0) + dividendIncome;
      
      notifyListeners();
    }
    
    // Check if it's a new day for investment market
    int todayDay = now.weekday; // 1-7 (Monday-Sunday)
    
    if (todayDay != currentDay) {
      // It's a new day, update investments
      currentDay = todayDay;
      _updateInvestments();
      
      // Update net worth for tracking with dynamic intervals based on game duration
      final gameDuration = now.difference(gameStartTime);
      bool shouldUpdateNetWorth = false;
      
      // If game just started (less than 1 day), track every 15 minutes
      if (gameDuration.inDays < 1) {
        shouldUpdateNetWorth = (now.minute % 15 == 0) && (now.second < 10);
      } 
      // If less than 3 days, track every hour
      else if (gameDuration.inDays < 3) {
        shouldUpdateNetWorth = (now.minute < 5);
      }
      // Otherwise track daily
      else {
        shouldUpdateNetWorth = (now.hour == 0 && now.minute < 10);
      }
      
      if (shouldUpdateNetWorth || netWorthHistory.isEmpty) {
        netWorthHistory.add(calculateNetWorth());
        if (netWorthHistory.length > 30) {
          netWorthHistory.removeAt(0); // Keep only last 30 data points
        }
      }
      
      // Check if we need to unlock more real estate locales
      _updateRealEstateUnlocks();
      
      notifyListeners();
    }
    
    lastSaved = now;
  }
  
  // Update investment prices on new day
  void _updateInvestments() {
    // Generate market events with a small chance
    _generateMarketEvents();
    
    // Process auto-investments if enabled
    _processAutoInvestments();
    
    for (var investment in investments) {
      // Add current price to history
      investment.priceHistory.add(investment.currentPrice);
      if (investment.priceHistory.length > 30) {
        investment.priceHistory.removeAt(0); // Keep only last 30 price points
      }
      
      // Apply random price change based on volatility and trend
      double change = investment.trend; // Base trend
      
      // Add random component based on volatility
      change += (Random().nextDouble() * 2 - 1) * investment.volatility;
      
      // Ensure price doesn't go below minimum threshold
      double newPrice = investment.currentPrice * (1 + change);
      if (newPrice < investment.basePrice * 0.1) {
        newPrice = investment.basePrice * 0.1;
      }
      
      // Cap maximum price to avoid excessive growth
      double maxPrice = investment.basePrice * 10;
      if (newPrice > maxPrice) {
        newPrice = maxPrice;
      }
      
      investment.currentPrice = newPrice;
      
      // Apply market event effects if any are active
      _applyMarketEventEffects(investment);
    }
  }
  
  // Generate random market events
  void _generateMarketEvents() {
    // Small chance to generate a new market event
    if (Random().nextDouble() < 0.15) { // 15% chance per day
      // Create a random market event
      MarketEvent newEvent = _createRandomMarketEvent();
      activeMarketEvents.add(newEvent);
    }
    
    // Decrease remaining days for active events and remove expired ones
    for (int i = activeMarketEvents.length - 1; i >= 0; i--) {
      activeMarketEvents[i].remainingDays--;
      if (activeMarketEvents[i].remainingDays <= 0) {
        activeMarketEvents.removeAt(i);
      }
    }
  }
  
  // Apply market event effects to an investment
  void _applyMarketEventEffects(Investment investment) {
    for (MarketEvent event in activeMarketEvents) {
      // Apply impact if the investment's category is affected
      if (event.categoryImpacts.containsKey(investment.category)) {
        double impact = event.categoryImpacts[investment.category]!;
        investment.currentPrice *= impact;
      }
    }
  }
  
  // Create a random market event
  MarketEvent _createRandomMarketEvent() {
    List<String> eventTypes = [
      'boom',
      'crash',
      'volatility',
      'regulation',
      'innovation'
    ];
    
    String eventType = eventTypes[Random().nextInt(eventTypes.length)];
    
    switch (eventType) {
      case 'boom':
        return _createBoomEvent();
      case 'crash':
        return _createCrashEvent();
      case 'volatility':
        return _createVolatilityEvent();
      case 'regulation':
        return _createRegulationEvent();
      case 'innovation':
        return _createInnovationEvent();
      default:
        return _createBoomEvent(); // Default fallback
    }
  }
  
  // Create a market boom event
  MarketEvent _createBoomEvent() {
    // List of available categories
    List<String> categories = _getInvestmentCategories();
    
    // Choose 1-2 random categories to experience a boom
    int numCategories = Random().nextInt(2) + 1;
    List<String> affectedCategories = [];
    
    for (int i = 0; i < numCategories; i++) {
      if (categories.isNotEmpty) {
        int index = Random().nextInt(categories.length);
        affectedCategories.add(categories[index]);
        categories.removeAt(index);
      }
    }
    
    // Create the impact map
    Map<String, double> impacts = {};
    for (String category in affectedCategories) {
      // Between 2% and 8% daily growth
      double impactValue = 1.0 + (Random().nextDouble() * 0.06 + 0.02);
      impacts[category] = impactValue;
    }
    
    // Pick the first category for the name
    String primaryCategory = affectedCategories.first;
    
    return MarketEvent(
      name: '$primaryCategory Boom',
      description: 'A market boom is happening in the $primaryCategory sector!',
      categoryImpacts: impacts,
      durationDays: Random().nextInt(3) + 2, // 2-4 days
    );
  }
  
  // Create a market crash event
  MarketEvent _createCrashEvent() {
    // List of available categories
    List<String> categories = _getInvestmentCategories();
    
    // Choose 1-2 random categories to experience a crash
    int numCategories = Random().nextInt(2) + 1;
    List<String> affectedCategories = [];
    
    for (int i = 0; i < numCategories; i++) {
      if (categories.isNotEmpty) {
        int index = Random().nextInt(categories.length);
        affectedCategories.add(categories[index]);
        categories.removeAt(index);
      }
    }
    
    // Create the impact map
    Map<String, double> impacts = {};
    for (String category in affectedCategories) {
      // Between 2% and 8% daily decline
      double impactValue = 1.0 - (Random().nextDouble() * 0.06 + 0.02);
      impacts[category] = impactValue;
    }
    
    // Pick the first category for the name
    String primaryCategory = affectedCategories.first;
    
    return MarketEvent(
      name: '$primaryCategory Crash',
      description: 'A market crash is affecting the $primaryCategory sector!',
      categoryImpacts: impacts,
      durationDays: Random().nextInt(3) + 2, // 2-4 days
    );
  }
  
  // Create a market volatility event
  MarketEvent _createVolatilityEvent() {
    // List of available categories
    List<String> categories = _getInvestmentCategories();
    
    // Choose a random category to experience volatility
    String category = categories[Random().nextInt(categories.length)];
    
    // For volatility, we'll actually use a random value each day
    // that could be positive or negative
    double impact = Random().nextBool() ? 1.1 : 0.9; // Start with either +10% or -10%
    
    Map<String, double> impacts = {
      category: impact
    };
    
    return MarketEvent(
      name: 'Market Volatility',
      description: 'The $category market is experiencing high volatility!',
      categoryImpacts: impacts,
      durationDays: Random().nextInt(5) + 3, // 3-7 days
    );
  }
  
  // Create a regulation event
  MarketEvent _createRegulationEvent() {
    // List of available categories
    List<String> categories = _getInvestmentCategories();
    
    // Choose a random category to be regulated
    String category = categories[Random().nextInt(categories.length)];
    
    // Regulations typically cause a slight decline
    Map<String, double> impacts = {
      category: 0.97, // 3% decline
    };
    
    return MarketEvent(
      name: 'New Regulations',
      description: 'New regulations are affecting the $category sector.',
      categoryImpacts: impacts,
      durationDays: Random().nextInt(3) + 5, // 5-7 days (longer impact)
    );
  }
  
  // Create an innovation event
  MarketEvent _createInnovationEvent() {
    // List of available categories
    List<String> categories = _getInvestmentCategories();
    
    // Choose a random category to experience innovation
    String category = categories[Random().nextInt(categories.length)];
    
    // Innovation causes growth
    Map<String, double> impacts = {
      category: 1.05, // 5% growth
    };
    
    return MarketEvent(
      name: 'Technological Breakthrough',
      description: 'A breakthrough innovation is boosting the $category sector!',
      categoryImpacts: impacts,
      durationDays: Random().nextInt(5) + 3, // 3-7 days
    );
  }
  
  // Helper method to get the list of unique investment categories
  List<String> _getInvestmentCategories() {
    Set<String> categories = {};
    for (var investment in investments) {
      categories.add(investment.category);
    }
    return categories.toList();
  }
  
  // Calculate diversification bonus based on owned investments across categories
  double calculateDiversificationBonus() {
    // Count investments owned across different categories
    Set<String> categories = {};
    for (var investment in investments) {
      if (investment.owned > 0) {
        categories.add(investment.category);
      }
    }
    
    // Calculate bonus (e.g., 2% per category)
    return categories.length * 0.02; // Return as decimal, e.g., 0.06 for 6%
  }
  
  // Process auto-investments
  void _processAutoInvestments() {
    for (var investment in investments) {
      if (investment.autoInvestEnabled && investment.autoInvestAmount > 0) {
        // Calculate how many shares can be purchased
        int quantity = (investment.autoInvestAmount / investment.currentPrice).floor();
        
        // Purchase if possible
        if (quantity > 0 && money >= investment.autoInvestAmount) {
          buyInvestment(investment.id, quantity);
        }
      }
    }
  }
  
  // Manual click to earn money
  void tap() {
    double earned = clickValue * clickMultiplier;
    money += earned;
    totalEarned += earned;
    manualEarnings += earned;
    taps++;
    lifetimeTaps++; // Increment lifetime taps count for persistent tracking
    
    String today = TimeUtils.getDayKey(DateTime.now());
    dailyEarnings[today] = (dailyEarnings[today] ?? 0) + earned;
    
    notifyListeners();
  }
  
  // Buy a business
  bool buyBusiness(String businessId) {
    int index = businesses.indexWhere((b) => b.id == businessId);
    if (index == -1) return false;
    
    Business business = businesses[index];
    
    // Check if it's already at max level
    if (business.isMaxLevel()) return false;
    
    double cost = business.getNextUpgradeCost();
    
    if (money >= cost) {
      money -= cost;
      
      // Level up instead of increasing owned count
      business.level++;
      business.unlocked = true;
      
      // Update unlocking of higher businesses
      _updateBusinessUnlocks();
      
      notifyListeners();
      return true;
    }
    
    return false;
  }
  
  // Update which businesses are unlocked based on money
  void _updateBusinessUnlocks() {
    // Count businesses owned for event system
    businessesOwnedCount = businesses.where((b) => b.level > 0).length;
    
    for (var business in businesses) {
      if (!business.unlocked) {
        if (business.id == 'fitness_studio' && money >= 10000.0) {
          business.unlocked = true;
        } else if (business.id == 'ecommerce_store' && money >= 50000.0) {
          business.unlocked = true;
        } else if (business.id == 'craft_brewery' && money >= 250000.0) {
          business.unlocked = true;
        } else if (business.id == 'boutique_hotel' && money >= 1000000.0) {
          business.unlocked = true;
        } else if (business.id == 'film_studio' && money >= 5000000.0) {
          business.unlocked = true;
        } else if (business.id == 'logistics_company' && money >= 25000000.0) {
          business.unlocked = true;
        } else if (business.id == 'real_estate_developer' && money >= 100000000.0) {
          business.unlocked = true;
        }
      }
    }
  }
  
  // Buy an investment
  bool buyInvestment(String investmentId, int quantity) {
    int index = investments.indexWhere((i) => i.id == investmentId);
    if (index == -1) return false;
    
    Investment investment = investments[index];
    double cost = investment.currentPrice * quantity;
    
    if (money >= cost) {
      money -= cost;
      investment.updatePurchasePrice(cost, quantity);
      investment.owned += quantity;
      
      notifyListeners();
      return true;
    }
    
    return false;
  }
  
  // Sell an investment
  bool sellInvestment(String investmentId, int quantity) {
    int index = investments.indexWhere((i) => i.id == investmentId);
    if (index == -1) return false;
    
    Investment investment = investments[index];
    
    if (investment.owned >= quantity) {
      double saleAmount = investment.currentPrice * quantity;
      money += saleAmount;
      investment.owned -= quantity;
      
      // Calculate profit/loss for stats
      double profitLoss = saleAmount - (investment.purchasePrice * quantity);
      investmentEarnings += profitLoss;
      
      // If sold all, reset purchase price
      if (investment.owned == 0) {
        investment.purchasePrice = 0.0;
      }
      
      notifyListeners();
      return true;
    }
    
    return false;
  }
  // Get list of investment holdings with purchase info
  List<InvestmentHolding> getInvestmentHoldings() {
    List<InvestmentHolding> holdings = [];
    
    for (Investment investment in investments) {
      if (investment.owned > 0) {
        holdings.add(InvestmentHolding(
          investmentId: investment.id,
          purchasePrice: investment.purchasePrice,
          shares: investment.owned,
        ));
      }
    }
    
    return holdings;
  }
  
  // Get total value of investment portfolio
  double getTotalInvestmentValue() {
    double total = 0.0;
    
    for (Investment investment in investments) {
      if (investment.owned > 0) {
        total += investment.currentPrice * investment.owned;
      }
    }
    
    return total;
  }

  
  // Buy a click boost (2x for 5 minutes)
  bool buyClickBoost() {
    double cost = 1000.0;
    
    if (money >= cost) {
      money -= cost;
  // Get a specific investment holding
  InvestmentHolding? getInvestmentHolding(String investmentId) {
    List<InvestmentHolding> holdings = getInvestmentHoldings();
    int index = holdings.indexWhere((h) => h.investmentId == investmentId);
    return index >= 0 ? holdings[index] : null;
  }

      clickMultiplier = 2.0;
      clickBoostEndTime = DateTime.now().add(const Duration(minutes: 5));
      
      notifyListeners();
      return true;
    }
    
    return false;
  }
  
  // Calculate total net worth (money + businesses + investments + real estate)
  double calculateNetWorth() {
    double businessesValue = businesses.fold(0.0, (sum, business) => sum + business.getCurrentValue());
    double investmentsValue = investments.fold(0.0, (sum, investment) => sum + investment.getCurrentValue());
    
    // Calculate real estate value (purchase price of all owned properties)
    double realEstateValue = 0.0;
    for (var locale in realEstateLocales) {
      for (var property in locale.properties) {
        realEstateValue += property.purchasePrice * property.owned;
      }
    }
    
    return money + businessesValue + investmentsValue + realEstateValue;
  }
  
  // Convert game state to JSON
  Map<String, dynamic> toJson() {
    print("💾 GameState.toJson starting...");
    Map<String, dynamic> json = {
      'money': money,
      'totalEarned': totalEarned,
      'manualEarnings': manualEarnings,
      'passiveEarnings': passiveEarnings,
      'investmentEarnings': investmentEarnings,
      'investmentDividendEarnings': investmentDividendEarnings, // Added for serialization
      'realEstateEarnings': realEstateEarnings, // Added for serialization
      'clickValue': clickValue,
      'taps': taps,
      'clickLevel': clickLevel,
      'totalRealEstateUpgradesPurchased': totalRealEstateUpgradesPurchased, // Serialize this

      // >> NEW: Serialize achievement tracking fields
      'totalUpgradeSpending': totalUpgradeSpending,
      'luxuryUpgradeSpending': luxuryUpgradeSpending,
      'fullyUpgradedPropertyIds': fullyUpgradedPropertyIds.toList(), // Convert Set to List
      'fullyUpgradedPropertiesPerLocale': fullyUpgradedPropertiesPerLocale,
      'localesWithOneFullyUpgradedProperty': localesWithOneFullyUpgradedProperty.toList(), // Convert Set to List
      'fullyUpgradedLocales': fullyUpgradedLocales.toList(), // Convert Set to List
      // << END NEW

      'isPremium': isPremium,
      'lifetimeTaps': lifetimeTaps,
      'gameStartTime': gameStartTime.toIso8601String(),
      'currentDay': currentDay,
      'incomeMultiplier': incomeMultiplier,
      'clickMultiplier': clickMultiplier,
      'prestigeMultiplier': prestigeMultiplier,
      'networkWorth': networkWorth,
      'reincorporationUsesAvailable': reincorporationUsesAvailable,
      'totalReincorporations': totalReincorporations, // Save total reincorporations performed
      'lastSaved': lastSaved.toIso8601String(),
      
      // Save event system data
      'events': eventsToJson(),
      'lastOpened': DateTime.now().toIso8601String(),
      'isInitialized': true,
    };
    
    if (clickBoostEndTime != null) {
      json['clickBoostEndTime'] = clickBoostEndTime!.toIso8601String();
    }
    
    // Save businesses state
    json['businesses'] = businesses.map((business) => {
      'id': business.id,
      'level': business.level,
      'unlocked': business.unlocked,
      'secondsSinceLastIncome': business.secondsSinceLastIncome,
    }).toList();
    
    // Save investments state
    json['investments'] = investments.map((investment) => {
      'id': investment.id,
      'owned': investment.owned,
      'purchasePrice': investment.purchasePrice,
      'currentPrice': investment.currentPrice,
      'priceHistory': investment.priceHistory,
    }).toList();
    
    // Save real estate state
    json['realEstateLocales'] = realEstateLocales.map((locale) => {
      'id': locale.id,
      'unlocked': locale.unlocked,
      'properties': locale.properties.map((property) => {
        'id': property.id,
        'owned': property.owned,
        // Save the IDs of purchased upgrades
        'purchasedUpgradeIds': property.upgrades
            .where((upgrade) => upgrade.purchased)
            .map((upgrade) => upgrade.id)
            .toList(),
      }).toList(),
    }).toList();
    
    // Save other stats
    json['dailyEarnings'] = dailyEarnings;
    json['netWorthHistory'] = netWorthHistory;
    
    // Save achievements
    json['achievements'] = achievementManager.achievements.map((achievement) => achievement.toJson()).toList();
    
    // Save event system data using the extension method
    json.addAll(eventsToJson());
    
    return json;
  }
  
  // Load game from JSON - NOW ASYNC
  Future<void> fromJson(Map<String, dynamic> json) async { // <-- Mark as async
    money = json['money'] ?? 1000.0;
    totalEarned = json['totalEarned'] ?? 1000.0;
    manualEarnings = json['manualEarnings'] ?? 0.0;
    passiveEarnings = json['passiveEarnings'] ?? 0.0;
    isPremium = json['isPremium'] ?? false;
    investmentEarnings = json['investmentEarnings'] ?? 0.0;
    investmentDividendEarnings = json['investmentDividendEarnings'] ?? 0.0;
    realEstateEarnings = json['realEstateEarnings'] ?? 0.0;
    clickValue = json['clickValue'] ?? 1.5;
    taps = json['taps'] ?? 0;
    clickLevel = json['clickLevel'] ?? 1;
    
    // Load lifetime stats (or initialize if they don't exist yet)
    lifetimeTaps = json['lifetimeTaps'] ?? taps; // Use current taps if lifetimeTaps not stored yet
    if (json['gameStartTime'] != null) {
      gameStartTime = DateTime.parse(json['gameStartTime']);
    }
    
    currentDay = json['currentDay'] ?? 0;
    incomeMultiplier = json['incomeMultiplier'] ?? 1.0;
    clickMultiplier = json['clickMultiplier'] ?? 1.0;
    prestigeMultiplier = json['prestigeMultiplier'] ?? 1.0;
    networkWorth = json['networkWorth'] ?? 0.0;
    reincorporationUsesAvailable = json['reincorporationUsesAvailable'] ?? 0;
    totalReincorporations = json['totalReincorporations'] ?? 0; // Load total reincorporations count
    isInitialized = json['isInitialized'] ?? false;
    
    // CRITICAL FIX: Always ensure we have a valid lastSaved timestamp
    try {
      if (json['lastSaved'] != null) {
        lastSaved = DateTime.parse(json['lastSaved']);
        print("📅 Loaded lastSaved timestamp: ${lastSaved.toIso8601String()}");
      } else {
        // If no lastSaved timestamp found, use current time
        lastSaved = DateTime.now();
        print("⚠️ No lastSaved timestamp found, using current time: ${lastSaved.toIso8601String()}");
      }
    } catch (e) {
      // In case of any parsing errors, use current time as fallback
      print("❌ Error parsing lastSaved timestamp: $e");
      lastSaved = DateTime.now();
      print("🔄 Using current time as fallback for lastSaved: ${lastSaved.toIso8601String()}");
    }
    
    // CRITICAL FIX: Handle lastOpened with robust error handling
    try {
      if (json['lastOpened'] != null) {
        DateTime previousOpen = DateTime.parse(json['lastOpened']);
        print("📆 Loaded lastOpened timestamp: ${previousOpen.toIso8601String()}");
        
        // Calculate offline time
        DateTime now = DateTime.now();
        int secondsElapsed = now.difference(previousOpen).inSeconds;
        print("⏱️ Time since last opened: ${secondsElapsed} seconds");
        
        // Process offline progress if more than 10 seconds elapsed
      
        if (secondsElapsed > 10) {
          print("💰 Processing offline progress for $secondsElapsed seconds");
          _processOfflineProgress(secondsElapsed);
        }
      } else {
        print("⚠️ No lastOpened timestamp found, using current time");
      }
    } catch (e) {
      print("❌ Error parsing lastOpened timestamp: $e");
    }
    
    // Always update lastOpened to current time
    lastOpened = DateTime.now();
    print("🔄 Updated lastOpened to: ${lastOpened.toIso8601String()}");
    
    if (json['clickBoostEndTime'] != null) {
      clickBoostEndTime = DateTime.parse(json['clickBoostEndTime']);
      
      // Check if the boost is already expired
      if (DateTime.now().isAfter(clickBoostEndTime!)) {
        clickMultiplier = 1.0;
        clickBoostEndTime = null;
      }
    }
    
    // Load businesses
    if (json['businesses'] != null) {
      List<dynamic> businessesJson = json['businesses'];
      
      // Map JSON businesses to existing businesses
      for (var businessJson in businessesJson) {
        if (businessJson['id'] == null) continue; // Skip if id is null
        
        String id = businessJson['id'];
        int index = businesses.indexWhere((b) => b.id == id);
        
        if (index != -1) {
          // Handle both old 'owned' and new 'level' format for backward compatibility
          if (businessJson['level'] != null) {
            businesses[index].level = businessJson['level'];
          } else if (businessJson['owned'] != null) {
            // Convert old owned count to level (owned > 0 means at least level 1)
            businesses[index].level = businessJson['owned'] > 0 ? 1 : 0;
          }
          businesses[index].unlocked = businessJson['unlocked'] ?? false;
          businesses[index].secondsSinceLastIncome = businessJson['secondsSinceLastIncome'] ?? 0;
        }
      }
    }
    
    // Load investments
    if (json['investments'] != null) {
      List<dynamic> investmentsJson = json['investments'];
      
      // Map JSON investments to existing investments
      for (var investmentJson in investmentsJson) {
        if (investmentJson['id'] == null) continue; // Skip if id is null
        
        String id = investmentJson['id'];
        int index = investments.indexWhere((i) => i.id == id);
        
        if (index != -1) {
          investments[index].owned = investmentJson['owned'] ?? 0;
          investments[index].currentPrice = investmentJson['currentPrice'] ?? investments[index].basePrice;
          investments[index].purchasePrice = investmentJson['purchasePrice'] ?? investments[index].basePrice;
          
          if (investmentJson['priceHistory'] != null) {
            try {
              List<dynamic> history = investmentJson['priceHistory'];
              investments[index].priceHistory = history.map((e) => (e is double) ? e : (e is int) ? e.toDouble() : 0.0).toList();
            } catch (e) {
              print('Error parsing price history: $e');
              // Use default price history if parsing fails
              investments[index].priceHistory = List.generate(30, (_) => investments[index].basePrice);
            }
          }
        }
      }
    }
    
    // Ensure real estate upgrades are loaded before applying saved state
    if (realEstateInitializationFuture != null) { // <-- Use public name
      print("⏳ Waiting for real estate initialization before loading saved state...");
      await realEstateInitializationFuture; // <-- Use public name
      print("✅ Real estate initialization complete. Proceeding with loading saved state.");
    }
    
    // Load real estate
    if (json['realEstateLocales'] != null) {
      List<dynamic> realEstateJson = json['realEstateLocales'];
      
      for (var localeJson in realEstateJson) {
        if (localeJson['id'] == null) continue;
        
        String id = localeJson['id'];
        int localeIndex = realEstateLocales.indexWhere((locale) => locale.id == id);
        
        if (localeIndex != -1) {
          // Update locale unlock status
          realEstateLocales[localeIndex].unlocked = localeJson['unlocked'] ?? false;
          
          // Update property owned counts and upgrades
          if (localeJson['properties'] != null) {
            List<dynamic> propertiesJson = localeJson['properties'];
            
            for (var propertyJson in propertiesJson) {
              if (propertyJson['id'] == null) continue;
              
              String propertyId = propertyJson['id'];
              int propertyIndex = realEstateLocales[localeIndex].properties.indexWhere((p) => p.id == propertyId);
              
              if (propertyIndex != -1) {
                final property = realEstateLocales[localeIndex].properties[propertyIndex];
                property.owned = propertyJson['owned'] ?? 0;

                // Load purchased upgrade IDs
                if (propertyJson['purchasedUpgradeIds'] != null) {
                  List<String> purchasedIds = List<String>.from(propertyJson['purchasedUpgradeIds']);
                  print("🔧 Loading upgrades for ${property.name} (${property.id}). Found ${purchasedIds.length} purchased IDs in save.");
                  print("   Current upgrades in memory: ${property.upgrades.length}");
                  
                  // Mark upgrades as purchased based on loaded IDs
                  int appliedCount = 0;
                  for (var upgrade in property.upgrades) {
                    if (purchasedIds.contains(upgrade.id)) {
                      if (!upgrade.purchased) { // Apply only if not already marked (might happen if loaded twice?)
                         upgrade.purchased = true;
                         appliedCount++;
                         print("      -> Applied purchased status to upgrade: ${upgrade.id} (${upgrade.description})");
                      } else {
                         print("      -> Upgrade already marked purchased: ${upgrade.id}");
                      }
                    } else {
                      // Ensure upgrades not in the list are marked as not purchased
                      // This handles cases where an upgrade might have been removed or save file is old
                      upgrade.purchased = false; 
                    }
                  }
                  print("   Applied purchased status to $appliedCount upgrades for ${property.name}.");
                } else {
                  // If no purchased IDs are saved, ensure all current upgrades are marked not purchased
                  print("🔧 No purchased upgrade IDs found for ${property.name} in save. Ensuring all current upgrades are marked not purchased.");
                  for (var upgrade in property.upgrades) {
                    upgrade.purchased = false;
                  }
                }
              }
            }
          }
        }
      }
    }
    
    // Load stats
    if (json['dailyEarnings'] != null) {
      Map<String, dynamic> dailyJson = json['dailyEarnings'];
      dailyEarnings = Map<String, double>.from(dailyJson);
    }
    
    if (json['netWorthHistory'] != null) {
      List<dynamic> historyJson = json['netWorthHistory'];
      netWorthHistory = historyJson.map((e) => e as double).toList();
    }
    
    // Initialize achievements manager
    achievementManager = AchievementManager(this);
    
    // Load achievement completions from saved state if they exist
    if (json['achievements'] != null) {
      List<dynamic> achievementsJson = json['achievements'];
      
      for (var achievementJson in achievementsJson) {
        String id = achievementJson['id'];
        bool completed = achievementJson['completed'] ?? false;
        
        if (completed) {
          // Find and mark the achievement as completed
          int index = achievementManager.achievements.indexWhere((a) => a.id == id);
          if (index != -1) {
            achievementManager.achievements[index].completed = true;
          }
        }
      }
    }
    
    // Load event system data using the extension method
    eventsFromJson(json);
    
    isInitialized = true;
    notifyListeners();
    print("✅ GameState.fromJson complete.");
  }
  
  // Process progress while game was closed
  void _processOfflineProgress(int secondsElapsed) {

    final int oneDaysInSeconds = 86400; // 24 hours * 60 minutes * 60 seconds
    int cappedSeconds = secondsElapsed > oneDaysInSeconds ? oneDaysInSeconds : secondsElapsed;
    
    print("💵 Processing offline income for ${cappedSeconds} seconds (capped from ${secondsElapsed})");
    print("📊 Time away: ${_formatTimeInterval(secondsElapsed)}");
    print("📊 Income period: ${_formatTimeInterval(cappedSeconds)}");
    
    
    // Calculate offline income from businesses
    for (var business in businesses) {
      if (business.level > 0) {
        // Calculate how many income cycles occurred
        int cycles = cappedSeconds ~/ business.incomeInterval;
        if (cycles > 0) {
          double income = business.getCurrentIncome() * cycles * incomeMultiplier;
          money += income;
          totalEarned += income;
          passiveEarnings += income;
        }
      }
    }
    
    // Calculate offline income from real estate (continuous per second)
    double realEstateIncomePerSecond = getRealEstateIncomePerSecond();
    if (realEstateIncomePerSecond > 0) {
      double realEstateIncome = realEstateIncomePerSecond * cappedSeconds * incomeMultiplier;
      money += realEstateIncome;
      totalEarned += realEstateIncome;
      realEstateEarnings += realEstateIncome; // Track real estate earnings separately
    }
    
    // Make sure timers are set up after loading from JSON
    // Cancel any existing timers first to prevent duplicates
    _saveTimer?.cancel();
    _updateTimer?.cancel();
    
    // Set up new timers
    _setupTimers();
    
    // Force update to unlock businesses and properties based on current money
    _updateBusinessUnlocks();
    _updateRealEstateUnlocks();
    
    // Make sure achievement manager is initialized
    if (achievementManager == null) {
      achievementManager = AchievementManager(this);
    }
    
    lastOpened = DateTime.now();
    
    // Notify listeners of the state change
    notifyListeners();
  }
  
  @override
  void dispose() {
    _saveTimer?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }
  
  // Reset game state to default values without creating a new instance
  void resetToDefaults() {
    // Reset basic player stats
    money = 500.0;
    totalEarned = 500.0;
    manualEarnings = 0.0;
    passiveEarnings = 0.0;
    investmentEarnings = 0.0;
    investmentDividendEarnings = 0.0;
    realEstateEarnings = 0.0;
    clickValue = 1.5; // Already updated from 1.0
    taps = 0;
    clickLevel = 1;
    
    // Don't reset premium status - this is a paid feature that should persist
    // isPremium stays unchanged
    
    // Reset lifetime stats (full game reset, not just reincorporation)
    lifetimeTaps = 0;
    gameStartTime = DateTime.now();
    
    // Reset time tracking
    lastSaved = DateTime.now();
    lastOpened = DateTime.now();
    currentDay = 0;
    
    // Reset multipliers and boosters
    incomeMultiplier = 1.0;
    clickMultiplier = 1.0;
    clickBoostEndTime = null;
    
    // Reset prestige system
    prestigeMultiplier = 1.0;
    networkWorth = 0.0;
    reincorporationUsesAvailable = 0;
    totalReincorporations = 0; // Reset the total reincorporations count
    
    // Reset stats tracking
    dailyEarnings = {};
    netWorthHistory = [];
    
    // Reset market events
    activeMarketEvents = [];
    
    // Re-initialize businesses and investments
    _initializeDefaultBusinesses();
    _initializeDefaultInvestments();
    _initializeRealEstateLocales();
    
    // Update unlocks based on starting money
    _updateBusinessUnlocks();
    _updateRealEstateUnlocks();
    
    // Reset achievements
    achievementManager = AchievementManager(this);
    recentlyCompletedAchievements = [];
    
    // Reset event system
    activeEvents = [];
    lastEventTime = null;
    eventsUnlocked = false;
    recentEventTimes = [];
    businessesOwnedCount = 0;
    localesWithPropertiesCount = 0;
    
    // Notify listeners that state has changed
    notifyListeners();
    
    print("Game state reset to defaults");
  }
  
  // Reincorporate (prestige) to earn permanent multipliers
  bool reincorporate() {
    // Check if we have any available uses or meet the minimum requirement
    updateReincorporationUses();
    double currentNetWorth = calculateNetWorth();
    double minRequiredNetWorth = getMinimumNetWorthForReincorporation();
    
    // Verify player can reincorporate
    if (reincorporationUsesAvailable <= 0 && currentNetWorth < minRequiredNetWorth) {
      return false;
    }
    
    // Calculate the prestige level being used in this reincorporation
    double baseRequirement = 1000000.0; // $1 million
    int currentPrestigeLevel = 0;
    
    // Calculate which threshold we're using (1, 2, 3, etc. for $1M, $10M, $100M...)
    if (currentNetWorth >= baseRequirement) {
      currentPrestigeLevel = (log(currentNetWorth / baseRequirement) / log(10)).floor() + 1;
    }
    
    // The network worth needs to be updated based on which threshold is being used
    // For $1M (level 1): add 0.01 to networkWorth
    // For $10M (level 2): add 0.1 to networkWorth
    // For $100M (level 3): add 1.0 to networkWorth
    // For $1B (level 4): add 10.0 to networkWorth
    
    // Convert the prestige level to the right networkWorth increment
    double networkWorthIncrement = pow(10, currentPrestigeLevel - 1).toDouble() / 100;
    
    // Update network worth - this is a lifetime statistic that persists across reincorporations
    networkWorth += networkWorthIncrement;
    
    // Calculate new passive income bonus (20% compounding per prestige level)
    double passiveBonus = 1.0;
    
    // Count how many threshold levels we've now used based on updated networkWorth
    int totalPrestigeLevels = 0;
    if (networkWorth > 0) {
      // $1M threshold
      if (networkWorth >= 0.01) totalPrestigeLevels++;
      // $10M threshold
      if (networkWorth >= 0.1) totalPrestigeLevels++;
      // $100M threshold
      if (networkWorth >= 1.0) totalPrestigeLevels++;
      // $1B threshold
      if (networkWorth >= 10.0) totalPrestigeLevels++;
      // $10B threshold
      if (networkWorth >= 100.0) totalPrestigeLevels++;
    }
    
    // Calculate passive bonus with 20% compounding per prestige level
    passiveBonus = pow(1.2, totalPrestigeLevels).toDouble();
    
    // Update click multiplier (1.1x per level)
    // First prestige should be 1.2x instead of 1.1x
    double newClickMultiplier = 1.0 + (0.1 * totalPrestigeLevels);
    if (totalPrestigeLevels > 0 && newClickMultiplier < 1.2) {
      newClickMultiplier = 1.2;
    }
    
    // Save the multiplier
    prestigeMultiplier = newClickMultiplier;
    
    // Decrease available uses
    reincorporationUsesAvailable--;
    
    // Increment total reincorporations counter
    totalReincorporations++;
    
    // Reset basic player stats but with prestige bonus
    money = 500.0 * prestigeMultiplier;
    totalEarned = money;
    manualEarnings = 0.0;
    passiveEarnings = 0.0;
    investmentEarnings = 0.0;
    investmentDividendEarnings = 0.0;
    realEstateEarnings = 0.0;
    // Update clickValue based on clickLevel and prestigeMultiplier
    // Base is 1.5, but we need to account for the current click level
    double baseClickValue = 1.5;
    double levelMultiplier = 1.0 + ((clickLevel - 1) * 0.5); // Each level adds 50% to base
    clickValue = baseClickValue * levelMultiplier * prestigeMultiplier;
    
    // Reset taps to the beginning of the current level instead of 0
    // This ensures the progress bar displays correctly and user maintains level progress
    if (clickLevel <= 5) {
      taps = (500 * (clickLevel - 1)) + 500;
    } else if (clickLevel <= 10) {
      taps = (750 * (clickLevel - 1)) + 500;
    } else {
      taps = (1000 * (clickLevel - 1)) + 500;
    }
    
    // Note: lifetimeTaps is intentionally not reset as it persists across reincorporation
    
    // Note: clickLevel is now also preserved across reincorporation
    
    // Reset time tracking
    lastSaved = DateTime.now();
    lastOpened = DateTime.now();
    // Note: gameStartTime is intentionally not reset as it persists across reincorporation
    currentDay = 0;
    
    // Set income multiplier to reflect the passive income bonus
    incomeMultiplier = passiveBonus;
    clickMultiplier = 1.0;
    clickBoostEndTime = null;
    
    // Reset stats tracking
    dailyEarnings = {};
    netWorthHistory = [];
    
    // Reset market events
    activeMarketEvents = [];
    
    // Re-initialize businesses and investments
    _initializeDefaultBusinesses();
    _initializeDefaultInvestments();
    _resetRealEstateForReincorporation();
    
    // Update unlocks based on starting money
    _updateBusinessUnlocks();
    _updateRealEstateUnlocks();
    
    // Reset event system
    activeEvents = [];
    lastEventTime = null;
    eventsUnlocked = false;
    recentEventTimes = [];
    businessesOwnedCount = 0;
    localesWithPropertiesCount = 0;
    
    // Notify listeners that state has changed
    notifyListeners();
    
    print("Reincorporated with network worth: $networkWorth, click multiplier: $prestigeMultiplier, passive bonus: $passiveBonus");
    return true;
  }
  
  // Get the minimum net worth required for reincorporation
  double getMinimumNetWorthForReincorporation() {
    // First use at $1M, subsequent uses at 10x increments
    if (reincorporationUsesAvailable > 0) {
      // If we have available uses, no minimum required
      return 0.0;
    }
    
    // Calculate next threshold based on thresholds already used
    // $1M, $10M, $100M, $1B, $10B, $100B, $1T, $10T, $100T
    double baseRequirement = 1000000.0; // $1 million for first unlock
    
    // Count which thresholds have already been used
    int thresholdsUsed = 0;
    if (networkWorth > 0) {
      // For the $1M threshold
      if (networkWorth >= 0.01) thresholdsUsed++;
      
      // For the $10M threshold
      if (networkWorth >= 0.1) thresholdsUsed++;
      
      // For the $100M threshold
      if (networkWorth >= 1.0) thresholdsUsed++;
      
      // For the $1B threshold
      if (networkWorth >= 10.0) thresholdsUsed++;
      
      // For the $10B threshold
      if (networkWorth >= 100.0) thresholdsUsed++;
      
      // For the $100B threshold
      if (networkWorth >= 1000.0) thresholdsUsed++;
      
      // For the $1T threshold
      if (networkWorth >= 10000.0) thresholdsUsed++;
      
      // For the $10T threshold
      if (networkWorth >= 100000.0) thresholdsUsed++;
      
      // For the $100T threshold
      if (networkWorth >= 1000000.0) thresholdsUsed++;
    }
    
    // Return the minimum required for the next threshold
    // First use is $1M (10^0), second is $10M (10^1), etc.
    return baseRequirement * pow(10, thresholdsUsed);
  }
  
  // Calculate the number of achieved reincorporation levels based on networkWorth
  int getAchievedReincorporationLevels() {
    int levelsAchieved = 0;
    if (networkWorth > 0) {
      // $1M threshold
      if (networkWorth >= 0.01) levelsAchieved++;
      // $10M threshold
      if (networkWorth >= 0.1) levelsAchieved++;
      // $100M threshold
      if (networkWorth >= 1.0) levelsAchieved++;
      // $1B threshold
      if (networkWorth >= 10.0) levelsAchieved++;
      // $10B threshold
      if (networkWorth >= 100.0) levelsAchieved++;
      // $100B threshold
      if (networkWorth >= 1000.0) levelsAchieved++;
      // $1T threshold
      if (networkWorth >= 10000.0) levelsAchieved++;
      // $10T threshold
      if (networkWorth >= 100000.0) levelsAchieved++;
      // $100T threshold
      if (networkWorth >= 1000000.0) levelsAchieved++;
    }
    return levelsAchieved;
  }
  
  // Check and update available reincorporation uses
  void updateReincorporationUses() {
    double netWorth = calculateNetWorth();
    double baseRequirement = 1000000.0; // $1 million
    
    // Calculate how many thresholds the player has crossed in total
    int totalThresholdsCrossed = 0;
    if (netWorth >= baseRequirement) {
      // Calculate how many power-of-10 thresholds have been crossed
      totalThresholdsCrossed = (log(netWorth / baseRequirement) / log(10)).floor() + 1;
    }
    
    // Define already used thresholds based on networkWorth
    // networkWorth tracks the accumulated prestige levels
    int alreadyUsedThresholds = 0;
    if (networkWorth > 0) {
      // For the $1M threshold, check if we've used it at all
      if (networkWorth >= 0.01) { // 0.01 = 1/100 (the first threshold)
        alreadyUsedThresholds++;
      }
      
      // For the $10M threshold
      if (networkWorth >= 0.1) { // 0.1 = 10/100 (the second threshold)
        alreadyUsedThresholds++;
      }
      
      // For the $100M threshold
      if (networkWorth >= 1.0) { // 1.0 = 100/100 (the third threshold)
        alreadyUsedThresholds++;
      }
      
      // For the $1B threshold
      if (networkWorth >= 10.0) { // 10.0 = 1000/100 (the fourth threshold)
        alreadyUsedThresholds++;
      }
      
      // For the $10B threshold
      if (networkWorth >= 100.0) { // 100.0 = 10000/100 (the fifth threshold)
        alreadyUsedThresholds++;
      }
      
      // For the $100B threshold
      if (networkWorth >= 1000.0) { // 1000.0 = 100000/100 (the sixth threshold)
        alreadyUsedThresholds++;
      }
      
      // For the $1T threshold
      if (networkWorth >= 10000.0) { // 10000.0 = 1000000/100 (the seventh threshold)
        alreadyUsedThresholds++;
      }
      
      // For the $10T threshold
      if (networkWorth >= 100000.0) { // 100000.0 = 10000000/100 (the eighth threshold)
        alreadyUsedThresholds++;
      }
      
      // For the $100T threshold
      if (networkWorth >= 1000000.0) { // 1000000.0 = 100000000/100 (the ninth threshold)
        alreadyUsedThresholds++;
      }
    }
    
    // Available uses is the difference between total thresholds crossed
    // and the thresholds already used for prestige
    int newAvailableUses = max(0, totalThresholdsCrossed - alreadyUsedThresholds);
    
    // Always update to reflect the current state
    reincorporationUsesAvailable = newAvailableUses;
    notifyListeners();
  }
  
  // Initialize real estate locales and properties
  void _initializeRealEstateLocales() {
    realEstateLocales = [
      // 1. Rural Kenya
      RealEstateLocale(
        id: 'rural_kenya',
        name: 'Rural Kenya',
        theme: 'Traditional and rural African homes',
        unlocked: true, // Always unlocked from the start
        icon: Icons.cabin,
        properties: [
          RealEstateProperty(
            id: 'mud_hut',
            name: 'Mud Hut',
            purchasePrice: 500.0,
            baseCashFlowPerSecond: 0.5 * 1.15, // +15%
          ),
          RealEstateProperty(
            id: 'thatched_cottage',
            name: 'Thatched Cottage',
            purchasePrice: 1000.0,
            baseCashFlowPerSecond: 1.0 * 1.25, // +25%
          ),
          RealEstateProperty(
            id: 'brick_shack',
            name: 'Brick Shack',
            purchasePrice: 2500.0,
            baseCashFlowPerSecond: 2.5 * 1.35, // +35%
          ),
          RealEstateProperty(
            id: 'solar_powered_hut',
            name: 'Solar-Powered Hut',
            purchasePrice: 5000.0,
            baseCashFlowPerSecond: 5.0 * 1.45, // +45%
          ),
          RealEstateProperty(
            id: 'village_compound',
            name: 'Village Compound',
            purchasePrice: 10000.0,
            baseCashFlowPerSecond: 10.0 * 1.55, // +55%
          ),
          RealEstateProperty(
            id: 'eco_lodge',
            name: 'Eco-Lodge',
            purchasePrice: 25000.0,
            baseCashFlowPerSecond: 25.0 * 1.65, // +65%
          ),
          RealEstateProperty(
            id: 'farmhouse',
            name: 'Farmhouse',
            purchasePrice: 50000.0,
            baseCashFlowPerSecond: 50.0 * 1.75, // +75%
          ),
          RealEstateProperty(
            id: 'safari_retreat',
            name: 'Safari Retreat',
            purchasePrice: 100000.0,
            baseCashFlowPerSecond: 100.0 * 1.85, // +85%
          ),
          RealEstateProperty(
            id: 'rural_estate',
            name: 'Rural Estate',
            purchasePrice: 250000.0,
            baseCashFlowPerSecond: 250.0 * 1.95, // +95%
          ),
          RealEstateProperty(
            id: 'conservation_villa',
            name: 'Conservation Villa',
            purchasePrice: 500000.0,
            baseCashFlowPerSecond: 500.0 * 2.05, // +105%
          ),
        ],
      ),
      
      // 2. Lagos, Nigeria
      RealEstateLocale(
        id: 'lagos_nigeria',
        name: 'Lagos, Nigeria',
        theme: 'Urban growth and modern apartments',
        unlocked: false,
        icon: Icons.apartment,
        properties: [
          RealEstateProperty(
            id: 'tin_roof_shack',
            name: 'Tin-Roof Shack',
            purchasePrice: 1000.0,
            baseCashFlowPerSecond: 1.0 * 1.15, // +15%
          ),
          RealEstateProperty(
            id: 'concrete_flat',
            name: 'Concrete Flat',
            purchasePrice: 2000.0,
            baseCashFlowPerSecond: 2.0 * 1.25, // +25%
          ),
          RealEstateProperty(
            id: 'small_apartment',
            name: 'Small Apartment',
            purchasePrice: 5000.0,
            baseCashFlowPerSecond: 5.0 * 1.35, // +35%
          ),
          RealEstateProperty(
            id: 'duplex',
            name: 'Duplex',
            purchasePrice: 10000.0,
            baseCashFlowPerSecond: 10.0 * 1.45, // +45%
          ),
          RealEstateProperty(
            id: 'mid_rise_block',
            name: 'Mid-Rise Block',
            purchasePrice: 25000.0,
            baseCashFlowPerSecond: 25.0 * 1.55, // +55%
          ),
          RealEstateProperty(
            id: 'gated_complex',
            name: 'Gated Complex',
            purchasePrice: 50000.0,
            baseCashFlowPerSecond: 50.0 * 1.65, // +65%
          ),
          RealEstateProperty(
            id: 'high_rise_tower',
            name: 'High-Rise Tower',
            purchasePrice: 100000.0,
            baseCashFlowPerSecond: 100.0 * 1.75, // +75%
          ),
          RealEstateProperty(
            id: 'luxury_condo',
            name: 'Luxury Condo',
            purchasePrice: 250000.0,
            baseCashFlowPerSecond: 250.0 * 1.85, // +85%
          ),
          RealEstateProperty(
            id: 'business_loft',
            name: 'Business Loft',
            purchasePrice: 500000.0,
            baseCashFlowPerSecond: 500.0 * 1.95, // +95%
          ),
          RealEstateProperty(
            id: 'skyline_penthouse',
            name: 'Skyline Penthouse',
            purchasePrice: 1000000.0,
            baseCashFlowPerSecond: 1000.0 * 2.05, // +105%
          ),
        ],
      ),
      
      // 3. Cape Town, South Africa
      RealEstateLocale(
        id: 'cape_town_sa',
        name: 'Cape Town, South Africa',
        theme: 'Coastal and scenic properties',
        unlocked: false,
        icon: Icons.beach_access,
        properties: [
          RealEstateProperty(
            id: 'beach_shack',
            name: 'Beach Shack',
            purchasePrice: 5000.0,
            baseCashFlowPerSecond: 5.0 * 1.15, // +15%
          ),
          RealEstateProperty(
            id: 'wooden_bungalow',
            name: 'Wooden Bungalow',
            purchasePrice: 10000.0,
            baseCashFlowPerSecond: 10.0 * 1.25, // +25%
          ),
          RealEstateProperty(
            id: 'cliffside_cottage',
            name: 'Cliffside Cottage',
            purchasePrice: 25000.0,
            baseCashFlowPerSecond: 25.0 * 1.35, // +35%
          ),
          RealEstateProperty(
            id: 'seaview_villa',
            name: 'Seaview Villa',
            purchasePrice: 50000.0,
            baseCashFlowPerSecond: 50.0 * 1.45, // +45%
          ),
          RealEstateProperty(
            id: 'modern_beach_house',
            name: 'Modern Beach House',
            purchasePrice: 100000.0,
            baseCashFlowPerSecond: 100.0 * 1.55, // +55%
          ),
          RealEstateProperty(
            id: 'coastal_estate',
            name: 'Coastal Estate',
            purchasePrice: 250000.0,
            baseCashFlowPerSecond: 250.0 * 1.65, // +65%
          ),
          RealEstateProperty(
            id: 'luxury_retreat',
            name: 'Luxury Retreat',
            purchasePrice: 500000.0,
            baseCashFlowPerSecond: 500.0 * 1.75, // +75%
          ),
          RealEstateProperty(
            id: 'oceanfront_mansion',
            name: 'Oceanfront Mansion',
            purchasePrice: 1000000.0,
            baseCashFlowPerSecond: 1000.0 * 1.85, // +85%
          ),
          RealEstateProperty(
            id: 'vineyard_manor',
            name: 'Vineyard Manor',
            purchasePrice: 2500000.0,
            baseCashFlowPerSecond: 2500.0 * 1.95, // +95%
          ),
          RealEstateProperty(
            id: 'cape_peninsula_chateau',
            name: 'Cape Peninsula Chateau',
            purchasePrice: 5000000.0,
            baseCashFlowPerSecond: 5000.0 * 2.05, // +105%
          ),
        ],
      ),

      // 4. Rural Thailand
      RealEstateLocale(
        id: 'rural_thailand',
        name: 'Rural Thailand',
        theme: 'Tropical and bamboo-based homes',
        unlocked: false,
        icon: Icons.holiday_village,
        properties: [
          RealEstateProperty(
            id: 'bamboo_hut',
            name: 'Bamboo Hut',
            purchasePrice: 750.0,
            baseCashFlowPerSecond: 0.75 * 1.15, // +15%
          ),
          RealEstateProperty(
            id: 'stilt_house',
            name: 'Stilt House',
            purchasePrice: 1500.0,
            baseCashFlowPerSecond: 1.5 * 1.25, // +25%
          ),
          RealEstateProperty(
            id: 'teak_cabin',
            name: 'Teak Cabin',
            purchasePrice: 3000.0,
            baseCashFlowPerSecond: 3.0 * 1.35, // +35%
          ),
          RealEstateProperty(
            id: 'rice_farmhouse',
            name: 'Rice Farmhouse',
            purchasePrice: 7500.0,
            baseCashFlowPerSecond: 7.5 * 1.45, // +45%
          ),
          RealEstateProperty(
            id: 'jungle_bungalow',
            name: 'Jungle Bungalow',
            purchasePrice: 15000.0,
            baseCashFlowPerSecond: 15.0 * 1.55, // +55%
          ),
          RealEstateProperty(
            id: 'riverside_villa',
            name: 'Riverside Villa',
            purchasePrice: 30000.0,
            baseCashFlowPerSecond: 30.0 * 1.65, // +65%
          ),
          RealEstateProperty(
            id: 'eco_resort',
            name: 'Eco-Resort',
            purchasePrice: 75000.0,
            baseCashFlowPerSecond: 75.0 * 1.75, // +75%
          ),
          RealEstateProperty(
            id: 'hilltop_retreat',
            name: 'Hilltop Retreat',
            purchasePrice: 150000.0,
            baseCashFlowPerSecond: 150.0 * 1.85, // +85%
          ),
          RealEstateProperty(
            id: 'teak_mansion',
            name: 'Teak Mansion',
            purchasePrice: 300000.0,
            baseCashFlowPerSecond: 300.0 * 1.95, // +95%
          ),
          RealEstateProperty(
            id: 'tropical_estate',
            name: 'Tropical Estate',
            purchasePrice: 750000.0,
            baseCashFlowPerSecond: 750.0 * 2.05, // +105%
          ),
        ],
      ),
      
      // 5. Mumbai, India
      RealEstateLocale(
        id: 'mumbai_india',
        name: 'Mumbai, India',
        theme: 'Dense urban housing with cultural flair',
        unlocked: false,
        icon: Icons.location_city,
        properties: [
          RealEstateProperty(
            id: 'slum_tenement',
            name: 'Slum Tenement',
            purchasePrice: 2000.0,
            baseCashFlowPerSecond: 2.0 * 1.15, // +15%
          ),
          RealEstateProperty(
            id: 'concrete_flat_mumbai',
            name: 'Concrete Flat',
            purchasePrice: 4000.0,
            baseCashFlowPerSecond: 4.0 * 1.25, // +25%
          ),
          RealEstateProperty(
            id: 'small_apartment_mumbai',
            name: 'Small Apartment',
            purchasePrice: 10000.0,
            baseCashFlowPerSecond: 10.0 * 1.35, // +35%
          ),
          RealEstateProperty(
            id: 'mid_tier_condo',
            name: 'Mid-Tier Condo',
            purchasePrice: 20000.0,
            baseCashFlowPerSecond: 20.0 * 1.45, // +45%
          ),
          RealEstateProperty(
            id: 'bollywood_loft',
            name: 'Bollywood Loft',
            purchasePrice: 50000.0,
            baseCashFlowPerSecond: 50.0 * 1.55, // +55%
          ),
          RealEstateProperty(
            id: 'high_rise_unit_mumbai',
            name: 'High-Rise Unit',
            purchasePrice: 100000.0,
            baseCashFlowPerSecond: 100.0 * 1.65, // +65%
          ),
          RealEstateProperty(
            id: 'gated_tower',
            name: 'Gated Tower',
            purchasePrice: 250000.0,
            baseCashFlowPerSecond: 250.0 * 1.75, // +75%
          ),
          RealEstateProperty(
            id: 'luxury_flat_mumbai',
            name: 'Luxury Flat',
            purchasePrice: 500000.0,
            baseCashFlowPerSecond: 500.0 * 1.85, // +85%
          ),
          RealEstateProperty(
            id: 'seafront_penthouse',
            name: 'Seafront Penthouse',
            purchasePrice: 1000000.0,
            baseCashFlowPerSecond: 1000.0 * 1.95, // +95%
          ),
          RealEstateProperty(
            id: 'mumbai_skyscraper',
            name: 'Mumbai Skyscraper',
            purchasePrice: 2000000.0,
            baseCashFlowPerSecond: 2000.0 * 2.05, // +105%
          ),
        ],
      ),
      
      // 6. Ho Chi Minh City, Vietnam
      RealEstateLocale(
        id: 'ho_chi_minh_city',
        name: 'Ho Chi Minh City, Vietnam',
        theme: 'Emerging urban and riverfront homes',
        unlocked: false,
        icon: Icons.house_siding,
        properties: [
          RealEstateProperty(
            id: 'shophouse',
            name: 'Shophouse',
            purchasePrice: 3000.0,
            baseCashFlowPerSecond: 3.0 * 1.15, // +15%
          ),
          RealEstateProperty(
            id: 'narrow_flat',
            name: 'Narrow Flat',
            purchasePrice: 6000.0,
            baseCashFlowPerSecond: 6.0 * 1.25, // +25%
          ),
          RealEstateProperty(
            id: 'riverside_hut',
            name: 'Riverside Hut',
            purchasePrice: 15000.0,
            baseCashFlowPerSecond: 15.0 * 1.35, // +35%
          ),
          RealEstateProperty(
            id: 'modern_apartment_hcmc',
            name: 'Modern Apartment',
            purchasePrice: 30000.0,
            baseCashFlowPerSecond: 30.0 * 1.45, // +45%
          ),
          RealEstateProperty(
            id: 'condo_unit_hcmc',
            name: 'Condo Unit',
            purchasePrice: 75000.0,
            baseCashFlowPerSecond: 75.0 * 1.55, // +55%
          ),
          RealEstateProperty(
            id: 'riverfront_villa',
            name: 'Riverfront Villa',
            purchasePrice: 150000.0,
            baseCashFlowPerSecond: 150.0 * 1.65, // +65%
          ),
          RealEstateProperty(
            id: 'high_rise_suite_hcmc',
            name: 'High-Rise Suite',
            purchasePrice: 300000.0,
            baseCashFlowPerSecond: 300.0 * 1.75, // +75%
          ),
          RealEstateProperty(
            id: 'luxury_tower_hcmc',
            name: 'Luxury Tower',
            purchasePrice: 750000.0,
            baseCashFlowPerSecond: 750.0 * 1.85, // +85%
          ),
          RealEstateProperty(
            id: 'business_loft_hcmc',
            name: 'Business Loft',
            purchasePrice: 1500000.0,
            baseCashFlowPerSecond: 1500.0 * 1.95, // +95%
          ),
          RealEstateProperty(
            id: 'saigon_skyline_estate',
            name: 'Saigon Skyline Estate',
            purchasePrice: 3000000.0,
            baseCashFlowPerSecond: 3000.0 * 2.05, // +105%
          ),
        ],
      ),
      
      // 7. Singapore
      RealEstateLocale(
        id: 'singapore',
        name: 'Singapore',
        theme: 'Ultra-modern, high-density urban living',
        unlocked: false,
        icon: Icons.apartment,
        properties: [
          RealEstateProperty(
            id: 'hdb_flat',
            name: 'HDB Flat',
            purchasePrice: 50000.0,
            baseCashFlowPerSecond: 50.0 * 1.15, // +15%
          ),
          RealEstateProperty(
            id: 'condo_unit_singapore',
            name: 'Condo Unit',
            purchasePrice: 100000.0,
            baseCashFlowPerSecond: 100.0 * 1.25, // +25%
          ),
          RealEstateProperty(
            id: 'executive_apartment',
            name: 'Executive Apartment',
            purchasePrice: 250000.0,
            baseCashFlowPerSecond: 250.0 * 1.35, // +35%
          ),
          RealEstateProperty(
            id: 'sky_terrace',
            name: 'Sky Terrace',
            purchasePrice: 500000.0,
            baseCashFlowPerSecond: 500.0 * 1.45, // +45%
          ),
          RealEstateProperty(
            id: 'luxury_condo_singapore',
            name: 'Luxury Condo',
            purchasePrice: 1000000.0,
            baseCashFlowPerSecond: 1000.0 * 1.55, // +55%
          ),
          RealEstateProperty(
            id: 'marina_view_suite',
            name: 'Marina View Suite',
            purchasePrice: 2500000.0,
            baseCashFlowPerSecond: 2500.0 * 1.65, // +65%
          ),
          RealEstateProperty(
            id: 'penthouse_tower_singapore',
            name: 'Penthouse Tower',
            purchasePrice: 5000000.0,
            baseCashFlowPerSecond: 5000.0 * 1.75, // +75%
          ),
          RealEstateProperty(
            id: 'sky_villa',
            name: 'Sky Villa',
            purchasePrice: 10000000.0,
            baseCashFlowPerSecond: 10000.0 * 1.85, // +85%
          ),
          RealEstateProperty(
            id: 'billionaire_loft_singapore',
            name: 'Billionaire Loft',
            purchasePrice: 25000000.0,
            baseCashFlowPerSecond: 25000.0 * 1.95, // +95%
          ),
          RealEstateProperty(
            id: 'iconic_skyscraper_singapore',
            name: 'Iconic Skyscraper',
            purchasePrice: 50000000.0,
            baseCashFlowPerSecond: 50000.0 * 2.05, // +105%
          ),
        ],
      ),
      
      // 8. Hong Kong
      RealEstateLocale(
        id: 'hong_kong',
        name: 'Hong Kong',
        theme: 'Compact, premium urban properties',
        unlocked: false,
        icon: Icons.location_city,
        properties: [
          RealEstateProperty(
            id: 'micro_flat',
            name: 'Micro-Flat',
            purchasePrice: 75000.0,
            baseCashFlowPerSecond: 75.0 * 1.15, // +15%
          ),
          RealEstateProperty(
            id: 'small_apartment_hk',
            name: 'Small Apartment',
            purchasePrice: 150000.0,
            baseCashFlowPerSecond: 150.0 * 1.25, // +25%
          ),
          RealEstateProperty(
            id: 'mid_rise_unit',
            name: 'Mid-Rise Unit',
            purchasePrice: 300000.0,
            baseCashFlowPerSecond: 300.0 * 1.35, // +35%
          ),
          RealEstateProperty(
            id: 'harbor_view_flat',
            name: 'Harbor View Flat',
            purchasePrice: 750000.0,
            baseCashFlowPerSecond: 750.0 * 1.45, // +45%
          ),
          RealEstateProperty(
            id: 'luxury_condo_hk',
            name: 'Luxury Condo',
            purchasePrice: 1500000.0,
            baseCashFlowPerSecond: 1500.0 * 1.55, // +55%
          ),
          RealEstateProperty(
            id: 'peak_villa',
            name: 'Peak Villa',
            purchasePrice: 3000000.0,
            baseCashFlowPerSecond: 3000.0 * 1.65, // +65%
          ),
          RealEstateProperty(
            id: 'skyline_suite_hk',
            name: 'Skyline Suite',
            purchasePrice: 7500000.0,
            baseCashFlowPerSecond: 7500.0 * 1.75, // +75%
          ),
          RealEstateProperty(
            id: 'penthouse_tower_hk',
            name: 'Penthouse Tower',
            purchasePrice: 15000000.0,
            baseCashFlowPerSecond: 15000.0 * 1.85, // +85%
          ),
          RealEstateProperty(
            id: 'billionaire_mansion',
            name: 'Billionaire Mansion',
            purchasePrice: 30000000.0,
            baseCashFlowPerSecond: 30000.0 * 1.95, // +95%
          ),
          RealEstateProperty(
            id: 'victoria_peak_estate',
            name: 'Victoria Peak Estate',
            purchasePrice: 75000000.0,
            baseCashFlowPerSecond: 75000.0 * 2.05, // +105%
          ),
        ],
      ),
      
      // 9. Lisbon, Portugal
      RealEstateLocale(
        id: 'lisbon_portugal',
        name: 'Lisbon, Portugal',
        theme: 'Historic and coastal European homes',
        unlocked: false,
        icon: Icons.villa,
        properties: [
          RealEstateProperty(
            id: 'stone_cottage',
            name: 'Stone Cottage',
            purchasePrice: 10000.0,
            baseCashFlowPerSecond: 10.0 * 1.15, // +15%
          ),
          RealEstateProperty(
            id: 'townhouse',
            name: 'Townhouse',
            purchasePrice: 20000.0,
            baseCashFlowPerSecond: 20.0 * 1.25, // +25%
          ),
          RealEstateProperty(
            id: 'riverside_flat',
            name: 'Riverside Flat',
            purchasePrice: 50000.0,
            baseCashFlowPerSecond: 50.0 * 1.35, // +35%
          ),
          RealEstateProperty(
            id: 'renovated_villa',
            name: 'Renovated Villa',
            purchasePrice: 100000.0,
            baseCashFlowPerSecond: 100.0 * 1.45, // +45%
          ),
          RealEstateProperty(
            id: 'coastal_bungalow',
            name: 'Coastal Bungalow',
            purchasePrice: 250000.0,
            baseCashFlowPerSecond: 250.0 * 1.55, // +55%
          ),
          RealEstateProperty(
            id: 'luxury_apartment_lisbon',
            name: 'Luxury Apartment',
            purchasePrice: 500000.0,
            baseCashFlowPerSecond: 500.0 * 1.65, // +65%
          ),
          RealEstateProperty(
            id: 'historic_manor',
            name: 'Historic Manor',
            purchasePrice: 1000000.0,
            baseCashFlowPerSecond: 1000.0 * 1.75, // +75%
          ),
          RealEstateProperty(
            id: 'seaside_mansion',
            name: 'Seaside Mansion',
            purchasePrice: 2500000.0,
            baseCashFlowPerSecond: 2500.0 * 1.85, // +85%
          ),
          RealEstateProperty(
            id: 'cliffside_estate',
            name: 'Cliffside Estate',
            purchasePrice: 5000000.0,
            baseCashFlowPerSecond: 5000.0 * 1.95, // +95%
          ),
          RealEstateProperty(
            id: 'lisbon_palace',
            name: 'Lisbon Palace',
            purchasePrice: 10000000.0,
            baseCashFlowPerSecond: 10000.0 * 2.05, // +105%
          ),
        ],
      ),
      
      // 10. Bucharest, Romania
      RealEstateLocale(
        id: 'bucharest_romania',
        name: 'Bucharest, Romania',
        theme: 'Affordable Eastern European urban growth',
        unlocked: false,
        icon: Icons.apartment,
        properties: [
          RealEstateProperty(
            id: 'panel_flat',
            name: 'Panel Flat',
            purchasePrice: 7500.0,
            baseCashFlowPerSecond: 7.5 * 1.15, // +15%
          ),
          RealEstateProperty(
            id: 'brick_apartment',
            name: 'Brick Apartment',
            purchasePrice: 15000.0,
            baseCashFlowPerSecond: 15.0 * 1.25, // +25%
          ),
          RealEstateProperty(
            id: 'modern_condo_bucharest',
            name: 'Modern Condo',
            purchasePrice: 30000.0,
            baseCashFlowPerSecond: 30.0 * 1.35, // +35%
          ),
          RealEstateProperty(
            id: 'renovated_loft',
            name: 'Renovated Loft',
            purchasePrice: 75000.0,
            baseCashFlowPerSecond: 75.0 * 1.45, // +45%
          ),
          RealEstateProperty(
            id: 'gated_unit',
            name: 'Gated Unit',
            purchasePrice: 150000.0,
            baseCashFlowPerSecond: 150.0 * 1.55, // +55%
          ),
          RealEstateProperty(
            id: 'high_rise_suite_bucharest',
            name: 'High-Rise Suite',
            purchasePrice: 300000.0,
            baseCashFlowPerSecond: 300.0 * 1.65, // +65%
          ),
          RealEstateProperty(
            id: 'luxury_flat_bucharest',
            name: 'Luxury Flat',
            purchasePrice: 750000.0,
            baseCashFlowPerSecond: 750.0 * 1.75, // +75%
          ),
          RealEstateProperty(
            id: 'urban_villa',
            name: 'Urban Villa',
            purchasePrice: 1500000.0,
            baseCashFlowPerSecond: 1500.0 * 1.85, // +85%
          ),
          RealEstateProperty(
            id: 'city_penthouse',
            name: 'City Penthouse',
            purchasePrice: 3000000.0,
            baseCashFlowPerSecond: 3000.0 * 1.95, // +95%
          ),
          RealEstateProperty(
            id: 'bucharest_tower',
            name: 'Bucharest Tower',
            purchasePrice: 7500000.0,
            baseCashFlowPerSecond: 7500.0 * 2.05, // +105%
          ),
        ],
      ),
      
      // 11. Berlin, Germany
      RealEstateLocale(
        id: 'berlin_germany',
        name: 'Berlin, Germany',
        theme: 'Creative and industrial-chic properties',
        unlocked: false,
        icon: Icons.house_siding,
        properties: [
          RealEstateProperty(
            id: 'studio_flat',
            name: 'Studio Flat',
            purchasePrice: 25000.0,
            baseCashFlowPerSecond: 25.0 * 1.15, // +15%
          ),
          RealEstateProperty(
            id: 'loft_space',
            name: 'Loft Space',
            purchasePrice: 50000.0,
            baseCashFlowPerSecond: 50.0 * 1.25, // +25%
          ),
          RealEstateProperty(
            id: 'renovated_warehouse',
            name: 'Renovated Warehouse',
            purchasePrice: 100000.0,
            baseCashFlowPerSecond: 100.0 * 1.35, // +35%
          ),
          RealEstateProperty(
            id: 'modern_apartment_berlin',
            name: 'Modern Apartment',
            purchasePrice: 250000.0,
            baseCashFlowPerSecond: 250.0 * 1.45, // +45%
          ),
          RealEstateProperty(
            id: 'artist_condo',
            name: 'Artist Condo',
            purchasePrice: 500000.0,
            baseCashFlowPerSecond: 500.0 * 1.55, // +55%
          ),
          RealEstateProperty(
            id: 'riverfront_suite',
            name: 'Riverfront Suite',
            purchasePrice: 1000000.0,
            baseCashFlowPerSecond: 1000.0 * 1.65, // +65%
          ),
          RealEstateProperty(
            id: 'luxury_loft',
            name: 'Luxury Loft',
            purchasePrice: 2500000.0,
            baseCashFlowPerSecond: 2500.0 * 1.75, // +75%
          ),
          RealEstateProperty(
            id: 'high_rise_tower_berlin',
            name: 'High-Rise Tower',
            purchasePrice: 5000000.0,
            baseCashFlowPerSecond: 5000.0 * 1.85, // +85%
          ),
          RealEstateProperty(
            id: 'tech_villa',
            name: 'Tech Villa',
            purchasePrice: 10000000.0,
            baseCashFlowPerSecond: 10000.0 * 1.95, // +95%
          ),
          RealEstateProperty(
            id: 'berlin_skyline_estate',
            name: 'Berlin Skyline Estate',
            purchasePrice: 25000000.0,
            baseCashFlowPerSecond: 25000.0 * 2.05, // +105%
          ),
        ],
      ),
      
      // 12. London, UK
      RealEstateLocale(
        id: 'london_uk',
        name: 'London, UK',
        theme: 'Historic and ultra-premium urban homes',
        unlocked: false,
        icon: Icons.location_city,
        properties: [
          RealEstateProperty(
            id: 'council_flat',
            name: 'Council Flat',
            purchasePrice: 40000.0,
            baseCashFlowPerSecond: 40.0 * 1.15, // +15%
          ),
          RealEstateProperty(
            id: 'terraced_house',
            name: 'Terraced House',
            purchasePrice: 80000.0,
            baseCashFlowPerSecond: 80.0 * 1.25, // +25%
          ),
          RealEstateProperty(
            id: 'georgian_townhouse',
            name: 'Georgian Townhouse',
            purchasePrice: 200000.0,
            baseCashFlowPerSecond: 200.0 * 1.35, // +35%
          ),
          RealEstateProperty(
            id: 'modern_condo_london',
            name: 'Modern Condo',
            purchasePrice: 400000.0,
            baseCashFlowPerSecond: 400.0 * 1.45, // +45%
          ),
          RealEstateProperty(
            id: 'riverside_apartment',
            name: 'Riverside Apartment',
            purchasePrice: 1000000.0,
            baseCashFlowPerSecond: 1000.0 * 1.55, // +55%
          ),
          RealEstateProperty(
            id: 'luxury_flat_london',
            name: 'Luxury Flat',
            purchasePrice: 2000000.0,
            baseCashFlowPerSecond: 2000.0 * 1.65, // +65%
          ),
          RealEstateProperty(
            id: 'mayfair_mansion',
            name: 'Mayfair Mansion',
            purchasePrice: 5000000.0,
            baseCashFlowPerSecond: 5000.0 * 1.75, // +75%
          ),
          RealEstateProperty(
            id: 'skyline_penthouse_london',
            name: 'Skyline Penthouse',
            purchasePrice: 10000000.0,
            baseCashFlowPerSecond: 10000.0 * 1.85, // +85%
          ),
          RealEstateProperty(
            id: 'historic_estate',
            name: 'Historic Estate',
            purchasePrice: 25000000.0,
            baseCashFlowPerSecond: 25000.0 * 1.95, // +95%
          ),
          RealEstateProperty(
            id: 'london_iconic_tower',
            name: 'London Iconic Tower',
            purchasePrice: 50000000.0,
            baseCashFlowPerSecond: 50000.0 * 2.05, // +105%
          ),
        ],
      ),
      
      // 13. Rural Mexico
      RealEstateLocale(
        id: 'rural_mexico',
        name: 'Rural Mexico',
        theme: 'Rustic and affordable Latin American homes',
        unlocked: false,
        icon: Icons.holiday_village,
        properties: [
          RealEstateProperty(
            id: 'adobe_hut',
            name: 'Adobe Hut',
            purchasePrice: 600.0,
            baseCashFlowPerSecond: 0.6 * 1.15, // +15%
          ),
          RealEstateProperty(
            id: 'clay_house',
            name: 'Clay House',
            purchasePrice: 1200.0,
            baseCashFlowPerSecond: 1.2 * 1.25, // +25%
          ),
          RealEstateProperty(
            id: 'brick_cottage_mexico',
            name: 'Brick Cottage',
            purchasePrice: 3000.0,
            baseCashFlowPerSecond: 3.0 * 1.35, // +35%
          ),
          RealEstateProperty(
            id: 'hacienda_bungalow',
            name: 'Hacienda Bungalow',
            purchasePrice: 6000.0,
            baseCashFlowPerSecond: 6.0 * 1.45, // +45%
          ),
          RealEstateProperty(
            id: 'village_flat',
            name: 'Village Flat',
            purchasePrice: 15000.0,
            baseCashFlowPerSecond: 15.0 * 1.55, // +55%
          ),
          RealEstateProperty(
            id: 'rural_villa',
            name: 'Rural Villa',
            purchasePrice: 30000.0,
            baseCashFlowPerSecond: 30.0 * 1.65, // +65%
          ),
          RealEstateProperty(
            id: 'eco_casa',
            name: 'Eco-Casa',
            purchasePrice: 75000.0,
            baseCashFlowPerSecond: 75.0 * 1.75, // +75%
          ),
          RealEstateProperty(
            id: 'farmstead',
            name: 'Farmstead',
            purchasePrice: 150000.0,
            baseCashFlowPerSecond: 150.0 * 1.85, // +85%
          ),
          RealEstateProperty(
            id: 'countryside_estate',
            name: 'Countryside Estate',
            purchasePrice: 300000.0,
            baseCashFlowPerSecond: 300.0 * 1.95, // +95%
          ),
          RealEstateProperty(
            id: 'hacienda_grande',
            name: 'Hacienda Grande',
            purchasePrice: 600000.0,
            baseCashFlowPerSecond: 600.0 * 2.05, // +105%
          ),
        ],
      ),
      
      // 14. Mexico City, Mexico
      RealEstateLocale(
        id: 'mexico_city',
        name: 'Mexico City, Mexico',
        theme: 'Urban sprawl with colonial charm',
        unlocked: false,
        icon: Icons.location_city,
        properties: [
          RealEstateProperty(
            id: 'barrio_flat',
            name: 'Barrio Flat',
            purchasePrice: 4000.0,
            baseCashFlowPerSecond: 4.0 * 1.15, // +15%
          ),
          RealEstateProperty(
            id: 'concrete_unit_mexico',
            name: 'Concrete Unit',
            purchasePrice: 8000.0,
            baseCashFlowPerSecond: 8.0 * 1.25, // +25%
          ),
          RealEstateProperty(
            id: 'colonial_house',
            name: 'Colonial House',
            purchasePrice: 20000.0,
            baseCashFlowPerSecond: 20.0 * 1.35, // +35%
          ),
          RealEstateProperty(
            id: 'mid_rise_apartment',
            name: 'Mid-Rise Apartment',
            purchasePrice: 40000.0,
            baseCashFlowPerSecond: 40.0 * 1.45, // +45%
          ),
          RealEstateProperty(
            id: 'gated_condo',
            name: 'Gated Condo',
            purchasePrice: 100000.0,
            baseCashFlowPerSecond: 100.0 * 1.55, // +55%
          ),
          RealEstateProperty(
            id: 'modern_loft_mexico',
            name: 'Modern Loft',
            purchasePrice: 200000.0,
            baseCashFlowPerSecond: 200.0 * 1.65, // +65%
          ),
          RealEstateProperty(
            id: 'luxury_suite_mexico',
            name: 'Luxury Suite',
            purchasePrice: 500000.0,
            baseCashFlowPerSecond: 500.0 * 1.75, // +75%
          ),
          RealEstateProperty(
            id: 'high_rise_tower_mexico',
            name: 'High-Rise Tower',
            purchasePrice: 1000000.0,
            baseCashFlowPerSecond: 1000.0 * 1.85, // +85%
          ),
          RealEstateProperty(
            id: 'historic_penthouse',
            name: 'Historic Penthouse',
            purchasePrice: 2000000.0,
            baseCashFlowPerSecond: 2000.0 * 1.95, // +95%
          ),
          RealEstateProperty(
            id: 'mexico_city_skyline',
            name: 'Mexico City Skyline',
            purchasePrice: 4000000.0,
            baseCashFlowPerSecond: 4000.0 * 2.05, // +105%
          ),
        ],
      ),
      
      // 15. Miami, Florida
      RealEstateLocale(
        id: 'miami_florida',
        name: 'Miami, Florida',
        theme: 'Coastal and flashy U.S. properties',
        unlocked: false,
        icon: Icons.beach_access,
        properties: [
          RealEstateProperty(
            id: 'beach_condo',
            name: 'Beach Condo',
            purchasePrice: 30000.0,
            baseCashFlowPerSecond: 30.0 * 1.15, // +15%
          ),
          RealEstateProperty(
            id: 'bungalow',
            name: 'Bungalow',
            purchasePrice: 60000.0,
            baseCashFlowPerSecond: 60.0 * 1.25, // +25%
          ),
          RealEstateProperty(
            id: 'oceanfront_flat',
            name: 'Oceanfront Flat',
            purchasePrice: 150000.0,
            baseCashFlowPerSecond: 150.0 * 1.35, // +35%
          ),
          RealEstateProperty(
            id: 'modern_villa_miami',
            name: 'Modern Villa',
            purchasePrice: 300000.0,
            baseCashFlowPerSecond: 300.0 * 1.45, // +45%
          ),
          RealEstateProperty(
            id: 'luxury_condo_miami',
            name: 'Luxury Condo',
            purchasePrice: 750000.0,
            baseCashFlowPerSecond: 750.0 * 1.55, // +55%
          ),
          RealEstateProperty(
            id: 'miami_beach_house',
            name: 'Miami Beach House',
            purchasePrice: 1500000.0,
            baseCashFlowPerSecond: 1500.0 * 1.65, // +65%
          ),
          RealEstateProperty(
            id: 'high_rise_suite_miami',
            name: 'High-Rise Suite',
            purchasePrice: 3000000.0,
            baseCashFlowPerSecond: 3000.0 * 1.75, // +75%
          ),
          RealEstateProperty(
            id: 'skyline_penthouse_miami',
            name: 'Skyline Penthouse',
            purchasePrice: 7500000.0,
            baseCashFlowPerSecond: 7500.0 * 1.85, // +85%
          ),
          RealEstateProperty(
            id: 'waterfront_mansion',
            name: 'Waterfront Mansion',
            purchasePrice: 15000000.0,
            baseCashFlowPerSecond: 15000.0 * 1.95, // +95%
          ),
          RealEstateProperty(
            id: 'miami_iconic_estate',
            name: 'Miami Iconic Estate',
            purchasePrice: 30000000.0,
            baseCashFlowPerSecond: 30000.0 * 2.05, // +105%
          ),
        ],
      ),
      
      // 16. New York City, NY
      RealEstateLocale(
        id: 'new_york_city',
        name: 'New York City, NY',
        theme: 'Iconic U.S. urban real estate',
        unlocked: false,
        icon: Icons.location_city,
        properties: [
          RealEstateProperty(
            id: 'studio_apartment',
            name: 'Studio Apartment',
            purchasePrice: 60000.0,
            baseCashFlowPerSecond: 60.0 * 1.15, // +15%
          ),
          RealEstateProperty(
            id: 'brownstone_flat',
            name: 'Brownstone Flat',
            purchasePrice: 120000.0,
            baseCashFlowPerSecond: 120.0 * 1.25, // +25%
          ),
          RealEstateProperty(
            id: 'midtown_condo',
            name: 'Midtown Condo',
            purchasePrice: 300000.0,
            baseCashFlowPerSecond: 300.0 * 1.35, // +35%
          ),
          RealEstateProperty(
            id: 'luxury_loft_nyc',
            name: 'Luxury Loft',
            purchasePrice: 600000.0,
            baseCashFlowPerSecond: 600.0 * 1.45, // +45%
          ),
          RealEstateProperty(
            id: 'high_rise_unit_nyc',
            name: 'High-Rise Unit',
            purchasePrice: 1500000.0,
            baseCashFlowPerSecond: 1500.0 * 1.55, // +55%
          ),
          RealEstateProperty(
            id: 'manhattan_suite',
            name: 'Manhattan Suite',
            purchasePrice: 3000000.0,
            baseCashFlowPerSecond: 3000.0 * 1.65, // +65%
          ),
          RealEstateProperty(
            id: 'skyline_penthouse_nyc',
            name: 'Skyline Penthouse',
            purchasePrice: 7500000.0,
            baseCashFlowPerSecond: 7500.0 * 1.75, // +75%
          ),
          RealEstateProperty(
            id: 'central_park_view',
            name: 'Central Park View',
            purchasePrice: 15000000.0,
            baseCashFlowPerSecond: 15000.0 * 1.85, // +85%
          ),
          RealEstateProperty(
            id: 'billionaire_tower',
            name: 'Billionaire Tower',
            purchasePrice: 30000000.0,
            baseCashFlowPerSecond: 30000.0 * 1.95, // +95%
          ),
          RealEstateProperty(
            id: 'nyc_landmark_estate',
            name: 'NYC Landmark Estate',
            purchasePrice: 60000000.0,
            baseCashFlowPerSecond: 60000.0 * 2.05, // +105%
          ),
        ],
      ),
      
      // 17. Los Angeles, CA
      RealEstateLocale(
        id: 'los_angeles',
        name: 'Los Angeles, CA',
        theme: 'Hollywood and luxury U.S. homes',
        unlocked: false,
        icon: Icons.villa,
        properties: [
          RealEstateProperty(
            id: 'studio_bungalow',
            name: 'Studio Bungalow',
            purchasePrice: 50000.0,
            baseCashFlowPerSecond: 50.0 * 1.15, // +15%
          ),
          RealEstateProperty(
            id: 'hillside_flat',
            name: 'Hillside Flat',
            purchasePrice: 100000.0,
            baseCashFlowPerSecond: 100.0 * 1.25, // +25%
          ),
          RealEstateProperty(
            id: 'modern_condo_la',
            name: 'Modern Condo',
            purchasePrice: 250000.0,
            baseCashFlowPerSecond: 250.0 * 1.35, // +35%
          ),
          RealEstateProperty(
            id: 'hollywood_villa',
            name: 'Hollywood Villa',
            purchasePrice: 500000.0,
            baseCashFlowPerSecond: 500.0 * 1.45, // +45%
          ),
          RealEstateProperty(
            id: 'luxury_loft_la',
            name: 'Luxury Loft',
            purchasePrice: 1000000.0,
            baseCashFlowPerSecond: 1000.0 * 1.55, // +55%
          ),
          RealEstateProperty(
            id: 'beverly_hills_house',
            name: 'Beverly Hills House',
            purchasePrice: 2500000.0,
            baseCashFlowPerSecond: 2500.0 * 1.65, // +65%
          ),
          RealEstateProperty(
            id: 'celebrity_mansion',
            name: 'Celebrity Mansion',
            purchasePrice: 5000000.0,
            baseCashFlowPerSecond: 5000.0 * 1.75, // +75%
          ),
          RealEstateProperty(
            id: 'skyline_penthouse_la',
            name: 'Skyline Penthouse',
            purchasePrice: 10000000.0,
            baseCashFlowPerSecond: 10000.0 * 1.85, // +85%
          ),
          RealEstateProperty(
            id: 'oceanfront_estate',
            name: 'Oceanfront Estate',
            purchasePrice: 25000000.0,
            baseCashFlowPerSecond: 25000.0 * 1.95, // +95%
          ),
          RealEstateProperty(
            id: 'la_iconic_compound',
            name: 'LA Iconic Compound',
            purchasePrice: 50000000.0,
            baseCashFlowPerSecond: 50000.0 * 2.05, // +105%
          ),
        ],
      ),
      
      // 18. Lima, Peru
      RealEstateLocale(
        id: 'lima_peru',
        name: 'Lima, Peru',
        theme: 'Andean urban and coastal homes',
        unlocked: false,
        icon: Icons.house_siding,
        properties: [
          RealEstateProperty(
            id: 'adobe_flat',
            name: 'Adobe Flat',
            purchasePrice: 2500.0,
            baseCashFlowPerSecond: 2.5 * 1.15, // +15%
          ),
          RealEstateProperty(
            id: 'brick_house_lima',
            name: 'Brick House',
            purchasePrice: 5000.0,
            baseCashFlowPerSecond: 5.0 * 1.25, // +25%
          ),
          RealEstateProperty(
            id: 'coastal_shack',
            name: 'Coastal Shack',
            purchasePrice: 12500.0,
            baseCashFlowPerSecond: 12.5 * 1.35, // +35%
          ),
          RealEstateProperty(
            id: 'modern_apartment_lima',
            name: 'Modern Apartment',
            purchasePrice: 25000.0,
            baseCashFlowPerSecond: 25.0 * 1.45, // +45%
          ),
          RealEstateProperty(
            id: 'gated_unit_lima',
            name: 'Gated Unit',
            purchasePrice: 50000.0,
            baseCashFlowPerSecond: 50.0 * 1.55, // +55%
          ),
          RealEstateProperty(
            id: 'andean_villa',
            name: 'Andean Villa',
            purchasePrice: 125000.0,
            baseCashFlowPerSecond: 125.0 * 1.65, // +65%
          ),
          RealEstateProperty(
            id: 'luxury_condo_lima',
            name: 'Luxury Condo',
            purchasePrice: 250000.0,
            baseCashFlowPerSecond: 250.0 * 1.75, // +75%
          ),
          RealEstateProperty(
            id: 'high_rise_suite_lima',
            name: 'High-Rise Suite',
            purchasePrice: 500000.0,
            baseCashFlowPerSecond: 500.0 * 1.85, // +85%
          ),
          RealEstateProperty(
            id: 'oceanfront_loft',
            name: 'Oceanfront Loft',
            purchasePrice: 1000000.0,
            baseCashFlowPerSecond: 1000.0 * 1.95, // +95%
          ),
          RealEstateProperty(
            id: 'lima_skyline_estate',
            name: 'Lima Skyline Estate',
            purchasePrice: 2500000.0,
            baseCashFlowPerSecond: 2500.0 * 2.05, // +105%
          ),
        ],
      ),
      
      // 19. Sao Paulo, Brazil
      RealEstateLocale(
        id: 'sao_paulo_brazil',
        name: 'Sao Paulo, Brazil',
        theme: 'Sprawling South American metropolis',
        unlocked: false,
        icon: Icons.location_city,
        properties: [
          RealEstateProperty(
            id: 'favela_hut',
            name: 'Favela Hut',
            purchasePrice: 3500.0,
            baseCashFlowPerSecond: 3.5 * 1.15, // +15%
          ),
          RealEstateProperty(
            id: 'concrete_flat_sao_paulo',
            name: 'Concrete Flat',
            purchasePrice: 7000.0,
            baseCashFlowPerSecond: 7.0 * 1.25, // +25%
          ),
          RealEstateProperty(
            id: 'small_apartment_sao_paulo',
            name: 'Small Apartment',
            purchasePrice: 17500.0,
            baseCashFlowPerSecond: 17.5 * 1.35, // +35%
          ),
          RealEstateProperty(
            id: 'mid_rise_condo',
            name: 'Mid-Rise Condo',
            purchasePrice: 35000.0,
            baseCashFlowPerSecond: 35.0 * 1.45, // +45%
          ),
          RealEstateProperty(
            id: 'gated_tower_sao_paulo',
            name: 'Gated Tower',
            purchasePrice: 75000.0,
            baseCashFlowPerSecond: 75.0 * 1.55, // +55%
          ),
          RealEstateProperty(
            id: 'luxury_unit',
            name: 'Luxury Unit',
            purchasePrice: 150000.0,
            baseCashFlowPerSecond: 150.0 * 1.65, // +65%
          ),
          RealEstateProperty(
            id: 'high_rise_suite_sao_paulo',
            name: 'High-Rise Suite',
            purchasePrice: 375000.0,
            baseCashFlowPerSecond: 375.0 * 1.75, // +75%
          ),
          RealEstateProperty(
            id: 'skyline_penthouse_sao_paulo',
            name: 'Skyline Penthouse',
            purchasePrice: 750000.0,
            baseCashFlowPerSecond: 750.0 * 1.85, // +85%
          ),
          RealEstateProperty(
            id: 'business_loft_sao_paulo',
            name: 'Business Loft',
            purchasePrice: 1500000.0,
            baseCashFlowPerSecond: 1500.0 * 1.95, // +95%
          ),
          RealEstateProperty(
            id: 'sao_paulo_iconic_tower',
            name: 'Sao Paulo Iconic Tower',
            purchasePrice: 3000000.0,
            baseCashFlowPerSecond: 3000.0 * 2.05, // +105%
          ),
        ],
      ),
      
      // 20. Dubai, UAE
      RealEstateLocale(
        id: 'dubai_uae',
        name: 'Dubai, UAE',
        theme: 'Flashy desert luxury properties',
        unlocked: false,
        icon: Icons.location_city,
        properties: [
          RealEstateProperty(
            id: 'desert_apartment',
            name: 'Desert Apartment',
            purchasePrice: 35000.0,
            baseCashFlowPerSecond: 35.0 * 1.15, // +15%
          ),
          RealEstateProperty(
            id: 'modern_condo_dubai',
            name: 'Modern Condo',
            purchasePrice: 70000.0,
            baseCashFlowPerSecond: 70.0 * 1.25, // +25%
          ),
          RealEstateProperty(
            id: 'palm_villa',
            name: 'Palm Villa',
            purchasePrice: 175000.0,
            baseCashFlowPerSecond: 175.0 * 1.35, // +35%
          ),
          RealEstateProperty(
            id: 'luxury_flat_dubai',
            name: 'Luxury Flat',
            purchasePrice: 350000.0,
            baseCashFlowPerSecond: 350.0 * 1.45, // +45%
          ),
          RealEstateProperty(
            id: 'high_rise_suite_dubai',
            name: 'High-Rise Suite',
            purchasePrice: 750000.0,
            baseCashFlowPerSecond: 750.0 * 1.55, // +55%
          ),
          RealEstateProperty(
            id: 'burj_tower_unit',
            name: 'Burj Tower Unit',
            purchasePrice: 1500000.0,
            baseCashFlowPerSecond: 1500.0 * 1.65, // +65%
          ),
          RealEstateProperty(
            id: 'skyline_mansion',
            name: 'Skyline Mansion',
            purchasePrice: 3750000.0,
            baseCashFlowPerSecond: 3750.0 * 1.75, // +75%
          ),
          RealEstateProperty(
            id: 'island_retreat',
            name: 'Island Retreat',
            purchasePrice: 7500000.0,
            baseCashFlowPerSecond: 7500.0 * 1.85, // +85%
          ),
          RealEstateProperty(
            id: 'billionaire_penthouse_dubai',
            name: 'Billionaire Penthouse',
            purchasePrice: 15000000.0,
            baseCashFlowPerSecond: 15000.0 * 1.95, // +95%
          ),
          RealEstateProperty(
            id: 'dubai_iconic_skyscraper',
            name: 'Dubai Iconic Skyscraper',
            purchasePrice: 35000000.0,
            baseCashFlowPerSecond: 35000.0 * 2.05, // +105%
          ),
        ],
      ),
    ];
  }
  
  // Function to unlock real estate locales based on game progress
  void _updateRealEstateUnlocks() {
    // Count locales with properties for event system
    localesWithPropertiesCount = 0;
    for (var locale in realEstateLocales) {
      if (locale.getTotalPropertiesOwned() > 0) {
        localesWithPropertiesCount++;
      }
    }
    
    // Rural Kenya is always unlocked from the start
    List<String> alwaysUnlocked = ['rural_kenya'];
    _unlockLocalesById(alwaysUnlocked);
    
    // Check if player has any businesses
    bool hasAnyBusiness = businesses.any((business) => business.level > 0);
    
    // Only proceed with money-based unlocks if player has at least one business
    if (hasAnyBusiness) {
      // Create maps for each tier with locale IDs matched exactly from initialization
      Map<String, List<String>> tierUnlocks = {
        // Tier 2 (Money >= $10,000)
        'tier2': ['lagos_nigeria', 'rural_thailand', 'rural_mexico'],
        
        // Tier 3 (Money >= $50,000)
        'tier3': ['cape_town_sa', 'mumbai_india', 'ho_chi_minh_city', 'bucharest_romania', 'lima_peru', 'sao_paulo_brazil'],
        
        // Tier 4 (Money >= $250,000)
        'tier4': ['lisbon_portugal', 'berlin_germany', 'mexico_city'],
        
        // Tier 5 (Money >= $1,000,000)
        'tier5': ['singapore', 'london_uk', 'miami_florida', 'new_york_city', 'los_angeles'],
        
        // Tier 6 (Money >= $5,000,000)
        'tier6': ['hong_kong', 'dubai_uae'],
      };
      
      // Tier 2 - Money >= $10,000
      if (money >= 10000) {
        _unlockLocalesById(tierUnlocks['tier2']!);
      }
      
      // Tier 3 - Money >= $50,000
      if (money >= 50000) {
        _unlockLocalesById(tierUnlocks['tier3']!);
      }
      
      // Tier 4 - Money >= $250,000
      if (money >= 250000) {
        _unlockLocalesById(tierUnlocks['tier4']!);
      }
      
      // Tier 5 - Money >= $1,000,000
      if (money >= 1000000) {
        _unlockLocalesById(tierUnlocks['tier5']!);
      }
      
      // Tier 6 - Money >= $5,000,000
      if (money >= 5000000) {
        _unlockLocalesById(tierUnlocks['tier6']!);
      }
      
      // Notify listeners of changes
      notifyListeners();
    }
  }
  
  // Helper method to unlock locales by ID
  void _unlockLocalesById(List<String> localeIds) {
    for (String id in localeIds) {
      int index = realEstateLocales.indexWhere((locale) => locale.id == id);
      if (index != -1) {
        realEstateLocales[index].unlocked = true;
      }
    }
    // No notifyListeners() here - parent method will handle notification
  }
  
  // Function to get the total real estate income per second
  double getRealEstateIncomePerSecond() {
    double total = 0.0;
    for (var locale in realEstateLocales) {
      // Check for active events affecting this locale
      bool hasLocaleEvent = hasActiveEventForLocale(locale.id);
      
      if (hasLocaleEvent) {
        // For locales affected by events, apply the event penalty
        total += locale.getTotalIncomePerSecond(affectedByEvent: true);
      } else {
        // No event, normal income
        total += locale.getTotalIncomePerSecond();
      }
    }
    return total;
  }
  
  // Function to get the total investment dividend income per second
  double getTotalDividendIncomePerSecond() {
    double total = 0.0;
    for (var investment in investments) {
      if (investment.owned > 0 && investment.hasDividends()) {
        total += investment.getDividendIncomePerSecond();
      }
    }
    return total;
  }
  
  // Calculate the total income from all sources per second
  double calculateTotalIncomePerSecond() {
    double total = 0.0;
    
    // Add business income - include both incomeMultiplier and prestigeMultiplier
    for (var business in businesses) {
      if (business.level > 0) {
        total += business.getIncomePerSecond() * incomeMultiplier * prestigeMultiplier;
      }
    }
    
    // Add real estate income - include both incomeMultiplier and prestigeMultiplier
    total += getRealEstateIncomePerSecond() * incomeMultiplier * prestigeMultiplier;
    
    // Add dividend income - include both incomeMultiplier and prestigeMultiplier
    total += getTotalDividendIncomePerSecond() * incomeMultiplier * prestigeMultiplier;
    
    return total;
  }
  
  // Calculate the total business income per second (with multipliers)
  double getBusinessIncomePerSecond() {
    double total = 0.0;
    for (var business in businesses) {
      if (business.level > 0) {
        total += business.getIncomePerSecond() * incomeMultiplier * prestigeMultiplier;
      }
    }
    return total;
  }
  
  // Get combined income per second from all sources with their respective multipliers
  Map<String, double> getCombinedIncomeBreakdown() {
    double businessIncome = getBusinessIncomePerSecond();
    double realEstateIncome = getRealEstateIncomePerSecond() * incomeMultiplier * prestigeMultiplier;
    double investmentIncome = getTotalDividendIncomePerSecond() * incomeMultiplier * prestigeMultiplier;
    
    return {
      'business': businessIncome,
      'realEstate': realEstateIncome,
      'investment': investmentIncome,
      'total': businessIncome + realEstateIncome + investmentIncome,
    };
  }
  
  // Function to purchase real estate property
  bool buyRealEstateProperty(String localeId, String propertyId) {
    // Find the locale
    final localeIndex = realEstateLocales.indexWhere((locale) => locale.id == localeId);
    if (localeIndex == -1) return false;
    
    // Find the property
    final propertyIndex = realEstateLocales[localeIndex].properties.indexWhere((property) => property.id == propertyId);
    if (propertyIndex == -1) return false;
    
    // Get the property
    final property = realEstateLocales[localeIndex].properties[propertyIndex];
    
    // Check if player can afford it
    if (money < property.purchasePrice) return false;
    
    // Purchase the property
    money -= property.purchasePrice;
    property.owned++;
    
    // Notify listeners that state has changed
    notifyListeners();
    
    return true;
  }
  
  // Method to purchase an upgrade for a property
  bool purchasePropertyUpgrade(String localeId, String propertyId, String upgradeId) {
    print("🛒 Attempting to purchase upgrade: localeId=$localeId, propertyId=$propertyId, upgradeId=$upgradeId");

    // Find locale
    final localeIndex = realEstateLocales.indexWhere((locale) => locale.id == localeId);
    if (localeIndex == -1) {
      print("❌ Locale not found: $localeId");
      return false;
    }
    final RealEstateLocale locale = realEstateLocales[localeIndex]; // << GET LOCALE OBJECT

    // Find property in the found locale
    final propertyIndex = locale.properties.indexWhere((p) => p.id == propertyId);
    if (propertyIndex == -1) {
      print("❌ Property not found: $propertyId in locale $localeId");
      return false;
    }

    // Get property
    final property = locale.properties[propertyIndex]; // Use locale object here
    print("🏠 Found property: ${property.name} with ${property.upgrades.length} upgrades");

    // Check if property is owned
    if (property.owned <= 0) {
      print("❌ Property not owned: ${property.name}");
      return false;
    }

    // Find upgrade
    final upgradeIndex = property.upgrades.indexWhere((u) => u.id == upgradeId);
    if (upgradeIndex == -1) {
      print("❌ Upgrade not found: $upgradeId");
      print("Available upgrades:");
      property.upgrades.forEach((u) => print("  - ${u.id}: ${u.description}"));
      return false;
    }

    final upgrade = property.upgrades[upgradeIndex];
    print("🔍 Found upgrade: ${upgrade.description} (${upgrade.id})");

    // Check if already purchased
    if (upgrade.purchased) {
      print("❌ Upgrade already purchased: ${upgrade.description}");
      return false;
    }

    // Check if player can afford it
    if (money < upgrade.cost) {
      print("❌ Not enough money: Have \$${money.toStringAsFixed(2)}, need \$${upgrade.cost.toStringAsFixed(2)}");
      return false;
    }

    // Purchase the upgrade
    print("💰 Purchasing upgrade: ${upgrade.description} for \$${upgrade.cost}");
    print("   Before: Money=$money, Income per second=${property.cashFlowPerSecond}");

    money -= upgrade.cost;
    upgrade.purchased = true;

    print("   After: Money=$money, Income per second=${property.cashFlowPerSecond}");
    print("✅ Upgrade purchased successfully! New property income: \$${property.cashFlowPerSecond}/sec");

    // Update stats for achievements (using the correctly scoped 'locale' variable)
    totalRealEstateUpgradesPurchased++; 
    totalUpgradeSpending += upgrade.cost;

    // Track spending for luxury properties (purchase price >= $1M)
    if (property.purchasePrice >= 1000000.0) {
      luxuryUpgradeSpending += upgrade.cost;
    }

    // Check if property is now fully upgraded
    if (property.allUpgradesPurchased) {
      print("✨ Property fully upgraded: ${property.name} (${property.id})");
      fullyUpgradedPropertyIds.add(property.id);
      localesWithOneFullyUpgradedProperty.add(locale.id); // Use locale.id here

      // Update per-locale count
      fullyUpgradedPropertiesPerLocale[locale.id] = (fullyUpgradedPropertiesPerLocale[locale.id] ?? 0) + 1; // Use locale.id here
      print("   Locale ${locale.name} now has ${fullyUpgradedPropertiesPerLocale[locale.id]} fully upgraded properties."); // Use locale.name and locale.id here

      // Check if the entire locale is now fully upgraded
      // Use the 'locale' object to check its properties
      bool allInLocaleUpgraded = locale.properties.every((p) => p.owned > 0 && p.allUpgradesPurchased);
      if (allInLocaleUpgraded) {
        print("🌟 Entire locale fully upgraded: ${locale.name} (${locale.id})"); // Use locale.name and locale.id here
        fullyUpgradedLocales.add(locale.id); // Use locale.id here
      }
    }

    // Check achievements after updating stats
    List<Achievement> newlyCompleted = achievementManager.evaluateAchievements(this);
    if (newlyCompleted.isNotEmpty) {
      print("🏆 Achievements completed: ${newlyCompleted.map((a) => a.name).join(', ')}");
      // Add to recently completed list for potential UI notification
      recentlyCompletedAchievements.addAll(newlyCompleted);
    }

    // Notify listeners
    notifyListeners();

    return true;
  }
  
  // Function to get the total number of properties owned across all locales
  int getTotalOwnedProperties() {
    int total = 0;
    for (var locale in realEstateLocales) {
      total += locale.getTotalPropertiesOwned();
    }
    return total;
  }
  
  // Returns a list of all owned properties with their locale details
  List<Map<String, dynamic>> getAllOwnedPropertiesWithDetails() {
    List<Map<String, dynamic>> result = [];
    for (var locale in realEstateLocales) {
      for (var property in locale.properties) {
        if (property.owned > 0) {
          result.add({
            'property': property,
            'locale': locale,
            'localeId': locale.id,
            'propertyId': property.id,
            'propertyName': property.name,
            'localeName': locale.name,
            'owned': property.owned,
          });
        }
      }
    }
    return result;
  }
  
  // Function to check if player owns all available properties across all locales
  bool ownsAllProperties() {
    if (realEstateLocales.isEmpty) return false;
    
    // Check if every locale has all properties owned
    for (var locale in realEstateLocales) {
      if (!locale.properties.every((property) => property.owned > 0)) {
        return false;
      }
    }
    return true;
  }
  
  // Function to check if each income source exceeds the given threshold
  bool hasCombinedIncomeOfAmount(double threshold) {
    Map<String, double> incomeBreakdown = getCombinedIncomeBreakdown();
    
    // Check if all three income sources individually exceed the threshold
    return incomeBreakdown['business']! >= threshold &&
           incomeBreakdown['realEstate']! >= threshold &&
           incomeBreakdown['investment']! >= threshold;
  }
  
  // Get the top 50% of properties by value in a locale
  List<RealEstateProperty> _getTopPropertiesByValue(RealEstateLocale locale) {
    // Filter to only owned properties
    List<RealEstateProperty> ownedProperties = locale.properties
        .where((p) => p.owned > 0)
        .toList();
    
    if (ownedProperties.isEmpty) return [];
    
    // Sort by purchase price (descending)
    ownedProperties.sort((a, b) => b.purchasePrice.compareTo(a.purchasePrice));
    
    // Take the top 50%
    int count = (ownedProperties.length / 2).ceil();
    return ownedProperties.take(count).toList();
  }
  
  // Special method to properly reset real estate during reincorporation
  void _resetRealEstateForReincorporation() {
    // First initialize new real estate locales with default properties
    _initializeRealEstateLocales();
    
    // Then reset all upgrades for all properties
    for (var locale in realEstateLocales) {
      for (var property in locale.properties) {
        // Reset ownership to 0
        property.owned = 0;
        
        // Reset upgrades list to empty, ensuring no purchased upgrades persist
        property.upgrades = [];
      }
    }
  }

  // Add micro-updates to investment prices for more dynamic chart movement
  void _updateInvestmentPricesMicro() {
    // Only update occasionally to avoid too many updates
    if (Random().nextDouble() > 0.2) return; // 20% chance each tick
    
    for (var investment in investments) {
      // Apply a much smaller random price change
      double microChange = investment.trend * 0.01; // Smaller trend impact
      
      // Add smaller random component based on volatility
      microChange += (Random().nextDouble() * 2 - 1) * investment.volatility * 0.03;
      
      // Apply the micro-change
      double newPrice = investment.currentPrice * (1 + microChange);
      
      // Ensure price doesn't go below minimum threshold
      if (newPrice < investment.basePrice * 0.1) {
        newPrice = investment.basePrice * 0.1;
      }
      
      // Cap maximum price to avoid excessive growth
      double maxPrice = investment.basePrice * 10;
      if (newPrice > maxPrice) {
        newPrice = maxPrice;
      }
      
      investment.currentPrice = newPrice;
      
      // Update the last price in history with the current price
      if (investment.priceHistory.isNotEmpty) {
        investment.priceHistory[investment.priceHistory.length - 1] = investment.currentPrice;
      }
    }
  }
}