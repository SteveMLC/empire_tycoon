import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../models/investment.dart';
import '../models/market_event.dart';
import '../widgets/portfolio_widget.dart';

class MarketOverviewWidget extends StatelessWidget {
  final List<Investment> investments;
  final VoidCallback onOpenPortfolio;

  const MarketOverviewWidget({
    Key? key,
    required this.investments,
    required this.onOpenPortfolio,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        // Count owned investments and total portfolio value
        double totalValue = 0.0;
        int ownedCount = 0;
        
        for (var investment in investments) {
          if (investment.owned > 0) {
            totalValue += investment.getCurrentValue();
            ownedCount++;
          }
        }
        
        // Count active market events
        bool hasMarketEvents = gameState.activeMarketEvents.isNotEmpty;
        
        return Card(
          color: Colors.white,
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Events indicator (if any)
                if (hasMarketEvents)
                  Align(
                    alignment: Alignment.topRight,
                    child: InkWell(
                      onTap: () => _showMarketEventsInfoDialog(context, gameState),
                      child: Tooltip(
                        message: gameState.activeMarketEvents.map((e) => e.name ?? 'Unknown Event').join(', '),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.purple,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Events',
                                style: TextStyle(
                                  color: Colors.purple.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.info_outline,
                                color: Colors.purple.shade700,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 4),
                
                // Portfolio button
                InkWell(
                  onTap: onOpenPortfolio,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Portfolio: $ownedCount ${ownedCount == 1 ? 'asset' : 'assets'}',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              '\$${totalValue.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.blue.shade700,
                              size: 14,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Diversification bonus and dividend row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Diversification bonus
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.diversity_3,
                            size: 14,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(gameState.calculateDiversificationBonus() * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          // Info button for diversification bonus
                          IconButton(
                            icon: Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(), // Remove default padding
                            tooltip: 'Learn about Diversification Bonus',
                            onPressed: () {
                              _showDiversificationInfoDialog(context, gameState);
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // Total dividend income (if any)
                    Builder(
                      builder: (context) {
                        double totalDividends = 0.0;
                        for (var investment in investments) {
                          if (investment.owned > 0 && investment.hasDividends()) {
                            totalDividends += investment.getDividendIncomePerSecond();
                          }
                        }
                        
                        if (totalDividends > 0) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.payments,
                                  size: 14,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '\$${totalDividends.toStringAsFixed(2)}/sec',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Helper function to show the diversification info dialog
void _showDiversificationInfoDialog(BuildContext context, GameState gameState) {
  // Get the current bonus percentage
  double bonusPercentage = gameState.calculateDiversificationBonus() * 100;
  // Get the number of unique categories owned
  Set<String> ownedCategories = gameState.investments
      .where((investment) => investment.owned > 0)
      .map((investment) => investment.category)
      .toSet();
  int categoryCount = ownedCategories.length;

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Diversification Bonus'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              const Text(
                'You receive a bonus to your total dividend income based on the number of unique investment categories you own.',
              ),
              const SizedBox(height: 10),
              Text(
                'Bonus: +2% per unique category owned.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'You currently own investments in $categoryCount unique categor${categoryCount == 1 ? 'y' : 'ies'}.',
              ),
              const SizedBox(height: 5),
              Text(
                'Current Bonus: +${bonusPercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Got it!'),
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Close the dialog
            },
          ),
        ],
      );
    },
  );
}

// Helper function to show the market events info dialog
void _showMarketEventsInfoDialog(BuildContext context, GameState gameState) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Active Market Events'),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              const Text(
                'Market events affect investment prices based on their category. Here are the currently active events:',
              ),
              const SizedBox(height: 15),
              ...gameState.activeMarketEvents.map((event) => _buildEventInfoWidget(event)).toList(),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Got it!'),
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Close the dialog
            },
          ),
        ],
      );
    },
  );
}

// Helper function to build individual event info widgets
Widget _buildEventInfoWidget(MarketEvent event) {
  // Determine color based on whether the event is positive or negative
  Color eventColor = Colors.blue;
  IconData eventIcon = Icons.info_outline;
  
  // Check the first impact value to determine if it's positive or negative
  if (event.categoryImpacts.isNotEmpty) {
    double firstImpact = event.categoryImpacts.values.first;
    if (firstImpact > 1.0) {
      eventColor = Colors.green;
      eventIcon = Icons.trending_up;
    } else if (firstImpact < 1.0) {
      eventColor = Colors.red;
      eventIcon = Icons.trending_down;
    } else {
      eventColor = Colors.amber;
      eventIcon = Icons.swap_vert;
    }
  }
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(eventIcon, color: eventColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              event.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: eventColor,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            '${event.remainingDays} day${event.remainingDays != 1 ? 's' : ''} left',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      Padding(
        padding: const EdgeInsets.only(left: 28),
        child: Text(event.description),
      ),
      const SizedBox(height: 5),
      Padding(
        padding: const EdgeInsets.only(left: 28),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: event.categoryImpacts.entries.map((entry) {
            final category = entry.key;
            final impact = entry.value;
            final isPositive = impact > 1.0;
            final percentChange = ((impact - 1.0) * 100).abs().toStringAsFixed(1);
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPositive ? Colors.green.shade200 : Colors.red.shade200,
                ),
              ),
              child: Text(
                '$category: ${isPositive ? '+' : '-'}$percentChange%',
                style: TextStyle(
                  color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 15),
    ],
  );
}
