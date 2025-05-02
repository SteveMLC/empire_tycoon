import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/game_state.dart';
import '../money_display.dart';
import '../../utils/number_formatter.dart';
import 'animated_pp_icon.dart';
import '../../painters/luxury_painters.dart';

/// The top panel of the main screen showing cash, income rate, and platinum points
class TopPanel extends StatelessWidget {
  final Function(Duration) formatBoostTimeRemaining;
  final Function(GameState) calculateIncomePerSecond;

  const TopPanel({
    Key? key,
    required this.formatBoostTimeRemaining,
    required this.calculateIncomePerSecond,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    // Get screen width to make panel full width
    final screenWidth = MediaQuery.of(context).size.width;
    final mediaQuery = MediaQuery.of(context);
    
    // Determine if boost is currently active based on GameState
    final bool isBoostCurrentlyActive = gameState.clickMultiplier > 1.0 && 
                                       gameState.clickBoostEndTime != null && 
                                       gameState.clickBoostEndTime!.isAfter(DateTime.now());

    // Check if platinum frame is active
    final bool isPlatinumFrameActive = gameState.isPlatinumFrameUnlocked && gameState.isPlatinumFrameActive;

    return Container(
      width: screenWidth,
      // Reduce overall padding, especially top padding to account for status bar
      padding: EdgeInsets.fromLTRB(
        12, 
        // Add mediaQuery.padding.top to ensure we account for status bar in both modes
        mediaQuery.padding.top + (isPlatinumFrameActive ? 8 : 12), 
        12, 
        isPlatinumFrameActive ? 10 : 12
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
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.3),
                          blurRadius: 6,
                          spreadRadius: 0,
                          offset: const Offset(0, -1),
                        ),
                      ],
                    ) : null,
                    child: Row(
                      children: [
                        if (isPlatinumFrameActive)
                          const Icon(
                            Icons.account_balance,
                            color: Color(0xFF241B38),
                            size: 16,
                          ),
                        if (isPlatinumFrameActive)
                          const SizedBox(width: 4),
                        Text(
                          'INVESTMENT ACCOUNT',
                          style: TextStyle(
                            color: isPlatinumFrameActive ? const Color(0xFF241B38) : Colors.grey.shade700,
                            fontSize: 15, // Reduced from 14
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            shadows: isPlatinumFrameActive 
                                ? [
                                    Shadow(
                                      color: Colors.white.withOpacity(0.6),
                                      blurRadius: 2,
                                      offset: const Offset(0, 0.5),
                                    ),
                                  ] 
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // PP display with enhanced glow
                  _buildPPDisplay(gameState, context),
                ],
              ),
              
              // Tighter spacing for both modes
              SizedBox(height: isPlatinumFrameActive ? 8 : 10),
              
              // Enhanced money container with platinum theme - more depth and dimension
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: isPlatinumFrameActive ? BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1B1E36).withOpacity(0.9),  // Dark base
                      const Color(0xFF262A4F).withOpacity(0.9),  // Rich indigo
                      const Color(0xFF1F2142).withOpacity(0.9),  // Deeper indigo-purple
                    ],
                    stops: [0.0, 0.5, 1.0],
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
                        margin: const EdgeInsets.symmetric(vertical: 6), // Reduced from 10
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
                      const SizedBox(height: 8), // Reduced from 12
                    
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
                              // Calculate income per second
                              '${NumberFormatter.formatCurrency(calculateIncomePerSecond(gameState))}/sec',
                              key: const Key('incomeDisplay'), // Add a unique key to ensure single instance
                              style: TextStyle(
                                color: isPlatinumFrameActive
                                    ? const Color(0xFF4CEA5C)  // Brighter green for platinum theme
                                    : Colors.green.shade700,
                                fontSize: 18, // Reduced from 24
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                shadows: isPlatinumFrameActive
                                    ? [
                                        Shadow(
                                          color: const Color(0xFF4CEA5C).withOpacity(0.6),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                        Shadow(
                                          color: Colors.black.withOpacity(0.5),
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
                ),
              ),
              
              // Active boost timer with premium styling
              if (isBoostCurrentlyActive)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: isPlatinumFrameActive
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF1F2769),  // Deep blue
                              Color(0xFF1A3480),  // Rich blue
                            ],
                          )
                        : null,
                    color: isPlatinumFrameActive ? null : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isPlatinumFrameActive
                          ? const Color(0xFF70C4FF).withOpacity(0.8)
                          : Colors.blue.shade200,
                      width: isPlatinumFrameActive ? 1.5 : 1.0,
                    ),
                    boxShadow: isPlatinumFrameActive
                        ? [
                            BoxShadow(
                              color: const Color(0xFF70C4FF).withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: -2,
                              offset: const Offset(0, 2),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 6,
                              spreadRadius: -2,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isPlatinumFrameActive
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF70A4FF),
                                    Color(0xFF2D78FF),
                                  ],
                                )
                              : null,
                          color: isPlatinumFrameActive ? null : Colors.blue.shade100,
                          boxShadow: isPlatinumFrameActive
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF70C4FF).withOpacity(0.6),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    spreadRadius: -1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          Icons.grid_view,
                          color: isPlatinumFrameActive
                              ? Colors.white
                              : Colors.blue.shade700,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Platinum UI Frame',
                                  style: TextStyle(
                                    color: isPlatinumFrameActive
                                        ? Colors.white
                                        : Colors.blue.shade900,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    letterSpacing: 0.3,
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
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD700),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'PREMIUM',
                                    style: TextStyle(
                                      color: Color(0xFF1F2769),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Luxury UI active',
                              style: TextStyle(
                                color: isPlatinumFrameActive
                                    ? Colors.blue.shade100
                                    : Colors.blue.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: gameState.isPlatinumFrameActive,
                        onChanged: (bool value) {
                          gameState.togglePlatinumFrame(value);
                        },
                        activeColor: const Color(0xFFFFD700),
                        activeTrackColor: const Color(0xFF70C4FF).withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          // Enhanced corner accents (only if platinum frame active)
          if (isPlatinumFrameActive) ...[
            // Top left corner accent
            Positioned(
              top: 0,
              left: 0,
              child: _buildCornerAccent(),
            ),
            // Top right corner accent
            Positioned(
              top: 0,
              right: 0,
              child: Transform.flip(
                flipX: true,
                child: _buildCornerAccent(),
              ),
            ),
            // Bottom left corner accent
            Positioned(
              bottom: 0,
              left: 0,
              child: Transform.flip(
                flipY: true,
                child: _buildCornerAccent(),
              ),
            ),
            // Bottom right corner accent
            Positioned(
              bottom: 0,
              right: 0,
              child: Transform.flip(
                flipX: true,
                flipY: true,
                child: _buildCornerAccent(),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  // Helper method to build luxury corner accents
  Widget _buildCornerAccent() {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: CornerAccentPainter(),
      ),
    );
  }

  // Rich UI component for PP display with animation
  Widget _buildPPDisplay(GameState gameState, BuildContext context) {
    return InkWell(
      onTap: () {
        // TODO: Add check if vault is unlocked (e.g., gameState.platinumPoints > 0 || gameState.vaultUnlocked)
        Navigator.pushNamed(context, '/platinumVault');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
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
      ),
    );
  }
} 