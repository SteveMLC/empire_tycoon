import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/leaderboard_entry.dart';
import '../themes/stats_themes.dart';
import '../utils/number_formatter.dart';

/// Widget for displaying a single leaderboard entry
class LeaderboardEntryWidget extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentPlayer;
  final bool isTopThree;
  final StatsTheme theme;
  final VoidCallback? onTap;

  const LeaderboardEntryWidget({
    Key? key,
    required this.entry,
    this.isCurrentPlayer = false,
    this.isTopThree = false,
    required this.theme,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isExecutive = theme.id == 'executive';
    
    // Medal colors for top 3
    Color? medalColor;
    IconData? medalIcon;
    if (entry.rank == 1) {
      medalColor = const Color(0xFFFFD700); // Gold
      medalIcon = Icons.emoji_events;
    } else if (entry.rank == 2) {
      medalColor = const Color(0xFFC0C0C0); // Silver
      medalIcon = Icons.emoji_events;
    } else if (entry.rank == 3) {
      medalColor = const Color(0xFFCD7F32); // Bronze
      medalIcon = Icons.emoji_events;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        gradient: isCurrentPlayer
            ? LinearGradient(
                colors: isExecutive
                    ? [const Color(0xFF2A3A5A), const Color(0xFF1E2840)]
                    : [Colors.blue.shade50, Colors.blue.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : isTopThree
                ? LinearGradient(
                    colors: [
                      medalColor!.withOpacity(isExecutive ? 0.2 : 0.15),
                      medalColor.withOpacity(isExecutive ? 0.1 : 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
        color: isCurrentPlayer || isTopThree
            ? null
            : (isExecutive ? const Color(0xFF1E2430) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentPlayer
              ? (isExecutive ? Colors.blue.shade400 : Colors.blue.shade300)
              : isTopThree
                  ? medalColor!.withOpacity(0.5)
                  : (isExecutive ? const Color(0xFF2A3142) : Colors.grey.shade200),
          width: isCurrentPlayer ? 2 : 1,
        ),
        boxShadow: isTopThree || isCurrentPlayer
            ? [
                BoxShadow(
                  color: (isCurrentPlayer ? Colors.blue : medalColor!)
                      .withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Rank indicator
                SizedBox(
                  width: 40,
                  child: isTopThree
                      ? Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: medalColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: medalColor!.withOpacity(0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              medalIcon,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        )
                      : Text(
                          '#${entry.rank}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isExecutive
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                ),

                const SizedBox(width: 12),

                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isTopThree
                          ? medalColor!
                          : (isExecutive
                              ? const Color(0xFF2A3142)
                              : Colors.grey.shade300),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: entry.avatarUrl != null
                        ? Image.network(
                            entry.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildDefaultAvatar(isExecutive),
                          )
                        : _buildDefaultAvatar(isExecutive),
                  ),
                ),

                const SizedBox(width: 12),

                // Player info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              entry.displayName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isExecutive ? Colors.white : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrentPlayer) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isExecutive
                                    ? Colors.blue.shade700
                                    : Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'YOU',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isExecutive
                                      ? Colors.white
                                      : Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            entry.tierBadge,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            entry.tierDisplayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: isExecutive
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Score
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NumberFormatter.formatCompact(entry.score),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isExecutive
                            ? const Color(0xFFFFD700)
                            : Colors.amber.shade700,
                      ),
                    ),
                    if (entry.percentile > 0)
                      Text(
                        'Top ${entry.percentile.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: isExecutive
                              ? Colors.green.shade300
                              : Colors.green.shade700,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(bool isExecutive) {
    return Container(
      color: isExecutive ? const Color(0xFF2A3142) : Colors.grey.shade200,
      child: Icon(
        Icons.person,
        size: 24,
        color: isExecutive ? Colors.grey.shade400 : Colors.grey.shade500,
      ),
    );
  }
}

/// Loading skeleton for leaderboard entries
class LeaderboardEntrySkeleton extends StatefulWidget {
  final StatsTheme theme;

  const LeaderboardEntrySkeleton({
    Key? key,
    required this.theme,
  }) : super(key: key);

  @override
  State<LeaderboardEntrySkeleton> createState() => _LeaderboardEntrySkeletonState();
}

class _LeaderboardEntrySkeletonState extends State<LeaderboardEntrySkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isExecutive = widget.theme.id == 'executive';

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isExecutive ? const Color(0xFF1E2430) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isExecutive ? const Color(0xFF2A3142) : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              // Rank skeleton
              Container(
                width: 32,
                height: 20,
                decoration: BoxDecoration(
                  color: (isExecutive ? Colors.grey.shade700 : Colors.grey.shade300)
                      .withOpacity(_animation.value),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              // Avatar skeleton
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isExecutive ? Colors.grey.shade700 : Colors.grey.shade300)
                      .withOpacity(_animation.value),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              // Text skeletons
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 120,
                      decoration: BoxDecoration(
                        color: (isExecutive ? Colors.grey.shade700 : Colors.grey.shade300)
                            .withOpacity(_animation.value),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 80,
                      decoration: BoxDecoration(
                        color: (isExecutive ? Colors.grey.shade700 : Colors.grey.shade300)
                            .withOpacity(_animation.value),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              // Score skeleton
              Container(
                height: 20,
                width: 60,
                decoration: BoxDecoration(
                  color: (isExecutive ? Colors.grey.shade700 : Colors.grey.shade300)
                      .withOpacity(_animation.value),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Current player's rank display at bottom
class CurrentPlayerRankBar extends StatelessWidget {
  final LeaderboardEntry entry;
  final StatsTheme theme;
  final VoidCallback? onTap;

  const CurrentPlayerRankBar({
    Key? key,
    required this.entry,
    required this.theme,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isExecutive = theme.id == 'executive';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isExecutive
            ? const Color(0xFF1E2430)
            : Colors.white,
        border: Border(
          top: BorderSide(
            color: isExecutive
                ? const Color(0xFF2A3142)
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Rank
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isExecutive
                    ? Colors.blue.shade700
                    : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#${entry.rank}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isExecutive ? Colors.white : Colors.blue.shade700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Avatar + Name
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.blue.shade400,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: entry.avatarUrl != null
                    ? Image.network(
                        entry.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildDefaultAvatar(isExecutive),
                      )
                    : _buildDefaultAvatar(isExecutive),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isExecutive ? Colors.white : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Your Position',
                    style: TextStyle(
                      fontSize: 12,
                      color: isExecutive
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Score
            Text(
              NumberFormatter.formatCompact(entry.score),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isExecutive
                    ? const Color(0xFFFFD700)
                    : Colors.amber.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(bool isExecutive) {
    return Container(
      color: isExecutive ? const Color(0xFF2A3142) : Colors.grey.shade200,
      child: Icon(
        Icons.person,
        size: 18,
        color: isExecutive ? Colors.grey.shade400 : Colors.grey.shade500,
      ),
    );
  }
}

/// Category tab for leaderboard
class LeaderboardCategoryTab extends StatelessWidget {
  final LeaderboardCategory category;
  final bool isSelected;
  final StatsTheme theme;
  final VoidCallback onTap;

  const LeaderboardCategoryTab({
    Key? key,
    required this.category,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isExecutive = theme.id == 'executive';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isExecutive ? const Color(0xFF2A3A5A) : Colors.blue.shade100)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(
                  color: isExecutive
                      ? Colors.blue.shade400
                      : Colors.blue.shade300,
                  width: 1.5,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category.icon,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Text(
              category.displayName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isExecutive ? Colors.white : Colors.blue.shade700)
                    : (isExecutive ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state widget for leaderboard
class LeaderboardEmptyState extends StatelessWidget {
  final StatsTheme theme;
  final String message;
  final VoidCallback? onRetry;

  const LeaderboardEmptyState({
    Key? key,
    required this.theme,
    this.message = 'No entries yet',
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isExecutive = theme.id == 'executive';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard_outlined,
              size: 64,
              color: isExecutive
                  ? Colors.grey.shade600
                  : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isExecutive
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isExecutive
                      ? const Color(0xFF1A56DB)
                      : Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Share rank button/card
class ShareRankCard extends StatelessWidget {
  final LeaderboardEntry playerEntry;
  final LeaderboardCategory category;
  final StatsTheme theme;
  final GlobalKey repaintKey;

  const ShareRankCard({
    Key? key,
    required this.playerEntry,
    required this.category,
    required this.theme,
    required this.repaintKey,
  }) : super(key: key);

  Future<void> _shareRank(BuildContext context) async {
    try {
      HapticFeedback.mediumImpact();

      // Create a shareable text
      final shareText = '🏆 I\'m ranked #${playerEntry.rank} in ${category.displayName} '
          'on Empire Tycoon with ${NumberFormatter.formatCompact(playerEntry.score)}!\n\n'
          'Think you can beat me? 🎮\n'
          'Download: https://play.google.com/store/apps/details?id=com.empiretycoon.game';

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: shareText));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Rank copied to clipboard! Share it anywhere 🎉'),
            backgroundColor: Colors.green.shade700,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isExecutive = theme.id == 'executive';

    return Container(
      margin: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () => _shareRank(context),
        icon: const Icon(Icons.share, size: 20),
        label: const Text('Share My Rank'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isExecutive
              ? const Color(0xFFFFD700)
              : Colors.amber.shade600,
          foregroundColor: isExecutive ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// Rank change animation indicator
class RankChangeIndicator extends StatelessWidget {
  final int previousRank;
  final int currentRank;
  final StatsTheme theme;

  const RankChangeIndicator({
    Key? key,
    required this.previousRank,
    required this.currentRank,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int change = previousRank - currentRank;
    final bool isExecutive = theme.id == 'executive';

    if (change == 0) return const SizedBox.shrink();

    final bool isPositive = change > 0;
    final Color color = isPositive
        ? Colors.green.shade400
        : Colors.red.shade400;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
          color: color,
          size: 14,
        ),
        const SizedBox(width: 2),
        Text(
          change.abs().toString(),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
