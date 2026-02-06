import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../utils/sound_manager.dart';

import '../models/game_state.dart';
import '../models/investment.dart';
import '../utils/number_formatter.dart';

class InvestmentItem extends StatefulWidget {
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
  _InvestmentItemState createState() => _InvestmentItemState();
}

class _InvestmentItemState extends State<InvestmentItem> with SingleTickerProviderStateMixin {
  late AnimationController _buttonController;
  late Animation<double> _buttonScaleAnimation;
  bool _isBuyPressed = false;
  bool _isSellPressed = false;
  
  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _buttonController.dispose();
    super.dispose();
  }
  
  void _handleBuyPressed() {
    SoundManager().playMediumHaptic();
    widget.onBuy();
  }
  
  void _handleSellPressed() {
    SoundManager().playMediumHaptic();
    widget.onSell();
  }
  
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
                          NumberFormatter.formatCurrencyPrecise(investment.currentPrice),
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
                        'Total: ${NumberFormatter.formatCurrencyPrecise(investment.currentPrice * quantity)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),
                
                // Buy and sell buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTapDown: canAfford ? (_) {
                          setState(() {
                            _isBuyPressed = true;
                          });
                          _buttonController.forward();
                        } : null,
                        onTapUp: canAfford ? (_) {
                          setState(() {
                            _isBuyPressed = false;
                          });
                          _buttonController.reverse();
                          _handleBuyPressed();
                        } : null,
                        onTapCancel: canAfford ? () {
                          setState(() {
                            _isBuyPressed = false;
                          });
                          _buttonController.reverse();
                        } : null,
                        child: AnimatedBuilder(
                          animation: _buttonScaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _isBuyPressed ? _buttonScaleAnimation.value : 1.0,
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: canAfford ? Colors.green : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _isBuyPressed && canAfford ? [] : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    'Buy',
                                    style: TextStyle(
                                      color: canAfford ? Colors.white : Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTapDown: canSell ? (_) {
                          setState(() {
                            _isSellPressed = true;
                          });
                          _buttonController.forward();
                        } : null,
                        onTapUp: canSell ? (_) {
                          setState(() {
                            _isSellPressed = false;
                          });
                          _buttonController.reverse();
                          _handleSellPressed();
                        } : null,
                        onTapCancel: canSell ? () {
                          setState(() {
                            _isSellPressed = false;
                          });
                          _buttonController.reverse();
                        } : null,
                        child: AnimatedBuilder(
                          animation: _buttonScaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _isSellPressed ? _buttonScaleAnimation.value : 1.0,
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: canSell ? Colors.red : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _isSellPressed && canSell ? [] : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    'Sell',
                                    style: TextStyle(
                                      color: canSell ? Colors.white : Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
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
    // Enhanced price history visualization with animations
    return Container(
      height: 70,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Text(
              'Price History',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(widget.investment.priceHistory.length, (index) {
                  // Calculate relative height
                  double minPrice = widget.investment.priceHistory.reduce((a, b) => a < b ? a : b);
                  double maxPrice = widget.investment.priceHistory.reduce((a, b) => a > b ? a : b);
                  double range = maxPrice - minPrice;
                  
                  // Prevent division by zero
                  double relativeHeight = range == 0 
                      ? 0.5 
                      : (widget.investment.priceHistory[index] - minPrice) / range;
                  
                  // Determine color based on comparison to previous day
                  Color barColor = Colors.grey;
                  if (index > 0) {
                    barColor = widget.investment.priceHistory[index] >= widget.investment.priceHistory[index - 1]
                        ? Colors.green.shade400
                        : Colors.red.shade400;
                  }
                  
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 800 + (index * 50)),
                        curve: Curves.elasticOut,
                        tween: Tween<double>(
                          begin: 0.0,
                          end: relativeHeight.clamp(0.1, 1.0),
                        ),
                        builder: (context, value, child) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                height: 40 * value,
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(2),
                                    topRight: Radius.circular(2),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: barColor.withOpacity(0.3),
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}