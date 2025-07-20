import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';

import '../models/game_state.dart';
import '../models/investment.dart';
import '../models/investment_holding.dart';
import '../services/game_service.dart';
import '../utils/number_formatter.dart';
import '../utils/sounds.dart';
import '../widgets/investment_chart.dart';
import '../utils/asset_loader.dart';
import '../utils/sound_assets.dart';

String formatCurrency(double value) {
  return NumberFormatter.formatCurrency(value);
}

String formatInt(int value) {
  return NumberFormatter.formatInt(value);
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
  late TextEditingController _quantityController;
  int _maxAffordable = 0;
  bool _isBuying = true;
  
  int get maxAffordable => _maxAffordable;
  
  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: _quantity.toString());
  }
  
  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }
  
  void _updateQuantityController() {
    if (_quantityController.text != _quantity.toString()) {
      _quantityController.text = _quantity.toString();
      _quantityController.selection = TextSelection.fromPosition(
        TextPosition(offset: _quantityController.text.length),
      );
    }
  }
  
  void _setMaxQuantity() {
    if (_isBuying) {
      if (_maxAffordable > 0) {
        setState(() {
          _quantity = _maxAffordable;
          _updateQuantityController();
        });
      }
    } else {
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
    final theme = Theme.of(context);
    
    final double totalCost = investment.currentPrice * _quantity;
    final bool canAfford = gameState.money >= totalCost;
    
    // Calculate max affordable considering cash and available shares
    int maxAffordableByCash = (investment.currentPrice > 0) 
        ? (gameState.money / investment.currentPrice).floor()
        : 0;
    int maxAffordableByShares = investment.availableShares;
    _maxAffordable = min(maxAffordableByCash, maxAffordableByShares);
    if (_maxAffordable < 0) _maxAffordable = 0;
    
    final int ownedShares = investment.owned;
    final double purchasedValue = investment.purchasePrice * ownedShares;
    final double currentValue = investment.currentPrice * ownedShares;
    final double profitLoss = currentValue - purchasedValue;
    final double profitPercentage = purchasedValue > 0 
      ? (profitLoss / purchasedValue) * 100 
      : 0.0;
    
    final Color performanceColor = profitLoss >= 0 ? Colors.green : Colors.red;
    final Color priceChangeColor = investment.getPriceChangePercent() >= 0 ? Colors.green : Colors.red;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          investment.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Quick Action Bar - Buy/Sell buttons at top
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Buy',
                    Colors.green,
                    Icons.trending_up,
                    _isBuying,
                    () => setState(() => _isBuying = true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Sell',
                    Colors.red,
                    Icons.trending_down,
                    !_isBuying,
                    () => setState(() => _isBuying = false),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price Header Card
                  _buildPriceHeaderCard(investment, priceChangeColor),
                  
                  const SizedBox(height: 16),
                  
                  // Enhanced Chart Card
                  _buildEnhancedChartCard(investment),
                  
                  const SizedBox(height: 16),
                  
                  // Holdings & P&L Card (if user owns shares)
                  if (ownedShares > 0) ..[
                    _buildHoldingsCard(ownedShares, purchasedValue, currentValue, profitLoss, profitPercentage, performanceColor),
                    const SizedBox(height: 16),
                  ],
                  
                  // Trading Card
                  _buildTradingCard(gameState, investment, totalCost, canAfford),
                  
                  const SizedBox(height: 16),
                  
                  // Investment Stats Grid
                  _buildStatsGrid(investment),
                  
                  const SizedBox(height: 16),
                  
                  // Forecast Card
                  _buildForecastCard(investment),
                  
                  const SizedBox(height: 16),
                  
                  // About Card
                  _buildAboutCard(investment),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton(
    BuildContext context,
    String label,
    Color color,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPriceHeaderCard(Investment investment, Color priceChangeColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              investment.color.withOpacity(0.1),
              investment.color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: investment.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    investment.icon,
                    color: investment.color,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        investment.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: investment.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          investment.category,
                          style: TextStyle(
                            color: investment.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Current Price Display
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCurrency(investment.currentPrice),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: priceChangeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: priceChangeColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        investment.getPriceChangePercent() >= 0 
                          ? Icons.trending_up 
                          : Icons.trending_down,
                        color: priceChangeColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${investment.getPriceChangePercent() >= 0 ? '+' : ''}${investment.getPriceChangePercent().toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: priceChangeColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEnhancedChartCard(Investment investment) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 280,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Price Chart',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${investment.priceHistory.length} points',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: investment.priceHistory.length > 1
                ? InvestmentChart(
                    priceHistory: investment.priceHistory,
                    changePercent: investment.getPriceChangePercent(),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.show_chart,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Building price history...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHoldingsCard(int ownedShares, double purchasedValue, double currentValue, double profitLoss, double profitPercentage, Color performanceColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              performanceColor.withOpacity(0.05),
              performanceColor.withOpacity(0.02),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: performanceColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Your Holdings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildHoldingsStat('Shares Owned', formatInt(ownedShares), Icons.pie_chart),
                ),
                Expanded(
                  child: _buildHoldingsStat('Avg. Price', formatCurrency(widget.investment.purchasePrice), Icons.attach_money),
                ),
                Expanded(
                  child: _buildHoldingsStat('Current Value', formatCurrency(currentValue), Icons.account_balance),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: performanceColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: performanceColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total P&L',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${profitLoss >= 0 ? '+' : ''}${formatCurrency(profitLoss)}',
                        style: TextStyle(
                          color: performanceColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: performanceColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${profitPercentage >= 0 ? '+' : ''}${profitPercentage.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: performanceColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
  
  Widget _buildHoldingsStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.blue[700],
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildTradingCard(GameState gameState, Investment investment, double totalCost, bool canAfford) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isBuying ? Icons.shopping_cart : Icons.sell,
                  color: _isBuying ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  _isBuying ? 'Buy Shares' : 'Sell Shares',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Quantity Input
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantity',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                        child: TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          onChanged: (value) {
                            final newQuantity = int.tryParse(value) ?? 1;
                            setState(() {
                              _quantity = newQuantity;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _setMaxQuantity,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'MAX',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Cost Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Cost:',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        formatCurrency(totalCost),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Available Cash:',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        formatCurrency(gameState.money),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: canAfford ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Execute Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isBuying && canAfford && _quantity > 0 && _quantity <= _maxAffordable) ||
                          (!_isBuying && _quantity > 0 && _quantity <= investment.owned)
                    ? () async {
                        final gameService = Provider.of<GameService>(context, listen: false);
                        
                        if (_isBuying) {
                          await gameService.buyInvestment(investment.id, _quantity);
                          gameService.soundService.playSound(SoundAssets.buy);
                        } else {
                          await gameService.sellInvestment(investment.id, _quantity);
                          gameService.soundService.playSound(SoundAssets.sell);
                        }
                        
                        HapticFeedback.lightImpact();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isBuying ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
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
    );
  }
  
  Widget _buildStatsGrid(Investment investment) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Investment Stats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatItem('Risk Level', investment.riskLevel, Icons.warning_amber, _getRiskColor(investment.riskLevel)),
                _buildStatItem('Market Cap', '\$${investment.marketCap.toStringAsFixed(1)}B', Icons.business, Colors.blue),
                _buildStatItem('Volume', formatInt(investment.getDailyVolume().toInt()), Icons.bar_chart, Colors.purple),
                _buildStatItem('Available', formatInt(investment.availableShares), Icons.inventory, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  Widget _buildAboutCard(Investment investment) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[700],
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'About This Investment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Text(
              investment.description,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
                      
                      SizedBox(
                        height: 180,
                        child: InvestmentChart(
                          priceHistory: investment.priceHistory,
                          changePercent: investment.priceChangePercent,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
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
                            'Max Shares',
                            formatInt(investment.maxShares),
                            icon: Icons.inventory_2_outlined,
                          ),
                          _buildDataItem(
                            'Volume',
                            formatCurrency(investment.getDailyVolume()),
                            icon: Icons.bar_chart,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildForecastCard(investment),
                          ),
                        ],
                      ),
                      
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
              
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                                  final gameService = Provider.of<GameService>(context, listen: false);
                                  final gameState = Provider.of<GameState>(context, listen: false);
                                  bool success = false;
                                  
                                  if (_isBuying) {
                                    success = gameState.buyInvestment(investment.id, _quantity);
                                  } else {
                                    success = gameState.sellInvestment(investment.id, _quantity);
                                  }
                                  
                                  if (success) {
                                    if (_isBuying) {
                                      try {
                                        // Preload sound first
                                        final assetLoader = AssetLoader();
                                        unawaited(assetLoader.preloadSound(SoundAssets.investmentBuyStock));
                                        // Play sound through GameService for better error handling
                                        gameService.playSound(() => gameService.soundManager.playInvestmentBuyStockSound());
                                      } catch (e) {
                                        // Only log investment sound errors occasionally to reduce spam
                                        if (DateTime.now().second % 30 == 0) {
                                          print("Error playing investment buy sound: $e");
                                        }
                                        // Continue with the purchase process even if sound fails
                                      }
                                    } else {
                                      try {
                                        // Preload sound first
                                        final assetLoader = AssetLoader();
                                        unawaited(assetLoader.preloadSound(SoundAssets.investmentSellStock));
                                        // Play sound directly through sound manager for better error handling
                                        gameService.playSound(() => gameService.soundManager.playInvestmentSellStockSound());
                                      } catch (e) {
                                        // Only log investment sound errors occasionally to reduce spam
                                        if (DateTime.now().second % 30 == 0) {
                                          print("Error playing investment sell sound: $e");
                                        }
                                        // Continue with the sell process even if sound fails
                                      }
                                    }
                                    
                                    if (!mounted) return; 

                                    // scaffoldMessenger.showSnackBar(
                                    //   SnackBar(
                                    //     content: Text(
                                    //       _isBuying
                                    //           ? 'Successfully purchased $_quantity shares of ${investment.name}'
                                    //           : 'Successfully sold $_quantity shares of ${investment.name}',
                                    //     ),
                                    //     backgroundColor: _isBuying ? Colors.green : Colors.blue,
                                    //   ),
                                    // );
                                    
                                    if (!mounted) return; 
                                    setState(() {
                                      _quantity = 1;
                                      _updateQuantityController();
                                    });
                                  } else {
                                    try {
                                      // Preload sound first
                                      final assetLoader = AssetLoader();
                                      unawaited(assetLoader.preloadSound(SoundAssets.feedbackError));
                                      // Play sound directly through sound manager for better error handling
                                      // Use generic playSound for error
                                      gameService.soundManager.playSound(SoundAssets.feedbackError, priority: SoundPriority.normal);
                                    } catch (e) {
                                      // Only log error sound errors occasionally to reduce spam
                                      if (DateTime.now().second % 30 == 0) {
                                        print("Error playing error sound: $e");
                                      }
                                      // Continue with the error handling even if sound fails
                                    }
                                    
                                    if (!mounted) return;

                                    // scaffoldMessenger.showSnackBar(
                                    //   SnackBar(
                                    //     content: Text(
                                    //       _isBuying
                                    //           ? 'Failed to purchase shares!'
                                    //           : 'Failed to sell shares!',
                                    //     ),
                                    //     backgroundColor: Colors.red,
                                    //   ),
                                    // );
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
  

  
  Widget _buildForecastCard(Investment investment) {
    final String forecastCategory = investment.getForecastCategory();
    final Color forecastColor = investment.getForecastColor();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              forecastColor.withOpacity(0.1),
              forecastColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: forecastColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getForecastIcon(forecastCategory),
                color: forecastColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expert Forecast',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    forecastCategory,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: forecastColor,
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