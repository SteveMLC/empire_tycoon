import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../models/game_state.dart';
import '../models/investment.dart';
import '../utils/number_formatter.dart';

class InvestmentItem extends StatelessWidget {
  final Investment investment;
  final int quantity;
  final Function(int) onQuantityChanged;
  final VoidCallback onBuy;
  final VoidCallback onSell;
  
  const InvestmentItem({
    Key? key,
    required this.investment,
    required this.quantity,
    required this.onQuantityChanged,
    required this.onBuy,
    required this.onSell,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        // Check if player can afford this investment
        bool canAfford = gameState.money >= (investment.currentPrice * quantity);
        bool canSell = investment.owned >= quantity;
        
        double priceChange = investment.getPriceChangePercent();
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon, name and price change
                Row(
                  children: [
                    Icon(investment.icon, size: 32, color: investment.color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            investment.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Owned: ${investment.owned}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${investment.currentPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${priceChange >= 0 ? '+' : ''}${priceChange.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: priceChange >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),
                
                // Investment description and category
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        investment.description,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        investment.category,
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),
                
                // Investment forecast
                Row(
                  children: [
                    Text(
                      'Forecast: ',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: investment.getForecastColor().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        investment.getForecastCategory(),
                        style: TextStyle(
                          color: investment.getForecastColor(),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),
                
                // Show dividend yield if applicable
                if (investment.hasDividends()) _buildDividendInfo(),

                // Investment stats
                if (investment.owned > 0) _buildInvestmentStats(),
                
                const SizedBox(height: 15),
                
                // Price history chart (simple visualization)
                _buildPriceHistoryChart(),
                
                const SizedBox(height: 15),
                
                // Quantity selector
                Row(
                  children: [
                    const Text('Quantity:'),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.remove_circle),
                      onPressed: quantity > 1
                          ? () => onQuantityChanged(quantity - 1)
                          : null,
                      color: Colors.blue,
                    ),
                    Container(
                      width: 50,
                      alignment: Alignment.center,
                      child: Text(
                        quantity.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      onPressed: () => onQuantityChanged(quantity + 1),
                      color: Colors.blue,
                    ),
                    Expanded(
                      child: Text(
                        'Total: \$${(investment.currentPrice * quantity).toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),
                
                // Buy and sell buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: canAfford ? onBuy : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Buy'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: canSell ? onSell : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Sell'),
                      ),
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
  
  Widget _buildInvestmentStats() {
    return Column(
      children: [
        // Current value
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Current Value:'),
            Text(
              '\$${investment.getCurrentValue().toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        
        const SizedBox(height: 6),
        
        // Purchase price
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Avg. Purchase Price:'),
            Text(
              '\$${investment.purchasePrice.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        
        const SizedBox(height: 6),
        
        // Profit/Loss
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Profit/Loss:'),
            Text(
              '\$${investment.getProfitLoss().toStringAsFixed(2)} (${investment.getProfitLossPercentage().toStringAsFixed(2)}%)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: investment.getProfitLoss() >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 10),
        const Divider(),
        const SizedBox(height: 5),
      ],
    );
  }
  
  Widget _buildDividendInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dividend info row
        Row(
          children: [
            Icon(Icons.payments, size: 16, color: Colors.green.shade700),
            const SizedBox(width: 5),
            Text(
              'Dividend:',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '\$${investment.dividendPerSecond.toStringAsFixed(2)}/sec',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(ROI ${investment.getROI().toStringAsFixed(2)}%)',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 13,
              ),
            ),
          ],
        ),
        if (investment.owned > 0) 
          Padding(
            padding: const EdgeInsets.only(top: 5.0, left: 21.0),
            child: Text(
              'Income: \$${investment.getDividendIncomePerSecond().toStringAsFixed(2)}/sec',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
        const SizedBox(height: 10),
      ],
    );
  }
  
  Widget _buildPriceHistoryChart() {
    // Simple price history visualization
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: List.generate(investment.priceHistory.length, (index) {
          // Calculate relative height
          double minPrice = investment.priceHistory.reduce((a, b) => a < b ? a : b);
          double maxPrice = investment.priceHistory.reduce((a, b) => a > b ? a : b);
          double range = maxPrice - minPrice;
          
          // Prevent division by zero
          double relativeHeight = range == 0 
              ? 0.5 
              : (investment.priceHistory[index] - minPrice) / range;
          
          // Determine color based on comparison to previous day
          Color barColor = Colors.grey;
          if (index > 0) {
            barColor = investment.priceHistory[index] >= investment.priceHistory[index - 1]
                ? Colors.green
                : Colors.red;
          }
          
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: 40 * relativeHeight.clamp(0.1, 1.0),
                    color: barColor,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}