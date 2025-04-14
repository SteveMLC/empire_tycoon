import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/business.dart';
import '../models/game_state.dart';
import '../utils/number_formatter.dart';

class BusinessItem extends StatelessWidget {
  final Business business;
  final VoidCallback onBuy;
  
  const BusinessItem({
    Key? key,
    required this.business,
    required this.onBuy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        // Check if player can afford this business
        bool canAfford = gameState.money >= business.getNextUpgradeCost();
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and name
                Row(
                  children: [
                    Icon(business.icon, size: 32, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            business.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Level: ${business.level}${business.isMaxLevel() ? " (MAX)" : ""}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),
                
                // Business description
                Text(
                  business.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Current level description (if business is owned)
                business.level > 0 ? Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.blue.withOpacity(0.1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Current: ${business.getCurrentLevelDescription()}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ) : const SizedBox.shrink(),
                
                // Show next level description if not at max level
                !business.isMaxLevel() ? Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.green.withOpacity(0.1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.upgrade, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          business.level == 0 
                            ? 'Unlock: ${business.getNextLevelDescription()}'
                            : 'Next: ${business.getNextLevelDescription()}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ) : const SizedBox.shrink(),
                
                const SizedBox(height: 15),
                
                // Business stats
                _buildBusinessStats(),
                
                // Income progress indicator if owned
                if (business.level > 0) _buildProgressIndicator(),
                
                const SizedBox(height: 10),
                
                // Buy button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: business.isMaxLevel() ? null : (canAfford ? onBuy : null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: business.isMaxLevel() 
                          ? Colors.grey
                          : (canAfford ? Colors.green : Colors.grey),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      business.isMaxLevel() 
                          ? 'MAX LEVEL'
                          : business.level == 0
                              ? 'Buy: ${NumberFormatter.formatCurrency(business.getNextUpgradeCost())}'
                              : 'Upgrade to Lvl ${business.level + 1}: ${NumberFormatter.formatCurrency(business.getNextUpgradeCost())}',
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
  
  Widget _buildBusinessStats() {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        // Calculate business income with all multipliers applied
        double incomeWithMultipliers = business.getCurrentIncome() * gameState.incomeMultiplier * gameState.prestigeMultiplier;
        // Check if this business is affected by an active event
        bool hasActiveEvent = gameState.hasActiveEventForBusiness(business.id);
        
        // Calculate income with event effects (if any)
        double incomePerSecondWithMultipliers = business.getIncomePerSecond(affectedByEvent: hasActiveEvent) * 
                                              gameState.incomeMultiplier * 
                                              gameState.prestigeMultiplier;
        
        return Column(
          children: [
            // Income per second (consolidated display)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Income:'),
                Row(
                  children: [
                    Text(
                      '${NumberFormatter.formatCurrency(incomePerSecondWithMultipliers)}/s',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: hasActiveEvent ? Colors.red : null,
                      ),
                    ),
                    if (hasActiveEvent)
                      const Icon(Icons.warning_amber_rounded, 
                        color: Colors.red, 
                        size: 16,
                      ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 6),
            
            // ROI (Return on Investment) - adjusted for multipliers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ROI:'),
                Text(
                  '${(business.getROI() * gameState.incomeMultiplier * gameState.prestigeMultiplier).toStringAsFixed(2)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Next income in ${business.getTimeToNextIncome()} seconds',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: business.getIncomeProgress(),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ],
      ),
    );
  }
}