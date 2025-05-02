import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A widget that displays the Platinum Spire Trophy with animation effects
class PlatinumSpireTrophy extends StatefulWidget {
  final double size;
  final bool showEmergenceAnimation;
  final VoidCallback? onTap;
  final String? username;
  
  const PlatinumSpireTrophy({
    Key? key,
    this.size = 120.0,
    this.showEmergenceAnimation = false,
    this.onTap,
    this.username,
  }) : super(key: key);

  @override
  State<PlatinumSpireTrophy> createState() => _PlatinumSpireTrophyState();
}

class _PlatinumSpireTrophyState extends State<PlatinumSpireTrophy> with TickerProviderStateMixin {
  late AnimationController _emergenceController;
  late Animation<double> _emergenceAnimation;
  
  // Store animation controllers
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  
  // For continuous particle effects after emergence
  late ValueNotifier<double> _particleAnimationValue = ValueNotifier(0.0);
  
  // Flag to track if image loaded successfully
  bool _imageLoadError = false;
  
  @override
  void initState() {
    super.initState();
    
    // Setup emergence animation controller
    _emergenceController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    _emergenceAnimation = CurvedAnimation(
      parent: _emergenceController,
      curve: Curves.easeOutCubic,
    );
    
    // Listen to changes for animation rebuilds
    _emergenceAnimation.addListener(() {
      setState(() {});
    });
    
    // Initialize particle controller
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    
    // Initialize pulse controller for the glow effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Initialize shimmer controller for the reflective effects
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    // Start animations
    _pulseController.repeat(reverse: true);
    _shimmerController.repeat(reverse: false);
    _startParticleAnimation();
    
    // If emergence animation is requested, run it
    if (widget.showEmergenceAnimation) {
      _playEmergenceAnimation();
    } else {
      // Otherwise, set to fully emerged state
      _emergenceController.value = 1.0;
    }
  }
  
