import 'dart:async';
import 'package:flutter/material.dart';

class PremiumPurchaseNotification extends StatefulWidget {
  final Function onDismiss;

  const PremiumPurchaseNotification({
    Key? key,
    required this.onDismiss,
  }) : super(key: key);

  @override
  _PremiumPurchaseNotificationState createState() =>
      _PremiumPurchaseNotificationState();
}

class _PremiumPurchaseNotificationState
    extends State<PremiumPurchaseNotification> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();

    // Slide animation controller (for entry/exit)
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -2.0), // Start above the screen
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack, // Fun bounce effect
    ));

    // Fade animation controller (for exit)
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Start entry animation
    _slideController.forward();

    // Start timer for auto-dismissal
    _startDismissTimer();
  }

  void _startDismissTimer() {
    _dismissTimer?.cancel(); // Cancel any existing timer
    _dismissTimer = Timer(const Duration(seconds: 5), _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    _dismissTimer?.cancel();
    // Start fade-out animation
    _fadeController.forward().then((_) {
      // After fade-out, slide up and call dismiss callback
      _slideController.reverse().then((_) {
         if (mounted) {
           widget.onDismiss();
         }
      });
    });
  }


  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation, // Use fade for exit
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade600, Colors.purple.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon (Star or Crown for Premium)
              const Icon(
                Icons.star_rounded, // Premium icon
                color: Color(0xFFFFD700),
                size: 32,
                shadows: [ Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(0,1)) ],
              ),
              const SizedBox(width: 16),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Premium Activated!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // P Reward Section
                    Row(
                      children: [
                         Container(
                           width: 16,
                           height: 16,
                           decoration: BoxDecoration(
                             shape: BoxShape.circle,
                             color: const Color(0xFFFFD700),
                             boxShadow: [
                               BoxShadow(
                                 color: const Color(0xFFFFD700).withOpacity(0.6),
                                 blurRadius: 3,
                               ),
                             ],
                           ),
                           child: const Center(
                             child: Text(
                               '✦',
                               style: TextStyle(
                                 fontSize: 10,
                                 color: Colors.white,
                                 fontWeight: FontWeight.bold,
                                 height: 1.0,
                               ),
                             ),
                           ),
                         ),
                         const SizedBox(width: 6),
                         Text(
                           '+1500 P Bonus!',
                           style: TextStyle(
                             fontSize: 14,
                             fontWeight: FontWeight.w600,
                             color: Colors.yellow.shade100,
                           ),
                         ),
                      ],
                    ),
                  ],
                ),
              ),
              // Close Button
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: _dismiss,
                color: Colors.white70,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Dismiss',
              ),
            ],
          ),
        ),
      ),
    );
  }
} 