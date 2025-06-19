import 'package:flutter/material.dart';
import 'dart:math' as math;

class EmpireLoadingScreen extends StatefulWidget {
  final String? loadingText;
  final String? subText;
  
  const EmpireLoadingScreen({
    Key? key,
    this.loadingText,
    this.subText,
  }) : super(key: key);

  @override
  State<EmpireLoadingScreen> createState() => _EmpireLoadingScreenState();
}

class _EmpireLoadingScreenState extends State<EmpireLoadingScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _logoController;
  late AnimationController _orbitalController;
  late AnimationController _progressController;
  late AnimationController _glowController;
  late AnimationController _textController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _orbitalRotation;
  late Animation<double> _progressAnimation;
  late Animation<double> _glowPulse;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    
    // Refined, professional animations
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Subtle orbital animation for floating elements
    _orbitalController = AnimationController(
      duration: const Duration(milliseconds: 8000),
      vsync: this,
    );
    
    // Smooth progress animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    // Elegant glow effect
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Professional text entrance
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Logo animations - more subtle and elegant
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    // Subtle orbital rotation for premium floating elements
    _orbitalRotation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _orbitalController,
        curve: Curves.linear,
      ),
    );
    
    // Smooth progress animation
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOutCubic,
      ),
    );
    
    // Refined glow effect
    _glowPulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Professional text animations
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    
    // Start refined animation sequence
    _startAnimations();
  }
  
  void _startAnimations() {
    // Start with logo entrance
    _logoController.forward();
    
    // Start text animation after short delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _textController.forward();
    });
    
    // Start subtle orbital elements
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _orbitalController.repeat();
      }
    });
    
    // Start progress animation
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _progressController.forward();
    });
    
    // Start elegant glow effect
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        _glowController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _orbitalController.dispose();
    _progressController.dispose();
    _glowController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1A2E), // Deep navy blue
              Color(0xFF16213E), // Rich dark blue
              Color(0xFF1A252F), // Sophisticated dark
            ],
          ),
        ),
        child: Stack(
          children: [
            // Sophisticated background pattern
            _buildRefinedBackground(),
            
            // Subtle orbital elements
            _buildOrbitalElements(),
            
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Enhanced logo presentation
                  _buildEnhancedLogo(),
                  
                  const SizedBox(height: 60),
                  
                  // Professional text
                  _buildProfessionalText(),
                  
                  const SizedBox(height: 80),
                  
                  // Refined progress section
                  _buildRefinedProgress(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRefinedBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: RefinedBackgroundPainter(),
      ),
    );
  }
  
  Widget _buildOrbitalElements() {
    return AnimatedBuilder(
      animation: _orbitalRotation,
      builder: (context, child) {
        return Stack(
          children: [
            // Subtle floating geometric elements instead of coins
            ...List.generate(4, (index) {
              final angle = _orbitalRotation.value + (index * math.pi / 2);
              final radius = 120.0 + (index * 15.0);
              final centerX = MediaQuery.of(context).size.width / 2;
              final centerY = MediaQuery.of(context).size.height / 2;
              
              return Positioned(
                left: centerX + math.cos(angle) * radius - 8,
                top: centerY + math.sin(angle) * radius - 8,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFD4AF37),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
  
  Widget _buildEnhancedLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoController, _glowController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScale.value,
          child: Opacity(
            opacity: _logoOpacity.value,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  // Sophisticated glow effect
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.15 * _glowPulse.value),
                    blurRadius: 40 * _glowPulse.value,
                    spreadRadius: 8 * _glowPulse.value,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipOval(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFFFFFFFF),
                        Color(0xFFF8F8F8),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Image.asset(
                      'assets/Enhanced Empire Tycoon App Icon.png',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
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
  
  Widget _buildProfessionalText() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return SlideTransition(
          position: _textSlide,
          child: FadeTransition(
            opacity: _textFade,
            child: Column(
              children: [
                Text(
                  widget.loadingText ?? 'EMPIRE TYCOON',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    fontFamily: 'Roboto',
                    color: Colors.white,
                    letterSpacing: 4.0,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 2),
                        blurRadius: 8,
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 60,
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Color(0xFFD4AF37), Colors.transparent],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.subText ?? 'Building Your Global Business Empire',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Roboto',
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildRefinedProgress() {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        return Column(
          children: [
            // Elegant progress bar
            Container(
              width: 200,
              height: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                color: Colors.white.withValues(alpha: 0.1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1),
                child: LinearProgressIndicator(
                  value: _progressAnimation.value,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Refined loading indicator
            SizedBox(
              width: 40,
              height: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(3, (index) {
                  final delay = index * 0.2;
                  final progress = (_progressAnimation.value + delay) % 1.0;
                  
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.lerp(
                        Colors.white.withValues(alpha: 0.2),
                        const Color(0xFFD4AF37),
                        progress,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }
}

class RefinedBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Subtle geometric grid pattern
    final gridSize = 60.0;
    
    // Vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // Horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Subtle corner accents
    final accentPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Top corners
    canvas.drawLine(Offset(0, 0), Offset(40, 0), accentPaint);
    canvas.drawLine(Offset(0, 0), Offset(0, 40), accentPaint);
    canvas.drawLine(Offset(size.width - 40, 0), Offset(size.width, 0), accentPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, 40), accentPaint);
    
    // Bottom corners
    canvas.drawLine(Offset(0, size.height - 40), Offset(0, size.height), accentPaint);
    canvas.drawLine(Offset(0, size.height), Offset(40, size.height), accentPaint);
    canvas.drawLine(Offset(size.width, size.height - 40), Offset(size.width, size.height), accentPaint);
    canvas.drawLine(Offset(size.width - 40, size.height), Offset(size.width, size.height), accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 