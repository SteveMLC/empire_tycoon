import 'dart:math';
import 'package:flutter/material.dart';

/// A widget that displays a floating money amount with clean animations.
/// Features:
/// - Clean white text on semi-transparent dark pill
/// - Smooth float-up animation centered on tap point
/// - Small random horizontal jitter for variety
/// - Scale pop animation before fading
/// - Automatic cleanup after animation completes
class FloatingMoneyWidget extends StatefulWidget {
  final double amount;
  final Offset startPosition;
  final VoidCallback? onComplete;

  const FloatingMoneyWidget({
    Key? key,
    required this.amount,
    required this.startPosition,
    this.onComplete,
  }) : super(key: key);

  @override
  State<FloatingMoneyWidget> createState() => _FloatingMoneyWidgetState();
}

class _FloatingMoneyWidgetState extends State<FloatingMoneyWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _verticalPosition;
  late Animation<double> _scale;
  late double _horizontalOffset;

  @override
  void initState() {
    super.initState();

    // Small random horizontal jitter for variety (-12 to +12 pixels)
    final random = Random();
    _horizontalOffset = (random.nextDouble() * 24) - 12;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    // Fade out smoothly (stays visible longer, then quick fade)
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
    ]).animate(_controller);

    // Float up smoothly
    _verticalPosition = Tween<double>(
      begin: 0,
      end: -120,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Scale animation: 1.0 → 1.2 → 1.0 (bounce effect)
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 60,
      ),
    ]).animate(_controller);

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Format currency amount with K/M notation
  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '+\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '+\$${(amount / 1000).toStringAsFixed(1)}K';
    } else if (amount >= 100) {
      return '+\$${amount.toStringAsFixed(0)}';
    } else {
      return '+\$${amount.toStringAsFixed(2)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.startPosition.dx + _horizontalOffset,
          top: widget.startPosition.dy + _verticalPosition.value,
          child: FractionalTranslation(
            translation: const Offset(-0.5, -0.5),
            child: Opacity(
              opacity: _opacity.value,
              child: Transform.scale(
                scale: _scale.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _formatAmount(widget.amount),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4ADE80),
                      letterSpacing: 0.3,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Manager to handle multiple floating money animations
/// Limits active animations to prevent performance issues
class FloatingMoneyManager extends StatefulWidget {
  final Widget child;

  const FloatingMoneyManager({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<FloatingMoneyManager> createState() => FloatingMoneyManagerState();

  static FloatingMoneyManagerState? of(BuildContext context) {
    return context.findAncestorStateOfType<FloatingMoneyManagerState>();
  }
}

class FloatingMoneyManagerState extends State<FloatingMoneyManager> {
  final List<Widget> _activeAnimations = [];
  static const int _maxAnimations = 10;

  /// Spawn a new floating money animation at the given position.
  /// [position] is in global coordinates; converted to Stack-local for Positioned.
  void spawnFloatingMoney(double amount, Offset position) {
    if (!mounted) return;

    // If we're at max, remove the oldest animation
    if (_activeAnimations.length >= _maxAnimations) {
      setState(() {
        _activeAnimations.removeAt(0);
      });
    }

    // Convert global to Stack-local for Positioned.
    Offset startPosition = position;
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      startPosition = box.globalToLocal(position);
    }

    final key = UniqueKey();
    final animation = FloatingMoneyWidget(
      key: key,
      amount: amount,
      startPosition: startPosition,
      onComplete: () {
        if (!mounted) return;
        setState(() {
          _activeAnimations.removeWhere((widget) {
            return widget.key == key;
          });
        });
      },
    );

    setState(() {
      _activeAnimations.add(animation);
    });
  }

  /// Clear all active animations
  void clearAll() {
    if (!mounted) return;
    setState(() {
      _activeAnimations.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        ..._activeAnimations,
      ],
    );
  }
}
