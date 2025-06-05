import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';

import '../models/real_estate.dart';
import '../models/game_state.dart';
import '../utils/number_formatter.dart';

class RealEstatePropertyItem extends StatelessWidget {
  final RealEstateProperty property;
  final String localeId;
  final VoidCallback onBuy;
  final bool canAfford;

  const RealEstatePropertyItem({
    Key? key,
    required this.property,
    required this.localeId,
    required this.onBuy,
    required this.canAfford,
  }) : super(key: key);
  
  // Helper method to get the correct image path
  String getImagePath() {
    return 'assets/images/$localeId/${property.id}.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: Colors.green,
      ),
    );
    final gameState = Provider.of<GameState>(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Property image at the top
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            child: Image.asset(
              getImagePath(),
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to a placeholder if image can't be loaded
                return Container(
                  height: 150,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Icon(
                      Icons.home_work,
                      size: 50,
                      color: Colors.grey.shade400,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Builder(builder: (context) {
                        // Check if this property's locale is affected by an event
                        bool isLocaleAffectedByEvent = gameState.hasActiveEventForLocale(localeId);
                        
                        // Calculate income with event penalty if applicable
                        double baseIncome = property.cashFlowPerSecond;
                        if (isLocaleAffectedByEvent) {
                          baseIncome += baseIncome * -0.25; // Apply -25% penalty
                        }
                        
                        double displayedIncome = baseIncome * 
                                                gameState.incomeMultiplier * 
                                                gameState.prestigeMultiplier;
                        
                        return Row(
                          children: [
                            Icon(Icons.attach_money, 
                                color: isLocaleAffectedByEvent ? Colors.red.shade700 : Colors.green.shade700, 
                                size: 16),
                            const SizedBox(width: 4),
                            Text(
                              isLocaleAffectedByEvent && displayedIncome < 0
                                  ? '(\$${NumberFormatter.formatCompact(displayedIncome.abs())})/sec'
                                  : '\$${NumberFormatter.formatCompact(displayedIncome)}/sec',
                              style: TextStyle(
                                fontSize: 14,
                                color: isLocaleAffectedByEvent ? Colors.red.shade700 : Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.show_chart, color: Colors.green.shade700, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'ROI: ${property.getROI().toStringAsFixed(2)}%/sec',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Owned: ${property.owned}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (property.owned > 0)
                      // --- Calculate Correct Display Income --- 
                      Builder(builder: (context) {
                        bool isLocaleAffectedByEvent = gameState.hasActiveEventForLocale(localeId);
                        
                        // Fetch relevant multipliers from GameState
                        double permanentIncomeBoostMultiplier = gameState.isPermanentIncomeBoostActive ? 1.05 : 1.0;
                        bool isFoundationApplied = gameState.platinumFoundationsApplied.containsKey(localeId);
                        bool isYachtDocked = gameState.platinumYachtDockedLocaleId == localeId;
                        double foundationMultiplier = isFoundationApplied ? 1.05 : 1.0;
                        double yachtMultiplier = isYachtDocked ? 1.05 : 1.0;
                        
                        // Get base income per property
                        double basePropertyIncome = property.getTotalIncomePerSecond(isResilienceActive: gameState.isPlatinumResilienceActive);
                        
                        // Apply locale-specific multipliers
                        double incomeWithLocaleBoosts = basePropertyIncome * foundationMultiplier * yachtMultiplier;

                        // Apply standard global multipliers
                        double finalPropertyIncome = incomeWithLocaleBoosts * gameState.incomeMultiplier;

                        // Apply the overall permanent boost
                        finalPropertyIncome *= permanentIncomeBoostMultiplier;
                        
                        // Apply Income Surge (if applicable)
                        if (gameState.isIncomeSurgeActive) finalPropertyIncome *= 2.0;

                        // Check for negative event affecting the LOCALE and apply multiplier AFTER all bonuses
                        if (isLocaleAffectedByEvent) {
                          finalPropertyIncome *= 0.75; // Apply -25% penalty (75% of original income)
                        }
                        // --- End Calculation ---
                        
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              // Use the correctly calculated finalPropertyIncome
                              'Income: \$${NumberFormatter.formatCompact(finalPropertyIncome)}/sec',
                              style: TextStyle(
                                fontSize: 14,
                                // Use isLocaleAffectedByEvent for color
                                color: isLocaleAffectedByEvent ? Colors.red.shade700 : Colors.green.shade700,
                                fontWeight: isLocaleAffectedByEvent ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            // Use isLocaleAffectedByEvent for warning icon
                            if (isLocaleAffectedByEvent)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red,
                                  size: 14,
                                ),
                              ),
                          ],
                        );
                      }),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Price: \$${NumberFormatter.formatCurrency(property.purchasePrice)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: canAfford ? onBuy : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    disabledBackgroundColor: Colors.grey.shade400,
                  ),
                  child: const Text('BUY'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}