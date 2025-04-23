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

  const VaultItemCard({
    Key? key,
    required this.item,
    required this.currentPoints,
    required this.isOwned,
    required this.onBuy,
    this.purchaseCount,
    this.maxPurchaseCount,
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
    final bool isPurchasable = (isRepeatable && !isMaxedOut) || (!isRepeatable && !widget.isOwned);
    final bool isBuyButtonEnabled = canAfford && isPurchasable;

    final buttonText = _getButtonText(canAfford, isRepeatable, widget.isOwned, isMaxedOut, 
                                     widget.purchaseCount, widget.maxPurchaseCount);

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
                  borderRadius: BorderRadius.circular(16.0),
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                                width: 65,
                                height: 65,
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
                                  size: 32,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                        fontSize: 10,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                    child: const Text(
                                      'Tap to Buy',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        // Title and description
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.item.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: widget.isOwned
                                      ? const Color(0xFFFFD700)
                                      : Colors.white,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.6),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 60, // Increased height for more text visibility
                                child: Text(
                                  widget.item.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade300,
                                    height: 1.3,
                                  ),
                                  maxLines: 3, // Allow up to 3 lines for description
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Optional tooltip/info button for full description
                              if (widget.item.description.length > 100)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () {
                                      _showFullDescription(context);
                                    },
                                    child: Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        // Spacer to push cost and button to bottom
                        const Spacer(),
                        
                        // Cost display and buy button
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                          child: Column(
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
                                        width: 20,
                                        height: 20,
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
                                          fontSize: 16,
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
                              
                              // Buy button with improved styling
                              SizedBox(
                                width: double.infinity,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 46,
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
                                                  size: 18,
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
                                                fontSize: 15,
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
                                            minHeight: 4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "${widget.purchaseCount}/${widget.maxPurchaseCount}",
                                        style: TextStyle(
                                          fontSize: 12,
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

  // Modified helper function to determine button text
  String _getButtonText(bool canAfford, bool isRepeatable, bool isOwned, bool isMaxedOut, int? purchaseCount, int? maxPurchaseCount) {
    if (!canAfford) {
      // Change to make the button text more informative without relying on external "Not Enough P" text
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          widget.item.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFD700),
          ),
        ),
        content: Text(widget.item.description),
        backgroundColor: const Color(0xFF2D0C3E),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFFFD700), width: 1),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFFFFD700)),
            ),
          ),
        ],
      ),
    );
  }
} 