import 'package:flutter/material.dart';
import '../models/achievement.dart';
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
  
  @override
  void initState() {
    super.initState();
    
    _playAchievementSound();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    _animationController.forward();
    
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
    
    return SlideTransition(
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
                  child: Column(
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
                      Text(
                        widget.achievement.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: rarityColors['descriptionColor'],
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