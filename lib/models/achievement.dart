import 'package:flutter/material.dart';
import 'game_state.dart';
import 'event.dart'; // Import for EventType extension

enum AchievementCategory {
  progress,
  wealth,
  regional,
}

enum AchievementRarity {
  basic,    // Common achievements, relatively easy to obtain
  rare,     // More challenging achievements that require significant progress
  milestone // Major game milestones that represent significant accomplishments
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final AchievementCategory category;
  final AchievementRarity rarity;
  bool completed;
  final DateTime? completedTimestamp;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    this.rarity = AchievementRarity.basic,
    this.completed = false,
    this.completedTimestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'completed': completed,
      'completedTimestamp': completedTimestamp?.toIso8601String(),
    };
  }
}

class AchievementManager {
  List<Achievement> achievements = [];

  static const Set<String> _tropicalLocaleIds = {'rural_thailand', 'ho_chi_minh_city', 'miami_florida'}; // Example IDs - replace with actual IDs
  static const Set<String> _urbanLocaleIds = {
      'lagos_nigeria', 'mumbai_india', 'singapore', 'hong_kong', 'berlin_germany',
      'london_uk', 'mexico_city', 'new_york_city', 'los_angeles', 'sao_paulo_brazil', 'dubai_uae'
  }; // Example IDs - replace with actual IDs
  static const Set<String> _ruralLocaleIds = {'rural_kenya', 'rural_thailand', 'rural_mexico'}; // Example IDs - replace with actual IDs

  AchievementManager(GameState gameState) {
    _initializeAchievements();
  }

