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
import '../utils/time_utils.dart'; // MOVED from offline_income_logic.dart
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
import '../services/income_service.dart'; // ADDED: Import for IncomeService
import '../services/admob_service.dart'; // ADDED: Import for AdMobService integration

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
part 'game_state/platinum_logic.dart';  // ADDED: New part file
part 'game_state/challenge_logic.dart'; // ADDED: New part file  
part 'game_state/booster_logic.dart';   // ADDED: New part file
part 'game_state/notification_logic.dart'; // ADDED: New part file
part 'game_state/promo_logic.dart';      // ADDED: Promo codes and deep-link rewards
part 'game_state/income_logic.dart';    // ADDED: New part file
part 'game_state/offline_income_logic.dart';    // ADDED: New part file for offline income

// Define a limit for how many days of earnings history to keep
const int _maxDailyEarningsHistory = 30; // Memory Optimization: Limit history size

class GameState with ChangeNotifier {
  // Timestamps for update tracking and optimization
  DateTime? _lastUpdateTime; // Track last game loop update time for debouncing
  DateTime? _lastInvestmentMicroUpdateTime; // Track last investment micro-update time
  DateTime? _lastDailyCheckTime; // Track last daily check time
  DateTime? _lastNetWorthUpdateTime; // Track last net worth update time
  DateTime? _lastEventStateCheckTime; // Track last event state check time for AdMobService

  // Timer state tracking
  bool timersActive = false;
  
  // ADDED: Track calculation state
  bool _isCalculatingIncome = false;
  double lastCalculatedIncomePerSecond = 0.0;
  
  // ADDED: Timestamp tracking to prevent duplicate income calculations
  final List<String> _processedIncomeTimestamps = <String>[];
  
  // ADDED: Global update ID tracking to prevent duplicate updates
  String? _lastProcessedUpdateId;

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
  
  // Google Play Games Services properties
  bool isGooglePlayConnected = false;
  String? googlePlayPlayerId;
  String? googlePlayDisplayName;
  String? googlePlayAvatarUrl;
  DateTime? lastCloudSync;
  
  // ADDED: Mogul avatar tracking
  bool isMogulAvatarsUnlocked = false;
  String? selectedMogulAvatarId;
  
  // ADDED: Premium avatar tracking
  bool isPremiumAvatarsUnlocked = false;
  String? selectedPremiumAvatarId;
  
  // ADDED: AdMobService integration for predictive ad loading
  AdMobService? _adMobService;
  
  // >> START: Platinum Points System Fields <<
  int platinumPoints = 0;
  bool _retroactivePPAwarded = false; // Flag for retroactive PP grant
  Map<String, int> ppPurchases = {}; // Tracks counts of repeatable PP items purchased {itemId: count}
  Set<String> ppOwnedItems = {};    // Tracks IDs of one-time PP items purchased {itemId}
  Set<String> redeemedPromoCodes = {}; // Promo codes already redeemed (deep links, etc.)
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
  DateTime? timeWarpCooldownEnd; // Cooldown for 'platinum_warp' (2h after each use)
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

  // ADDED: UI State Persistence - Real Estate Screen
  String? lastSelectedRealEstateLocaleId; // Remember last selected locale in Real Estate screen

  // ADDED: Net Worth Ticker State
  Offset? netWorthTickerPosition; // Position of the draggable net worth ticker
  bool isNetWorthTickerExpanded = false; // Collapsed (crown only) or expanded (full display)

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

  // Auto Clicker: hold-to-auto-click at 10/sec for 5 min
  int autoClickerRemainingSeconds = 0;
  DateTime? autoClickerEndTime;
  Timer? _autoClickerTimer;

  // Getter to check if *any* platinum click booster is active
  bool get isPlatinumBoostActive => platinumClickFrenzyRemainingSeconds > 0 || platinumSteadyBoostRemainingSeconds > 0 || autoClickerRemainingSeconds > 0;
  // << END: Platinum Booster State >>

  // >> START: Derived Active Flags for Boosters <<
  // Used to easily check if a specific booster is active for UI/logic
  bool get isClickFrenzyActive => platinumClickFrenzyRemainingSeconds > 0;
  bool get isSteadyBoostActive => platinumSteadyBoostRemainingSeconds > 0;
  bool get isAutoClickerActive => autoClickerRemainingSeconds > 0;
  // >> END: Derived Active Flags for Boosters <<

  // ADDED: Notification permission request tracking
  bool _shouldRequestNotificationPermissions = false;
  bool get shouldRequestNotificationPermissions => _shouldRequestNotificationPermissions;
  
