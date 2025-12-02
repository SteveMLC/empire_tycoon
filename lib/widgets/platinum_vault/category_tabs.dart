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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF30363D),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        indicatorColor: const Color(0xFFFFD700),
        indicatorWeight: 3,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
        labelColor: const Color(0xFFFFD700),
        unselectedLabelColor: const Color(0xFF8B949E),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 0.8,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        tabs: VaultItemCategory.values.map((category) {
          final categoryIndex = VaultItemCategory.values.indexOf(category);
          return Tab(
            height: 44,
            child: AnimatedBuilder(
              animation: tabController.animation!, // Use animation for immediate response
              builder: (context, child) {
                // Calculate selection based on animation value for smooth transitions
                final animValue = tabController.animation!.value;
                final distance = (animValue - categoryIndex).abs();
                final _ = distance < 0.5; // Selected when closest to this tab
                final selectionProgress = (1.0 - distance.clamp(0.0, 1.0)); // 0-1 progress
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: selectionProgress > 0.3 ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFFFD700).withOpacity(0.2 * selectionProgress),
                        const Color(0xFFFFD700).withOpacity(0.05 * selectionProgress),
                      ],
                    ) : null,
                    borderRadius: BorderRadius.circular(8),
                    border: selectionProgress > 0.3 ? Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.4 * selectionProgress),
                      width: 1,
                    ) : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        size: 16,
                        color: Color.lerp(
                          const Color(0xFF8B949E),
                          const Color(0xFFFFD700),
                          selectionProgress,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(_getCategoryName(category)),
                    ],
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(52.0);

  IconData _getCategoryIcon(VaultItemCategory category) {
    switch (category) {
      case VaultItemCategory.boosters:
        return Icons.flash_on;
      case VaultItemCategory.cosmetics:
        return Icons.palette;
      case VaultItemCategory.eventsAndChallenges:
        return Icons.emoji_events;
      case VaultItemCategory.unlockables:
        return Icons.lock_open;
      case VaultItemCategory.upgrades:
        return Icons.upgrade;
      default:
        return Icons.category;
    }
  }

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