  void _initializeAchievements() {
    achievements = [
      Achievement(
        id: 'first_business',
        name: 'Entrepreneur',
        description: 'Buy your first business',
        icon: Icons.store,
        category: AchievementCategory.progress,
        rarity: AchievementRarity.basic,
      ),
      Achievement(
        id: 'five_businesses',
        name: 'Business Mogul',
        description: 'Own 5 different types of businesses',
        icon: Icons.corporate_fare,
        category: AchievementCategory.progress,
        rarity: AchievementRarity.basic,
      ),
      Achievement(
        id: 'first_investment',
        name: 'Investor',
        description: 'Make your first investment',
        icon: Icons.trending_up,
        category: AchievementCategory.progress,
        rarity: AchievementRarity.basic,
      ),
      Achievement(
        id: 'first_real_estate',
        name: 'Property Owner',
        description: 'Purchase your first real estate property',
        icon: Icons.home,
        category: AchievementCategory.progress,
        rarity: AchievementRarity.basic,
      ),
      Achievement(
        id: 'tap_master',
        name: 'Tap Master',
        description: 'Tap 1,000 times',
        icon: Icons.touch_app,
        category: AchievementCategory.progress,
        rarity: AchievementRarity.basic,
      ),

      Achievement(
        id: 'all_businesses',
        name: 'Empire Builder',
        description: 'Own at least one of each type of business',
        icon: Icons.location_city,
        category: AchievementCategory.progress,
        rarity: AchievementRarity.rare,
      ),
      Achievement(
        id: 'max_level_business',
        name: 'Expansion Expert',
        description: 'Upgrade any business to maximum level',
        icon: Icons.arrow_upward,
        category: AchievementCategory.progress,
        rarity: AchievementRarity.rare,
      ),
      Achievement(
        id: 'big_investment',
        name: 'Stock Market Savvy',
        description: 'Own investments worth 100,000 dollars or more',
        icon: Icons.attach_money,
        category: AchievementCategory.progress,
        rarity: AchievementRarity.rare,
      ),
      Achievement(
        id: 'tap_champion',
        name: 'Tap Champion',
        description: 'Tap 10,000 times',
        icon: Icons.back_hand,
        category: AchievementCategory.progress,
        rarity: AchievementRarity.rare,
      ),
      Achievement(
        id: 'first_reincorporation',
        name: 'Corporate Phoenix',
        description: 'Complete your first re-incorporation',
        icon: Icons.cyclone,
        category: AchievementCategory.progress,
        rarity: AchievementRarity.rare,
      ),

      Achievement(
        id: 'crisis_manager',
        name: 'Crisis Manager',
        description: 'Resolve 10 events across your empire to prove your management skills',
        icon: Icons.task_alt,
        category: AchievementCategory.progress,
        rarity: AchievementRarity.basic,
      ),
      Achievement(
        id: 'tap_titan',
        name: 'Tap Titan',
        description: 'Tap your way through 1,000 clicks to solve crises manually',
        icon: Icons.touch_app,
        category: AchievementCategory.progress,
        rarity: AchievementRarity.basic,
      ),
      Achievement(
        id: 'ad_enthusiast',
        name: 'Ad Enthusiast',
        description: 'Watch 25 ads to resolve events quickly and keep your empire running',
        icon: Icons.ondemand_video,
        category: AchievementCategory.progress,
        rarity: AchievementRarity.basic,
      ),
      Achievement(
        id: 'event_veteran',
        name: 'Event Veteran',
        description: 'Resolve 50 events to become a seasoned crisis handler',
        icon: Icons.gpp_good,
        category: AchievementCategory.progress,
        rarity: AchievementRarity.rare,
      ),
      Achievement(
        id: 'quick_fixer',
        name: 'Quick Fixer',
        description: 'Resolve 5 events within 5 minutes of their occurrence',
        icon: Icons.timer,
        category: AchievementCategory.progress,
        rarity: AchievementRarity.rare,
      ),
      Achievement(
        id: 'business_specialist',
        name: 'Business Specialist',
        description: 'Resolve 25 business events to master corporate crisis management',
        icon: Icons.business,
        category: AchievementCategory.progress,
        rarity: AchievementRarity.rare,
      ),

      Achievement(
        id: 'all_max_level',
        name: 'Business Perfectionist',
        description: 'Upgrade all businesses to maximum level',
        icon: Icons.star,
        category: AchievementCategory.progress,
        rarity: AchievementRarity.milestone,
      ),
      Achievement(
        id: 'max_reincorporations',
        name: 'Corporate Dynasty',
        description: 'Complete all 9 re-incorporations (1M to 100T dollars)',
        icon: Icons.sync_alt,
        category: AchievementCategory.progress,
        rarity: AchievementRarity.milestone,
      ),

      Achievement(
        id: 'first_thousand',
        name: 'First Grand',
        description: 'Earn your first 1000 dollars',
        icon: Icons.monetization_on,
        category: AchievementCategory.wealth,
        rarity: AchievementRarity.basic,
      ),

      Achievement(
        id: 'crisis_investor',
        name: 'Crisis Investor',
        description: 'Spend 50,000 dollars resolving events to keep your empire afloat',
        icon: Icons.attach_money,
        category: AchievementCategory.wealth,
        rarity: AchievementRarity.basic,
      ),

      Achievement(
        id: 'first_million',
        name: 'Millionaire',
        description: 'Reach 1,000,000 dollars in total earnings',
        icon: Icons.emoji_events,
        category: AchievementCategory.wealth,
        rarity: AchievementRarity.rare,
      ),
      Achievement(
        id: 'passive_income_master',
        name: 'Passive Income Master',
        description: 'Earn 10,000 dollars per second in passive income',
        icon: Icons.update,
        category: AchievementCategory.wealth,
        rarity: AchievementRarity.rare,
      ),
      Achievement(
        id: 'investment_genius',
        name: 'Investment Genius',
        description: 'Make 500,000 dollars profit from investments',
        icon: Icons.insert_chart,
        category: AchievementCategory.wealth,
        rarity: AchievementRarity.rare,
      ),
      Achievement(
        id: 'real_estate_tycoon',
        name: 'Real Estate Tycoon',
        description: 'Own 20 real estate properties',
        icon: Icons.apartment,
        category: AchievementCategory.wealth,
        rarity: AchievementRarity.rare,
      ),

      Achievement(
        id: 'first_billion',
        name: 'Billionaire',
        description: 'Reach 1,000,000,000 dollars in total earnings',
        icon: Icons.diamond,
        category: AchievementCategory.wealth,
        rarity: AchievementRarity.milestone,
      ),
      Achievement(
        id: 'trillionaire',
        name: 'Trillion-Dollar Titan',
        description: 'Reach 1,000,000,000,000 dollars in total earnings',
        icon: Icons.auto_awesome,
        category: AchievementCategory.wealth,
        rarity: AchievementRarity.milestone,
      ),
      Achievement(
        id: 'income_trifecta',
        name: 'Income Trifecta',
        description: 'Generate 10,000,000 dollars income per second from each: Businesses, Real Estate, and Investments',
        icon: Icons.monetization_on_outlined,
        category: AchievementCategory.wealth,
        rarity: AchievementRarity.milestone,
      ),

      Achievement(
        id: 'million_dollar_fixer',
        name: 'Million-Dollar Fixer',
        description: 'Spend 1,000,000 dollars on event resolutions to prove your financial might',
        icon: Icons.diamond,
        category: AchievementCategory.wealth,
        rarity: AchievementRarity.milestone,
      ),
      Achievement(
        id: 'tycoon_titan',
        name: 'Tycoon Titan',
        description: 'Spend 50,000,000 dollars resolving events to dominate crisis management',
        icon: Icons.auto_awesome,
        category: AchievementCategory.wealth,
        rarity: AchievementRarity.milestone,
      ),
      Achievement(
        id: 'million_dollar_maverick',
        name: 'Million-Dollar Maverick',
        description: 'Pay a single fee of 1,000,000 dollars to resolve an event in one bold move',
        icon: Icons.monetization_on_outlined,
        category: AchievementCategory.wealth,
        rarity: AchievementRarity.milestone,
      ),

      Achievement(
        id: 'all_local_properties',
        name: 'Local Monopoly',
        description: 'Own all properties in your starting region',
        icon: Icons.location_on,
        category: AchievementCategory.regional,
        rarity: AchievementRarity.basic,
      ),

      Achievement(
        id: 'global_crisis_handler',
        name: 'Global Crisis Handler',
        description: 'Resolve at least one event in 10 different real estate locales',
        icon: Icons.public,
        category: AchievementCategory.regional,
        rarity: AchievementRarity.basic,
      ),

      Achievement(
        id: 'global_investor',
        name: 'Global Investor',
        description: 'Own properties in at least 3 different regions',
        icon: Icons.public,
        category: AchievementCategory.regional,
        rarity: AchievementRarity.rare,
      ),

      Achievement(
        id: 'disaster_master',
        name: 'Disaster Master',
        description: 'Resolve 3 natural disaster events in a single locale',
        icon: Icons.warning_amber,
        category: AchievementCategory.regional,
        rarity: AchievementRarity.rare,
      ),
      Achievement(
        id: 'real_estate_expert',
        name: 'Real Estate Expert',
        description: 'Resolve 25 real estate events to secure your property empire',
        icon: Icons.apartment,
        category: AchievementCategory.regional,
        rarity: AchievementRarity.rare,
      ),

      Achievement(
        id: 'world_domination',
        name: 'World Domination',
        description: 'Own at least one property in every region',
        icon: Icons.terrain,
        category: AchievementCategory.regional,
        rarity: AchievementRarity.milestone,
      ),
      Achievement(
        id: 'own_all_properties',
        name: 'Global Real Estate Monopoly',
        description: 'Own every single property across all regions',
        icon: Icons.real_estate_agent,
        category: AchievementCategory.regional,
        rarity: AchievementRarity.milestone,
      ),

      Achievement(
        id: 'first_fixer',
        name: 'First Fixer',
        description: 'Fully upgrade your first building to kickstart your real estate empire.',
        icon: Icons.handyman,
        category: AchievementCategory.progress,
        rarity: AchievementRarity.basic,
      ),
      Achievement(
        id: 'upgrade_enthusiast',
        name: 'Upgrade Enthusiast',
        description: 'Apply 50 upgrades across your properties to show your commitment.',
        icon: Icons.home_repair_service,
        category: AchievementCategory.progress,
        rarity: AchievementRarity.basic,
      ),
      Achievement(
        id: 'renovation_master',
        name: 'Renovation Master',
        description: 'Fully upgrade 25 properties to transform your portfolio.',
        icon: Icons.build_circle,
        category: AchievementCategory.progress,
        rarity: AchievementRarity.rare,
      ),
      Achievement(
        id: 'property_perfectionist',
        name: 'Property Perfectionist',
        description: 'Apply 500 upgrades to become a true upgrade aficionado.',
        icon: Icons.architecture,
        category: AchievementCategory.progress,
        rarity: AchievementRarity.rare,
      ),
      Achievement(
        id: 'upgrade_titan',
        name: 'Upgrade Titan',
        description: 'Fully upgrade all 200 properties to achieve real estate supremacy.',
        icon: Icons.domain,
        category: AchievementCategory.progress,
        rarity: AchievementRarity.milestone,
      ),

      Achievement(
        id: 'renovation_spender',
        name: 'Renovation Spender',
        description: "Spend 100,000 dollars upgrading properties to boost your empire's value.",
        icon: Icons.payments,
        category: AchievementCategory.wealth,
        rarity: AchievementRarity.basic,
      ),
      Achievement(
        id: 'million_dollar_upgrader',
        name: 'Million-Dollar Upgrader',
        description: 'Spend 1,000,000 dollars on upgrades to prove your financial prowess.',
        icon: Icons.account_balance,
        category: AchievementCategory.wealth,
        rarity: AchievementRarity.basic,
      ),
      Achievement(
        id: 'big_renovator',
        name: 'Big Renovator',
        description: 'Spend 4,000,000 dollars upgrading properties to reshape your empire.',
        icon: Icons.storefront,
        category: AchievementCategory.wealth,
        rarity: AchievementRarity.rare,
      ),
      Achievement(
        id: 'luxury_investor',
        name: 'Luxury Investor',
        description: 'Spend 10,000,000 dollars on upgrades for premium properties.',
        icon: Icons.villa,
        category: AchievementCategory.wealth,
        rarity: AchievementRarity.rare,
      ),
      Achievement(
        id: 'billion_dollar_builder',
        name: 'Billion-Dollar Builder',
        description: 'Spend 1,000,000,000 dollars upgrading properties to dominate the real estate market.',
        icon: Icons.diamond,
        category: AchievementCategory.wealth,
        rarity: AchievementRarity.milestone,
      ),

      Achievement(
        id: 'locale_landscaper',
        name: 'Locale Landscaper',
        description: 'Fully upgrade all properties in a single locale to master a region.',
        icon: Icons.landscape,
        category: AchievementCategory.regional,
        rarity: AchievementRarity.basic,
      ),
      Achievement(
        id: 'tropical_transformer',
        name: 'Tropical Transformer',
        description: 'Fully upgrade 15 properties across tropical locales: Rural Thailand, Ho Chi Minh City, and Miami.',
        icon: Icons.beach_access,
        category: AchievementCategory.regional,
        rarity: AchievementRarity.rare,
      ),
      Achievement(
        id: 'urban_upgrader',
        name: 'Urban Upgrader',
        description: 'Fully upgrade 30 properties in major cities.',
        icon: Icons.location_city,
        category: AchievementCategory.regional,
        rarity: AchievementRarity.rare,
      ),
      Achievement(
        id: 'rural_renovator',
        name: 'Rural Renovator',
        description: 'Fully upgrade 15 properties in rural areas: Rural Kenya, Rural Thailand, and Rural Mexico.',
        icon: Icons.agriculture,
        category: AchievementCategory.regional,
        rarity: AchievementRarity.basic,
      ),
      Achievement(
        id: 'global_renovator',
        name: 'Global Renovator',
        description: 'Fully upgrade at least one property in every locale to conquer the world.',
        icon: Icons.public,
        category: AchievementCategory.regional,
        rarity: AchievementRarity.milestone,
      ),

    ];
  }

