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
import 'market_event.dart';
import 'achievement_data.dart'; // Added import

part 'game_state/initialization_logic.dart';
part 'game_state/business_logic.dart';
part 'game_state/investment_logic.dart';
part 'game_state/real_estate_logic.dart';
part 'game_state/prestige_logic.dart';
part 'game_state/achievement_logic.dart';
part 'game_state/event_logic.dart';
part 'game_state/serialization_logic.dart';
part 'game_state/update_logic.dart';
part 'game_state/utility_logic.dart';

// Define a limit for how many days of earnings history to keep
const int _maxDailyEarningsHistory = 30; // Memory Optimization: Limit history size

class GameState with ChangeNotifier {
  double money = 500.0;
  double totalEarned = 500.0;
  double manualEarnings = 0.0;
  double passiveEarnings = 0.0;
  double investmentEarnings = 0.0;
  double investmentDividendEarnings = 0.0; // Track dividend income
  double realEstateEarnings = 0.0;
  double clickValue = 1.5;
  int taps = 0;
  int clickLevel = 1;
  int totalRealEstateUpgradesPurchased = 0; // Track total upgrades purchased

  // >> START: Add Achievement Tracking Fields Declaration <<
  // These fields are explicitly marked as needed for achievement tracking
  double totalUpgradeSpending = 0.0;
  double luxuryUpgradeSpending = 0.0;
  Set<String> fullyUpgradedPropertyIds = {};
  Map<String, int> fullyUpgradedPropertiesPerLocale = {};
  Set<String> localesWithOneFullyUpgradedProperty = {};
  Set<String> fullyUpgradedLocales = {};
  // >> END: Add Achievement Tracking Fields Declaration <<

  Map<String, double> hourlyEarnings = {}; // Key: YYYY-MM-DD-HH

  // Persistent Net Worth History (key: timestamp ms, value: net worth)
  // This map persists across reincorporation
  Map<int, double> persistentNetWorthHistory = {};

  bool isPremium = false;

  // Lifetime stats (persist across reincorporation)
  int lifetimeTaps = 0;
  DateTime gameStartTime = DateTime.now(); // Tracks when the game was first started

  late AchievementManager achievementManager;

  // Achievement Notification Queue System
  final List<Achievement> _pendingAchievementNotifications = [];
  Achievement? _currentAchievementNotification;
  bool _isAchievementNotificationVisible = false;

  List<Achievement> get pendingAchievementNotifications => List.unmodifiable(_pendingAchievementNotifications);
  Achievement? get currentAchievementNotification => _currentAchievementNotification;
  bool get isAchievementNotificationVisible => _isAchievementNotificationVisible;

  // CRITICAL FIX: ensure these are always initialized
  DateTime lastSaved = DateTime.now(); // When the game was last saved
  DateTime lastOpened = DateTime.now(); // When the game was last opened

  int currentDay = DateTime.now().weekday; // 1=Mon, 7=Sun
  bool isInitialized = false;

  List<Business> businesses = [];
  List<Investment> investments = [];
  List<RealEstateLocale> realEstateLocales = [];

  List<MarketEvent> activeMarketEvents = [];

  List<GameEvent> activeEvents = [];
  DateTime? lastEventTime;
  bool eventsUnlocked = false;
  List<DateTime> recentEventTimes = [];
  int businessesOwnedCount = 0;
  int localesWithPropertiesCount = 0;

  int totalEventsResolved = 0;
  int eventsResolvedByTapping = 0;
  int eventsResolvedByFee = 0;
  double eventFeesSpent = 0.0;
  int eventsResolvedByAd = 0;
  Map<String, int> eventsResolvedByLocale = {};
  DateTime? lastEventResolvedTime;
  List<GameEvent> resolvedEvents = []; // History of resolved events (limited)

  bool hasActiveEventForBusiness(String businessId) {
    for (var event in activeEvents) {
      if (!event.isResolved && event.affectedBusinessIds.contains(businessId)) {
        return true;
      }
    }
    return false;
  }

  bool hasActiveEventForLocale(String localeId) {
    for (var event in activeEvents) {
      if (!event.isResolved && event.affectedLocaleIds.contains(localeId)) {
        return true;
      }
    }
    return false;
  }

  void processTapForEvent(GameEvent event) {
    if (event.resolution.type != EventResolutionType.tapChallenge) return;

    Map<String, dynamic> tapData = event.resolution.value as Map<String, dynamic>;
    int current = tapData['current'] ?? 0;
    int required = tapData['required'] ?? 0;

    current++;
    tapData['current'] = current;

    lifetimeTaps++; // Increment lifetime taps to track event taps as well

    if (current >= required) {
      event.resolve();

      totalEventsResolved++;
      eventsResolvedByTapping++;
      trackEventResolution(event, "tap");
    }

    notifyListeners();
  }

  void trackEventResolution(GameEvent event, String method) {
    lastEventResolvedTime = DateTime.now();

    for (String localeId in event.affectedLocaleIds) {
      eventsResolvedByLocale[localeId] = (eventsResolvedByLocale[localeId] ?? 0) + 1;
    }

    resolvedEvents.add(event);
    if (resolvedEvents.length > 25) { // Keep only the last 25 events
      resolvedEvents.removeAt(0);
    }

    notifyListeners();
  }

  double get totalIncomePerSecond {
    double total = 0.0;

    for (var business in businesses) {
      if (business.level > 0) {
        total += business.getIncomePerSecond();
      }
    }

    total += getRealEstateIncomePerSecond();

    for (var investment in investments) {
      if (investment.owned > 0 && investment.hasDividends()) {
        total += investment.getDividendIncomePerSecond();
      }
    }

    return total;
  }

  double incomeMultiplier = 1.0;
  double clickMultiplier = 1.0;
  DateTime? clickBoostEndTime;

  double prestigeMultiplier = 1.0;
  double networkWorth = 0.0; // Accumulates with each reincorporation
  int reincorporationUsesAvailable = 0;
  int totalReincorporations = 0;

  Timer? _saveTimer;
  Timer? _updateTimer;
  Timer? _investmentUpdateTimer;

  // Future for tracking real estate initialization
  Future<void>? realEstateInitializationFuture;

  GameState() {
    print("🚀 Initializing GameState...");
    _initializeDefaultBusinesses(); // From initialization_logic.dart
    _initializeDefaultInvestments(); // From initialization_logic.dart
    _initializeRealEstateLocales(); // From initialization_logic.dart

    // Initialize achievement tracking fields explicitly
    totalUpgradeSpending = 0.0;
    luxuryUpgradeSpending = 0.0;
    fullyUpgradedPropertyIds = {};
    fullyUpgradedPropertiesPerLocale = {};
    localesWithOneFullyUpgradedProperty = {};
    fullyUpgradedLocales = {};
    totalRealEstateUpgradesPurchased = 0;

    // Initialize Achievement Manager FIRST
    achievementManager = AchievementManager(this);
    print("🏆 Achievement Manager Initialized.");

    print("🏘️ Starting Real Estate Upgrade Initialization...");
    realEstateInitializationFuture = initializeRealEstateUpgrades(); // From initialization_logic.dart
    realEstateInitializationFuture?.then((_) {
       print("✅ Real Estate Upgrades Initialized Successfully.");
       _updateBusinessUnlocks(); // From business_logic.dart
       _updateRealEstateUnlocks(); // From real_estate_logic.dart
       isInitialized = true;
       print("🏁 GameState Initialized (after async). Setting up timers...");
       _setupTimers(); // From update_logic.dart
       notifyListeners();
    }).catchError((e, stackTrace) {
        print("❌❌❌ CRITICAL ERROR during Real Estate Upgrade Initialization: $e");
        print(stackTrace);
        isInitialized = true; // Still mark as initialized to allow game to run potentially degraded
        print("⚠️ GameState Initialized (with RE upgrade error). Setting up timers...");
        _setupTimers(); // Setup timers even if upgrades failed
        notifyListeners();
    });

    _updateBusinessUnlocks();
    _updateRealEstateUnlocks();

    print("🚀 GameState Constructor Complete.");
  }

  Future<void> initializeRealEstateUpgrades() async {
    try {
      final upgradesByPropertyId = await RealEstateDataLoader.loadUpgradesFromCSV();
      RealEstateDataLoader.applyUpgradesToProperties(realEstateLocales, upgradesByPropertyId);
      notifyListeners();
    } catch (e) {
      print('Failed to initialize real estate upgrades: $e');
    }
  }

