import 'package:flutter/material.dart';
import 'dart:async';

import '../data/platinum_vault_items.dart';

// Rarity tiers based on cost
enum ItemRarity { common, rare, epic, legendary }

ItemRarity getRarity(int cost) {
  if (cost >= 150) return ItemRarity.legendary;
  if (cost >= 100) return ItemRarity.epic;
  if (cost >= 50) return ItemRarity.rare;
  return ItemRarity.common;
}

// Rarity colors and styling
class RarityStyle {
  final Color primary;
  final Color secondary;
  final Color glow;
  final String label;
  
  const RarityStyle({
    required this.primary,
    required this.secondary,
    required this.glow,
    required this.label,
  });
  
  static RarityStyle forRarity(ItemRarity rarity) {
    switch (rarity) {
      case ItemRarity.legendary:
        return const RarityStyle(
          primary: Color(0xFFFFD700),     // Gold
          secondary: Color(0xFFFF8C00),   // Dark orange
          glow: Color(0xFFFFD700),
          label: '★ LEGENDARY',
        );
      case ItemRarity.epic:
        return const RarityStyle(
          primary: Color(0xFFAB47BC),     // Purple
          secondary: Color(0xFF7B1FA2),   // Deep purple
          glow: Color(0xFFCE93D8),
          label: '◆ EPIC',
        );
      case ItemRarity.rare:
        return const RarityStyle(
          primary: Color(0xFF42A5F5),     // Blue
          secondary: Color(0xFF1976D2),   // Deep blue
          glow: Color(0xFF90CAF9),
          label: '● RARE',
        );
      case ItemRarity.common:
        return const RarityStyle(
          primary: Color(0xFFE0E0E0),     // Light silver/white
          secondary: Color(0xFFBDBDBD),   // Medium grey
          glow: Color(0xFFFFFFFF),
          label: '',  // No badge for common
        );
    }
  }
}

// Premium vault theme colors
class VaultColors {
  static const Color cardBg = Color(0xFF1A1D24);
  static const Color cardBgLight = Color(0xFF252A34);
  static const Color border = Color(0xFF3A3F4B);
  static const Color gold = Color(0xFFFFD700);
  static const Color goldDark = Color(0xFFB8860B);
  static const Color goldLight = Color(0xFFFFF4CC);
  static const Color textPrimary = Color(0xFFF0F2F5);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color success = Color(0xFF10B981);
  static const Color active = Color(0xFF3B82F6);
  static const Color cooldown = Color(0xFFF59E0B);
}

