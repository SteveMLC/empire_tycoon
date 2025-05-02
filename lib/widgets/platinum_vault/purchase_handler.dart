import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../models/game_state.dart';
import '../../data/platinum_vault_items.dart';
import '../../services/game_service.dart';
import '../../utils/asset_loader.dart';
import '../../models/real_estate.dart';
import '../../models/mogul_avatar.dart';
import 'locale_selection_dialog.dart';
import '../platinum_facade_selector.dart';

/// A utility class that handles the purchase logic for platinum vault items
class PurchaseHandler {
  /// Shows a feedback snackbar after a purchase attempt
  static void showPurchaseFeedback(
    BuildContext context, 
    bool success, 
    VaultItem item, 
    GameState gameState, {
    String? selectedLocaleName, 
    String? extraMessage
  }) {
    if (success) {
      try {
        final gameService = Provider.of<GameService>(context, listen: false);
        // Preload the sound first, then play it
        final assetLoader = AssetLoader();
        unawaited(assetLoader.preloadSound('assets/sounds/platinum/platinum_purchase.mp3'));
        // Use the playSound method directly which has better error handling
        gameService.soundManager.playPlatinumPurchaseSound();
      } catch (e) {
        print("Error playing platinum purchase sound: $e");
        // Continue with the purchase process even if sound fails
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

  /// Handle purchase of a platinum vault item
  static void handlePurchase(BuildContext context, GameState gameState, VaultItem item) {
    if (item.id == 'platinum_foundation') {
      _showLocaleSelectionDialog(context, gameState, item);
    } else if (item.id == 'platinum_facade') {
      _showBusinessSelectionDialog(context, gameState, item);
    } else if (item.id == 'platinum_yacht') {
      if (gameState.isPlatinumYachtUnlocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Platinum Yacht already unlocked."),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      _showYachtDockingDialog(context, gameState, item);
    } else if (item.id == 'platinum_spire') {
      if (gameState.platinumSpireLocaleId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Platinum Spire Trophy already placed."),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      _showSpireLocaleSelectionDialog(context, gameState, item);
    } else if (item.id == 'unlock_stats_theme_1') {
      bool success = gameState.spendPlatinumPoints(item.id, item.cost);
      if (success) {
        _showStatsThemeUnlockDialog(context, gameState);
      } else {
        showPurchaseFeedback(context, success, item, gameState);
      }
    } else if (item.id == 'cosmetic_platinum_frame') {
      bool success = gameState.spendPlatinumPoints(item.id, item.cost);
      if (success) {
        _showPlatinumFrameUnlockDialog(context, gameState);
      } else {
        showPurchaseFeedback(context, success, item, gameState);
      }
    } else if (item.id == 'platinum_mogul') {
      bool success = gameState.spendPlatinumPoints(item.id, item.cost);
      if (success) {
        _showMogulAvatarsUnlockDialog(context, gameState);
      } else {
        showPurchaseFeedback(context, success, item, gameState);
      }
    } else if (item.id == 'platinum_crest') {
      bool success = gameState.spendPlatinumPoints(item.id, item.cost);
      if (success) {
        _showPlatinumCrestUnlockDialog(context, gameState);
      } else {
        showPurchaseFeedback(context, success, item, gameState);
      }
    } else {
      // Default purchase logic for other items
      bool success = gameState.spendPlatinumPoints(item.id, item.cost);
      showPurchaseFeedback(context, success, item, gameState);
    }
  }

  // Private methods for showing specific dialogs
  
  /// Show dialog for selecting a locale for Platinum Foundation
  static void _showLocaleSelectionDialog(BuildContext context, GameState gameState, VaultItem item) {
    // Filter eligible locales: unlocked and not already boosted by this item
    final eligibleLocales = gameState.realEstateLocales
        .where((locale) => locale.unlocked && !gameState.platinumFoundationsApplied.containsKey(locale.id))
        .toList();

    if (gameState.platinumFoundationsApplied.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Maximum number of Foundations (5) already applied."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (eligibleLocales.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No eligible locations available to apply Foundation."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return LocaleSelectionDialog(
          eligibleLocales: eligibleLocales,
          onConfirm: (selectedLocaleId) {
            if (selectedLocaleId != null) {
              // Pass context for the purchase
              bool success = gameState.spendPlatinumPoints(
                item.id,
                item.cost,
                purchaseContext: {'selectedLocaleId': selectedLocaleId} // Pass selected locale ID
              );
              final selectedLocaleName = eligibleLocales
                  .firstWhere((l) => l.id == selectedLocaleId)
                  .name;
              showPurchaseFeedback(
                context, 
                success, 
                item, 
                gameState, 
                selectedLocaleName: selectedLocaleName
              );
            }
          },
        );
      },
    );
  }

  /// Show dialog for selecting yacht docking locale
  static void _showYachtDockingDialog(BuildContext context, GameState gameState, VaultItem item) {
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
        const SnackBar(
          content: Text("Yacht already docked elsewhere."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (eligibleLocales.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No eligible mega-locales unlocked to dock the yacht."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return YachtDockingSelectionDialog(
          eligibleLocales: eligibleLocales,
          onConfirm: (selectedLocaleId) {
            if (selectedLocaleId != null) {
              // Pass context for the purchase
              bool success = gameState.spendPlatinumPoints(
                item.id,
                item.cost,
                purchaseContext: {'selectedLocaleId': selectedLocaleId}
              );
              // Use selectedLocaleName in feedback if needed
              String? selectedName = eligibleLocales
                  .firstWhere(
                    (l) => l.id == selectedLocaleId, 
                    orElse: () => RealEstateLocale(
                      id: '', 
                      name: 'Unknown', 
                      properties: [], 
                      theme: '', 
                      icon: Icons.error, 
                      unlocked: false
                    )
                  )
                  .name;
              showPurchaseFeedback(
                context, 
                success, 
                item, 
                gameState, 
                selectedLocaleName: selectedName
              );
            }
          },
        );
      },
    );
  }

  /// Show dialog for selecting business for Platinum Facade
  static void _showBusinessSelectionDialog(
    BuildContext context, 
    GameState gameState, 
    VaultItem item
  ) async {
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
      bool success = gameState.spendPlatinumPoints(
        item.id, 
        item.cost, 
        purchaseContext: purchaseContext
      );
      
      // Show feedback to the user
      showPurchaseFeedback(
        context, 
        success, 
        item, 
        gameState, 
        selectedLocaleName: selectedBusinessName,
        extraMessage: 'Your business now has a stunning platinum appearance!'
      );
    }
  }

  /// Show dialog for Stats Theme unlock
  static void _showStatsThemeUnlockDialog(BuildContext context, GameState gameState) {
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
              showPurchaseFeedback(context, true, VaultItem(
                id: 'unlock_stats_theme_1',
                name: 'Executive Stats Theme',
                description: 'Unlock a sleek executive theme for the Stats screen.',
                category: VaultItemCategory.cosmetics,
                type: VaultItemType.oneTime,
                cost: 100,
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
              showPurchaseFeedback(context, true, VaultItem(
                id: 'unlock_stats_theme_1',
                name: 'Executive Stats Theme',
                description: 'Unlock a sleek executive theme for the Stats screen.',
                category: VaultItemCategory.cosmetics,
                type: VaultItemType.oneTime,
                cost: 100,
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

  /// Show dialog for Platinum Frame unlock
  static void _showPlatinumFrameUnlockDialog(BuildContext context, GameState gameState) {
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
              showPurchaseFeedback(context, true, VaultItem(
                id: 'cosmetic_platinum_frame',
                name: 'Platinum UI Frame',
                description: 'Apply a shiny platinum border to your main game UI.',
                category: VaultItemCategory.cosmetics,
                type: VaultItemType.oneTime,
                cost: 300,
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
              showPurchaseFeedback(context, true, VaultItem(
                id: 'cosmetic_platinum_frame',
                name: 'Platinum UI Frame',
                description: 'Apply a shiny platinum border to your main game UI.',
                category: VaultItemCategory.cosmetics,
                type: VaultItemType.oneTime,
                cost: 300,
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

  /// Show dialog for Mogul Avatars unlock
  static void _showMogulAvatarsUnlockDialog(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Mogul Avatars Unlocked!', 
          style: TextStyle(color: Color(0xFFFFD700)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You\'ve unlocked premium Mogul Avatars!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Access these exclusive avatars in your user profile settings.'),
          ],
        ),
        backgroundColor: const Color(0xFF2D2D3A),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              showPurchaseFeedback(context, true, VaultItem(
                id: 'platinum_mogul',
                name: 'Platinum Mogul',
                description: 'Unlock premium mogul avatars and executive theme.',
                category: VaultItemCategory.cosmetics,
                type: VaultItemType.oneTime,
                cost: 250,
              ), gameState);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            child: const Text('Got It!'),
          ),
        ],
      ),
    );
  }

  /// Show dialog for platinum crest unlock
  static void _showPlatinumCrestUnlockDialog(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade200,
                  Colors.grey.shade100,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE5E4E2), // Platinum color
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with platinum crest icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shield_moon,
                      size: 28,
                      color: Colors.grey.shade800,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Platinum Crest Unlocked',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Divider with platinum color
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFFE5E4E2), // Platinum color
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Preview of avatar with crest
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Shine effect behind the avatar
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFE5E4E2).withOpacity(0.5),
                            Colors.transparent,
                          ],
                          stops: const [0.6, 1.0],
                          radius: 0.7,
                        ),
                      ),
                    ),
                    
                    // Simulated crest effect
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE5E4E2),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE5E4E2).withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    
                    // Avatar container (simplified version for preview)
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE5E4E2),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: gameState.selectedMogulAvatarId != null
                          ? ClipOval(
                              child: Image.asset(
                                getMogulAvatars()
                                  .firstWhere((avatar) => avatar.id == gameState.selectedMogulAvatarId)
                                  .imagePath,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Text(
                                    getMogulAvatars()
                                      .firstWhere((avatar) => avatar.id == gameState.selectedMogulAvatarId)
                                      .emoji,
                                    style: const TextStyle(fontSize: 36),
                                  );
                                },
                              ),
                            )
                          : Text(
                              gameState.userAvatar ?? '👨‍💼',
                              style: const TextStyle(fontSize: 44),
                            ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Description text
                Text(
                  'Your prestigious Platinum Crest is now displayed proudly around your profile avatar, showcasing your elite status in the business world.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Other tycoons will recognize your distinguished achievements at a glance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Close button with platinum styling
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      
                      // Show purchase feedback after dialog closes
                      final item = VaultItem(
                        id: 'platinum_crest',
                        name: 'Platinum Crest',
                        description: 'Display a prestigious platinum crest in your empire profile.',
                        category: VaultItemCategory.cosmetics,
                        type: VaultItemType.oneTime,
                        cost: 75,
                        iconData: Icons.shield_moon,
                      );
                      
                      showPurchaseFeedback(context, true, item, gameState);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5E4E2),
                      foregroundColor: Colors.grey.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    child: const Text('CONTINUE', 
                      style: TextStyle(fontWeight: FontWeight.bold),
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

  /// Show dialog for selecting a locale for Platinum Spire Trophy
  static void _showSpireLocaleSelectionDialog(BuildContext context, GameState gameState, VaultItem item) {
    // Filter eligible locales: only show unlocked locales
    final eligibleLocales = gameState.realEstateLocales
        .where((locale) => locale.unlocked)
        .toList();

    if (eligibleLocales.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No eligible locations available to place the Spire Trophy."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return LocaleSelectionDialog(
          eligibleLocales: eligibleLocales,
          title: 'Select Trophy Location',
          message: 'Choose a location to display your prestigious Platinum Spire Trophy:',
          onConfirm: (selectedLocaleId) {
            if (selectedLocaleId != null) {
              // Pass context for the purchase
              bool success = gameState.spendPlatinumPoints(
                item.id,
                item.cost,
                purchaseContext: {'selectedLocaleId': selectedLocaleId} // Pass selected locale ID
              );
              
              final selectedLocaleName = eligibleLocales
                  .firstWhere((l) => l.id == selectedLocaleId)
                  .name;
              
              showPurchaseFeedback(
                context, 
                success, 
                item, 
                gameState, 
                selectedLocaleName: selectedLocaleName,
                extraMessage: 'The Platinum Spire Trophy now stands majestically in your chosen location!'
              );
            }
          },
        );
      },
    );
  }
} 