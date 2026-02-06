import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For haptic feedback
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_state.dart';
import '../services/game_service.dart';
import '../services/admob_service.dart';
import '../widgets/hustle/upgrade_dialog.dart';
import '../widgets/hustle/boost_dialog.dart';
import '../utils/number_formatter.dart';
import '../utils/matrix4_fallback.dart';
import '../utils/responsive_utils.dart';
import '../utils/tap_boost_config.dart';

// Helper function to avoid extension conflicts
void _callTapOnGameState(GameState gameState) {
  // This will call the tap() method in income_logic.dart
  // The compiler will choose the extension based on import order
  gameState.tap();
}

/// Wins the horizontal-drag gesture arena when [shouldAccept] is true, so the
/// TabBarView does not receive the swipe and the hold-to-auto-tap is not cancelled.
class _HoldAwareHorizontalDragRecognizer extends HorizontalDragGestureRecognizer {
  _HoldAwareHorizontalDragRecognizer({required this.shouldAccept});

  final bool Function() shouldAccept;

  bool _accepted = false;

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent && shouldAccept() && !_accepted) {
      acceptGesture(event.pointer);
      _accepted = true;
    }
    super.handleEvent(event);
  }

  @override
  void rejectGesture(int pointer) {
    _accepted = false;
    super.rejectGesture(pointer);
  }
}

class HustleScreen extends StatefulWidget {
  const HustleScreen({Key? key}) : super(key: key);

  @override
  _HustleScreenState createState() => _HustleScreenState();
}

class _HustleScreenState extends State<HustleScreen> with SingleTickerProviderStateMixin {
  static const String _firstTapTutorialShownKey = 'hustle_first_tap_tutorial_shown';

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isWatchingAd = false;
  Timer? _autoClickHoldTimer;
  bool _firstTapTutorialShown = false;

  @override
  void initState() {
    super.initState();
    _loadFirstTapTutorialState();
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
    _autoClickHoldTimer?.cancel();
    _autoClickHoldTimer = null;
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
    _autoClickHoldTimer?.cancel();
    _autoClickHoldTimer = null;
  }

  void _onTapCancel() {
    _animationController.reverse();
    // When holding for auto-tap, the tap recognizer may cancel due to pointer movement
    // (we won the horizontal drag to block TabBarView). Keep the timer running; only
    // onTapUp (finger lifted) stops it.
    if (_autoClickHoldTimer != null) return;
    _autoClickHoldTimer?.cancel();
    _autoClickHoldTimer = null;
  }

