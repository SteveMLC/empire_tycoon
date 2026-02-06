import 'package:flutter/material.dart';

/// A reusable overlay widget that displays subtle visual feedback
/// when a purchase is made. Combines:
/// - Brief, low-opacity full-screen tint (buy notification)
/// - Soft gold edge frame along the screen perimeter (no center focus)
///
/// Usage:
/// ```dart
/// PurchaseFlashOverlay.show(context);
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

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _PurchaseFlashWidget(
        flashColor: flashColor,
        duration: duration,
        onComplete: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}

/// Internal widget that renders the tint + edge frame animation
class _PurchaseFlashWidget extends StatefulWidget {
  final Color flashColor;
  final Duration duration;
  final VoidCallback onComplete;

  const _PurchaseFlashWidget({
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
  late Animation<double> _tintAnimation;
  late Animation<double> _frameAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Full-screen tint: subtle flash then fade
    _tintAnimation = Tween<double>(
      begin: 0.07,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Edge frame: quick fade in then out (slightly more visible than tint)
    _frameAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 0.0), weight: 3),
    ]).animate(CurvedAnimation(
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
            // Full-screen tint (buy notification)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: widget.flashColor.withOpacity(_tintAnimation.value),
                ),
              ),
            ),
            // Edge frame: soft gold border along screen perimeter
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _EdgeFramePainter(
                    opacity: _frameAnimation.value,
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

/// Draws a soft gold stroke along the screen edges (no center origin)
class _EdgeFramePainter extends CustomPainter {
  final double opacity;
  final Color color;

  _EdgeFramePainter({required this.opacity, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    final strokeWidth = 3.0;
    final borderRadius = 12.0;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(borderRadius),
    );

    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_EdgeFramePainter oldDelegate) {
    return oldDelegate.opacity != opacity;
  }
}
