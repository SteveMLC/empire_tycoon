import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // To potentially access GameState for owned status?
import 'dart:async'; // Import for Timer

import '../data/platinum_vault_items.dart';
import '../utils/number_formatter.dart'; // For formatting cost

class VaultItemCard extends StatefulWidget {
  final VaultItem item;
  final int currentPoints;
  final bool isOwned; // For one-time items OR if max repeatable reached
  final VoidCallback onBuy;
  final int? purchaseCount; // Optional: Current purchase count for repeatable items
  final int? maxPurchaseCount; // Optional: Max purchase count for repeatable items
  final bool isActive; // Is the effect currently active?
  final Duration? activeDurationRemaining; // Remaining duration if active
  final bool isOnCooldown; // Is the item on cooldown?
  final Duration? cooldownDurationRemaining; // Remaining duration if on cooldown
  final int usesLeft; // Uses left for limited-use items (e.g., Time Warp)
  final int maxUses; // Max uses for limited-use items
  final bool isAnyPlatinumBoostActive;
  final int? activeBoostRemainingSeconds; // Remaining seconds if THIS booster is active

  const VaultItemCard({
    Key? key,
    required this.item,
    required this.currentPoints,
    required this.isOwned,
    required this.onBuy,
    this.purchaseCount,
    this.maxPurchaseCount,
    this.isActive = false,
    this.activeDurationRemaining,
    this.isOnCooldown = false,
    this.cooldownDurationRemaining,
    this.usesLeft = 0,
    this.maxUses = 0,
    this.isAnyPlatinumBoostActive = false,
    this.activeBoostRemainingSeconds,
  }) : super(key: key);

  @override
  State<VaultItemCard> createState() => _VaultItemCardState();
}

