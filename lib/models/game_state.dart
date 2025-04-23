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
import '../data/achievement_definitions.dart'; // Import needed for retroactive PP
import 'challenge.dart'; // ADDED: Import for Challenge model

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

  // >> START: Platinum Points System Fields <<
  int platinumPoints = 0;
  bool _retroactivePPAwarded = false; // Flag for retroactive PP grant
  Map<String, int> ppPurchases = {}; // Tracks counts of repeatable PP items purchased {itemId: count}
  Set<String> ppOwnedItems = {};    // Tracks IDs of one-time PP items purchased {itemId}
  bool showPPAnimation = false; // Flag to control PP animation
  bool showPremiumPurchaseNotification = false; // ADDED: Flag for premium notification
  // >> END: Platinum Points System Fields <<

  // >> START: Platinum Vault Item State <<
  bool isPlatinumEfficiencyActive = false; // platinum_efficiency
  bool isPlatinumPortfolioActive = false; // platinum_portfolio
  Map<String, int> platinumFoundationsApplied = {}; // { localeId: count } - platinum_foundation (Max 5 total)
  bool isPlatinumResilienceActive = false; // platinum_resilience
  bool isPlatinumTowerUnlocked = false; // platinum_tower (Unlocks property)
  bool isPlatinumVentureUnlocked = false; // platinum_venture (Unlocks business)
  bool isPlatinumIslandsUnlocked = false; // platinum_islands (Unlocks locale)
  bool isPlatinumYachtUnlocked = false; // platinum_yacht (Unlocks the ability to buy the yacht)
  bool isPlatinumYachtPurchased = false; // Tracks if the yacht itself has been purchased
  String? platinumYachtDockedLocaleId; // Where the yacht is currently providing a boost (resets on reincorp)
  List<RealEstateUpgrade> platinumYachtUpgrades = []; // Upgrades for the yacht itself
  bool isPlatinumIslandUnlocked = false; // platinum_island (Unlocks property in Platinum Islands)
  bool isPlatinumStockUnlocked = false; // ADDED: platinum_stock (Unlocks investment)
  // >> END: Platinum Vault Item State <<

  // ADDED: Active Challenge State
  Challenge? activeChallenge;

  // ADDED: Disaster Shield State
  bool isDisasterShieldActive = false;
  DateTime? disasterShieldEndTime;

  // ADDED: Crisis Accelerator State
  bool isCrisisAcceleratorActive = false;
  DateTime? crisisAcceleratorEndTime;

  // ADDED: Platinum Facade State
  Set<String> platinumFacadeAppliedBusinessIds = {};

  // ADDED: Platinum Crest State
  bool isPlatinumCrestUnlocked = false;

  // ADDED: Platinum Spire State
  String? platinumSpireLocaleId; // ID of the locale where the spire is placed

  // ADDED: Income Surge State
  bool isIncomeSurgeActive = false;
  DateTime? incomeSurgeEndTime;

  // Flags for specific unlocks from Platinum Vault
  bool isGoldenCursorUnlocked = false;
  bool isExecutiveThemeUnlocked = false;
  bool isPlatinumFrameUnlocked = false;

  // Boost Timer State
  int boostRemainingSeconds = 0;
  Timer? _boostTimer;
  bool get isBoostActive => boostRemainingSeconds > 0;

  // Ad Boost State (separate system)
  int adBoostRemainingSeconds = 0;
  Timer? _adBoostTimer;
  bool get isAdBoostActive => adBoostRemainingSeconds > 0;

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
  Timer? _achievementNotificationTimer; // ADDED: Timer for hiding notification

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
/*
  void enablePremium() {
    isPremium = true;
    notifyListeners();
    print("Premium status enabled");
  }
*/

  void _setupTimers() {
    // REMOVED: _saveTimer = Timer.periodic(const Duration(minutes: 1), (_) {
    //   notifyListeners(); // This comment is incorrect; GameService uses its own timer.
    // });

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

      // --- ADDED: Challenge Check --- 
      if (activeChallenge != null) {
        if (!activeChallenge!.isActive(now)) {
          // Challenge has expired
          bool success = activeChallenge!.wasSuccessful(totalEarned);
          if (success) {
            print("🎉 Platinum Challenge Successful! Awarding ${activeChallenge!.rewardPP} PP.");
            awardPlatinumPoints(activeChallenge!.rewardPP);
            // TODO: Add user-facing notification for success
          } else {
            print("😞 Platinum Challenge Failed. Goal not met.");
            // TODO: Add user-facing notification for failure
          }
          activeChallenge = null; // Clear the challenge
          notifyListeners(); // Update UI potentially showing challenge status
        }
      }
      // --- END: Challenge Check --- 

      // --- ADDED: Disaster Shield Check --- 
      if (isDisasterShieldActive && disasterShieldEndTime != null && now.isAfter(disasterShieldEndTime!)) {
        print("INFO: Disaster Shield expired.");
        isDisasterShieldActive = false;
        disasterShieldEndTime = null;
        // TODO: Add user-facing notification for shield expiry?
        notifyListeners();
      }
      // --- END: Disaster Shield Check --- 

      // --- ADDED: Crisis Accelerator Check --- 
      if (isCrisisAcceleratorActive && crisisAcceleratorEndTime != null && now.isAfter(crisisAcceleratorEndTime!)) {
        print("INFO: Crisis Accelerator expired.");
        isCrisisAcceleratorActive = false;
        crisisAcceleratorEndTime = null;
        // TODO: Add user-facing notification?
        notifyListeners();
      }
      // --- END: Crisis Accelerator Check --- 

      // --- ADDED: Income Surge Check --- 
      if (isIncomeSurgeActive && incomeSurgeEndTime != null && now.isAfter(incomeSurgeEndTime!)) {
        print("INFO: Income Surge expired.");
        isIncomeSurgeActive = false;
        incomeSurgeEndTime = null;
        notifyListeners();
      }
      // --- END: Income Surge Check --- 

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
            // ADDED: Apply Income Surge
            if (isIncomeSurgeActive) income *= 2.0;
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
          // ADDED: Apply Income Surge
          if (isIncomeSurgeActive) investmentDividend *= 2.0;
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
    // Calculate earnings based on click value and potential boost effects
    double baseEarnings = clickValue * clickMultiplier; // Base click value * permanent PP multiplier
    
    // Apply temporary boosts - they can stack multiplicatively
    double boostMultiplier = 1.0;
    if (isBoostActive) boostMultiplier *= 2.0;
    if (isAdBoostActive) boostMultiplier *= 10.0;
    
    double finalEarnings = baseEarnings * boostMultiplier;

    print("~~~ GameState.tap() called. BaseClick: $clickValue, PermClickMult: $clickMultiplier, PlatBoostMult: ${isBoostActive ? '2.0x' : '1.0x'}, AdBoostMult: ${isAdBoostActive ? '10.0x' : '1.0x'}, Final: $finalEarnings ~~~ "); // DEBUG LOG

    money += finalEarnings;
    totalEarned += finalEarnings;
    manualEarnings += finalEarnings;
    taps++;
    lifetimeTaps++;

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

  // Dispose timers when GameState is disposed
  @override
  void dispose() {
    print("🗑️ Disposing GameState and canceling timers...");
    _saveTimer?.cancel();
    _updateTimer?.cancel();
    _investmentUpdateTimer?.cancel();
    _boostTimer?.cancel();
    _adBoostTimer?.cancel(); // ADDED: Cancel ad boost timer
    _achievementNotificationTimer?.cancel();
    super.dispose();
  }

  // ADDED: Method to start the temporary platinum boost 
  void startBoost() {
    if (!isBoostActive) {
      boostRemainingSeconds = 300; // 5 minutes
      _startBoostTimer();
      notifyListeners();
    }
  }

  // ADDED: Method to start the ad boost (10x for 60 seconds)
  void startAdBoost() {
    adBoostRemainingSeconds = 60; // 60 seconds
    _startAdBoostTimer();
    notifyListeners();
  }

  // ADDED: Method to award Platinum Points
  void awardPlatinumPoints(int amount) {
    if (amount <= 0) return;
    platinumPoints += amount;
    showPPAnimation = true; // Trigger animation
    notifyListeners();
    // Optional: Set a timer to turn off the animation flag after a short duration
    Timer(const Duration(seconds: 3), () {
      showPPAnimation = false;
      notifyListeners();
    });
  }

  // ADDED: Method to spend Platinum Points, now with optional context
  // TODO: Needs robust handling of item effects and limits
  bool spendPlatinumPoints(String itemId, int cost, {Map<String, dynamic>? purchaseContext}) {
    // Check if affordable
    if (platinumPoints < cost) {
        print("DEBUG: Cannot afford item $itemId. Cost: $cost, Have: $platinumPoints");
        return false;
    }

    // Check ownership for one-time items
    if (ppOwnedItems.contains(itemId)) {
        print("DEBUG: Item $itemId already owned (one-time purchase).");
        return false; // Already owned
    }

    // --- Specific checks for Platinum Foundation ---
    if (itemId == 'platinum_foundation') {
        // Check global limit
        if (platinumFoundationsApplied.length >= 5) {
            print("DEBUG: Cannot apply Foundation: Maximum limit (5) reached.");
            return false;
        }
        // Check if the specific locale (passed in context) is already boosted
        String? selectedLocaleId = purchaseContext?['selectedLocaleId'] as String?;
        if (selectedLocaleId == null) {
             print("ERROR: No locale ID provided for Platinum Foundation purchase.");
             return false; // Need locale context
        }
        if (platinumFoundationsApplied.containsKey(selectedLocaleId)) {
            print("DEBUG: Cannot apply Foundation: Locale $selectedLocaleId already has one.");
            // Assuming 1 per locale limit for now
            return false;
        }
    }
    // --- End specific checks ---

    // Basic check for repeatable item limits (Placeholder - needs specific item logic)
    // Example: if (itemId == 'platinum_surge' && (ppPurchases[itemId] ?? 0) >= 3) return false;

    platinumPoints -= cost;

    // Apply the actual effect of the item based on itemId, passing context
    _applyVaultItemEffect(itemId, purchaseContext);

    // Track purchase
    // TODO: Differentiate between one-time and repeatable logic more cleanly
    if (itemId == 'platinum_foundation' || itemId == 'platinum_challenge' || itemId == 'platinum_shield' || itemId == 'platinum_accelerator' || itemId == 'platinum_surge' || itemId == 'platinum_warp' || itemId == 'platinum_cache') {
        ppPurchases[itemId] = (ppPurchases[itemId] ?? 0) + 1;
    } else {
        ppOwnedItems.add(itemId);
    }

    notifyListeners();
    return true;
  }

  // ADDED: Placeholder for applying vault item effects - NEEDS IMPLEMENTATION
  // Now accepts optional purchaseContext
  void _applyVaultItemEffect(String itemId, Map<String, dynamic>? purchaseContext) {
    print("INFO: Applying effect for Platinum Vault item: $itemId with context: $purchaseContext");
    // --- This needs detailed implementation based on item ID ---
    switch (itemId) {
        case 'platinum_efficiency':
            isPlatinumEfficiencyActive = true;
            // Logic to apply 1.05x multiplier needs to be integrated where business upgrades are calculated
            // This might require modifying Business.getCurrentIncome or how upgrades are applied initially.
            print("TODO: Integrate platinum_efficiency bonus calculation.");
            break;
        case 'platinum_portfolio':
            isPlatinumPortfolioActive = true;
            // Logic to apply 1.25x multiplier is integrated in investment dividend calculation.
            break;
        case 'platinum_foundation':
            // Use the selected locale ID from the context
            String? targetLocaleId = purchaseContext?['selectedLocaleId'] as String?;

            if (targetLocaleId != null) {
                // Check limits again just in case (should be pre-checked in spendPlatinumPoints)
                if (platinumFoundationsApplied.length < 5 && !platinumFoundationsApplied.containsKey(targetLocaleId)) {
                   platinumFoundationsApplied[targetLocaleId] = 1; // Store that foundation is applied
                   print("Applied Platinum Foundation to $targetLocaleId");
                } else {
                   print("WARNING: Attempted to apply foundation $itemId to $targetLocaleId but limits were reached or already applied.");
                }
            } else {
               print("ERROR: Could not apply Platinum Foundation - missing selectedLocaleId in context.");
            }
            break;
        case 'platinum_resilience':
            isPlatinumResilienceActive = true;
            // Logic is integrated where event penalties are calculated (e.g., resolveEvent).
            break;
        case 'platinum_tower':
            isPlatinumTowerUnlocked = true;
            _updateRealEstateUnlocks(); // Trigger unlock check
            break;
        case 'platinum_venture':
            isPlatinumVentureUnlocked = true;
            _updateBusinessUnlocks(); // Trigger unlock check
            break;
        case 'platinum_stock':
            isPlatinumStockUnlocked = true;
            // TODO: Add the actual 'platinum_stock' investment to the investments list if not present.
            // Need to ensure it's only added once.
            if (!investments.any((inv) => inv.id == 'platinum_stock')) {
                _addPlatinumStockInvestment(); // Add helper function for this
                print("Added Platinum Stock Investment.");
            }
            break;
        case 'platinum_islands':
            isPlatinumIslandsUnlocked = true;
            _updateRealEstateUnlocks(); // Trigger unlock check
            break;
        case 'platinum_yacht':
            isPlatinumYachtUnlocked = true;
             // The UI should handle the actual purchase of the yacht *property* after this unlock.
             // This flag just enables the ability to buy it.
            print("Platinum Yacht purchase capability unlocked.");
            break;
        case 'platinum_island':
             // Requires Platinum Islands locale to be unlocked FIRST (checked in UI ideally)
             if (isPlatinumIslandsUnlocked) {
                 isPlatinumIslandUnlocked = true;
                 _updateRealEstateUnlocks(); // Trigger unlock check
             } else {
                 print("Cannot unlock Platinum Island property: Platinum Islands locale not unlocked.");
                 // Optionally refund points?
             }
            break;
        // --- Events & Challenges ---
        case 'platinum_challenge':
            if (activeChallenge != null) {
              print("WARNING: Cannot start Platinum Challenge, another challenge is already active.");
              // Optionally: refund points or prevent purchase in spendPlatinumPoints?
              // For now, just don't start a new one.
            } else {
              // FIX: Use the getter 'totalIncomePerSecond', not method call
              final currentIncomePerHour = totalIncomePerSecond * 3600;
              final goalAmount = currentIncomePerHour * 2;
              activeChallenge = Challenge(
                itemId: itemId,
                startTime: DateTime.now(),
                duration: const Duration(hours: 1),
                goalEarnedAmount: goalAmount,
                startTotalEarned: totalEarned,
                rewardPP: 30, // Hardcoded based on item definition
              );
              print("INFO: Platinum Challenge Started! Goal: Earn ${goalAmount.toStringAsFixed(2)} in 1 hour.");
              // TODO: Add a user-facing notification for challenge start.
              notifyListeners(); // Ensure UI can react to the challenge starting
            }
            break;
        case 'platinum_shield':
            if (isDisasterShieldActive) {
              print("WARNING: Disaster Shield is already active.");
              // TODO: Decide if purchasing again extends duration or is disallowed.
              // For now, disallow re-purchase while active.
            } else {
              isDisasterShieldActive = true;
              disasterShieldEndTime = DateTime.now().add(const Duration(days: 1)); // 1 day duration
              print("INFO: Disaster Shield Activated! Ends at: $disasterShieldEndTime");
              // TODO: Add user-facing notification for shield activation.
              notifyListeners();
            }
            break;
        case 'platinum_accelerator':
            if (isCrisisAcceleratorActive) {
              print("WARNING: Crisis Accelerator is already active.");
              // TODO: Decide if purchasing again extends duration or is disallowed.
            } else {
              isCrisisAcceleratorActive = true;
              crisisAcceleratorEndTime = DateTime.now().add(const Duration(days: 1)); // 24h duration
              print("INFO: Crisis Accelerator Activated! Ends at: $crisisAcceleratorEndTime");
              // TODO: Add user-facing notification.
              notifyListeners();
            }
            break;
        // --- Cosmetics ---
        case 'platinum_mogul':
            isExecutiveThemeUnlocked = true;
            print("Unlocked Executive Theme (via Platinum Mogul).");
            break;
        case 'platinum_facade': 
            // TODO: Implement UI to select which owned business gets the facade.
            // For now, just acknowledge the purchase attempt.
            print("TODO: Implement business selection UI for Platinum Facade. Effect not applied yet.");
            // Example future logic:
            // String? targetBusinessId = // ... get from purchase context ...;
            // if (targetBusinessId != null && businesses.any((b) => b.id == targetBusinessId && b.level > 0) && !platinumFacadeAppliedBusinessIds.contains(targetBusinessId)) {
            //     platinumFacadeAppliedBusinessIds.add(targetBusinessId);
            //     print("Applied Platinum Facade to $targetBusinessId");
            // } else {
            //     print("Failed to apply Platinum Facade: Invalid target or already applied.");
            //     // Optionally refund points
            // }
            break;
        case 'platinum_crest': 
            isPlatinumCrestUnlocked = true;
            print("Unlocked Platinum Crest.");
            break;
        case 'platinum_spire': 
            // TODO: Implement UI to select which unlocked locale gets the spire.
            print("TODO: Implement locale selection UI for Platinum Spire. Effect not applied yet.");
            // Example future logic:
            // String? targetLocaleId = // ... get from purchase context ...;
            // if (targetLocaleId != null && realEstateLocales.any((l) => l.id == targetLocaleId && l.unlocked) && platinumSpireLocaleId == null) {
            //     platinumSpireLocaleId = targetLocaleId;
            //     print("Placed Platinum Spire in $targetLocaleId");
            // } else {
            //     print("Failed to place Platinum Spire: Invalid target or spire already placed.");
            //     // Optionally refund points
            // }
            break;
        // --- Boosters ---
        case 'platinum_surge':
            if (isIncomeSurgeActive) {
              print("WARNING: Income Surge is already active.");
              // TODO: Extend duration or disallow?
            } else {
              isIncomeSurgeActive = true;
              incomeSurgeEndTime = DateTime.now().add(const Duration(hours: 1));
              print("INFO: Income Surge Activated! Ends at: $incomeSurgeEndTime");
              // TODO: Add user-facing notification.
              notifyListeners();
            }
            break;
        case 'platinum_warp':
            double offlineHours = 4.0; // Defined by the item
            double offlineIncome = calculateOfflineIncome(Duration(hours: offlineHours.toInt())); 
            if (offlineIncome > 0) {
                money += offlineIncome;
                totalEarned += offlineIncome;
                passiveEarnings += offlineIncome; // Attribute to passive
                print("INFO: Awarded ${offlineIncome.toStringAsFixed(2)} offline income via Platinum Warp (${offlineHours}h).");
                // TODO: Add user-facing notification.
                 notifyListeners();
            } else {
                 print("INFO: Platinum Warp: No offline income calculated (income/sec might be zero).");
            }
            break;
        case 'platinum_cache':
             double cashAward = _calculateScaledCashCache(); // Add helper for scaling
             money += cashAward;
             totalEarned += cashAward;
             passiveEarnings += cashAward; // Attribute to passive for simplicity
             print("Awarded ${cashAward.toStringAsFixed(2)} via Platinum Cache.");
             // Ensure notifyListeners is called
             notifyListeners(); 
             break;
        case 'golden_cursor': // Added missing case
             isGoldenCursorUnlocked = true;
            break;
        default:
            print("WARNING: Unknown Platinum Vault item ID: $itemId");
    }
    notifyListeners(); // Notify after applying effect
  }

  // ADDED: Helper to add the Platinum Stock investment
  void _addPlatinumStockInvestment() {
      investments.add(Investment(
          id: 'platinum_stock',
          name: 'Quantum Computing Inc.',
          description: 'High-risk, high-reward venture in quantum computing.',
          currentPrice: 1000000000.0, // 1B per share
          basePrice: 1000000000.0,
          volatility: 0.40, // High volatility
          trend: 0.06, // High potential trend
          owned: 0,
          icon: Icons.memory, // Placeholder icon
          color: Colors.cyan,
          priceHistory: List.generate(30, (i) => 1000000000.0 * (0.95 + (Random().nextDouble() * 0.1))), // Wider random range
          category: 'Technology', // Or a unique category like 'Quantum'
          marketCap: 4.0e12, // 4 Trillion market cap
          // Potentially add a high dividend yield as well for extra reward/risk
          // dividendPerSecond: 50000.0, // Example: 50k/sec per share
      ));
  }

  // ADDED: Helper to calculate scaled cash cache amount
  double _calculateScaledCashCache() {
      // Simple scaling based on total earned (adjust thresholds as needed)
      if (totalEarned < 1e6) return 100000.0; // 100K early game (< $1M earned)
      if (totalEarned < 1e9) return 1000000.0; // $1M mid game (< $1B earned)
      return 10000000.0; // $10M late game (>= $1B earned)
  }

  // ADDED: Helper to calculate potential offline income for a given duration
  double calculateOfflineIncome(Duration offlineDuration) {
    // Cap maximum offline time to avoid exploits (e.g., max 8 hours)
    final maxOfflineDuration = const Duration(hours: 8);
    final cappedDuration = offlineDuration > maxOfflineDuration ? maxOfflineDuration : offlineDuration;

    if (cappedDuration <= Duration.zero) return 0.0;

    // Simple calculation: current total income/sec * duration in seconds
    // Note: This doesn't account for potential unlocks/upgrades during offline time.
    // More complex logic could simulate ticks, but this is simpler for a booster.
    double incomePerSecond = totalIncomePerSecond; // Use the getter
    double offlineIncome = incomePerSecond * cappedDuration.inSeconds;
    
    // Apply a potential reduction factor for offline income (e.g., 50%)?
    // offlineIncome *= 0.5; // Example: only earn 50% while offline

    print("Calculated offline income for ${cappedDuration.inHours}h: ${offlineIncome.toStringAsFixed(2)}");
    return offlineIncome;
  }

  // ADDED: Calculate passive income per second for achievements
  double calculatePassiveIncomePerSecond() {
    double total = 0.0;

    // Business income
    for (var business in businesses) {
      if (business.level > 0) {
        bool hasEvent = hasActiveEventForBusiness(business.id);
        total += business.getCurrentIncome(affectedByEvent: hasEvent) * 
                 incomeMultiplier * 
                 prestigeMultiplier;
      }
    }

    // Real estate income
    total += getRealEstateIncomePerSecond() * incomeMultiplier * prestigeMultiplier;

    // Dividend income from investments
    double diversificationBonus = calculateDiversificationBonus();
    for (var investment in investments) {
      if (investment.owned > 0 && investment.hasDividends()) {
        total += investment.getDividendIncomePerSecond() *
                     incomeMultiplier *
                     prestigeMultiplier *
                     (1 + diversificationBonus); // Apply diversification bonus
      }
    }
    
    // Apply global income boosts (e.g., Income Surge)
    if (isIncomeSurgeActive) total *= 2.0;

    return total;
  }

  // Helper method to start the boost timer
  void _startBoostTimer() {
    _boostTimer?.cancel();
    _boostTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (boostRemainingSeconds > 0) {
        boostRemainingSeconds--;
      } else {
        timer.cancel();
        _boostTimer = null;
      }
      notifyListeners();
    });
  }

  // Helper method to start the ad boost timer
  void _startAdBoostTimer() {
    _adBoostTimer?.cancel();
    _adBoostTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (adBoostRemainingSeconds > 0) {
        adBoostRemainingSeconds--;
      } else {
        timer.cancel();
        _adBoostTimer = null;
      }
      notifyListeners();
    });
  }
}
