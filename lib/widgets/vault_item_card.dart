import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // To potentially access GameState for owned status?

import '../data/platinum_vault_items.dart';
import '../utils/number_formatter.dart'; // For formatting cost

class VaultItemCard extends StatelessWidget {
  final VaultItem item;
  final int currentPoints;
  final bool isOwned; // For one-time items OR if max repeatable reached
  final VoidCallback onBuy;
  final int? purchaseCount; // Optional: Current purchase count for repeatable items
  final int? maxPurchaseCount; // Optional: Max purchase count for repeatable items

  const VaultItemCard({
    Key? key,
    required this.item,
    required this.currentPoints,
    required this.isOwned,
    required this.onBuy,
    this.purchaseCount,
    this.maxPurchaseCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool canAfford = currentPoints >= item.cost;
    // Determine if the item is purchasable based on type, owned status, and limits
    final bool isRepeatable = item.type == VaultItemType.repeatable;
    final bool isMaxedOut = isRepeatable && 
                           maxPurchaseCount != null && 
                           purchaseCount != null && 
                           purchaseCount! >= maxPurchaseCount!;
    final bool isPurchasable = (isRepeatable && !isMaxedOut) || (!isRepeatable && !isOwned);
    final bool isBuyButtonEnabled = canAfford && isPurchasable;

    // Determine text for the button
    String buttonText = 'Buy';
    if (!canAfford) {
        buttonText = 'Not Enough PP';
    } else if (isMaxedOut) {
        buttonText = 'Maxed Out (${maxPurchaseCount!}/${maxPurchaseCount!})';
    } else if (!isRepeatable && isOwned) {
        buttonText = 'Owned';
    }

    // Text to display purchase count if applicable
    String countText = '';
    if (isRepeatable && maxPurchaseCount != null && purchaseCount != null) {
        countText = ' (${purchaseCount!}/${maxPurchaseCount!})';
    }

    return Card(
      elevation: 8.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: isOwned || isMaxedOut
              ? const Color(0xFFFFD700).withOpacity(0.7)
              : const Color(0xFFAA00FF).withOpacity(0.3),
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      color: const Color(0xFF2D0C3E), // Rich purple for luxury
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF3A1249),
              const Color(0xFF260B33),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Item Icon Section with metallic accent
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF4A1259),
                    const Color(0xFF38134A),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFFFD700).withOpacity(0.4),
                    width: 1.0,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Subtle shine overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Icon with glow effect if affordable
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF38134A),
                        border: Border.all(
                          color: canAfford 
                              ? const Color(0xFFFFD700).withOpacity(0.7)
                              : Colors.grey.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          if (canAfford)
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      child: Icon(
                        item.iconData ?? Icons.shopping_bag,
                        size: 32,
                        color: canAfford 
                            ? const Color(0xFFFFD700)
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Item Details Section with platinum accents
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item name with platinum accent for owned items
                  Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isOwned 
                          ? const Color(0xFFFFD700) // Gold for owned items
                          : const Color(0xFFF0F0F0), // Light color for others
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 1,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Description with subtle styling
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade300,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Cost and Buy Button Section with enhanced styling
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0),
              child: Column(
                children: [
                  // Cost Display with platinum coin icon
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: canAfford 
                            ? const Color(0xFFFFD700).withOpacity(0.6)
                            : Colors.red.shade300.withOpacity(0.4),
                        width: 1,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF4A1259).withOpacity(0.5),
                          const Color(0xFF38134A).withOpacity(0.5),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Custom platinum coin
                        Container(
                          width: 18,
                          height: 18,
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
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${item.cost.toString()} PP',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: canAfford 
                                ? const Color(0xFFFFD700)
                                : Colors.red.shade300,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Buy Button with luxury styling
                  ElevatedButton(
                    onPressed: isBuyButtonEnabled ? onBuy : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOwned 
                          ? const Color(0xFF38134A)
                          : (isBuyButtonEnabled 
                              ? const Color(0xFF8E44AD) // Purple color
                              : const Color(0xFF38134A)),
                      disabledBackgroundColor: isOwned 
                          ? const Color(0xFF38134A)
                          : const Color(0xFF2D0C3E),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isOwned 
                              ? const Color(0xFFFFD700).withOpacity(0.3)
                              : (isBuyButtonEnabled 
                                  ? const Color(0xFFFFD700).withOpacity(0.6)
                                  : Colors.grey.shade600),
                          width: 1.0,
                        ),
                      ),
                      elevation: isBuyButtonEnabled ? 4 : 0,
                      shadowColor: const Color(0xFFFFD700).withOpacity(0.3),
                    ),
                    child: Text(
                      isOwned ? 'Owned' : (canAfford ? 'Buy' : 'Not Enough PP'),
                      style: TextStyle(
                        color: isOwned 
                            ? const Color(0xFFFFD700).withOpacity(0.7)
                            : (isBuyButtonEnabled 
                                ? const Color(0xFFFFD700)
                                : Colors.grey.shade400),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 