class _VaultItemCardState extends State<VaultItemCard> with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  Timer? _timer; // Timer for updating remaining duration display
  Duration? _currentActiveRemaining;
  Duration? _currentCooldownRemaining;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _updateTimers();
  }

  @override
  void didUpdateWidget(covariant VaultItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update timers if the relevant durations change
    if (widget.activeDurationRemaining != oldWidget.activeDurationRemaining ||
        widget.cooldownDurationRemaining != oldWidget.cooldownDurationRemaining) {
      _updateTimers();
    }
  }

  void _updateTimers() {
    _timer?.cancel();
    _currentActiveRemaining = widget.activeDurationRemaining;
    _currentCooldownRemaining = widget.cooldownDurationRemaining;

    if ((_currentActiveRemaining != null && _currentActiveRemaining! > Duration.zero) ||
        (_currentCooldownRemaining != null && _currentCooldownRemaining! > Duration.zero)) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          bool activeTimerRunning = false;
          bool cooldownTimerRunning = false;

          if (_currentActiveRemaining != null && _currentActiveRemaining! > Duration.zero) {
            _currentActiveRemaining = _currentActiveRemaining! - const Duration(seconds: 1);
            if (_currentActiveRemaining! <= Duration.zero) {
              _currentActiveRemaining = Duration.zero;
            } else {
               activeTimerRunning = true;
            }
          }
          if (_currentCooldownRemaining != null && _currentCooldownRemaining! > Duration.zero) {
            _currentCooldownRemaining = _currentCooldownRemaining! - const Duration(seconds: 1);
             if (_currentCooldownRemaining! <= Duration.zero) {
              _currentCooldownRemaining = Duration.zero;
            } else {
              cooldownTimerRunning = true;
            }
          }

          if (!activeTimerRunning && !cooldownTimerRunning) {
            timer.cancel();
            _timer = null;
            // Optionally trigger a state refresh from GameState if needed
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // Helper to format duration into HH:MM:SS or MM:SS
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return "${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}";
    } else {
      return "${twoDigits(minutes)}:${twoDigits(seconds)}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canAfford = widget.currentPoints >= widget.item.cost;
    final bool isRepeatable = widget.item.type == VaultItemType.repeatable;
    final bool isOneTimeOwned = !isRepeatable && widget.isOwned;
    final bool isMaxedOut = isRepeatable && 
                           widget.maxPurchaseCount != null && 
                           widget.purchaseCount != null && 
                           widget.purchaseCount! >= widget.maxPurchaseCount!;
    
    // --- Determine purchasability based on new states --- 
    bool isPurchasable = true;
    if (isOneTimeOwned) isPurchasable = false;
    if (isMaxedOut) isPurchasable = false;
    // Use the locally updating timer values for checks
    if (widget.isActive && (_currentActiveRemaining == null || _currentActiveRemaining! > Duration.zero)) isPurchasable = false; // Cannot buy if already active
    if (widget.isOnCooldown && (_currentCooldownRemaining == null || _currentCooldownRemaining! > Duration.zero)) isPurchasable = false; // Cannot buy if on cooldown
    if (widget.item.id == 'platinum_warp' && widget.usesLeft <= 0) isPurchasable = false;
    if ((widget.item.id == 'temp_boost_10x_5min' || widget.item.id == 'temp_boost_2x_10min') && widget.isAnyPlatinumBoostActive) {
       isPurchasable = false; // Cannot buy one booster if another plat booster is active
    }
    // --- End purchasability logic --- 

    bool isBuyButtonEnabled = canAfford && isPurchasable;

    // --- Determine Button Text and Style based on state --- 
    String buttonText = "Purchase"; // Default
    Color buttonColor = const Color(0xFF8E44AD); // Default purple
    Color buttonTextColor = const Color(0xFFFFD700); // Default gold text
    Color buttonBorderColor = const Color(0xFFFFD700).withOpacity(0.4);
    List<BoxShadow>? buttonShadow = [ // Default shadow
      BoxShadow(
        color: const Color(0xFFAA00FF).withOpacity(0.2),
        blurRadius: 6,
        spreadRadius: 0,
      ),
    ];

    if (!canAfford) {
      buttonText = "Insufficient PP";
      buttonColor = const Color(0xFF38134A); // Darker disabled color
      buttonTextColor = Colors.grey.shade600;
      buttonBorderColor = Colors.grey.shade700;
      buttonShadow = [];
    } else if (isOneTimeOwned) {
      buttonText = "Owned";
      buttonColor = const Color(0xFFFFD700); // Gold color for owned
      buttonTextColor = Colors.black;
      buttonBorderColor = const Color(0xFFFFD700).withOpacity(0.8);
       buttonShadow = [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.3), blurRadius: 8)];
    } else if (isMaxedOut) {
       buttonText = "Maxed Out";
       buttonColor = Colors.grey.shade700;
       buttonTextColor = Colors.grey.shade400;
       buttonBorderColor = Colors.grey.shade600;
       buttonShadow = [];
    } else if (widget.isActive && _currentActiveRemaining != null && _currentActiveRemaining! > Duration.zero) {
       buttonText = "Active: ${_formatDuration(_currentActiveRemaining!)}";
       buttonColor = Colors.blue.shade800; // Distinct color for active
       buttonTextColor = Colors.lightBlue.shade100;
       buttonBorderColor = Colors.blue.shade400;
       buttonShadow = [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 8)];
    } else if (widget.isOnCooldown && _currentCooldownRemaining != null && _currentCooldownRemaining! > Duration.zero) {
      buttonText = "Cooldown: ${_formatDuration(_currentCooldownRemaining!)}";
       buttonColor = Colors.orange.shade900; // Distinct color for cooldown
       buttonTextColor = Colors.orange.shade100;
       buttonBorderColor = Colors.orange.shade600;
       buttonShadow = [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 8)];
    } else if (widget.item.id == 'platinum_warp') {
       if (widget.usesLeft > 0) {
         buttonText = "Purchase (${widget.usesLeft}/${widget.maxUses} Left)";
         // Keep default purchase colors
       } else {
         buttonText = "Limit Reached";
         buttonColor = Colors.grey.shade700;
         buttonTextColor = Colors.grey.shade400;
         buttonBorderColor = Colors.grey.shade600;
         buttonShadow = [];
       }
    } else if ((widget.item.id == 'temp_boost_10x_5min' || widget.item.id == 'temp_boost_2x_10min') && widget.isAnyPlatinumBoostActive) {
       // Find which booster IS active to display its timer potentially
       // For now, just show generic text
       buttonText = "Boost Active"; 
       buttonColor = Colors.blue.shade800;
       buttonTextColor = Colors.lightBlue.shade100;
       buttonBorderColor = Colors.blue.shade400;
       buttonShadow = [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 8)];
    }
    // --- End Button Text and Style Logic --- 

    // Check for mobile screen size
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    
    // Adjusted for better mobile readability
    final double iconSize = isMobile ? 50 : 55; 
    final double borderRadius = isMobile ? 16.0 : 16.0;
    final double titleFontSize = isMobile ? 15.0 : 16.0;
    final double descFontSize = isMobile ? 13.0 : 12.0;
    final EdgeInsets contentPadding = isMobile 
        ? const EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 6.0)
        : const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 4.0);
    final double buttonHeight = isMobile ? 42 : 38;

    return MouseRegion(
      onEnter: (_) {
        if (isBuyButtonEnabled) {
          setState(() => _isHovering = true);
          _animationController.forward();
        }
      },
      onExit: (_) {
        setState(() => _isHovering = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return GestureDetector(
            onTap: isBuyButtonEnabled ? widget.onBuy : null,
            child: Transform.scale(
              scale: isBuyButtonEnabled ? _scaleAnimation.value : 1.0,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF3A1249).withOpacity(0.95),
                      const Color(0xFF260B33).withOpacity(0.95),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.isOwned || isMaxedOut
                          ? const Color(0xFFFFD700).withOpacity(0.3 + (_glowAnimation.value * 0.2))
                          : isBuyButtonEnabled && _isHovering
                              ? const Color(0xFFAA00FF).withOpacity(0.3 + (_glowAnimation.value * 0.2))
                              : Colors.black26,
                      blurRadius: 12 + (_glowAnimation.value * 8),
                      spreadRadius: 2 + (_glowAnimation.value * 2),
                    ),
                  ],
                  border: Border.all(
                    width: 1.5,
                    color: widget.isOwned || isMaxedOut
                        ? const Color(0xFFFFD700).withOpacity(0.7)
                        : isBuyButtonEnabled && _isHovering
                            ? const Color(0xFFAA00FF).withOpacity(0.7)
                            : const Color(0xFF4A1259).withOpacity(0.5),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    splashColor: isBuyButtonEnabled 
                        ? const Color(0xFFFFD700).withOpacity(0.3) 
                        : Colors.transparent,
                    highlightColor: isBuyButtonEnabled 
                        ? const Color(0xFFAA00FF).withOpacity(0.1) 
                        : Colors.transparent,
                    onTap: isBuyButtonEnabled ? widget.onBuy : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top section with icon
                        Container(
                          padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF4A1259),
                                const Color(0xFF38134A),
                              ],
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Shine effect
                              Positioned.fill(
                                child: ShaderMask(
                                  blendMode: BlendMode.srcIn,
                                  shaderCallback: (bounds) => LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0.15),
                                      Colors.transparent,
                                    ],
                                  ).createShader(bounds),
                                  child: Container(color: Colors.white),
                                ),
                              ),
                              
                              // Icon with animated glow
                              Container(
                                width: iconSize,
                                height: iconSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(0xFF38134A).withOpacity(0.9),
                                      const Color(0xFF260B33).withOpacity(0.9),
                                    ],
                                  ),
                                  boxShadow: [
                                    if (canAfford)
                                      BoxShadow(
                                        color: const Color(0xFFFFD700).withOpacity(0.4 + (_glowAnimation.value * 0.4)),
                                        blurRadius: 15 + (_glowAnimation.value * 10),
                                        spreadRadius: 1 + (_glowAnimation.value * 2),
                                      ),
                                  ],
                                  border: Border.all(
                                    color: canAfford
                                        ? const Color(0xFFFFD700).withOpacity(0.7 + (_glowAnimation.value * 0.3))
                                        : Colors.grey.withOpacity(0.4),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  widget.item.iconData ?? Icons.shopping_bag,
                                  size: isMobile ? 28 : 28,
                                  color: canAfford
                                      ? const Color(0xFFFFD700).withOpacity(0.8 + (_glowAnimation.value * 0.2))
                                      : Colors.grey.shade400,
                                ),
                              ),
                              
                              // Status indicator for owned items OR maxed out
                              if (isOneTimeOwned || isMaxedOut)
                                Positioned(
                                  top: 0,
                                  right: 16,
                                  child: _buildStatusIndicator(isOneTimeOwned, isMaxedOut),
                                ),
                            ],
                          ),
                        ),
                        
                        // Title and description - allow 2 lines for title to avoid truncation
                        Padding(
                          padding: contentPadding,
                          child: LayoutBuilder(
                            builder: (context, constraints) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.item.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: titleFontSize,
                                    color: widget.isOwned
                                        ? const Color(0xFFFFD700)
                                        : Colors.white,
                                    height: 1.2, // Add line height to ensure readability
                                    letterSpacing: 0.5,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.6),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  maxLines: 2, // Allow two lines for title
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: isMobile ? 8 : 4),
                                Container(
                                  constraints: BoxConstraints(
                                    maxHeight: constraints.maxHeight * (isMobile ? 0.25 : 0.3)
                                  ),
                                  child: Text(
                                    widget.item.description,
                                    style: TextStyle(
                                      fontSize: descFontSize,
                                      color: Colors.grey.shade300,
                                      height: 1.3, // Increase line height for better readability
                                    ),
                                    maxLines: isMobile ? 3 : 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Info button for detailed description
                                if (widget.item.description.length > 80)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: GestureDetector(
                                      onTap: () {
                                        _showFullDescription(context);
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black12,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.info_outline,
                                          size: isMobile ? 16 : 16,
                                          color: const Color(0xFFFFD700).withOpacity(0.7),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Spacer to push cost and button to bottom
                        const Spacer(),
                        
                        // Cost display and buy button
                        Padding(
                          padding: EdgeInsets.fromLTRB(12.0, 0, 12.0, isMobile ? 12.0 : 8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Cost with premium coin indicator
                              GestureDetector(
                                onTap: isBuyButtonEnabled ? widget.onBuy : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: canAfford
                                          ? const Color(0xFFFFD700).withOpacity(0.6)
                                          : Colors.red.shade300.withOpacity(0.4),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: canAfford
                                            ? const Color(0xFFFFD700).withOpacity(0.2)
                                            : Colors.transparent,
                                        blurRadius: 8,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Premium coin
                                      Container(
                                        width: isMobile ? 20 : 18,
                                        height: isMobile ? 20 : 18,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              const Color(0xFFFFD700),
                                              const Color(0xFFFFBC00),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFFFD700).withOpacity(0.7),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Text(
                                            '✦',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.item.cost.toString(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isMobile ? 16 : 14,
                                          color: canAfford
                                              ? const Color(0xFFFFD700)
                                              : Colors.red.shade300,
                                          letterSpacing: 0.5,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withOpacity(0.6),
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Buy button with improved styling for mobile
                              SizedBox(
                                width: double.infinity,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: buttonHeight,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: isBuyButtonEnabled
                                          ? [
                                              _isHovering
                                                  ? Color.lerp(buttonColor, Colors.white, 0.1)! // Slightly lighter on hover
                                                  : buttonColor,
                                              _isHovering
                                                  ? Color.lerp(buttonColor, Colors.black, 0.1)! // Slightly darker on hover
                                                  : buttonColor.withOpacity(0.8),
                                            ]
                                          : [
                                              buttonColor, // Use the determined disabled/status color
                                              buttonColor.withOpacity(0.8),
                                            ],
                                    ),
                                    boxShadow: isBuyButtonEnabled
                                        ? buttonShadow // Use determined shadow
                                        : [], // No shadow when disabled
                                    border: Border.all(
                                      color: isBuyButtonEnabled
                                          ? (_isHovering
                                              ? buttonBorderColor.withOpacity(0.8)
                                              : buttonBorderColor)
                                          : buttonBorderColor, // Use determined border color
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: isBuyButtonEnabled ? widget.onBuy : null,
                                      splashColor: const Color(0xFFFFD700).withOpacity(0.1),
                                      highlightColor: const Color(0xFFFFD700).withOpacity(0.05),
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            if (isBuyButtonEnabled && _isHovering)
                                              Padding(
                                                padding: const EdgeInsets.only(right: 8.0),
                                                child: Icon(
                                                  Icons.shopping_cart,
                                                  size: isMobile ? 18 : 16,
                                                  color: const Color(0xFFFFD700),
                                                ),
                                              ),
                                            Text(
                                              buttonText, // Use the determined text
                                              style: TextStyle(
                                                color: isBuyButtonEnabled
                                                    ? buttonTextColor // Use determined text color
                                                    : buttonTextColor, // Use determined disabled/status text color
                                                fontWeight: FontWeight.bold,
                                                fontSize: isMobile ? 16 : 14,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Purchase count indicator for repeatable items
                              if (isRepeatable && widget.purchaseCount != null && widget.maxPurchaseCount != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Progress bar
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: widget.purchaseCount! / widget.maxPurchaseCount!,
                                            backgroundColor: Colors.grey.shade800.withOpacity(0.5),
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              isMaxedOut
                                                  ? const Color(0xFFFFD700).withOpacity(0.7)
                                                  : const Color(0xFFAA00FF).withOpacity(0.7),
                                            ),
                                            minHeight: isMobile ? 4 : 3,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "${widget.purchaseCount}/${widget.maxPurchaseCount}",
                                        style: TextStyle(
                                          fontSize: isMobile ? 14 : 10,
                                          color: isMaxedOut
                                              ? const Color(0xFFFFD700)
                                              : Colors.grey.shade400,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
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
            ),
          );
        },
      ),
    );
  }

  void _showFullDescription(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          widget.item.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFD700),
            fontSize: 18,
          ),
        ),
        content: Container(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 400,
            maxHeight: isMobile ? 300 : 400,
          ),
          child: SingleChildScrollView(
            child: Text(
              widget.item.description,
              style: TextStyle(
                fontSize: isMobile ? 16 : 14,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
        ),
        backgroundColor: const Color(0xFF2D0C3E),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF8E44AD),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFFFD700), width: 1),
                ),
              ),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.only(bottom: 16),
      ),
    );
  }

  Widget _buildActiveBoosterStatus() {
    if (widget.activeBoostRemainingSeconds == null || widget.activeBoostRemainingSeconds! <= 0) {
      return const SizedBox.shrink(); // Should not happen if isThisBoosterActive is true
    }

    final minutes = widget.activeBoostRemainingSeconds! ~/ 60;
    final seconds = widget.activeBoostRemainingSeconds! % 60;
    final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      height: 42, // Match button height
      decoration: BoxDecoration(
        color: Colors.purple.shade700, // Use a distinct active color
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.purple.shade300),
      ),
      child: Center(
        child: Text(
          'Active: $timeString',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseButton(bool isEnabled, String text, bool canAfford, double height) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isEnabled
                ? [const Color(0xFFFFD700), const Color(0xFFE5C100)]
                : [Colors.grey.shade600, Colors.grey.shade500],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Optional: Add cost icon
              if (isEnabled && canAfford)
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF260B33), // Dark purple contrast
                  ),
                  child: const Center(
                    child: Text(
                      '✦',
                      style: TextStyle(
                        fontSize: 9,
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              Text(
                isEnabled ? '${widget.item.cost} - $text' : text,
                style: TextStyle(
                  color: isEnabled ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to build the status indicator (Owned/Maxed)
  Widget _buildStatusIndicator(bool isOneTimeOwned, bool isMaxedOut) {
    String text = "";
    Color bgColor = Colors.grey;
    Color textColor = Colors.white;

    if (isOneTimeOwned) {
      text = "Owned";
      bgColor = const Color(0xFFFFD700).withOpacity(0.9);
      textColor = Colors.black;
    } else if (isMaxedOut) {
      text = "Maxed";
      bgColor = Colors.grey.withOpacity(0.9);
    } else {
      return const SizedBox.shrink(); // No indicator if not owned/maxed
    }

    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: isMobile ? 12 : 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 