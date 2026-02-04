import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

import '../../models/game_state.dart';
import '../../services/income_service.dart';
import '../../services/game_service.dart';
import '../money_display.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/number_formatter.dart';
import 'animated_pp_icon.dart';
import '../../painters/luxury_painters.dart';

/// The top panel of the main screen showing cash, income rate, and platinum points
class TopPanel extends StatefulWidget {
  const TopPanel({Key? key}) : super(key: key);

  @override
  State<TopPanel> createState() => _TopPanelState();
}

class _TopPanelState extends State<TopPanel> {
  static const String _ppZoneTutorialShownKey = 'pp_zone_tutorial_shown';
  bool _ppZoneTutorialShown = false;

  @override
  void initState() {
    super.initState();
    _loadPPZoneTutorialState();
  }

  Future<void> _loadPPZoneTutorialState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shown = prefs.getBool(_ppZoneTutorialShownKey) ?? false;
      if (mounted) setState(() => _ppZoneTutorialShown = shown);
    } catch (_) {}
  }

  Future<void> _markPPZoneTutorialShown() async {
    if (_ppZoneTutorialShown) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_ppZoneTutorialShownKey, true);
      if (mounted) setState(() => _ppZoneTutorialShown = true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Get responsive design utilities
    final responsive = context.responsive;
    final layoutConstraints = responsive.layoutConstraints;
    final mediaQuery = MediaQuery.of(context);
    
    // Use Consumer for efficient rebuilds
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        // Get IncomeService from GameService instead of direct Provider to ensure consistency
        final gameService = Provider.of<GameService>(context, listen: false);
        final incomeService = gameService.incomeService;
        
        // Determine if boost is currently active based on GameState
        final bool isBoostCurrentlyActive = gameState.clickMultiplier > 1.0 && 
                                           gameState.clickBoostEndTime != null && 
                                           gameState.clickBoostEndTime!.isAfter(DateTime.now());

        // Check if platinum frame is active
        final bool isPlatinumFrameActive = gameState.isPlatinumFrameUnlocked && gameState.isPlatinumFrameActive;

        return Container(
          width: double.infinity,
          // FIXED: Increased height by 21px to prevent overflow (132px content + 69px padding = 201px needed)
          height: math.max(mediaQuery.padding.top + 145, 188),
          // RESPONSIVE PADDING: Fine-tuned padding for optimal spacing
          padding: EdgeInsets.fromLTRB(
            responsive.spacing(12), 
            // Status bar + reduced top padding
            mediaQuery.padding.top + responsive.spacing(4), 
            responsive.spacing(12), 
            responsive.spacing(25) // Increased bottom padding to separate from tab bar
          ),
          decoration: isPlatinumFrameActive
              ? BoxDecoration(
                  // Rich luxury platinum gradient with depth and dimension
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2A1D47),  // Deeper royal purple for contrast
                      Color(0xFF2E2A5A),  // Rich royal blue, slightly darker
                      Color(0xFF34305E),  // Indigo with purple hints
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.7), // More intense golden glow
                      blurRadius: 16,
                      spreadRadius: -2,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.45),
                      blurRadius: 10,
                      spreadRadius: -1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border(
                    bottom: const BorderSide(
                      color: Color(0xFFFFD700), // Pure gold color
                      width: 2.0,
                    ),
                    top: const BorderSide(
                      color: Color(0xFFFFD700), // Pure gold color
                      width: 0.75,
                    ),
                    left: BorderSide(
                      color: const Color(0xFFFFD700).withOpacity(0.6), // Gold side accents
                      width: 0.75,
                    ),
                    right: BorderSide(
                      color: const Color(0xFFFFD700).withOpacity(0.6), // Gold side accents
                      width: 0.75,
                    ),
                  ),
                )
              : BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1.0,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
          child: Stack(
            children: [
              // Enhanced luxury background pattern for platinum frame (only if active)
              if (isPlatinumFrameActive)
                Positioned.fill(
                  child: CustomPaint(
                    painter: LuxuryPatternPainter(),
                  ),
                ),
              
              // Main content with enhanced visual design
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Better content distribution
                children: [
                  // Top Row: Account Label and PP Display - More compact for Platinum
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Elevated account label with premium styling
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: isPlatinumFrameActive ? BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFD700), Color(0xFFFDB833)], // Richer gold gradient
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFFD700).withOpacity(0.8),
                            width: 1.75,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: -2,
                              offset: const Offset(0, 2),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: -2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ) : null,
                        child: Row(
                          children: [
                            if (isPlatinumFrameActive)
                              const Icon(
                                Icons.account_balance,
                                color: Colors.white,
                                size: 16,
                              ),
                            if (isPlatinumFrameActive)
                              const SizedBox(width: 6),
                            Text(
                              isPlatinumFrameActive ? 'INVESTMENT ACCOUNT' : 'Investment Account',
                              style: TextStyle(
                                color: isPlatinumFrameActive ? Colors.white : Colors.grey.shade800,
                                fontSize: isPlatinumFrameActive ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: isPlatinumFrameActive ? 1.0 : 0.5,
                                shadows: isPlatinumFrameActive
                                    ? [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.5),
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ] 
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // PP display with enhanced glow
                      _buildPPDisplay(
                        gameState,
                        context,
                        showTutorial: gameState.platinumPoints >= 25 && !_ppZoneTutorialShown,
                      ),
                    ],
                  ),
                  
                  // Minimized spacing between account label and cash
                  SizedBox(height: isPlatinumFrameActive ? 2 : 4),
                  
                  // Enhanced money container with platinum theme - more depth and dimension
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: isPlatinumFrameActive
                        ? BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1F1835),  // Deep royal purple
                                Color(0xFF252152),  // Rich royal blue
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFFD700).withOpacity(0.6),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: -2,
                                offset: const Offset(0, 2),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 6,
                                spreadRadius: -2,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          )
                        : BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                    child: Column(
                      children: [
                        // Money display with improved styling, reduced size, and better overflow handling
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center, // Vertically align items
                          children: [
                            // Label with iconic platinum money sign - Wrap in Expanded
                            Expanded(
                              flex: 2, // Give label reasonable space
                              child: Row(
                                mainAxisSize: MainAxisSize.min, // Don't expand horizontally
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: isPlatinumFrameActive
                                        ? BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFFFD700), Color(0xFFFFC107)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFFFD700).withOpacity(0.6),
                                                blurRadius: 8,
                                                spreadRadius: 0,
                                                offset: const Offset(0, 1),
                                              ),
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.4),
                                                blurRadius: 4,
                                                spreadRadius: -1,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          )
                                        : null,
                                    child: Icon(
                                      Icons.attach_money,
                                      color: isPlatinumFrameActive ? Colors.white : Colors.grey.shade800,
                                      size: 18, // Reduced from 20
                                    ),
                                  ),
                                  const SizedBox(width: 8), // Reduced from 10
                                  Text(
                                    'Cash:',
                                    style: TextStyle(
                                      color: isPlatinumFrameActive ? Colors.white : Colors.grey.shade800,
                                      fontSize: 16, // Reduced from 18
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: isPlatinumFrameActive ? 0.5 : 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Value - Wrap in Expanded
                            Expanded(
                              flex: 3, // Give value more space
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: MoneyDisplay(
                                  money: gameState.money,
                                  fontColor: isPlatinumFrameActive ? Colors.white : Colors.black,
                                  fontSize: 18, // Match the income rate size
                                  fontWeight: FontWeight.bold,
                                  isPlatinumStyle: isPlatinumFrameActive,
                                  textAlign: TextAlign.right,
                                  shadows: isPlatinumFrameActive
                                      ? [
                                          Shadow(
                                            color: const Color(0xFFFFD700).withOpacity(0.6),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                          Shadow(
                                            color: Colors.black.withOpacity(0.4),
                                            blurRadius: 2,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        if (isPlatinumFrameActive) 
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 6), // Reduced spacing
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0x00FFD700), Color(0xFFFFD700), Color(0x00FFD700)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withOpacity(0.3),
                                  blurRadius: 3,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                          )
                        else 
                          const SizedBox(height: 8), // Reduced spacing between cash and income
                        
                        // Income per second with improved styling - more clear and vibrant, smaller size
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center, // Vertically align items
                          children: [
                            // Label with glowing icon - Wrap in Expanded
                            Expanded(
                              flex: 2, // Give label reasonable space
                              child: Row(
                                mainAxisSize: MainAxisSize.min, // Don't expand horizontally
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: isPlatinumFrameActive
                                        ? BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF4CEA5C), Color(0xFF36C745)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF4CEA5C).withOpacity(0.5),
                                                blurRadius: 8,
                                                spreadRadius: 0,
                                                offset: const Offset(0, 1),
                                              ),
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 4,
                                                spreadRadius: -1,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          )
                                        : null,
                                    child: Icon(
                                      Icons.trending_up,
                                      color: isPlatinumFrameActive ? Colors.white : Colors.grey.shade800,
                                      size: 18, // Reduced from 20
                                    ),
                                  ),
                                  const SizedBox(width: 8), // Reduced from 10
                                  Text(
                                    'Income Rate:',
                                    style: TextStyle(
                                      color: isPlatinumFrameActive ? Colors.white : Colors.grey.shade800,
                                      fontSize: 16, // Reduced from 18
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: isPlatinumFrameActive ? 0.5 : 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Value - Wrap in Expanded
                            Expanded(
                              flex: 3, // Give value more space
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  // FIXED: Use safer income calculation with fallback
                                  _getSafeIncomeDisplay(incomeService, gameState),
                                  key: const Key('incomeDisplay'), // Add a unique key to ensure single instance
                                  style: TextStyle(
                                    color: isPlatinumFrameActive ? const Color(0xFF4CEA5C) : Colors.green.shade700,
                                    fontSize: 18, // Reduced from 20
                                    fontWeight: FontWeight.bold,
                                    shadows: isPlatinumFrameActive
                                        ? [
                                            Shadow(
                                              color: const Color(0xFF4CEA5C).withOpacity(0.5),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1),
                                            ),
                                            Shadow(
                                              color: Colors.black.withOpacity(0.3),
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // Boost timer display - only visible when boost is active
                        if (isBoostCurrentlyActive) ...[
                          const SizedBox(height: 12), // Increased spacing
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Label with boost icon
                              Expanded(
                                flex: 2,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: isPlatinumFrameActive
                                          ? BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFFFF9800).withOpacity(0.5),
                                                  blurRadius: 8,
                                                  spreadRadius: 0,
                                                  offset: const Offset(0, 1),
                                                ),
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.3),
                                                  blurRadius: 4,
                                                  spreadRadius: -1,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            )
                                          : null,
                                      child: Icon(
                                        Icons.bolt,
                                        color: isPlatinumFrameActive ? Colors.white : Colors.orange,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Boost:',
                                      style: TextStyle(
                                        color: isPlatinumFrameActive ? Colors.white : Colors.grey.shade800,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: isPlatinumFrameActive ? 0.5 : 0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Timer value
                              Expanded(
                                flex: 3,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    // FIXED: Use safer boost timer calculation with fallback
                                    _getSafeBoostTimeDisplay(gameState),
                                    style: TextStyle(
                                      color: isPlatinumFrameActive ? const Color(0xFFFF9800) : Colors.orange,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      shadows: isPlatinumFrameActive
                                          ? [
                                              Shadow(
                                                color: const Color(0xFFFF9800).withOpacity(0.5),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                              Shadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 2,
                                                offset: const Offset(0, 1),
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              
              // Simplified platinum frame - no corner accents for cleaner look
            ],
          ),
        );
      },
    );
  }
  
  /// Safe income display with fallback calculation
  String _getSafeIncomeDisplay(IncomeService incomeService, GameState gameState) {
    try {
      // Try to use IncomeService for consistent calculation
      final incomePerSecond = incomeService.calculateIncomePerSecond(gameState);
      return incomeService.formatIncomePerSecond(incomePerSecond);
    } catch (e) {
      // Fallback to direct calculation if IncomeService fails
      print('⚠️ IncomeService failed, using fallback: $e');
      final incomePerSecond = gameState.calculateTotalIncomePerSecond();
      return '${NumberFormatter.formatCurrency(incomePerSecond)}/sec';
    }
  }
  
  /// Safe boost timer display with proper edge case handling
  String _getSafeBoostTimeDisplay(GameState gameState) {
    try {
      if (gameState.clickBoostEndTime == null) {
        return 'Expired';
      }
      
      final now = DateTime.now();
      final endTime = gameState.clickBoostEndTime!;
      final remaining = endTime.difference(now);
      
      // Handle edge cases
      if (remaining.isNegative || remaining.inSeconds <= 0) {
        return 'Expired';
      }
      
      // Use NumberFormatter for consistent formatting
      return NumberFormatter.formatBoostTimeRemaining(remaining);
    } catch (e) {
      print('⚠️ Boost timer calculation failed: $e');
      return 'Error';
    }
  }
  


  // Rich UI component for PP display with animation
  Widget _buildPPDisplay(
    GameState gameState,
    BuildContext context, {
    bool showTutorial = false,
  }) {
    return InkWell(
      onTap: () {
        if (showTutorial) _markPPZoneTutorialShown();
        Navigator.pushNamed(context, '/platinum_vault');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: showTutorial ? Colors.cyan.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: showTutorial
              ? Border.all(color: Colors.cyan.shade600, width: 2)
              : null,
          boxShadow: showTutorial
              ? [
                  BoxShadow(
                    color: Colors.cyan.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated PP Icon
                AnimatedPPIcon(showAnimation: gameState.showPPAnimation),
                const SizedBox(width: 8),
                // PP Amount with improved styling - sharper text
                Text(
                  '${gameState.platinumPoints}',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Color(0xFF000000),
                        blurRadius: 1,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showTutorial)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Tap here to spend your Platinum Points!',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.cyan.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