  void resetNotificationPermissionRequest() {
    _shouldRequestNotificationPermissions = false;
  }

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
  
  // Premium restoration tracking
  bool hasUsedPremiumRestore = false; // Track if user has used their one-time restore
  bool isEligibleForPremiumRestore = false; // Track if user is eligible for restore (owns premium)

  // Lifetime stats (persist across reincorporation)
  int lifetimeTaps = 0;
  DateTime gameStartTime = DateTime.now(); // Tracks when the game was first started

  late AchievementManager achievementManager;

  // Achievement Notification Queue System
  final List<Achievement> _pendingAchievementNotifications = [];
  Achievement? _currentAchievementNotification;
  bool _isAchievementNotificationVisible = false;
  bool _isAchievementAnimationInProgress = false; // Flag to track animation state
  Timer? _achievementNotificationTimer; // ADDED: Timer for hiding notification

  List<Achievement> get pendingAchievementNotifications => List.unmodifiable(_pendingAchievementNotifications);
  Achievement? get currentAchievementNotification => _currentAchievementNotification;
  bool get isAchievementNotificationVisible => _isAchievementNotificationVisible;
  bool get isAchievementAnimationInProgress => _isAchievementAnimationInProgress;

  // CRITICAL FIX: ensure these are always initialized
  DateTime lastSaved = DateTime.now(); // When the game was last saved
  DateTime lastOpened = DateTime.now(); // When the game was last opened

  // Rate-us dialog (smart rate-us from promo/ASO)
  bool hasShownRateUsDialog = false;
  DateTime? rateUsDialogShownAt;

  // Login streak for achievements (consecutive days)
  DateTime? lastLoginDay;
  int consecutiveLoginDays = 1;

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
  double totalEventFeesPaid = 0.0; // Track total money spent on resolving events
  int eventsResolvedByTapping = 0;
  int eventsResolvedByFee = 0;
  double eventFeesSpent = 0.0;
  int eventsResolvedByAd = 0;
  int eventsResolvedByFallback = 0; // Resolved without a rewarded ad due to fail-open
  int eventsResolvedByPP = 0; // Resolved by spending Platinum Points
  int ppSpentOnEventSkips = 0; // Total PP spent on event skips
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
  // ADDED: Track actual networth accumulated at time of each reincorporation
  double lifetimeNetworkWorth = 0.0; // Accumulates actual networth at reincorporation time
  int reincorporationUsesAvailable = 0;
  int totalReincorporations = 0;
  
  // ADDED: Track which food stall branches have been maxed (persists through reincorporation)
  Set<String> maxedFoodStallBranches = {};

  Timer? _saveTimer;
  Timer? _updateTimer;
  Timer? _investmentUpdateTimer;

  // Timer delegates from GameService (scheduleOneShot / cancelScheduled)
  void Function(String id, Duration delay, void Function() action)? _scheduleOneShot;
  void Function(String id)? _cancelScheduled;

  // Income tracking to prevent duplicate application
  DateTime? _lastIncomeApplicationTime;

  // Future for tracking real estate initialization
  Future<void>? realEstateInitializationFuture;

