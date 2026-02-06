import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/daily_reward.dart';

class DailyRewardPopup extends StatefulWidget {
  final DailyReward reward;
  final List<DailyReward> allRewards;
  final bool streakBroken;
  final int currentDay;
  final Future<void> Function() onClaim;

  const DailyRewardPopup({
    super.key,
    required this.reward,
    required this.allRewards,
    required this.streakBroken,
    required this.currentDay,
    required this.onClaim,
  });

  static Future<void> show(
    BuildContext context, {
    required DailyReward reward,
    required List<DailyReward> allRewards,
    required bool streakBroken,
    required int currentDay,
    required Future<void> Function() onClaim,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => DailyRewardPopup(
        reward: reward,
        allRewards: allRewards,
        streakBroken: streakBroken,
        currentDay: currentDay,
        onClaim: onClaim,
      ),
    );
  }

  @override
  State<DailyRewardPopup> createState() => _DailyRewardPopupState();
}

class _DailyRewardPopupState extends State<DailyRewardPopup> {
  bool _isClaiming = false;
  bool _showConfetti = false;
  late final List<_ConfettiPiece> _confettiPieces;

  @override
  void initState() {
    super.initState();
    _confettiPieces = _buildConfettiPieces();
  }

  List<_ConfettiPiece> _buildConfettiPieces() {
    final Random random = Random();
    final List<Color> palette = [
      const Color(0xFFFFC857),
      const Color(0xFF4CC9F0),
      const Color(0xFFF72585),
      const Color(0xFF4361EE),
      const Color(0xFFB5179E),
    ];
    return List<_ConfettiPiece>.generate(60, (index) {
      final double angle = random.nextDouble() * pi * 2;
      final double distance = 90 + random.nextDouble() * 120;
      final double size = 4 + random.nextDouble() * 6;
      return _ConfettiPiece(
        angle: angle,
        distance: distance,
        size: size,
        color: palette[random.nextInt(palette.length)],
        rotation: random.nextDouble() * pi,
      );
    });
  }

  Future<void> _handleClaim() async {
    if (_isClaiming) return;
    setState(() {
      _isClaiming = true;
      _showConfetti = true;
    });

    HapticFeedback.heavyImpact();

    await widget.onClaim();

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color primary = theme.colorScheme.primary;
    final Color surface = theme.dialogBackgroundColor;
    final Color onSurface = theme.colorScheme.onSurface;

    return Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'DAILY REWARD',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                if (widget.streakBroken)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'You missed yesterday! Streak reset to Day 1.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                _StreakHeader(
                  day: widget.currentDay,
                  primary: primary,
                  onSurface: onSurface,
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: widget.currentDay / 7,
                  minHeight: 8,
                  backgroundColor: primary.withOpacity(0.15),
                  color: primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(height: 16),
                _DaysRow(
                  rewards: widget.allRewards,
                  currentDay: widget.currentDay,
                  primary: primary,
                ),
                const SizedBox(height: 20),
                _RewardShowcase(reward: widget.reward, primary: primary),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isClaiming ? null : _handleClaim,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _isClaiming ? 'CLAIMING...' : 'CLAIM',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showConfetti)
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                onEnd: () {
                  if (mounted) {
                    setState(() {
                      _showConfetti = false;
                    });
                  }
                },
                builder: (context, value, child) {
                  return CustomPaint(
                    painter: _ConfettiPainter(
                      progress: value,
                      pieces: _confettiPieces,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _StreakHeader extends StatelessWidget {
  final int day;
  final Color primary;
  final Color onSurface;

  const _StreakHeader({
    required this.day,
    required this.primary,
    required this.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Day $day of 7',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: onSurface,
              ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Streak: $day days',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
          ),
        ),
      ],
    );
  }
}

class _DaysRow extends StatelessWidget {
  final List<DailyReward> rewards;
  final int currentDay;
  final Color primary;

  const _DaysRow({
    required this.rewards,
    required this.currentDay,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: rewards.map((reward) {
        final bool isClaimed = reward.day < currentDay;
        final bool isToday = reward.day == currentDay;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isToday ? primary.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isToday ? primary : Colors.black12,
                width: isToday ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  isClaimed ? '✓' : reward.icon,
                  style: TextStyle(
                    fontSize: 16,
                    color: isClaimed ? primary : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'D${reward.day}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isToday ? primary : Colors.black54,
                      ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RewardShowcase extends StatelessWidget {
  final DailyReward reward;
  final Color primary;

  const _RewardShowcase({
    required this.reward,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final String title = _rewardTitle(reward);
    final String subtitle = _rewardSubtitle(reward);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            "TODAY'S REWARD",
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: primary,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            reward.icon,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                ),
          ),
        ],
      ),
    );
  }

  String _rewardTitle(DailyReward reward) {
    switch (reward.type) {
      case DailyRewardType.cash:
        return '${reward.value.toStringAsFixed(0)} min income';
      case DailyRewardType.boost:
        return '2x Boost (${reward.value.toStringAsFixed(0)} min)';
      case DailyRewardType.mega:
        return 'Mega Reward';
    }
  }

  String _rewardSubtitle(DailyReward reward) {
    switch (reward.type) {
      case DailyRewardType.cash:
        return reward.description;
      case DailyRewardType.boost:
        return reward.description;
      case DailyRewardType.mega:
        return '2h income + 15 min 2x boost';
    }
  }
}

class _ConfettiPiece {
  final double angle;
  final double distance;
  final double size;
  final double rotation;
  final Color color;

  const _ConfettiPiece({
    required this.angle,
    required this.distance,
    required this.size,
    required this.rotation,
    required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiPiece> pieces;

  _ConfettiPainter({
    required this.progress,
    required this.pieces,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2.5);
    final Paint paint = Paint();

    for (final piece in pieces) {
      final double travel = piece.distance * progress;
      final double dx = cos(piece.angle) * travel;
      final double dy = sin(piece.angle) * travel + (progress * progress * 30);
      final double opacity = (1 - progress).clamp(0.0, 1.0);

      paint.color = piece.color.withOpacity(opacity);

      canvas.save();
      canvas.translate(center.dx + dx, center.dy + dy);
      canvas.rotate(piece.rotation + progress * 2.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: piece.size,
            height: piece.size * 1.6,
          ),
          Radius.circular(piece.size / 2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.pieces != pieces;
  }
}
