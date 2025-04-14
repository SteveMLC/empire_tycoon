import 'package:flutter/material.dart';
import '../models/investment.dart';

class InvestmentListItem extends StatelessWidget {
  final Investment investment;
  final VoidCallback onTap;

  const InvestmentListItem({
    Key? key,
    required this.investment,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double priceChange = investment.getPriceChangePercent();
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
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
            
            // Investment name and category
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
                  Text(
                    investment.category,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  if (investment.owned > 0)
                    Text(
                      'Owned: ${investment.owned}',
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
                  '\$${investment.currentPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                if (investment.hasDividends()) ...[
                  const SizedBox(height: 2),
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
                        '${investment.getDividendYield().toStringAsFixed(1)}% Div',
                        style: TextStyle(
                          fontSize: 12,
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
  }
}
