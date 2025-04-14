import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'main_screen.dart';
import '../utils/matrix4_fallback.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoSizeAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _textOpacityAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize the animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    // Logo size animation: grow from 0.5 to 1.0 scale
    _logoSizeAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    // Logo opacity animation: fade in from 0.0 to 1.0
    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
    
    // Text opacity animation: fade in from 0.0 to 1.0, but start later
    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
      ),
    );
    
    // Start the animation
    _controller.forward();
    
    // Navigate to main screen after delay
    Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(animation);
              return FadeTransition(opacity: fadeAnimation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  // Logo builder with Matrix4Fallback utility
  Widget _buildLogoWithFallback() {
    return Matrix4Fallback.scale(
      scale: _logoSizeAnimation.value,
      child: SvgPicture.asset(
        'assets/empire_logo.svg',
        width: 180,
        height: 180,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo
                Opacity(
                  opacity: _logoOpacityAnimation.value,
                  child: _buildLogoWithFallback(),
                ),
                const SizedBox(height: 40),
                
                // Animated Text
                Opacity(
                  opacity: _textOpacityAnimation.value,
                  child: Column(
                    children: [
                      Text(
                        'EMPIRE TYCOON',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E7D32),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Build Your Global Business Empire',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Progress Indicator (Only visible near the end)
                Opacity(
                  opacity: _controller.value > 0.7 ? 1.0 : 0.0,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        color: const Color(0xFF2E7D32),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}