  Future<void> _loadFirstTapTutorialState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shown = prefs.getBool(_firstTapTutorialShownKey) ?? false;
      if (mounted) setState(() => _firstTapTutorialShown = shown);
    } catch (_) {}
  }

  Future<void> _markFirstTapTutorialShown() async {
    if (_firstTapTutorialShown) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_firstTapTutorialShownKey, true);
      if (mounted) setState(() => _firstTapTutorialShown = true);
    } catch (_) {}
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
      
      // 🎯 HAPTIC FEEDBACK: Light tap feel for every click
      HapticFeedback.lightImpact();
      
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

      // 💰 FLOATING MONEY: Show catchy floating money animation
      if (_lastTapPosition != null && mounted) {
        final floatingMoneyManager = FloatingMoneyManager.of(context);
        if (floatingMoneyManager != null) {
          final clickValue = _calculateClickValue(gameState);
          floatingMoneyManager.spawnFloatingMoney(clickValue, _lastTapPosition!);
        }
      }

      // First-tap tutorial: mark as shown so we stop highlighting the tap area
      if (!_firstTapTutorialShown) _markFirstTapTutorialShown();
      
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
      final int requiredTaps = TapBoostConfig.getCumulativeTapsForLevel(nextLevel);
      
      if (gameState.taps >= requiredTaps && gameState.clickLevel < TapBoostConfig.maxClickLevel) {
        // 🎯 HAPTIC FEEDBACK: Heavy impact for level up - make it feel significant!
        HapticFeedback.heavyImpact();

        gameState.clickLevel = nextLevel;
        gameState.clickValue = TapBoostConfig.getClickBaseValueForLevel(nextLevel) * gameState.prestigeMultiplier;
        
        try {
          GameService? gameService = Provider.of<GameService>(context, listen: false);
          if (nextLevel >= 40) {
            gameService.playSound(() => gameService.soundManager.playAchievementMilestoneSound());
          } else if (nextLevel >= 25) {
            gameService.playSound(() => gameService.soundManager.playAchievementRareSound());
          } else if (nextLevel >= 10) {
            gameService.playAchievementSound();
          } else {
            gameService.playSound(() => gameService.soundManager.playFeedbackSuccessSound());
          }
        } catch (e) {
          if (DateTime.now().second % 30 == 0) {
            print("Sound error: $e");
          }
        }
        
        if (nextLevel % 5 == 0 || nextLevel >= 40) {
          print("🌟 LEVEL UP! New click level: ${gameState.clickLevel}, new value: ${gameState.clickValue.toStringAsFixed(2)}");
        }
      }
    } catch (e) {
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
      
      // 🎯 HAPTIC FEEDBACK: Medium impact for boost activation
      HapticFeedback.mediumImpact();
      
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
          
          // 🎯 HAPTIC FEEDBACK: Medium impact for boost activation from ad
          HapticFeedback.mediumImpact();
          
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
        final int requiredTaps = TapBoostConfig.getCumulativeTapsForLevel(nextLevel);
        final int currentLevelTaps = TapBoostConfig.getCumulativeTapsForLevel(gameState.clickLevel);
        final int relativeTaps = gameState.taps - currentLevelTaps;
        
        final double progress = gameState.clickLevel >= TapBoostConfig.maxClickLevel ? 1.0 :
          (relativeTaps <= 0 || (requiredTaps - currentLevelTaps) <= 0) ? 0.0 :
          (relativeTaps / (requiredTaps - currentLevelTaps)).clamp(0.0, 1.0);
        
        final double nextClickValue = gameState.clickLevel >= TapBoostConfig.maxClickLevel ? gameState.clickValue :
          _calculateNextClickValue(gameState.clickLevel + 1);
        
        // Hide boost section ONLY when achievement notification is visible
        final bool showBoost = !gameState.isAchievementNotificationVisible;
        
        // RESPONSIVE LAYOUT: Optimize for device size and ensure tap zone visibility
        return FloatingMoneyManager(
          child: Column(
            children: [
            // Click info card - responsive sizing
            _buildClickInfoCard(gameState, progress, nextClickValue, responsive),
            
            // Boost card - conditionally shown and responsive
            if (showBoost)
              _buildBoostCard(gameState, responsive),
            
            // CRITICAL FIX: Expanded tap area with guaranteed minimum space.
            // Use Selector so the tap area only rebuilds when display-related state changes,
            // not on every tap (money/taps). Rebuilding every 100ms during auto-click was
            // replacing the GestureDetector and cancelling the hold, stopping auto-tap.
            Expanded(
              flex: responsive.flexValues.content,
              child: ResponsiveContainer(
                padding: EdgeInsets.all(layoutConstraints.cardPadding),
                child:                 Selector<GameState, (
                  bool, int, bool, int, int, double, bool, int, int
                )>(
                  selector: (_, gs) => (
                    gs.isAutoClickerActive,
                    gs.autoClickerRemainingSeconds,
                    gs.isAdBoostActive,
                    gs.platinumClickFrenzyRemainingSeconds,
                    gs.platinumSteadyBoostRemainingSeconds,
                    gs.clickValue,
                    gs.isPermanentClickBoostActive,
                    gs.clickLevel,
                    gs.taps,
                  ),
                  builder: (context, __, child) {
                    final gs = Provider.of<GameState>(context, listen: false);
                    return _buildClickArea(gs, responsive);
                  },
                ),
              ),
            ),
            
            // Bottom spacing: use smaller value to avoid overflow when notification bar is visible
            SizedBox(height: responsive.spacing(16)),
          ],
          ),
        );
      },
    );
  }
  
  double _calculateNextClickValue(int level) {
    final gameState = Provider.of<GameState>(context, listen: false);
    return TapBoostConfig.getClickBaseValueForLevel(level) * gameState.prestigeMultiplier;
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
                if (gameState.clickLevel < TapBoostConfig.maxClickLevel)
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
                    '${gameState.clickLevel} ${gameState.clickLevel >= TapBoostConfig.maxClickLevel ? "(MAX)" : ""}',
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
                      
                      if (gameState.clickLevel < TapBoostConfig.maxClickLevel)
                        Padding(
                          padding: EdgeInsets.only(top: responsive.spacing(4.0)),
                          child: ResponsiveText(
                            '${gameState.taps} / ${TapBoostConfig.getCumulativeTapsForLevel(gameState.clickLevel + 1)} taps',
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
    final showFirstTapTutorial = !_firstTapTutorialShown && gameState.taps == 0;

    final tapArea = GestureDetector(
      onTap: () {
        _earnMoney();
      },
      onTapDown: (details) {
        _onTapDown(details);
        if (gameState.isAutoClickerActive) {
          _autoClickHoldTimer?.cancel();
          _autoClickHoldTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
            if (!mounted) {
              _autoClickHoldTimer?.cancel();
              _autoClickHoldTimer = null;
              return;
            }
            final gs = Provider.of<GameState>(context, listen: false);
            if (!gs.isAutoClickerActive) {
              _autoClickHoldTimer?.cancel();
              _autoClickHoldTimer = null;
              return;
            }
            _earnMoney();
          });
        }
      },
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
                        : showFirstTapTutorial
                            ? Colors.green.withOpacity(0.12)
                            : Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(responsive.spacing(24.0)),
                    border: Border.all(
                      color: showFirstTapTutorial
                          ? Colors.green.shade600
                          : gameState.isAdBoostActive
                              ? Colors.amber
                              : Colors.blue.shade300,
                      width: showFirstTapTutorial ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: showFirstTapTutorial
                            ? Colors.green.withOpacity(0.35)
                            : gameState.isAdBoostActive
                                ? Colors.amber.withOpacity(0.2)
                                : Colors.blue.withOpacity(0.1),
                        blurRadius: responsive.spacing(showFirstTapTutorial ? 14 : 10),
                        spreadRadius: responsive.spacing(showFirstTapTutorial ? 3 : 2),
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
                            color: showFirstTapTutorial
                                ? Colors.green.shade600
                                : gameState.isAdBoostActive
                                    ? Colors.amber
                                    : Colors.blue.shade400,
                          ),
                          SizedBox(height: responsive.spacing(16)),
                          Flexible(
                            child: ResponsiveText(
                              gameState.isAutoClickerActive
                                  ? 'Tap or hold to earn ${NumberFormatter.formatCurrency(_calculateClickValue(gameState))}'
                                  : 'Tap to earn ${NumberFormatter.formatCurrency(_calculateClickValue(gameState))}',
                              baseFontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: showFirstTapTutorial
                                  ? Colors.green.shade800
                                  : gameState.isAdBoostActive
                                      ? Colors.amber.shade800
                                      : Colors.blue.shade800,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                          if (showFirstTapTutorial)
                            Padding(
                              padding: EdgeInsets.only(top: responsive.spacing(6)),
                              child: ResponsiveText(
                                'Tap here to earn money',
                                baseFontSize: 14,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (gameState.isAutoClickerActive)
                            Padding(
                              padding: EdgeInsets.only(top: responsive.spacing(4)),
                              child: ResponsiveText(
                                'Hold to auto-click',
                                baseFontSize: 12,
                                color: Colors.blue.shade600,
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
    // When holding for auto-tap, win the horizontal-drag arena so TabBarView does not
    // receive the swipe and cancel the hold. Listener ensures we stop the timer on
    // pointer up even when the tap recognizer lost (e.g. drag won).
    return Listener(
      onPointerUp: (_) {
        _autoClickHoldTimer?.cancel();
        _autoClickHoldTimer = null;
      },
      child: RawGestureDetector(
        gestures: <Type, GestureRecognizerFactory>{
          _HoldAwareHorizontalDragRecognizer:
              GestureRecognizerFactoryWithHandlers<_HoldAwareHorizontalDragRecognizer>(
            () => _HoldAwareHorizontalDragRecognizer(
                shouldAccept: () => _autoClickHoldTimer != null),
            (_HoldAwareHorizontalDragRecognizer instance) {
              instance.onStart = (_) {};
              instance.onUpdate = (_) {};
              instance.onEnd = (_) {
                _autoClickHoldTimer?.cancel();
                _autoClickHoldTimer = null;
              };
              instance.onCancel = () {
                _autoClickHoldTimer?.cancel();
                _autoClickHoldTimer = null;
              };
            },
          ),
        },
        child: tapArea,
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
    final chips = <Widget>[];
    if (gameState.platinumClickFrenzyRemainingSeconds > 0) {
      chips.add(
        Container(
          padding: responsive.padding(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade600, Colors.pink.shade600],
            ),
            borderRadius: BorderRadius.circular(responsive.spacing(16)),
          ),
          child: ResponsiveText(
            'FRENZY: ${gameState.platinumClickFrenzyRemainingSeconds}s',
            baseFontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    if (gameState.platinumSteadyBoostRemainingSeconds > 0) {
      chips.add(
        Container(
          padding: responsive.padding(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.cyan.shade600],
            ),
            borderRadius: BorderRadius.circular(responsive.spacing(16)),
          ),
          child: ResponsiveText(
            'STEADY: ${gameState.platinumSteadyBoostRemainingSeconds}s',
            baseFontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    if (gameState.autoClickerRemainingSeconds > 0) {
      chips.add(
        Container(
          padding: responsive.padding(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade600, Colors.green.shade600],
            ),
            borderRadius: BorderRadius.circular(responsive.spacing(16)),
          ),
          child: ResponsiveText(
            'AUTO: ${gameState.autoClickerRemainingSeconds}s',
            baseFontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: responsive.spacing(6)),
      child: Wrap(
        spacing: responsive.spacing(6),
        runSpacing: responsive.spacing(4),
        alignment: WrapAlignment.center,
        children: chips,
      ),
    );
  }

  double _calculateClickValue(GameState gameState) {
    // Calculate base earnings including permanent boost
    double permanentClickMultiplier = gameState.isPermanentClickBoostActive ? 1.1 : 1.0;
    double baseValue = gameState.clickValue * permanentClickMultiplier; // Base * Permanent Vault Boost

    // Apply Ad boost multiplier
    double adBoostMultiplier = gameState.isAdBoostActive ? 10.0 : 1.0;

    // Apply Platinum Boosters multiplier (stack Frenzy 10x and Steady 2x; Auto Clicker does not change per-tap value)
    double platinumBoostMultiplier = 1.0;
    if (gameState.platinumClickFrenzyRemainingSeconds > 0) platinumBoostMultiplier *= 10.0;
    if (gameState.platinumSteadyBoostRemainingSeconds > 0) platinumBoostMultiplier *= 2.0;

    // Combine all multipliers: Base * Ad * Platinum
    return baseValue * adBoostMultiplier * platinumBoostMultiplier;
  }
}