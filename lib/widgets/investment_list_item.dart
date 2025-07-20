import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/investment.dart';
import '../utils/number_formatter.dart';

class InvestmentListItem extends StatefulWidget {
  final Investment investment;
  final VoidCallback onTap;

  const InvestmentListItem({
    Key? key,
    required this.investment,
    required this.onTap,
  }) : super(key: key);

  @override
  _InvestmentListItemState createState() => _InvestmentListItemState();
}

class _InvestmentListItemState extends State<InvestmentListItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double priceChange = widget.investment.getPriceChangePercent();
    
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
        _controller.forward();
        HapticFeedback.lightImpact(); // Add haptic feedback for better interaction feel
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                color: _isPressed ? Colors.grey.shade50 : Colors.white,
              ),
              child: Row(
                children: [
                  // Investment icon
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: widget.investment.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.investment.icon,
                      size: 20,
                      color: widget.investment.color,
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Investment name and category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.investment.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          widget.investment.category,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        if (widget.investment.owned > 0)
                          Text(
                            'Owned: ${widget.investment.owned}',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Price info and change
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        NumberFormatter.formatCurrencyPrecise(widget.investment.currentPrice),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      
                      // Show market performance for all investments (owned and non-owned)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: priceChange >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${priceChange >= 0 ? '+' : ''}${priceChange.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: priceChange >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      
                      // Always show dividend yield if the investment has dividends, regardless of ownership
                      if (widget.investment.hasDividends()) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.payments,
                              size: 10,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 1),
                            Text(
                              '${widget.investment.getDividendYield().toStringAsFixed(1)}% Div',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
