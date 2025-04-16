import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../utils/number_formatter.dart'; // For formatting PP display
import '../data/platinum_vault_items.dart'; // Import actual item data
import '../widgets/vault_item_card.dart'; // Import the new card widget

class PlatinumVaultScreen extends StatefulWidget {
  const PlatinumVaultScreen({Key? key}) : super(key: key);

  @override
  _PlatinumVaultScreenState createState() => _PlatinumVaultScreenState();
}

class _PlatinumVaultScreenState extends State<PlatinumVaultScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<VaultItem> _vaultItems; // Hold the items

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: VaultItemCategory.values.length, vsync: this);
    _vaultItems = getVaultItems(); // Load items on init
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shield_moon_outlined, color: Colors.purple.shade200), // Vault icon
            const SizedBox(width: 8),
            const Text('Platinum Vault'),
          ],
        ),
        backgroundColor: Colors.grey.shade800, // Darker theme for vault
        actions: [
          // Display PP balance in AppBar
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Icon(Icons.star, color: Colors.purple.shade300, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${gameState.platinumPoints.toString()} PP',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.purple.shade300,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey.shade400,
          tabs: VaultItemCategory.values.map((category) => Tab(text: _getCategoryName(category))).toList(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey.shade800, Colors.grey.shade900],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: VaultItemCategory.values.map((category) {
            final categoryItems = _vaultItems.where((item) => item.category == category).toList();
            return _buildItemGrid(categoryItems, gameState);
          }).toList(),
        ),
      ),
    );
  }

  // Helper to get category name (you might want a more robust solution)
  String _getCategoryName(VaultItemCategory category) {
    switch (category) {
      case VaultItemCategory.upgrades: return 'Upgrades';
      case VaultItemCategory.unlockables: return 'Unlockables';
      case VaultItemCategory.eventsAndChallenges: return 'Events';
      case VaultItemCategory.cosmetics: return 'Cosmetics';
      case VaultItemCategory.boosters: return 'Boosters';
      default: return category.toString().split('.').last; // Fallback
    }
  }

  // Builds the grid view for a specific category
  Widget _buildItemGrid(List<VaultItem> items, GameState gameState) {
    if (items.isEmpty) {
      return _buildPlaceholderTab("No items available in this category yet.");
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200.0, // Adjust based on desired item size
        childAspectRatio: 2 / 3.5, // Decreased aspect ratio to give more height
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return VaultItemCard(
          item: item,
          currentPoints: gameState.platinumPoints,
          isOwned: item.type == VaultItemType.oneTime && gameState.ppOwnedItems.contains(item.id),
          onBuy: () {
            bool success = gameState.spendPlatinumPoints(
              item.id,
              item.cost,
              isOneTime: item.type == VaultItemType.oneTime,
            );
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Purchased ${item.name}!'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            } else {
              // Feedback for failure (e.g., insufficient funds or already owned)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Could not purchase ${item.name}. ${gameState.platinumPoints < item.cost ? "Not enough PP." : "Item already owned or unavailable."}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        );
      },
    );
  }

  // Placeholder for empty categories or initial state
  Widget _buildPlaceholderTab(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 50, color: Colors.grey.shade500),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Keep earning Platinum Points!",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
} 