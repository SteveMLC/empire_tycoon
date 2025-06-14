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
  String _sortMode = 'value';
  
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isCompact = screenHeight < 700; // Detect smaller screens or limited space
    
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: Colors.blue.shade700,
                        size: isCompact ? 20 : 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'My Portfolio',
                        style: TextStyle(
                          fontSize: isCompact ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  _buildSortDropdown(),
                ],
              ),
            ),
            
            // Portfolio Summary
            _buildPortfolioSummary(),
            
            // Investments List - Using Flexible instead of unbounded ListView
            Flexible(
              child: _buildInvestmentsList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSortDropdown() {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: _sortMode,
        isExpanded: true,
        underline: const SizedBox(),
        icon: Icon(Icons.sort, color: Colors.blue.shade700, size: 16),
        style: TextStyle(
          color: Colors.grey.shade800,
          fontSize: 12,
        ),
        items: const [
          DropdownMenuItem(value: 'value', child: Text('Value')),
          DropdownMenuItem(value: 'profit', child: Text('P&L')),
          DropdownMenuItem(value: 'name', child: Text('Name')),
        ],
        onChanged: (value) {
          setState(() {
            _sortMode = value!;
          });
        },
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
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.blue.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              // Primary metrics row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Total Portfolio Value
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Value',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${totalValue.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  
                  // Total P&L
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total P&L',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            totalProfit >= 0 ? Icons.trending_up : Icons.trending_down,
                            size: 16,
                            color: totalProfit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${totalProfit >= 0 ? '+' : ''}\$${totalProfit.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: totalProfit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              
              // Secondary metrics row
              if (totalDividends > 0) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 14,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Dividends: \$${totalDividends.toStringAsFixed(2)}/s',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildInvestmentsList() {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        List<Investment> ownedInvestments = gameState.investments
            .where((investment) => investment.owned > 0)
            .toList();

        // Sort investments
        _sortInvestments(ownedInvestments);

        if (ownedInvestments.isEmpty) {
          return SizedBox(
            height: 200, // Fixed height for empty state
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Investments Yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start building your portfolio by\npurchasing some investments!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
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
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade100,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header Row
                    Row(
                      children: [
                        // Investment Icon & Name
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: investment.category == 'Stock' 
                                      ? Colors.blue.shade50
                                      : investment.category == 'Bond'
                                          ? Colors.green.shade50
                                          : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  investment.category == 'Stock' 
                                      ? Icons.trending_up
                                      : investment.category == 'Bond'
                                          ? Icons.account_balance
                                          : Icons.business,
                                  color: investment.category == 'Stock' 
                                      ? Colors.blue.shade600
                                      : investment.category == 'Bond'
                                          ? Colors.green.shade600
                                          : Colors.orange.shade600,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      investment.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '${investment.owned} shares',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        if (investment.hasDividends()) ...[
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade100,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.attach_money,
                                                    size: 10,
                                                    color: Colors.green.shade700,
                                                  ),
                                                  Text(
                                                    'DIV',
                                                    style: TextStyle(
                                                      fontSize: 8,
                                                      color: Colors.green.shade700,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Total Value
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${investment.getCurrentValue().toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '\$${investment.currentPrice.toStringAsFixed(2)}/share',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Performance Section
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          // Purchase info row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Avg. cost: \$${investment.purchasePrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                'Total invested: \$${(investment.purchasePrice * investment.owned).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // P&L and Market Performance Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Your P&L (Most Important)
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: investment.getProfitLoss() >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: investment.getProfitLoss() >= 0 ? Colors.green.shade200 : Colors.red.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Your P&L',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            investment.getProfitLoss() >= 0 ? Icons.trending_up : Icons.trending_down,
                                            size: 12,
                                            color: investment.getProfitLoss() >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            '\$${investment.getProfitLoss().toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: investment.getProfitLoss() >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${investment.getProfitLoss() >= 0 ? '+' : ''}${investment.getProfitLossPercentage().toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: investment.getProfitLoss() >= 0 ? Colors.green.shade600 : Colors.red.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              const SizedBox(width: 12),
                              
                              // Market Performance (Secondary)
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Market Today',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            priceChange >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                                            size: 10,
                                            color: priceChange >= 0 ? Colors.green.shade600 : Colors.red.shade600,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${priceChange >= 0 ? '+' : ''}${priceChange.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: priceChange >= 0 ? Colors.green.shade600 : Colors.red.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'vs. yesterday',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
      case 'value':
        investments.sort((a, b) => b.getCurrentValue().compareTo(a.getCurrentValue()));
        break;
      case 'profit':
        investments.sort((a, b) => b.getProfitLoss().compareTo(a.getProfitLoss()));
        break;
      case 'name':
        investments.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
  }
}
