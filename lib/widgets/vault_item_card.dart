import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // To potentially access GameState for owned status?

import '../data/platinum_vault_items.dart';
import '../utils/number_formatter.dart'; // For formatting cost

class VaultItemCard extends StatefulWidget {
  final VaultItem item;
  final int currentPoints;
  final bool isOwned; // For one-time items OR if max repeatable reached
  final VoidCallback onBuy;
  final int? purchaseCount; // Optional: Current purchase count for repeatable items
  final int? maxPurchaseCount; // Optional: Max purchase count for repeatable items
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool canAfford = widget.currentPoints >= widget.item.cost;
    final bool isRepeatable = widget.item.type == VaultItemType.repeatable;
    final bool isMaxedOut = isRepeatable && 
                           widget.maxPurchaseCount != null && 
                           widget.purchaseCount != null && 
                           widget.purchaseCount! >= widget.maxPurchaseCount!;
    final bool isBoosterItem = widget.item.id == 'temp_boost_10x_5min' || widget.item.id == 'temp_boost_2x_10min';
    final bool isThisBoosterActive = isBoosterItem && widget.activeBoostRemainingSeconds != null && widget.activeBoostRemainingSeconds! > 0;
    final bool isPurchasable = (isRepeatable && !isMaxedOut) || (!isRepeatable && !widget.isOwned);
    bool isBuyButtonEnabled = canAfford && isPurchasable;
    if (isBoosterItem && widget.isAnyPlatinumBoostActive) {
      isBuyButtonEnabled = false;
    }

    final buttonText = _getButtonText(canAfford, isRepeatable, widget.isOwned, isMaxedOut, 
                                     widget.purchaseCount, widget.maxPurchaseCount);

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
                              
                              // Status indicator for owned items
                              if (widget.isOwned || isMaxedOut)
                                Positioned(
                                  top: 0,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: widget.isOwned 
                                          ? const Color(0xFFFFD700).withOpacity(0.9)
                                          : Colors.grey.withOpacity(0.9),
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
                                      widget.isOwned ? 'Owned' : 'Maxed',
                                      style: TextStyle(
                                        color: widget.isOwned ? Colors.black : Colors.white,
                                        fontSize: isMobile ? 12 : 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              
                              // Purchasable indicator
                              if (isBuyButtonEnabled && _isHovering)
                                Positioned(
                                  top: 0,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFD700).withOpacity(0.9),
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
                                      'Tap to Buy',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: isMobile ? 12 : 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
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
                                                  ? const Color(0xFF9A55BE)
                                                  : const Color(0xFF8E44AD),
                                              _isHovering
                                                  ? const Color(0xFF7D36A0)
                                                  : const Color(0xFF6C3384),
                                            ]
                                          : [
                                              const Color(0xFF38134A),
                                              const Color(0xFF2D0C3E),
                                            ],
                                    ),
                                    boxShadow: isBuyButtonEnabled
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFFAA00FF).withOpacity(_isHovering ? 0.4 : 0.2),
                                              blurRadius: _isHovering ? 12 : 6,
                                              spreadRadius: _isHovering ? 1 : 0,
                                            ),
                                          ]
                                        : [],
                                    border: Border.all(
                                      color: isBuyButtonEnabled
                                          ? (_isHovering
                                              ? const Color(0xFFFFD700).withOpacity(0.8)
                                              : const Color(0xFFFFD700).withOpacity(0.4))
                                          : Colors.grey.shade700,
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
                                              buttonText,
                                              style: TextStyle(
                                                color: isBuyButtonEnabled
                                                    ? const Color(0xFFFFD700)
                                                    : Colors.grey.shade500,
                                                fontWeight: FontWeight.bold,
                                                fontSize: isMobile ? 16 : 14,
                                                letterSpacing: 0.8,
                                                shadows: isBuyButtonEnabled
                                                    ? [
                                                        Shadow(
                                                          color: Colors.black.withOpacity(0.6),
                                                          blurRadius: 2,
                                                          offset: const Offset(0, 1),
                                                        ),
                                                      ]
                                                    : [],
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

  // Helper function to determine button text
  String _getButtonText(bool canAfford, bool isRepeatable, bool isOwned, bool isMaxedOut, int? purchaseCount, int? maxPurchaseCount) {
    if (!canAfford) {
      return 'Need More P';
    } else if (isMaxedOut) {
      return 'Maxed Out';
    } else if (!isRepeatable && isOwned) {
      return 'Owned';
    } else if (isRepeatable) {
      return 'Purchase';
    } else {
      return 'Buy Now';
    }
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
} 