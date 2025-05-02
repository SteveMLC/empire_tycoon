import 'dart:math'; // Import dart:math for Random
import 'package:flutter/material.dart';

/// Animated Platinum Points icon that shows a sparkle animation when triggered
class AnimatedPPIcon extends StatefulWidget {
  final bool showAnimation;
  
  const AnimatedPPIcon({
    Key? key,
    required this.showAnimation,
  }) : super(key: key);
  
  @override
  _AnimatedPPIconState createState() => _AnimatedPPIconState();
}

class _AnimatedPPIconState extends State<AnimatedPPIcon> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  
  // For the random glitter effect
  List<Map<String, dynamic>> _glitters = [];
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2)
          .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
          .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 60,
      ),
    ]).animate(_animationController);
    
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );
    
    // Generate random glitters
    _generateGlitters();
    
    // Add listener to restart animation when prop changes
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.showAnimation) {
          _animationController.reset();
          _generateGlitters(); // Regenerate glitters for variety
          _animationController.forward();
        }
      }
    });
  }
  
  @override
  void didUpdateWidget(AnimatedPPIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.showAnimation && !oldWidget.showAnimation) {
      _animationController.reset();
      _generateGlitters();
      _animationController.forward();
    }
  }
  
  void _generateGlitters() {
    final random = Random();
    _glitters = List.generate(15, (index) {
      return {
        'size': 1.5 + random.nextDouble() * 2.0,
        'offsetX': -12.0 + random.nextDouble() * 24.0,
        'offsetY': -12.0 + random.nextDouble() * 24.0,
        'delay': random.nextDouble() * 0.7,
        'duration': 0.3 + random.nextDouble() * 0.7,
      };
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: 30,
          height: 30,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Base coin with scale and slight rotation
              Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotateAnimation.value,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFE566), Color(0xFFFFD700)],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFFFFD700),
                          blurRadius: 1,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Color(0xFFFFD700),
                          blurRadius: 6,
                          spreadRadius: -1,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white,
                        width: 0.8,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '✦',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Glitter particles with staggered appearance
              if (widget.showAnimation)
                ...List.generate(_glitters.length, (index) {
                  final glitter = _glitters[index];
                  final delay = glitter['delay'] as double;
                  final duration = glitter['duration'] as double;
                  
                  // Calculate the opacity based on animation progress and delay
                  double opacity = 0.0;
                  if (_animationController.value > delay) {
                    final relativeProgress = (_animationController.value - delay) / duration;
                    // Create a fade in/out effect
                    if (relativeProgress < 0.5) {
                      opacity = relativeProgress * 2.0;
                    } else {
                      opacity = (1.0 - relativeProgress) * 2.0;
                    }
                    // Clamp to valid range
                    opacity = opacity.clamp(0.0, 1.0);
                  }
                  
                  return Positioned(
                    left: 12 + (glitter['offsetX'] as double),
                    top: 12 + (glitter['offsetY'] as double),
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: glitter['size'] as double,
                        height: glitter['size'] as double,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFFFFD700),
                              blurRadius: 4,
                              spreadRadius: 0.5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
} 