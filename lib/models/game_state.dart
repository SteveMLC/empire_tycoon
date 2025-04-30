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
import '../data/business_definitions.dart'; // ADDED: Import for business data
import '../data/investment_definitions.dart'; // ADDED: Import for investment data
import '../data/platinum_vault_items.dart'; // ADDED: Import for vault items
import '../utils/number_formatter.dart'; // ADDED: Import for formatting
import 'mogul_avatar.dart'; // ADDED: Import for mogul avatars

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
  // ADDED: Track last game loop update time for debouncing
  DateTime? _lastUpdateTime;

  // ADDED: Track last calculated income per second for consistent UI display
  double lastCalculatedIncomePerSecond = 0.0;

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

  // User profile properties
  String? username;
  String? userAvatar;
  
  // ADDED: Mogul avatar tracking
  bool isMogulAvatarsUnlocked = false;
  String? selectedMogulAvatarId;
  
  // --- OFFLINE INCOME NOTIFICATION STATE ---
  double offlineEarningsAwarded = 0.0;
  Duration? offlineDurationForNotification;
  bool _shouldShowOfflineEarnings = false; // Changed to private for proper getter/setter
  
  // Getter for shouldShowOfflineEarnings
  bool get shouldShowOfflineEarnings => _shouldShowOfflineEarnings;
  
  // Setter for shouldShowOfflineEarnings
  set shouldShowOfflineEarnings(bool value) {
    if (_shouldShowOfflineEarnings != value) {
      _shouldShowOfflineEarnings = value;
      print("📣 shouldShowOfflineEarnings changed to: $value");
      notifyListeners();
    }
  }

  // >> START: Platinum Points System Fields <<
  int platinumPoints = 0;
  bool _retroactivePPAwarded = false; // Flag for retroactive PP grant
  Map<String, int> ppPurchases = {}; // Tracks counts of repeatable PP items purchased {itemId: count}
  Set<String> ppOwnedItems = {};    // Tracks IDs of one-time PP items purchased {itemId}
  bool showPPAnimation = false; // Flag to control PP animation
  bool showPremiumPurchaseNotification = false; // ADDED: Flag for premium notification
  // >> END: Platinum Points System Fields <<

  // ADDED: Variable to track offline earnings for notification
  // >> START: Platinum Vault Item State <<
  // --- Permanent Boost Flags (from Upgrades category) ---
  bool isPlatinumEfficiencyActive = false; // platinum_efficiency: Business upgrade effectiveness +5%
  bool isPlatinumPortfolioActive = false; // platinum_portfolio: Dividend income +25%
  bool isPlatinumResilienceActive = false; // platinum_resilience: Negative event impact -10%
  bool isPermanentIncomeBoostActive = false; // perm_income_boost_5pct: All passive income +5%
  bool isPermanentClickBoostActive = false; // perm_click_boost_10pct: Manual tap value +10%
  // --- Other Unlock/State Flags ---
  Map<String, int> platinumFoundationsApplied = {}; // { localeId: count } - platinum_foundation (Max 5 total)
  bool isPlatinumTowerUnlocked = false; // platinum_tower (Unlocks property)
  bool isPlatinumVentureUnlocked = false; // platinum_venture (Unlocks business)
  bool isPlatinumIslandsUnlocked = false; // platinum_islands (Unlocks locale)
  bool isPlatinumYachtUnlocked = false; // platinum_yacht (Unlocks the ability to buy the yacht)
  bool isPlatinumYachtPurchased = false; // Tracks if the yacht itself has been purchased
  String? platinumYachtDockedLocaleId; // Where the yacht is currently providing a boost (resets on reincorp)
  List<RealEstateUpgrade> platinumYachtUpgrades = []; // Upgrades for the yacht itself
  bool isPlatinumIslandUnlocked = false; // platinum_island (Unlocks property in Platinum Islands)
  bool isPlatinumStockUnlocked = false; // ADDED: platinum_stock (Unlocks investment)
  // --- Cooldowns and Usage Limits ---
  DateTime? incomeSurgeCooldownEnd; // Cooldown for 'platinum_surge' (1x per day)
  DateTime? cashCacheCooldownEnd; // Cooldown for 'platinum_cache' (1x per day - previously 5x/week)
  int timeWarpUsesThisPeriod = 0; // Counter for 'platinum_warp' (2x per week)
  DateTime? lastTimeWarpReset; // Timestamp for weekly reset of 'platinum_warp'
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
  bool isPlatinumFrameActive = false; // Track if frame is currently displayed

  // Boost Timer State
  int boostRemainingSeconds = 0;
  Timer? _boostTimer;
  bool get isBoostActive => boostRemainingSeconds > 0;

  // Ad Boost State (separate system)
  int adBoostRemainingSeconds = 0;
  Timer? _adBoostTimer;
  bool get isAdBoostActive => adBoostRemainingSeconds > 0;

  // >> START: Platinum Booster State (Click Frenzy / Steady Boost) <<
  int platinumClickFrenzyRemainingSeconds = 0;
  DateTime? platinumClickFrenzyEndTime;
  Timer? _platinumClickFrenzyTimer;

  int platinumSteadyBoostRemainingSeconds = 0;
  DateTime? platinumSteadyBoostEndTime;
  Timer? _platinumSteadyBoostTimer;

  // Getter to check if *any* platinum click booster is active
  bool get isPlatinumBoostActive => platinumClickFrenzyRemainingSeconds > 0 || platinumSteadyBoostRemainingSeconds > 0;
  // << END: Platinum Booster State >>

  // >> START: Derived Active Flags for Boosters <<
  // Used to easily check if a specific booster is active for UI/logic
  bool get isClickFrenzyActive => platinumClickFrenzyRemainingSeconds > 0;
  bool get isSteadyBoostActive => platinumSteadyBoostRemainingSeconds > 0;
  // >> END: Derived Active Flags for Boosters <<

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

  // Add near the other theme-related variables like isExecutiveThemeUnlocked
  bool isExecutiveStatsThemeUnlocked = false;  // Whether the user has unlocked the theme
  String? selectedStatsTheme = null;  // The currently selected theme for stats screen

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

    // Apply Platinum Resilience: Reduce required taps by 10% if active
    double resilienceMultiplier = isPlatinumResilienceActive ? 0.9 : 1.0;
    int finalRequired = (required * resilienceMultiplier).ceil(); // Use ceil to ensure it doesn't become 0 easily

    current++;
    tapData['current'] = current;

    lifetimeTaps++; // Increment lifetime taps to track event taps as well

    if (current >= finalRequired) {
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
    businesses = defaultBusinesses; // Use the imported list
  }

  void _initializeDefaultInvestments() {
    investments = defaultInvestments; // Use the imported list
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

      // --- ADDED: Check for Business Upgrades --- 
      for (var business in businesses) {
        if (business.isUpgrading && business.upgradeEndTime != null && now.isAfter(business.upgradeEndTime!)) {
          completeBusinessUpgrade(business);
        }
      }
      // --- END: Check for Business Upgrades --- 

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
      double permanentIncomeBoostMultiplier = isPermanentIncomeBoostActive ? 1.05 : 1.0;

      // Update businesses income
      double businessIncomeThisTick = 0;
      double businessEfficiencyMultiplier = isPlatinumEfficiencyActive ? 1.05 : 1.0;
      for (var business in businesses) {
        if (business.level > 0) {
          business.secondsSinceLastIncome++;
          if (business.secondsSinceLastIncome >= business.incomeInterval) {
            bool hasEvent = hasActiveEventForBusiness(business.id);
            // Apply Platinum Efficiency to base income first
            double income = business.getCurrentIncome() * businessEfficiencyMultiplier;
            // Then apply standard multipliers
            income *= incomeMultiplier * prestigeMultiplier;
            // Then apply the overall permanent boost
            income *= permanentIncomeBoostMultiplier;
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
      // Apply standard multipliers
      double realEstateIncomeThisTick = realEstateIncomePerSecond * incomeMultiplier * prestigeMultiplier;
      // Apply the overall permanent boost
      realEstateIncomeThisTick *= permanentIncomeBoostMultiplier;
      // Apply Income Surge (if applicable)
      if (isIncomeSurgeActive) realEstateIncomeThisTick *= 2.0;
      if (realEstateIncomeThisTick > 0) {
        money += realEstateIncomeThisTick;
        totalEarned += realEstateIncomeThisTick;
        realEstateEarnings += realEstateIncomeThisTick;
        _updateHourlyEarnings(hourKey, realEstateIncomeThisTick);
      }

      // Generate dividend income from investments
      double dividendIncomeThisTick = 0.0;
      double diversificationBonus = calculateDiversificationBonus();
      double portfolioMultiplier = isPlatinumPortfolioActive ? 1.25 : 1.0;
      for (var investment in investments) {
        if (investment.owned > 0 && investment.hasDividends()) {
          // Apply Platinum Portfolio and Diversification Bonus first
          double investmentDividend = investment.getDividendIncomePerSecond() * portfolioMultiplier *
                                     (1 + diversificationBonus);
          // Then apply standard multipliers
          investmentDividend *= incomeMultiplier *
                               prestigeMultiplier *
                               permanentIncomeBoostMultiplier;
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

      // ADDED: Check active challenge
      _checkActiveChallenge(now);

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
    // Calculate base earnings including permanent boost
    double permanentClickMultiplier = isPermanentClickBoostActive ? 1.1 : 1.0;
    double baseEarnings = clickValue * permanentClickMultiplier; // Base * Permanent Vault Boost

    // Apply Ad boost multiplier
    double adBoostMultiplier = isAdBoostActive ? 10.0 : 1.0;

    // Apply Platinum Boosters multiplier
    double platinumBoostMultiplier = 1.0;
    if (platinumClickFrenzyRemainingSeconds > 0) {
        platinumBoostMultiplier = 10.0;
    } else if (platinumSteadyBoostRemainingSeconds > 0) {
        platinumBoostMultiplier = 2.0;
    }

    // Combine all multipliers: Base * Prestige * Ad * Platinum
    double finalEarnings = baseEarnings * clickMultiplier * adBoostMultiplier * platinumBoostMultiplier;

    // --- REMOVED potentially conflicting old boost logic (isBoostActive, clickMultiplier) ---
    // double boostMultiplier = 1.0;
    // if (isBoostActive) boostMultiplier *= 2.0; 
    // baseEarnings = clickValue * clickMultiplier * permanentClickMultiplier; 
    // finalEarnings = baseEarnings * boostMultiplier * platinumBoostMultiplier; 

    print("~~~ GameState.tap() called. BaseClick: $clickValue, PermVaultMult: ${permanentClickMultiplier.toStringAsFixed(1)}x, PrestigeMult: ${clickMultiplier.toStringAsFixed(1)}x, AdBoostMult: ${adBoostMultiplier.toStringAsFixed(1)}x, PlatinumBoostMult: ${platinumBoostMultiplier.toStringAsFixed(1)}x, Final: $finalEarnings ~~~ "); // Updated DEBUG LOG

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
    int timerSeconds = business.getNextUpgradeTimerSeconds();
    
    if (money >= cost) {
      money -= cost;
      
      // Check if this upgrade requires a timer
      if (timerSeconds <= 0) {
        // No timer needed, increment level immediately
        business.level++;
      } else {
        // Start the upgrade timer instead of incrementing level immediately
        business.startUpgrade(timerSeconds);
      }
      
      business.unlocked = true;
      _updateBusinessUnlocks();
      notifyListeners();
      return true;
    }
    return false;
  }

  // Add method to complete a business upgrade when its timer finishes
  void completeBusinessUpgrade(Business business) {
    business.completeUpgrade(); // This will increment the level
    _updateBusinessUnlocks();
    notifyListeners();
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
    _cancelPlatinumTimers(); // ADDED: Cancel platinum booster timers
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

  // Method to enable premium features
  void enablePremium() {
    if (isPremium) return; // Already premium
    
    isPremium = true;
    // Award bonus platinum points
    platinumPoints += 1500;
    // Show premium purchase notification
    showPremiumPurchaseNotification = true;
    
    // After short delay, hide notification
    Timer(const Duration(seconds: 5), () {
      showPremiumPurchaseNotification = false;
      notifyListeners();
    });
    
    notifyListeners();
  }

  // ADDED: Method to spend Platinum Points, now with optional context
  // TODO: Needs robust handling of item effects and limits
  bool spendPlatinumPoints(String itemId, int cost, {Map<String, dynamic>? purchaseContext}) {
    DateTime now = DateTime.now(); // Get current time for checks

    // Check if affordable
    if (platinumPoints < cost) {
        print("DEBUG: Cannot afford item $itemId. Cost: $cost, Have: $platinumPoints");
        return false; // Not enough PP
    }

    // Check ownership for one-time items (before cooldowns)
    if (ppOwnedItems.contains(itemId)) {
        // Find the item definition to confirm it's one-time (should be, but good practice)
        // VaultItem itemDef = getVaultItems().firstWhere((item) => item.id == itemId); // Assuming access or cached list
        // if (itemDef.type == VaultItemType.oneTime) {
             print("DEBUG: Item $itemId already owned (one-time purchase).");
             return false; // Already owned
        // }
    }

    // --- Specific Cooldown/Limit/Active Checks ---
    switch (itemId) {
        case 'platinum_surge':
            if (isIncomeSurgeActive) {
                print("DEBUG: Cannot purchase $itemId: Already active.");
                return false; // Prevent purchase if already active
            }
            if (incomeSurgeCooldownEnd != null && now.isBefore(incomeSurgeCooldownEnd!)) {
                print("DEBUG: Cannot purchase $itemId: On cooldown until $incomeSurgeCooldownEnd.");
                return false; // On cooldown
            }
            break;
        case 'platinum_cache':
            if (cashCacheCooldownEnd != null && now.isBefore(cashCacheCooldownEnd!)) {
                print("DEBUG: Cannot purchase $itemId: On cooldown until $cashCacheCooldownEnd.");
                return false; // On cooldown
            }
            break;
        case 'platinum_warp':
            _checkAndResetTimeWarpLimit(now); // Ensure weekly limit is current
            if (timeWarpUsesThisPeriod >= 2) {
                print("DEBUG: Cannot purchase $itemId: Weekly limit (2) reached.");
                return false; // Limit reached
            }
            break;
        case 'platinum_shield':
            if (isDisasterShieldActive) {
                 print("DEBUG: Cannot purchase $itemId: Already active.");
                 return false; // Already active, don't allow stacking/extending for now
            }
            break;
        case 'platinum_accelerator':
            if (isCrisisAcceleratorActive) {
                 print("DEBUG: Cannot purchase $itemId: Already active.");
                 return false; // Already active, don't allow stacking/extending for now
            }
            break;
        case 'temp_boost_10x_5min':
            if (isClickFrenzyActive) {
                print("DEBUG: Cannot purchase $itemId: Already active.");
                return false; // Prevent stacking
            }
            if (isSteadyBoostActive) {
                 print("DEBUG: Cannot purchase $itemId: Another Platinum booster (Steady Boost) is active.");
                 return false; // Prevent running both simultaneously
            }
            break;
        case 'temp_boost_2x_10min':
            if (isSteadyBoostActive) {
                print("DEBUG: Cannot purchase $itemId: Already active.");
                return false; // Prevent stacking
            }
             if (isClickFrenzyActive) {
                 print("DEBUG: Cannot purchase $itemId: Another Platinum booster (Click Frenzy) is active.");
                 return false; // Prevent running both simultaneously
            }
            break;
        case 'platinum_foundation':
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
             break;
        // Add other specific checks here if needed
    }
    // --- End specific checks ---


    // If all checks passed, proceed with purchase
    platinumPoints -= cost;

    // Apply the actual effect of the item based on itemId, passing context and current time
    _applyVaultItemEffect(itemId, now, purchaseContext);

    // Track purchase - distinguish one-time vs repeatable
    // Note: This logic might need refinement based on exact item types from definition
    var itemDefinition = getVaultItems().firstWhere((item) => item.id == itemId, orElse: () => VaultItem(id: 'unknown', name: 'Unknown', description: '', category: VaultItemCategory.cosmetics, type: VaultItemType.oneTime, cost: 0)); // Basic fallback

    if (itemDefinition.type == VaultItemType.repeatable) {
        ppPurchases[itemId] = (ppPurchases[itemId] ?? 0) + 1;
    } else {
        // Check again before adding, just in case logic changes
        if (!ppOwnedItems.contains(itemId)) {
             ppOwnedItems.add(itemId);
        }
    }

    notifyListeners();
    return true;
  }

  // ADDED: Helper to check and reset the weekly Time Warp limit
  void _checkAndResetTimeWarpLimit(DateTime now) {
    if (lastTimeWarpReset == null) {
      // First use ever, set the reset time to next week (e.g., next Monday)
      lastTimeWarpReset = TimeUtils.findNextWeekday(now, DateTime.monday);
      timeWarpUsesThisPeriod = 0;
       print("Time Warp: Initializing weekly limit. Resets on $lastTimeWarpReset");
    } else if (now.isAfter(lastTimeWarpReset!)) {
      // It's past the reset time, reset the counter and set the next reset time
      int periodsPassed = now.difference(lastTimeWarpReset!).inDays ~/ 7;
      lastTimeWarpReset = TimeUtils.findNextWeekday(lastTimeWarpReset!.add(Duration(days: (periodsPassed + 1) * 7)), DateTime.monday);
      timeWarpUsesThisPeriod = 0;
      print("Time Warp: Weekly limit reset. Uses reset to 0. Next reset: $lastTimeWarpReset");
    }
    // Otherwise, the limit is still valid for the current week
  }

  // ADDED: Placeholder for applying vault item effects - NEEDS IMPLEMENTATION
  // Now accepts optional purchaseContext and the purchase time
  void _applyVaultItemEffect(String itemId, DateTime purchaseTime, Map<String, dynamic>? purchaseContext) {
    print("Applying effect for $itemId at $purchaseTime");
    // --- This needs detailed implementation based on item ID ---
    switch (itemId) {
        case 'platinum_efficiency':
            isPlatinumEfficiencyActive = true;
            print("Activated Platinum Efficiency (Business Upgrade +5%). Effect applied in income calculation.");
            break;
        case 'platinum_portfolio':
            isPlatinumPortfolioActive = true;
            print("Activated Platinum Portfolio (Dividend +25%). Effect applied in income calculation.");
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
            print("Activated Platinum Resilience (Event Impact -10%). Effect applied in event processing.");
            break;
        case 'platinum_facade':
            // Use the selected business ID from the context
            String? targetBusinessId = purchaseContext?['selectedBusinessId'] as String?;
            
            if (targetBusinessId != null) {
                // Apply the platinum facade to the selected business
                applyPlatinumFacade(targetBusinessId);
                print("Applied Platinum Facade to business $targetBusinessId");
            } else {
                print("ERROR: Could not apply Platinum Facade - missing selectedBusinessId in context.");
            }
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
            // Apply effect: Set unlock flag and store docked location from context
            String? targetLocaleId = purchaseContext?['selectedLocaleId'] as String?;
            if (targetLocaleId != null) {
                isPlatinumYachtUnlocked = true;
                platinumYachtDockedLocaleId = targetLocaleId;
                print("Activated Platinum Yacht and docked at $targetLocaleId.");
            } else {
                print("ERROR: Could not apply Platinum Yacht effect - missing selectedLocaleId in context.");
                // Attempt to refund points? This requires more complex logic.
            }
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
            // Check if the user can start a new challenge based on current income
            double currentIncomePerSecond = _calculateIncomePerSecond();
            double challengeGoal = currentIncomePerSecond * 2 * 3600; // Double hourly income = 2 * current/sec * 3600
            
            // If current income is 0, set a minimum challenge goal
            if (challengeGoal <= 0) {
              challengeGoal = 1000; // Minimum challenge goal of $1,000
            }
            
            // Create and assign the active challenge
            activeChallenge = Challenge(
              itemId: itemId,
              name: "Platinum Income Challenge", // Added missing name
              description: "Earn double your hourly income within 1 hour!", // Added missing description
              startTime: purchaseTime,
              duration: const Duration(hours: 1),  // 1 hour challenge
              goalEarnedAmount: challengeGoal,
              startTotalEarned: totalEarned,  // Current total earned
              rewardPP: 30,  // PP reward for completing the challenge
            );
            
            // Track usage
            platinumChallengeLastUsedTime = purchaseTime;
            platinumChallengeUsesToday++; // Increment daily usage counter
            lastPlatinumChallengeDayTracked = DateTime(purchaseTime.year, purchaseTime.month, purchaseTime.day);
            
            print("INFO: Started Platinum Challenge to earn $challengeGoal within 1 hour (${platinumChallengeUsesToday}/2 today)");
            notifyListeners(); // Explicitly notify listeners for challenge activation
            break;
        case 'platinum_shield':
            // Pre-check in spendPlatinumPoints ensures it's not already active
            isDisasterShieldActive = true;
            disasterShieldEndTime = purchaseTime.add(const Duration(days: 1)); // 24h duration
            print("INFO: Disaster Shield Activated! Ends at: $disasterShieldEndTime");
            // TODO: Add user-facing notification for shield activation.
            // notifyListeners(); // Called at the end of the method
            break;
        case 'platinum_accelerator':
             // Pre-check in spendPlatinumPoints ensures it's not already active
            isCrisisAcceleratorActive = true;
            crisisAcceleratorEndTime = purchaseTime.add(const Duration(days: 1)); // 24h duration
            print("INFO: Crisis Accelerator Activated! Ends at: $crisisAcceleratorEndTime");
            // TODO: Add user-facing notification.
             // notifyListeners(); // Called at the end of the method
            break;
        // --- Cosmetics ---
        case 'platinum_mogul':
            isExecutiveThemeUnlocked = true;
            // ADDED: Unlock mogul avatars
            isMogulAvatarsUnlocked = true;
            print("Unlocked Executive Theme and Mogul Avatars (via Platinum Mogul).");
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
            // Pre-check in spendPlatinumPoints ensures it's not already active and not on cooldown
            isIncomeSurgeActive = true;
            incomeSurgeEndTime = purchaseTime.add(const Duration(hours: 1));
            incomeSurgeCooldownEnd = purchaseTime.add(const Duration(days: 1)); // 24h cooldown
            print("INFO: Income Surge Activated! Ends at: $incomeSurgeEndTime. Cooldown until: $incomeSurgeCooldownEnd");
            // TODO: Add user-facing notification.
            // notifyListeners(); // Called at the end of the method
            break;
        case 'platinum_warp':
            // Pre-check in spendPlatinumPoints ensures limit not reached
            double offlineHours = 4.0; // Defined by the item
            // Use the existing calculateOfflineIncome which respects multipliers etc.
            double offlineIncome = calculateOfflineIncome(Duration(hours: offlineHours.toInt()));
            if (offlineIncome > 0) {
                money += offlineIncome;
                totalEarned += offlineIncome;
                passiveEarnings += offlineIncome; // Attribute to passive
                print("INFO: Awarded ${NumberFormatter.formatCompact(offlineIncome)} offline income via Platinum Warp (${offlineHours}h).");
                // TODO: Add user-facing notification.
            } else {
                 print("INFO: Platinum Warp: No offline income calculated (income/sec might be zero).");
            }
            timeWarpUsesThisPeriod++; // Increment usage count
            print("INFO: Time Warp uses this period: $timeWarpUsesThisPeriod/2");
            // notifyListeners(); // Called at the end of the method
            break;
        case 'platinum_cache':
             // Pre-check in spendPlatinumPoints ensures not on cooldown
             double cashAward = _calculateScaledCashCache(); // Use helper for scaling
             money += cashAward;
             totalEarned += cashAward; // Track earnings
             // Maybe attribute to a specific category later?
             // passiveEarnings += cashAward; // Or maybe manualEarnings?
             cashCacheCooldownEnd = purchaseTime.add(const Duration(days: 1)); // 24h cooldown
             print("Awarded ${NumberFormatter.formatCompact(cashAward)} via Platinum Cache. Cooldown until: $cashCacheCooldownEnd");
             // TODO: Add user-facing notification.
             // notifyListeners(); // Called at the end of the method
             break;
        case 'perm_income_boost_5pct':
            isPermanentIncomeBoostActive = true;
            print("Activated Permanent Income Boost (+5%). Effect applied in income calculation.");
            break;
        case 'perm_click_boost_10pct':
            isPermanentClickBoostActive = true;
            print("Activated Permanent Click Boost (+10%). Effect applied in tap calculation.");
            break;
        case 'golden_cursor': // Cosmetic Unlock - Kept separate for clarity
             isGoldenCursorUnlocked = true;
            break;
        // --- ADDED: Platinum Click Boosters ---
        case 'temp_boost_10x_5min': // Click Frenzy
             platinumClickFrenzyEndTime = DateTime.now().add(const Duration(minutes: 5));
             platinumClickFrenzyRemainingSeconds = 300;
             _startPlatinumClickFrenzyTimer();
             print("INFO: Click Frenzy (10x) Activated! Ends at: $platinumClickFrenzyEndTime");
             notifyListeners();
             break;
        case 'temp_boost_2x_10min': // Steady Boost
             platinumSteadyBoostEndTime = DateTime.now().add(const Duration(minutes: 10));
             platinumSteadyBoostRemainingSeconds = 600;
             _startPlatinumSteadyBoostTimer();
             print("INFO: Steady Boost (2x) Activated! Ends at: $platinumSteadyBoostEndTime");
             notifyListeners();
             break;
        // --- END: Platinum Click Boosters ---
        case 'unlock_stats_theme_1':
            print("DEBUG: Before unlock: isExecutiveStatsThemeUnlocked=$isExecutiveStatsThemeUnlocked");
            isExecutiveStatsThemeUnlocked = true;
            print("DEBUG: After unlock: isExecutiveStatsThemeUnlocked=$isExecutiveStatsThemeUnlocked");
            print("Unlocked Executive Stats Theme. User can now select it as an option.");
            break;
        case 'cosmetic_platinum_frame':
            print("DEBUG: Before unlock: isPlatinumFrameUnlocked=$isPlatinumFrameUnlocked");
            isPlatinumFrameUnlocked = true;
            print("DEBUG: After unlock: isPlatinumFrameUnlocked=$isPlatinumFrameUnlocked");
            print("Unlocked Platinum UI Frame. User can now enable it in Settings.");
            break;
        default:
            print("WARNING: Unknown Platinum Vault item ID: $itemId");
    }
    notifyListeners(); // Notify after applying effect
  }

  // ADDED: Helper to calculate scaled cash cache amount
  double _calculateScaledCashCache() {
    // Example scaling: 15 minutes of current passive income?
    // Or based on total earned, net worth, etc.
    // Let's use 15 minutes of total passive income per second for now.
    double passiveIncomePerSecond = calculateTotalIncomePerSecond(); // Use the detailed calculation
    double cashAmount = passiveIncomePerSecond * 60 * 15; // 15 minutes worth

    // Add a small floor value and potentially cap it?
    cashAmount = max(cashAmount, 1000.0); // Minimum $1k
    // Example cap: Maybe 1% of current money or net worth?
    // cashAmount = min(cashAmount, money * 0.01); // Cap at 1% of current cash (can be low)
    // cashAmount = min(cashAmount, calculateNetWorth() * 0.005); // Cap at 0.5% of net worth

    print("Calculating Cash Cache: Passive/sec=$passiveIncomePerSecond, Base Award=$cashAmount");
    return cashAmount;
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
          category: 'Technology',// Or a unique category like 'Quantum'
          dividendPerSecond: 1750000, // 1.75 million per second
          marketCap: 4.0e12, // 4 Trillion market cap
          // Potentially add a high dividend yield as well for extra reward/risk
          // dividendPerSecond: 50000.0, // Example: 50k/sec per share
      ));
  }

  // ADDED: Helper to calculate potential offline income for a given duration
  double calculateOfflineIncome(Duration offlineDuration) {
    // Cap to max 8 hours of offline income to prevent massive numbers
    final int maxSeconds = 8 * 60 * 60; // 8 hours in seconds
    final int actualSeconds = min(offlineDuration.inSeconds, maxSeconds);
    
    // Calculate based on total income per second
    return calculateTotalIncomePerSecond() * actualSeconds;
  }
  
  // Calculate total income per second (including all sources)
  double calculateTotalIncomePerSecond() {
    // Business income per second
    double businessIncome = 0.0;
    for (var business in businesses) {
      if (business.level > 0) {
        double cyclesPerSecond = 1 / business.incomeInterval;
        double baseIncomePerSecond = business.getCurrentIncome(isResilienceActive: isPlatinumResilienceActive) * cyclesPerSecond;
        // Apply efficiency multiplier
        double modifiedIncomePerSecond = baseIncomePerSecond * (isPlatinumEfficiencyActive ? 1.05 : 1.0);
        businessIncome += modifiedIncomePerSecond;
      }
    }
    
    // Real estate income per second
    double realEstateIncome = 0.0;
    for (var locale in realEstateLocales) {
      if (locale.unlocked) {
        bool isFoundationApplied = platinumFoundationsApplied.containsKey(locale.id);
        bool isYachtDocked = platinumYachtDockedLocaleId == locale.id;
        double foundationMultiplier = isFoundationApplied ? 1.05 : 1.0;
        double yachtMultiplier = isYachtDocked ? 1.05 : 1.0;
        
        for (var property in locale.properties) {
          if (property.owned > 0) {
            double basePerSecond = property.getTotalIncomePerSecond(isResilienceActive: isPlatinumResilienceActive);
            realEstateIncome += basePerSecond * foundationMultiplier * yachtMultiplier;
          }
        }
      }
    }
    
    // Dividend income per second
    double dividendIncome = 0.0;
    double diversificationBonus = calculateDiversificationBonus();
    double portfolioMultiplier = isPlatinumPortfolioActive ? 1.25 : 1.0;
    
    for (var investment in investments) {
      if (investment.owned > 0 && investment.hasDividends()) {
        double baseDividendPerSecond = investment.getDividendIncomePerSecond();
        double effectiveDividendPerShare = baseDividendPerSecond * portfolioMultiplier * (1 + diversificationBonus);
        dividendIncome += effectiveDividendPerShare * investment.owned;
      }
    }
    
    // Apply global multipliers
    double baseTotal = businessIncome + realEstateIncome + dividendIncome;
    double withGlobalMultipliers = baseTotal * incomeMultiplier * prestigeMultiplier;
    
    // Apply permanent income boost
    if (isPermanentIncomeBoostActive) {
      withGlobalMultipliers *= 1.05;
    }
    
    // Apply income surge if active
    if (isIncomeSurgeActive) {
      withGlobalMultipliers *= 2.0;
    }
    
    return withGlobalMultipliers;
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

  // --- ADDED: Helper methods for Platinum Booster Timers ---
  void _startPlatinumClickFrenzyTimer() {
    _platinumClickFrenzyTimer?.cancel(); // Cancel existing timer if any
    _platinumClickFrenzyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (platinumClickFrenzyRemainingSeconds > 0) {
        platinumClickFrenzyRemainingSeconds--;
        notifyListeners(); // Notify UI about remaining time change
      } else {
        timer.cancel();
        _platinumClickFrenzyTimer = null;
        platinumClickFrenzyEndTime = null; // Clear end time when timer finishes
        print("INFO: Click Frenzy boost expired.");
        notifyListeners(); // Notify UI that boost is no longer active
      }
    });
  }

  void _startPlatinumSteadyBoostTimer() {
    _platinumSteadyBoostTimer?.cancel(); // Cancel existing timer if any
    _platinumSteadyBoostTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (platinumSteadyBoostRemainingSeconds > 0) {
        platinumSteadyBoostRemainingSeconds--;
        notifyListeners(); // Notify UI about remaining time change
      } else {
        timer.cancel();
        _platinumSteadyBoostTimer = null;
        platinumSteadyBoostEndTime = null; // Clear end time when timer finishes
        print("INFO: Steady Boost expired.");
        notifyListeners(); // Notify UI that boost is no longer active
      }
    });
  }

  void _cancelPlatinumTimers() {
    _platinumClickFrenzyTimer?.cancel();
    _platinumSteadyBoostTimer?.cancel();
    _platinumClickFrenzyTimer = null;
    _platinumSteadyBoostTimer = null;
  }
  // --- END: Helper methods for Platinum Booster Timers ---

  // IMPROVED: Check and trigger notification display
  bool checkAndClearOfflineEarnings() {
    print("🔍 Checking offline earnings: amount=$offlineEarningsAwarded, duration=${offlineDurationForNotification?.inSeconds ?? 0}s, shouldShow=$_shouldShowOfflineEarnings");
    
    // ENHANCED VALIDATION: Check for sane values
    bool hasValidAmount = offlineEarningsAwarded > 0 && offlineEarningsAwarded.isFinite;
    bool hasValidDuration = offlineDurationForNotification != null && 
                            offlineDurationForNotification!.inSeconds > 0 &&
                            offlineDurationForNotification!.inSeconds <= 86400; // Max 1 day
    
    // Check if we have valid offline income to show
    if (_shouldShowOfflineEarnings && hasValidAmount && hasValidDuration) {
      print("✅ Valid offline income found! Amount: $offlineEarningsAwarded for ${offlineDurationForNotification!.inSeconds}s");
      
      // Clear flag after checking (caller will show notification)
      _shouldShowOfflineEarnings = false;
      notifyListeners();
      return true;
    }
    
    // Log why we're not showing offline income
    if (!_shouldShowOfflineEarnings) {
      print("❌ Not showing offline income: shouldShowOfflineEarnings is false");
    } else if (!hasValidAmount) {
      print("❌ Not showing offline income: Invalid amount $offlineEarningsAwarded");
    } else if (!hasValidDuration) {
      print("❌ Not showing offline income: Invalid duration ${offlineDurationForNotification?.inSeconds}s");
    }
    
    return false;
  }

  // ADDED: Get offline earnings data for notification
  Map<String, dynamic> getOfflineEarningsData() {
    return {
      'amount': offlineEarningsAwarded,
      'duration': offlineDurationForNotification ?? Duration.zero
    };
  }
  
  // ADDED: Clear offline notification state
  void clearOfflineNotification() {
    _shouldShowOfflineEarnings = false;
    offlineEarningsAwarded = 0.0;
    offlineDurationForNotification = null;
    notifyListeners();
  }
  
  // ADDED: Method to dismiss premium purchase notification
  void dismissPremiumPurchaseNotification() {
    showPremiumPurchaseNotification = false;
    notifyListeners();
  }

  // Function to select a stats theme (add this function)
  void selectStatsTheme(String? theme) {
    print("DEBUG: Selecting stats theme: $theme, Current unlock status: isExecutiveStatsThemeUnlocked=$isExecutiveStatsThemeUnlocked");
    if (theme == null || theme == 'default' || (theme == 'executive' && isExecutiveStatsThemeUnlocked)) {
      selectedStatsTheme = theme;
      notifyListeners();
      print("Stats theme changed to: ${theme ?? 'default'}");
    } else {
      print("Cannot select theme '$theme': Not unlocked or invalid theme.");
    }
  }
  
  // Method to toggle platinum frame display
  void togglePlatinumFrame(bool active) {
    print("DEBUG: Toggling platinum frame: $active, Current unlock status: isPlatinumFrameUnlocked=$isPlatinumFrameUnlocked");
    if (isPlatinumFrameUnlocked) {
      isPlatinumFrameActive = active;
      notifyListeners();
      print("Platinum frame ${active ? 'enabled' : 'disabled'}");
    } else {
      print("Cannot toggle platinum frame: Not unlocked.");
    }
  }

  // Public method to cancel the standard boost timer
  void cancelBoostTimer() {
    _boostTimer?.cancel();
    _boostTimer = null;
  }

  // Public method to cancel the ad boost timer
  void cancelAdBoostTimer() {
    _adBoostTimer?.cancel();
    _adBoostTimer = null;
  }

  // Apply platinum facade to a business
  void applyPlatinumFacade(String businessId) {
    // Find the business by ID
    final businessIndex = businesses.indexWhere((b) => b.id == businessId);
    if (businessIndex >= 0) {
      businesses[businessIndex].hasPlatinumFacade = true;
      
      // Also track this in the set for persistence
      platinumFacadeAppliedBusinessIds.add(businessId);
      
      // Notify listeners of the change
      notifyListeners();
    }
  }
  
  // Check if a business has platinum facade
  bool hasBusinessPlatinumFacade(String businessId) {
    return platinumFacadeAppliedBusinessIds.contains(businessId);
  }
  
  // Get list of businesses that can have platinum facade applied
  List<Business> getBusinessesForPlatinumFacade() {
    // Only return businesses that are owned (level > 0) and don't already have the facade
    return businesses.where((b) => b.level > 0 && !b.hasPlatinumFacade && b.unlocked).toList();
  }

  // Calculate the current income per second
  double _calculateIncomePerSecond() {
    return calculateTotalIncomePerSecond();
  }

  // ADDED: Method to manage platinum challenge daily limits
  void checkAndResetPlatinumChallengeLimit(DateTime now) {
    // If never used before, initialize
    if (lastPlatinumChallengeDayTracked == null) {
      lastPlatinumChallengeDayTracked = DateTime(now.year, now.month, now.day);
      platinumChallengeUsesToday = 0;
      return;
    }
    
    // Check if it's a new day
    DateTime currentDay = DateTime(now.year, now.month, now.day);
    if (currentDay.isAfter(lastPlatinumChallengeDayTracked!)) {
      // Reset the limit for the new day
      lastPlatinumChallengeDayTracked = currentDay;
      platinumChallengeUsesToday = 0;
      print("INFO: Platinum Challenge daily limit reset (0/2)");
    }
  }
  
  // ADDED: Method to check platinum challenge eligibility
  bool canStartPlatinumChallenge(DateTime now) {
    checkAndResetPlatinumChallengeLimit(now); // UPDATED call to public method
    
    // Check if there's already an active challenge
    if (activeChallenge != null && activeChallenge!.isActive(now)) {
      print("DEBUG: Cannot start Platinum Challenge: Already active.");
      return false;
    }
    
    // Check if we've reached the daily limit (2x per day)
    if (platinumChallengeUsesToday >= 2) {
      print("DEBUG: Cannot start Platinum Challenge: Daily limit (2) reached.");
      return false;
    }
    
    return true;
  }
  
  // UPDATED: Method to check and complete challenges in the update loop
  void _checkActiveChallenge(DateTime now) {
    if (activeChallenge == null) return;

    // Check for success FIRST, even if time hasn't expired
    if (activeChallenge!.wasSuccessful(totalEarned)) {
      // Award PP for successful challenge
      platinumPoints += activeChallenge!.rewardPP;
      showPPAnimation = true; // Trigger UI animation
      print("SUCCESS: Platinum Challenge completed! Awarded ${activeChallenge!.rewardPP} PP");
      
      // Create a temporary achievement-like notification for display
      Achievement challengeComplete = Achievement(
        id: 'temp_challenge_complete_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Challenge Completed!', 
        description: 'Successfully doubled your hourly income rate within the time limit!',
        icon: Icons.emoji_events,
        rarity: AchievementRarity.rare, // Use rare style for fancy display
        ppReward: activeChallenge!.rewardPP,
        category: AchievementCategory.progress, // Added category
      );
      
      // Queue the notification - sound will play through the achievement notification system
      queueAchievementsForDisplay([challengeComplete]);
      
      // Clear the completed challenge
      activeChallenge = null;
      notifyListeners();
      return; // Exit early since it's completed
    }

    // If not successful yet, check if the time has expired
    if (!activeChallenge!.isActive(now)) {
      print("FAILED: Platinum Challenge expired without reaching the goal.");
      // Clear the expired challenge
      activeChallenge = null;
      notifyListeners();
    }
  }

  // Platinum Challenge tracking
  DateTime? platinumChallengeLastUsedTime; // Tracks last usage for limit
  int platinumChallengeUsesToday = 0; // Tracks uses today (max 2)
  DateTime? lastPlatinumChallengeDayTracked; // For daily reset
}
