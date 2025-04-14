import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../models/game_state.dart';
import '../models/investment.dart';
import '../models/investment_holding.dart';
import '../services/game_service.dart';
import '../utils/number_formatter.dart';
import '../utils/sounds.dart';  // Import GameSounds
import '../widgets/investment_chart.dart';

// Helper function to format currency using the NumberFormatter
String formatCurrency(double value) {
  return NumberFormatter.formatCurrency(value);
}

class InvestmentDetailScreen extends StatefulWidget {
  final Investment investment;

  const InvestmentDetailScreen({
    Key? key,
    required this.investment,
  }) : super(key: key);

  @override
  _InvestmentDetailScreenState createState() => _InvestmentDetailScreenState();
}

class _InvestmentDetailScreenState extends State<InvestmentDetailScreen> {
  int _quantity = 1;
  // Create a TextEditingController to manage the input field
  late TextEditingController _quantityController;
  // Track maximum affordable quantity at the class level
  int _maxAffordable = 0;
  // Track whether we're buying or selling
  bool _isBuying = true;
  
  // Getter for maxAffordable to fix references in the code
  int get maxAffordable => _maxAffordable;
  
  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: _quantity.toString());
    // Get the game state from the provider
    final gameState = Provider.of<GameState>(context, listen: false);
    // Force a rebuild when the game state updates (like price changes)
    gameState.addListener(_onGameStateUpdate);
  }
  
  @override
  void dispose() {
    // Clean up listener when widget is disposed
    final gameState = Provider.of<GameState>(context, listen: false);
    gameState.removeListener(_onGameStateUpdate);
    _quantityController.dispose();
    super.dispose();
  }
  
  // This will be called when game state updates
  void _onGameStateUpdate() {
    if (mounted) {
      setState(() {}); // Trigger a rebuild of the widget
    }
  }
  
  // Update the text controller when quantity changes
  void _updateQuantityController() {
    // Only update if the value has actually changed
    if (_quantityController.text != _quantity.toString()) {
      _quantityController.text = _quantity.toString();
      // Move cursor to the end of the text
      _quantityController.selection = TextSelection.fromPosition(
        TextPosition(offset: _quantityController.text.length),
      );
    }
  }
  
  // Method to set quantity to maximum affordable amount or owned amount
  void _setMaxQuantity() {
    if (_isBuying) {
      if (_maxAffordable > 0) {
        setState(() {
          _quantity = _maxAffordable;
          _updateQuantityController();
        });
      }
    } else {
      // If selling, set to max owned
      final ownedShares = widget.investment.owned;
      if (ownedShares > 0) {
        setState(() {
          _quantity = ownedShares;
          _updateQuantityController();
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final investment = widget.investment;
    
    // Calculate the current affordable quantity based on player funds
    final double totalCost = investment.currentPrice * _quantity;
    final bool canAfford = gameState.money >= totalCost;
    
    // Calculate how many shares the player can afford
    _maxAffordable = (gameState.money / investment.currentPrice).floor();
    
    // Get player's owned shares
    final int ownedShares = investment.owned;
    
    // Calculate the potential profit
    final double purchasedValue = investment.purchasePrice * ownedShares;
    final double currentValue = investment.currentPrice * ownedShares;
    final double profitLoss = currentValue - purchasedValue;
    final double profitPercentage = purchasedValue > 0 
      ? (profitLoss / purchasedValue) * 100 
      : 0.0;
    
    // Calculate color based on performance
    final Color performanceColor = profitLoss >= 0 ? Colors.green : Colors.red;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(investment.name),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Market Card with Current Price and Chart
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Company Name and Icon
                      Row(
                        children: [
                          Icon(
                            investment.icon,
                            color: investment.color,
                            size: 32,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  investment.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  investment.category,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Current Price and Change
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Current Price',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                formatCurrency(investment.currentPrice),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: investment.priceChangePercent >= 0
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  investment.priceChangePercent >= 0
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: investment.priceChangePercent >= 0
                                      ? Colors.green
                                      : Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${investment.priceChangePercent.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color: investment.priceChangePercent >= 0
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Price Chart
                      SizedBox(
                        height: 180,
                        child: InvestmentChart(
                          priceHistory: investment.priceHistory,
                          changePercent: investment.priceChangePercent,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Market Data
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDataItem(
                            'Risk',
                            investment.riskLevel,
                            icon: Icons.warning_outlined,
                          ),
                          _buildDataItem(
                            'Market Cap',
                            '\$${investment.marketCap.toStringAsFixed(2)}B',
                            icon: Icons.pie_chart_outline,
                          ),
                          _buildDataItem(
                            'Volume',
                            formatCurrency(investment.getDailyVolume()),
                            icon: Icons.bar_chart,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Investment Forecast
                      Row(
                        children: [
                          Expanded(
                            child: _buildForecastCard(investment),
                          ),
                        ],
                      ),
                      
                      // Dividend info - always show if this investment has dividends
                      if (investment.hasDividends()) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.payments,
                                color: Colors.green.shade700,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Dividend Information',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Yield: ${investment.getDividendYield().toStringAsFixed(2)}% • Income: \$${investment.dividendPerSecond.toStringAsFixed(2)}/sec per share',
                                      style: TextStyle(
                                        color: Colors.grey.shade800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Your Holdings Card
              if (ownedShares > 0)
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Holdings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildDataItem(
                              'Owned',
                              '$ownedShares Shares',
                              icon: Icons.account_balance_wallet_outlined,
                            ),
                            _buildDataItem(
                              'Avg. Price',
                              formatCurrency(investment.purchasePrice),
                              icon: Icons.attach_money,
                            ),
                            _buildDataItem(
                              'Current Value',
                              formatCurrency(currentValue),
                              icon: Icons.monetization_on_outlined,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Profit/Loss Banner
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: performanceColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Profit/Loss',
                                style: TextStyle(
                                  color: performanceColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    formatCurrency(profitLoss),
                                    style: TextStyle(
                                      color: performanceColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${profitPercentage.toStringAsFixed(2)}%)',
                                    style: TextStyle(
                                      color: performanceColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Dividend Info if applicable
                        if (investment.hasDividends())
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Dividend Information',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildDataItem(
                                      'Yield',
                                      '${investment.getDividendYield().toStringAsFixed(2)}%',
                                      icon: Icons.trending_up,
                                    ),
                                    _buildDataItem(
                                      'Income/sec',
                                      formatCurrency(investment.getDividendIncomePerSecond()),
                                      icon: Icons.access_time,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Buy/Sell Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Buy/Sell Toggle
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isBuying ? Colors.blue : Colors.grey[300],
                                foregroundColor: _isBuying ? Colors.white : Colors.black,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isBuying = true;
                                  _quantity = 1;
                                  _updateQuantityController();
                                });
                              },
                              child: const Text('Buy'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: !_isBuying ? Colors.blue : Colors.grey[300],
                                foregroundColor: !_isBuying ? Colors.white : Colors.black,
                              ),
                              onPressed: ownedShares > 0
                                  ? () {
                                      setState(() {
                                        _isBuying = false;
                                        _quantity = 1;
                                        _updateQuantityController();
                                      });
                                    }
                                  : null,
                              child: const Text('Sell'),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Quantity Row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Quantity',
                                border: OutlineInputBorder(),
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _quantity = int.tryParse(value) ?? 1;
                                  if (_quantity < 1) _quantity = 1;
                                  if (_isBuying && _quantity > _maxAffordable) {
                                    _quantity = _maxAffordable > 0 ? _maxAffordable : 1;
                                    _updateQuantityController();
                                  } else if (!_isBuying && _quantity > ownedShares) {
                                    _quantity = ownedShares > 0 ? ownedShares : 1;
                                    _updateQuantityController();
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _setMaxQuantity,
                            child: const Text('MAX'),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Total Cost/Proceeds
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isBuying ? 'Total Cost:' : 'Total Proceeds:',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            formatCurrency(totalCost),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Current Cash Available
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Available Cash:'),
                          Text(formatCurrency(gameState.money)),
                        ],
                      ),
                      
                      if (_isBuying && !canAfford && _quantity > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'You cannot afford this purchase!',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Buy/Sell Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isBuying ? Colors.green : Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: (_isBuying && canAfford && _quantity > 0) ||
                                  (!_isBuying && ownedShares >= _quantity && _quantity > 0)
                              ? () {
                                  final gameService = Provider.of<GameService>(context, listen: false);
                                  bool success = false;
                                  
                                  if (_isBuying) {
                                    success = gameState.buyInvestment(investment.id, _quantity);
                                  } else {
                                    success = gameState.sellInvestment(investment.id, _quantity);
                                  }
                                  
                                  if (success) {
                                    // Play the appropriate investment sound effects
                                    if (_isBuying) {
                                      gameService.playSound(GameSounds.investmentBuyStock);
                                    } else {
                                      gameService.playSound(GameSounds.investmentSellStock);
                                    }
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          _isBuying
                                              ? 'Successfully purchased $_quantity shares of ${investment.name}'
                                              : 'Successfully sold $_quantity shares of ${investment.name}',
                                        ),
                                        backgroundColor: _isBuying ? Colors.green : Colors.blue,
                                      ),
                                    );
                                    
                                    setState(() {
                                      _quantity = 1;
                                      _updateQuantityController();
                                    });
                                  } else {
                                    // Play error sound
                                    gameService.playSound(GameSounds.error);
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          _isBuying
                                              ? 'Failed to purchase shares!'
                                              : 'Failed to sell shares!',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              : null,
                          child: Text(
                            _isBuying
                                ? 'Buy $_quantity Shares'
                                : 'Sell $_quantity Shares',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // About This Investment
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'About This Investment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        investment.description,
                        style: TextStyle(
                          color: Colors.grey[800],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDataItem(String label, String value, {required IconData icon}) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.blue[700],
          size: 18,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildForecastCard(Investment investment) {
    final String forecastCategory = investment.getForecastCategory();
    final Color forecastColor = investment.getForecastColor();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: forecastColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: forecastColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getForecastIcon(forecastCategory),
            color: forecastColor,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expert Forecast',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  forecastCategory,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: forecastColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getForecastIcon(String category) {
    switch (category) {
      case 'Strong Buy':
        return Icons.trending_up;
      case 'Buy':
        return Icons.arrow_upward;
      case 'Hold':
        return Icons.remove;
      case 'Sell':
        return Icons.arrow_downward;
      case 'Strong Sell':
        return Icons.trending_down;
      default:
        return Icons.help_outline;
    }
  }
}