  @override
  void didUpdateWidget(PlatinumSpireTrophy oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.showEmergenceAnimation && !oldWidget.showEmergenceAnimation) {
      _playEmergenceAnimation();
    }
  }
  
  void _playEmergenceAnimation() {
    _emergenceController.reset();
    _emergenceController.forward();
  }
  
  void _startParticleAnimation() {
    // Use the already created particle controller
    _particleController.repeat(); // Start repeating animation
    
    _particleController.addListener(() {
      // Create a continuous oscillation
      _particleAnimationValue.value = _particleController.value * 100; // Scale up to get good variation
    });
  }
  
  // Handle tap on the trophy
  void _handleTap() {
    // If emergence animation is still running, don't respond to taps
    if (_emergenceController.isAnimating && _emergenceController.value < 0.8) {
      return;
    }
    
    // Create a brief pulse animation when tapped
    double currentValue = _emergenceController.value;
    _emergenceController.animateTo(0.8, duration: const Duration(milliseconds: 150))
      .then((_) => _emergenceController.animateTo(currentValue, duration: const Duration(milliseconds: 300)));
    
    // Also pulse the glow effect
    _pulseController.forward(from: 0.0);
    
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }
  
  @override
  void dispose() {
    // Dispose all controllers properly
    _emergenceController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Calculate appropriate dimensions to prevent overflow
    final trophyWidth = widget.size * 1.1;
    
    return GestureDetector(
      onTap: _handleTap,
      child: SizedBox(
        width: widget.size * 1.2,
        height: widget.size * 1.7,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background glow
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: widget.size * 1.2,
                  height: widget.size * 1.2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFD700).withOpacity(0.1 + _pulseController.value * 0.2),
                        Colors.transparent,
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                );
              },
            ),
            
            // Vertical emergence animation
            AnimatedBuilder(
              animation: _emergenceAnimation, 
              builder: (context, child) {
                final emergenceOffset = (1.0 - _emergenceAnimation.value) * widget.size * 0.7;
                
                return Transform.translate(
                  offset: Offset(0, emergenceOffset),
                  child: child,
                );
              },
              child: Center(
                child: Container(
                  width: widget.size * 1.1,
                  height: widget.size * 1.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.size * 0.15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Trophy content
                      ClipRRect(
                        borderRadius: BorderRadius.circular(widget.size * 0.15),
                        child: _imageLoadError 
                            ? _buildFallbackTrophy() 
                            : Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Main image
                                  Image.asset(
                                    'images/platinum_unlocks/platinum_spire.jpg',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      _imageLoadError = true;
                                      return _buildFallbackTrophy();
                                    },
                                  ),
                                  
                                  // Overlay effects
                                  AnimatedBuilder(
                                    animation: _shimmerController,
                                    builder: (context, child) {
                                      return Positioned(
                                        left: -widget.size * 0.5 + (widget.size * 2 * _shimmerController.value),
                                        top: 0,
                                        bottom: 0,
                                        width: widget.size * 0.5,
                                        child: Transform.rotate(
                                          angle: -math.pi / 4,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.white.withOpacity(0),
                                                  Colors.white.withOpacity(0.4),
                                                  Colors.white.withOpacity(0),
                                                ],
                                                stops: const [0.0, 0.5, 1.0],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                      ),
                      
                      // Platinum frame
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(widget.size * 0.15),
                          border: Border.all(
                            width: 5,
                            color: const Color(0xFFF5F5F5),
                          ),
                          // Inner platinum gradient
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.05),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Title plate at bottom
            AnimatedBuilder(
              animation: _emergenceAnimation,
              builder: (context, child) {
                final titleOffset = (1.0 - _emergenceAnimation.value) * widget.size * 0.5;
                return Positioned(
                  bottom: widget.size * 0.05 - titleOffset,
                  left: widget.size * 0.1,
                  right: widget.size * 0.1,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 6, 
                      horizontal: widget.size * 0.05,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E4E2),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFFFFD700),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.username ?? "TYCOON",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: widget.size * 0.09,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                );
              },
            ),
            
            // Particle effects
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ParticleEffectPainter(
                    animationValue: _particleController.value,
                    isEmerging: _emergenceAnimation.value < 1.0,
                    emergenceValue: _emergenceAnimation.value,
                  ),
                  size: Size(widget.size * 1.2, widget.size * 1.7),
                );
              },
            ),
            
            // Top crown effect
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return Positioned(
                  top: widget.size * 0.05,
                  child: Container(
                    width: widget.size * 0.5,
                    height: widget.size * 0.15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFFD700).withOpacity(0.6 + _pulseController.value * 0.2),
                          const Color(0xFFFFD700).withOpacity(0.1),
                          Colors.transparent,
                        ],
                        stops: const [0.1, 0.3, 1.0],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // Fallback trophy display when image fails to load
  Widget _buildFallbackTrophy() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFE5E4E2),
            const Color(0xFFD1D0CE),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events,
              color: const Color(0xFFFFD700),
              size: widget.size * 0.4,
            ),
            const SizedBox(height: 10),
            Text(
              widget.username ?? "Trophy",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: widget.size * 0.12,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 2,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for particle effects around the trophy
class _ParticleEffectPainter extends CustomPainter {
  final double animationValue;
  final bool isEmerging;
  final double emergenceValue;
  
  _ParticleEffectPainter({
    required this.animationValue,
    this.isEmerging = false,
    this.emergenceValue = 1.0,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Fixed seed for consistency
    final particleCount = isEmerging ? 30 : 15;
    
    // Gold accent color with opacity
    final goldColor = const Color(0xFFFFD700);
    final platinumColor = const Color(0xFFE5E4E2);
    final sparkleColor = Colors.white;
    
    for (int i = 0; i < particleCount; i++) {
      // Particle parameters
      final particleSize = 1.0 + random.nextDouble() * 3.0;
      
      // Position based on sine waves and random placement
      final angle = 2 * math.pi * i / particleCount + animationValue * math.pi * 2;
      final radius = size.width * (0.3 + 0.15 * math.sin(animationValue * math.pi * 2 + i));
      
      final xOffset = math.cos(angle) * radius;
      final yOffset = math.sin(angle) * radius + size.height * 0.4;
      
      // Opacity based on animation
      double opacity = 0.3 + 0.3 * math.sin(animationValue * math.pi * 2 + i * 0.5);
      
      // If emerging, add extra particles below
      if (isEmerging) {
        opacity *= (1.0 - emergenceValue);
        
        // Only draw rising particles during emergence
        if (random.nextBool()) {
          final riseParticleSize = 1.5 + random.nextDouble() * 3.0;
          final riseX = (random.nextDouble() - 0.5) * size.width * 0.8;
          final riseY = size.height * (0.6 + 0.3 * random.nextDouble() - emergenceValue * 0.5);
          
          final riseOpacity = (1.0 - emergenceValue) * (0.4 + random.nextDouble() * 0.3);
          final riseColor = (i % 3 == 0) ? goldColor : platinumColor;
          
          final risePaint = Paint()
            ..color = riseColor.withOpacity(riseOpacity)
            ..style = PaintingStyle.fill;
            
          canvas.drawCircle(
            Offset(size.width * 0.5 + riseX, riseY),
            riseParticleSize,
            risePaint,
          );
        }
      }
      
      // Particle color alternates between gold, platinum and sparkle white
      Color color;
      if (i % 3 == 0) {
        color = goldColor;
      } else if (i % 3 == 1) {
        color = platinumColor;
      } else {
        color = sparkleColor;
      }
      
      final particlePaint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      
      // Draw sparkle effect for some particles
      if (i % 5 == 0) {
        final sparkleSize = particleSize * 2;
        final x = size.width * 0.5 + xOffset;
        final y = yOffset;
        
        // Draw a 4-point star
        final path = Path();
        path.moveTo(x, y - sparkleSize);
        path.lineTo(x + sparkleSize * 0.3, y - sparkleSize * 0.3);
        path.lineTo(x + sparkleSize, y);
        path.lineTo(x + sparkleSize * 0.3, y + sparkleSize * 0.3);
        path.lineTo(x, y + sparkleSize);
        path.lineTo(x - sparkleSize * 0.3, y + sparkleSize * 0.3);
        path.lineTo(x - sparkleSize, y);
        path.lineTo(x - sparkleSize * 0.3, y - sparkleSize * 0.3);
        path.close();
        
        canvas.drawPath(path, particlePaint);
      } else {
        // Draw regular circle particles
        canvas.drawCircle(
          Offset(size.width * 0.5 + xOffset, yOffset),
          particleSize,
          particlePaint,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant _ParticleEffectPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.isEmerging != isEmerging ||
           oldDelegate.emergenceValue != emergenceValue;
  }
} 