  void _initializeDefaultBusinesses() {
    businesses = [
      // 1. Mobile Car Wash
      Business(
        id: 'mobile_car_wash',
        name: 'Mobile Car Wash',
        description: 'A van-based car wash service with direct customer service',
        basePrice: 250.0,
        baseIncome: 0.43, // Adjusted income
        level: 0,
        incomeInterval: 1,
        unlocked: true,
        icon: Icons.local_car_wash,
        levels: [
          BusinessLevel(cost: 250.0, incomePerSecond: 0.43, description: 'Better van and supplies'),
          BusinessLevel(cost: 500.0, incomePerSecond: 1.09, description: 'Pressure washer'),
          BusinessLevel(cost: 1000.0, incomePerSecond: 2.60, description: 'Extra staff'),
          BusinessLevel(cost: 2000.0, incomePerSecond: 6.50, description: 'Second van'),
          BusinessLevel(cost: 4000.0, incomePerSecond: 17.34, description: 'Eco-friendly soap'),
          BusinessLevel(cost: 8000.0, incomePerSecond: 43.35, description: 'Mobile app rollout'),
          BusinessLevel(cost: 16000.0, incomePerSecond: 108.38, description: 'Franchise model'),
          BusinessLevel(cost: 32000.0, incomePerSecond: 260.1, description: 'Fleet expansion'),
          BusinessLevel(cost: 64000.0, incomePerSecond: 650.25, description: 'VIP detailing'),
          BusinessLevel(cost: 128000.0, incomePerSecond: 1625.63, description: 'Citywide coverage'),
        ],
      ),
      // 2. Pop-Up Food Stall
      Business(
        id: 'food_stall',
        name: 'Pop-Up Food Stall',
        description: 'A street stall selling food like burgers or tacos',
        basePrice: 1000.0,
        baseIncome: 2.17, // Adjusted income
        level: 0,
        incomeInterval: 1,
        unlocked: true,
        icon: Icons.fastfood,
        levels: [
          BusinessLevel(cost: 1000.0, incomePerSecond: 2.17, description: 'Basic stall'),
          BusinessLevel(cost: 2000.0, incomePerSecond: 5.20, description: 'Better grill'),
          BusinessLevel(cost: 4000.0, incomePerSecond: 13.01, description: 'Menu expansion'),
          BusinessLevel(cost: 8000.0, incomePerSecond: 32.51, description: 'More staff'),
          BusinessLevel(cost: 16000.0, incomePerSecond: 82.37, description: 'Branded tent'),
          BusinessLevel(cost: 32000.0, incomePerSecond: 205.91, description: 'Weekend markets'),
          BusinessLevel(cost: 64000.0, incomePerSecond: 520.2, description: 'Food truck expansion'),
          BusinessLevel(cost: 128000.0, incomePerSecond: 1300.5, description: 'Multi-city stalls'),
          BusinessLevel(cost: 256000.0, incomePerSecond: 3251.25, description: 'Catering gigs'),
          BusinessLevel(cost: 512000.0, incomePerSecond: 8128.13, description: 'Chain operation'),
        ],
      ),
      // 3. Boutique Coffee Roaster
      Business(
        id: 'coffee_roaster',
        name: 'Boutique Coffee Roaster',
        description: 'A small-batch coffee roasting and retail business',
        basePrice: 5000.0,
        baseIncome: 8.67, // Adjusted income
        level: 0,
        incomeInterval: 1,
        unlocked: true,
        icon: Icons.coffee,
        levels: [
          BusinessLevel(cost: 5000.0, incomePerSecond: 8.67, description: 'Home roaster offering'),
          BusinessLevel(cost: 10000.0, incomePerSecond: 21.68, description: 'Premium beans'),
          BusinessLevel(cost: 20000.0, incomePerSecond: 54.19, description: 'Cafe counter'),
          BusinessLevel(cost: 40000.0, incomePerSecond: 130.05, description: 'Wholesale deals'),
          BusinessLevel(cost: 80000.0, incomePerSecond: 325.13, description: 'Efficient Roasting machines'),
          BusinessLevel(cost: 160000.0, incomePerSecond: 812.81, description: 'Local chain'),
          BusinessLevel(cost: 320000.0, incomePerSecond: 2037.45, description: 'Online store launch'),
          BusinessLevel(cost: 640000.0, incomePerSecond: 5093.63, description: 'Brand licensing'),
          BusinessLevel(cost: 1280000.0, incomePerSecond: 12734.06, description: 'Export market'),
          BusinessLevel(cost: 2560000.0, incomePerSecond: 31862.25, description: 'Global supplier'),
        ],
      ),
      // 4. Fitness Studio
      Business(
        id: 'fitness_studio',
        name: 'Fitness Studio',
        description: 'A gym offering classes and personal training',
        basePrice: 20000.0,
        baseIncome: 36.0, // Adjusted income
        level: 0,
        incomeInterval: 1,
        unlocked: false,
        icon: Icons.fitness_center,
        levels: [
          BusinessLevel(cost: 20000.0, incomePerSecond: 36.0, description: 'Small space upgrade'),
          BusinessLevel(cost: 40000.0, incomePerSecond: 90.0, description: 'New equipment'),
          BusinessLevel(cost: 80000.0, incomePerSecond: 225.0, description: 'Group classes'),
          BusinessLevel(cost: 160000.0, incomePerSecond: 540.0, description: 'Hire more trainers'),
          BusinessLevel(cost: 320000.0, incomePerSecond: 1350.0, description: 'Acquire expanded space'),
          BusinessLevel(cost: 640000.0, incomePerSecond: 3375.0, description: 'App membership'),
          BusinessLevel(cost: 1280000.0, incomePerSecond: 8460.0, description: 'Second location'),
          BusinessLevel(cost: 2560000.0, incomePerSecond: 21150.0, description: 'Franchise rights'),
          BusinessLevel(cost: 5120000.0, incomePerSecond: 52920.0, description: 'Influencer endorsements'),
          BusinessLevel(cost: 10240000.0, incomePerSecond: 132300.0, description: 'National chain'),
        ],
      ),
      // 5. E-Commerce Store
      Business(
        id: 'ecommerce_store',
        name: 'E-Commerce Store',
        description: 'An online shop selling niche products like gadgets or apparel',
        basePrice: 100000.0,
        baseIncome: 240.0, // Adjusted income
        level: 0,
        incomeInterval: 1,
        unlocked: false,
        icon: Icons.shopping_basket,
        levels: [
          BusinessLevel(cost: 100000.0, incomePerSecond: 240.0, description: 'Basic website'),
          BusinessLevel(cost: 200000.0, incomePerSecond: 600.0, description: 'SEO boost'),
          BusinessLevel(cost: 400000.0, incomePerSecond: 1500.0, description: 'Expanded inventory offering'),
          BusinessLevel(cost: 800000.0, incomePerSecond: 3744.0, description: 'Faster shipping processes'),
          BusinessLevel(cost: 1600000.0, incomePerSecond: 9360.0, description: 'Ad campaigns'),
          BusinessLevel(cost: 3200000.0, incomePerSecond: 23400.0, description: 'Mobile app'),
          BusinessLevel(cost: 6400000.0, incomePerSecond: 58560.0, description: 'Warehouse expansion'),
          BusinessLevel(cost: 12800000.0, incomePerSecond: 146400.0, description: 'Multi-brand'),
          BusinessLevel(cost: 25600000.0, incomePerSecond: 366000.0, description: 'Global reach'),
          BusinessLevel(cost: 51200000.0, incomePerSecond: 912000.0, description: 'Market leader'),
        ],
      ),
      // 6. Craft Brewery
      Business(
        id: 'craft_brewery',
        name: 'Craft Brewery',
        description: 'A brewery producing artisanal beers for local and regional sale',
        basePrice: 500000.0,
        baseIncome: 720.0, // Adjusted income
        level: 0,
        incomeInterval: 1,
        unlocked: false,
        icon: Icons.sports_bar,
        levels: [
          BusinessLevel(cost: 500000.0, incomePerSecond: 720.0, description: 'Small batch production'),
          BusinessLevel(cost: 1000000.0, incomePerSecond: 1800.0, description: 'Tasting room at brewery'),
          BusinessLevel(cost: 2000000.0, incomePerSecond: 4500.0, description: 'New flavors'),
          BusinessLevel(cost: 4000000.0, incomePerSecond: 11250.0, description: 'Bigger tanks'),
          BusinessLevel(cost: 8000000.0, incomePerSecond: 28125.0, description: 'Distribution agreements'),
          BusinessLevel(cost: 16000000.0, incomePerSecond: 70200.0, description: 'Pub chain'),
          BusinessLevel(cost: 32000000.0, incomePerSecond: 175500.0, description: 'Canning line'),
          BusinessLevel(cost: 64000000.0, incomePerSecond: 439200.0, description: 'National sales team'),
          BusinessLevel(cost: 128000000.0, incomePerSecond: 1098000.0, description: 'Export deals'),
          BusinessLevel(cost: 256000000.0, incomePerSecond: 2743200.0, description: 'Industry giant'),
        ],
      ),
      // 7. Boutique Hotel
      Business(
        id: 'boutique_hotel',
        name: 'Boutique Hotel',
        description: 'A stylish hotel catering to travelers and locals',
        basePrice: 2000000.0,
        baseIncome: 3375.0, // Adjusted income
        level: 0,
        incomeInterval: 1,
        unlocked: false,
        icon: Icons.hotel,
        levels: [
          BusinessLevel(cost: 2000000.0, incomePerSecond: 3375.0, description: 'Small property'),
          BusinessLevel(cost: 4000000.0, incomePerSecond: 8437.5, description: 'More rooms'),
          BusinessLevel(cost: 8000000.0, incomePerSecond: 21093.75, description: 'Restaurant opening'),
          BusinessLevel(cost: 16000000.0, incomePerSecond: 52734.38, description: 'Spa add-on'),
          BusinessLevel(cost: 32000000.0, incomePerSecond: 131835.94, description: 'Luxury suites'),
          BusinessLevel(cost: 64000000.0, incomePerSecond: 329400.0, description: 'Event and convention space'),
          BusinessLevel(cost: 128000000.0, incomePerSecond: 823500.0, description: 'Second location'),
          BusinessLevel(cost: 256000000.0, incomePerSecond: 2058750.0, description: 'Chain branding'),
          BusinessLevel(cost: 512000000.0, incomePerSecond: 5146875.0, description: 'Global presence'),
          BusinessLevel(cost: 1000000000.0, incomePerSecond: 12858750.0, description: 'Luxury empire'),
        ],
      ),
      // 8. Film Production Studio
      Business(
        id: 'film_studio',
        name: 'Film Production Studio',
        description: 'A studio making indie films and streaming content',
        basePrice: 10000000.0,
        baseIncome: 16875.0, // Adjusted income
        level: 0,
        incomeInterval: 1,
        unlocked: false,
        icon: Icons.movie,
        levels: [
          BusinessLevel(cost: 10000000.0, incomePerSecond: 16875.0, description: 'Small crew'),
          BusinessLevel(cost: 20000000.0, incomePerSecond: 42187.5, description: 'Better film and studio gear'),
          BusinessLevel(cost: 40000000.0, incomePerSecond: 105468.75, description: 'Bigger castings'),
          BusinessLevel(cost: 80000000.0, incomePerSecond: 263671.88, description: 'Studio lot acquired'),
          BusinessLevel(cost: 160000000.0, incomePerSecond: 658125.0, description: 'Streaming deal with major brand'),
          BusinessLevel(cost: 320000000.0, incomePerSecond: 1647000.0, description: 'Blockbuster releases'),
          BusinessLevel(cost: 640000000.0, incomePerSecond: 4117500.0, description: 'Franchise IP'),
          BusinessLevel(cost: 1280000000.0, incomePerSecond: 10293750.0, description: 'Global releases'),
          BusinessLevel(cost: 2560000000.0, incomePerSecond: 25734375.0, description: 'Awards buzz'),
          BusinessLevel(cost: 5120000000.0, incomePerSecond: 64125000.0, description: 'Media titan'),
        ],
      ),
      // 9. Logistics Company
      Business(
        id: 'logistics_company',
        name: 'Logistics Company',
        description: 'A freight and delivery service for businesses',
        basePrice: 50000000.0,
        baseIncome: 84375.0, // Adjusted income
        level: 0,
        incomeInterval: 1,
        unlocked: false,
        icon: Icons.local_shipping,
        levels: [
          BusinessLevel(cost: 50000000.0, incomePerSecond: 84375.0, description: 'Additional trucks'),
          BusinessLevel(cost: 100000000.0, incomePerSecond: 210937.5, description: 'Strategic route expansion'),
          BusinessLevel(cost: 200000000.0, incomePerSecond: 526500.0, description: 'Multiple warehouses acquired'),
          BusinessLevel(cost: 400000000.0, incomePerSecond: 1316250.0, description: 'Fleet upgrade with high tech truck and trailers'),
          BusinessLevel(cost: 800000000.0, incomePerSecond: 3290625.0, description: 'Air shipping'),
          BusinessLevel(cost: 1600000000.0, incomePerSecond: 8235000.0, description: 'Automation with robotics'),
          BusinessLevel(cost: 3200000000.0, incomePerSecond: 20587500.0, description: 'Regional hub expansion'),
          BusinessLevel(cost: 6400000000.0, incomePerSecond: 51468750.0, description: 'National scale'),
          BusinessLevel(cost: 12800000000.0, incomePerSecond: 128587500.0, description: 'Global network with tanker shipping'),
          BusinessLevel(cost: 25600000000.0, incomePerSecond: 321300000.0, description: 'Industry leader'),
        ],
      ),
      // 10. Luxury Real Estate Developer
      Business(
        id: 'real_estate_developer',
        name: 'Luxury Real Estate Developer',
        description: 'Builds and sells high-end homes and condos',
        basePrice: 250000000.0,
        baseIncome: 337500.0, // Adjusted income
        level: 0,
        incomeInterval: 1,
        unlocked: false,
        icon: Icons.apartment,
        levels: [
          BusinessLevel(cost: 250000000.0, incomePerSecond: 337500.0, description: 'Single high end project'),
          BusinessLevel(cost: 500000000.0, incomePerSecond: 843750.0, description: 'Multiple gated community projects'),
          BusinessLevel(cost: 1000000000.0, incomePerSecond: 2109375.0, description: 'Luxury towers'),
          BusinessLevel(cost: 2000000000.0, incomePerSecond: 5265000.0, description: 'Beachfront high rises'),
          BusinessLevel(cost: 4000000000.0, incomePerSecond: 13162500.0, description: 'Smart homes for ultra rich'),
          BusinessLevel(cost: 8000000000.0, incomePerSecond: 32906250.0, description: 'City expansion projects'),
          BusinessLevel(cost: 16000000000.0, incomePerSecond: 82350000.0, description: 'Resort chain development deals'),
          BusinessLevel(cost: 32000000000.0, incomePerSecond: 205875000.0, description: 'Global brand'),
          BusinessLevel(cost: 64000000000.0, incomePerSecond: 513000000.0, description: 'Billionaire clients'),
          BusinessLevel(cost: 128000000000.0, incomePerSecond: 1285875000.0, description: 'Real estate empire'),
        ],
      ),
    ];
  }

  void _initializeDefaultInvestments() {
    investments = [
      // STOCKS
      Investment(
        id: 'nxt', name: 'NexTech', description: 'A tech firm specializing in AI software.',
        currentPrice: 10.0, basePrice: 10.0, volatility: 0.15, trend: 0.02, owned: 0,
        icon: Icons.computer, color: Colors.blue, category: 'Technology', marketCap: 2.5,
        priceHistory: List.generate(30, (i) => 10.0 * (0.98 + (Random().nextDouble() * 0.04))),
      ),
      Investment(
        id: 'grv', name: 'GreenVolt', description: 'Renewable energy company with steady growth.',
        currentPrice: 25.0, basePrice: 25.0, volatility: 0.12, trend: 0.03, owned: 0,
        icon: Icons.eco, color: Colors.green, category: 'Energy', marketCap: 5.0,
        priceHistory: List.generate(30, (i) => 25.0 * (0.98 + (Random().nextDouble() * 0.04))),
      ),
      Investment(
        id: 'mft', name: 'MegaFreight', description: 'Logistics and shipping giant.',
        currentPrice: 50.0, basePrice: 50.0, volatility: 0.15, trend: 0.01, owned: 0,
        icon: Icons.local_shipping, color: Colors.blueGrey, category: 'Transportation', marketCap: 12.0,
        priceHistory: List.generate(30, (i) => 50.0 * (0.98 + (Random().nextDouble() * 0.04))),
      ),
      Investment(
        id: 'lxw', name: 'LuxWear', description: 'High-end fashion brand with trendy spikes.',
        currentPrice: 100.0, basePrice: 100.0, volatility: 0.20, trend: 0.02, owned: 0,
        icon: Icons.diamond_outlined, color: Colors.pink, category: 'Fashion', marketCap: 3.2,
        priceHistory: List.generate(30, (i) => 100.0 * (0.98 + (Random().nextDouble() * 0.04))),
      ),
      Investment(
        id: 'stf', name: 'StarForge', description: 'Space exploration company with high risk/reward.',
        currentPrice: 500.0, basePrice: 500.0, volatility: 0.25, trend: 0.04, owned: 0,
        icon: Icons.rocket_launch, color: Colors.deepPurple, category: 'Aerospace', marketCap: 20.0,
        priceHistory: List.generate(30, (i) => 500.0 * (0.98 + (Random().nextDouble() * 0.04))),
      ),
      // CRYPTOCURRENCIES
      Investment(
        id: 'bcl', name: 'BitCoinLite', description: 'A beginner-friendly crypto with moderate swings.',
        currentPrice: 50.0, basePrice: 50.0, volatility: 0.30, trend: 0.02, owned: 0,
        icon: Icons.currency_bitcoin, color: Colors.amber, category: 'Cryptocurrency', marketCap: 0.85,
        priceHistory: List.generate(30, (i) => 50.0 * (0.98 + (Random().nextDouble() * 0.04))),
      ),
      Investment(
        id: 'etc', name: 'EtherCore', description: 'A blockchain platform with growing adoption.',
        currentPrice: 200.0, basePrice: 200.0, volatility: 0.25, trend: 0.03, owned: 0,
        icon: Icons.hub, color: Colors.blue.shade800, category: 'Cryptocurrency', marketCap: 2.4,
        priceHistory: List.generate(30, (i) => 200.0 * (0.98 + (Random().nextDouble() * 0.04))),
      ),
      Investment(
        id: 'mtk', name: 'MoonToken', description: 'A meme coin with wild volatility.',
        currentPrice: 10.0, basePrice: 10.0, volatility: 0.50, trend: -0.01, owned: 0,
        icon: Icons.nightlight_round, color: Colors.purple.shade300, category: 'Cryptocurrency', marketCap: 0.25,
        priceHistory: List.generate(30, (i) => 10.0 * (0.98 + (Random().nextDouble() * 0.04))),
      ),
      Investment(
        id: 'sbx', name: 'StableX', description: 'A low-risk crypto pegged to real-world value.',
        currentPrice: 100.0, basePrice: 100.0, volatility: 0.03, trend: 0.001, owned: 0,
        icon: Icons.lock, color: Colors.teal, category: 'Cryptocurrency', marketCap: 5.7,
        priceHistory: List.generate(30, (i) => 100.0 * (0.98 + (Random().nextDouble() * 0.04))),
      ),
      Investment(
        id: 'qbt', name: 'QuantumBit', description: 'Cutting-edge crypto tied to quantum computing.',
        currentPrice: 1000.0, basePrice: 1000.0, volatility: 0.35, trend: 0.05, owned: 0,
        icon: Icons.pending, color: Colors.cyan.shade700, category: 'Cryptocurrency', marketCap: 3.2,
        priceHistory: List.generate(30, (i) => 1000.0 * (0.98 + (Random().nextDouble() * 0.04))),
      ),
      // DIVIDEND INVESTMENTS
      Investment(
        id: 'btf', name: 'BioTech Innovators Fund', description: 'Fund for biotech startups in gene therapy and vaccines.',
        currentPrice: 500.0, basePrice: 500.0, volatility: 0.20, trend: 0.03, owned: 0,
        icon: Icons.healing, color: Colors.lightBlue.shade700, category: 'Healthcare', dividendPerSecond: 1.89, marketCap: 12.5,
        priceHistory: List.generate(30, (i) => 500.0 * (0.98 + (Random().nextDouble() * 0.04))),
      ),
      Investment(
        id: 'sme', name: 'Streaming Media ETF', description: 'ETF of streaming platforms and content creators.',
        currentPrice: 2000.0, basePrice: 2000.0, volatility: 0.20, trend: 0.04, owned: 0,
        icon: Icons.live_tv, color: Colors.red.shade700, category: 'Entertainment', dividendPerSecond: 7.56, marketCap: 35.8,
        priceHistory: List.generate(30, (i) => 2000.0 * (0.98 + (Random().nextDouble() * 0.04))),
      ),
      Investment(
        id: 'sab', name: 'Sustainable Agriculture Bonds', description: 'Bonds for organic farming and sustainable food production.',
        currentPrice: 10000.0, basePrice: 10000.0, volatility: 0.10, trend: 0.02, owned: 0,
        icon: Icons.agriculture, color: Colors.green.shade800, category: 'Agriculture', dividendPerSecond: 39, marketCap: 22.7,
        priceHistory: List.generate(30, (i) => 10000.0 * (0.98 + (Random().nextDouble() * 0.04))),
      ),
      Investment(
        id: 'gti', name: 'Global Tourism Index', description: 'Index fund of major tourism companies.',
        currentPrice: 50000.0, basePrice: 50000.0, volatility: 0.20, trend: 0.03, owned: 0,
        icon: Icons.flight, color: Colors.amber.shade800, category: 'Tourism', dividendPerSecond: 191, marketCap: 86.5,
        priceHistory: List.generate(30, (i) => 50000.0 * (0.98 + (Random().nextDouble() * 0.04))),
      ),
      Investment(
        id: 'urt', name: 'Urban REIT', description: 'REIT for urban commercial properties.',
        currentPrice: 200000.0, basePrice: 200000.0, volatility: 0.10, trend: 0.02, owned: 0,
        icon: Icons.business, color: Colors.brown.shade600, category: 'REITs', dividendPerSecond: 762, marketCap: 125.8,
        priceHistory: List.generate(30, (i) => 200000.0 * (0.98 + (Random().nextDouble() * 0.04))),
      ),
      Investment(
        id: 'vrv', name: 'Virtual Reality Ventures', description: 'Stocks in VR gaming and entertainment companies.',
        currentPrice: 1000000.0, basePrice: 1000000.0, volatility: 0.30, trend: 0.05, owned: 0,
        icon: Icons.vrpano, color: Colors.deepPurple.shade600, category: 'Entertainment', dividendPerSecond: 3900, marketCap: 75.2,
        priceHistory: List.generate(30, (i) => 1000000.0 * (0.98 + (Random().nextDouble() * 0.04))),
      ),
      Investment(
        id: 'mrc', name: 'Medical Robotics Corp', description: 'Company producing robotic surgery and AI diagnostics.',
        currentPrice: 5000000.0, basePrice: 5000000.0, volatility: 0.20, trend: 0.04, owned: 0,
        icon: Icons.biotech, color: Colors.blue.shade800, category: 'Healthcare', dividendPerSecond: 19500.0, marketCap: 120.7,
        priceHistory: List.generate(30, (i) => 5000000.0 * (0.98 + (Random().nextDouble() * 0.04))),
      ),
      Investment(
        id: 'atf', name: 'AgroTech Futures', description: 'Futures on agrotech firms in vertical farming.',
        currentPrice: 20000000.0, basePrice: 20000000.0, volatility: 0.30, trend: 0.03, owned: 0,
        icon: Icons.eco, color: Colors.lightGreen.shade800, category: 'Agriculture', dividendPerSecond: 83000, marketCap: 195.3,
        priceHistory: List.generate(30, (i) => 20000000.0 * (0.98 + (Random().nextDouble() * 0.04))),
      ),
      Investment(
        id: 'lrr', name: 'Luxury Resort REIT', description: 'REIT for luxury resorts and vacation properties.',
        currentPrice: 100000000.0, basePrice: 100000000.0, volatility: 0.10, trend: 0.02, owned: 0,
        icon: Icons.beach_access, color: Colors.teal.shade600, category: 'REITs', dividendPerSecond: 385000, marketCap: 580.6,
        priceHistory: List.generate(30, (i) => 100000000.0 * (0.98 + (Random().nextDouble() * 0.04))),
      ),
      Investment(
        id: 'ath', name: 'Adventure Travel Holdings', description: 'Holdings in adventure travel and eco-tourism operators.',
        currentPrice: 500000000.0, basePrice: 500000000.0, volatility: 0.20, trend: 0.03, owned: 0,
        icon: Icons.terrain, color: Colors.orange.shade800, category: 'Tourism', dividendPerSecond: 1900000, marketCap: 1250.0,
        priceHistory: List.generate(30, (i) => 500000000.0 * (0.98 + (Random().nextDouble() * 0.04))),
      ),
    ];
  }

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

