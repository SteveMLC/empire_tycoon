import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom painter for drawing a platinum crest decoration around a profile avatar
class PlatinumCrestPainter extends CustomPainter {
  final double animationValue;
  
  PlatinumCrestPainter({this.animationValue = 1.0});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Define premium platinum and gold gradient colors
    final platinumColors = [
      const Color(0xFFE5E4E2), // Light platinum
      const Color(0xFFFFFFFF), // White highlight
      const Color(0xFFDADAD9), // Medium platinum 
      const Color(0xFFC0C0C0), // Silver accent
      const Color(0xFFEAEAEA), // Light platinum again
    ];

    final goldAccentColor = const Color(0xFFFFD700).withOpacity(0.6);
    
    // Outer glow effect - more prominent
    final outerGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE5E4E2).withOpacity(0.8 * animationValue),
          goldAccentColor.withOpacity(0.4 * animationValue),
          const Color(0xFFE5E4E2).withOpacity(0.0),
        ],
        stops: const [0.4, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.3))
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius * 1.3, outerGlowPaint);
    
    // Draw decorative radial lines for a more regal appearance
    final linePaint = Paint()
      ..color = const Color(0xFFE5E4E2).withOpacity(0.3 * animationValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    for (int i = 0; i < 36; i++) {
      final angle = i * math.pi / 18;
      final outerPoint = Offset(
        center.dx + radius * 1.25 * math.cos(angle),
        center.dy + radius * 1.25 * math.sin(angle)
      );
      final innerPoint = Offset(
        center.dx + radius * 1.1 * math.cos(angle),
        center.dy + radius * 1.1 * math.sin(angle)
      );
      
      canvas.drawLine(innerPoint, outerPoint, linePaint);
    }
    
    // Outer decorative ring - platinum with gold accents
    final outerRingPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          ...platinumColors,
          goldAccentColor,
          platinumColors[0],
        ],
        startAngle: 0, 
        endAngle: math.pi * 2,
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * animationValue;
    
    canvas.drawCircle(center, radius * 1.2, outerRingPaint);
    
    // Main crest ring - thicker and more elaborate
    final crestPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFE5E4E2), // Light platinum
          const Color(0xFFFFFFFF), // White highlight
          const Color(0xFFD0D0D0), // Medium platinum
          const Color(0xFFFFD700).withOpacity(0.3), // Gold accent
          const Color(0xFFE5E4E2), // Light platinum again
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.08))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0 * animationValue;
    
    canvas.drawCircle(center, radius * 1.08, crestPaint);
    
    // Inner subtle ring for depth
    final innerRingPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFFFFFFF), // White
          const Color(0xFFE5E4E2), // Light platinum
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.02))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * animationValue;
    
    canvas.drawCircle(center, radius * 1.02, innerRingPaint);
    
    // Draw decorative gem-like points around the circle
    final numberOfPoints = 8;
    const double pointAngleOffset = math.pi / 16; // Small offset for visual interest
    
    for (int i = 0; i < numberOfPoints; i++) {
      final angle = (i * 2 * math.pi / numberOfPoints) + pointAngleOffset;
      final pointRadius = 5.0 * animationValue; 
      final pointPosition = Offset(
        center.dx + (radius * 1.15) * math.cos(angle),
        center.dy + (radius * 1.15) * math.sin(angle),
      );
      
      // Draw gem-like decoration
      final pointPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFFFFF), // White center
            goldAccentColor, // Gold tint
            const Color(0xFFE5E4E2), // Platinum edges
          ],
          stops: const [0.2, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: pointPosition, radius: pointRadius * 1.5));
      
      canvas.drawCircle(pointPosition, pointRadius, pointPaint);
      
      // Add small highlight to each gem
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.7 * animationValue)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(
          pointPosition.dx - pointRadius * 0.3,
          pointPosition.dy - pointRadius * 0.3,
        ), 
        pointRadius * 0.3, 
        highlightPaint
      );
    }
    
    // Draw elaborate decorative elements at cardinal points
    final decorSize = 12.0 * animationValue;
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final decorPosition = Offset(
        center.dx + (radius * 1.2) * math.cos(angle),
        center.dy + (radius * 1.2) * math.sin(angle),
      );
      
      _drawOrnateDecoration(canvas, decorPosition, decorSize, angle);
    }
    
    // Add shine effect
    final shinePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.5 * animationValue),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    
    // Draw diagonal shine line
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.pi / 4); // 45-degree angle
    canvas.drawRect(
      Rect.fromLTWH(
        -size.width / 2, 
        -3.0 * animationValue, 
        size.width, 
        6.0 * animationValue
      ), 
      shinePaint
    );
    canvas.restore();
    
    // Add subtle rotating sparkles
    final sparkleRadius = 1.0 * animationValue;
    final time = DateTime.now().millisecondsSinceEpoch / 1000;
    for (int i = 0; i < 12; i++) {
      final sparkleAngle = (i * math.pi / 6) + (time % (2 * math.pi));
      final distance = radius * (0.9 + 0.3 * math.sin(sparkleAngle + time));
      final sparklePos = Offset(
        center.dx + distance * math.cos(sparkleAngle),
        center.dy + distance * math.sin(sparkleAngle),
      );
      
      final sparklePaint = Paint()
        ..color = Colors.white.withOpacity(0.7 * animationValue)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(sparklePos, sparkleRadius, sparklePaint);
    }
  }
  
  // Helper method to draw ornate decorations at cardinal points
  void _drawOrnateDecoration(Canvas canvas, Offset position, double size, double angle) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(angle);
    
    final decorPaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.7 * animationValue)
      ..style = PaintingStyle.fill;
    
    // Draw a small ornate shape (like a fleur-de-lis or crown)
    final path = Path();
    
    // Base
    path.moveTo(-size/2, 0);
    path.lineTo(size/2, 0);
    path.lineTo(size/3, -size/2);
    path.lineTo(0, -size);
    path.lineTo(-size/3, -size/2);
    path.close();
    
    canvas.drawPath(path, decorPaint);
    
    // Add highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.5 * animationValue)
      ..style = PaintingStyle.fill;
    
    final highlightPath = Path();
    highlightPath.moveTo(-size/4, -size/4);
    highlightPath.lineTo(0, -size/2);
    highlightPath.lineTo(size/4, -size/4);
    
    canvas.drawPath(highlightPath, highlightPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PlatinumCrestPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
} 