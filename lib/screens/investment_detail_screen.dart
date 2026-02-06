import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:math'; // Import math for min function
import 'dart:async';

import '../models/game_state.dart';
import '../models/investment.dart';
import '../services/game_service.dart';
import '../utils/number_formatter.dart';
import '../utils/sounds.dart';
import '../widgets/investment_chart.dart';
import '../utils/asset_loader.dart';

String formatCurrency(double value) {
  return NumberFormatter.formatCurrencyPrecise(value);
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
    
    final double totalCost = investment.currentPrice * _quantity;
    final bool canAfford = gameState.money >= totalCost;
    
    // Calculate max affordable considering cash and available shares
    int maxAffordableByCash = (investment.currentPrice > 0) 
        ? (gameState.money / investment.currentPrice).floor()
        : 0;
    int maxAffordableByShares = investment.availableShares; // Use the new getter
    _maxAffordable = min(maxAffordableByCash, maxAffordableByShares);
    if (_maxAffordable < 0) _maxAffordable = 0; // Ensure it's not negative
    
    final int ownedShares = investment.owned;
    
    final double purchasedValue = investment.purchasePrice * ownedShares;
    final double currentValue = investment.currentPrice * ownedShares;
    final double profitLoss = currentValue - purchasedValue;
    final double profitPercentage = purchasedValue > 0 
      ? (profitLoss / purchasedValue) * 100 
      : 0.0;
    
    final Color performanceColor = profitLoss >= 0 ? Colors.green : Colors.red;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(investment.name),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      
                      const SizedBox(height: 12),
                      
                      SizedBox(
                        height: 140,
                        child: InvestmentChart(
                          priceHistory: _getDisplayPriceHistory(investment),
                          changePercent: investment.priceChangePercent,
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildCompactStat('Risk', investment.riskLevel),
                          _buildCompactStat('Mkt Cap', NumberFormatter.formatLargeNumber(investment.marketCap * 1000000000)),
                          _buildCompactStat('Shares', _formatCompactInt(investment.maxShares)),
                          _buildCompactStat('Vol', NumberFormatter.formatLargeNumber(investment.getDailyVolume())),
                        ],
                      ),
                      
                      const SizedBox(height: 10),
                      
                      _buildCompactForecast(investment),
                      
                      if (investment.hasDividends()) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.payments, color: Colors.green.shade700, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Yield: ${investment.getDividendYield().toStringAsFixed(2)}% • \$${investment.dividendPerSecond.toStringAsFixed(2)}/sec/share',
                                  style: TextStyle(color: Colors.green.shade800, fontSize: 12, fontWeight: FontWeight.w500),
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
              
              const SizedBox(height: 10),
              
              if (ownedShares > 0)
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Your Holdings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: performanceColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${profitLoss >= 0 ? "+" : ""}${formatCurrency(profitLoss)} (${profitPercentage.toStringAsFixed(1)}%)',
                                style: TextStyle(color: performanceColor, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildCompactStat('Owned', '$ownedShares'),
                            _buildCompactStat('Avg Price', formatCurrency(investment.purchasePrice)),
                            _buildCompactStat('Value', formatCurrency(currentValue)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 10),
              
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (!_isBuying) {
                                    setState(() {
                                      _isBuying = true;
                                      _quantity = 1;
                                      _updateQuantityController();
                                    });
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _isBuying ? Colors.green : Colors.transparent,
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'BUY',
                                    style: TextStyle(
                                      color: _isBuying ? Colors.white : Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: ownedShares > 0
                                    ? () {
                                        if (_isBuying) {
                                          setState(() {
                                            _isBuying = false;
                                            _quantity = 1;
                                            _updateQuantityController();
                                          });
                                        }
                                      }
                                    : null,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: !_isBuying ? Colors.red : Colors.transparent,
                                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'SELL',
                                    style: TextStyle(
                                      color: !_isBuying ? Colors.white : (ownedShares > 0 ? Colors.grey.shade600 : Colors.grey.shade400),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
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
                      
                      const SizedBox(height: 10),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_isBuying ? 'Total Cost:' : 'Proceeds:', style: const TextStyle(fontSize: 14)),
                          Text(formatCurrency(totalCost), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Cash:', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          Text(formatCurrency(gameState.money), style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                        ],
                      ),
                      
                      if (_isBuying && !canAfford && _quantity > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text('Insufficient funds', style: TextStyle(color: Colors.red[700], fontSize: 12, fontWeight: FontWeight.w500)),
                        ),
                      
                      const SizedBox(height: 10),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isBuying ? Colors.green : Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
                                    unawaited(gameService.saveGame());

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
                            _isBuying ? 'Buy $_quantity Shares' : 'Sell $_quantity Shares',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 10),
              
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('About', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(investment.description, style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.4)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      )
    );
  }
  
  String _formatCompactInt(int value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }

  Widget _buildCompactStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildCompactForecast(Investment investment) {
    final String forecastCategory = investment.getForecastCategory();
    final Color forecastColor = investment.getForecastColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: forecastColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: forecastColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(_getForecastIcon(forecastCategory), color: forecastColor, size: 18),
          const SizedBox(width: 8),
          Text('Forecast: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Text(forecastCategory, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: forecastColor)),
        ],
      ),
    );
  }

  List<double> _getDisplayPriceHistory(Investment investment) {
    return _generateSyntheticHistory(investment);
  }

  List<double> _generateSyntheticHistory(Investment investment) {
    final int targetLength = Investment.maxPriceHistoryLength;
    double currentPrice = investment.currentPrice;
    final double basePrice = investment.basePrice;
    final double volatility = investment.volatility;
    final random = Random(investment.id.hashCode ^ 0x9E3779B9);

    if (currentPrice <= 0) {
      currentPrice = basePrice > 0 ? basePrice : 1.0;
    }

    final double direction = investment.trend >= 0 ? 1.0 : -1.0;
    final double baseDrift = 0.15 + volatility * 0.35;
    final double totalChange = direction * baseDrift;
    double startPrice = currentPrice / (1.0 + totalChange);

    final double minBound = currentPrice * 0.5;
    final double maxBound = currentPrice * 2.0;
    startPrice = startPrice.clamp(minBound, maxBound);

    final List<double> history = List<double>.filled(targetLength, 0.0);
    double runningPrice = startPrice;
    
    for (int i = 0; i < targetLength; i++) {
      final double t = i / (targetLength - 1);
      final double targetPrice = startPrice + (currentPrice - startPrice) * t;
      
      final double noiseAmplitude = (0.03 + volatility * 0.12).clamp(0.03, 0.15);
      final double noise = (random.nextDouble() * 2 - 1.0) * noiseAmplitude;
      runningPrice = targetPrice * (1 + noise);
      
      if (runningPrice <= 0) runningPrice = 0.0001;
      history[i] = runningPrice;
    }

    history[history.length - 1] = currentPrice;
    return history;
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