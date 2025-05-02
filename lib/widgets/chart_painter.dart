import 'package:flutter/material.dart';
import '../themes/stats_themes.dart';

// Chart painter for line charts
class ChartPainter extends CustomPainter {
  final List<double> data;
  final double minValue;
  final double maxValue;
  final StatsTheme theme;

  ChartPainter({
    required this.data,
    required this.minValue,
    required this.maxValue,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bool isExecutiveTheme = theme.id == 'executive';
    
    final paint = Paint()
      ..color = theme.primaryChartColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Create gradient paint for the path with enhanced colors
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        colors: theme.chartGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Create enhanced fill paint for area under the curve
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          theme.primaryChartColor.withOpacity(isExecutiveTheme ? 0.3 : 0.2),
          theme.primaryChartColor.withOpacity(isExecutiveTheme ? 0.03 : 0.05),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Add subtle grid lines for executive theme
    if (isExecutiveTheme) {
      final gridPaint = Paint()
        ..color = const Color(0xFF2A3142).withOpacity(0.5)
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke;
        
      // Draw horizontal grid lines
      for (int i = 1; i < 5; i++) {
        final y = (size.height - 20) * i / 5;
        canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          gridPaint,
        );
      }
      
      // Draw vertical grid lines
      for (int i = 1; i < data.length; i += 2) {
        final x = size.width * i / (data.length - 1);
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height - 20),
          gridPaint,
        );
      }
    }

    final textStyle = TextStyle(
      color: theme.textColor.withOpacity(0.7),
      fontSize: 10,
    );
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final path = Path();
    final width = size.width;
    final height = size.height - 20; // Reserve space for labels at bottom

    final double xStep = width / (data.length - 1);

    final range = (maxValue - minValue) == 0 ? 1 : maxValue - minValue;

    // Create fill path (start from bottom)
    final fillPath = Path();
    
    // Add the points for the line path and fill path
    for (int i = 0; i < data.length; i++) {
      final x = i * xStep;
      final y = height - ((data[i] - minValue) / range * height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, y);
      } else {
        // Use a smoother curve for Executive theme
        if (isExecutiveTheme && i > 0 && i < data.length - 1) {
          final prevX = (i - 1) * xStep;
          final prevY = height - ((data[i - 1] - minValue) / range * height);
          final controlX = (x + prevX) / 2;
          
          path.quadraticBezierTo(controlX, prevY, x, y);
          fillPath.quadraticBezierTo(controlX, prevY, x, y);
        } else {
          path.lineTo(x, y);
          fillPath.lineTo(x, y);
        }
      }
    }
    
    // Complete the fill path by drawing down to the bottom and back to start
    fillPath.lineTo((data.length - 1) * xStep, height);
    fillPath.lineTo(0, height);
    fillPath.close();

    // Draw the filled area under the curve
    canvas.drawPath(fillPath, fillPaint);
    
    // Draw the main line with gradient
    canvas.drawPath(path, gradientPaint);

    // Draw enhanced points on the line with subtle glow for executive theme
    final pointPaint = Paint()
      ..color = isExecutiveTheme ? Colors.white : theme.primaryChartColor
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;
      
    // For glowing effect in executive theme
    final glowPaint = isExecutiveTheme ? (Paint()
      ..color = theme.primaryChartColor.withOpacity(0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.fill) : null;

    // Draw fewer points for a cleaner look
    final pointInterval = data.length > 20 ? 3 : 2;
    
    for (int i = 0; i < data.length; i += pointInterval) {
      final x = i * xStep;
      final y = height - ((data[i] - minValue) / range * height);

      // For executive theme, add subtle point glow
      if (isExecutiveTheme && glowPaint != null) {
        canvas.drawCircle(Offset(x, y), 5, glowPaint);
      }
      
      // Draw the actual point
      canvas.drawCircle(
        Offset(x, y), 
        isExecutiveTheme ? 3 : 4, 
        pointPaint
      );
      
      // Add white center for executive theme points
      if (isExecutiveTheme) {
        final centerPaint = Paint()
          ..color = theme.primaryChartColor
          ..strokeWidth = 2
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 1.5, centerPaint);
      }
    }

    // Draw min and max value labels on y-axis with enhanced styling
    if (maxValue > minValue) {
      // Draw background for labels in executive theme
      if (isExecutiveTheme) {
        final labelBgPaint = Paint()
          ..color = const Color(0xFF1E2430)
          ..style = PaintingStyle.fill;
          
        canvas.drawRect(
          Rect.fromLTWH(0, 0, 50, 16),
          labelBgPaint
        );
        
        canvas.drawRect(
          Rect.fromLTWH(0, height / 2 - 8, 50, 16),
          labelBgPaint
        );
        
        canvas.drawRect(
          Rect.fromLTWH(0, height - 16, 50, 16),
          labelBgPaint
        );
      }
    
      String maxLabel = _formatValue(maxValue);
      textPainter.text = TextSpan(
        text: maxLabel, 
        style: textStyle.copyWith(
          fontWeight: isExecutiveTheme ? FontWeight.bold : FontWeight.normal,
          fontSize: isExecutiveTheme ? 11 : 10,
        )
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(4, 4));

      String midLabel = _formatValue(minValue + range / 2);
      textPainter.text = TextSpan(
        text: midLabel, 
        style: textStyle.copyWith(
          fontWeight: isExecutiveTheme ? FontWeight.bold : FontWeight.normal,
          fontSize: isExecutiveTheme ? 11 : 10,
        )
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(4, height / 2 - textPainter.height / 2));

      String minLabel = _formatValue(minValue);
      textPainter.text = TextSpan(
        text: minLabel, 
        style: textStyle.copyWith(
          fontWeight: isExecutiveTheme ? FontWeight.bold : FontWeight.normal,
          fontSize: isExecutiveTheme ? 11 : 10,
        )
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(4, height - textPainter.height - 4));
    }
  }

  String _formatValue(double value) {
    if (value >= 1000000000000) {
      return '\$${(value / 1000000000000).toStringAsFixed(1)}T';
    } else if (value >= 1000000000) {
      return '\$${(value / 1000000000).toStringAsFixed(1)}B';
    } else if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$${value.toStringAsFixed(0)}';
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 