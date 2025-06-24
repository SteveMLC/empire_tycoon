import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../../models/game_state.dart';
import '../../data/platinum_vault_items.dart';
import '../../widgets/vault_item_card.dart';
import '../../models/real_estate.dart';
import 'purchase_handler.dart';

/// Widget that displays the grid of items for a specific category
class CategoryContent extends StatelessWidget {
  final VaultItemCategory category;
  final List<VaultItem> items;
  
  const CategoryContent({
    Key? key,
    required this.category,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final filteredItems = items.where((item) => item.category == category).toList();
    
    if (filteredItems.isEmpty) {
      return const Center(
        child: Text(
          'No items available in this category',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 96.0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200.0,
        childAspectRatio: 2 / 4.2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        
        // Check if the item is already owned
        final isOwned = gameState.ppOwnedItems.contains(item.id);
        final purchaseCount = gameState.ppPurchases[item.id] ?? 0;
        final now = DateTime.now();
        
        // Determine specific item status from GameState
        bool isActive = false;
        DateTime? cooldownEndTime;
        DateTime? activeEndTime;
        int usesLeft = 0;
        int maxUses = 0;
        int? maxPurchases;
        
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
            activeEndTime = gameState.platinumClickFrenzyEndTime;
            break;
          case 'temp_boost_2x_10min':
            isActive = gameState.isSteadyBoostActive;
            activeEndTime = gameState.platinumSteadyBoostEndTime;
            break;
          case 'platinum_foundation':
            maxPurchases = 5;
            break;
          case 'cosmetic_platinum_frame':
            isActive = gameState.isPlatinumFrameUnlocked;
            break;
          case 'unlock_stats_theme_1':
            isActive = gameState.isExecutiveStatsThemeUnlocked;
            break;
          case 'platinum_challenge':
            gameState.checkAndResetPlatinumChallengeLimit(now);
            maxUses = 2;
            usesLeft = max(0, maxUses - gameState.platinumChallengeUsesToday);
            isActive = gameState.activeChallenge != null && 
                      gameState.activeChallenge!.itemId == 'platinum_challenge' && 
                      gameState.activeChallenge!.isActive(now);
            break;
          case 'platinum_crest':
            isActive = gameState.isPlatinumCrestUnlocked;
            break;
          case 'platinum_spire':
            isActive = gameState.platinumSpireLocaleId != null;
            break;
        }
        
        // Determine if the item is currently on cooldown
        bool onCooldown = cooldownEndTime != null && now.isBefore(cooldownEndTime);
        Duration? cooldownRemaining = onCooldown ? cooldownEndTime.difference(now) : null;
        
        // Determine remaining active duration
        Duration? activeRemaining = isActive && activeEndTime != null ? activeEndTime.difference(now) : null;
        if (activeRemaining != null && activeRemaining.isNegative) {
          activeRemaining = Duration.zero;
          isActive = false;
        }
        
        // Check for special items that need additional context
        bool hasValidContext = true;
        String? errorMessage;
        
        if (item.id == 'platinum_foundation' && !isOwned) {
          final availableLocales = gameState.realEstateLocales
              .where((locale) => locale.unlocked && !gameState.platinumFoundationsApplied.containsKey(locale.id))
              .toList();
              
          if (availableLocales.isEmpty) {
            hasValidContext = false;
            errorMessage = 'No available locations for foundation';
          } else if (gameState.platinumFoundationsApplied.length >= 5) {
            hasValidContext = false;
            errorMessage = 'Maximum of 5 foundations already applied';
          }
        } else if (item.id == 'platinum_facade' && !isOwned) {
          final availableBusinesses = gameState.getBusinessesForPlatinumFacade();
          if (availableBusinesses.isEmpty) {
            hasValidContext = false;
            errorMessage = 'No available businesses for facade';
          }
        } else if (item.id == 'platinum_yacht' && !isOwned) {
          final unlockedLocales = gameState.realEstateLocales.where((locale) => locale.unlocked).toList();
          if (unlockedLocales.isEmpty) {
            hasValidContext = false;
            errorMessage = 'No available locations to dock yacht';
          }
        }
        
        // Return the item card with appropriate context
        return VaultItemCard(
          item: item,
          currentPoints: gameState.platinumPoints,
          isOwned: isOwned,
          purchaseCount: purchaseCount,
          maxPurchaseCount: maxPurchases,
          
          isActive: isActive,
          activeDurationRemaining: activeRemaining,
          isOnCooldown: onCooldown,
          cooldownDurationRemaining: cooldownRemaining,
          usesLeft: usesLeft,
          maxUses: maxUses,
          
          isAnyPlatinumBoostActive: gameState.isPlatinumBoostActive,
          activeBoostRemainingSeconds: (item.id == 'temp_boost_10x_5min')
              ? gameState.platinumClickFrenzyRemainingSeconds
              : (item.id == 'temp_boost_2x_10min')
                  ? gameState.platinumSteadyBoostRemainingSeconds
                  : null,
          
          onBuy: () {
            // Pre-purchase check for instant feedback
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
            
            // Use the purchase handler
            PurchaseHandler.handlePurchase(context, gameState, item);
          },
        );
      },
    );
  }
} 