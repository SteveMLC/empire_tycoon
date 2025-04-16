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
  final int cost; // Cost in Platinum Points
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
      id: 'unlock_golden_cursor',
      name: 'Golden Cursor',
      description: 'Unlock a flashy golden cursor effect for tapping!',
      category: VaultItemCategory.unlockables,
      type: VaultItemType.oneTime,
      cost: 75,
      iconData: Icons.mouse,
    ),
    VaultItem(
      id: 'unlock_stats_theme_1',
      name: 'Executive Stats Theme',
      description: 'Unlock a sleek executive theme for the Stats screen.',
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

  ];
} 