  /// Optional callback for throttled leaderboard score submit (same interval as net worth history).
  /// Set from app init; receives this GameState so caller can submit totalLifetimeNetWorth via AuthService.
  void Function(GameState)? onThrottledLeaderboardSubmit;

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
       _setupTimers(); // No-op; GameService TimerService drives all timers
       notifyListeners();
    }).catchError((e, stackTrace) {
        print("❌❌❌ CRITICAL ERROR during Real Estate Upgrade Initialization: $e");
        print(stackTrace);
        isInitialized = true; // Still mark as initialized to allow game to run potentially degraded
        print("⚠️ GameState Initialized (with RE upgrade error). Setting up timers...");
        _setupTimers(); // No-op; GameService TimerService drives all timers
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
    // No-op: TimerService in GameService drives the 1s game update and 30s investment update.
    // Do not create timers here to avoid duplicate ticks (see docs/CODEBASE_CONSISTENCY_ANALYSIS.md).
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
    if (!isInitialized) return; // Skip if not initialized
    
    final DateTime now = DateTime.now();
    final String hourKey = TimeUtils.getHourKey(now);
    final String dayKey = TimeUtils.getDayKey(now);
    
    // OPTIMIZED SAFEGUARD: Prevent duplicate income application with improved thresholds
    // Increased threshold and reduced logging frequency to improve performance
    if (_lastIncomeApplicationTime != null) {
      final int msSinceLastIncome = now.difference(_lastIncomeApplicationTime!).inMilliseconds;
      if (msSinceLastIncome < 1000) { // Increased to full second for better stability
        // Only log every 20th skip and only if significant delay to reduce spam
        if (msSinceLastIncome < 100 && DateTime.now().second % 20 == 0 && DateTime.now().millisecond < 100) {
          print("! INCOME SAFEGUARD: Skipping income application - too soon (${msSinceLastIncome}ms since last)");
        }
        return; // Skip update entirely if too soon
      }
    }
    
    // Apply all daily updates if needed
    if (currentDay != now.weekday) {
      currentDay = now.weekday;
      _updateInvestments(); // Update investments on day change
      _updateInvestmentPrices(); // Update prices on day change
    }

    try {
      // Track the last time income was applied to prevent duplicate income
      _lastIncomeApplicationTime = now;

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
            double income = business.getCurrentIncome(isResilienceActive: isPlatinumResilienceActive) * businessEfficiencyMultiplier;
            // Then apply standard multipliers
            income *= incomeMultiplier; // Removed prestigeMultiplier
            // Then apply the overall permanent boost
            income *= permanentIncomeBoostMultiplier;
            // ADDED: Apply Income Surge
            if (isIncomeSurgeActive) income *= 2.0;
            
            // CRITICAL FIX: Apply event penalty if business is affected
            if (hasEvent) {
              income *= GameStateEvents.NEGATIVE_EVENT_MULTIPLIER;
            }
            
            businessIncomeThisTick += income;
            business.secondsSinceLastIncome = 0;
          }
        }
      }
      if (businessIncomeThisTick != 0) {
        money += businessIncomeThisTick;
        totalEarned += businessIncomeThisTick;
        passiveEarnings += businessIncomeThisTick;
        _updateHourlyEarnings(hourKey, businessIncomeThisTick);
      }

      // Generate real estate income
      double realEstateIncomePerSecond = getRealEstateIncomePerSecond();
      // Apply standard multipliers
      double realEstateIncomeThisTick = realEstateIncomePerSecond * incomeMultiplier; // Removed prestigeMultiplier
      // Apply the overall permanent boost
      realEstateIncomeThisTick *= permanentIncomeBoostMultiplier;
      // Apply Income Surge (if applicable)
      if (isIncomeSurgeActive) realEstateIncomeThisTick *= 2.0;
      if (realEstateIncomeThisTick != 0) { // Changed from > 0 to != 0 to handle negative income
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
                               permanentIncomeBoostMultiplier;
          // ADDED: Apply Income Surge
          if (isIncomeSurgeActive) investmentDividend *= 2.0;
          dividendIncomeThisTick += investmentDividend;
        }
      }
      if (dividendIncomeThisTick != 0) { // Changed from > 0 to != 0 to handle negative income
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

  // Market event methods have been moved to investment_logic.dart
  // This reduces code duplication and centralizes market event functionality

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
        else if (business.id == 'platinum_venture' && isPlatinumVentureUnlocked && money >= 500000000.0) business.unlocked = true;
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

  /// Total lifetime net worth (current net worth + accumulated from reincorporations). Used for leaderboard.
  double get totalLifetimeNetWorth => lifetimeNetworkWorth + calculateNetWorth();

  // Dispose timers when GameState is disposed
  @override
  void dispose() {
    print("🗑️ Disposing GameState resources");
    // Call the extension method to properly clean up timers
    if (timersActive) {
      cancelAllTimers();
    }
    
    _boostTimer?.cancel();
    _adBoostTimer?.cancel();
    _platinumClickFrenzyTimer?.cancel();
    _platinumSteadyBoostTimer?.cancel();
    _achievementNotificationTimer?.cancel();
    
    super.dispose();
  }

  // enablePremium method moved to utility_logic.dart extension to avoid conflicts

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
                return false; // Already active, no double-stack
            }
            break;
        case 'temp_boost_2x_10min':
            if (isSteadyBoostActive) {
                print("DEBUG: Cannot purchase $itemId: Already active.");
                return false; // Already active, no double-stack
            }
            break;
        case 'auto_clicker':
            if (isAutoClickerActive) {
                print("DEBUG: Cannot purchase $itemId: Already active.");
                return false; // Prevent stacking
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
            // Use the selected locale ID from the context
            String? targetLocaleId = purchaseContext?['selectedLocaleId'] as String?;

            if (targetLocaleId != null && realEstateLocales.any((l) => l.id == targetLocaleId && l.unlocked) && platinumSpireLocaleId == null) {
                platinumSpireLocaleId = targetLocaleId;
                print("Placed Platinum Spire Trophy in locale $targetLocaleId");
            } else if (targetLocaleId == null) {
                print("ERROR: Could not place Platinum Spire Trophy - missing selectedLocaleId in context.");
            } else {
                print("Failed to place Platinum Spire Trophy: Invalid target or spire already placed.");
            }
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
            double incomePerSecond = calculateTotalIncomePerSecond(); // FIX: Use correct method for current income rate
            double oneHourInSeconds = 1.0 * 60 * 60; // 1 hour in seconds
            double incomeAward = incomePerSecond * oneHourInSeconds;
            
            if (incomeAward > 0) {
                money += incomeAward;
                totalEarned += incomeAward;
                passiveEarnings += incomeAward; // Attribute to passive
                print("INFO: Awarded ${NumberFormatter.formatCompact(incomeAward)} via Income Warp (1 hour of income).");
                // TODO: Add user-facing notification.
            } else {
                print("INFO: Income Warp: No income calculated (income/sec might be zero).");
            }
            timeWarpUsesThisPeriod++; // Increment usage count
            print("INFO: Income Warp uses this period: $timeWarpUsesThisPeriod/2");
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
        case 'auto_clicker':
             autoClickerEndTime = DateTime.now().add(const Duration(minutes: 5));
             autoClickerRemainingSeconds = 300;
             _startPlatinumAutoClickerTimer();
             print("INFO: Auto Clicker Activated! Ends at: $autoClickerEndTime");
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
        
        // CRITICAL FIX: Apply event penalty if business is affected
        bool hasEvent = hasActiveEventForBusiness(business.id);
        if (hasEvent) {
          modifiedIncomePerSecond *= GameStateEvents.NEGATIVE_EVENT_MULTIPLIER;
        }
        
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
        
        // CRITICAL FIX: Apply event penalty if locale is affected
        bool hasEvent = hasActiveEventForLocale(locale.id);
        
        for (var property in locale.properties) {
          if (property.owned > 0) {
            double basePerSecond = property.getTotalIncomePerSecond(isResilienceActive: isPlatinumResilienceActive);
            double incomeWithBoosts = basePerSecond * foundationMultiplier * yachtMultiplier;
            
            // Apply event penalty if locale is affected
            if (hasEvent) {
              incomeWithBoosts *= GameStateEvents.NEGATIVE_EVENT_MULTIPLIER;
            }
            
            realEstateIncome += incomeWithBoosts;
          }
        }
      }
    }
    
    // Dividend income per second (investments are not affected by events)
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
    double withGlobalMultipliers = baseTotal * incomeMultiplier;
    
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
    _autoClickerTimer?.cancel();
    _platinumClickFrenzyTimer = null;
    _platinumSteadyBoostTimer = null;
    _autoClickerTimer = null;
  }

  void _startPlatinumAutoClickerTimer() {
    _autoClickerTimer?.cancel();
    _autoClickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (autoClickerRemainingSeconds > 0) {
        autoClickerRemainingSeconds--;
        notifyListeners();
      } else {
        timer.cancel();
        _autoClickerTimer = null;
        autoClickerEndTime = null;
        print("INFO: Auto Clicker expired.");
        notifyListeners();
      }
    });
  }
  // --- END: Helper methods for Platinum Booster Timers ---

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

  // Methods for Net Worth Ticker state management
  void toggleNetWorthTicker() {
    isNetWorthTickerExpanded = !isNetWorthTickerExpanded;
    notifyListeners();
  }

  void setNetWorthTickerPosition(Offset position) {
    netWorthTickerPosition = position;
    notifyListeners();
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
  // Income calculation methods have been moved to income_logic.dart

  // Platinum challenge methods have been moved to challenge_logic.dart
  // This reduces code duplication and centralizes challenge functionality

  // Platinum Challenge tracking
  DateTime? platinumChallengeLastUsedTime; // Tracks last usage for limit
  int platinumChallengeUsesToday = 0; // Tracks uses today (max 2)
  DateTime? lastPlatinumChallengeDayTracked; // For daily reset

  // Utility method to update hourly earnings (used by multiple extensions to avoid conflicts)
  // This public method delegates to the implementation in update_logic.dart
  void updateHourlyEarnings(String hourKey, double amount) {
    // CRITICAL FIX: Don't create a new extension instance for each call
    // Instead, directly call the method which preserves the safeguards against duplicate updates
    // The implementation in update_logic.dart handles duplicate prevention and periodic pruning
    hourlyEarnings[hourKey] = (hourlyEarnings[hourKey] ?? 0) + amount;
    
    // Only prune periodically to reduce overhead
    if (hourlyEarnings.length > 45) { // Using the same threshold as in update_logic.dart
      // Pruning logic will be handled by the update loop
    }
  }

  // Public method to cancel all timers (for game_service.dart to use)
  void cancelAllTimers() {
    if (timersActive) {
      print("🛑 External call to cancel all game timers");
      _cancelAllTimers(); // Extension no-op; TimerService cancels its own timers
    }
    // Also cancel any timers owned by this GameState (legacy / safety)
    if (_updateTimer != null) {
      _updateTimer!.cancel();
      _updateTimer = null;
    }
    if (_investmentUpdateTimer != null) {
      _investmentUpdateTimer!.cancel();
      _investmentUpdateTimer = null;
    }
    timersActive = false;
  }
  
  // This method is kept for backward compatibility but delegates to the centralized timer system
  // Do not call this directly - GameService manages all timers
  @deprecated
  void setupTimers() {
    print("⏱️ DEPRECATED: External call to set up game timers - using centralized system instead");
    // No longer setting up timers directly in GameState
  }
  
  // Public method to update game state (called by centralized timer in GameService)
  void updateGameState() {
    // CRITICAL FIX: Don't create a new extension instance for each call
    // Instead, use direct method call which preserves the extension's internal state tracking
    _updateGameState(); // Call the extension method directly to preserve safeguards
  }
  
  // Public method to update investment prices (called by centralized timer in GameService)
  void updateInvestmentPrices() {
    _updateInvestmentPrices(); // Call the extension method directly to preserve state
  }

  /// Register timer callbacks from GameService (scheduleOneShot, cancelScheduled).
  void registerTimerDelegates({
    required void Function() cancelAllTimers,
    required void Function(String id, Duration delay, void Function() action) scheduleOneShot,
    required void Function(String id) cancelScheduled,
  }) {
    _scheduleOneShot = scheduleOneShot;
    _cancelScheduled = cancelScheduled;
  }

  /// Schedule a one-shot timer (delegates to TimerService).
  void scheduleTimer(String id, Duration delay, void Function() action) {
    _scheduleOneShot?.call(id, delay, action);
  }

  /// Cancel a scheduled one-shot (delegates to TimerService).
  void cancelScheduledTimer(String id) {
    _cancelScheduled?.call(id);
  }

  /// Update login streak when loading or opening app (new day = increment, gap = reset to 1).
  void _updateLoginStreak(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    if (lastLoginDay == null) {
      lastLoginDay = today;
      consecutiveLoginDays = 1;
      return;
    }
    final last = DateTime(lastLoginDay!.year, lastLoginDay!.month, lastLoginDay!.day);
    final daysDiff = today.difference(last).inDays;
    if (daysDiff == 0) {
      return;
    }
    if (daysDiff == 1) {
      consecutiveLoginDays += 1;
      lastLoginDay = today;
    } else {
      consecutiveLoginDays = 1;
      lastLoginDay = today;
    }
    notifyListeners();
  }

  // >> START: Offline Income Fields <<
  double offlineIncome = 0.0;
  DateTime? offlineIncomeStartTime;
  DateTime? offlineIncomeEndTime;
  bool showOfflineIncomeNotification = false;
  // >> END: Offline Income Fields <<

  // --- Offline Income Ad Bonus State ---
  bool _offlineIncomeAdWatched = false;
  bool get offlineIncomeAdWatched => _offlineIncomeAdWatched;
  void setOfflineIncomeAdWatched(bool value) {
    _offlineIncomeAdWatched = value;
    notifyListeners();
  }
  
  // ADDED: AdMobService integration methods for predictive ad loading
  void setAdMobService(AdMobService adMobService) {
    _adMobService = adMobService;
    // Update initial state when AdMobService is set
    _updateAdMobServiceGameState();
  }
  
  void _updateAdMobServiceGameState() {
    if (_adMobService != null) {
      _adMobService!.updateGameState(
        businessCount: businesses.length,
        firstBusinessLevel: businesses.isNotEmpty ? businesses.first.level : 1,
        hasActiveEvents: activeEvents.isNotEmpty,
        hasOfflineIncome: showOfflineIncomeNotification,
      );
    }
  }
  
  // Call this method whenever event state changes
  void notifyAdMobServiceOfEventStateChange() {
    if (_adMobService != null) {
      final bool hasActiveEvents = activeEvents.isNotEmpty;
      if (kDebugMode) {
        print('🎯 Notifying AdMobService: hasActiveEvents = $hasActiveEvents (${activeEvents.length} events)');
      }
      _adMobService!.updateGameState(hasActiveEvents: hasActiveEvents);
    }
  }
}
