import 'package:flutter/material.dart';
import 'dart:math' show max;
import '../models/investment.dart';

class InvestmentChart extends StatelessWidget {
  final List<double> priceHistory;
  final double changePercent;

  const InvestmentChart({
    Key? key,
    required this.priceHistory,
    required this.changePercent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ChartPainter(priceHistory, changePercent),
      child: Container(),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> priceHistory;
  final double changePercent;

  _ChartPainter(this.priceHistory, this.changePercent);

  @override
  void paint(Canvas canvas, Size size) {
    if (priceHistory.isEmpty) return;

    // Chart dimensions
    final double chartWidth = size.width;
    final double chartHeight = size.height;
    final double padding = 20.0; // Increased padding for better visibility
    
    // Get prices - create a deep copy to avoid modifying the original
    List<double> allPrices = List.from(priceHistory);
    
    // Add current price (last price in the history) for calculation
    double currentPrice = allPrices.isNotEmpty ? allPrices.last : 0;
    
    // Ensure we have at least two points to draw a line
    if (allPrices.length == 1) {
      // If we only have one price point, duplicate it to create a flat line
      allPrices.add(allPrices.first);
    }
    
    // Determine min and max price
    final double minPrice = allPrices.reduce((a, b) => a < b ? a : b);
    final double maxPrice = allPrices.reduce((a, b) => a > b ? a : b);
    
    // Enhanced dynamic scaling for price range
    final double priceVariability = (maxPrice - minPrice) / (minPrice > 0 ? minPrice : 1);
    
    // Adaptive buffer factor based on price volatility
    // More volatile = more buffer space to prevent values from going off screen
    final double bufferFactor = priceVariability > 0.2 ? 0.6 : 
                                priceVariability > 0.1 ? 0.4 : 0.2;
    
    // Calculate minimum Y value with sufficient buffer to prevent values hugging bottom
    final double minY = max(0, minPrice * (1 - bufferFactor));
    
    // Calculate price range with extra padding at top to prevent values going off screen
    final double rawPriceRange = max(maxPrice - minY, 0.0001); // Prevent zero range
    
    // Apply buffer to the top of the chart
    final double topBuffer = rawPriceRange * bufferFactor;
    final double effectivePriceRange = rawPriceRange + topBuffer;
    
    // Minimum range to prevent flat lines when prices barely change
    final double minimumRange = currentPrice * 0.05; // At least 5% of current price
    final double displayRange = max(effectivePriceRange, minimumRange);
    
    // Drawing settings
    final Paint linePaint = Paint()
      ..color = changePercent >= 0 ? Colors.green : Colors.red
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    
    final Paint fillPaint = Paint()
      ..color = (changePercent >= 0 ? Colors.green : Colors.red).withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    final Paint gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1.0;
    
    // Draw horizontal grid lines
    final int numGridLines = 5;
    for (int i = 0; i < numGridLines; i++) {
      final double y = padding + (chartHeight - 2 * padding) * i / (numGridLines - 1);
      canvas.drawLine(
        Offset(padding, y),
        Offset(chartWidth - padding, y),
        gridPaint,
      );
    }
    
    // Create path for line
    final Path linePath = Path();
    final Path fillPath = Path();
    
    // Calculate points
    List<Offset> points = [];
    
    for (int i = 0; i < allPrices.length; i++) {
      final double x = padding + (chartWidth - 2 * padding) * i / (allPrices.length - 1);
      final double normalizedPrice = (allPrices[i] - minY) / displayRange;
      final double y = chartHeight - padding - normalizedPrice * (chartHeight - 2 * padding);
      points.add(Offset(x, y));
    }
    
    if (points.isEmpty) return;
    
    // Create line path
    linePath.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    
    // Create fill path (area under the curve)
    fillPath.moveTo(points[0].dx, chartHeight - padding); // Bottom left
    fillPath.lineTo(points[0].dx, points[0].dy); // Top left
    
    for (int i = 1; i < points.length; i++) {
      fillPath.lineTo(points[i].dx, points[i].dy);
    }
    
    fillPath.lineTo(points.last.dx, chartHeight - padding); // Bottom right
    fillPath.close();
    
    // Draw fill and line
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);
    
    // Draw price labels
    final TextPainter labelPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    // Draw top price
    labelPainter.text = TextSpan(
      text: '\$${maxPrice.toStringAsFixed(2)}',
      style: TextStyle(
        backgroundColor: Colors.white.withOpacity(0.7),
        fontWeight: FontWeight.bold,
        color: Colors.grey[600],
        fontSize: 12,
      ),
    );
    labelPainter.layout();
    labelPainter.paint(
      canvas,
      Offset(chartWidth - padding - labelPainter.width, padding),
    );
    
    // Draw bottom price
    labelPainter.text = TextSpan(
      text: '\$${minPrice.toStringAsFixed(2)}',
      style: TextStyle(
        backgroundColor: Colors.white.withOpacity(0.7),
        fontWeight: FontWeight.bold,
        color: Colors.grey[600],
        fontSize: 12,
      ),
    );
    labelPainter.layout();
    labelPainter.paint(
      canvas,
      Offset(chartWidth - padding - labelPainter.width, chartHeight - padding - labelPainter.height),
    );
    
    // Draw current price marker
    final Paint currentPricePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0;
    
    final double normalizedCurrentPrice = (currentPrice - minY) / displayRange;
    final double currentPriceY = chartHeight - padding - normalizedCurrentPrice * (chartHeight - 2 * padding);
    
    canvas.drawLine(
      Offset(chartWidth - 2 * padding, currentPriceY),
      Offset(chartWidth - padding, currentPriceY),
      currentPricePaint,
    );
    
    // Draw current price label
    labelPainter.text = TextSpan(
      text: '\$${currentPrice.toStringAsFixed(2)}',
      style: const TextStyle(
        color: Colors.blue,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    labelPainter.layout();
    labelPainter.paint(
      canvas,
      Offset(chartWidth - padding - labelPainter.width, currentPriceY - labelPainter.height),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