  List<Achievement> getCompletedAchievements() {
    return achievements.where((achievement) => achievement.completed).toList();
  }

  List<Achievement> getAchievementsByCategory(AchievementCategory category) {
    return achievements.where((achievement) => achievement.category == category).toList();
  }

  void completeAchievement(String id) {
    int index = achievements.indexWhere((a) => a.id == id);
    if (index != -1 && !achievements[index].completed) {
      achievements[index].completed = true;
      achievements[index] = Achievement(
        id: achievements[index].id,
        name: achievements[index].name,
        description: achievements[index].description,
        icon: achievements[index].icon,
        category: achievements[index].category,
        rarity: achievements[index].rarity,
        completed: true,
        completedTimestamp: DateTime.now(),
      );
    }
  }

  /// Check all achievements against current game state
  List<Achievement> evaluateAchievements(GameState gameState) {
    List<Achievement> newlyCompleted = [];

    _checkBusinessAchievements(gameState, newlyCompleted);
    _checkInvestmentAchievements(gameState, newlyCompleted);
    _checkRealEstateAchievements(gameState, newlyCompleted);
    _checkTapAchievements(gameState, newlyCompleted);
    _checkReincorporationAchievements(gameState, newlyCompleted);
    _checkWealthAchievements(gameState, newlyCompleted);
    _checkRegionalAchievements(gameState, newlyCompleted);
    _checkEventAchievements(gameState, newlyCompleted);
    _checkRealEstateUpgradeAchievements(gameState, newlyCompleted);

    return newlyCompleted;
  }

