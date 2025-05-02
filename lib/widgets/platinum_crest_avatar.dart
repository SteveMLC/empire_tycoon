import 'package:flutter/material.dart';
import 'dart:math';
import '../painters/platinum_crest_painter.dart';
import '../models/mogul_avatar.dart';

/// A widget that displays an avatar with a platinum crest decoration
/// when the platinum_crest is unlocked
class PlatinumCrestAvatar extends StatefulWidget {
  final bool showCrest;
  final String? userAvatar;
  final String? mogulAvatarId;
  final double size;
  
  const PlatinumCrestAvatar({
    Key? key,
    required this.showCrest,
    this.userAvatar,
    this.mogulAvatarId,
    this.size = 80.0,
  }) : super(key: key);

  @override
  State<PlatinumCrestAvatar> createState() => _PlatinumCrestAvatarState();
}

class _PlatinumCrestAvatarState extends State<PlatinumCrestAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Create a curved animation for the crest effect
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    
    // Start animation if crest should be shown
    if (widget.showCrest) {
      _controller.forward();
    }
  }
  
  @override
  void didUpdateWidget(PlatinumCrestAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Animate crest appearance/disappearance when showCrest changes
    if (widget.showCrest != oldWidget.showCrest) {
      if (widget.showCrest) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Background glow effect to make it more prominent
            if (widget.showCrest)
              Container(
                width: widget.size * 1.4,
                height: widget.size * 1.4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFE5E4E2).withOpacity(0.3 * _animation.value),
                      const Color(0xFFFFD700).withOpacity(0.1 * _animation.value),
                      Colors.transparent,
                    ],
                    stops: const [0.3, 0.6, 1.0],
                  ),
                ),
              ),
            
            // The platinum crest effect with CustomPaint
            if (widget.showCrest)
              CustomPaint(
                size: Size(widget.size * 1.4, widget.size * 1.4),
                painter: PlatinumCrestPainter(
                  animationValue: _animation.value,
                ),
              ),
            
            // Gold accent ring (appears before the avatar)
            if (widget.showCrest)
              Container(
                width: widget.size * 1.02,
                height: widget.size * 1.02,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      const Color(0xFFE5E4E2),
                      const Color(0xFFFFD700).withOpacity(0.7),
                      const Color(0xFFE5E4E2),
                      const Color(0xFFFFD700).withOpacity(0.3),
                      const Color(0xFFE5E4E2),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5 * _animation.value),
                      blurRadius: 8,
                      spreadRadius: -2,
                    ),
                  ],
                ),
              ),
            
            // The avatar container
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.showCrest ? Colors.grey.shade50 : Colors.blue.shade50,
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.showCrest 
                    ? const Color(0xFFE5E4E2) // Platinum color for border when crest is shown
                    : Colors.blue.shade300,
                  width: widget.showCrest ? 3.0 : 2.0,
                ),
                // Add enhanced shadow when crest is active
                boxShadow: widget.showCrest ? [
                  BoxShadow(
                    color: const Color(0xFFE5E4E2).withOpacity(0.8 * _animation.value),
                    blurRadius: 12 * _animation.value,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.2 * _animation.value),
                    blurRadius: 15 * _animation.value,
                    spreadRadius: -2,
                  ),
                ] : null,
              ),
              child: Center(
                child: widget.mogulAvatarId != null
                  ? Container(
                      width: widget.size * 0.8,
                      height: widget.size * 0.8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade200,
                        // Add subtle inner shadow for depth
                        boxShadow: widget.showCrest ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            spreadRadius: -2,
                            offset: const Offset(0, 1),
                          ),
                        ] : null,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          getMogulAvatars()
                            .firstWhere((avatar) => avatar.id == widget.mogulAvatarId)
                            .imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                getMogulAvatars()
                                  .firstWhere((avatar) => avatar.id == widget.mogulAvatarId)
                                  .emoji,
                                style: const TextStyle(fontSize: 32),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  : Text(
                      widget.userAvatar ?? '👨‍💼',
                      style: TextStyle(
                        fontSize: 40,
                        // Add shadow to text if crest is active
                        shadows: widget.showCrest ? [
                          Shadow(
                            offset: const Offset(1, 1),
                            blurRadius: 3,
                            color: Colors.black.withOpacity(0.2),
                          ),
                        ] : null,
                      ),
                    ),
              ),
            ),
            
            // Optional: Animated sparkle effects
            if (widget.showCrest) ...[
              for (int i = 0; i < 3; i++)
                _buildAnimatedSparkle(i),
            ],
          ],
        );
      },
    );
  }
  
  // Build an animated sparkle at different positions
  Widget _buildAnimatedSparkle(int index) {
    // Calculate position based on index and animation value
    final angle = (index * 2.0 * 3.14159 / 3) + (_controller.value * 3.14159 / 2);
    final distance = widget.size * 0.6;
    final x = distance * cos(angle);
    final y = distance * sin(angle);
    
    return Positioned(
      left: widget.size / 2 + x,
      top: widget.size / 2 + y,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          // Calculate a pulse animation for the sparkle
          final pulseValue = sin(_controller.value * 10 + index) * 0.5 + 0.5;
          return Opacity(
            opacity: 0.7 * _animation.value * pulseValue,
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.5),
                    blurRadius: 3,
                    spreadRadius: 1,
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