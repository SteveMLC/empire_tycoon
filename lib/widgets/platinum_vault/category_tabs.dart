import 'package:flutter/material.dart';
import '../../data/platinum_vault_items.dart';

/// Widget that displays the category tabs for the Platinum Vault
class CategoryTabs extends StatelessWidget implements PreferredSizeWidget {
  final TabController tabController;
  
  const CategoryTabs({
    Key? key,
    required this.tabController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: tabController,
      isScrollable: true,
      indicatorColor: const Color(0xFFFFD700), // Gold indicator
      labelColor: const Color(0xFFFFD700), // Gold text for selected tab
      unselectedLabelColor: Colors.grey.shade300,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        letterSpacing: 0.5,
      ),
      tabs: VaultItemCategory.values.map((category) =>
        Tab(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(_getCategoryName(category)),
          ),
        )
      ).toList(),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  /// Helper method to get a user-friendly name for each category
  String _getCategoryName(VaultItemCategory category) {
    switch (category) {
      case VaultItemCategory.upgrades:
        return 'Upgrades';
      case VaultItemCategory.boosters:
        return 'Boosters';
      case VaultItemCategory.cosmetics:
        return 'Cosmetics';
      case VaultItemCategory.unlockables:
        return 'Unlocks';
      case VaultItemCategory.eventsAndChallenges:
        return 'Events';
      default:
        return 'Unknown';
    }
  }
} 