  void enablePremium() {
    isPremium = true;
    notifyListeners();
    print("Premium status enabled");
  }

  void _setupTimers() {
    _saveTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      notifyListeners(); // This will trigger the save in GameService
    });

    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateGameState();
    });

    // Update investment prices more frequently
    Timer.periodic(const Duration(seconds: 30), (_) {
      if (isInitialized) {
        _updateInvestmentPrices();
      }
    });
  }

  void _updateInvestmentPrices() {
    for (var investment in investments) {
      double change = investment.trend * 0.2;
      change += (Random().nextDouble() * 2 - 1) * investment.volatility * 0.3;

      double newPrice = investment.currentPrice * (1 + change);
      newPrice = max(investment.basePrice * 0.1, newPrice); // Ensure min price
      newPrice = min(investment.basePrice * 10, newPrice); // Ensure max price

      investment.currentPrice = newPrice;

      if (investment.priceHistory.isNotEmpty) {
        investment.priceHistory[investment.priceHistory.length - 1] = investment.currentPrice;
      }
    }
    notifyListeners();
  }

  void _updateGameState() {
    try {
      DateTime now = DateTime.now();
      String hourKey = TimeUtils.getHourKey(now);

      checkAndTriggerEvents();

      if (clickBoostEndTime != null && now.isAfter(clickBoostEndTime!)) {
        clickMultiplier = 1.0;
        clickBoostEndTime = null;
        notifyListeners();
      }

      _updateInvestmentPricesMicro();

      if (isInitialized && achievementManager != null) {
        List<Achievement> newlyCompleted = achievementManager.evaluateAchievements(this);
        if (newlyCompleted.isNotEmpty) {
          queueAchievementsForDisplay(newlyCompleted);
        }
      }

      updateReincorporationUses();
      _updateRealEstateUnlocks();

      double previousMoney = money;

      // Update businesses income
      double businessIncomeThisTick = 0;
      for (var business in businesses) {
        if (business.level > 0) {
          business.secondsSinceLastIncome++;
          if (business.secondsSinceLastIncome >= business.incomeInterval) {
            bool hasEvent = hasActiveEventForBusiness(business.id);
            double income = business.getCurrentIncome(affectedByEvent: hasEvent) * incomeMultiplier * prestigeMultiplier;
            businessIncomeThisTick += income;
            business.secondsSinceLastIncome = 0;
          }
        }
      }
      if (businessIncomeThisTick > 0) {
        money += businessIncomeThisTick;
        totalEarned += businessIncomeThisTick;
        passiveEarnings += businessIncomeThisTick;
        _updateHourlyEarnings(hourKey, businessIncomeThisTick);
      }

      // Generate real estate income
      double realEstateIncomePerSecond = getRealEstateIncomePerSecond();
      double realEstateIncomeThisTick = realEstateIncomePerSecond * incomeMultiplier * prestigeMultiplier;
      if (realEstateIncomeThisTick > 0) {
        money += realEstateIncomeThisTick;
        totalEarned += realEstateIncomeThisTick;
        realEstateEarnings += realEstateIncomeThisTick;
        _updateHourlyEarnings(hourKey, realEstateIncomeThisTick);
      }

      // Generate dividend income from investments
      double dividendIncomeThisTick = 0.0;
      double diversificationBonus = calculateDiversificationBonus();
      for (var investment in investments) {
        if (investment.owned > 0 && investment.hasDividends()) {
          double investmentDividend = investment.getDividendIncomePerSecond() *
                                     incomeMultiplier *
                                     prestigeMultiplier *
                                     (1 + diversificationBonus); // Apply diversification bonus
          dividendIncomeThisTick += investmentDividend;
        }
      }
      if (dividendIncomeThisTick > 0) {
        money += dividendIncomeThisTick;
        totalEarned += dividendIncomeThisTick;
        investmentDividendEarnings += dividendIncomeThisTick;
        _updateHourlyEarnings(hourKey, dividendIncomeThisTick);
      }

      if (money != previousMoney) {
         notifyListeners();
      }

      // Persistent Net Worth Tracking (every 30 mins)
      if (now.minute % 30 == 0 && now.second < 5) {
        int timestampMs = now.millisecondsSinceEpoch;
        persistentNetWorthHistory[timestampMs] = calculateNetWorth();

        final cutoffMs = now.subtract(const Duration(days: 7)).millisecondsSinceEpoch;
        persistentNetWorthHistory.removeWhere((key, value) => key < cutoffMs);
      }

      // Check for new day
      int todayDay = now.weekday;
      if (todayDay != currentDay) {
        currentDay = todayDay;
        _updateInvestments();
        _updateRealEstateUnlocks();
        notifyListeners();
      }

    } catch (e, stackTrace) {
      print("❌❌❌ CRITICAL ERROR in _updateGameState: $e");
      print(stackTrace);
    }
  }

  void _updateInvestments() {
    _generateMarketEvents();
    _processAutoInvestments();

    for (var investment in investments) {
      investment.priceHistory.add(investment.currentPrice);
      if (investment.priceHistory.length > 30) {
        investment.priceHistory.removeAt(0);
      }

      double change = investment.trend;
      change += (Random().nextDouble() * 2 - 1) * investment.volatility;

      double newPrice = investment.currentPrice * (1 + change);
      newPrice = max(investment.basePrice * 0.1, newPrice); // Min price
      newPrice = min(investment.basePrice * 10, newPrice); // Max price

      investment.currentPrice = newPrice;

      _applyMarketEventEffects(investment);
    }
  }

  void _generateMarketEvents() {
    if (Random().nextDouble() < 0.15) { // 15% chance per day
      MarketEvent newEvent = _createRandomMarketEvent();
      activeMarketEvents.add(newEvent);
    }

    activeMarketEvents.removeWhere((event) {
      event.remainingDays--;
      return event.remainingDays <= 0;
    });
  }

  void _applyMarketEventEffects(Investment investment) {
    for (MarketEvent event in activeMarketEvents) {
      if (event.categoryImpacts.containsKey(investment.category)) {
        double impact = event.categoryImpacts[investment.category]!;
        investment.currentPrice *= impact;
      }
    }
  }

  MarketEvent _createRandomMarketEvent() {
    List<String> eventTypes = [
      'boom', 'crash', 'volatility', 'regulation', 'innovation'
    ];
    String eventType = eventTypes[Random().nextInt(eventTypes.length)];

    switch (eventType) {
      case 'boom': return _createBoomEvent();
      case 'crash': return _createCrashEvent();
      case 'volatility': return _createVolatilityEvent();
      case 'regulation': return _createRegulationEvent();
      case 'innovation': return _createInnovationEvent();
      default: return _createBoomEvent();
    }
  }

  MarketEvent _createBoomEvent() {
    List<String> categories = _getInvestmentCategories();
    int numCategories = Random().nextInt(2) + 1;
    List<String> affectedCategories = [];
    for (int i = 0; i < numCategories && categories.isNotEmpty; i++) {
      int index = Random().nextInt(categories.length);
      affectedCategories.add(categories.removeAt(index));
    }
    Map<String, double> impacts = { for (var cat in affectedCategories) cat: 1.0 + (Random().nextDouble() * 0.06 + 0.02) }; // +2% to +8%
    String primaryCategory = affectedCategories.isNotEmpty ? affectedCategories.first : "Market";
    return MarketEvent(
      name: '$primaryCategory Boom', description: 'A market boom is happening in the $primaryCategory sector!',
      categoryImpacts: impacts, durationDays: Random().nextInt(3) + 2, // 2-4 days
    );
  }

  MarketEvent _createCrashEvent() {
    List<String> categories = _getInvestmentCategories();
    int numCategories = Random().nextInt(2) + 1;
    List<String> affectedCategories = [];
     for (int i = 0; i < numCategories && categories.isNotEmpty; i++) {
      int index = Random().nextInt(categories.length);
      affectedCategories.add(categories.removeAt(index));
    }
    Map<String, double> impacts = { for (var cat in affectedCategories) cat: 1.0 - (Random().nextDouble() * 0.06 + 0.02) }; // -2% to -8%
    String primaryCategory = affectedCategories.isNotEmpty ? affectedCategories.first : "Market";
    return MarketEvent(
      name: '$primaryCategory Crash', description: 'A market crash is affecting the $primaryCategory sector!',
      categoryImpacts: impacts, durationDays: Random().nextInt(3) + 2, // 2-4 days
    );
  }

  MarketEvent _createVolatilityEvent() {
    List<String> categories = _getInvestmentCategories();
    String category = categories.isNotEmpty ? categories[Random().nextInt(categories.length)] : "Market";
    double impact = Random().nextBool() ? 1.1 : 0.9; // Start +10% or -10%
    Map<String, double> impacts = { category: impact };
    return MarketEvent(
      name: 'Market Volatility', description: 'The $category market is experiencing high volatility!',
      categoryImpacts: impacts, durationDays: Random().nextInt(5) + 3, // 3-7 days
    );
  }

  MarketEvent _createRegulationEvent() {
    List<String> categories = _getInvestmentCategories();
    String category = categories.isNotEmpty ? categories[Random().nextInt(categories.length)] : "Market";
    Map<String, double> impacts = { category: 0.97 }; // -3%
    return MarketEvent(
      name: 'New Regulations', description: 'New regulations are affecting the $category sector.',
      categoryImpacts: impacts, durationDays: Random().nextInt(3) + 5, // 5-7 days
    );
  }

  MarketEvent _createInnovationEvent() {
    List<String> categories = _getInvestmentCategories();
    String category = categories.isNotEmpty ? categories[Random().nextInt(categories.length)] : "Market";
    Map<String, double> impacts = { category: 1.05 }; // +5%
    return MarketEvent(
      name: 'Technological Breakthrough', description: 'A breakthrough innovation is boosting the $category sector!',
      categoryImpacts: impacts, durationDays: Random().nextInt(5) + 3, // 3-7 days
    );
  }

  List<String> _getInvestmentCategories() {
    return investments.map((i) => i.category).toSet().toList();
  }

  double calculateDiversificationBonus() {
    Set<String> categories = {};
    for (var investment in investments) {
      if (investment.owned > 0) {
        categories.add(investment.category);
      }
    }
    return categories.length * 0.02; // 2% bonus per unique category owned
  }

  void _processAutoInvestments() {
    for (var investment in investments) {
      if (investment.autoInvestEnabled && investment.autoInvestAmount > 0) {
        int quantity = (investment.autoInvestAmount / investment.currentPrice).floor();
        if (quantity > 0 && money >= investment.autoInvestAmount) {
          buyInvestment(investment.id, quantity);
        }
      }
    }
  }

  void tap() {
    double earned = clickValue * clickMultiplier;
    money += earned;
    totalEarned += earned;
    manualEarnings += earned;
    taps++;
    lifetimeTaps++;

    String today = TimeUtils.getDayKey(DateTime.now());
    _updateDailyEarnings(today, earned);

    notifyListeners();
  }

  bool buyBusiness(String businessId) {
    int index = businesses.indexWhere((b) => b.id == businessId);
    if (index == -1) return false;

    Business business = businesses[index];
    if (business.isMaxLevel()) return false;

    double cost = business.getNextUpgradeCost();
    if (money >= cost) {
      money -= cost;
      business.level++;
      business.unlocked = true;
      _updateBusinessUnlocks();
      notifyListeners();
      return true;
    }
    return false;
  }

  void _updateBusinessUnlocks() {
    businessesOwnedCount = businesses.where((b) => b.level > 0).length;

    for (var business in businesses) {
      if (!business.unlocked) {
        // Simple cascading unlock based on money thresholds
        if (business.id == 'fitness_studio' && money >= 10000.0) business.unlocked = true;
        else if (business.id == 'ecommerce_store' && money >= 50000.0) business.unlocked = true;
        else if (business.id == 'craft_brewery' && money >= 250000.0) business.unlocked = true;
        else if (business.id == 'boutique_hotel' && money >= 1000000.0) business.unlocked = true;
        else if (business.id == 'film_studio' && money >= 5000000.0) business.unlocked = true;
        else if (business.id == 'logistics_company' && money >= 25000000.0) business.unlocked = true;
        else if (business.id == 'real_estate_developer' && money >= 100000000.0) business.unlocked = true;
      }
    }
  }

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

  bool sellInvestment(String investmentId, int quantity) {
    int index = investments.indexWhere((i) => i.id == investmentId);
    if (index == -1) return false;

    Investment investment = investments[index];
    if (investment.owned >= quantity) {
      double saleAmount = investment.currentPrice * quantity;
      money += saleAmount;
      investment.owned -= quantity;

      double profitLoss = saleAmount - (investment.purchasePrice * quantity);
      investmentEarnings += profitLoss;

      if (investment.owned == 0) {
        investment.purchasePrice = 0.0;
      }
      notifyListeners();
      return true;
    }
    return false;
  }

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

  InvestmentHolding? getInvestmentHolding(String investmentId) {
    int index = investments.indexWhere((i) => i.id == investmentId && i.owned > 0);
    if (index == -1) return null;
    return InvestmentHolding(
      investmentId: investments[index].id,
      purchasePrice: investments[index].purchasePrice,
      shares: investments[index].owned,
    );
  }


  double getTotalInvestmentValue() {
    return investments.fold(0.0, (sum, investment) => sum + investment.getCurrentValue());
  }

  bool buyClickBoost() {
    double cost = 1000.0;
    if (money >= cost) {
      money -= cost;
      clickMultiplier = 2.0;
      clickBoostEndTime = DateTime.now().add(const Duration(minutes: 5));
      notifyListeners();
      return true;
    }
    return false;
  }

  double calculateNetWorth() {
    double businessesValue = businesses.fold(0.0, (sum, business) => sum + business.getCurrentValue());
    double investmentsValue = investments.fold(0.0, (sum, investment) => sum + investment.getCurrentValue());
    double realEstateValue = realEstateLocales.fold(0.0, (sum, locale) => sum + locale.getTotalValue());
    return money + businessesValue + investmentsValue + realEstateValue;
  }

  Map<String, dynamic> toJson() {
    print("💾 GameState.toJson starting...");
    Map<String, dynamic> json = {
      'money': money,
      'totalEarned': totalEarned,
      'manualEarnings': manualEarnings,
      'passiveEarnings': passiveEarnings,
      'investmentEarnings': investmentEarnings,
      'investmentDividendEarnings': investmentDividendEarnings,
      'realEstateEarnings': realEstateEarnings,
      'clickValue': clickValue,
      'taps': taps,
      'clickLevel': clickLevel,
      'totalRealEstateUpgradesPurchased': totalRealEstateUpgradesPurchased,
      'totalUpgradeSpending': totalUpgradeSpending,
      'luxuryUpgradeSpending': luxuryUpgradeSpending,
      'fullyUpgradedPropertyIds': fullyUpgradedPropertyIds.toList(),
      'fullyUpgradedPropertiesPerLocale': fullyUpgradedPropertiesPerLocale,
      'localesWithOneFullyUpgradedProperty': localesWithOneFullyUpgradedProperty.toList(),
      'fullyUpgradedLocales': fullyUpgradedLocales.toList(),
      'isPremium': isPremium,
      'lifetimeTaps': lifetimeTaps,
      'gameStartTime': gameStartTime.toIso8601String(),
      'currentDay': currentDay,
      'incomeMultiplier': incomeMultiplier,
      'clickMultiplier': clickMultiplier,
      'prestigeMultiplier': prestigeMultiplier,
      'networkWorth': networkWorth,
      'reincorporationUsesAvailable': reincorporationUsesAvailable,
      'totalReincorporations': totalReincorporations,
      'lastSaved': lastSaved.toIso8601String(),
      'events': eventsToJson(),
      'lastOpened': DateTime.now().toIso8601String(),
      'isInitialized': true, // Assuming saving means it's initialized
    };

    if (clickBoostEndTime != null) {
      json['clickBoostEndTime'] = clickBoostEndTime!.toIso8601String();
    }

    json['businesses'] = businesses.map((b) => {
      'id': b.id, 'level': b.level, 'unlocked': b.unlocked, 'secondsSinceLastIncome': b.secondsSinceLastIncome
    }).toList();

    json['investments'] = investments.map((i) => {
      'id': i.id, 'owned': i.owned, 'purchasePrice': i.purchasePrice,
      'currentPrice': i.currentPrice, 'priceHistory': i.priceHistory
    }).toList();

    json['realEstateLocales'] = realEstateLocales.map((locale) => {
      'id': locale.id, 'unlocked': locale.unlocked,
      'properties': locale.properties.map((p) => {
        'id': p.id, 'owned': p.owned,
        'purchasedUpgradeIds': p.upgrades.where((u) => u.purchased).map((u) => u.id).toList(),
      }).toList(),
    }).toList();

    json['hourlyEarnings'] = hourlyEarnings;
    json['persistentNetWorthHistory'] = persistentNetWorthHistory.map((k, v) => MapEntry(k.toString(), v));
    json['achievements'] = achievementManager.achievements.map((a) => a.toJson()).toList();
    json.addAll(eventsToJson());

    return json;
  }

  Future<void> fromJson(Map<String, dynamic> json) async {
    money = json['money'] ?? 500.0;
    totalEarned = json['totalEarned'] ?? 500.0;
    manualEarnings = json['manualEarnings'] ?? 0.0;
    passiveEarnings = json['passiveEarnings'] ?? 0.0;
    isPremium = json['isPremium'] ?? false;
    investmentEarnings = json['investmentEarnings'] ?? 0.0;
    investmentDividendEarnings = json['investmentDividendEarnings'] ?? 0.0;
    realEstateEarnings = json['realEstateEarnings'] ?? 0.0;
    clickValue = json['clickValue'] ?? 1.5;
    taps = json['taps'] ?? 0;
    clickLevel = json['clickLevel'] ?? 1;
    totalRealEstateUpgradesPurchased = json['totalRealEstateUpgradesPurchased'] ?? 0;

    totalUpgradeSpending = json['totalUpgradeSpending'] ?? 0.0;
    luxuryUpgradeSpending = json['luxuryUpgradeSpending'] ?? 0.0;
    fullyUpgradedPropertyIds = Set<String>.from(json['fullyUpgradedPropertyIds'] ?? []);
    fullyUpgradedPropertiesPerLocale = Map<String, int>.from(json['fullyUpgradedPropertiesPerLocale'] ?? {});
    localesWithOneFullyUpgradedProperty = Set<String>.from(json['localesWithOneFullyUpgradedProperty'] ?? []);
    fullyUpgradedLocales = Set<String>.from(json['fullyUpgradedLocales'] ?? []);


    lifetimeTaps = json['lifetimeTaps'] ?? taps;
    if (json['gameStartTime'] != null) {
      try { gameStartTime = DateTime.parse(json['gameStartTime']); } catch (_) {}
    }

    currentDay = json['currentDay'] ?? DateTime.now().weekday;
    incomeMultiplier = json['incomeMultiplier'] ?? 1.0;
    clickMultiplier = json['clickMultiplier'] ?? 1.0;
    prestigeMultiplier = json['prestigeMultiplier'] ?? 1.0;
    networkWorth = json['networkWorth'] ?? 0.0;
    reincorporationUsesAvailable = json['reincorporationUsesAvailable'] ?? 0;
    totalReincorporations = json['totalReincorporations'] ?? 0;
    isInitialized = json['isInitialized'] ?? false; // Load initialized status

    // CRITICAL FIX: Load lastSaved robustly
    try {
      lastSaved = json['lastSaved'] != null ? DateTime.parse(json['lastSaved']) : DateTime.now();
      print("📅 Loaded lastSaved timestamp: ${lastSaved.toIso8601String()}");
    } catch (e) {
      print("❌ Error parsing lastSaved timestamp: $e. Using current time.");
      lastSaved = DateTime.now();
    }

    // Process offline progress based on lastOpened
    try {
      if (json['lastOpened'] != null) {
        DateTime previousOpen = DateTime.parse(json['lastOpened']);
        print("📆 Loaded lastOpened timestamp: ${previousOpen.toIso8601String()}");
        int secondsElapsed = DateTime.now().difference(previousOpen).inSeconds;
        print("⏱️ Time since last opened: ${secondsElapsed} seconds");
        if (secondsElapsed > 10) {
          print("💰 Processing offline progress for $secondsElapsed seconds");
          // Ensure achievementManager is initialized before processing offline progress
          achievementManager = AchievementManager(this);
          _processOfflineProgress(secondsElapsed);
        }
      } else {
        print("⚠️ No lastOpened timestamp found, using current time");
      }
    } catch (e) {
      print("❌ Error parsing lastOpened timestamp: $e");
    }
    lastOpened = DateTime.now(); // Always update lastOpened
    print("🔄 Updated lastOpened to: ${lastOpened.toIso8601String()}");


    if (json['clickBoostEndTime'] != null) {
       try {
        clickBoostEndTime = DateTime.parse(json['clickBoostEndTime']);
        if (DateTime.now().isAfter(clickBoostEndTime!)) {
          clickMultiplier = 1.0;
          clickBoostEndTime = null;
        }
      } catch (_) {}
    }

    // Load businesses
    if (json['businesses'] is List) {
      for (var businessJson in json['businesses']) {
        if (businessJson is Map && businessJson['id'] != null) {
          int index = businesses.indexWhere((b) => b.id == businessJson['id']);
          if (index != -1) {
            if (businessJson['level'] != null) businesses[index].level = businessJson['level'];
            else if (businessJson['owned'] != null) businesses[index].level = businessJson['owned'] > 0 ? 1 : 0; // Backward compatibility
            businesses[index].unlocked = businessJson['unlocked'] ?? false;
            businesses[index].secondsSinceLastIncome = businessJson['secondsSinceLastIncome'] ?? 0;
          }
        }
      }
    }

    // Load investments
    if (json['investments'] is List) {
      for (var investmentJson in json['investments']) {
         if (investmentJson is Map && investmentJson['id'] != null) {
          int index = investments.indexWhere((i) => i.id == investmentJson['id']);
          if (index != -1) {
            investments[index].owned = investmentJson['owned'] ?? 0;
            investments[index].currentPrice = investmentJson['currentPrice'] ?? investments[index].basePrice;
            investments[index].purchasePrice = investmentJson['purchasePrice'] ?? 0.0; // Default to 0 if missing

            if (investmentJson['priceHistory'] is List) {
              try {
                investments[index].priceHistory = (investmentJson['priceHistory'] as List).map((e) => (e as num).toDouble()).toList();
              } catch (e) {
                print('Error parsing price history for ${investmentJson['id']}: $e');
                investments[index].priceHistory = List.generate(30, (_) => investments[index].basePrice);
              }
            }
          }
        }
      }
    }

    // Ensure real estate upgrades are initialized before loading state
    if (realEstateInitializationFuture != null) {
      print("⏳ Waiting for real estate initialization before loading saved state...");
      await realEstateInitializationFuture;
      print("✅ Real estate initialization complete. Proceeding with loading saved state.");
    } else {
       print("⚠️ Real estate initialization future was null. Attempting to load state anyway.");
    }


    // Load real estate
    if (json['realEstateLocales'] is List) {
      for (var localeJson in json['realEstateLocales']) {
        if (localeJson is Map && localeJson['id'] != null) {
          int localeIndex = realEstateLocales.indexWhere((l) => l.id == localeJson['id']);
          if (localeIndex != -1) {
            realEstateLocales[localeIndex].unlocked = localeJson['unlocked'] ?? false;
            if (localeJson['properties'] is List) {
              for (var propertyJson in localeJson['properties']) {
                if (propertyJson is Map && propertyJson['id'] != null) {
                  int propertyIndex = realEstateLocales[localeIndex].properties.indexWhere((p) => p.id == propertyJson['id']);
                  if (propertyIndex != -1) {
                    final property = realEstateLocales[localeIndex].properties[propertyIndex];
                    property.owned = propertyJson['owned'] ?? 0;

                    // Load purchased upgrades
                    List<String> purchasedIds = [];
                    if (propertyJson['purchasedUpgradeIds'] is List) {
                       purchasedIds = List<String>.from(propertyJson['purchasedUpgradeIds']);
                    }
                    print("🔧 Loading upgrades for ${property.name}. Found ${purchasedIds.length} saved IDs. Property has ${property.upgrades.length} upgrades in definition.");

                    int appliedCount = 0;
                    for (var upgrade in property.upgrades) {
                      bool shouldBePurchased = purchasedIds.contains(upgrade.id);
                      if (upgrade.purchased != shouldBePurchased) {
                         upgrade.purchased = shouldBePurchased;
                         if (shouldBePurchased) appliedCount++;
                         print("      -> Set purchased=${shouldBePurchased} for upgrade: ${upgrade.id}");
                      }
                    }
                     print("   Applied purchased status to $appliedCount upgrades for ${property.name}.");
                  }
                }
              }
            }
          }
        }
      }
    }


    // Load stats
    if (json['hourlyEarnings'] is Map) {
      try { hourlyEarnings = Map<String, double>.from((json['hourlyEarnings'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble()))); }
      catch (e) { print("Error loading hourlyEarnings: $e. Resetting."); hourlyEarnings = {}; }
    } else { hourlyEarnings = {}; }

    if (json['persistentNetWorthHistory'] is Map) {
       try { persistentNetWorthHistory = Map<int, double>.from((json['persistentNetWorthHistory'] as Map).map((k, v) => MapEntry(int.parse(k.toString()), (v as num).toDouble()))); }
       catch (e) { print("Error loading persistentNetWorthHistory: $e. Resetting."); persistentNetWorthHistory = {}; }
    } else { persistentNetWorthHistory = {}; }


    // Initialize achievements manager *after* loading basic stats but *before* loading achievement status
    achievementManager = AchievementManager(this);

    if (json['achievements'] is List) {
      for (var achievementJson in json['achievements']) {
        if (achievementJson is Map && achievementJson['id'] != null) {
          bool completed = achievementJson['completed'] ?? false;
          if (completed) {
            int index = achievementManager.achievements.indexWhere((a) => a.id == achievementJson['id']);
            if (index != -1) {
              achievementManager.achievements[index].completed = true;
              // Optionally load timestamp if needed:
              // if (achievementJson['completedTimestamp'] != null) {
              //   try { achievementManager.achievements[index].completedTimestamp = DateTime.parse(achievementJson['completedTimestamp']); } catch(_) {}
              // }
            }
          }
        }
      }
    }

    eventsFromJson(json); // Load event system data

    isInitialized = true; // Mark as initialized after loading everything
    notifyListeners();
    print("✅ GameState.fromJson complete.");
  }


  void _processOfflineProgress(int secondsElapsed) {
    final int oneDaysInSeconds = 86400;
    int cappedSeconds = min(secondsElapsed, oneDaysInSeconds);

    print("💵 Processing offline income for ${cappedSeconds} seconds (capped from ${secondsElapsed})");
    print("📊 Time away: ${_formatTimeInterval(secondsElapsed)}");
    print("📊 Income period: ${_formatTimeInterval(cappedSeconds)}");

    double offlineBusinessIncome = 0;
    for (var business in businesses) {
      if (business.level > 0) {
        int cycles = cappedSeconds ~/ business.incomeInterval;
        if (cycles > 0) {
          offlineBusinessIncome += business.getCurrentIncome() * cycles * incomeMultiplier * prestigeMultiplier;
        }
      }
    }
     if (offlineBusinessIncome > 0) {
      money += offlineBusinessIncome;
      totalEarned += offlineBusinessIncome;
      passiveEarnings += offlineBusinessIncome;
    }

    double offlineRealEstateIncome = getRealEstateIncomePerSecond() * cappedSeconds * incomeMultiplier * prestigeMultiplier;
    if (offlineRealEstateIncome > 0) {
      money += offlineRealEstateIncome;
      totalEarned += offlineRealEstateIncome;
      realEstateEarnings += offlineRealEstateIncome;
    }

    double offlineDividendIncome = getTotalDividendIncomePerSecond() * cappedSeconds * incomeMultiplier * prestigeMultiplier;
     if (offlineDividendIncome > 0) {
      money += offlineDividendIncome;
      totalEarned += offlineDividendIncome;
      investmentDividendEarnings += offlineDividendIncome;
    }

    // Note: Timers are typically setup *after* loading state, not necessarily here.
    // Ensure they are running if needed.

    _updateBusinessUnlocks();
    _updateRealEstateUnlocks();

    // Ensure AchievementManager is ready if needed for offline calculations (though usually not)
    // if (achievementManager == null) achievementManager = AchievementManager(this);

    // lastOpened is updated in the caller (fromJson)

    notifyListeners(); // Notify after applying all offline income
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _updateTimer?.cancel();
    _investmentUpdateTimer?.cancel(); // Ensure this timer is cancelled too
    super.dispose();
  }

  void resetToDefaults() {
    money = 500.0;
    totalEarned = 500.0;
    manualEarnings = 0.0;
    passiveEarnings = 0.0;
    investmentEarnings = 0.0;
    investmentDividendEarnings = 0.0;
    realEstateEarnings = 0.0;
    clickValue = 1.5;
    taps = 0;
    clickLevel = 1;
    totalRealEstateUpgradesPurchased = 0;

    // Reset Achievement Tracking Fields
    totalUpgradeSpending = 0.0;
    luxuryUpgradeSpending = 0.0;
    fullyUpgradedPropertyIds = {};
    fullyUpgradedPropertiesPerLocale = {};
    localesWithOneFullyUpgradedProperty = {};
    fullyUpgradedLocales = {};

    // isPremium persists
    lifetimeTaps = 0;
    gameStartTime = DateTime.now();

    lastSaved = DateTime.now();
    lastOpened = DateTime.now();
    currentDay = DateTime.now().weekday;

    incomeMultiplier = 1.0;
    clickMultiplier = 1.0;
    clickBoostEndTime = null;

    prestigeMultiplier = 1.0;
    networkWorth = 0.0;
    reincorporationUsesAvailable = 0;
    totalReincorporations = 0;

    hourlyEarnings = {};
    persistentNetWorthHistory = {};

    activeMarketEvents = [];

    _initializeDefaultBusinesses();
    _initializeDefaultInvestments();
    _initializeRealEstateLocales(); // This creates new instances, effectively resetting ownership and upgrades

    _updateBusinessUnlocks();
    _updateRealEstateUnlocks();

    achievementManager = AchievementManager(this); // Re-initialize achievements

    // Reset Event System
    activeEvents = [];
    lastEventTime = null;
    eventsUnlocked = false;
    recentEventTimes = [];
    businessesOwnedCount = 0;
    localesWithPropertiesCount = 0;
    totalEventsResolved = 0;
    eventsResolvedByTapping = 0;
    eventsResolvedByFee = 0;
    eventFeesSpent = 0.0;
    eventsResolvedByAd = 0;
    eventsResolvedByLocale = {};
    lastEventResolvedTime = null;
    resolvedEvents = [];


    notifyListeners();
    print("Game state reset to defaults");
  }

  bool reincorporate() {
    updateReincorporationUses();
    double currentNetWorth = calculateNetWorth();
    double minRequiredNetWorth = getMinimumNetWorthForReincorporation();

    if (reincorporationUsesAvailable <= 0 && currentNetWorth < minRequiredNetWorth) {
      return false;
    }

    int currentPrestigeLevel = 0;
    if (currentNetWorth >= 1000000.0) {
      currentPrestigeLevel = (log(currentNetWorth / 1000000.0) / log(10)).floor() + 1;
    }

    // Calculate increment based on the level being achieved *now*
    double networkWorthIncrement = currentPrestigeLevel > 0 ? pow(10, currentPrestigeLevel - 1).toDouble() / 100.0 : 0.0;

    networkWorth += networkWorthIncrement; // Persists
    totalReincorporations++; // Increment total count

    int totalAchievedLevels = getAchievedReincorporationLevels(); // Based on new total networkWorth

    // Update multipliers based on *total* achieved levels
    prestigeMultiplier = 1.0 + (0.1 * totalAchievedLevels);
    if (totalAchievedLevels > 0 && prestigeMultiplier < 1.2) {
       prestigeMultiplier = 1.2; // Ensure first level gives at least 1.2x
    }
    incomeMultiplier = pow(1.2, totalAchievedLevels).toDouble(); // Compounding passive bonus


    if (reincorporationUsesAvailable > 0) {
       reincorporationUsesAvailable--; // Consume an available use if one existed
    }

    // Reset basic stats (apply prestige multiplier to starting money)
    money = 500.0 * prestigeMultiplier;
    totalEarned = money;
    manualEarnings = 0.0;
    passiveEarnings = 0.0;
    investmentEarnings = 0.0;
    investmentDividendEarnings = 0.0;
    realEstateEarnings = 0.0;

    // Reset click value based on *persistent* click level and new prestige multiplier
    double baseClickValue = 1.5;
    double levelMultiplier = 1.0 + ((clickLevel - 1) * 0.5);
    clickValue = baseClickValue * levelMultiplier * prestigeMultiplier;

    // Reset taps to start of current level (persists across reincorporation)
    if (clickLevel <= 5) taps = (500 * (clickLevel - 1));
    else if (clickLevel <= 10) taps = 2500 + (750 * (clickLevel - 6)); // 500*5 + 750*(level-6+1)
    else taps = 6250 + (1000 * (clickLevel - 11)); // 2500 + 750*5 + 1000*(level-11+1)


    lastSaved = DateTime.now();
    lastOpened = DateTime.now();
    currentDay = DateTime.now().weekday;

    clickMultiplier = 1.0; // Reset temporary click boost
    clickBoostEndTime = null;

    hourlyEarnings = {};

    activeMarketEvents = [];

    _initializeDefaultBusinesses();
    _initializeDefaultInvestments();
    _resetRealEstateForReincorporation(); // Crucial step

    _updateBusinessUnlocks();
    _updateRealEstateUnlocks();

    // Reset Event System
    activeEvents = [];
    lastEventTime = null;
    eventsUnlocked = false;
    recentEventTimes = [];
    businessesOwnedCount = 0;
    localesWithPropertiesCount = 0;
    totalEventsResolved = 0;
    eventsResolvedByTapping = 0;
    eventsResolvedByFee = 0;
    eventFeesSpent = 0.0;
    eventsResolvedByAd = 0;
    eventsResolvedByLocale = {};
    lastEventResolvedTime = null;
    resolvedEvents = [];


    notifyListeners();
    print("Reincorporated! Network Worth: $networkWorth, Click Multiplier: $prestigeMultiplier, Passive Bonus Multiplier: $incomeMultiplier");
    return true;
  }


  double getMinimumNetWorthForReincorporation() {
    if (reincorporationUsesAvailable > 0) return 0.0;

    int thresholdsUsed = getAchievedReincorporationLevels();
    if (thresholdsUsed >= 9) return double.infinity; // Max 9 levels ($100T)

    double baseRequirement = 1000000.0;
    return baseRequirement * pow(10, thresholdsUsed);
  }

  int getAchievedReincorporationLevels() {
    int levelsAchieved = 0;
    if (networkWorth >= 0.01) levelsAchieved++;    // 1M
    if (networkWorth >= 0.1) levelsAchieved++;     // 10M
    if (networkWorth >= 1.0) levelsAchieved++;     // 100M
    if (networkWorth >= 10.0) levelsAchieved++;    // 1B
    if (networkWorth >= 100.0) levelsAchieved++;   // 10B
    if (networkWorth >= 1000.0) levelsAchieved++;  // 100B
    if (networkWorth >= 10000.0) levelsAchieved++; // 1T
    if (networkWorth >= 100000.0) levelsAchieved++;// 10T
    if (networkWorth >= 1000000.0) levelsAchieved++; // 100T
    return levelsAchieved;
  }

  void updateReincorporationUses() {
    double netWorth = calculateNetWorth();
    double baseRequirement = 1000000.0;

    int totalThresholdsCrossed = 0;
    if (netWorth >= baseRequirement) {
      totalThresholdsCrossed = (log(netWorth / baseRequirement) / log(10)).floor() + 1;
      totalThresholdsCrossed = min(totalThresholdsCrossed, 9); // Cap at 9 levels ($100T)
    }

    int alreadyUsedThresholds = getAchievedReincorporationLevels();
    int newAvailableUses = max(0, totalThresholdsCrossed - alreadyUsedThresholds);

    if (reincorporationUsesAvailable != newAvailableUses) {
       reincorporationUsesAvailable = newAvailableUses;
       notifyListeners(); // Only notify if the value actually changed
    }
  }

  void _initializeRealEstateLocales() {
    realEstateLocales = [
      RealEstateLocale( id: 'rural_kenya', name: 'Rural Kenya', theme: 'Traditional and rural African homes', unlocked: true, icon: Icons.cabin, properties: [
          RealEstateProperty(id: 'mud_hut', name: 'Mud Hut', purchasePrice: 500.0, baseCashFlowPerSecond: 0.5 * 1.15),
          RealEstateProperty(id: 'thatched_cottage', name: 'Thatched Cottage', purchasePrice: 1000.0, baseCashFlowPerSecond: 1.0 * 1.25),
          RealEstateProperty(id: 'brick_shack', name: 'Brick Shack', purchasePrice: 2500.0, baseCashFlowPerSecond: 2.5 * 1.35),
          RealEstateProperty(id: 'solar_powered_hut', name: 'Solar-Powered Hut', purchasePrice: 5000.0, baseCashFlowPerSecond: 5.0 * 1.45),
          RealEstateProperty(id: 'village_compound', name: 'Village Compound', purchasePrice: 10000.0, baseCashFlowPerSecond: 10.0 * 1.55),
          RealEstateProperty(id: 'eco_lodge', name: 'Eco-Lodge', purchasePrice: 25000.0, baseCashFlowPerSecond: 25.0 * 1.65),
          RealEstateProperty(id: 'farmhouse', name: 'Farmhouse', purchasePrice: 50000.0, baseCashFlowPerSecond: 50.0 * 1.75),
          RealEstateProperty(id: 'safari_retreat', name: 'Safari Retreat', purchasePrice: 100000.0, baseCashFlowPerSecond: 100.0 * 1.85),
          RealEstateProperty(id: 'rural_estate', name: 'Rural Estate', purchasePrice: 250000.0, baseCashFlowPerSecond: 250.0 * 1.95),
          RealEstateProperty(id: 'conservation_villa', name: 'Conservation Villa', purchasePrice: 500000.0, baseCashFlowPerSecond: 500.0 * 2.05),
        ],
      ),
      RealEstateLocale( id: 'lagos_nigeria', name: 'Lagos, Nigeria', theme: 'Urban growth and modern apartments', unlocked: false, icon: Icons.apartment, properties: [
          RealEstateProperty(id: 'tin_roof_shack', name: 'Tin-Roof Shack', purchasePrice: 1000.0, baseCashFlowPerSecond: 1.0 * 1.15),
          RealEstateProperty(id: 'concrete_flat', name: 'Concrete Flat', purchasePrice: 2000.0, baseCashFlowPerSecond: 2.0 * 1.25),
          RealEstateProperty(id: 'small_apartment', name: 'Small Apartment', purchasePrice: 5000.0, baseCashFlowPerSecond: 5.0 * 1.35),
          RealEstateProperty(id: 'duplex', name: 'Duplex', purchasePrice: 10000.0, baseCashFlowPerSecond: 10.0 * 1.45),
          RealEstateProperty(id: 'mid_rise_block', name: 'Mid-Rise Block', purchasePrice: 25000.0, baseCashFlowPerSecond: 25.0 * 1.55),
          RealEstateProperty(id: 'gated_complex', name: 'Gated Complex', purchasePrice: 50000.0, baseCashFlowPerSecond: 50.0 * 1.65),
          RealEstateProperty(id: 'high_rise_tower', name: 'High-Rise Tower', purchasePrice: 100000.0, baseCashFlowPerSecond: 100.0 * 1.75),
          RealEstateProperty(id: 'luxury_condo', name: 'Luxury Condo', purchasePrice: 250000.0, baseCashFlowPerSecond: 250.0 * 1.85),
          RealEstateProperty(id: 'business_loft', name: 'Business Loft', purchasePrice: 500000.0, baseCashFlowPerSecond: 500.0 * 1.95),
          RealEstateProperty(id: 'skyline_penthouse', name: 'Skyline Penthouse', purchasePrice: 1000000.0, baseCashFlowPerSecond: 1000.0 * 2.05),
        ],
      ),
      RealEstateLocale( id: 'cape_town_sa', name: 'Cape Town, South Africa', theme: 'Coastal and scenic properties', unlocked: false, icon: Icons.beach_access, properties: [
           RealEstateProperty(id: 'beach_shack', name: 'Beach Shack', purchasePrice: 5000.0, baseCashFlowPerSecond: 5.0 * 1.15),
           RealEstateProperty(id: 'wooden_bungalow', name: 'Wooden Bungalow', purchasePrice: 10000.0, baseCashFlowPerSecond: 10.0 * 1.25),
           RealEstateProperty(id: 'cliffside_cottage', name: 'Cliffside Cottage', purchasePrice: 25000.0, baseCashFlowPerSecond: 25.0 * 1.35),
           RealEstateProperty(id: 'seaview_villa', name: 'Seaview Villa', purchasePrice: 50000.0, baseCashFlowPerSecond: 50.0 * 1.45),
           RealEstateProperty(id: 'modern_beach_house', name: 'Modern Beach House', purchasePrice: 100000.0, baseCashFlowPerSecond: 100.0 * 1.55),
           RealEstateProperty(id: 'coastal_estate', name: 'Coastal Estate', purchasePrice: 250000.0, baseCashFlowPerSecond: 250.0 * 1.65),
           RealEstateProperty(id: 'luxury_retreat', name: 'Luxury Retreat', purchasePrice: 500000.0, baseCashFlowPerSecond: 500.0 * 1.75),
           RealEstateProperty(id: 'oceanfront_mansion', name: 'Oceanfront Mansion', purchasePrice: 1000000.0, baseCashFlowPerSecond: 1000.0 * 1.85),
           RealEstateProperty(id: 'vineyard_manor', name: 'Vineyard Manor', purchasePrice: 2500000.0, baseCashFlowPerSecond: 2500.0 * 1.95),
           RealEstateProperty(id: 'cape_peninsula_chateau', name: 'Cape Peninsula Chateau', purchasePrice: 5000000.0, baseCashFlowPerSecond: 5000.0 * 2.05),
        ],
      ),
      RealEstateLocale( id: 'rural_thailand', name: 'Rural Thailand', theme: 'Tropical and bamboo-based homes', unlocked: false, icon: Icons.holiday_village, properties: [
           RealEstateProperty(id: 'bamboo_hut', name: 'Bamboo Hut', purchasePrice: 750.0, baseCashFlowPerSecond: 0.75 * 1.15),
           RealEstateProperty(id: 'stilt_house', name: 'Stilt House', purchasePrice: 1500.0, baseCashFlowPerSecond: 1.5 * 1.25),
           RealEstateProperty(id: 'teak_cabin', name: 'Teak Cabin', purchasePrice: 3000.0, baseCashFlowPerSecond: 3.0 * 1.35),
           RealEstateProperty(id: 'rice_farmhouse', name: 'Rice Farmhouse', purchasePrice: 7500.0, baseCashFlowPerSecond: 7.5 * 1.45),
           RealEstateProperty(id: 'jungle_bungalow', name: 'Jungle Bungalow', purchasePrice: 15000.0, baseCashFlowPerSecond: 15.0 * 1.55),
           RealEstateProperty(id: 'riverside_villa', name: 'Riverside Villa', purchasePrice: 30000.0, baseCashFlowPerSecond: 30.0 * 1.65),
           RealEstateProperty(id: 'eco_resort', name: 'Eco-Resort', purchasePrice: 75000.0, baseCashFlowPerSecond: 75.0 * 1.75),
           RealEstateProperty(id: 'hilltop_retreat', name: 'Hilltop Retreat', purchasePrice: 150000.0, baseCashFlowPerSecond: 150.0 * 1.85),
           RealEstateProperty(id: 'teak_mansion', name: 'Teak Mansion', purchasePrice: 300000.0, baseCashFlowPerSecond: 300.0 * 1.95),
           RealEstateProperty(id: 'tropical_estate', name: 'Tropical Estate', purchasePrice: 750000.0, baseCashFlowPerSecond: 750.0 * 2.05),
        ],
      ),
      RealEstateLocale( id: 'mumbai_india', name: 'Mumbai, India', theme: 'Dense urban housing with cultural flair', unlocked: false, icon: Icons.location_city, properties: [
           RealEstateProperty(id: 'slum_tenement', name: 'Slum Tenement', purchasePrice: 2000.0, baseCashFlowPerSecond: 2.0 * 1.15),
           RealEstateProperty(id: 'concrete_flat_mumbai', name: 'Concrete Flat', purchasePrice: 4000.0, baseCashFlowPerSecond: 4.0 * 1.25),
           RealEstateProperty(id: 'small_apartment_mumbai', name: 'Small Apartment', purchasePrice: 10000.0, baseCashFlowPerSecond: 10.0 * 1.35),
           RealEstateProperty(id: 'mid_tier_condo', name: 'Mid-Tier Condo', purchasePrice: 20000.0, baseCashFlowPerSecond: 20.0 * 1.45),
           RealEstateProperty(id: 'bollywood_loft', name: 'Bollywood Loft', purchasePrice: 50000.0, baseCashFlowPerSecond: 50.0 * 1.55),
           RealEstateProperty(id: 'high_rise_unit_mumbai', name: 'High-Rise Unit', purchasePrice: 100000.0, baseCashFlowPerSecond: 100.0 * 1.65),
           RealEstateProperty(id: 'gated_tower', name: 'Gated Tower', purchasePrice: 250000.0, baseCashFlowPerSecond: 250.0 * 1.75),
           RealEstateProperty(id: 'luxury_flat_mumbai', name: 'Luxury Flat', purchasePrice: 500000.0, baseCashFlowPerSecond: 500.0 * 1.85),
           RealEstateProperty(id: 'seafront_penthouse', name: 'Seafront Penthouse', purchasePrice: 1000000.0, baseCashFlowPerSecond: 1000.0 * 1.95),
           RealEstateProperty(id: 'mumbai_skyscraper', name: 'Mumbai Skyscraper', purchasePrice: 2000000.0, baseCashFlowPerSecond: 2000.0 * 2.05),
        ],
      ),
      RealEstateLocale( id: 'ho_chi_minh_city', name: 'Ho Chi Minh City, Vietnam', theme: 'Emerging urban and riverfront homes', unlocked: false, icon: Icons.house_siding, properties: [
           RealEstateProperty(id: 'shophouse', name: 'Shophouse', purchasePrice: 3000.0, baseCashFlowPerSecond: 3.0 * 1.15),
           RealEstateProperty(id: 'narrow_flat', name: 'Narrow Flat', purchasePrice: 6000.0, baseCashFlowPerSecond: 6.0 * 1.25),
           RealEstateProperty(id: 'riverside_hut', name: 'Riverside Hut', purchasePrice: 15000.0, baseCashFlowPerSecond: 15.0 * 1.35),
           RealEstateProperty(id: 'modern_apartment_hcmc', name: 'Modern Apartment', purchasePrice: 30000.0, baseCashFlowPerSecond: 30.0 * 1.45),
           RealEstateProperty(id: 'condo_unit_hcmc', name: 'Condo Unit', purchasePrice: 75000.0, baseCashFlowPerSecond: 75.0 * 1.55),
           RealEstateProperty(id: 'riverfront_villa', name: 'Riverfront Villa', purchasePrice: 150000.0, baseCashFlowPerSecond: 150.0 * 1.65),
           RealEstateProperty(id: 'high_rise_suite_hcmc', name: 'High-Rise Suite', purchasePrice: 300000.0, baseCashFlowPerSecond: 300.0 * 1.75),
           RealEstateProperty(id: 'luxury_tower_hcmc', name: 'Luxury Tower', purchasePrice: 750000.0, baseCashFlowPerSecond: 750.0 * 1.85),
           RealEstateProperty(id: 'business_loft_hcmc', name: 'Business Loft', purchasePrice: 1500000.0, baseCashFlowPerSecond: 1500.0 * 1.95),
           RealEstateProperty(id: 'saigon_skyline_estate', name: 'Saigon Skyline Estate', purchasePrice: 3000000.0, baseCashFlowPerSecond: 3000.0 * 2.05),
        ],
      ),
      RealEstateLocale( id: 'singapore', name: 'Singapore', theme: 'Ultra-modern, high-density urban living', unlocked: false, icon: Icons.apartment, properties: [
           RealEstateProperty(id: 'hdb_flat', name: 'HDB Flat', purchasePrice: 50000.0, baseCashFlowPerSecond: 50.0 * 1.15),
           RealEstateProperty(id: 'condo_unit_singapore', name: 'Condo Unit', purchasePrice: 100000.0, baseCashFlowPerSecond: 100.0 * 1.25),
           RealEstateProperty(id: 'executive_apartment', name: 'Executive Apartment', purchasePrice: 250000.0, baseCashFlowPerSecond: 250.0 * 1.35),
           RealEstateProperty(id: 'sky_terrace', name: 'Sky Terrace', purchasePrice: 500000.0, baseCashFlowPerSecond: 500.0 * 1.45),
           RealEstateProperty(id: 'luxury_condo_singapore', name: 'Luxury Condo', purchasePrice: 1000000.0, baseCashFlowPerSecond: 1000.0 * 1.55),
           RealEstateProperty(id: 'marina_view_suite', name: 'Marina View Suite', purchasePrice: 2500000.0, baseCashFlowPerSecond: 2500.0 * 1.65),
           RealEstateProperty(id: 'penthouse_tower_singapore', name: 'Penthouse Tower', purchasePrice: 5000000.0, baseCashFlowPerSecond: 5000.0 * 1.75),
           RealEstateProperty(id: 'sky_villa', name: 'Sky Villa', purchasePrice: 10000000.0, baseCashFlowPerSecond: 10000.0 * 1.85),
           RealEstateProperty(id: 'billionaire_loft_singapore', name: 'Billionaire Loft', purchasePrice: 25000000.0, baseCashFlowPerSecond: 25000.0 * 1.95),
           RealEstateProperty(id: 'iconic_skyscraper_singapore', name: 'Iconic Skyscraper', purchasePrice: 50000000.0, baseCashFlowPerSecond: 50000.0 * 2.05),
        ],
      ),
      RealEstateLocale( id: 'hong_kong', name: 'Hong Kong', theme: 'Compact, premium urban properties', unlocked: false, icon: Icons.location_city, properties: [
           RealEstateProperty(id: 'micro_flat', name: 'Micro-Flat', purchasePrice: 75000.0, baseCashFlowPerSecond: 75.0 * 1.15),
           RealEstateProperty(id: 'small_apartment_hk', name: 'Small Apartment', purchasePrice: 150000.0, baseCashFlowPerSecond: 150.0 * 1.25),
           RealEstateProperty(id: 'mid_rise_unit', name: 'Mid-Rise Unit', purchasePrice: 300000.0, baseCashFlowPerSecond: 300.0 * 1.35),
           RealEstateProperty(id: 'harbor_view_flat', name: 'Harbor View Flat', purchasePrice: 750000.0, baseCashFlowPerSecond: 750.0 * 1.45),
           RealEstateProperty(id: 'luxury_condo_hk', name: 'Luxury Condo', purchasePrice: 1500000.0, baseCashFlowPerSecond: 1500.0 * 1.55),
           RealEstateProperty(id: 'peak_villa', name: 'Peak Villa', purchasePrice: 3000000.0, baseCashFlowPerSecond: 3000.0 * 1.65),
           RealEstateProperty(id: 'skyline_suite_hk', name: 'Skyline Suite', purchasePrice: 7500000.0, baseCashFlowPerSecond: 7500.0 * 1.75),
           RealEstateProperty(id: 'penthouse_tower_hk', name: 'Penthouse Tower', purchasePrice: 15000000.0, baseCashFlowPerSecond: 15000.0 * 1.85),
           RealEstateProperty(id: 'billionaire_mansion', name: 'Billionaire Mansion', purchasePrice: 30000000.0, baseCashFlowPerSecond: 30000.0 * 1.95),
           RealEstateProperty(id: 'victoria_peak_estate', name: 'Victoria Peak Estate', purchasePrice: 75000000.0, baseCashFlowPerSecond: 75000.0 * 2.05),
        ],
      ),
      RealEstateLocale( id: 'lisbon_portugal', name: 'Lisbon, Portugal', theme: 'Historic and coastal European homes', unlocked: false, icon: Icons.villa, properties: [
           RealEstateProperty(id: 'stone_cottage', name: 'Stone Cottage', purchasePrice: 10000.0, baseCashFlowPerSecond: 10.0 * 1.15),
           RealEstateProperty(id: 'townhouse', name: 'Townhouse', purchasePrice: 20000.0, baseCashFlowPerSecond: 20.0 * 1.25),
           RealEstateProperty(id: 'riverside_flat', name: 'Riverside Flat', purchasePrice: 50000.0, baseCashFlowPerSecond: 50.0 * 1.35),
           RealEstateProperty(id: 'renovated_villa', name: 'Renovated Villa', purchasePrice: 100000.0, baseCashFlowPerSecond: 100.0 * 1.45),
           RealEstateProperty(id: 'coastal_bungalow', name: 'Coastal Bungalow', purchasePrice: 250000.0, baseCashFlowPerSecond: 250.0 * 1.55),
           RealEstateProperty(id: 'luxury_apartment_lisbon', name: 'Luxury Apartment', purchasePrice: 500000.0, baseCashFlowPerSecond: 500.0 * 1.65),
           RealEstateProperty(id: 'historic_manor', name: 'Historic Manor', purchasePrice: 1000000.0, baseCashFlowPerSecond: 1000.0 * 1.75),
           RealEstateProperty(id: 'seaside_mansion', name: 'Seaside Mansion', purchasePrice: 2500000.0, baseCashFlowPerSecond: 2500.0 * 1.85),
           RealEstateProperty(id: 'cliffside_estate', name: 'Cliffside Estate', purchasePrice: 5000000.0, baseCashFlowPerSecond: 5000.0 * 1.95),
           RealEstateProperty(id: 'lisbon_palace', name: 'Lisbon Palace', purchasePrice: 10000000.0, baseCashFlowPerSecond: 10000.0 * 2.05),
        ],
      ),
      RealEstateLocale( id: 'bucharest_romania', name: 'Bucharest, Romania', theme: 'Affordable Eastern European urban growth', unlocked: false, icon: Icons.apartment, properties: [
           RealEstateProperty(id: 'panel_flat', name: 'Panel Flat', purchasePrice: 7500.0, baseCashFlowPerSecond: 7.5 * 1.15),
           RealEstateProperty(id: 'brick_apartment', name: 'Brick Apartment', purchasePrice: 15000.0, baseCashFlowPerSecond: 15.0 * 1.25),
           RealEstateProperty(id: 'modern_condo_bucharest', name: 'Modern Condo', purchasePrice: 30000.0, baseCashFlowPerSecond: 30.0 * 1.35),
           RealEstateProperty(id: 'renovated_loft', name: 'Renovated Loft', purchasePrice: 75000.0, baseCashFlowPerSecond: 75.0 * 1.45),
           RealEstateProperty(id: 'gated_unit', name: 'Gated Unit', purchasePrice: 150000.0, baseCashFlowPerSecond: 150.0 * 1.55),
           RealEstateProperty(id: 'high_rise_suite_bucharest', name: 'High-Rise Suite', purchasePrice: 300000.0, baseCashFlowPerSecond: 300.0 * 1.65),
           RealEstateProperty(id: 'luxury_flat_bucharest', name: 'Luxury Flat', purchasePrice: 750000.0, baseCashFlowPerSecond: 750.0 * 1.75),
           RealEstateProperty(id: 'urban_villa', name: 'Urban Villa', purchasePrice: 1500000.0, baseCashFlowPerSecond: 1500.0 * 1.85),
           RealEstateProperty(id: 'city_penthouse', name: 'City Penthouse', purchasePrice: 3000000.0, baseCashFlowPerSecond: 3000.0 * 1.95),
           RealEstateProperty(id: 'bucharest_tower', name: 'Bucharest Tower', purchasePrice: 7500000.0, baseCashFlowPerSecond: 7500.0 * 2.05),
        ],
      ),
      RealEstateLocale( id: 'berlin_germany', name: 'Berlin, Germany', theme: 'Creative and industrial-chic properties', unlocked: false, icon: Icons.house_siding, properties: [
           RealEstateProperty(id: 'studio_flat', name: 'Studio Flat', purchasePrice: 25000.0, baseCashFlowPerSecond: 25.0 * 1.15),
           RealEstateProperty(id: 'loft_space', name: 'Loft Space', purchasePrice: 50000.0, baseCashFlowPerSecond: 50.0 * 1.25),
           RealEstateProperty(id: 'renovated_warehouse', name: 'Renovated Warehouse', purchasePrice: 100000.0, baseCashFlowPerSecond: 100.0 * 1.35),
           RealEstateProperty(id: 'modern_apartment_berlin', name: 'Modern Apartment', purchasePrice: 250000.0, baseCashFlowPerSecond: 250.0 * 1.45),
           RealEstateProperty(id: 'artist_condo', name: 'Artist Condo', purchasePrice: 500000.0, baseCashFlowPerSecond: 500.0 * 1.55),
           RealEstateProperty(id: 'riverfront_suite', name: 'Riverfront Suite', purchasePrice: 1000000.0, baseCashFlowPerSecond: 1000.0 * 1.65),
           RealEstateProperty(id: 'luxury_loft', name: 'Luxury Loft', purchasePrice: 2500000.0, baseCashFlowPerSecond: 2500.0 * 1.75),
           RealEstateProperty(id: 'high_rise_tower_berlin', name: 'High-Rise Tower', purchasePrice: 5000000.0, baseCashFlowPerSecond: 5000.0 * 1.85),
           RealEstateProperty(id: 'tech_villa', name: 'Tech Villa', purchasePrice: 10000000.0, baseCashFlowPerSecond: 10000.0 * 1.95),
           RealEstateProperty(id: 'berlin_skyline_estate', name: 'Berlin Skyline Estate', purchasePrice: 25000000.0, baseCashFlowPerSecond: 25000.0 * 2.05),
        ],
      ),
      RealEstateLocale( id: 'london_uk', name: 'London, UK', theme: 'Historic and ultra-premium urban homes', unlocked: false, icon: Icons.location_city, properties: [
           RealEstateProperty(id: 'council_flat', name: 'Council Flat', purchasePrice: 40000.0, baseCashFlowPerSecond: 40.0 * 1.15),
           RealEstateProperty(id: 'terraced_house', name: 'Terraced House', purchasePrice: 80000.0, baseCashFlowPerSecond: 80.0 * 1.25),
           RealEstateProperty(id: 'georgian_townhouse', name: 'Georgian Townhouse', purchasePrice: 200000.0, baseCashFlowPerSecond: 200.0 * 1.35),
           RealEstateProperty(id: 'modern_condo_london', name: 'Modern Condo', purchasePrice: 400000.0, baseCashFlowPerSecond: 400.0 * 1.45),
           RealEstateProperty(id: 'riverside_apartment', name: 'Riverside Apartment', purchasePrice: 1000000.0, baseCashFlowPerSecond: 1000.0 * 1.55),
           RealEstateProperty(id: 'luxury_flat_london', name: 'Luxury Flat', purchasePrice: 2000000.0, baseCashFlowPerSecond: 2000.0 * 1.65),
           RealEstateProperty(id: 'mayfair_mansion', name: 'Mayfair Mansion', purchasePrice: 5000000.0, baseCashFlowPerSecond: 5000.0 * 1.75),
           RealEstateProperty(id: 'skyline_penthouse_london', name: 'Skyline Penthouse', purchasePrice: 10000000.0, baseCashFlowPerSecond: 10000.0 * 1.85),
           RealEstateProperty(id: 'historic_estate', name: 'Historic Estate', purchasePrice: 25000000.0, baseCashFlowPerSecond: 25000.0 * 1.95),
           RealEstateProperty(id: 'london_iconic_tower', name: 'London Iconic Tower', purchasePrice: 50000000.0, baseCashFlowPerSecond: 50000.0 * 2.05),
        ],
      ),
      RealEstateLocale( id: 'rural_mexico', name: 'Rural Mexico', theme: 'Rustic and affordable Latin American homes', unlocked: false, icon: Icons.holiday_village, properties: [
           RealEstateProperty(id: 'adobe_hut', name: 'Adobe Hut', purchasePrice: 600.0, baseCashFlowPerSecond: 0.6 * 1.15),
           RealEstateProperty(id: 'clay_house', name: 'Clay House', purchasePrice: 1200.0, baseCashFlowPerSecond: 1.2 * 1.25),
           RealEstateProperty(id: 'brick_cottage_mexico', name: 'Brick Cottage', purchasePrice: 3000.0, baseCashFlowPerSecond: 3.0 * 1.35),
           RealEstateProperty(id: 'hacienda_bungalow', name: 'Hacienda Bungalow', purchasePrice: 6000.0, baseCashFlowPerSecond: 6.0 * 1.45),
           RealEstateProperty(id: 'village_flat', name: 'Village Flat', purchasePrice: 15000.0, baseCashFlowPerSecond: 15.0 * 1.55),
           RealEstateProperty(id: 'rural_villa', name: 'Rural Villa', purchasePrice: 30000.0, baseCashFlowPerSecond: 30.0 * 1.65),
           RealEstateProperty(id: 'eco_casa', name: 'Eco-Casa', purchasePrice: 75000.0, baseCashFlowPerSecond: 75.0 * 1.75),
           RealEstateProperty(id: 'farmstead', name: 'Farmstead', purchasePrice: 150000.0, baseCashFlowPerSecond: 150.0 * 1.85),
           RealEstateProperty(id: 'countryside_estate', name: 'Countryside Estate', purchasePrice: 300000.0, baseCashFlowPerSecond: 300.0 * 1.95),
           RealEstateProperty(id: 'hacienda_grande', name: 'Hacienda Grande', purchasePrice: 600000.0, baseCashFlowPerSecond: 600.0 * 2.05),
        ],
      ),
      RealEstateLocale( id: 'mexico_city', name: 'Mexico City, Mexico', theme: 'Urban sprawl with colonial charm', unlocked: false, icon: Icons.location_city, properties: [
           RealEstateProperty(id: 'barrio_flat', name: 'Barrio Flat', purchasePrice: 4000.0, baseCashFlowPerSecond: 4.0 * 1.15),
           RealEstateProperty(id: 'concrete_unit_mexico', name: 'Concrete Unit', purchasePrice: 8000.0, baseCashFlowPerSecond: 8.0 * 1.25),
           RealEstateProperty(id: 'colonial_house', name: 'Colonial House', purchasePrice: 20000.0, baseCashFlowPerSecond: 20.0 * 1.35),
           RealEstateProperty(id: 'mid_rise_apartment', name: 'Mid-Rise Apartment', purchasePrice: 40000.0, baseCashFlowPerSecond: 40.0 * 1.45),
           RealEstateProperty(id: 'gated_condo', name: 'Gated Condo', purchasePrice: 100000.0, baseCashFlowPerSecond: 100.0 * 1.55),
           RealEstateProperty(id: 'modern_loft_mexico', name: 'Modern Loft', purchasePrice: 200000.0, baseCashFlowPerSecond: 200.0 * 1.65),
           RealEstateProperty(id: 'luxury_suite_mexico', name: 'Luxury Suite', purchasePrice: 500000.0, baseCashFlowPerSecond: 500.0 * 1.75),
           RealEstateProperty(id: 'high_rise_tower_mexico', name: 'High-Rise Tower', purchasePrice: 1000000.0, baseCashFlowPerSecond: 1000.0 * 1.85),
           RealEstateProperty(id: 'historic_penthouse', name: 'Historic Penthouse', purchasePrice: 2000000.0, baseCashFlowPerSecond: 2000.0 * 1.95),
           RealEstateProperty(id: 'mexico_city_skyline', name: 'Mexico City Skyline', purchasePrice: 4000000.0, baseCashFlowPerSecond: 4000.0 * 2.05),
        ],
      ),
      RealEstateLocale( id: 'miami_florida', name: 'Miami, Florida', theme: 'Coastal and flashy U.S. properties', unlocked: false, icon: Icons.beach_access, properties: [
           RealEstateProperty(id: 'beach_condo', name: 'Beach Condo', purchasePrice: 30000.0, baseCashFlowPerSecond: 30.0 * 1.15),
           RealEstateProperty(id: 'bungalow', name: 'Bungalow', purchasePrice: 60000.0, baseCashFlowPerSecond: 60.0 * 1.25),
           RealEstateProperty(id: 'oceanfront_flat', name: 'Oceanfront Flat', purchasePrice: 150000.0, baseCashFlowPerSecond: 150.0 * 1.35),
           RealEstateProperty(id: 'modern_villa_miami', name: 'Modern Villa', purchasePrice: 300000.0, baseCashFlowPerSecond: 300.0 * 1.45),
           RealEstateProperty(id: 'luxury_condo_miami', name: 'Luxury Condo', purchasePrice: 750000.0, baseCashFlowPerSecond: 750.0 * 1.55),
           RealEstateProperty(id: 'miami_beach_house', name: 'Miami Beach House', purchasePrice: 1500000.0, baseCashFlowPerSecond: 1500.0 * 1.65),
           RealEstateProperty(id: 'high_rise_suite_miami', name: 'High-Rise Suite', purchasePrice: 3000000.0, baseCashFlowPerSecond: 3000.0 * 1.75),
           RealEstateProperty(id: 'skyline_penthouse_miami', name: 'Skyline Penthouse', purchasePrice: 7500000.0, baseCashFlowPerSecond: 7500.0 * 1.85),
           RealEstateProperty(id: 'waterfront_mansion', name: 'Waterfront Mansion', purchasePrice: 15000000.0, baseCashFlowPerSecond: 15000.0 * 1.95),
           RealEstateProperty(id: 'miami_iconic_estate', name: 'Miami Iconic Estate', purchasePrice: 30000000.0, baseCashFlowPerSecond: 30000.0 * 2.05),
        ],
      ),
      RealEstateLocale( id: 'new_york_city', name: 'New York City, NY', theme: 'Iconic U.S. urban real estate', unlocked: false, icon: Icons.location_city, properties: [
           RealEstateProperty(id: 'studio_apartment', name: 'Studio Apartment', purchasePrice: 60000.0, baseCashFlowPerSecond: 60.0 * 1.15),
           RealEstateProperty(id: 'brownstone_flat', name: 'Brownstone Flat', purchasePrice: 120000.0, baseCashFlowPerSecond: 120.0 * 1.25),
           RealEstateProperty(id: 'midtown_condo', name: 'Midtown Condo', purchasePrice: 300000.0, baseCashFlowPerSecond: 300.0 * 1.35),
           RealEstateProperty(id: 'luxury_loft_nyc', name: 'Luxury Loft', purchasePrice: 600000.0, baseCashFlowPerSecond: 600.0 * 1.45),
           RealEstateProperty(id: 'high_rise_unit_nyc', name: 'High-Rise Unit', purchasePrice: 1500000.0, baseCashFlowPerSecond: 1500.0 * 1.55),
           RealEstateProperty(id: 'manhattan_suite', name: 'Manhattan Suite', purchasePrice: 3000000.0, baseCashFlowPerSecond: 3000.0 * 1.65),
           RealEstateProperty(id: 'skyline_penthouse_nyc', name: 'Skyline Penthouse', purchasePrice: 7500000.0, baseCashFlowPerSecond: 7500.0 * 1.75),
           RealEstateProperty(id: 'central_park_view', name: 'Central Park View', purchasePrice: 15000000.0, baseCashFlowPerSecond: 15000.0 * 1.85),
           RealEstateProperty(id: 'billionaire_tower', name: 'Billionaire Tower', purchasePrice: 30000000.0, baseCashFlowPerSecond: 30000.0 * 1.95),
           RealEstateProperty(id: 'nyc_landmark_estate', name: 'NYC Landmark Estate', purchasePrice: 60000000.0, baseCashFlowPerSecond: 60000.0 * 2.05),
        ],
      ),
      RealEstateLocale( id: 'los_angeles', name: 'Los Angeles, CA', theme: 'Hollywood and luxury U.S. homes', unlocked: false, icon: Icons.villa, properties: [
           RealEstateProperty(id: 'studio_bungalow', name: 'Studio Bungalow', purchasePrice: 50000.0, baseCashFlowPerSecond: 50.0 * 1.15),
           RealEstateProperty(id: 'hillside_flat', name: 'Hillside Flat', purchasePrice: 100000.0, baseCashFlowPerSecond: 100.0 * 1.25),
           RealEstateProperty(id: 'modern_condo_la', name: 'Modern Condo', purchasePrice: 250000.0, baseCashFlowPerSecond: 250.0 * 1.35),
           RealEstateProperty(id: 'hollywood_villa', name: 'Hollywood Villa', purchasePrice: 500000.0, baseCashFlowPerSecond: 500.0 * 1.45),
           RealEstateProperty(id: 'luxury_loft_la', name: 'Luxury Loft', purchasePrice: 1000000.0, baseCashFlowPerSecond: 1000.0 * 1.55),
           RealEstateProperty(id: 'beverly_hills_house', name: 'Beverly Hills House', purchasePrice: 2500000.0, baseCashFlowPerSecond: 2500.0 * 1.65),
           RealEstateProperty(id: 'celebrity_mansion', name: 'Celebrity Mansion', purchasePrice: 5000000.0, baseCashFlowPerSecond: 5000.0 * 1.75),
           RealEstateProperty(id: 'skyline_penthouse_la', name: 'Skyline Penthouse', purchasePrice: 10000000.0, baseCashFlowPerSecond: 10000.0 * 1.85),
           RealEstateProperty(id: 'oceanfront_estate', name: 'Oceanfront Estate', purchasePrice: 25000000.0, baseCashFlowPerSecond: 25000.0 * 1.95),
           RealEstateProperty(id: 'la_iconic_compound', name: 'LA Iconic Compound', purchasePrice: 50000000.0, baseCashFlowPerSecond: 50000.0 * 2.05),
        ],
      ),
      RealEstateLocale( id: 'lima_peru', name: 'Lima, Peru', theme: 'Andean urban and coastal homes', unlocked: false, icon: Icons.house_siding, properties: [
           RealEstateProperty(id: 'adobe_flat', name: 'Adobe Flat', purchasePrice: 2500.0, baseCashFlowPerSecond: 2.5 * 1.15),
           RealEstateProperty(id: 'brick_house_lima', name: 'Brick House', purchasePrice: 5000.0, baseCashFlowPerSecond: 5.0 * 1.25),
           RealEstateProperty(id: 'coastal_shack', name: 'Coastal Shack', purchasePrice: 12500.0, baseCashFlowPerSecond: 12.5 * 1.35),
           RealEstateProperty(id: 'modern_apartment_lima', name: 'Modern Apartment', purchasePrice: 25000.0, baseCashFlowPerSecond: 25.0 * 1.45),
           RealEstateProperty(id: 'gated_unit_lima', name: 'Gated Unit', purchasePrice: 50000.0, baseCashFlowPerSecond: 50.0 * 1.55),
           RealEstateProperty(id: 'andean_villa', name: 'Andean Villa', purchasePrice: 125000.0, baseCashFlowPerSecond: 125.0 * 1.65),
           RealEstateProperty(id: 'luxury_condo_lima', name: 'Luxury Condo', purchasePrice: 250000.0, baseCashFlowPerSecond: 250.0 * 1.75),
           RealEstateProperty(id: 'high_rise_suite_lima', name: 'High-Rise Suite', purchasePrice: 500000.0, baseCashFlowPerSecond: 500.0 * 1.85),
           RealEstateProperty(id: 'oceanfront_loft', name: 'Oceanfront Loft', purchasePrice: 1000000.0, baseCashFlowPerSecond: 1000.0 * 1.95),
           RealEstateProperty(id: 'lima_skyline_estate', name: 'Lima Skyline Estate', purchasePrice: 2500000.0, baseCashFlowPerSecond: 2500.0 * 2.05),
        ],
      ),
      RealEstateLocale( id: 'sao_paulo_brazil', name: 'Sao Paulo, Brazil', theme: 'Sprawling South American metropolis', unlocked: false, icon: Icons.location_city, properties: [
           RealEstateProperty(id: 'favela_hut', name: 'Favela Hut', purchasePrice: 3500.0, baseCashFlowPerSecond: 3.5 * 1.15),
           RealEstateProperty(id: 'concrete_flat_sao_paulo', name: 'Concrete Flat', purchasePrice: 7000.0, baseCashFlowPerSecond: 7.0 * 1.25),
           RealEstateProperty(id: 'small_apartment_sao_paulo', name: 'Small Apartment', purchasePrice: 17500.0, baseCashFlowPerSecond: 17.5 * 1.35),
           RealEstateProperty(id: 'mid_rise_condo', name: 'Mid-Rise Condo', purchasePrice: 35000.0, baseCashFlowPerSecond: 35.0 * 1.45),
           RealEstateProperty(id: 'gated_tower_sao_paulo', name: 'Gated Tower', purchasePrice: 75000.0, baseCashFlowPerSecond: 75.0 * 1.55),
           RealEstateProperty(id: 'luxury_unit', name: 'Luxury Unit', purchasePrice: 150000.0, baseCashFlowPerSecond: 150.0 * 1.65),
           RealEstateProperty(id: 'high_rise_suite_sao_paulo', name: 'High-Rise Suite', purchasePrice: 375000.0, baseCashFlowPerSecond: 375.0 * 1.75),
           RealEstateProperty(id: 'skyline_penthouse_sao_paulo', name: 'Skyline Penthouse', purchasePrice: 750000.0, baseCashFlowPerSecond: 750.0 * 1.85),
           RealEstateProperty(id: 'business_loft_sao_paulo', name: 'Business Loft', purchasePrice: 1500000.0, baseCashFlowPerSecond: 1500.0 * 1.95),
           RealEstateProperty(id: 'sao_paulo_iconic_tower', name: 'Sao Paulo Iconic Tower', purchasePrice: 3000000.0, baseCashFlowPerSecond: 3000.0 * 2.05),
        ],
      ),
      RealEstateLocale( id: 'dubai_uae', name: 'Dubai, UAE', theme: 'Flashy desert luxury properties', unlocked: false, icon: Icons.location_city, properties: [
           RealEstateProperty(id: 'desert_apartment', name: 'Desert Apartment', purchasePrice: 35000.0, baseCashFlowPerSecond: 35.0 * 1.15),
           RealEstateProperty(id: 'modern_condo_dubai', name: 'Modern Condo', purchasePrice: 70000.0, baseCashFlowPerSecond: 70.0 * 1.25),
           RealEstateProperty(id: 'palm_villa', name: 'Palm Villa', purchasePrice: 175000.0, baseCashFlowPerSecond: 175.0 * 1.35),
           RealEstateProperty(id: 'luxury_flat_dubai', name: 'Luxury Flat', purchasePrice: 350000.0, baseCashFlowPerSecond: 350.0 * 1.45),
           RealEstateProperty(id: 'high_rise_suite_dubai', name: 'High-Rise Suite', purchasePrice: 750000.0, baseCashFlowPerSecond: 750.0 * 1.55),
           RealEstateProperty(id: 'burj_tower_unit', name: 'Burj Tower Unit', purchasePrice: 1500000.0, baseCashFlowPerSecond: 1500.0 * 1.65),
           RealEstateProperty(id: 'skyline_mansion', name: 'Skyline Mansion', purchasePrice: 3750000.0, baseCashFlowPerSecond: 3750.0 * 1.75),
           RealEstateProperty(id: 'island_retreat', name: 'Island Retreat', purchasePrice: 7500000.0, baseCashFlowPerSecond: 7500.0 * 1.85),
           RealEstateProperty(id: 'billionaire_penthouse_dubai', name: 'Billionaire Penthouse', purchasePrice: 15000000.0, baseCashFlowPerSecond: 15000.0 * 1.95),
           RealEstateProperty(id: 'dubai_iconic_skyscraper', name: 'Dubai Iconic Skyscraper', purchasePrice: 35000000.0, baseCashFlowPerSecond: 35000.0 * 2.05),
        ],
      ),
    ];
  }

  void _updateRealEstateUnlocks() {
    localesWithPropertiesCount = realEstateLocales.where((l) => l.getTotalPropertiesOwned() > 0).length;

    bool hasAnyBusiness = businesses.any((b) => b.level > 0);
    if (!hasAnyBusiness && money < 10000) return; // Early exit if no business and low money

    bool changed = false;
    Map<double, List<String>> unlockThresholds = {
       10000: ['lagos_nigeria', 'rural_thailand', 'rural_mexico'],
       50000: ['cape_town_sa', 'mumbai_india', 'ho_chi_minh_city', 'bucharest_romania', 'lima_peru', 'sao_paulo_brazil'],
      250000: ['lisbon_portugal', 'berlin_germany', 'mexico_city'],
     1000000: ['singapore', 'london_uk', 'miami_florida', 'new_york_city', 'los_angeles'],
     5000000: ['hong_kong', 'dubai_uae'],
    };

    for (var locale in realEstateLocales) {
       if (!locale.unlocked) {
          bool shouldUnlock = false;
          // Check thresholds (only if player has a business OR starting money > 10k)
          if (hasAnyBusiness || money >= 10000) {
              for (var entry in unlockThresholds.entries) {
                if (money >= entry.key && entry.value.contains(locale.id)) {
                  shouldUnlock = true;
                  break;
                }
              }
          }
          if (shouldUnlock) {
            locale.unlocked = true;
            changed = true;
          }
       }
    }

    if (changed) {
      notifyListeners();
    }
  }

  void _unlockLocalesById(List<String> localeIds) {
     bool changed = false;
     for (String id in localeIds) {
       int index = realEstateLocales.indexWhere((l) => l.id == id);
       if (index != -1 && !realEstateLocales[index].unlocked) {
         realEstateLocales[index].unlocked = true;
         changed = true;
       }
     }
     // No notifyListeners() here; called by parent _updateRealEstateUnlocks if needed
  }


  double getRealEstateIncomePerSecond() {
    double total = 0.0;
    for (var locale in realEstateLocales) {
      bool hasLocaleEvent = hasActiveEventForLocale(locale.id);
      total += locale.getTotalIncomePerSecond(affectedByEvent: hasLocaleEvent);
    }
    return total;
  }

  double getTotalDividendIncomePerSecond() {
    double total = 0.0;
    for (var investment in investments) {
      if (investment.owned > 0 && investment.hasDividends()) {
        total += investment.getDividendIncomePerSecond();
      }
    }
    return total;
  }

  double calculateTotalIncomePerSecond() {
    double businessInc = businesses.fold(0.0, (sum, b) => sum + (b.level > 0 ? b.getIncomePerSecond() : 0.0)) * incomeMultiplier * prestigeMultiplier;
    double realEstateInc = getRealEstateIncomePerSecond() * incomeMultiplier * prestigeMultiplier;
    double dividendInc = getTotalDividendIncomePerSecond() * incomeMultiplier * prestigeMultiplier;
    return businessInc + realEstateInc + dividendInc;
  }

  double getBusinessIncomePerSecond() {
     return businesses.fold(0.0, (sum, b) => sum + (b.level > 0 ? b.getIncomePerSecond() : 0.0)) * incomeMultiplier * prestigeMultiplier;
  }

  Map<String, double> getCombinedIncomeBreakdown() {
    double businessIncome = getBusinessIncomePerSecond(); // Already includes multipliers
    double realEstateIncome = getRealEstateIncomePerSecond() * incomeMultiplier * prestigeMultiplier;
    double investmentIncome = getTotalDividendIncomePerSecond() * incomeMultiplier * prestigeMultiplier;
    return {
      'business': businessIncome,
      'realEstate': realEstateIncome,
      'investment': investmentIncome,
      'total': businessIncome + realEstateIncome + investmentIncome,
    };
  }

  bool buyRealEstateProperty(String localeId, String propertyId) {
    final localeIndex = realEstateLocales.indexWhere((l) => l.id == localeId);
    if (localeIndex == -1) return false;
    final propertyIndex = realEstateLocales[localeIndex].properties.indexWhere((p) => p.id == propertyId);
    if (propertyIndex == -1) return false;

    final property = realEstateLocales[localeIndex].properties[propertyIndex];
    if (money < property.purchasePrice) return false;

    money -= property.purchasePrice;
    property.owned++;
    notifyListeners();
    return true;
  }

  bool purchasePropertyUpgrade(String localeId, String propertyId, String upgradeId) {
    print("🛒 Attempting purchase: Loc: $localeId, Prop: $propertyId, Upg: $upgradeId");
    final localeIndex = realEstateLocales.indexWhere((l) => l.id == localeId);
    if (localeIndex == -1) { print("❌ Locale not found"); return false; }
    final locale = realEstateLocales[localeIndex];

    final propertyIndex = locale.properties.indexWhere((p) => p.id == propertyId);
    if (propertyIndex == -1) { print("❌ Property not found"); return false; }
    final property = locale.properties[propertyIndex];
    print("🏠 Found property: ${property.name}");

    if (property.owned <= 0) { print("❌ Property not owned"); return false; }

    final upgradeIndex = property.upgrades.indexWhere((u) => u.id == upgradeId);
    if (upgradeIndex == -1) {
       print("❌ Upgrade not found: $upgradeId in ${property.name}");
       print("   Available: ${property.upgrades.map((u)=>u.id).join(', ')}");
       return false;
    }
    final upgrade = property.upgrades[upgradeIndex];
    print("🔍 Found upgrade: ${upgrade.description}");

    if (upgrade.purchased) { print("❌ Already purchased"); return false; }
    if (money < upgrade.cost) { print("❌ Insufficient funds"); return false; }

    print("💰 Purchasing: ${upgrade.description} for \$${upgrade.cost}. Money before: $money");
    money -= upgrade.cost;
    upgrade.purchased = true;
    print("✅ Purchased! Money after: $money. New income: \$${property.cashFlowPerSecond}/sec");

    // Update stats
    totalRealEstateUpgradesPurchased++;
    totalUpgradeSpending += upgrade.cost;
    if (property.purchasePrice >= 1000000.0) {
      luxuryUpgradeSpending += upgrade.cost;
    }

    if (property.allUpgradesPurchased) {
      print("✨ Property fully upgraded: ${property.name}");
      fullyUpgradedPropertyIds.add(property.id);
      localesWithOneFullyUpgradedProperty.add(locale.id);
      fullyUpgradedPropertiesPerLocale[locale.id] = (fullyUpgradedPropertiesPerLocale[locale.id] ?? 0) + 1;
      print("   Locale ${locale.name} upgrades count: ${fullyUpgradedPropertiesPerLocale[locale.id]}");

      if (locale.properties.every((p) => p.owned > 0 && p.allUpgradesPurchased)) {
        print("🌟 Entire locale fully upgraded: ${locale.name}");
        fullyUpgradedLocales.add(locale.id);
      }
    }

    // Check achievements
    List<Achievement> newlyCompleted = achievementManager.evaluateAchievements(this);
    if (newlyCompleted.isNotEmpty) {
      print("🏆 Achievements completed: ${newlyCompleted.map((a) => a.name).join(', ')}");
      queueAchievementsForDisplay(newlyCompleted);
    }

    notifyListeners();
    return true;
  }

  int getTotalOwnedProperties() {
     return realEstateLocales.fold(0, (sum, locale) => sum + locale.getTotalPropertiesOwned());
  }

  List<Map<String, dynamic>> getAllOwnedPropertiesWithDetails() {
    List<Map<String, dynamic>> result = [];
    for (var locale in realEstateLocales) {
      for (var property in locale.properties) {
        if (property.owned > 0) {
          result.add({
            'property': property, 'locale': locale, 'localeId': locale.id, 'propertyId': property.id,
            'propertyName': property.name, 'localeName': locale.name, 'owned': property.owned,
          });
        }
      }
    }
    return result;
  }

  bool ownsAllProperties() {
    if (realEstateLocales.isEmpty) return false;
    return realEstateLocales.every((locale) => locale.properties.every((property) => property.owned > 0));
  }

  bool hasCombinedIncomeOfAmount(double threshold) {
    Map<String, double> income = getCombinedIncomeBreakdown();
    return income['business']! >= threshold && income['realEstate']! >= threshold && income['investment']! >= threshold;
  }

  List<RealEstateProperty> _getTopPropertiesByValue(RealEstateLocale locale) {
    List<RealEstateProperty> owned = locale.properties.where((p) => p.owned > 0).toList();
    if (owned.isEmpty) return [];
    owned.sort((a, b) => b.purchasePrice.compareTo(a.purchasePrice));
    int count = (owned.length / 2).ceil();
    return owned.take(count).toList();
  }

  void _resetRealEstateForReincorporation() {
     for (var locale in realEstateLocales) {
      for (var property in locale.properties) {
        property.owned = 0;
        // Reset purchased status of existing upgrades
        for (var upgrade in property.upgrades) {
          upgrade.purchased = false;
        }
      }
      // Optionally reset locale unlocked status based on game rules
      // locale.unlocked = (locale.id == 'rural_kenya'); // Example: only unlock the first one
    }
     // Re-initialize locales and their properties to ensure clean state
     _initializeRealEstateLocales();
     // Immediately apply upgrades again as they are part of the definition now
     // but their 'purchased' status is false by default.
     // NOTE: If upgrades were dynamically loaded, this would need adjustment.
  }


  void _updateInvestmentPricesMicro() {
    if (Random().nextDouble() > 0.2) return; // Run only 20% of ticks

    for (var investment in investments) {
      double microChange = investment.trend * 0.01;
      microChange += (Random().nextDouble() * 2 - 1) * investment.volatility * 0.03;

      double newPrice = investment.currentPrice * (1 + microChange);
      newPrice = max(investment.basePrice * 0.1, newPrice); // Min price
      newPrice = min(investment.basePrice * 10, newPrice); // Max price

      investment.currentPrice = newPrice;

      if (investment.priceHistory.isNotEmpty) {
        investment.priceHistory[investment.priceHistory.length - 1] = investment.currentPrice;
      }
    }
    // No notifyListeners here, called by main game loop if money changed
  }


  void _updateDailyEarnings(String dayKey, double amount) {
     // This function seems deprecated by hourly earnings. Keeping structure but potentially removable.
     // If used, should interact with hourlyEarnings for consistency or be removed.
     print("Warning: _updateDailyEarnings called, might be deprecated. Day: $dayKey, Amount: $amount");
     // hourlyEarnings[dayKey] = (hourlyEarnings[dayKey] ?? 0) + amount; // Example interaction if needed
  }


  void _updateHourlyEarnings(String hourKey, double earnings) {
    hourlyEarnings[hourKey] = (hourlyEarnings[hourKey] ?? 0) + earnings;

    // Prune entries older than 7 days (168 hours)
    final cutoff = DateTime.now().subtract(const Duration(hours: 168));
    hourlyEarnings.removeWhere((key, value) {
       try {
         List<String> parts = key.split('-');
         if (parts.length == 4) {
           DateTime entryTime = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]), int.parse(parts[3]));
           return entryTime.isBefore(cutoff);
         }
         return true; // Remove invalid keys
       } catch (e) {
         print("Error parsing hourly earnings key for removal: $key, Error: $e");
         return true; // Remove keys that cause errors
       }
    });
  }
}
