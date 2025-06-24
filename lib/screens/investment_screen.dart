import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../models/investment.dart';
import '../screens/investment_detail_screen.dart';
import '../screens/investment_portfolio_screen.dart';
import '../widgets/investment_list_item.dart';
import '../widgets/market_overview_widget.dart';

class InvestmentScreen extends StatefulWidget {
  const InvestmentScreen({Key? key}) : super(key: key);

  @override
  _InvestmentScreenState createState() => _InvestmentScreenState();
}

class _InvestmentScreenState extends State<InvestmentScreen> {
  // Sort options for investments
  final List<String> _sortOptions = [
    'Default',
    'Price (Low to High)',
    'Price (High to Low)',
    'Volatility (Low to High)',
    'Volatility (High to Low)',
    'Performance (Best First)',
    'Dividend Yield (High to Low)',
  ];
  
  String _currentSort = 'Default';
  String _selectedCategory = 'All Categories';

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        // Get list of investments and sort based on selection
        List<Investment> investments = _getSortedInvestments(gameState.investments);
        
        return Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Market overview widget (new compact design)
              MarketOverviewWidget(
                investments: gameState.investments,
                onOpenPortfolio: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InvestmentPortfolioScreen(),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 10),
              
              // Filter controls row
              _buildFilterControls(gameState),
              
              const SizedBox(height: 8),
              
              // Investments list
              Expanded(
                child: _buildInvestmentsList(investments),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildFilterControls(GameState gameState) {
    // Get all unique categories from investments plus special options
    List<String> categories = ['All Categories', 'Owned Only', 'Dividend Investments'];
    
    // Add unique categories
    for (var investment in gameState.investments) {
      if (!categories.contains(investment.category)) {
        categories.add(investment.category);
      }
    }
    
    return Row(
      children: [
        // Category filter dropdown
        Expanded(
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.filter_list, size: 20),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
              items: categories.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Sort dropdown
        Expanded(
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _currentSort,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.sort, size: 20),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _currentSort = newValue;
                  });
                }
              },
              items: _sortOptions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildInvestmentsList(List<Investment> investments) {
    if (investments.isEmpty) {
      return const Center(
        child: Text(
          'No investments match the current filters',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80.0),
        itemCount: investments.length,
        itemBuilder: (context, index) {
          Investment investment = investments[index];
          
          return InvestmentListItem(
            investment: investment,
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
          );
        },
      ),
    );
  }
  
  List<Investment> _getSortedInvestments(List<Investment> investments) {
    // Create a copy of the list to avoid modifying the original
    List<Investment> filtered = List.from(investments);
    
    // Apply category filter if not "All Categories"
    if (_selectedCategory != 'All Categories') {
      if (_selectedCategory == 'Owned Only') {
        // Filter to only show investments the player owns
        filtered = filtered.where((investment) => investment.owned > 0).toList();
      } else if (_selectedCategory == 'Dividend Investments') {
        // Filter to only show investments with dividends
        filtered = filtered.where((investment) => investment.hasDividends()).toList();
      } else {
        // Normal category filtering
        filtered = filtered.where((investment) => 
          investment.category == _selectedCategory
        ).toList();
      }
    }
    
    // Sort the filtered list
    switch (_currentSort) {
      case 'Price (Low to High)':
        filtered.sort((a, b) => a.currentPrice.compareTo(b.currentPrice));
        break;
      case 'Price (High to Low)':
        filtered.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
        break;
      case 'Volatility (Low to High)':
        filtered.sort((a, b) => a.volatility.compareTo(b.volatility));
        break;
      case 'Volatility (High to Low)':
        filtered.sort((a, b) => b.volatility.compareTo(a.volatility));
        break;
      case 'Performance (Best First)':
        filtered.sort((a, b) => b.getPriceChangePercent().compareTo(a.getPriceChangePercent()));
        break;
      case 'Dividend Yield (High to Low)':
        filtered.sort((a, b) => b.getDividendYield().compareTo(a.getDividendYield()));
        break;
      default:
        // Default is the original order
        break;
    }
    
    return filtered;
  }
}
