import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../models/investment.dart';
import '../screens/investment_detail_screen.dart';

class PortfolioWidget extends StatefulWidget {
  final VoidCallback onClose;

  const PortfolioWidget({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  _PortfolioWidgetState createState() => _PortfolioWidgetState();
}

class _PortfolioWidgetState extends State<PortfolioWidget> {
  String _sortMode = 'Value (High to Low)';
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Portfolio',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            _buildSortDropdown(),
            
            const SizedBox(height: 16),
            
            // Portfolio summary
            _buildPortfolioSummary(),
            
            const SizedBox(height: 16),
            
            // Owned investments list
            Expanded(
              child: _buildOwnedInvestmentsList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: _sortMode,
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(Icons.sort),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _sortMode = newValue;
            });
          }
        },
        items: [
          'Value (High to Low)',
          'Value (Low to High)',
          'Profit/Loss (Best First)',
          'Profit/Loss (Worst First)',
          'Alphabetical',
        ].map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildPortfolioSummary() {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        // Calculate portfolio metrics
        double totalValue = 0.0;
        double totalProfit = 0.0;
        double totalDividends = 0.0;
        
        for (var investment in gameState.investments) {
          if (investment.owned > 0) {
            totalValue += investment.getCurrentValue();
            totalProfit += investment.getProfitLoss();
            if (investment.hasDividends()) {
              totalDividends += investment.getDividendIncomePerSecond();
            }
          }
        }
        
        return Card(
          color: Colors.blue.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Value:',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '\$${totalValue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Profit/Loss:',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '\$${totalProfit.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: totalProfit >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                
                if (totalDividends > 0) ...[
                  const SizedBox(height: 8),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.payments, size: 16, color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          const Text(
                            'Dividend Income:',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '\$${totalDividends.toStringAsFixed(2)}/sec',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 8),
                
                // Diversification bonus
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Diversification Bonus:',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '+${(gameState.calculateDiversificationBonus() * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
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
  
  Widget _buildOwnedInvestmentsList() {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        // Filter to only owned investments
        List<Investment> ownedInvestments = gameState.investments
            .where((investment) => investment.owned > 0)
            .toList();
        
        // Sort based on selected mode
        _sortInvestments(ownedInvestments);
        
        if (ownedInvestments.isEmpty) {
          return const Center(
            child: Text(
              'You don\'t own any investments yet',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          );
        }
        
        return ListView.builder(
          shrinkWrap: true,
          itemCount: ownedInvestments.length,
          itemBuilder: (context, index) {
            Investment investment = ownedInvestments[index];
            double priceChange = investment.getPriceChangePercent();
            
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InvestmentDetailScreen(
                      investment: investment,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    // Investment icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: investment.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        investment.icon,
                        size: 24,
                        color: investment.color,
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Investment details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            investment.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            children: [
                              Text('${investment.owned} shares'),
                              const SizedBox(width: 8),
                              if (investment.hasDividends())
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.payments,
                                      size: 12,
                                      color: Colors.green.shade700,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '\$${investment.getDividendIncomePerSecond().toStringAsFixed(2)}/s',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Price and change
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${investment.getCurrentValue().toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${priceChange >= 0 ? '+' : ''}${priceChange.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: priceChange >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
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
      },
    );
  }
  
  void _sortInvestments(List<Investment> investments) {
    switch (_sortMode) {
      case 'Value (High to Low)':
        investments.sort((a, b) => b.getCurrentValue().compareTo(a.getCurrentValue()));
        break;
      case 'Value (Low to High)':
        investments.sort((a, b) => a.getCurrentValue().compareTo(b.getCurrentValue()));
        break;
      case 'Profit/Loss (Best First)':
        investments.sort((a, b) => b.getProfitLossPercentage().compareTo(a.getProfitLossPercentage()));
        break;
      case 'Profit/Loss (Worst First)':
        investments.sort((a, b) => a.getProfitLossPercentage().compareTo(b.getProfitLossPercentage()));
        break;
      case 'Alphabetical':
        investments.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
  }
}
