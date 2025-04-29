import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math'; // ADDED: Import for max()

import '../models/game_state.dart';
import '../models/real_estate.dart'; // Import RealEstateLocale
import '../utils/number_formatter.dart'; // For formatting PP display
import '../data/platinum_vault_items.dart'; // Import actual item data
import '../widgets/vault_item_card.dart'; // Import the new card widget
import '../services/game_service.dart'; // Added import for GameService
import '../widgets/platinum_facade_selector.dart'; // Import the PlatinumFacadeSelector

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
                  gameState.platinumPoints.toString(),
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

  // Helper to build the grid for each category
  Widget _buildItemGrid(List<VaultItem> items, GameState gameState) {
    if (items.isEmpty) {
      return _buildPlaceholderTab("No items available in this category yet.");
    }

    // Adjust grid based on screen size
    final width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 600;
    
    // For mobile: always use 2 columns with better aspect ratio
    // For desktop: use 3-4 columns based on width
    final int crossAxisCount = isMobile ? 2 : (width < 1200 ? 3 : 4);
    
    // Use taller cards on mobile to fit content properly
    final double aspectRatio = isMobile ? 0.68 : 0.75;
    
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
        padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: aspectRatio,
          crossAxisSpacing: isMobile ? 10.0 : 16.0,
          mainAxisSpacing: isMobile ? 12.0 : 16.0,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final bool isOwned = gameState.ppOwnedItems.contains(item.id);
          final int purchaseCount = gameState.ppPurchases[item.id] ?? 0;
          final now = DateTime.now(); // For calculating remaining time

          // --- Determine specific item status from GameState --- 
          bool isActive = false;
          DateTime? cooldownEndTime;
          DateTime? activeEndTime;
          int usesLeft = 0; // Default/unused
          int maxUses = 0; // Default/unused
          int? maxPurchases; // MOVED declaration BEFORE switch

          switch (item.id) {
            case 'platinum_surge':
              isActive = gameState.isIncomeSurgeActive;
              activeEndTime = gameState.incomeSurgeEndTime;
              cooldownEndTime = gameState.incomeSurgeCooldownEnd;
              break;
            case 'platinum_cache':
              cooldownEndTime = gameState.cashCacheCooldownEnd;
              break;
            case 'platinum_warp':
              maxUses = 2;
              usesLeft = max(0, maxUses - gameState.timeWarpUsesThisPeriod);
              break;
            case 'platinum_shield':
              isActive = gameState.isDisasterShieldActive;
              activeEndTime = gameState.disasterShieldEndTime;
              break;
            case 'platinum_accelerator':
              isActive = gameState.isCrisisAcceleratorActive;
              activeEndTime = gameState.crisisAcceleratorEndTime;
              break;
            case 'temp_boost_10x_5min':
              isActive = gameState.isClickFrenzyActive;
              // activeEndTime = gameState.platinumClickFrenzyEndTime; // Can use this if needed
              break;
            case 'temp_boost_2x_10min':
              isActive = gameState.isSteadyBoostActive;
              // activeEndTime = gameState.platinumSteadyBoostEndTime; // Can use this if needed
              break;
            case 'platinum_foundation':
              maxPurchases = 5; // Assign value here
              // This item doesn't have a simple active/cooldown state at the item level
              break;
            case 'cosmetic_platinum_frame':
              print("DEBUG VAULT CARD: Item 'cosmetic_platinum_frame' - isPlatinumFrameUnlocked=${gameState.isPlatinumFrameUnlocked}, isPlatinumFrameActive=${gameState.isPlatinumFrameActive}");
              // Consider the item "active" if it's unlocked, even if not currently displayed
              isActive = gameState.isPlatinumFrameUnlocked;
              activeEndTime = null; // Frame is permanent, no end time
              break;
            case 'unlock_stats_theme_1':
              print("DEBUG VAULT CARD: Item 'unlock_stats_theme_1' - isExecutiveStatsThemeUnlocked=${gameState.isExecutiveStatsThemeUnlocked}, selectedStatsTheme=${gameState.selectedStatsTheme}");
              // Consider the item "active" if it's unlocked, even if not currently selected
              isActive = gameState.isExecutiveStatsThemeUnlocked;
              activeEndTime = null; // Stats theme is permanent, no end time
              break;
            case 'platinum_challenge':
              // Check daily usage limits
              DateTime now = DateTime.now();
              gameState.checkAndResetPlatinumChallengeLimit(now);
              maxUses = 2;
              usesLeft = max(0, maxUses - gameState.platinumChallengeUsesToday);
              isActive = gameState.activeChallenge != null && 
                        gameState.activeChallenge!.itemId == 'platinum_challenge' && 
                        gameState.activeChallenge!.isActive(now);
              // No cooldown for challenge, just daily limits
              break;
            // Add other items if they gain timed states later
          }

          // Determine if the item is currently on cooldown
          bool onCooldown = cooldownEndTime != null && now.isBefore(cooldownEndTime);
          Duration? cooldownRemaining = onCooldown ? cooldownEndTime.difference(now) : null;

          // Determine remaining active duration
          Duration? activeRemaining = isActive && activeEndTime != null ? activeEndTime.difference(now) : null;
          if (activeRemaining != null && activeRemaining.isNegative) {
            activeRemaining = Duration.zero; // Ensure it doesn't show negative
            isActive = false; // Correct the state if timer ran out but flag not cleared yet
          }

          // --- END Determine specific item status --- 

          // Define max purchases (example for platinum_foundation)
          if (item.id == 'platinum_foundation') {
             // Max purchases is now set within the switch case above
             // maxPurchases = 5; 
          }

          return VaultItemCard(
            item: item,
            currentPoints: gameState.platinumPoints,
            isOwned: isOwned, // For one-time items
            purchaseCount: purchaseCount, // For repeatable count display
            maxPurchaseCount: maxPurchases, // Pass the value (might be null for non-foundation)

            // --- Pass calculated status to card ---
            isActive: isActive,
            activeDurationRemaining: activeRemaining,
            isOnCooldown: onCooldown,
            cooldownDurationRemaining: cooldownRemaining,
            usesLeft: usesLeft, // e.g., for Time Warp
            maxUses: maxUses,   // e.g., for Time Warp

            // --- Keep existing booster logic for now, might refactor later ---
            isAnyPlatinumBoostActive: gameState.isPlatinumBoostActive, // For general booster checks if needed
            activeBoostRemainingSeconds: (item.id == 'temp_boost_10x_5min')
                ? gameState.platinumClickFrenzyRemainingSeconds
                : (item.id == 'temp_boost_2x_10min')
                    ? gameState.platinumSteadyBoostRemainingSeconds
                    : null,
            // --- END --- 

            onBuy: () {
              // --- ADDED: Pre-purchase check in UI for instant feedback ---
              if (isActive) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${item.name} is already active."), backgroundColor: Colors.orange),
                );
                return;
              }
              if (onCooldown) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text("${item.name} is on cooldown."), backgroundColor: Colors.orange),
                 );
                 return;
              }
              if (item.id == 'platinum_warp' && usesLeft <= 0) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text("${item.name} weekly limit reached."), backgroundColor: Colors.orange),
                 );
                 return;
              }
              // --- END Pre-purchase check ---

              // Proceed with purchase logic (dialogs or direct call)
              _handlePurchase(context, gameState, item);
            },
          );
        },
      ),
    );
  }

  // Handle purchase logic, including showing dialog for specific items
  void _handlePurchase(BuildContext context, GameState gameState, VaultItem item) {
    if (item.id == 'platinum_foundation') {
      // --- Special handling for Platinum Foundation ---
      _showLocaleSelectionDialog(context, gameState, item);
    } else if (item.id == 'platinum_facade') {
      // --- Special handling for Platinum Facade ---
      _showBusinessSelectionDialog(context, gameState, item);
    } else if (item.id == 'platinum_yacht') {
      // --- Special handling for Platinum Yacht ---
      // Check if yacht is already unlocked (it's a one-time purchase effect)
      if (gameState.isPlatinumYachtUnlocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Platinum Yacht already unlocked."), backgroundColor: Colors.orange),
        );
        return;
      }
      _showYachtDockingDialog(context, gameState, item);
    } else if (item.id == 'unlock_stats_theme_1') {
      // --- Special handling for Stats Theme ---
      bool success = gameState.spendPlatinumPoints(item.id, item.cost);
      if (success) {
        _showStatsThemeUnlockDialog(context, gameState);
      } else {
        _showPurchaseFeedback(context, success, item, gameState);
      }
    } else if (item.id == 'cosmetic_platinum_frame') {
      // --- Special handling for Platinum UI Frame ---
      bool success = gameState.spendPlatinumPoints(item.id, item.cost);
      if (success) {
        _showPlatinumFrameUnlockDialog(context, gameState);
      } else {
        _showPurchaseFeedback(context, success, item, gameState);
      }
    } else if (item.id == 'platinum_mogul') {
      // --- Special handling for Platinum Mogul ---
      bool success = gameState.spendPlatinumPoints(item.id, item.cost);
      if (success) {
        _showMogulAvatarsUnlockDialog(context, gameState);
      } else {
        _showPurchaseFeedback(context, success, item, gameState);
      }
    } else {
      // --- Default purchase logic for other items ---
      bool success = gameState.spendPlatinumPoints(item.id, item.cost);
      _showPurchaseFeedback(context, success, item, gameState);
    }
  }

  // Show dialog for selecting locale for Platinum Foundation
  void _showLocaleSelectionDialog(BuildContext context, GameState gameState, VaultItem item) {
    // Filter eligible locales: unlocked and not already boosted by this item
    // Assuming 1 foundation per locale for now. Check global limit as well.
    final eligibleLocales = gameState.realEstateLocales
        .where((locale) => locale.unlocked && !gameState.platinumFoundationsApplied.containsKey(locale.id))
        .toList();

    if (gameState.platinumFoundationsApplied.length >= 5) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Maximum number of Foundations (5) already applied."), backgroundColor: Colors.orange),
        );
        return;
    }

    if (eligibleLocales.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No eligible locations available to apply Foundation."), backgroundColor: Colors.orange),
        );
        return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return _LocaleSelectionDialog(
          eligibleLocales: eligibleLocales,
          onConfirm: (selectedLocaleId) {
            if (selectedLocaleId != null) {
                // Pass context for the purchase
                bool success = gameState.spendPlatinumPoints(
                    item.id,
                    item.cost,
                    purchaseContext: {'selectedLocaleId': selectedLocaleId} // Pass selected locale ID
                );
                _showPurchaseFeedback(context, success, item, gameState, selectedLocaleName: eligibleLocales.firstWhere((l) => l.id == selectedLocaleId).name);
            }
          },
        );
      },
    );
  }

  // Show dialog for selecting Yacht Docking locale
  void _showYachtDockingDialog(BuildContext context, GameState gameState, VaultItem item) {
    // Define eligible "mega locales"
    const List<String> megaLocaleIds = [
      'dubai_uae', 'hong_kong', 'los_angeles', 'new_york_city', 
      'platinum_islands', 'miami_florida', 'london_uk', 'singapore'
    ];

    // Filter eligible locales: must be in megaLocaleIds AND unlocked
    final eligibleLocales = gameState.realEstateLocales
        .where((locale) => megaLocaleIds.contains(locale.id) && locale.unlocked)
        .toList();

    // Check if yacht already docked (should technically be covered by isPlatinumYachtUnlocked, but good safeguard)
    if (gameState.platinumYachtDockedLocaleId != null) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Yacht already docked elsewhere."), backgroundColor: Colors.orange),
        );
        return;
    }

    if (eligibleLocales.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No eligible mega-locales unlocked to dock the yacht."), backgroundColor: Colors.orange),
        );
        return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Use a stateful builder for the dropdown inside the dialog
        return _YachtDockingSelectionDialog(
          eligibleLocales: eligibleLocales,
          onConfirm: (selectedLocaleId) {
            if (selectedLocaleId != null) {
                // Pass context for the purchase
                bool success = gameState.spendPlatinumPoints(
                    item.id,
                    item.cost,
                    purchaseContext: {'selectedLocaleId': selectedLocaleId} // Pass selected locale ID
                );
                // Use selectedLocaleName in feedback if needed
                String? selectedName = eligibleLocales.firstWhere((l) => l.id == selectedLocaleId, orElse: () => RealEstateLocale(id: '', name: 'Unknown', properties: [], theme: '', icon: Icons.error, unlocked: false)).name;
                _showPurchaseFeedback(context, success, item, gameState, selectedLocaleName: selectedName);
            }
          },
        );
      },
    );
  }

  // Show dialog for Mogul Avatars unlock
  void _showMogulAvatarsUnlockDialog(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4A1259),
                  const Color(0xFF2D0C3E),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.6),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title with gold shimmer
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Colors.amber.shade200,
                      const Color(0xFFFFD700),
                      Colors.amber.shade200,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ).createShader(bounds),
                  child: const Text(
                    "Premium Mogul Look Unlocked!",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Avatar preview section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "You've unlocked exclusive mogul avatars!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Avatar preview row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Show 4 sample avatars
                          _buildSampleAvatarPreview('👑👨'),
                          _buildSampleAvatarPreview('👑👸'),
                          _buildSampleAvatarPreview('🧔‍♂️💼'),
                          _buildSampleAvatarPreview('📈👩'),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      const Text(
                        "Access them in your user profile!",
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Close button
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    // Show success feedback after closing dialog
                    _showPurchaseFeedback(
                      context, 
                      true, 
                      getVaultItems().firstWhere((i) => i.id == 'platinum_mogul'), 
                      gameState
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.amber.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: const BorderSide(color: Colors.amber, width: 1),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: const Text(
                    "Got it!",
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper for avatar preview in unlock dialog
  Widget _buildSampleAvatarPreview(String emoji) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade700.withOpacity(0.3),
            Colors.amber.shade300.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.amber.withOpacity(0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.2),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  // Show SnackBar feedback after purchase attempt
  void _showPurchaseFeedback(BuildContext context, bool success, VaultItem item, GameState gameState, {String? selectedLocaleName, String? extraMessage}) {
      if (success) {
          try {
            final gameService = Provider.of<GameService>(context, listen: false);
            gameService.soundManager.playPlatinumPurchaseSound();
          } catch (e) {
            print("Error playing platinum purchase sound: $e");
          }
          String message = 'Successfully purchased ${item.name}!';
          if (item.id == 'platinum_foundation' && selectedLocaleName != null) {
              message += ' Applied to $selectedLocaleName.';
          } else if (item.id == 'platinum_yacht' && selectedLocaleName != null) {
              message += ' Docked at $selectedLocaleName.';
          }
          if (extraMessage != null) {
              message += ' $extraMessage';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Flexible(child: Text(message)),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          // TODO: Add sparkle animation on successful purchase
      } else {
          String errorMessage = 'Purchase failed.';
          if (gameState.platinumPoints < item.cost) {
              errorMessage = 'Not enough Platinum to purchase ${item.name}.';
          } else if (item.type == VaultItemType.oneTime && gameState.ppOwnedItems.contains(item.id)) {
              errorMessage = 'You already own this item.';
          } else if (item.id == 'platinum_foundation' && gameState.platinumFoundationsApplied.length >= 5){
               errorMessage = 'Cannot apply Foundation: Maximum limit (5) reached.';
          } else {
              // Generic failure or specific reason if available from gameState
              errorMessage = 'Could not purchase ${item.name}.';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Flexible(child: Text(errorMessage)),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
      }
  }

  // Add the method to show the theme unlock dialog
  void _showStatsThemeUnlockDialog(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Executive Stats Theme Unlocked!', 
          style: TextStyle(color: Color(0xFFE5C100)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You\'ve unlocked the premium Executive Stats Theme!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('This exclusive theme gives your Stats screen a professional, executive look.'),
            const SizedBox(height: 16),
            const Text('Would you like to apply this theme now?'),
          ],
        ),
        backgroundColor: const Color(0xFF2D2D3A),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE5C100), width: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Don't activate theme yet
              Navigator.of(dialogContext).pop();
              _showPurchaseFeedback(context, true, VaultItem(
                id: 'unlock_stats_theme_1',
                name: 'Executive Stats Theme',
                description: 'Unlock a sleek executive theme for the Stats screen.',
                category: VaultItemCategory.unlockables,
                type: VaultItemType.oneTime,
                cost: 100,
                iconData: Icons.style,
              ), gameState);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
            ),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              // Activate the theme
              gameState.selectStatsTheme('executive');
              Navigator.of(dialogContext).pop();
              _showPurchaseFeedback(context, true, VaultItem(
                id: 'unlock_stats_theme_1',
                name: 'Executive Stats Theme',
                description: 'Unlock a sleek executive theme for the Stats screen.',
                category: VaultItemCategory.unlockables,
                type: VaultItemType.oneTime,
                cost: 100,
                iconData: Icons.style,
              ), gameState, extraMessage: 'Theme activated!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5C100),
              foregroundColor: Colors.black,
            ),
            child: const Text('Apply Now'),
          ),
        ],
      ),
    );
  }

  void _showPlatinumFrameUnlockDialog(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Platinum UI Frame Unlocked!', 
          style: TextStyle(color: Color(0xFFFFD700)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You\'ve unlocked the premium Platinum UI Frame!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('This exclusive frame gives your game a luxurious, premium look with golden accents and rich styling.'),
            const SizedBox(height: 16),
            const Text('Would you like to apply this frame now?'),
          ],
        ),
        backgroundColor: const Color(0xFF2D2D3A),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Don't activate theme yet
              Navigator.of(dialogContext).pop();
              _showPurchaseFeedback(context, true, VaultItem(
                id: 'cosmetic_platinum_frame',
                name: 'Platinum UI Frame',
                description: 'Apply a shiny platinum border to your main game UI.',
                category: VaultItemCategory.cosmetics,
                type: VaultItemType.oneTime,
                cost: 300,
                iconData: Icons.image_aspect_ratio,
              ), gameState);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
            ),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              // Activate the platinum frame
              gameState.togglePlatinumFrame(true);
              Navigator.of(dialogContext).pop();
              _showPurchaseFeedback(context, true, VaultItem(
                id: 'cosmetic_platinum_frame',
                name: 'Platinum UI Frame',
                description: 'Apply a shiny platinum border to your main game UI.',
                category: VaultItemCategory.cosmetics,
                type: VaultItemType.oneTime,
                cost: 300,
                iconData: Icons.image_aspect_ratio,
              ), gameState, extraMessage: 'Frame activated!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            child: const Text('Apply Now'),
          ),
        ],
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
            "Keep earning Platinum!",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // Show dialog to select a business to apply the Platinum Facade to
  void _showBusinessSelectionDialog(BuildContext context, GameState gameState, VaultItem item) async {
    // Show the business selection dialog
    final selectedBusinessId = await PlatinumFacadeSelector.show(context);
    
    // Handle the selection
    if (selectedBusinessId != null) {
      // Get the business name for feedback
      final selectedBusiness = gameState.businesses.firstWhere(
        (b) => b.id == selectedBusinessId,
        orElse: () => gameState.businesses.first // Provide a default value
      );
      final selectedBusinessName = selectedBusiness.name;
      
      // Create context for the purchase
      final purchaseContext = {'selectedBusinessId': selectedBusinessId};
      
      // Attempt to purchase and apply the Platinum Facade
      bool success = gameState.spendPlatinumPoints(item.id, item.cost, purchaseContext: purchaseContext);
      
      // Show feedback to the user
      _showPurchaseFeedback(
        context, 
        success, 
        item, 
        gameState, 
        selectedLocaleName: selectedBusinessName,
        extraMessage: 'Your business now has a stunning platinum appearance!'
      );
    }
  }
}


