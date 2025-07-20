import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../services/game_service.dart';
import '../services/admob_service.dart';
import '../widgets/hustle/upgrade_dialog.dart';
import '../widgets/hustle/boost_dialog.dart';
import '../utils/number_formatter.dart';
import '../utils/matrix4_fallback.dart';
import '../utils/responsive_utils.dart';

// Helper function to avoid extension conflicts
void _callTapOnGameState(GameState gameState) {
  // This will call the tap() method in income_logic.dart
  // The compiler will choose the extension based on import order
  gameState.tap();
}

class HustleScreen extends StatefulWidget {
  const HustleScreen({Key? key}) : super(key: key);

  @override
  _HustleScreenState createState() => _HustleScreenState();
}

class _HustleScreenState extends State<HustleScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isWatchingAd = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
    // We'll use the onTap handler of InkWell for the actual earning
    // This is to prevent duplicate earning on both onTap and onTapUp
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  void _earnMoney() {
    try {
      final gameState = Provider.of<GameState>(context, listen: false);
      
      if (!gameState.isInitialized) {
        // Only log this occasionally to reduce spam
        if (DateTime.now().second % 10 == 0) {
          print("Game not yet initialized, ignoring tap");
        }
        return;
      }
      
      GameService? gameService;
      try {
        gameService = Provider.of<GameService>(context, listen: false);
      } catch (e) {
        // Only log service errors occasionally
        if (DateTime.now().second % 30 == 0) {
          print("Could not get GameService: $e");
        }
      }
      
      // Use the helper function to avoid extension conflicts
      _callTapOnGameState(gameState);
      
      _checkForLevelUp(gameState);
      
      if (mounted) {
        setState(() {});
      }
      
      if (gameService != null) {
        try {
          if (gameState.isAdBoostActive) {
            gameService.playBoostedTapSound();
          } else {
            gameService.playTapSound();
          }
        } catch (e) {
          // Only log sound errors occasionally to reduce spam
          if (DateTime.now().second % 30 == 0) {
            print("Sound error: $e");
          }
        }
      }
    } catch (e) {
      // Only log general errors occasionally
      if (DateTime.now().second % 30 == 0) {
        print("Error in _earnMoney: $e");
      }
    }
  }
  
  void _checkForLevelUp(GameState gameState) {
    try {
      final int nextLevel = gameState.clickLevel + 1;
      int requiredTaps;
      
      if (nextLevel <= 5) {
        requiredTaps = 500 * nextLevel;
      } else if (nextLevel <= 10) {
        requiredTaps = 750 * nextLevel;
      } else {
        requiredTaps = 1000 * nextLevel;
      }
      
      if (gameState.taps >= requiredTaps && gameState.clickLevel < 20) {
        gameState.clickLevel = nextLevel;
        
        double baseValue;
        if (nextLevel <= 5) {
          baseValue = 1.5 + (nextLevel * 0.5);
        } else if (nextLevel <= 10) {
          baseValue = 4.0 + ((nextLevel - 5) * 1.0);
        } else if (nextLevel <= 15) {
          baseValue = 9.0 + ((nextLevel - 10) * 2.0);
        } else {
          baseValue = 19.0 + ((nextLevel - 15) * 3.5);
        }
        
        gameState.clickValue = baseValue * gameState.prestigeMultiplier;
        
        try {
          GameService? gameService = Provider.of<GameService>(context, listen: false);
          
          if (nextLevel >= 15) {
            gameService.playSound(() => gameService.soundManager.playAchievementMilestoneSound());
          } else if (nextLevel >= 10) {
            gameService.playSound(() => gameService.soundManager.playAchievementRareSound());
          } else if (nextLevel >= 5) {
            gameService.playAchievementSound();
          } else {
            gameService.playSound(() => gameService.soundManager.playFeedbackSuccessSound());
          }
        } catch (e) {
          // Only log sound errors occasionally to reduce spam
          if (DateTime.now().second % 30 == 0) {
            print("Sound error: $e");
          }
        }
        
        // Only log level ups occasionally to reduce spam, or for significant milestones
        if (nextLevel % 5 == 0 || nextLevel >= 15) {
          print("🌟 LEVEL UP! New click level: ${gameState.clickLevel}, new value: ${gameState.clickValue.toStringAsFixed(2)}");
        }
      }
    } catch (e) {
      // Only log errors occasionally
      if (DateTime.now().second % 30 == 0) {
        print("Error in _checkForLevelUp: $e");
      }
    }
  }
  
  void _startAdBoost() {
    final gameState = Provider.of<GameState>(context, listen: false);
    final adMobService = Provider.of<AdMobService>(context, listen: false);
    
    // Check if premium user should skip ads
    if (gameState.isPremium) {
      // Premium users skip ads and get boost immediately
      gameState.startAdBoost();
      
      try {
        GameService? gameService = Provider.of<GameService>(context, listen: false);
        gameService.soundManager.playFeedbackNotificationSound();
      } catch (e) {
        // Only log boost sound errors occasionally to reduce spam
        if (DateTime.now().second % 30 == 0) {
          print("Could not play boost success sound: $e");
        }
      }
      return;
    }
    
    setState(() {
      _isWatchingAd = true;
    });
    
    // Show AdMob rewarded ad
    adMobService.showHustleBoostAd(
      onRewardEarned: (String rewardType) {
        if (!mounted) return;
        
        // Verify we received the correct reward type
        if (rewardType == 'HustleBoost') {
          // User watched the ad successfully, give the boost
          gameState.startAdBoost();
          
          // Update local state for UI
          setState(() {
            _isWatchingAd = false;
          });
          
          try {
            GameService? gameService = Provider.of<GameService>(context, listen: false);
            gameService.soundManager.playFeedbackNotificationSound();
          } catch (e) {
            // Only log boost sound errors occasionally to reduce spam
            if (DateTime.now().second % 30 == 0) {
              print("Could not play boost success sound: $e");
            }
          }
        } else {
          print('Warning: Expected HustleBoost reward but received: $rewardType');
        }
      },
      onAdFailure: () {
        if (!mounted) return;
        
        // Ad failed to load or show, reset state and show error
        setState(() {
          _isWatchingAd = false;
        });
        
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text('Ad not available. Please try again later.'),
        //     duration: Duration(seconds: 3),
        //   ),
        // );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final layoutConstraints = responsive.layoutConstraints;
    
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final int nextLevel = gameState.clickLevel + 1;
        int requiredTaps;
        int currentLevelTaps;
        int relativeTaps;

        if (nextLevel <= 5) {
          requiredTaps = 500 * nextLevel;
        } else if (nextLevel <= 10) {
          requiredTaps = 750 * nextLevel;
        } else {
          requiredTaps = 1000 * nextLevel;
        }
        
        currentLevelTaps = gameState.clickLevel <= 1 ? 0 : 
          gameState.clickLevel <= 5 ? 500 * gameState.clickLevel :
          gameState.clickLevel <= 10 ? 750 * gameState.clickLevel :
          1000 * gameState.clickLevel;
        
        relativeTaps = gameState.taps - currentLevelTaps;
        
        final double progress = gameState.clickLevel >= 20 ? 1.0 :
          (relativeTaps <= 0 || (requiredTaps - currentLevelTaps) <= 0) ? 0.0 :
          (relativeTaps / (requiredTaps - currentLevelTaps)).clamp(0.0, 1.0);
        
        final double nextClickValue = gameState.clickLevel >= 20 ? gameState.clickValue :
          _calculateNextClickValue(gameState.clickLevel + 1);
        
        // Hide boost section ONLY when achievement notification is visible
        final bool showBoost = !gameState.isAchievementNotificationVisible;
        
        // RESPONSIVE LAYOUT: Optimize for device size and ensure tap zone visibility
        return Column(
          children: [
            // Click info card - responsive sizing
            _buildClickInfoCard(gameState, progress, nextClickValue, responsive),
            
            // Boost card - conditionally shown and responsive
            if (showBoost)
              _buildBoostCard(gameState, responsive),
            
            // CRITICAL FIX: Expanded tap area with guaranteed minimum space
            Expanded(
              flex: responsive.flexValues.content,
              child: ResponsiveContainer(
                padding: EdgeInsets.all(layoutConstraints.cardPadding),
                child: _buildClickArea(gameState, responsive),
              ),
            ),
            
            // RESPONSIVE BOTTOM SPACING: Ensure safe area for navigation
            SizedBox(height: responsive.safeAreaBottom),
          ],
        );
      },
    );
  }
  
  double _calculateNextClickValue(int level) {
    double baseValue;
    if (level <= 5) {
      baseValue = 1.5 + (level * 0.5);
    } else if (level <= 10) {
      baseValue = 4.0 + ((level - 5) * 1.0);
    } else if (level <= 15) {
      baseValue = 9.0 + ((level - 10) * 2.0);
    } else {
      baseValue = 19.0 + ((level - 15) * 3.5);
    }
    
    final gameState = Provider.of<GameState>(context, listen: false);
    return baseValue * gameState.prestigeMultiplier;
  }
  
  Widget _buildClickInfoCard(GameState gameState, double progress, double nextClickValue, ResponsiveUtils responsive) {
    // Calculate effective click value including ALL boosts (permanent, ad, platinum)
    double finalClickValue = _calculateClickValue(gameState);

    return Card(
      margin: responsive.margin(all: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(responsive.spacing(16.0)),
      ),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(responsive.spacing(16.0)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade700,
              Colors.teal.shade600,
            ],
          ),
        ),
        padding: responsive.padding(all: 16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${NumberFormatter.formatCurrency(finalClickValue)} ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: responsive.fontSize(18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: 'per click',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: responsive.fontSize(14),
                        ),
                      ),
                    ],
                  ),
                ),
                if (gameState.clickLevel < 20)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ResponsiveText(
                        'Next: ${NumberFormatter.formatCurrency(nextClickValue)}',
                        baseFontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      ResponsiveText(
                        'Level ${gameState.clickLevel + 1}',
                        baseFontSize: 10,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ],
                  ),
              ],
            ),
            
            SizedBox(height: responsive.spacing(12)),
            
            // RESPONSIVE PROGRESS DISPLAY
            Row(
              children: [
                Container(
                  padding: responsive.padding(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(responsive.spacing(12)),
                  ),
                  child: ResponsiveText(
                    '${gameState.clickLevel} ${gameState.clickLevel >= 20 ? "(MAX)" : ""}',
                    baseFontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                SizedBox(width: responsive.spacing(12)),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(responsive.spacing(8)),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                          minHeight: responsive.spacing(8),
                        ),
                      ),
                      
                      if (gameState.clickLevel < 20)
                        Padding(
                          padding: EdgeInsets.only(top: responsive.spacing(4.0)),
                          child: ResponsiveText(
                            '${gameState.taps} / ${_calculateRequiredTaps(gameState.clickLevel + 1)} taps',
                            baseFontSize: 10,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  int _calculateRequiredTaps(int level) {
    if (level <= 5) {
      return 500 * level;
    } else if (level <= 10) {
      return 750 * level;
    } else {
      return 1000 * level;
    }
  }
  
  Widget _buildBoostCard(GameState gameState, ResponsiveUtils responsive) {
    return Padding(
      padding: responsive.padding(horizontal: 16.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.spacing(12.0)),
        ),
        color: gameState.isAdBoostActive
            ? Colors.amber.shade100 
            : Colors.green.shade100,
        child: InkWell(
          onTap: (gameState.isAdBoostActive || _isWatchingAd) 
              ? null 
              : () {
                  final gs = Provider.of<GameState>(context, listen: false);
                  if (!gs.isAdBoostActive) {
                    _startAdBoost(); 
                  }
                },
          borderRadius: BorderRadius.circular(responsive.spacing(12.0)),
          child: Container(
            constraints: BoxConstraints(
              minHeight: responsive.layoutConstraints.buttonHeight,
            ),
            padding: responsive.padding(all: 12.0),
            child: Row(
              children: [
                Icon(
                  Icons.play_circle_fill,
                  color: gameState.isAdBoostActive ? Colors.amber.shade600 : Colors.green.shade600,
                  size: responsive.iconSize(24),
                ),
                SizedBox(width: responsive.spacing(12)),
                Expanded(
                  child: gameState.isAdBoostActive
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ResponsiveText(
                              'Boost Active! (10x earnings)',
                              baseFontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            SizedBox(height: responsive.spacing(4)),
                            ResponsiveText(
                              'Time remaining: ${_formatAdBoostTime(gameState.adBoostRemainingSeconds)}',
                              baseFontSize: 12,
                            ),
                          ],
                        )
                      : _isWatchingAd
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ResponsiveText(
                                  'Watching Ad...',
                                  baseFontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                SizedBox(height: responsive.spacing(4)),
                                ResponsiveText(
                                  'Please wait to receive your boost',
                                  baseFontSize: 12,
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ResponsiveText(
                                  gameState.isPremium ? 'Premium Boost (No Ads)' : 'Watch Ad for 10x Boost',
                                  baseFontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                SizedBox(height: responsive.spacing(4)),
                                ResponsiveText(
                                  gameState.isPremium 
                                    ? 'Get instant 10x click earnings for 60 seconds'
                                    : 'Get 10x click earnings for 60 seconds',
                                  baseFontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ],
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClickArea(GameState gameState, ResponsiveUtils responsive) {
    return GestureDetector(
      onTap: () {
        _earnMoney();
      },
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.translucent,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Matrix4Fallback.scale(
            scale: _scaleAnimation.value,
            child: Material(
                color: Colors.transparent,
                child: Container(
                  // GUARANTEED MINIMUM TAP TARGET SIZE
                  constraints: BoxConstraints(
                    minHeight: responsive.layoutConstraints.minimumTapTarget * 3, // 3x minimum for gaming
                    minWidth: double.infinity,
                  ),
                  decoration: BoxDecoration(
                    color: gameState.isAdBoostActive
                        ? Colors.amber.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(responsive.spacing(24.0)),
                    border: Border.all(
                      color: gameState.isAdBoostActive
                          ? Colors.amber
                          : Colors.blue.shade300,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: gameState.isAdBoostActive
                            ? Colors.amber.withOpacity(0.2)
                            : Colors.blue.withOpacity(0.1),
                        blurRadius: responsive.spacing(10),
                        spreadRadius: responsive.spacing(2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: _earnMoney,
                    splashColor: gameState.isAdBoostActive
                        ? Colors.amber.withOpacity(0.3)
                        : Colors.blue.withOpacity(0.3),
                    highlightColor: gameState.isAdBoostActive
                        ? Colors.amber.withOpacity(0.2)
                        : Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(responsive.spacing(24.0)),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: responsive.iconSize(72),
                            color: gameState.isAdBoostActive
                                ? Colors.amber
                                : Colors.blue.shade400,
                          ),
                          SizedBox(height: responsive.spacing(16)),
                          Flexible(
                            child: ResponsiveText(
                              'Tap to earn ${NumberFormatter.formatCurrency(_calculateClickValue(gameState))}',
                              baseFontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: gameState.isAdBoostActive
                                  ? Colors.amber.shade800
                                  : Colors.blue.shade800,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                          if (gameState.isPlatinumBoostActive)
                            Flexible(
                              child: _buildPlatinumBoostStatus(gameState, responsive),
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
    );
  }

  String _formatBoostTime(DateTime? endTime) {
    if (endTime == null) return "00:00";
    
    final Duration remaining = endTime.difference(DateTime.now());
    if (remaining.isNegative) return "00:00";
    
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  String _formatAdBoostTime(int remainingSeconds) {
    if (remainingSeconds <= 0) return "00:00";
    
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  Widget _buildPlatinumBoostStatus(GameState gameState, ResponsiveUtils responsive) {
    if (gameState.platinumClickFrenzyRemainingSeconds > 0) {
      return Padding(
        padding: EdgeInsets.only(top: responsive.spacing(8)),
        child: Container(
          padding: responsive.padding(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade600, Colors.pink.shade600],
            ),
            borderRadius: BorderRadius.circular(responsive.spacing(20)),
          ),
          child: ResponsiveText(
            'PLATINUM FRENZY: ${gameState.platinumClickFrenzyRemainingSeconds}s',
            baseFontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    } else if (gameState.platinumSteadyBoostRemainingSeconds > 0) {
      return Padding(
        padding: EdgeInsets.only(top: responsive.spacing(8)),
        child: Container(
          padding: responsive.padding(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.cyan.shade600],
            ),
            borderRadius: BorderRadius.circular(responsive.spacing(20)),
          ),
          child: ResponsiveText(
            'STEADY BOOST: ${gameState.platinumSteadyBoostRemainingSeconds}s',
            baseFontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  double _calculateClickValue(GameState gameState) {
    // Calculate base earnings including permanent boost
    double permanentClickMultiplier = gameState.isPermanentClickBoostActive ? 1.1 : 1.0;
    double baseValue = gameState.clickValue * permanentClickMultiplier; // Base * Permanent Vault Boost

    // Apply Ad boost multiplier
    double adBoostMultiplier = gameState.isAdBoostActive ? 10.0 : 1.0;

    // Apply Platinum Boosters multiplier
    double platinumBoostMultiplier = 1.0;
    if (gameState.platinumClickFrenzyRemainingSeconds > 0) {
        platinumBoostMultiplier = 10.0;
    } else if (gameState.platinumSteadyBoostRemainingSeconds > 0) {
        platinumBoostMultiplier = 2.0;
    }

    // Combine all multipliers: Base * Ad * Platinum
    return baseValue * adBoostMultiplier * platinumBoostMultiplier;
  }
}