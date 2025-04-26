import 'package:flutter/material.dart'; // Import for IconData and Icons

enum VaultItemCategory {
  upgrades,
  unlockables,
  eventsAndChallenges,
  cosmetics,
  boosters
}

enum VaultItemType {
  oneTime,
  repeatable
}

class VaultItem {
  final String id;
  final String name;
  final String description;
  final VaultItemCategory category;
  final VaultItemType type;
  final int cost; // Cost in Platinum
  final String iconAsset; // Path to an icon asset (e.g., 'assets/icons/placeholder_item.png')
  final IconData? iconData; // Alternative: Use Material Icon

  VaultItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.type,
    required this.cost,
    this.iconAsset = 'assets/icons/item_placeholder.png',
    this.iconData,
  });
}

// Placeholder list - This will be replaced with actual item data later.
// For now, it provides the structure for the Vault UI to potentially use.
List<VaultItem> getVaultItems() {
  return [
    // --- Upgrades --- (One-Time)
    VaultItem(
      id: 'platinum_efficiency',
      name: 'Platinum Efficiency',
      description: 'Permanently boosts all business upgrade effectiveness by 5%.',
      category: VaultItemCategory.upgrades,
      type: VaultItemType.oneTime,
      cost: 150,
      iconData: Icons.settings_input_component,
    ),
    VaultItem(
      id: 'platinum_portfolio',
      name: 'Platinum Portfolio',
      description: 'Permanently increases dividend income from investments by 25%.',
      category: VaultItemCategory.upgrades,
      type: VaultItemType.oneTime,
      cost: 120,
      iconData: Icons.assessment,
    ),
    VaultItem(
      id: 'platinum_foundation',
      name: 'Platinum Foundation',
      description: 'Increases real estate income in one chosen location by 5%. (Max 5)',
      category: VaultItemCategory.upgrades,
      type: VaultItemType.repeatable, // Repeatable up to 5 times
      cost: 100,
      iconData: Icons.foundation,
    ),
    VaultItem(
      id: 'platinum_resilience',
      name: 'Platinum Resilience',
      description: 'Reduces negative event impacts (costs, penalties) by 10%.',
      category: VaultItemCategory.upgrades,
      type: VaultItemType.oneTime,
      cost: 80,
      iconData: Icons.security,
    ),
    VaultItem(
      id: 'perm_income_boost_5pct',
      name: 'Permanent Income Boost',
      description: 'Permanently increases all passive income sources by 5%.',
      category: VaultItemCategory.upgrades,
      type: VaultItemType.oneTime,
      cost: 250,
      iconData: Icons.trending_up,
    ),
    VaultItem(
      id: 'perm_click_boost_10pct',
      name: 'Permanent Click Boost',
      description: 'Permanently increases manual tap value by 10%.',
      category: VaultItemCategory.upgrades,
      type: VaultItemType.oneTime,
      cost: 150,
      iconData: Icons.touch_app,
    ),

    // --- Unlockables --- (One-Time)
    VaultItem(
      id: 'platinum_tower',
      name: 'Platinum Tower',
      description: 'Unlock an exclusive skyscraper property in Dubai (+10% regional income).',
      category: VaultItemCategory.unlockables,
      type: VaultItemType.oneTime,
      cost: 200,
      iconData: Icons.location_city, // Skyscraper icon
    ),
    VaultItem(
      id: 'platinum_venture',
      name: 'Platinum Venture',
      description: 'Unlock a rare Private Space Agency business with high income potential.',
      category: VaultItemCategory.unlockables,
      type: VaultItemType.oneTime,
      cost: 250,
      iconData: Icons.rocket, // Rocket icon
    ),
    VaultItem(
      id: 'platinum_stock',
      name: 'Quantum Computing Inc.',
      description: 'Unlock a high-risk, high-reward stock investment (\$1B/share).',
      category: VaultItemCategory.unlockables,
      type: VaultItemType.oneTime,
      cost: 150,
      iconData: Icons.memory, // Chip/memory icon
    ),
    // VaultItem(
    //   id: 'unlock_golden_cursor',
    //   name: 'Golden Cursor',
    //   description: 'Unlock a flashy golden cursor effect for tapping!',
    //   category: VaultItemCategory.unlockables,
    //   type: VaultItemType.oneTime,
    //   cost: 75,
    //   iconData: Icons.mouse,
    // ),
    VaultItem(
      id: 'unlock_stats_theme_1',
      name: 'Executive Stats Theme',
      description: 'Unlock a sleek executive theme for the Stats screen with premium dark styling and gold accents.',
      category: VaultItemCategory.unlockables,
      type: VaultItemType.oneTime,
      cost: 100,
      iconData: Icons.style,
    ),

    // --- Boosters --- (Repeatable)
    VaultItem(
      id: 'temp_boost_10x_5min',
      name: 'Click Frenzy (5 min)',
      description: 'Boost manual tap value by 10x for 5 minutes.',
      category: VaultItemCategory.boosters,
      type: VaultItemType.repeatable,
      cost: 50, // Example cost
      iconData: Icons.bolt,
    ),
    VaultItem(
      id: 'temp_boost_2x_10min',
      name: 'Steady Boost (10 min)',
      description: 'Boost manual tap value by 2x for 10 minutes.',
      category: VaultItemCategory.boosters,
      type: VaultItemType.repeatable,
      cost: 30, // Cheaper, longer, less potent boost
      iconData: Icons.speed,
    ),

    // --- Events & Challenges --- (Example - could grant temporary event modifiers)
    VaultItem(
      id: 'event_skip_ticket',
      name: 'Event Skip Ticket',
      description: 'Instantly resolve one active non-disaster event. Consumed on use.',
      category: VaultItemCategory.eventsAndChallenges,
      type: VaultItemType.repeatable, // Consumable
      cost: 100,
      iconData: Icons.skip_next,
    ),
    // ADDED: Platinum Challenge Token
    VaultItem(
      id: 'platinum_challenge',
      name: 'Platinum Challenge',
      description: 'Challenge: Earn double your current hourly income within the next hour! Reward: 30 P.',
      category: VaultItemCategory.eventsAndChallenges,
      type: VaultItemType.repeatable, // TODO: Implement 2x per day limit later
      cost: 20,
      iconData: Icons.emoji_events,
    ),
    // ADDED: Platinum Disaster Shield
    VaultItem(
      id: 'platinum_shield',
      name: 'Disaster Shield',
      description: 'Prevents natural disaster events for 1 in-game day.',
      category: VaultItemCategory.eventsAndChallenges,
      type: VaultItemType.repeatable, // TODO: Implement 3x per week limit
      cost: 40,
      iconData: Icons.shield,
    ),
    // ADDED: Platinum Crisis Accelerator
    VaultItem(
      id: 'platinum_accelerator',
      name: 'Crisis Accelerator',
      description: 'Reduces event cost & resolution time by 50% for 24h.',
      category: VaultItemCategory.eventsAndChallenges,
      type: VaultItemType.repeatable, // TODO: Implement 2x per week limit
      cost: 50,
      iconData: Icons.rocket_launch, // Example icon
    ),

    // --- Cosmetics --- (One-Time - Functionality might overlap with Unlockables)
    VaultItem(
      id: 'cosmetic_platinum_frame',
      name: 'Platinum UI Frame',
      description: 'Apply a shiny platinum border to your main game UI.',
      category: VaultItemCategory.cosmetics,
      type: VaultItemType.oneTime,
      cost: 300,
      iconData: Icons.image_aspect_ratio,
    ),
    // ADDED: Platinum Mogul Avatar
    VaultItem(
      id: 'platinum_mogul',
      name: 'Platinum Mogul Look',
      description: 'Unlock the exclusive Executive Theme.',
      category: VaultItemCategory.cosmetics,
      type: VaultItemType.oneTime,
      cost: 50,
      iconData: Icons.person_outline, // Example icon
    ),
    // ADDED: Platinum Facade
    VaultItem(
      id: 'platinum_facade',
      name: 'Platinum Facade',
      description: 'Apply a metallic skin to one owned business.',
      category: VaultItemCategory.cosmetics,
      type: VaultItemType.repeatable, // Limit per business handled in purchase logic
      cost: 30,
      iconData: Icons.business, // Example icon
    ),
    // ADDED: Platinum Crest
    VaultItem(
      id: 'platinum_crest',
      name: 'Platinum Crest',
      description: 'Display a prestigious platinum crest in your empire HQ view.',
      category: VaultItemCategory.cosmetics,
      type: VaultItemType.oneTime,
      cost: 75,
      iconData: Icons.shield_moon, // Example icon
    ),
    // ADDED: Platinum Spire Trophy
    VaultItem(
      id: 'platinum_spire',
      name: 'Platinum Spire Trophy',
      description: 'Place a cosmetic platinum statue in one chosen unlocked locale.',
      category: VaultItemCategory.cosmetics,
      type: VaultItemType.oneTime,
      cost: 100,
      iconData: Icons.emoji_events, // Example icon (reuse?)
    ),
    // ADDED: Platinum Surge
    VaultItem(
      id: 'platinum_surge',
      name: 'Income Surge (1h)',
      description: 'Doubles ALL income sources for 1 hour.',
      category: VaultItemCategory.boosters,
      type: VaultItemType.repeatable, // TODO: Implement 1x per day limit
      cost: 25,
      iconData: Icons.flash_on, // Example icon
    ),
    // ADDED: Platinum Time Warp
    VaultItem(
      id: 'platinum_warp',
      name: 'Time Warp (4h)',
      description: 'Instantly receive 4 hours worth of passive income.',
      category: VaultItemCategory.boosters,
      type: VaultItemType.repeatable, // TODO: Implement 2x per week limit
      cost: 50,
      iconData: Icons.hourglass_bottom, // Example icon
    ),
    // ADDED: Platinum Cash Cache
    VaultItem(
      id: 'platinum_cache',
      name: 'Cash Cache',
      description: 'Instantly receive a cash injection (scales with progress).',
      category: VaultItemCategory.boosters,
      type: VaultItemType.repeatable, // TODO: Implement 5x per week limit
      cost: 25,
      iconData: Icons.attach_money, // Example icon
    ),
    // ADDED: Platinum Islands (Missing from original implementation)
    VaultItem(
      id: 'platinum_islands',
      name: 'Platinum Islands',
      description: 'Unlocks a new global location with exclusive luxury properties.',
      category: VaultItemCategory.unlockables,
      type: VaultItemType.oneTime,
      cost: 500,
      iconData: Icons.beach_access, // Island icon
    ),
    // ADDED: Platinum Yacht
    VaultItem(
      id: 'platinum_yacht',
      name: 'Platinum Yacht',
      description: 'Unlocks a mega-yacht property with +5% income in its docked region.',
      category: VaultItemCategory.unlockables,
      type: VaultItemType.oneTime,
      cost: 175,
      iconData: Icons.sailing, // Yacht/sailing icon
    ),
    // ADDED: Platinum Island
    VaultItem(
      id: 'platinum_island',
      name: 'Sovereign Island',
      description: 'Unlocks an exclusive private island in Platinum Islands (+8% regional income).',
      category: VaultItemCategory.unlockables,
      type: VaultItemType.oneTime,
      cost: 225,
      iconData: Icons.landscape, // Island landscape icon
    ),

  ];
} 