  void _checkEventAchievements(GameState gameState, List<Achievement> newlyCompleted) {
    // Basic Rarity - Crisis Manager (10 events)
    if (!_isCompleted('crisis_manager') && gameState.totalEventsResolved >= 10) {
      completeAchievement('crisis_manager');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'crisis_manager'));
    }

    int eventTaps = gameState.eventsResolvedByTapping * 200; // Assuming each event requires 200 taps
    if (!_isCompleted('tap_titan') && eventTaps >= 1000) {
      completeAchievement('tap_titan');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'tap_titan'));
    }

    if (!_isCompleted('ad_enthusiast') && gameState.eventsResolvedByAd >= 25) {
      completeAchievement('ad_enthusiast');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'ad_enthusiast'));
    }

    if (!_isCompleted('crisis_investor') && gameState.eventFeesSpent >= 50000.0) {
      completeAchievement('crisis_investor');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'crisis_investor'));
    }

    int localesWithEvents = 0;
    for (var locale in gameState.realEstateLocales) {
      if (gameState.eventsResolvedByLocale.containsKey(locale.id) &&
          gameState.eventsResolvedByLocale[locale.id]! > 0) {
        localesWithEvents++;
      }
    }
    if (!_isCompleted('global_crisis_handler') && localesWithEvents >= 10) {
      completeAchievement('global_crisis_handler');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'global_crisis_handler'));
    }

    if (!_isCompleted('event_veteran') && gameState.totalEventsResolved >= 50) {
      completeAchievement('event_veteran');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'event_veteran'));
    }

    int quicklyResolvedEvents = 0;
    for (final event in gameState.resolvedEvents) {
      if (event.completedTimestamp != null && event.timestamp != null) {
        final resolutionTime = event.completedTimestamp!.difference(event.timestamp!);
        if (resolutionTime.inMinutes <= 5) {
          quicklyResolvedEvents++;
        }
      }
    }
    if (!_isCompleted('quick_fixer') && quicklyResolvedEvents >= 5) {
      completeAchievement('quick_fixer');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'quick_fixer'));
    }

    Map<String, int> disastersByLocale = {};
    for (final event in gameState.resolvedEvents) {
      if (event.type.isNaturalDisaster && event.affectedLocaleIds.isNotEmpty) {
        String localeId = event.affectedLocaleIds.first;
        disastersByLocale[localeId] = (disastersByLocale[localeId] ?? 0) + 1;
      }
    }
    bool hasLocaleWith3Disasters = disastersByLocale.values.any((count) => count >= 3);
    if (!_isCompleted('disaster_master') && hasLocaleWith3Disasters) {
      completeAchievement('disaster_master');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'disaster_master'));
    }

    int businessEventsResolved = 0;
    for (final event in gameState.resolvedEvents) {
      if (event.affectedBusinessIds.isNotEmpty) {
        businessEventsResolved++;
      }
    }
    if (!_isCompleted('business_specialist') && businessEventsResolved >= 25) {
      completeAchievement('business_specialist');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'business_specialist'));
    }

    int realEstateEventsResolved = 0;
    for (final event in gameState.resolvedEvents) {
      if (event.affectedLocaleIds.isNotEmpty) {
        realEstateEventsResolved++;
      }
    }
    if (!_isCompleted('real_estate_expert') && realEstateEventsResolved >= 25) {
      completeAchievement('real_estate_expert');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'real_estate_expert'));
    }

    if (!_isCompleted('million_dollar_fixer') && gameState.eventFeesSpent >= 1000000.0) {
      completeAchievement('million_dollar_fixer');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'million_dollar_fixer'));
    }

    if (!_isCompleted('tycoon_titan') && gameState.eventFeesSpent >= 50000000.0) {
      completeAchievement('tycoon_titan');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'tycoon_titan'));
    }

    double largestFeePaid = 0.0;
    for (final event in gameState.resolvedEvents) {
      if (event.resolutionFee != null && event.resolutionFee! > largestFeePaid) {
        largestFeePaid = event.resolutionFee!;
      }
    }
    if (!_isCompleted('million_dollar_maverick') && largestFeePaid >= 1000000.0) {
      completeAchievement('million_dollar_maverick');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'million_dollar_maverick'));
    }
  }

  void _checkReincorporationAchievements(GameState gameState, List<Achievement> newlyCompleted) {
    if (!_isCompleted('first_reincorporation') && gameState.totalReincorporations >= 1) {
      completeAchievement('first_reincorporation');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'first_reincorporation'));
    }

    if (!_isCompleted('max_reincorporations') && gameState.getAchievedReincorporationLevels() >= 9) {
      completeAchievement('max_reincorporations');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'max_reincorporations'));
    }
  }

  /// Calculate achievement progress for UI display (0.0 to 1.0)
  double calculateProgress(String achievementId, GameState gameState) {
    switch (achievementId) {
      case 'first_business':
        bool anyBusiness = gameState.businesses.any((b) => b.level > 0);
        return anyBusiness ? 1.0 : 0.0;

      case 'five_businesses':
        int count = gameState.businesses.where((b) => b.level > 0).length;
        return count / 5.0 > 1.0 ? 1.0 : count / 5.0;

      case 'all_businesses':
        int count = gameState.businesses.where((b) => b.level > 0).length;
        return count / gameState.businesses.length;

      case 'max_level_business':
        bool anyMaxLevel = gameState.businesses.any((b) => b.isMaxLevel());
        return anyMaxLevel ? 1.0 : 0.0;

      case 'all_max_level':
        int maxLevelCount = gameState.businesses.where((b) => b.isMaxLevel()).length;
        return maxLevelCount / gameState.businesses.length;

      case 'first_investment':
        bool anyInvestment = gameState.investments.any((i) => i.owned > 0);
        return anyInvestment ? 1.0 : 0.0;

      case 'big_investment':
        double investmentValue = gameState.investments.fold(
          0.0, (sum, i) => sum + (i.currentPrice * i.owned));
        return investmentValue / 100000.0 > 1.0 ? 1.0 : investmentValue / 100000.0;

      case 'first_real_estate':
        bool anyProperty = gameState.realEstateLocales.any(
          (locale) => locale.properties.any((p) => p.owned > 0));
        return anyProperty ? 1.0 : 0.0;

      case 'tap_master':
        return gameState.taps / 1000.0 > 1.0 ? 1.0 : gameState.taps / 1000.0;

      case 'tap_champion':
        return gameState.taps / 10000.0 > 1.0 ? 1.0 : gameState.taps / 10000.0;

      case 'first_thousand':
        return gameState.totalEarned / 1000.0 > 1.0 ? 1.0 : gameState.totalEarned / 1000.0;

      case 'first_million':
        return gameState.totalEarned / 1000000.0 > 1.0 ? 1.0 : gameState.totalEarned / 1000000.0;

      case 'first_billion':
        return gameState.totalEarned / 1000000000.0 > 1.0 ? 1.0 : gameState.totalEarned / 1000000000.0;

      case 'passive_income_master':
        double passiveIncome = gameState.calculateTotalIncomePerSecond();
        return passiveIncome / 10000.0 > 1.0 ? 1.0 : passiveIncome / 10000.0;

      case 'investment_genius':
        return gameState.investmentEarnings / 500000.0 > 1.0 ? 1.0 : gameState.investmentEarnings / 500000.0;

      case 'real_estate_tycoon':
        int propertyCount = gameState.realEstateLocales.fold(
          0, (sum, locale) => sum + locale.properties.fold(
            0, (s, p) => s + p.owned));
        return propertyCount / 20.0 > 1.0 ? 1.0 : propertyCount / 20.0;

      case 'all_local_properties':
        if (gameState.realEstateLocales.isEmpty) return 0.0;
        var locale = gameState.realEstateLocales[0];
        int ownedCount = locale.properties.where((p) => p.owned > 0).length;
        return ownedCount / locale.properties.length;

      case 'global_investor':
        int localesWithProperties = gameState.realEstateLocales.where(
          (l) => l.properties.any((p) => p.owned > 0)).length;
        return localesWithProperties / 3.0 > 1.0 ? 1.0 : localesWithProperties / 3.0;

      case 'world_domination':
        int localesWithProperties = gameState.realEstateLocales.where(
          (l) => l.properties.any((p) => p.owned > 0)).length;
        return localesWithProperties / gameState.realEstateLocales.length;

      case 'trillionaire':
        return gameState.totalEarned / 1000000000000.0 > 1.0 ? 1.0 : gameState.totalEarned / 1000000000000.0;

      case 'own_all_properties':
        int totalProperties = 0;
        int totalOwnedProperties = 0;

        for (var locale in gameState.realEstateLocales) {
          totalProperties += locale.properties.length;
          totalOwnedProperties += locale.properties.where((p) => p.owned > 0).length;
        }

        return totalProperties > 0 ? totalOwnedProperties / totalProperties : 0.0;

      case 'first_reincorporation':
        return gameState.totalReincorporations >= 1 ? 1.0 : 0.0;

      case 'max_reincorporations':
        return gameState.getAchievedReincorporationLevels() / 9.0 > 1.0 ? 1.0 : gameState.getAchievedReincorporationLevels() / 9.0;

      case 'income_trifecta':
        Map<String, double> incomeBreakdown = gameState.getCombinedIncomeBreakdown();
        double threshold = 10000000.0;

        double businessProgress = incomeBreakdown['business']! / threshold > 1.0 ? 1.0 : incomeBreakdown['business']! / threshold;
        double realEstateProgress = incomeBreakdown['realEstate']! / threshold > 1.0 ? 1.0 : incomeBreakdown['realEstate']! / threshold;
        double investmentProgress = incomeBreakdown['investment']! / threshold > 1.0 ? 1.0 : incomeBreakdown['investment']! / threshold;

        return (businessProgress + realEstateProgress + investmentProgress) / 3.0;

      case 'crisis_manager':
        return gameState.totalEventsResolved / 10.0 > 1.0 ? 1.0 : gameState.totalEventsResolved / 10.0;

      case 'tap_titan':
        int eventTaps = gameState.eventsResolvedByTapping * 200;
        return eventTaps / 1000.0 > 1.0 ? 1.0 : eventTaps / 1000.0;

      case 'ad_enthusiast':
        return gameState.eventsResolvedByAd / 25.0 > 1.0 ? 1.0 : gameState.eventsResolvedByAd / 25.0;

      case 'crisis_investor':
        return gameState.eventFeesSpent / 50000.0 > 1.0 ? 1.0 : gameState.eventFeesSpent / 50000.0;

      case 'global_crisis_handler':
        int localesWithEvents = 0;
        for (var locale in gameState.realEstateLocales) {
          if (gameState.eventsResolvedByLocale.containsKey(locale.id) &&
              gameState.eventsResolvedByLocale[locale.id]! > 0) {
            localesWithEvents++;
          }
        }
        return localesWithEvents / 10.0 > 1.0 ? 1.0 : localesWithEvents / 10.0;

      case 'event_veteran':
        return gameState.totalEventsResolved / 50.0 > 1.0 ? 1.0 : gameState.totalEventsResolved / 50.0;

      case 'quick_fixer':
        int quicklyResolvedEvents = 0;
        for (final event in gameState.resolvedEvents) {
          if (event.completedTimestamp != null && event.timestamp != null) {
            final resolutionTime = event.completedTimestamp!.difference(event.timestamp!);
            if (resolutionTime.inMinutes <= 5) {
              quicklyResolvedEvents++;
            }
          }
        }
        return quicklyResolvedEvents / 5.0 > 1.0 ? 1.0 : quicklyResolvedEvents / 5.0;

      case 'disaster_master':
        Map<String, int> disastersByLocale = {};
        for (final event in gameState.resolvedEvents) {
          if (event.type.isNaturalDisaster && event.affectedLocaleIds.isNotEmpty) {
            String localeId = event.affectedLocaleIds.first;
            disastersByLocale[localeId] = (disastersByLocale[localeId] ?? 0) + 1;
          }
        }
        int maxDisastersInSingleLocale = disastersByLocale.values.fold(0, (max, count) => count > max ? count : max);
        return maxDisastersInSingleLocale / 3.0 > 1.0 ? 1.0 : maxDisastersInSingleLocale / 3.0;

      case 'business_specialist':
        int businessEventsResolved = 0;
        for (final event in gameState.resolvedEvents) {
          if (event.affectedBusinessIds.isNotEmpty) {
            businessEventsResolved++;
          }
        }
        return businessEventsResolved / 25.0 > 1.0 ? 1.0 : businessEventsResolved / 25.0;

      case 'real_estate_expert':
        int realEstateEventsResolved = 0;
        for (final event in gameState.resolvedEvents) {
          if (event.affectedLocaleIds.isNotEmpty) {
            realEstateEventsResolved++;
          }
        }
        return realEstateEventsResolved / 25.0 > 1.0 ? 1.0 : realEstateEventsResolved / 25.0;

      case 'million_dollar_fixer':
        return gameState.eventFeesSpent / 1000000.0 > 1.0 ? 1.0 : gameState.eventFeesSpent / 1000000.0;

      case 'tycoon_titan':
        return gameState.eventFeesSpent / 50000000.0 > 1.0 ? 1.0 : gameState.eventFeesSpent / 50000000.0;

      case 'million_dollar_maverick':
        double largestFeePaid = 0.0;
        for (final event in gameState.resolvedEvents) {
          if (event.resolutionFee != null && event.resolutionFee! > largestFeePaid) {
            largestFeePaid = event.resolutionFee!;
          }
        }
        return largestFeePaid / 1000000.0 > 1.0 ? 1.0 : largestFeePaid / 1000000.0;

      case 'first_fixer':
        return gameState.fullyUpgradedPropertyIds.isNotEmpty ? 1.0 : 0.0;

      case 'upgrade_enthusiast':
        return gameState.totalRealEstateUpgradesPurchased / 50.0 > 1.0 ? 1.0 : gameState.totalRealEstateUpgradesPurchased / 50.0;

      case 'renovation_master':
        return gameState.fullyUpgradedPropertyIds.length / 25.0 > 1.0 ? 1.0 : gameState.fullyUpgradedPropertyIds.length / 25.0;

      case 'property_perfectionist':
        return gameState.totalRealEstateUpgradesPurchased / 500.0 > 1.0 ? 1.0 : gameState.totalRealEstateUpgradesPurchased / 500.0;

      case 'upgrade_titan':
        int totalProperties = gameState.realEstateLocales.fold(0, (sum, locale) => sum + locale.properties.length);
        if (totalProperties == 0) return 0.0;
        return gameState.fullyUpgradedPropertyIds.length / totalProperties > 1.0 ? 1.0 : gameState.fullyUpgradedPropertyIds.length / totalProperties;

      case 'renovation_spender':
        return gameState.totalUpgradeSpending / 100000.0 > 1.0 ? 1.0 : gameState.totalUpgradeSpending / 100000.0;

      case 'million_dollar_upgrader':
        return gameState.totalUpgradeSpending / 1000000.0 > 1.0 ? 1.0 : gameState.totalUpgradeSpending / 1000000.0;

      case 'big_renovator':
        return gameState.totalUpgradeSpending / 4000000.0 > 1.0 ? 1.0 : gameState.totalUpgradeSpending / 4000000.0;

      case 'luxury_investor':
        return gameState.luxuryUpgradeSpending / 10000000.0 > 1.0 ? 1.0 : gameState.luxuryUpgradeSpending / 10000000.0;

      case 'billion_dollar_builder':
        return gameState.totalUpgradeSpending / 1000000000.0 > 1.0 ? 1.0 : gameState.totalUpgradeSpending / 1000000000.0;

      case 'locale_landscaper':
        return gameState.fullyUpgradedLocales.isNotEmpty ? 1.0 : 0.0;

      case 'tropical_transformer':
        int count = _countFullyUpgradedInLocales(gameState, _tropicalLocaleIds);
        return count / 15.0 > 1.0 ? 1.0 : count / 15.0;

      case 'urban_upgrader':
        int count = _countFullyUpgradedInLocales(gameState, _urbanLocaleIds);
        return count / 30.0 > 1.0 ? 1.0 : count / 30.0;

      case 'rural_renovator':
        int count = _countFullyUpgradedInLocales(gameState, _ruralLocaleIds);
        return count / 15.0 > 1.0 ? 1.0 : count / 15.0;

      case 'global_renovator':
        int totalLocales = gameState.realEstateLocales.length;
        if (totalLocales == 0) return 0.0;
        return gameState.localesWithOneFullyUpgradedProperty.length / totalLocales > 1.0 ? 1.0 : gameState.localesWithOneFullyUpgradedProperty.length / totalLocales;

      default:
        return 0.0;
    }
  }

  void _checkBusinessAchievements(GameState gameState, List<Achievement> newlyCompleted) {
    if (!_isCompleted('first_business') && gameState.businesses.any((b) => b.level > 0)) {
      completeAchievement('first_business');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'first_business'));
    }

    if (!_isCompleted('five_businesses') &&
        gameState.businesses.where((b) => b.level > 0).length >= 5) {
      completeAchievement('five_businesses');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'five_businesses'));
    }

    if (!_isCompleted('all_businesses') &&
        gameState.businesses.every((b) => b.level > 0)) {
      completeAchievement('all_businesses');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'all_businesses'));
    }

    if (!_isCompleted('max_level_business') &&
        gameState.businesses.any((b) => b.isMaxLevel())) {
      completeAchievement('max_level_business');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'max_level_business'));
    }

    if (!_isCompleted('all_max_level') &&
        gameState.businesses.every((b) => b.isMaxLevel())) {
      completeAchievement('all_max_level');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'all_max_level'));
    }
  }

  void _checkInvestmentAchievements(GameState gameState, List<Achievement> newlyCompleted) {
    if (!_isCompleted('first_investment') &&
        gameState.investments.any((i) => i.owned > 0)) {
      completeAchievement('first_investment');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'first_investment'));
    }

    double investmentValue = gameState.investments.fold(
      0.0, (sum, i) => sum + (i.currentPrice * i.owned));

    if (!_isCompleted('big_investment') && investmentValue >= 100000.0) {
      completeAchievement('big_investment');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'big_investment'));
    }
  }

  void _checkRealEstateAchievements(GameState gameState, List<Achievement> newlyCompleted) {
    bool anyPropertyOwned = gameState.realEstateLocales.any(
      (locale) => locale.properties.any((p) => p.owned > 0));

    if (!_isCompleted('first_real_estate') && anyPropertyOwned) {
      completeAchievement('first_real_estate');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'first_real_estate'));
    }

    // ** FIX: Corrected ID from 'regional_investor' to 'global_investor' **
    // ** FIX: Corrected condition from >= 5 to >= 3 to match achievement description **
    int localesWithProperties = gameState.realEstateLocales.where((l) => l.hasOwnedProperties()).length;
    if (!_isCompleted('global_investor') && localesWithProperties >= 3) {
      completeAchievement('global_investor');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'global_investor'));
    }

    // ** FIX: Corrected logic to use 'real_estate_tycoon' (20 properties) **
    if (!_isCompleted('real_estate_tycoon') && gameState.getTotalOwnedProperties() >= 20) {
      completeAchievement('real_estate_tycoon');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'real_estate_tycoon'));
    }

    // ** FIX: Corrected logic to use 'world_domination' (own property in every locale) **
    int totalLocales = gameState.realEstateLocales.length;
    if (!_isCompleted('world_domination') && localesWithProperties >= totalLocales && totalLocales > 0) {
      completeAchievement('world_domination');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'world_domination'));
    }

    if (!_isCompleted('own_all_properties') && gameState.ownsAllProperties()) {
      completeAchievement('own_all_properties');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'own_all_properties'));
    }
  }

  void _checkTapAchievements(GameState gameState, List<Achievement> newlyCompleted) {
    if (!_isCompleted('tap_master') && gameState.taps >= 1000) {
      completeAchievement('tap_master');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'tap_master'));
    }

    if (!_isCompleted('tap_champion') && gameState.taps >= 10000) {
      completeAchievement('tap_champion');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'tap_champion'));
    }
  }

  void _checkWealthAchievements(GameState gameState, List<Achievement> newlyCompleted) {
    if (!_isCompleted('first_thousand') && gameState.totalEarned >= 1000.0) {
      completeAchievement('first_thousand');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'first_thousand'));
    }

    if (!_isCompleted('first_million') && gameState.totalEarned >= 1000000.0) {
      completeAchievement('first_million');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'first_million'));
    }

    if (!_isCompleted('first_billion') && gameState.totalEarned >= 1000000000.0) {
      completeAchievement('first_billion');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'first_billion'));
    }

    if (!_isCompleted('trillionaire') && gameState.totalEarned >= 1000000000000.0) {
      completeAchievement('trillionaire');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'trillionaire'));
    }

    double passiveIncome = gameState.calculateTotalIncomePerSecond();
    if (!_isCompleted('passive_income_master') && passiveIncome >= 10000.0) {
      completeAchievement('passive_income_master');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'passive_income_master'));
    }

    if (!_isCompleted('investment_genius') && gameState.investmentEarnings >= 500000.0) {
      completeAchievement('investment_genius');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'investment_genius'));
    }

    int propertyCount = gameState.realEstateLocales.fold(
      0, (sum, locale) => sum + locale.properties.fold(
        0, (s, p) => s + p.owned));

    if (!_isCompleted('real_estate_tycoon') && propertyCount >= 20) {
      completeAchievement('real_estate_tycoon');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'real_estate_tycoon'));
    }

    if (!_isCompleted('income_trifecta') &&
        gameState.hasCombinedIncomeOfAmount(10000000.0)) {
      completeAchievement('income_trifecta');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'income_trifecta'));
    }
  }

  void _checkRegionalAchievements(GameState gameState, List<Achievement> newlyCompleted) {
    if (!gameState.realEstateLocales.isEmpty) {
      var locale = gameState.realEstateLocales[0];
      bool allOwned = locale.properties.every((p) => p.owned > 0);

      if (!_isCompleted('all_local_properties') && allOwned) {
        completeAchievement('all_local_properties');
        newlyCompleted.add(achievements.firstWhere((a) => a.id == 'all_local_properties'));
      }
    }

    int localesWithProperties = gameState.realEstateLocales.where(
      (l) => l.properties.any((p) => p.owned > 0)).length;

    if (!_isCompleted('global_investor') && localesWithProperties >= 3) {
      completeAchievement('global_investor');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'global_investor'));
    }

    if (!_isCompleted('world_domination') &&
        localesWithProperties == gameState.realEstateLocales.length &&
        gameState.realEstateLocales.isNotEmpty) {
      completeAchievement('world_domination');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'world_domination'));
    }

    if (!_isCompleted('own_all_properties') && gameState.ownsAllProperties()) {
      completeAchievement('own_all_properties');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'own_all_properties'));
    }
  }

  bool _isCompleted(String id) {
    final achievement = achievements.firstWhere((a) => a.id == id, orElse: () => Achievement(id: '', name: '', description: '', icon: Icons.error, category: AchievementCategory.progress));
    return achievement.completed;
  }

  void _checkRealEstateUpgradeAchievements(GameState gameState, List<Achievement> newlyCompleted) {
    // Progress Category
    if (!_isCompleted('first_fixer') && gameState.fullyUpgradedPropertyIds.isNotEmpty) {
      completeAchievement('first_fixer');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'first_fixer'));
    }

    if (!_isCompleted('upgrade_enthusiast') && gameState.totalRealEstateUpgradesPurchased >= 50) {
      completeAchievement('upgrade_enthusiast');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'upgrade_enthusiast'));
    }

    if (!_isCompleted('renovation_master') && gameState.fullyUpgradedPropertyIds.length >= 25) {
      completeAchievement('renovation_master');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'renovation_master'));
    }

    if (!_isCompleted('property_perfectionist') && gameState.totalRealEstateUpgradesPurchased >= 500) {
      completeAchievement('property_perfectionist');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'property_perfectionist'));
    }

    int totalProperties = gameState.realEstateLocales.fold(0, (sum, locale) => sum + locale.properties.length);
    if (!_isCompleted('upgrade_titan') && gameState.fullyUpgradedPropertyIds.length >= totalProperties && totalProperties > 0) {
      completeAchievement('upgrade_titan');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'upgrade_titan'));
    }

    // Wealth Category
    if (!_isCompleted('renovation_spender') && gameState.totalUpgradeSpending >= 100000.0) {
      completeAchievement('renovation_spender');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'renovation_spender'));
    }

    if (!_isCompleted('million_dollar_upgrader') && gameState.totalUpgradeSpending >= 1000000.0) {
      completeAchievement('million_dollar_upgrader');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'million_dollar_upgrader'));
    }

    if (!_isCompleted('big_renovator') && gameState.totalUpgradeSpending >= 4000000.0) {
      completeAchievement('big_renovator');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'big_renovator'));
    }

    if (!_isCompleted('luxury_investor') && gameState.luxuryUpgradeSpending >= 10000000.0) {
      completeAchievement('luxury_investor');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'luxury_investor'));
    }

    if (!_isCompleted('billion_dollar_builder') && gameState.totalUpgradeSpending >= 1000000000.0) {
      completeAchievement('billion_dollar_builder');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'billion_dollar_builder'));
    }

    // Regional Category
    if (!_isCompleted('locale_landscaper') && gameState.fullyUpgradedLocales.isNotEmpty) {
      completeAchievement('locale_landscaper');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'locale_landscaper'));
    }

    if (!_isCompleted('tropical_transformer') && _countFullyUpgradedInLocales(gameState, _tropicalLocaleIds) >= 15) {
      completeAchievement('tropical_transformer');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'tropical_transformer'));
    }

    if (!_isCompleted('urban_upgrader') && _countFullyUpgradedInLocales(gameState, _urbanLocaleIds) >= 30) {
      completeAchievement('urban_upgrader');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'urban_upgrader'));
    }

    if (!_isCompleted('rural_renovator') && _countFullyUpgradedInLocales(gameState, _ruralLocaleIds) >= 15) {
      completeAchievement('rural_renovator');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'rural_renovator'));
    }

    int totalLocales = gameState.realEstateLocales.length;
    if (!_isCompleted('global_renovator') && gameState.localesWithOneFullyUpgradedProperty.length >= totalLocales && totalLocales > 0) {
      completeAchievement('global_renovator');
      newlyCompleted.add(achievements.firstWhere((a) => a.id == 'global_renovator'));
    }
  }

  int _countFullyUpgradedInLocales(GameState gameState, Set<String> localeIds) {
    int count = 0;
    for (String localeId in localeIds) {
      count += gameState.fullyUpgradedPropertiesPerLocale[localeId] ?? 0;
    }
    return count;
  }
}
