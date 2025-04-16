import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // To potentially access GameState for owned status?

import '../data/platinum_vault_items.dart';
import '../utils/number_formatter.dart'; // For formatting cost

class VaultItemCard extends StatelessWidget {
  final VaultItem item;
  final int currentPoints;
  final bool isOwned; // For one-time items
  final VoidCallback onBuy;

  const VaultItemCard({
    Key? key,
    required this.item,
    required this.currentPoints,
    required this.isOwned,
    required this.onBuy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool canAfford = currentPoints >= item.cost;
    final bool isPurchasable = item.type == VaultItemType.repeatable || !isOwned;
    final bool isBuyButtonEnabled = canAfford && isPurchasable;

    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: Colors.grey.shade700, // Darker card theme
      clipBehavior: Clip.antiAlias, // Ensures content respects border radius
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Item Icon Section
          Container(
            height: 100, // Adjust height as needed
            color: Colors.grey.shade600,
            child: Icon(
              item.iconData ?? Icons.shopping_bag, // Use provided icon or fallback
              size: 40,
              color: Colors.purple.shade200,
            ),
          ),

          // Item Details Section
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade300,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Cost and Buy Button Section
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0),
            child: Column(
              children: [
                // Cost Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: Colors.purple.shade300, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${item.cost.toString()} PP',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: canAfford ? Colors.purple.shade200 : Colors.red.shade300,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Buy Button
                ElevatedButton(
                  onPressed: isBuyButtonEnabled ? onBuy : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOwned ? Colors.grey.shade500 : (isBuyButtonEnabled ? Colors.purple.shade400 : Colors.grey.shade600),
                    disabledBackgroundColor: isOwned ? Colors.grey.shade500 : Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isOwned ? 'Owned' : (canAfford ? 'Buy' : 'Not Enough PP'),
                    style: TextStyle(
                      color: isOwned ? Colors.grey.shade300 : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 