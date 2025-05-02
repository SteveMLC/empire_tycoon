import 'dart:math'; // Import dart:math for Random, pi, cos, sin
import 'package:flutter/material.dart';

/// Custom painter for luxury background pattern in Platinum UI
class LuxuryPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Create richer luxury patterns with depth and dimension
    final Paint goldStrokePaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    
    final Paint subtlePatternPaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    
    // Create a gradient shader for luxury glow effects
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final goldGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFFFFD700).withOpacity(0.15),
        const Color(0xFFFFF4B8).withOpacity(0.08),
      ],
    );
    
    final Paint sparkleGradientPaint = Paint()
      ..shader = goldGradient.createShader(rect)
      ..style = PaintingStyle.fill;
    
    // Draw high-end subtle diamond pattern background
    final double diamondSize = 32;
    
    // Draw luxury diamond grid pattern
    final Path primaryDiamondPath = Path();
    for (double x = -diamondSize; x < size.width + diamondSize; x += diamondSize * 2) {
      for (double y = -diamondSize; y < size.height + diamondSize; y += diamondSize * 2) {
        primaryDiamondPath.moveTo(x + diamondSize / 2, y);
        primaryDiamondPath.lineTo(x + diamondSize, y + diamondSize / 2);
        primaryDiamondPath.lineTo(x + diamondSize / 2, y + diamondSize);
        primaryDiamondPath.lineTo(x, y + diamondSize / 2);
        primaryDiamondPath.close();
      }
    }
    
    // Draw subtle secondary diamond grid (offset for layered effect)
    final Path secondaryDiamondPath = Path();
    for (double x = -diamondSize + diamondSize; x < size.width + diamondSize; x += diamondSize * 2) {
      for (double y = -diamondSize + diamondSize; y < size.height + diamondSize; y += diamondSize * 2) {
        secondaryDiamondPath.moveTo(x + diamondSize / 2, y);
        secondaryDiamondPath.lineTo(x + diamondSize, y + diamondSize / 2);
        secondaryDiamondPath.lineTo(x + diamondSize / 2, y + diamondSize);
        secondaryDiamondPath.lineTo(x, y + diamondSize / 2);
        secondaryDiamondPath.close();
      }
    }
    
    // Apply base pattern with subtle fill
    canvas.drawPath(
      primaryDiamondPath, 
      Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.03)
        ..style = PaintingStyle.fill,
    );
    
    // Apply strokes for primary grid with more opacity
    canvas.drawPath(
      primaryDiamondPath, 
      Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    
    // Apply strokes for secondary grid with different opacity
    canvas.drawPath(
      secondaryDiamondPath, 
      Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
    
    // Add diagonal pinstripes for texture and depth
    for (double i = -size.height; i < size.width + size.height; i += 40) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        goldStrokePaint,
      );
    }
    
    // Add subtle crosshatch for visual richness
    for (double i = -size.height; i < size.width + size.height; i += 120) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        subtlePatternPaint,
      );
    }
    
    // Add reverse diagonal lines for a woven effect
    for (double i = -size.height; i < size.width + size.height; i += 120) {
      canvas.drawLine(
        Offset(i + size.width, 0),
        Offset(i, size.height),
        subtlePatternPaint..strokeWidth = 0.7,
      );
    }
    
    // Create premium corner highlights
    _drawCornerHighlight(canvas, size, Offset(0, 0), false, false);
    _drawCornerHighlight(canvas, size, Offset(size.width, 0), true, false);
    _drawCornerHighlight(canvas, size, Offset(0, size.height), false, true);
    _drawCornerHighlight(canvas, size, Offset(size.width, size.height), true, true);
    
    // Add premium sparkles with varying sizes for luxury effect
    final Random random = Random(42); // Fixed seed for consistent pattern
    for (int i = 0; i < 80; i++) {
      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height;
      
      // Create varying sized sparkles with emphasis on corners and edges
      double radius;
      
      // Create some larger sparkles at key positions for emphasis
      if (i < 10) {
        // Key positions get larger sparkles
        radius = 1.5 + random.nextDouble() * 2.5;
      } else {
        // Standard sparkles
        radius = 0.8 + random.nextDouble() * 1.2;
      }
      
      // Apply sparkle with glow effect
      final Paint sparklePaint = Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.2 + random.nextDouble() * 0.2)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8); // Soft glow
      
      canvas.drawCircle(
        Offset(x, y),
        radius,
        sparklePaint,
      );
      
      // Add tiny center highlight for selected sparkles
      if (random.nextDouble() > 0.7) {
        canvas.drawCircle(
          Offset(x, y),
          radius * 0.3,
          Paint()..color = Colors.white.withOpacity(0.4),
        );
      }
    }
  }
  
  // Helper method to draw elegant corner highlight accents
  void _drawCornerHighlight(Canvas canvas, Size size, Offset position, bool flipX, bool flipY) {
    final cornerSize = size.width * 0.15;
    
    final Paint cornerGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD700).withOpacity(0.15),
          const Color(0xFFFFD700).withOpacity(0),
        ],
      ).createShader(Rect.fromCircle(center: position, radius: cornerSize));
    
    canvas.drawCircle(position, cornerSize, cornerGlowPaint);
    
    // Draw subtle corner rays
    final Paint rayPaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    
    final double rayLength = cornerSize * 0.7;
    final int rayCount = 5;
    
    for (int i = 0; i < rayCount; i++) {
      double angle = (i * (pi / (rayCount * 2)));
      
      if (flipX && !flipY) angle = pi - angle;
      if (!flipX && flipY) angle = 2 * pi - angle;
      if (flipX && flipY) angle = pi + angle;
      
      final double x2 = position.dx + cos(angle) * rayLength;
      final double y2 = position.dy + sin(angle) * rayLength;
      
      canvas.drawLine(
        position,
        Offset(x2, y2),
        rayPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Custom painter for luxury corner accents
class CornerAccentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Main gold color for elegant accents
    final Paint goldPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    
    // Secondary accent colors with varying opacities for layered effect
    final Paint accentPaint1 = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    
    final Paint accentPaint2 = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    
    // Premium gold fill with subtle gradient
    final Paint goldFillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFFFD700).withOpacity(0.15),
          const Color(0xFFFFE866).withOpacity(0.03),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    
    // Draw primary elegant corner accent - sweeping curve
    final Path primaryPath = Path()
      ..moveTo(0, size.height * 0.8)
      ..cubicTo(
        size.width * 0.1, size.height * 0.25, 
        size.width * 0.25, size.width * 0.1, 
        size.width * 0.8, 0
      );
    
    // Draw a parallel accent line for depth
    final Path secondaryPath = Path()
      ..moveTo(0, size.height * 0.65)
      ..cubicTo(
        size.width * 0.15, size.height * 0.2, 
        size.width * 0.2, size.width * 0.15, 
        size.width * 0.65, 0
      );
    
    canvas.drawPath(primaryPath, goldPaint);
    canvas.drawPath(secondaryPath, accentPaint1);
    
    // Draw decorative luxury motif
    final Path decorativePath = Path();
    
    // Create diamond-shaped accent in corner area
    decorativePath.moveTo(size.width * 0.25, size.height * 0.25);
    decorativePath.lineTo(size.width * 0.4, size.height * 0.1);
    decorativePath.lineTo(size.width * 0.55, size.height * 0.25);
    decorativePath.lineTo(size.width * 0.4, size.height * 0.4);
    decorativePath.close();
    
    // Add inner accent for layered effect
    final Path innerAccentPath = Path();
    innerAccentPath.moveTo(size.width * 0.32, size.height * 0.25);
    innerAccentPath.lineTo(size.width * 0.4, size.height * 0.17);
    innerAccentPath.lineTo(size.width * 0.48, size.height * 0.25);
    innerAccentPath.lineTo(size.width * 0.4, size.height * 0.33);
    innerAccentPath.close();
    
    // Apply gold gradient fill to main motif
    canvas.drawPath(
      decorativePath,
      goldFillPaint,
    );
    
    // Apply gold stroke with higher opacity
    canvas.drawPath(
      decorativePath,
      Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    
    // Apply fill to inner accent
    canvas.drawPath(
      innerAccentPath,
      Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.3)
        ..style = PaintingStyle.fill,
    );
    
    // Apply stroke to inner accent
    canvas.drawPath(
      innerAccentPath,
      Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
    
    // Draw central gold dot with glow effect
    final Paint centerDotPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);
    
    canvas.drawCircle(
      Offset(size.width * 0.4, size.height * 0.25),
      2.0,
      centerDotPaint,
    );
    
    // Add tiny bright center for sparkle effect
    canvas.drawCircle(
      Offset(size.width * 0.4, size.height * 0.25),
      0.8,
      Paint()..color = Colors.white.withOpacity(0.9),
    );
    
    // Draw additional accent lines for framing effect
    // Top edge accent
    canvas.drawLine(
      Offset(size.width * 0.75, 0),
      Offset(size.width, 0),
      accentPaint2..strokeWidth = 1.2,
    );
    
    // Left edge accent
    canvas.drawLine(
      Offset(0, size.height * 0.75),
      Offset(0, size.height),
      accentPaint2..strokeWidth = 1.2,
    );
    
    // Draw subtle corner rays for light effect
    final Paint rayPaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..strokeCap = StrokeCap.round;
    
    // Draw subtle gold rays from center
    for (int i = 0; i < 4; i++) {
      double angle = i * pi / 8;
      double length = size.width * 0.12;
      double startX = size.width * 0.4;
      double startY = size.height * 0.25;
      double endX = startX + cos(angle) * length;
      double endY = startY + sin(angle) * length;
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        rayPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
} 