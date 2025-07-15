import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../services/game_service.dart';
import '../services/admob_service.dart';
import '../widgets/hustle/upgrade_dialog.dart';
import '../widgets/hustle/boost_dialog.dart';
import '../utils/number_formatter.dart';
import '../utils/matrix4_fallback.dart';

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
        
        return Column(
          children: [
            _buildClickInfoCard(gameState, progress, nextClickValue),
            if (showBoost)
              _buildBoostCard(gameState),
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildClickArea(gameState),
              ),
            ),
            
            const SizedBox(height: 80),
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
  
  Widget _buildClickInfoCard(GameState gameState, double progress, double nextClickValue) {
    // Calculate effective click value including ALL boosts (permanent, ad, platinum)
    double finalClickValue = _calculateClickValue(gameState);

    return Card(
      margin: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade700,
              Colors.teal.shade600,
            ],
          ),
        ),
        padding: const EdgeInsets.all(16.0),
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
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const TextSpan(
                        text: 'per click',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (gameState.clickLevel < 20)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.arrow_upward,
                          color: Colors.greenAccent,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${NumberFormatter.formatCurrency(nextClickValue)} per click',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${gameState.clickLevel} ${gameState.clickLevel >= 20 ? "(MAX)" : ""}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                          minHeight: 8,
                        ),
                      ),
                      
                      if (gameState.clickLevel < 20)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '${gameState.taps} / ${_calculateRequiredTaps(gameState.clickLevel + 1)} taps',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
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
  
  Widget _buildBoostCard(GameState gameState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
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
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: _isWatchingAd
                      ? const Center(child: CircularProgressIndicator())
                      : const Icon(
                          Icons.play_circle_filled,
                          color: Colors.grey,
                          size: 30,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: gameState.isAdBoostActive
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Boost Active!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '10x earnings for ${gameState.adBoostRemainingSeconds} more seconds',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        )
                      : _isWatchingAd
                          ? const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Watching Ad...',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Please wait to receive your boost',
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gameState.isPremium ? 'Premium Boost (No Ads)' : 'Watch Ad for 10x Boost',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  gameState.isPremium 
                                    ? 'Get instant 10x click earnings for 60 seconds'
                                    : 'Get 10x click earnings for 60 seconds',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                  ),
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

  Widget _buildClickArea(GameState gameState) {
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
                  decoration: BoxDecoration(
                    color: gameState.isAdBoostActive
                        ? Colors.amber.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24.0),
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
                        blurRadius: 10,
                        spreadRadius: 2,
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
                    borderRadius: BorderRadius.circular(24.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 72,
                            color: gameState.isAdBoostActive
                                ? Colors.amber
                                : Colors.blue.shade400,
                          ),
                          const SizedBox(height: 16),
                          Flexible(
                            child: Text(
                              'Tap to earn ${NumberFormatter.formatCurrency(_calculateClickValue(gameState))}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: gameState.isAdBoostActive
                                    ? Colors.amber.shade800
                                    : Colors.blue.shade800,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                          if (gameState.isPlatinumBoostActive)
                            Flexible(
                              child: _buildPlatinumBoostStatus(gameState),
                            ),
                          if (gameState.isAdBoostActive)
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.amber),
                                  ),
                                  child: Text(
                                    '10x BOOST ACTIVE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade800,
                                    ),
                                    overflow: TextOverflow.ellipsis,
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
            );
        },
      ),
    );
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

  Widget _buildPlatinumBoostStatus(GameState gameState) {
    String boostName = '';
    String boostMultiplier = '';
    int remainingSeconds = 0;

    if (gameState.platinumClickFrenzyRemainingSeconds > 0) {
      boostName = 'Click Frenzy';
      boostMultiplier = '10x';
      remainingSeconds = gameState.platinumClickFrenzyRemainingSeconds;
    } else if (gameState.platinumSteadyBoostRemainingSeconds > 0) {
      boostName = 'Steady Boost';
      boostMultiplier = '2x';
      remainingSeconds = gameState.platinumSteadyBoostRemainingSeconds;
    } else {
      return const SizedBox.shrink();
    }

    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.purple.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purple),
        ),
        child: Text(
          '$boostName Active ($boostMultiplier) - $timeString remaining',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.purple.shade800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}