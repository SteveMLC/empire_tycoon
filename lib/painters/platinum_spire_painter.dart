import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom painter for drawing the platinum spire trophy with animation effects
class PlatinumSpirePainter extends CustomPainter {
  final double animationValue;
  final double particleAnimationValue;
  
  PlatinumSpirePainter({
    this.animationValue = 1.0,
    this.particleAnimationValue = 0.0,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 4; // Spire is more narrow than the crest
    
    // Define platinum and gold colors for the spire
    final platinumColors = [
      const Color(0xFFE5E4E2), // Light platinum
      const Color(0xFFFFFFFF), // White highlight
      const Color(0xFFDADAD9), // Medium platinum 
      const Color(0xFFC0C0C0), // Silver accent
      const Color(0xFFEAEAEA), // Light platinum again
    ];

    final goldAccentColor = const Color(0xFFFFD700).withOpacity(0.7);
    
    // Calculate emergence from ground effect
    final emergenceOffset = (1.0 - animationValue) * size.height * 0.7;
    
    canvas.save();
    canvas.translate(0, emergenceOffset);

    // Base platform glow
    final baseGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          goldAccentColor.withOpacity(0.6 * animationValue),
          goldAccentColor.withOpacity(0.2 * animationValue),
          goldAccentColor.withOpacity(0.0),
        ],
        stops: const [0.1, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(center.dx, size.height * 0.85), radius: radius * 2.0))
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(center.dx, size.height * 0.85), radius * 2.0, baseGlowPaint);
    
    // Base platform
    final basePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          platinumColors[2],
          platinumColors[1],
          platinumColors[0],
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(
        center.dx - radius * 1.2, 
        size.height * 0.8, 
        radius * 2.4, 
        radius * 0.4
      ))
      ..style = PaintingStyle.fill;
    
    final basePath = Path()
      ..moveTo(center.dx - radius * 1.2, size.height * 0.82)
      ..lineTo(center.dx + radius * 1.2, size.height * 0.82)
      ..lineTo(center.dx + radius, size.height * 0.88)
      ..lineTo(center.dx - radius, size.height * 0.88)
      ..close();
    
    canvas.drawPath(basePath, basePaint);
    
    // Add base platform edge detail
    final baseEdgePaint = Paint()
      ..color = goldAccentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    canvas.drawLine(
      Offset(center.dx - radius * 1.2, size.height * 0.82),
      Offset(center.dx + radius * 1.2, size.height * 0.82),
      baseEdgePaint
    );
    
    // Draw the main spire
    final spirePath = Path();
    
    // Main spire body
    spirePath.moveTo(center.dx - radius * 0.8, size.height * 0.82); // Base left
    spirePath.lineTo(center.dx + radius * 0.8, size.height * 0.82); // Base right
    spirePath.lineTo(center.dx + radius * 0.3, size.height * 0.3); // Narrowing
    spirePath.lineTo(center.dx, size.height * 0.1); // Tip
    spirePath.lineTo(center.dx - radius * 0.3, size.height * 0.3); // Narrowing
    spirePath.close();
    
    final spirePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          platinumColors[3],
          platinumColors[0],
          platinumColors[1],
          platinumColors[0],
          platinumColors[3],
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(
        center.dx - radius, 
        size.height * 0.1, 
        radius * 2, 
        size.height * 0.72
      ));
    
    canvas.drawPath(spirePath, spirePaint);
    
    // Spire edge highlights
    final edgePaint = Paint()
      ..color = Colors.white.withOpacity(0.7 * animationValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawLine(
      Offset(center.dx - radius * 0.3, size.height * 0.3),
      Offset(center.dx, size.height * 0.1),
      edgePaint
    );
    
    canvas.drawLine(
      Offset(center.dx, size.height * 0.1),
      Offset(center.dx + radius * 0.3, size.height * 0.3),
      edgePaint
    );
    
    // Holographic orb at top
    final orbPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.9 * animationValue),
          goldAccentColor.withOpacity(0.6 * animationValue),
          platinumColors[0].withOpacity(0.4 * animationValue),
          Colors.transparent,
        ],
        stops: const [0.1, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(center.dx, size.height * 0.1), radius: radius * 0.4));
    
    // Use a pulsing effect for the orb
    final orbPulse = (math.sin(particleAnimationValue * math.pi * 2) + 1) / 2;
    final orbRadius = radius * 0.2 * (1.0 + orbPulse * 0.3);
    
    canvas.drawCircle(Offset(center.dx, size.height * 0.1), orbRadius, orbPaint);
    
    // Add decorative bands around the spire
    for (int i = 1; i <= 3; i++) {
      final yPos = size.height * (0.3 + i * 0.13);
      final bandWidth = radius * (0.4 + i * 0.15);
      
      final bandPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            goldAccentColor,
            platinumColors[1],
            goldAccentColor,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(
          center.dx - bandWidth,
          yPos - 3, 
          bandWidth * 2, 
          6
        ))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      canvas.drawLine(
        Offset(center.dx - bandWidth, yPos),
        Offset(center.dx + bandWidth, yPos),
        bandPaint
      );
    }
    
    // Draw platinum dust particle effect - only visible during emergence animation
    if (animationValue < 1.0) {
      final random = math.Random(42); // Fixed seed for consistent pattern
      final particleCount = (20 * (1.0 - animationValue)).round();
      
      for (int i = 0; i < particleCount; i++) {
        final particleSize = 1.0 + random.nextDouble() * 2.0;
        final xOffset = (random.nextDouble() - 0.5) * size.width * 0.8;
        final yOffset = size.height * (0.3 + random.nextDouble() * 0.6);
        
        final particlePaint = Paint()
          ..color = i % 3 == 0 
            ? goldAccentColor.withOpacity(0.7 * (1.0 - animationValue))
            : platinumColors[random.nextInt(platinumColors.length)].withOpacity(0.6 * (1.0 - animationValue))
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(
          Offset(center.dx + xOffset, yOffset),
          particleSize,
          particlePaint
        );
      }
    }
    
    // Soft glow aura effect for the spire when fully emerged
    if (animationValue > 0.8) {
      final auraOpacity = (animationValue - 0.8) * 5.0; // Remap 0.8-1.0 to 0-1
      final auraPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            platinumColors[1].withOpacity(0.15 * auraOpacity),
            goldAccentColor.withOpacity(0.08 * auraOpacity),
            Colors.transparent,
          ],
          stops: const [0.2, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 3.0))
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(center, radius * 3.0, auraPaint);
    }
    
    // Add sparkles for active state - based on particle animation value
    if (animationValue >= 1.0) {
      final sparkleCount = 5;
      final time = particleAnimationValue * math.pi * 2;
      
      for (int i = 0; i < sparkleCount; i++) {
        final angle = (i * math.pi * 2 / sparkleCount) + time * 0.2;
        final distance = radius * 0.8 + math.sin(time + i) * radius * 0.2;
        final yPosition = size.height * 0.4 + math.sin(time + i * 0.5) * size.height * 0.1;
        
        final sparklePos = Offset(
          center.dx + distance * math.cos(angle),
          yPosition
        );
        
        // Create a simple sparkle effect
        final sparkleSize = 2.0 + math.sin(time + i * 0.7) * 1.0;
        final sparklePaint = Paint()
          ..color = Colors.white.withOpacity(0.7 + math.sin(time + i) * 0.3)
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(sparklePos, sparkleSize, sparklePaint);
        
        // Add a subtle gold halo around each sparkle
        final haloPaint = Paint()
          ..color = goldAccentColor.withOpacity(0.4)
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(sparklePos, sparkleSize * 2, haloPaint);
      }
    }
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PlatinumSpirePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.particleAnimationValue != particleAnimationValue;
  }
} 