class VaultItemCard extends StatefulWidget {
  final VaultItem item;
  final int currentPoints;
  final bool isOwned;
  final VoidCallback onBuy;
  final int? purchaseCount;
  final int? maxPurchaseCount;
  final bool isActive;
  final Duration? activeDurationRemaining;
  final bool isOnCooldown;
  final Duration? cooldownDurationRemaining;
  final int usesLeft;
  final int maxUses;
  final bool isAnyPlatinumBoostActive;
  final int? activeBoostRemainingSeconds;

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
  late AnimationController _glowController;
  Timer? _timer;
  Duration? _currentActiveRemaining;
  Duration? _currentCooldownRemaining;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _updateTimers();
  }

  @override
  void didUpdateWidget(covariant VaultItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
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
        if (!mounted) { timer.cancel(); return; }
        bool needsUpdate = false;
        if (_currentActiveRemaining != null && _currentActiveRemaining! > Duration.zero) {
          _currentActiveRemaining = _currentActiveRemaining! - const Duration(seconds: 1);
          needsUpdate = true;
        }
        if (_currentCooldownRemaining != null && _currentCooldownRemaining! > Duration.zero) {
          _currentCooldownRemaining = _currentCooldownRemaining! - const Duration(seconds: 1);
          needsUpdate = true;
        }
        if (needsUpdate) setState(() {});
        if ((_currentActiveRemaining == null || _currentActiveRemaining! <= Duration.zero) &&
            (_currentCooldownRemaining == null || _currentCooldownRemaining! <= Duration.zero)) {
          timer.cancel();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  Color _accentColor(VaultItemCategory cat) {
    switch (cat) {
      case VaultItemCategory.boosters: return const Color(0xFFFFB020);
      case VaultItemCategory.cosmetics: return const Color(0xFFE040FB);
      case VaultItemCategory.eventsAndChallenges: return const Color(0xFFFF6D00);
      case VaultItemCategory.unlockables: return const Color(0xFF00B0FF);
      case VaultItemCategory.upgrades: return const Color(0xFF00E676);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAfford = widget.currentPoints >= widget.item.cost;
    final isRepeatable = widget.item.type == VaultItemType.repeatable;
    final isOneTimeOwned = !isRepeatable && widget.isOwned;
    final isMaxedOut = isRepeatable &&
        widget.maxPurchaseCount != null &&
        widget.purchaseCount != null &&
        widget.purchaseCount! >= widget.maxPurchaseCount!;

    bool isPurchasable = true;
    if (isOneTimeOwned) isPurchasable = false;
    if (isMaxedOut) isPurchasable = false;
    if (widget.isActive && (_currentActiveRemaining == null || _currentActiveRemaining! > Duration.zero)) isPurchasable = false;
    if (widget.isOnCooldown && (_currentCooldownRemaining == null || _currentCooldownRemaining! > Duration.zero)) isPurchasable = false;
    if (widget.item.id == 'platinum_warp' && widget.usesLeft <= 0) isPurchasable = false;

    final isBuyEnabled = canAfford && isPurchasable;
    final isInteractive = isBuyEnabled || (widget.item.id == 'platinum_yacht' && widget.isOwned);
    final isActive = widget.isActive && _currentActiveRemaining != null && _currentActiveRemaining! > Duration.zero;
    final isOnCooldown = widget.isOnCooldown && _currentCooldownRemaining != null && _currentCooldownRemaining! > Duration.zero;
    
    // Get rarity styling
    final rarity = getRarity(widget.item.cost);
    final rarityStyle = RarityStyle.forRarity(rarity);
    final accent = _accentColor(widget.item.category);

    // No full-card tap - purchase only via BUY button
    return AnimatedBuilder(
        animation: _glowController,
        builder: (context, _) {
          final glowVal = _glowController.value;
          final isLegendary = rarity == ItemRarity.legendary;
          final isEpic = rarity == ItemRarity.epic;
          
          // Dynamic border color based on rarity and state
          Color borderColor;
          double borderWidth = 1.5;
          if (isOneTimeOwned || isMaxedOut) {
            borderColor = VaultColors.gold.withOpacity(0.8 + glowVal * 0.2);
            borderWidth = 2.5;
          } else if (isActive) {
            borderColor = accent.withOpacity(0.9);
            borderWidth = 2;
          } else if (isOnCooldown) {
            borderColor = VaultColors.cooldown.withOpacity(0.7);
          } else if (isLegendary) {
            borderColor = Color.lerp(rarityStyle.primary, rarityStyle.secondary, glowVal)!.withOpacity(0.8);
            borderWidth = 2;
          } else if (isEpic) {
            borderColor = rarityStyle.primary.withOpacity(0.6 + glowVal * 0.2);
          } else if (canAfford) {
            borderColor = accent.withOpacity(0.5);
          } else {
            borderColor = VaultColors.border.withOpacity(0.5);
          }

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              // Rich gradient background based on rarity
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isLegendary ? [
                  const Color(0xFF2A2215), // Dark gold tint
                  const Color(0xFF1A1510),
                  const Color(0xFF151210),
                ] : isEpic ? [
                  const Color(0xFF1F1A28), // Dark purple tint
                  const Color(0xFF151218),
                  const Color(0xFF100E14),
                ] : rarity == ItemRarity.rare ? [
                  const Color(0xFF151D28), // Dark blue tint
                  const Color(0xFF121820),
                  const Color(0xFF0E1318),
                ] : [
                  const Color(0xFF1F2226), // Lighter for common - more visible
                  const Color(0xFF1A1D22),
                  const Color(0xFF16191E),
                ],
              ),
              border: Border.all(width: borderWidth, color: borderColor),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4)),
                if (isOneTimeOwned || isMaxedOut)
                  BoxShadow(color: VaultColors.gold.withOpacity(0.2 + glowVal * 0.2), blurRadius: 24, spreadRadius: 2),
                if (isActive)
                  BoxShadow(color: accent.withOpacity(0.3 + glowVal * 0.2), blurRadius: 20, spreadRadius: 2),
                if (isLegendary && !isOneTimeOwned)
                  BoxShadow(color: rarityStyle.glow.withOpacity(0.15 + glowVal * 0.1), blurRadius: 16, spreadRadius: 1),
                if (isEpic && !isOneTimeOwned)
                  BoxShadow(color: rarityStyle.glow.withOpacity(0.1 + glowVal * 0.08), blurRadius: 12),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Rarity gradient overlay at top
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          rarityStyle.primary.withOpacity(isLegendary ? 0.35 : isEpic ? 0.25 : rarity == ItemRarity.rare ? 0.18 : 0.12),
                          rarityStyle.secondary.withOpacity(0.05),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),
                // Static diagonal shine for legendary/epic (no animation)
                if (isLegendary || isEpic)
                  Positioned(
                    right: -20,
                    top: -10,
                    child: Transform.rotate(
                      angle: -0.5,
                      child: Container(
                        width: 60,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(isLegendary ? 0.12 : 0.06),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                // Corner accent for legendary
                if (isLegendary)
                  Positioned(
                    top: 0, right: 0,
                    child: Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topRight,
                          radius: 1.2,
                          colors: [
                            VaultColors.gold.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                // Main content
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon + Title row (titles now align across all cards)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon with rarity indicator
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      rarityStyle.primary.withOpacity(0.4),
                                      rarityStyle.secondary.withOpacity(0.2),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: (isOneTimeOwned || canAfford) 
                                        ? VaultColors.gold.withOpacity(0.7 + glowVal * 0.3)
                                        : rarityStyle.primary.withOpacity(0.5),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isOneTimeOwned || canAfford)
                                          ? VaultColors.gold.withOpacity(0.35)
                                          : rarityStyle.glow.withOpacity(0.2),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  widget.item.iconData ?? Icons.star,
                                  size: 20,
                                  color: (isOneTimeOwned || canAfford) ? VaultColors.gold : rarityStyle.primary,
                                ),
                              ),
                              // Rarity badge on icon (only for rare+)
                              if (rarityStyle.label.isNotEmpty)
                                Positioned(
                                  bottom: -2,
                                  right: -4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [rarityStyle.primary, rarityStyle.secondary],
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF1A1D24), width: 1.5),
                                      boxShadow: [
                                        BoxShadow(color: rarityStyle.glow.withOpacity(0.5), blurRadius: 4),
                                      ],
                                    ),
                                    child: Text(
                                      rarity == ItemRarity.legendary ? '★' : rarity == ItemRarity.epic ? '◆' : '●',
                                      style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          // Title
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.item.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: isOneTimeOwned 
                                        ? VaultColors.gold 
                                        : isLegendary 
                                            ? const Color(0xFFFFE082)
                                            : VaultColors.textPrimary,
                                    height: 1.2,
                                    shadows: isLegendary ? [
                                      Shadow(color: VaultColors.gold.withOpacity(0.5), blurRadius: 8),
                                    ] : null,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (isOneTimeOwned || isMaxedOut || isActive || isOnCooldown) ...[
                                  const SizedBox(height: 4),
                                  _buildStatusChip(isOneTimeOwned, isMaxedOut, isActive, isOnCooldown, accent),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Description
                      Expanded(
                        child: Text(
                          widget.item.description,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: VaultColors.textSecondary,
                            height: 1.35,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Cost + Button row
                      Row(
                        children: [
                          // Cost pill with glow
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: canAfford 
                                    ? [const Color(0xFF2A2510), const Color(0xFF1A1808)]
                                    : [const Color(0xFF2A1515), const Color(0xFF1A0E0E)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: canAfford 
                                    ? VaultColors.gold.withOpacity(0.6) 
                                    : Colors.red.withOpacity(0.4),
                                width: 1.5,
                              ),
                              boxShadow: canAfford ? [
                                BoxShadow(color: VaultColors.gold.withOpacity(0.2), blurRadius: 8),
                              ] : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 16, height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [VaultColors.gold, VaultColors.goldDark],
                                    ),
                                    boxShadow: [
                                      BoxShadow(color: VaultColors.gold.withOpacity(0.4), blurRadius: 3),
                                    ],
                                  ),
                                  child: const Icon(Icons.star_rounded, size: 10, color: Colors.white),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${widget.item.cost} PP',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: canAfford ? VaultColors.gold : const Color(0xFFFF6B6B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Action button - only tappable element for purchase
                          Expanded(
                            child: GestureDetector(
                              onTap: isInteractive ? widget.onBuy : null,
                              child: _buildButton(canAfford, isBuyEnabled, isOneTimeOwned, isMaxedOut, isActive, isOnCooldown, rarityStyle),
                            ),
                          ),
                        ],
                      ),
                      // Progress bar for repeatables (compact)
                      if (isRepeatable && widget.purchaseCount != null && widget.maxPurchaseCount != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: VaultColors.border.withOpacity(0.3),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: widget.purchaseCount! / widget.maxPurchaseCount!,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      gradient: LinearGradient(
                                        colors: isMaxedOut 
                                            ? [VaultColors.gold, VaultColors.goldDark]
                                            : [accent, accent.withOpacity(0.7)],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (isMaxedOut ? VaultColors.gold : accent).withOpacity(0.4),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${widget.purchaseCount}/${widget.maxPurchaseCount}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isMaxedOut ? VaultColors.gold : VaultColors.textSecondary,
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
          );
        },
      );
  }

  Widget _buildStatusChip(bool isOwned, bool isMaxed, bool isActive, bool isOnCooldown, Color accent) {
    String label;
    Color bg;
    Color fg;
    List<BoxShadow>? shadows;
    
    if (isOwned) {
      label = '✓ OWNED';
      bg = VaultColors.gold;
      fg = Colors.black;
      shadows = [BoxShadow(color: VaultColors.gold.withOpacity(0.5), blurRadius: 6)];
    } else if (isMaxed) {
      label = '★ MAXED';
      bg = VaultColors.gold;
      fg = Colors.black;
      shadows = [BoxShadow(color: VaultColors.gold.withOpacity(0.4), blurRadius: 6)];
    } else if (isActive) {
      label = '⚡ ${_formatDuration(_currentActiveRemaining!)}';
      bg = accent;
      fg = Colors.white;
      shadows = [BoxShadow(color: accent.withOpacity(0.5), blurRadius: 6)];
    } else {
      label = '⏳ ${_formatDuration(_currentCooldownRemaining!)}';
      bg = VaultColors.cooldown;
      fg = Colors.white;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        boxShadow: shadows,
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Widget _buildButton(bool canAfford, bool isEnabled, bool isOwned, bool isMaxed, bool isActive, bool isOnCooldown, RarityStyle rarityStyle) {
    String text;
    Color bg;
    Color fg;
    Color borderColor;
    List<BoxShadow>? shadows;
    
    if (isOwned) {
      text = widget.item.id == 'platinum_yacht' ? 'Manage' : 'Owned';
      bg = VaultColors.gold;
      fg = Colors.black;
      borderColor = VaultColors.gold;
      shadows = [BoxShadow(color: VaultColors.gold.withOpacity(0.4), blurRadius: 8)];
    } else if (isMaxed) {
      text = 'Maxed';
      bg = VaultColors.gold.withOpacity(0.2);
      fg = VaultColors.gold;
      borderColor = VaultColors.gold.withOpacity(0.5);
    } else if (isActive) {
      text = 'Active';
      bg = VaultColors.active;
      fg = Colors.white;
      borderColor = VaultColors.active;
      shadows = [BoxShadow(color: VaultColors.active.withOpacity(0.4), blurRadius: 8)];
    } else if (isOnCooldown) {
      text = 'Cooldown';
      bg = VaultColors.cooldown.withOpacity(0.2);
      fg = VaultColors.cooldown;
      borderColor = VaultColors.cooldown.withOpacity(0.6);
    } else if (!canAfford) {
      text = 'Locked';
      bg = Colors.transparent;
      fg = VaultColors.textSecondary.withOpacity(0.6);
      borderColor = VaultColors.border.withOpacity(0.3);
    } else if (widget.item.id == 'platinum_warp' && widget.usesLeft <= 0) {
      text = 'Limit';
      bg = VaultColors.border.withOpacity(0.3);
      fg = VaultColors.textSecondary;
      borderColor = VaultColors.border;
    } else {
      text = 'BUY';
      bg = VaultColors.gold.withOpacity(0.15);
      fg = VaultColors.gold;
      borderColor = VaultColors.gold.withOpacity(0.7);
      shadows = [BoxShadow(color: VaultColors.gold.withOpacity(0.3), blurRadius: 10)];
    }
    
    if (widget.item.id == 'platinum_warp' && widget.usesLeft > 0 && isEnabled) {
      text = 'BUY (${widget.usesLeft})';
    }
    
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: shadows,
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: fg,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
} 