// --- Locale Selection Dialog Widget ---

class _LocaleSelectionDialog extends StatefulWidget {
  final List<RealEstateLocale> eligibleLocales;
  final Function(String?) onConfirm;

  const _LocaleSelectionDialog({
    required this.eligibleLocales,
    required this.onConfirm,
  });

  @override
  __LocaleSelectionDialogState createState() => __LocaleSelectionDialogState();
}

class __LocaleSelectionDialogState extends State<_LocaleSelectionDialog> {
  String? _selectedLocaleId;

  @override
  void initState() {
    super.initState();
    // Pre-select the first eligible locale if available
    if (widget.eligibleLocales.isNotEmpty) {
      _selectedLocaleId = widget.eligibleLocales.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Location'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose a location to apply the Platinum Foundation (+5% Income):'),
          const SizedBox(height: 16),
          if (widget.eligibleLocales.isNotEmpty)
            DropdownButton<String>(
              value: _selectedLocaleId,
              isExpanded: true,
              hint: const Text('Select Location'),
              items: widget.eligibleLocales.map((locale) {
                return DropdownMenuItem<String>(
                  value: locale.id,
                  child: Text(locale.name), // Display locale name
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedLocaleId = newValue;
                });
              },
            )
          else
            const Text('No locations available for boost.', style: TextStyle(color: Colors.grey)),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
        ),
        TextButton(
          child: const Text('Confirm'),
          onPressed: _selectedLocaleId == null ? null : () { // Disable confirm if nothing selected
            widget.onConfirm(_selectedLocaleId);
            Navigator.of(context).pop(); // Close the dialog
          },
        ),
      ],
    );
  }
}

