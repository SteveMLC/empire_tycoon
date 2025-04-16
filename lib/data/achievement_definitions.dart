import 'package:flutter/material.dart';
import '../models/achievement_data.dart';

List<Achievement> getAchievementDefinitions() {
  return [
      // --- Progress Achievements ---
      // Basic
      Achievement(
        id: 'first_business', name: 'Entrepreneur', description: 'Buy your first business',
        icon: Icons.store, category: AchievementCategory.progress, rarity: AchievementRarity.basic, ppReward: 5,
      ),
      Achievement(
        id: 'five_businesses', name: 'Business Mogul', description: 'Own 5 different types of businesses',
        icon: Icons.corporate_fare, category: AchievementCategory.progress, rarity: AchievementRarity.basic, ppReward: 10,
      ),
      Achievement(
        id: 'first_investment', name: 'Investor', description: 'Make your first investment',
        icon: Icons.trending_up, category: AchievementCategory.progress, rarity: AchievementRarity.basic, ppReward: 5,
      ),
      Achievement(
        id: 'first_real_estate', name: 'Property Owner', description: 'Purchase your first real estate property',
        icon: Icons.home, category: AchievementCategory.progress, rarity: AchievementRarity.basic, ppReward: 5,
      ),
      Achievement(
        id: 'tap_master', name: 'Tap Master', description: 'Tap 1,000 times',
        icon: Icons.touch_app, category: AchievementCategory.progress, rarity: AchievementRarity.basic, ppReward: 10,
      ),
      Achievement(
        id: 'crisis_manager', name: 'Crisis Manager', description: 'Resolve 10 events across your empire to prove your management skills',
        icon: Icons.task_alt, category: AchievementCategory.progress, rarity: AchievementRarity.basic, ppReward: 10,
      ),
      Achievement(
        id: 'tap_titan', name: 'Tap Titan', description: 'Tap your way through 1,000 clicks to solve crises manually',
        icon: Icons.touch_app, category: AchievementCategory.progress, rarity: AchievementRarity.basic, ppReward: 10,
      ),
      Achievement(
        id: 'ad_enthusiast', name: 'Ad Enthusiast', description: 'Watch 25 ads to resolve events quickly and keep your empire running',
        icon: Icons.ondemand_video, category: AchievementCategory.progress, rarity: AchievementRarity.basic, ppReward: 10,
      ),
      Achievement(
        id: 'first_fixer', name: 'First Fixer', description: 'Fully upgrade your first building to kickstart your real estate empire.',
        icon: Icons.handyman, category: AchievementCategory.progress, rarity: AchievementRarity.basic, ppReward: 8,
      ),
      Achievement(
        id: 'upgrade_enthusiast', name: 'Upgrade Enthusiast', description: 'Apply 50 upgrades across your properties to show your commitment.',
        icon: Icons.home_repair_service, category: AchievementCategory.progress, rarity: AchievementRarity.basic, ppReward: 12,
      ),
      // Rare
      Achievement(
        id: 'all_businesses', name: 'Empire Builder', description: 'Own at least one of each type of business',
        icon: Icons.location_city, category: AchievementCategory.progress, rarity: AchievementRarity.rare, ppReward: 30,
      ),
      Achievement(
        id: 'max_level_business', name: 'Expansion Expert', description: 'Upgrade any business to maximum level',
        icon: Icons.arrow_upward, category: AchievementCategory.progress, rarity: AchievementRarity.rare, ppReward: 40,
      ),
      Achievement(
        id: 'big_investment', name: 'Stock Market Savvy', description: 'Own investments worth 100,000 dollars or more',
        icon: Icons.attach_money, category: AchievementCategory.progress, rarity: AchievementRarity.rare, ppReward: 30,
      ),
      Achievement(
        id: 'tap_champion', name: 'Tap Champion', description: 'Tap 10,000 times',
        icon: Icons.back_hand, category: AchievementCategory.progress, rarity: AchievementRarity.rare, ppReward: 35,
      ),
      Achievement(
        id: 'first_reincorporation', name: 'Corporate Phoenix', description: 'Complete your first re-incorporation',
        icon: Icons.cyclone, category: AchievementCategory.progress, rarity: AchievementRarity.rare, ppReward: 40,
      ),
      Achievement(
        id: 'event_veteran', name: 'Event Veteran', description: 'Resolve 50 events to become a seasoned crisis handler',
        icon: Icons.gpp_good, category: AchievementCategory.progress, rarity: AchievementRarity.rare, ppReward: 35,
      ),
      Achievement(
        id: 'quick_fixer', name: 'Quick Fixer', description: 'Resolve 5 events within 5 minutes of their occurrence',
        icon: Icons.timer, category: AchievementCategory.progress, rarity: AchievementRarity.rare, ppReward: 25,
      ),
      Achievement(
        id: 'business_specialist', name: 'Business Specialist', description: 'Resolve 25 business events to master corporate crisis management',
        icon: Icons.business, category: AchievementCategory.progress, rarity: AchievementRarity.rare, ppReward: 30,
      ),
      Achievement(
        id: 'renovation_master', name: 'Renovation Master', description: 'Fully upgrade 25 properties to transform your portfolio.',
        icon: Icons.build_circle, category: AchievementCategory.progress, rarity: AchievementRarity.rare, ppReward: 40,
      ),
      Achievement(
        id: 'property_perfectionist', name: 'Property Perfectionist', description: 'Apply 500 upgrades to become a true upgrade aficionado.',
        icon: Icons.architecture, category: AchievementCategory.progress, rarity: AchievementRarity.rare, ppReward: 45,
      ),
      // Milestone
      Achievement(
        id: 'all_max_level', name: 'Business Perfectionist', description: 'Upgrade all businesses to maximum level',
        icon: Icons.star, category: AchievementCategory.progress, rarity: AchievementRarity.milestone, ppReward: 150,
      ),
      Achievement(
        id: 'max_reincorporations', name: 'Corporate Dynasty', description: 'Complete all 9 re-incorporations (1M to 100T dollars)',
        icon: Icons.sync_alt, category: AchievementCategory.progress, rarity: AchievementRarity.milestone, ppReward: 200,
      ),
      Achievement(
        id: 'upgrade_titan', name: 'Upgrade Titan', description: 'Fully upgrade all 200 properties to achieve real estate supremacy.',
        icon: Icons.domain, category: AchievementCategory.progress, rarity: AchievementRarity.milestone, ppReward: 200,
      ),

      // --- Wealth Achievements ---
      // Basic
      Achievement(
        id: 'first_thousand', name: 'First Grand', description: 'Earn your first 1000 dollars',
        icon: Icons.monetization_on, category: AchievementCategory.wealth, rarity: AchievementRarity.basic, ppReward: 5,
      ),
      Achievement(
        id: 'crisis_investor', name: 'Crisis Investor', description: 'Spend 50,000 dollars resolving events to keep your empire afloat',
        icon: Icons.attach_money, category: AchievementCategory.wealth, rarity: AchievementRarity.basic, ppReward: 10,
      ),
      Achievement(
        id: 'renovation_spender', name: 'Renovation Spender', description: "Spend 100,000 dollars upgrading properties to boost your empire's value.",
        icon: Icons.payments, category: AchievementCategory.wealth, rarity: AchievementRarity.basic, ppReward: 10,
      ),
      Achievement(
        id: 'million_dollar_upgrader', name: 'Million-Dollar Upgrader', description: 'Spend 1,000,000 dollars on upgrades to prove your financial prowess.',
        icon: Icons.account_balance, category: AchievementCategory.wealth, rarity: AchievementRarity.basic, ppReward: 15,
      ),
      // Rare
      Achievement(
        id: 'first_million', name: 'Millionaire', description: 'Reach 1,000,000 dollars in total earnings',
        icon: Icons.emoji_events, category: AchievementCategory.wealth, rarity: AchievementRarity.rare, ppReward: 30,
      ),
      Achievement(
        id: 'passive_income_master', name: 'Passive Income Master', description: 'Earn 10,000 dollars per second in passive income',
        icon: Icons.update, category: AchievementCategory.wealth, rarity: AchievementRarity.rare, ppReward: 40,
      ),
      Achievement(
        id: 'investment_genius', name: 'Investment Genius', description: 'Make 500,000 dollars profit from investments',
        icon: Icons.insert_chart, category: AchievementCategory.wealth, rarity: AchievementRarity.rare, ppReward: 35,
      ),
      Achievement(
        id: 'real_estate_tycoon', name: 'Real Estate Tycoon', description: 'Own 20 real estate properties',
        icon: Icons.apartment, category: AchievementCategory.wealth, rarity: AchievementRarity.rare, ppReward: 30,
      ),
      Achievement(
        id: 'big_renovator', name: 'Big Renovator', description: 'Spend 4,000,000 dollars upgrading properties to reshape your empire.',
        icon: Icons.storefront, category: AchievementCategory.wealth, rarity: AchievementRarity.rare, ppReward: 40,
      ),
      Achievement(
        id: 'luxury_investor', name: 'Luxury Investor', description: 'Spend 10,000,000 dollars on upgrades for premium properties.',
        icon: Icons.villa, category: AchievementCategory.wealth, rarity: AchievementRarity.rare, ppReward: 45,
      ),
      // Milestone
      Achievement(
        id: 'first_billion', name: 'Billionaire', description: 'Reach 1,000,000,000 dollars in total earnings',
        icon: Icons.diamond, category: AchievementCategory.wealth, rarity: AchievementRarity.milestone, ppReward: 100,
      ),
      Achievement(
        id: 'trillionaire', name: 'Trillion-Dollar Titan', description: 'Reach 1,000,000,000,000 dollars in total earnings',
        icon: Icons.auto_awesome, category: AchievementCategory.wealth, rarity: AchievementRarity.milestone, ppReward: 150,
      ),
      Achievement(
        id: 'income_trifecta', name: 'Income Trifecta', description: 'Generate 10,000,000 dollars income per second from each: Businesses, Real Estate, and Investments',
        icon: Icons.monetization_on_outlined, category: AchievementCategory.wealth, rarity: AchievementRarity.milestone, ppReward: 175,
      ),
      Achievement(
        id: 'million_dollar_fixer', name: 'Million-Dollar Fixer', description: 'Spend 1,000,000 dollars on event resolutions to prove your financial might',
        icon: Icons.diamond, category: AchievementCategory.wealth, rarity: AchievementRarity.milestone, ppReward: 100,
      ),
      Achievement(
        id: 'tycoon_titan', name: 'Tycoon Titan', description: 'Spend 50,000,000 dollars resolving events to dominate crisis management',
        icon: Icons.auto_awesome, category: AchievementCategory.wealth, rarity: AchievementRarity.milestone, ppReward: 150,
      ),
      Achievement(
        id: 'million_dollar_maverick', name: 'Million-Dollar Maverick', description: 'Pay a single fee of 1,000,000 dollars to resolve an event in one bold move',
        icon: Icons.monetization_on_outlined, category: AchievementCategory.wealth, rarity: AchievementRarity.milestone, ppReward: 100,
      ),
      Achievement(
        id: 'billion_dollar_builder', name: 'Billion-Dollar Builder', description: 'Spend 1,000,000,000 dollars upgrading properties to dominate the real estate market.',
        icon: Icons.diamond, category: AchievementCategory.wealth, rarity: AchievementRarity.milestone, ppReward: 175,
      ),

      // --- Regional Achievements ---
      // Basic
      Achievement(
        id: 'all_local_properties', name: 'Local Monopoly', description: 'Own all properties in your starting region',
        icon: Icons.location_on, category: AchievementCategory.regional, rarity: AchievementRarity.basic, ppReward: 10,
      ),
      Achievement(
        id: 'global_crisis_handler', name: 'Global Crisis Handler', description: 'Resolve at least one event in 10 different real estate locales',
        icon: Icons.public, category: AchievementCategory.regional, rarity: AchievementRarity.basic, ppReward: 12,
      ),
      Achievement(
        id: 'locale_landscaper', name: 'Locale Landscaper', description: 'Fully upgrade all properties in a single locale to master a region.',
        icon: Icons.landscape, category: AchievementCategory.regional, rarity: AchievementRarity.basic, ppReward: 10,
      ),
      Achievement(
        id: 'rural_renovator', name: 'Rural Renovator', description: 'Fully upgrade 15 properties in rural areas: Rural Kenya, Rural Thailand, and Rural Mexico.',
        icon: Icons.agriculture, category: AchievementCategory.regional, rarity: AchievementRarity.basic, ppReward: 12,
      ),
      // Rare
      Achievement(
        id: 'global_investor', name: 'Global Investor', description: 'Own properties in at least 3 different regions',
        icon: Icons.public, category: AchievementCategory.regional, rarity: AchievementRarity.rare, ppReward: 25,
      ),
      Achievement(
        id: 'disaster_master', name: 'Disaster Master', description: 'Resolve 3 natural disaster events in a single locale',
        icon: Icons.warning_amber, category: AchievementCategory.regional, rarity: AchievementRarity.rare, ppReward: 30,
      ),
      Achievement(
        id: 'real_estate_expert', name: 'Real Estate Expert', description: 'Resolve 25 real estate events to secure your property empire',
        icon: Icons.apartment, category: AchievementCategory.regional, rarity: AchievementRarity.rare, ppReward: 35,
      ),
      Achievement(
        id: 'tropical_transformer', name: 'Tropical Transformer', description: 'Fully upgrade 15 properties across tropical locales: Rural Thailand, Ho Chi Minh City, and Miami.',
        icon: Icons.beach_access, category: AchievementCategory.regional, rarity: AchievementRarity.rare, ppReward: 40,
      ),
      Achievement(
        id: 'urban_upgrader', name: 'Urban Upgrader', description: 'Fully upgrade 30 properties in major cities.',
        icon: Icons.location_city, category: AchievementCategory.regional, rarity: AchievementRarity.rare, ppReward: 45,
      ),
      // Milestone
      Achievement(
        id: 'world_domination', name: 'World Domination', description: 'Own at least one property in every region',
        icon: Icons.terrain, category: AchievementCategory.regional, rarity: AchievementRarity.milestone, ppReward: 125,
      ),
      Achievement(
        id: 'own_all_properties', name: 'Global Real Estate Monopoly', description: 'Own every single property across all regions',
        icon: Icons.real_estate_agent, category: AchievementCategory.regional, rarity: AchievementRarity.milestone, ppReward: 200,
      ),
      Achievement(
        id: 'global_renovator', name: 'Global Renovator', description: 'Fully upgrade at least one property in every locale to conquer the world.',
        icon: Icons.public, category: AchievementCategory.regional, rarity: AchievementRarity.milestone, ppReward: 150,
      ),
    ];
} 