import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/achievement.dart';
import '../models/game_state.dart';
import '../utils/number_formatter.dart';
import '../models/achievement_data.dart';
import '../services/game_service.dart';

class AchievementNotification extends StatefulWidget {
  final Achievement achievement;
  final Function onDismiss;
  final GameService gameService;

  const AchievementNotification({
    Key? key,
    required this.achievement,
    required this.onDismiss,
    required this.gameService,
  }) : super(key: key);

  @override
  _AchievementNotificationState createState() => _AchievementNotificationState();
}

class _AchievementNotificationState extends State<AchievementNotification> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _ppFadeAnimation;
  late Animation<Offset> _ppSlideAnimation;
  late Animation<double> _ppScaleAnimation;
  bool _showPpAnimation = false;
  
  @override
  void initState() {
    super.initState();
    
    _playAchievementSound();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
    
    // PP reward animations - MODIFIED
    _ppFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate( // Fade OUT
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut), // Fade out during the second half of travel
      ),
    );
    
    _ppSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.0), // Start at the Positioned location
      end: const Offset(0.5, -4.1), // Move towards top-right (adjust as needed)
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut), // Travel lasts longer
      ),
    );
    
    _ppScaleAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut), // Scale down during travel
      ),
    );
    
    _animationController.forward();
    
    // Trigger PP animation after the achievement appears
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showPpAnimation = true;
        });
      }
    });
    
    // Dismiss after animation completes
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismiss();
      }
    });
  }
  
  void _playAchievementSound() {
    try {
      switch (widget.achievement.rarity) {
        case AchievementRarity.milestone:
          widget.gameService.soundManager.playAchievementMilestoneSound();
          break;
        case AchievementRarity.rare:
          widget.gameService.soundManager.playAchievementRareSound();
          break;
        case AchievementRarity.basic:
        default:
          widget.gameService.soundManager.playAchievementBasicSound();
          break;
      }
    } catch (e) {
      print("Error playing achievement sound: $e");
      try {
        widget.gameService.soundManager.playFeedbackSuccessSound();
      } catch (e) {
        print("Error playing fallback success sound: $e");
      }
    }
  }
  
  void _dismiss() {
    _animationController.reverse().then((_) {
      widget.onDismiss();
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rarityColors = _getRarityColors(widget.achievement.rarity);
    
    return Stack(
      children: [
        SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: rarityColors['backgroundColor'],
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: rarityColors['shadowColor']!,
                      blurRadius: rarityColors['blurRadius'] as double,
                      spreadRadius: rarityColors['spreadRadius'] as double,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(
                    color: rarityColors['borderColor']!,
                    width: rarityColors['borderWidth'] as double,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: rarityColors['iconBackgroundColor'],
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (widget.achievement.rarity == AchievementRarity.milestone)
                            BoxShadow(
                              color: rarityColors['iconGlowColor']!,
                              blurRadius: 8.0,
                              spreadRadius: 2.0,
                            ),
                        ],
                      ),
                      child: Icon(
                        widget.achievement.icon,
                        color: rarityColors['iconColor'],
                        size: widget.achievement.rarity == AchievementRarity.milestone ? 28 : 24,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    Expanded(
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Achievement Unlocked!',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: rarityColors['titleColor'],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  
                                  if (widget.achievement.rarity != AchievementRarity.basic)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: rarityColors['badgeColor'],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _getRarityText(widget.achievement.rarity),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: rarityColors['badgeTextColor'],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.achievement.name,
                                style: TextStyle(
                                  fontSize: widget.achievement.rarity == AchievementRarity.milestone ? 18 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: rarityColors['nameColor'],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Padding(
                                padding: const EdgeInsets.only(right: 50.0), 
                                child: Text(
                                  widget.achievement.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: rarityColors['descriptionColor'],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          Positioned(
                            top: 0,
                            right: 0,
                            child: Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFFFD700),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFFD700).withOpacity(0.6),
                                        blurRadius: 3,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '✦',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '+${widget.achievement.ppReward}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: rarityColors['nameColor']?.withOpacity(0.8) ?? Colors.black.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    IconButton(
                      icon: Icon(Icons.close, size: 18),
                      onPressed: _dismiss,
                      color: rarityColors['closeButtonColor'],
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Animated PP reward indicator
        if (_showPpAnimation)
          Positioned(
            top: 20, // Adjusted starting position closer to new PP location
            right: 30, // Adjusted starting position closer to new PP location
            child: SlideTransition(
              position: _ppSlideAnimation,
              child: FadeTransition(
                opacity: _ppFadeAnimation,
                child: ScaleTransition(
                  scale: _ppScaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A).withOpacity(0.85), // Dark background with transparency
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withOpacity(0.8),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFFFD700).withOpacity(0.6), // Gold glow
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Main content
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFFD700), // Solid gold background
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD700).withOpacity(0.6),
                                    blurRadius: 4,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  '✦',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '+${widget.achievement.ppReward} PP!',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 2,
                                    offset: Offset(0.5, 0.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        // Glitter effects (random positions)
                        ...List.generate(8, (index) {
                          final random = Random();
                          final size = 2.0 + random.nextDouble() * 2.0;
                          final top = -15.0 + random.nextDouble() * 50;
                          final left = -15.0 + random.nextDouble() * 80;
                          
                          return Positioned(
                            top: top,
                            left: left,
                            child: AnimatedOpacity(
                              opacity: _fadeAnimation.value * (0.5 + 0.5 * random.nextDouble()),
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                width: size,
                                height: size,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD700).withOpacity(0.8),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        
                        // Radiating rings for extra flair
                        if (_ppFadeAnimation.value > 0.5)
                          Positioned.fill(
                            child: Opacity(
                              opacity: (_ppFadeAnimation.value - 0.5) * 2 * 0.3,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFFFD700),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                        if (_ppFadeAnimation.value > 0.7)
                          Positioned.fill(
                            child: Opacity(
                              opacity: (_ppFadeAnimation.value - 0.7) * 3 * 0.2,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  Map<String, dynamic> _getRarityColors(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.milestone:
        return {
          'backgroundColor': Colors.purple.shade50,
          'borderColor': Colors.amber.shade500,
          'shadowColor': Colors.purple.withOpacity(0.3),
          'blurRadius': 15.0,
          'spreadRadius': 1.0,
          'borderWidth': 2.5,
          'iconBackgroundColor': Colors.amber.shade100,
          'iconColor': Colors.amber.shade800,
          'iconGlowColor': Colors.amber.withOpacity(0.5),
          'titleColor': Colors.purple.shade700,
          'nameColor': Colors.purple.shade900,
          'descriptionColor': Colors.grey.shade800,
          'closeButtonColor': Colors.grey.shade600,
          'badgeColor': Colors.amber.shade400,
          'badgeTextColor': Colors.white,
        };
      
      case AchievementRarity.rare:
        return {
          'backgroundColor': Colors.blue.shade50,
          'borderColor': Colors.blue.shade400,
          'shadowColor': Colors.blue.withOpacity(0.2),
          'blurRadius': 12.0,
          'spreadRadius': 1.0,
          'borderWidth': 2.0,
          'iconBackgroundColor': Colors.blue.withOpacity(0.2),
          'iconColor': Colors.blue.shade700,
          'iconGlowColor': Colors.transparent,
          'titleColor': Colors.blue.shade700,
          'nameColor': Colors.blue.shade900,
          'descriptionColor': Colors.grey.shade800,
          'closeButtonColor': Colors.grey.shade600,
          'badgeColor': Colors.blue.shade400,
          'badgeTextColor': Colors.white,
        };
      
      case AchievementRarity.basic:
      default:
        return {
          'backgroundColor': Colors.green.shade100,
          'borderColor': Colors.green.shade300,
          'shadowColor': Colors.black26,
          'blurRadius': 10.0,
          'spreadRadius': 0.0,
          'borderWidth': 2.0,
          'iconBackgroundColor': Colors.green.withOpacity(0.2),
          'iconColor': Colors.green.shade700,
          'iconGlowColor': Colors.transparent,
          'titleColor': Colors.green.shade700,
          'nameColor': Colors.black,
          'descriptionColor': Colors.grey.shade800,
          'closeButtonColor': Colors.grey.shade700,
          'badgeColor': Colors.transparent,
          'badgeTextColor': Colors.transparent,
        };
    }
  }
  
  String _getRarityText(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.milestone:
        return 'MILESTONE';
      case AchievementRarity.rare:
        return 'RARE';
      case AchievementRarity.basic:
      default:
        return '';
    }
  }
}