// --- ADDED: Yacht Docking Selection Dialog Widget ---

class _YachtDockingSelectionDialog extends StatefulWidget {
  final List<RealEstateLocale> eligibleLocales;
  final Function(String?) onConfirm;

  const _YachtDockingSelectionDialog({
    required this.eligibleLocales,
    required this.onConfirm,
  });

  @override
  __YachtDockingSelectionDialogState createState() => __YachtDockingSelectionDialogState();
}

class __YachtDockingSelectionDialogState extends State<_YachtDockingSelectionDialog> {
  String? _selectedLocaleId;

  @override
  void initState() {
    super.initState();
    // Pre-select the first eligible locale if available
    if (widget.eligibleLocales.isNotEmpty) {
      _selectedLocaleId = widget.eligibleLocales.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Docking Location'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose a mega-locale to dock the Platinum Yacht (+5% Income):'),
          const SizedBox(height: 16),
          if (widget.eligibleLocales.isNotEmpty)
            DropdownButton<String>(
              value: _selectedLocaleId,
              isExpanded: true,
              hint: const Text('Select Location'),
              items: widget.eligibleLocales.map((locale) {
                return DropdownMenuItem<String>(
                  value: locale.id,
                  child: Text(locale.name), // Display locale name
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedLocaleId = newValue;
                });
              },
            )
          else
            const Text('No locations available for docking.', style: TextStyle(color: Colors.grey)),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
        ),
        TextButton(
          child: const Text('Confirm Docking'),
          onPressed: _selectedLocaleId == null ? null : () { // Disable confirm if nothing selected
            widget.onConfirm(_selectedLocaleId);
            Navigator.of(context).pop(); // Close the dialog
          },
        ),
      ],
    );
  }
} 