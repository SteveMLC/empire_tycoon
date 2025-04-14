import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../services/game_service.dart';
import '../utils/number_formatter.dart';
import '../utils/matrix4_fallback.dart';

class HustleScreen extends StatefulWidget {
  const HustleScreen({Key? key}) : super(key: key);

  @override
  _HustleScreenState createState() => _HustleScreenState();
}

class _HustleScreenState extends State<HustleScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  Timer? _boostTimer;
  int _remainingBoostSeconds = 0;
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
    _boostTimer?.cancel();
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
      
      // Safety check that game is initialized
      if (!gameState.isInitialized) {
        print("Game not yet initialized, ignoring tap");
        return;
      }
      
      // Try to get game service
      GameService? gameService;
      try {
        gameService = Provider.of<GameService>(context, listen: false);
      } catch (e) {
        print("Could not get GameService: $e");
        // Continue without sound if service not available
      }
      
      // Call the tap method in GameState which properly updates all stats including lifetimeTaps
      if (_remainingBoostSeconds > 0) {
        // Custom handling for the boost case since tap() doesn't handle boost
        double boostedClickMultiplier = gameState.clickMultiplier * 10.0; // Store the original multiplier
        gameState.clickMultiplier *= 10.0; // Apply 10x boost temporarily
        gameState.tap(); // This increments both taps and lifetimeTaps
        gameState.clickMultiplier = boostedClickMultiplier / 10.0; // Reset to original
      } else {
        gameState.tap(); // Regular tap, which increments both taps and lifetimeTaps
      }
      
      // Check for level up
      _checkForLevelUp(gameState);
      
      // Enhanced debug logging
      double earnings = gameState.clickValue * (_remainingBoostSeconds > 0 ? 10.0 : 1.0);
      print("💰 HUSTLE TAP: earned \$${earnings.toStringAsFixed(2)}, new total: \$${gameState.money.toStringAsFixed(2)}, level: ${gameState.clickLevel}");
      
      // Force UI update in case state change isn't detected
      if (mounted) {
        setState(() {});
      }
      
      // Play sound - use boosted tap sound if boost is active
      if (gameService != null) {
        try {
          // Use the new specific method based on boost state
          if (_remainingBoostSeconds > 0) {
            gameService.soundManager.playUiTapBoostedSound();
          } else {
            gameService.soundManager.playUiTapSound(); // Use new UI tap sound method
          }
        } catch (e) {
          print("Sound error: $e");
        }
      }
      
      // Explicitly notify listeners for GameState
      gameState.notifyListeners();
    } catch (e) {
      print("Error in _earnMoney: $e");
    }
  }
  
  void _checkForLevelUp(GameState gameState) {
    try {
      // For example, level up click value at specific tap counts
      final int nextLevel = gameState.clickLevel + 1;
      int requiredTaps;
      
      // Calculate required taps for next level (with progressive scaling)
      if (nextLevel <= 5) {
        requiredTaps = 500 * nextLevel;
      } else if (nextLevel <= 10) {
        requiredTaps = 750 * nextLevel;
      } else {
        requiredTaps = 1000 * nextLevel;
      }
      
      // Check if we should level up
      if (gameState.taps >= requiredTaps && gameState.clickLevel < 20) {
        // Level up!
        gameState.clickLevel = nextLevel;
        
        // Increase click value (increasing gains per level)
        double baseValue;
        if (nextLevel <= 5) {
          // Starting from 1.5, increasing by at least 0.5 per level for first 5 levels
          baseValue = 1.5 + (nextLevel * 0.5);
        } else if (nextLevel <= 10) {
          // Base of 4.0 at level 6, increasing by 1.0 per level
          baseValue = 4.0 + ((nextLevel - 5) * 1.0);
        } else if (nextLevel <= 15) {
          // Base of 9.0 at level 11, increasing by 2.0 per level
          baseValue = 9.0 + ((nextLevel - 10) * 2.0);
        } else {
          // Base of 19.0 at level 16, increasing by 3.5 per level up to level 20
          baseValue = 19.0 + ((nextLevel - 15) * 3.5);
        }
        
        // Apply prestigeMultiplier to the new base value
        gameState.clickValue = baseValue * gameState.prestigeMultiplier;
        
        // Play level up sound based on milestone level
        try {
          GameService? gameService = Provider.of<GameService>(context, listen: false);
          
          // Play different achievement sounds based on level significance
          if (nextLevel >= 15) {
            // Major milestone achievement sound for high levels
            gameService.soundManager.playAchievementMilestoneSound();
          } else if (nextLevel >= 10) {
            // Rare achievement sound for medium-high levels
            gameService.soundManager.playAchievementRareSound();
          } else if (nextLevel >= 5) {
            // Basic achievement sound for medium levels
            gameService.soundManager.playAchievementBasicSound();
          } else {
            // Use feedback success sound for early levels
            gameService.soundManager.playFeedbackSuccessSound();
          }
        } catch (e) {
          print("Could not play level up sound: $e");
        }
        
        print("🌟 LEVEL UP! New click level: ${gameState.clickLevel}, new value: ${gameState.clickValue.toStringAsFixed(2)}");
      }
    } catch (e) {
      print("Error in _checkForLevelUp: $e");
    }
  }
  
  void _startAdBoost() {
    // In a real app, you would show an actual ad here
    setState(() {
      _isWatchingAd = true;
    });
    
    // Simulate ad viewing
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return; // Safety check if widget is disposed
      
      setState(() {
        _isWatchingAd = false;
        _remainingBoostSeconds = 60;
      });
      
      // Start boost timer
      _boostTimer?.cancel();
      _boostTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        
        setState(() {
          _remainingBoostSeconds--;
          if (_remainingBoostSeconds <= 0) {
            timer.cancel();
          }
        });
      });
      
      // Play boost success sound with error handling
      try {
        GameService? gameService = Provider.of<GameService>(context, listen: false);
        // Use notification sound for boost activation
        gameService.soundManager.playFeedbackNotificationSound();
      } catch (e) {
        print("Could not play boost success sound: $e");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        // Calculate progress to next level
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
        
        // Calculate relative progress within current level
        // Use taps (current level progress) instead of lifetimeTaps % requiredTaps
        // This ensures progress bar properly tracks taps for current level
        relativeTaps = gameState.taps - currentLevelTaps;
        
        final double progress = gameState.clickLevel >= 20 ? 1.0 :
          relativeTaps / (requiredTaps - currentLevelTaps);
        
        final double nextClickValue = gameState.clickLevel >= 20 ? gameState.clickValue :
          _calculateNextClickValue(gameState.clickLevel + 1);
        
        return Column(
          children: [
            _buildClickInfoCard(gameState, progress, nextClickValue),
            _buildBoostCard(),
            
            // Click area (takes up about half the screen)
            Expanded(
              flex: 6, // Increased from 3 to 6 to make it much taller
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildClickArea(gameState),
              ),
            ),
            
            // Bottom spacer
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
  
  double _calculateNextClickValue(int level) {
    double baseValue;
    if (level <= 5) {
      // Starting from 1.5, increasing by at least 0.5 per level for first 5 levels
      baseValue = 1.5 + (level * 0.5);
    } else if (level <= 10) {
      // Base of 4.0 at level 6, increasing by 1.0 per level
      baseValue = 4.0 + ((level - 5) * 1.0);
    } else if (level <= 15) {
      // Base of 9.0 at level 11, increasing by 2.0 per level
      baseValue = 9.0 + ((level - 10) * 2.0);
    } else {
      // Base of 19.0 at level 16, increasing by 3.5 per level up to level 20
      baseValue = 19.0 + ((level - 15) * 3.5);
    }
    
    // Apply the prestige multiplier to the next level value
    final gameState = Provider.of<GameState>(context, listen: false);
    return baseValue * gameState.prestigeMultiplier;
  }
  
  Widget _buildClickInfoCard(GameState gameState, double progress, double nextClickValue) {
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
            // Current click value
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${NumberFormatter.formatCurrency(gameState.clickValue)} ',
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
                
                // Next level value preview
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
            
            // Level indicator and progress bar
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
                
                // Progress bar
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
      return 500 * level; // Start with 500 taps for level 1, already updated from 1000
    } else if (level <= 10) {
      return 750 * level;
    } else {
      return 1000 * level;
    }
  }
  
  Widget _buildBoostCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        color: _remainingBoostSeconds > 0 
            ? Colors.amber.shade100 
            : Colors.green.shade100,
        child: InkWell(
          onTap: (_remainingBoostSeconds > 0 || _isWatchingAd) ? null : _startAdBoost,
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
                  child: _remainingBoostSeconds > 0
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
                              '10x earnings for $_remainingBoostSeconds more seconds',
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
                                const Text(
                                  'Watch Ad for 10x Boost',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Get 10x click earnings for 60 seconds',
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
        // Debug print to confirm tap is registered
        print("TAP REGISTERED IN HUSTLE SCREEN");
      },
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.translucent, // Changed to translucent for better detection
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          // Use Matrix4Fallback utility for better deployment compatibility
          return Matrix4Fallback.scale(
            scale: _scaleAnimation.value,
            child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: _remainingBoostSeconds > 0
                        ? Colors.amber.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(
                      color: _remainingBoostSeconds > 0
                          ? Colors.amber
                          : Colors.blue.shade300,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _remainingBoostSeconds > 0
                            ? Colors.amber.withOpacity(0.2)
                            : Colors.blue.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: _earnMoney,
                    splashColor: _remainingBoostSeconds > 0
                        ? Colors.amber.withOpacity(0.3)
                        : Colors.blue.withOpacity(0.3),
                    highlightColor: _remainingBoostSeconds > 0
                        ? Colors.amber.withOpacity(0.2)
                        : Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 72,
                            color: _remainingBoostSeconds > 0
                                ? Colors.amber
                                : Colors.blue.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tap to earn ${NumberFormatter.formatCurrency(_remainingBoostSeconds > 0 ? gameState.clickValue * 10 : gameState.clickValue)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _remainingBoostSeconds > 0
                                  ? Colors.amber.shade800
                                  : Colors.blue.shade800,
                            ),
                          ),
                          if (_remainingBoostSeconds > 0)
                            Padding(
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
}