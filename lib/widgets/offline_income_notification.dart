import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:async';
import '../models/game_state.dart';
import '../services/game_service.dart';
import '../services/admob_service.dart';
import '../utils/number_formatter.dart';
import 'package:flutter/foundation.dart';

class OfflineIncomeNotification extends StatefulWidget {
  const OfflineIncomeNotification({Key? key}) : super(key: key);

  @override
  State<OfflineIncomeNotification> createState() => _OfflineIncomeNotificationState();
}

class _OfflineIncomeNotificationState extends State<OfflineIncomeNotification> 
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _iconBounceController;
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _iconBounceAnimation;
  
  bool _soundPlayed = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }
  
  void _setupAnimations() {
    // Slide animation for entrance
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    
    // Gentle pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    // Subtle shimmer effect
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    
    // Icon bounce for excitement
    _iconBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _shimmerAnimation = Tween<double>(
      begin: -1.5,
      end: 1.5,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.linear,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
    ));
    
    _iconBounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _iconBounceController,
      curve: Curves.elasticOut,
    ));
  }
  
  void _startAnimations() {
    _slideController.forward();
    
    // Start continuous animations with delays
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_disposed) {
        _pulseController.repeat(reverse: true);
      }
    });
    
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!_disposed) {
        _shimmerController.repeat();
      }
    });
    
    // Periodic icon bounce for excitement
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!_disposed) {
        _iconBounceController.forward().then((_) {
          if (!_disposed) {
            _iconBounceController.reverse();
            Timer.periodic(const Duration(seconds: 4), (timer) {
              if (_disposed) {
                timer.cancel();
                return;
              }
              _iconBounceController.forward().then((_) {
                if (!_disposed) _iconBounceController.reverse();
              });
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _slideController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _iconBounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final gameService = Provider.of<GameService>(context, listen: false);
    
    // Play sound once when notification appears
    if (!_soundPlayed) {
      gameService.playOfflineIncomeSound();
      _soundPlayed = true;
    }
    
    // Calculate the display amount (doubled if ad watched)
    final double baseAmount = gameState.offlineIncome;
    final double displayAmount = gameState.offlineIncomeAdWatched ? baseAmount * 2 : baseAmount;
    final formattedIncome = NumberFormatter.formatCompact(displayAmount);
    
    // Format the time period
    final String timePeriod = _formatTimePeriod(gameState);
    
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: gameState.offlineIncomeAdWatched 
                            ? Colors.amber.shade400.withOpacity(0.6)
                            : const Color(0xFF4CAF50).withOpacity(0.3),
                        width: gameState.offlineIncomeAdWatched ? 2.0 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: gameState.offlineIncomeAdWatched 
                              ? Colors.amber.shade300.withOpacity(0.3)
                              : const Color(0xFF4CAF50).withOpacity(0.15),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          // Enhanced gradient background when bonus is active
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: gameState.offlineIncomeAdWatched 
                                    ? [
                                        const Color(0xFFFFFDF7),
                                        Colors.white,
                                        const Color(0xFFFFF8E1),
                                      ]
                                    : [
                                        const Color(0xFFF8FFF8),
                                        Colors.white,
                                        const Color(0xFFF0F8F0),
                                      ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                          
                          // Enhanced shimmer overlay when bonus is active
                          AnimatedBuilder(
                            animation: _shimmerAnimation,
                            builder: (context, child) {
                              return Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment(_shimmerAnimation.value - 0.5, -0.5),
                                      end: Alignment(_shimmerAnimation.value + 0.5, 0.5),
                                      colors: gameState.offlineIncomeAdWatched 
                                          ? [
                                              Colors.transparent,
                                              Colors.amber.shade200.withOpacity(0.3),
                                              Colors.transparent,
                                            ]
                                          : [
                                              Colors.transparent,
                                              const Color(0xFF4CAF50).withOpacity(0.1),
                                              Colors.transparent,
                                            ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          // Content
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Header row - clean and compact
                                Row(
                                  children: [
                                    // Animated icon with bounce
                                    ScaleTransition(
                                      scale: _iconBounceAnimation,
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: gameState.offlineIncomeAdWatched 
                                                ? [
                                                    Colors.amber.shade500,
                                                    Colors.amber.shade600,
                                                  ]
                                                : [
                                                    const Color(0xFF4CAF50),
                                                    const Color(0xFF45A049),
                                                  ],
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: gameState.offlineIncomeAdWatched 
                                                  ? Colors.amber.shade300.withOpacity(0.4)
                                                  : const Color(0xFF4CAF50).withOpacity(0.3),
                                              blurRadius: 8,
                                              spreadRadius: 0,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          gameState.offlineIncomeAdWatched 
                                              ? Icons.stars 
                                              : Icons.account_balance,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    
                                    // Welcome back text
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                gameState.offlineIncomeAdWatched 
                                                    ? 'BONUS ACTIVE!'
                                                    : 'WELCOME BACK',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: gameState.offlineIncomeAdWatched 
                                                      ? Colors.amber.shade600
                                                      : const Color(0xFF4CAF50),
                                                  letterSpacing: 0.8,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                Icons.star,
                                                color: Colors.amber.shade400,
                                                size: 12,
                                              ),
                                            ],
                                          ),
                                          Text(
                                            gameState.offlineIncomeAdWatched 
                                                ? 'Double Offline Income'
                                                : 'Offline Income',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: gameState.offlineIncomeAdWatched 
                                                  ? Colors.amber.shade800
                                                  : const Color(0xFF2E7D32),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Close button
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () => gameState.dismissOfflineIncomeNotification(),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.grey.shade500,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Earnings display - mobile optimized
                                Row(
                                  children: [
                                    // Income amount section
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: gameState.offlineIncomeAdWatched 
                                              ? const Color(0xFFFFFDF7)
                                              : const Color(0xFFF8FFF8),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: gameState.offlineIncomeAdWatched 
                                                ? Colors.amber.shade300.withOpacity(0.4)
                                                : const Color(0xFF4CAF50).withOpacity(0.2),
                                            width: gameState.offlineIncomeAdWatched ? 1.5 : 1,
                                          ),
                                          boxShadow: gameState.offlineIncomeAdWatched 
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.amber.shade200.withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'You earned',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                if (gameState.offlineIncomeAdWatched) ...[
                                                  const SizedBox(width: 4),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.amber.shade400,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: const Text(
                                                      '2x',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: gameState.offlineIncomeAdWatched 
                                                          ? [
                                                              Colors.amber.shade500,
                                                              Colors.amber.shade600,
                                                            ]
                                                          : [
                                                              const Color(0xFF4CAF50),
                                                              const Color(0xFF45A049),
                                                            ],
                                                    ),
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: gameState.offlineIncomeAdWatched 
                                                            ? Colors.amber.shade300.withOpacity(0.4)
                                                            : const Color(0xFF4CAF50).withOpacity(0.3),
                                                        blurRadius: 4,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Center(
                                                    child: Text(
                                                      '\$',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    formattedIncome,
                                                    style: TextStyle(
                                                      fontSize: 22,
                                                      fontWeight: FontWeight.bold,
                                                      color: gameState.offlineIncomeAdWatched 
                                                          ? Colors.amber.shade800
                                                          : const Color(0xFF2E7D32),
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 12,
                                                  color: Colors.grey.shade500,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'in $timePeriod',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    
                                    const SizedBox(width: 12),
                                    
                                    // Action buttons - vertical stack
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        children: [
                                          // Watch Ad Button
                                          SizedBox(
                                            width: double.infinity,
                                            height: 36,
                                            child: ElevatedButton(
                                              onPressed: gameState.offlineIncomeAdWatched 
                                                  ? null 
                                                  : () {
                                                      final adMobService = Provider.of<AdMobService>(context, listen: false);
                                                      
                                                      // Check if premium user should skip ads
                                                      if (gameState.isPremium) {
                                                        // Premium users skip ads and get 2x boost immediately
                                                        gameState.setOfflineIncomeAdWatched(true);
                                                        return;
                                                      }
                                                      
                                                      // Show AdMob rewarded ad for offline income boost
                                                      adMobService.showOfflineIncomeBoostAd(
                                                        onRewardEarned: (String rewardType) {
                                                          // Verify we received the correct reward type
                                                          if (rewardType == 'OfflineIncomeBoost') {
                                                            // User successfully watched the ad
                                                            gameState.setOfflineIncomeAdWatched(true);
                                                          } else {
                                                            print('Warning: Expected OfflineIncomeBoost reward but received: $rewardType');
                                                          }
                                                        },
                                                        onAdFailure: () async {
                                                          // Ad failed to show, show error message
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(
                                                              content: Text('Ad not available. Please try again later.'),
                                                              duration: Duration(seconds: 3),
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: gameState.offlineIncomeAdWatched 
                                                    ? Colors.grey.shade300
                                                    : const Color(0xFFFF9800),
                                                foregroundColor: gameState.offlineIncomeAdWatched 
                                                    ? Colors.grey.shade600
                                                    : Colors.white,
                                                elevation: gameState.offlineIncomeAdWatched ? 0 : 2,
                                                shadowColor: const Color(0xFFFF9800).withOpacity(0.3),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                padding: EdgeInsets.zero,
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    gameState.offlineIncomeAdWatched 
                                                        ? Icons.check_circle
                                                        : Icons.play_circle_outline, 
                                                    size: 14
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    gameState.offlineIncomeAdWatched 
                                                        ? 'AD WATCHED'
                                                        : '2x AD',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          
                                          const SizedBox(height: 8),
                                          
                                          // Collect Button
                                          SizedBox(
                                            width: double.infinity,
                                            height: 36,
                                            child: ElevatedButton(
                                              onPressed: () => gameState.collectOfflineIncome(),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: gameState.offlineIncomeAdWatched 
                                                    ? Colors.amber.shade500
                                                    : const Color(0xFF4CAF50),
                                                foregroundColor: Colors.white,
                                                elevation: 2,
                                                shadowColor: gameState.offlineIncomeAdWatched 
                                                    ? Colors.amber.shade300.withOpacity(0.4)
                                                    : const Color(0xFF4CAF50).withOpacity(0.3),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                padding: EdgeInsets.zero,
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(Icons.download, size: 14),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    gameState.offlineIncomeAdWatched ? 'CLAIM 2x' : 'CLAIM',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                // Bonus banner - only show if ad not watched
                                if (!gameState.offlineIncomeAdWatched) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.amber.shade400,
                                          Colors.amber.shade500,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.amber.shade300.withOpacity(0.4),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'Watch AD for 2x bonus!',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  // Helper method to format time period string - compact format for mobile
  String _formatTimePeriod(GameState gameState) {
    if (gameState.offlineIncomeStartTime == null || gameState.offlineIncomeEndTime == null) {
      return 'away';
    }
    
    // Get the actual duration between start and end time
    final actualDuration = gameState.offlineIncomeEndTime!.difference(gameState.offlineIncomeStartTime!);
    
    // Apply the 4-hour cap that's used in the income calculation
    // This matches the MAX_OFFLINE_SECONDS constant in GameStateOfflineIncome
    final int maxOfflineSeconds = 4 * 60 * 60; // 4 hours in seconds
    final int cappedSeconds = min(actualDuration.inSeconds, maxOfflineSeconds);
    
    // Create a capped duration
    final cappedDuration = Duration(seconds: cappedSeconds);
    
    // Format the capped duration - compact format for mobile
    if (cappedDuration.inMinutes < 60) {
      return '${cappedDuration.inMinutes}m';
    } else {
      final hours = cappedDuration.inHours;
      final minutes = cappedDuration.inMinutes % 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
  }
} 