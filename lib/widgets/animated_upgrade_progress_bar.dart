import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedUpgradeProgressBar extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final Duration remainingTime;
  final Color primaryColor;
  final bool showGlow;
  final bool enablePulse;
  
  const AnimatedUpgradeProgressBar({
    Key? key,
    required this.progress,
    required this.remainingTime,
    this.primaryColor = Colors.orange,
    this.showGlow = true,
    this.enablePulse = true,
  }) : super(key: key);

  @override
  _AnimatedUpgradeProgressBarState createState() => _AnimatedUpgradeProgressBarState();
}

class _AnimatedUpgradeProgressBarState extends State<AnimatedUpgradeProgressBar>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  double _lastProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _lastProgress = widget.progress;
    
    // Progress animation controller - smooth transitions
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Shimmer effect controller - continuous
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    // Pulse effect controller - for near-completion
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: _lastProgress,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    _progressController.forward();
  }

  @override
  void didUpdateWidget(AnimatedUpgradeProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Animate progress changes smoothly
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: _lastProgress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ));
      
      _progressController.forward(from: 0.0);
      _lastProgress = widget.progress;
    }
    
    // Handle pulse animation when near completion
    if (widget.enablePulse && widget.progress > 0.9 && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (widget.progress <= 0.9 && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Color _getProgressColor(double progress) {
    // Color transition: orange (0%) -> yellow (50%) -> green (100%)
    if (progress < 0.5) {
      // Orange to yellow
      return Color.lerp(
        Colors.orange.shade600,
        Colors.yellow.shade600,
        progress * 2,
      )!;
    } else {
      // Yellow to green
      return Color.lerp(
        Colors.yellow.shade600,
        Colors.green.shade600,
        (progress - 0.5) * 2,
      )!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _progressController,
        _shimmerController,
        _pulseController,
      ]),
      builder: (context, child) {
        final currentProgress = _progressAnimation.value;
        final progressColor = _getProgressColor(currentProgress);
        final pulseScale = widget.enablePulse && currentProgress > 0.9
            ? 1.0 + (_pulseController.value * 0.05)
            : 1.0;

        return Transform.scale(
          scale: pulseScale,
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              boxShadow: widget.showGlow && currentProgress > 0
                  ? [
                      BoxShadow(
                        color: progressColor.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  // Background
                  Container(
                    width: double.infinity,
                    height: 8,
                    color: Colors.grey.shade200,
                  ),
                  
                  // Progress fill
                  FractionallySizedBox(
                    widthFactor: currentProgress.clamp(0.0, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            progressColor,
                            progressColor.withOpacity(0.8),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                  
                  // Shimmer overlay
                  if (currentProgress > 0 && currentProgress < 1.0)
                    FractionallySizedBox(
                      widthFactor: currentProgress.clamp(0.0, 1.0),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.3),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                            begin: Alignment(-1.0 + (_shimmerController.value * 2), 0),
                            end: Alignment(1.0 + (_shimmerController.value * 2), 0),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
