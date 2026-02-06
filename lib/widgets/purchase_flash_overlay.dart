import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A reusable overlay widget that displays subtle visual feedback
/// when a purchase is made. Combines:
/// - Soft gold rings radiating outward from tap point
/// - Brief, low-opacity screen tint
///
/// Usage:
/// ```dart
/// PurchaseFlashOverlay.show(
///   context,
///   tapPosition: Offset(100, 200), // Optional, defaults to center
/// );
/// ```
class PurchaseFlashOverlay {
  /// Shows the purchase flash effect as an overlay
  static void show(
    BuildContext context, {
    Offset? tapPosition,
    Color flashColor = const Color(0xFFFFD700), // Gold
    Duration duration = const Duration(milliseconds: 400),
  }) {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    
    // Default to screen center if no tap position provided
    final screenSize = MediaQuery.of(context).size;
    final effectivePosition = tapPosition ?? Offset(screenSize.width / 2, screenSize.height / 2);
    
    // Create and insert the overlay entry
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _PurchaseFlashWidget(
        tapPosition: effectivePosition,
        flashColor: flashColor,
        duration: duration,
        onComplete: () {
          // Remove the overlay after animation completes
          overlayEntry.remove();
        },
      ),
    );
    
    overlay.insert(overlayEntry);
  }
}

/// Internal widget that renders the actual flash animation
class _PurchaseFlashWidget extends StatefulWidget {
  final Offset tapPosition;
  final Color flashColor;
  final Duration duration;
  final VoidCallback onComplete;
  
  const _PurchaseFlashWidget({
    required this.tapPosition,
    required this.flashColor,
    required this.duration,
    required this.onComplete,
  });
  
  @override
  State<_PurchaseFlashWidget> createState() => _PurchaseFlashWidgetState();
}

class _PurchaseFlashWidgetState extends State<_PurchaseFlashWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _tintAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    // Pulse animation: grows outward quickly, fades as it grows
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    // Fade animation: fades out the pulse
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));
    
    // Tint animation: subtle flash then fade
    _tintAnimation = Tween<double>(
      begin: 0.07, // Low peak opacity for a gentle glow
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _controller.forward().then((_) {
      widget.onComplete();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // Full-screen amber tint
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: widget.flashColor.withOpacity(_tintAnimation.value),
                ),
              ),
            ),
            
            // Radiating pulse from tap point
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _PulsePainter(
                    tapPosition: widget.tapPosition,
                    progress: _pulseAnimation.value,
                    opacity: _fadeAnimation.value,
                    color: widget.flashColor,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Custom painter for the radiating pulse effect
class _PulsePainter extends CustomPainter {
  final Offset tapPosition;
  final double progress;
  final double opacity;
  final Color color;
  
  _PulsePainter({
    required this.tapPosition,
    required this.progress,
    required this.opacity,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Calculate max radius to cover the entire screen from tap point
    final maxDistance = math.max(
      math.max(tapPosition.dx, size.width - tapPosition.dx),
      math.max(tapPosition.dy, size.height - tapPosition.dy),
    ) * 1.5;
    
    final currentRadius = maxDistance * progress;
    
    // Draw multiple expanding circles for a soft layered effect (no center dot)
    for (int i = 0; i < 3; i++) {
      final layerDelay = i * 0.15;
      final layerProgress = math.max(0.0, math.min(1.0, progress - layerDelay));
      
      if (layerProgress > 0) {
        final layerRadius = currentRadius * layerProgress;
        final layerOpacity = opacity * (1.0 - layerProgress) * 0.2;
        
        final paint = Paint()
          ..color = color.withOpacity(layerOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0 + (i * 1.5);
        
        canvas.drawCircle(tapPosition, layerRadius, paint);
      }
    }
  }
  
  @override
  bool shouldRepaint(_PulsePainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.opacity != opacity;
  }
}
