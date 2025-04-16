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
            // Custom vault icon with glow effect
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.8),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(Icons.shield_moon_outlined, color: const Color(0xFFFFD700), size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Platinum Vault',
              style: TextStyle(
                color: const Color(0xFFFFD700),
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.7),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2D0C3E), // Rich purple background for luxury
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.5),
        actions: [
          // Display PP balance in AppBar with enhanced styling
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4A1259).withOpacity(0.8),
                  const Color(0xFF7B1FA2).withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.6),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  blurRadius: 5,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                // Custom platinum coin
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFD700), // Solid gold background
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.6),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '✦',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${gameState.platinumPoints.toString()} PP',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
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
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          // Luxury rich purple gradient background
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2D0C3E), // Rich purple
              const Color(0xFF1A0523), // Darker purple
            ],
            stops: const [0.0, 1.0],
          ),
          // Add shimmer effect
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.05),
              blurRadius: 15,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative floating particles/stars
            ...List.generate(20, (index) {
              final random = 0.3 + (index / 20) * 0.7; // Create varied positions
              return Positioned(
                top: MediaQuery.of(context).size.height * (index % 5) / 5,
                left: MediaQuery.of(context).size.width * random,
                child: Container(
                  width: 3 + (index % 3),
                  height: 3 + (index % 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFD700).withOpacity(0.2 + (index % 10) / 20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            }),
            
            // Main content
            TabBarView(
              controller: _tabController,
              children: VaultItemCategory.values.map((category) {
                final categoryItems = _vaultItems.where((item) => item.category == category).toList();
                return _buildItemGrid(categoryItems, gameState);
              }).toList(),
            ),
          ],
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

    return Container(
      // Add subtle animated shine effect
      foregroundDecoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200.0,
          childAspectRatio: 2 / 3.5,
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
                // Enhanced success feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('Successfully purchased ${item.name}!'),
                      ],
                    ),
                    backgroundColor: Colors.green.shade600,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
                
                // TODO: Add sparkle animation on successful purchase
              } else {
                // Enhanced error feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            gameState.platinumPoints < item.cost
                                ? 'Not enough Platinum Points to purchase ${item.name}.'
                                : 'You already own this item.',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red.shade600,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
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