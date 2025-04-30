import 'package:flutter/material.dart';
import 'dart:async';
import '../models/challenge.dart';
import '../models/game_state.dart';
import '../utils/number_formatter.dart';

class ChallengeNotification extends StatefulWidget {
  final Challenge challenge;
  final GameState gameState;
  final VoidCallback? onDismiss;

  const ChallengeNotification({
    Key? key,
    required this.challenge,
    required this.gameState,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<ChallengeNotification> createState() => _ChallengeNotificationState();
}

class _ChallengeNotificationState extends State<ChallengeNotification> {
  Timer? _timer;
  bool _isMinimized = false;
  Duration _remainingTime = Duration.zero;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _updateProgress();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    // Update every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _updateProgress();
        });
      }
    });
  }

  void _updateProgress() {
    final now = DateTime.now();
    _remainingTime = widget.challenge.remainingTime(now);
    
    // Calculate progress towards goal
    final earnedDuringChallenge = widget.gameState.totalEarned - widget.challenge.startTotalEarned;
    _progress = earnedDuringChallenge / widget.challenge.goalEarnedAmount;
    _progress = _progress.clamp(0.0, 1.0); // Ensure progress is between 0 and 1
    
    // Check if challenge has ended or is no longer active in game state
    if (_remainingTime == Duration.zero || widget.gameState.activeChallenge == null) {
      _timer?.cancel();
      // Dismiss after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (widget.onDismiss != null && mounted) {
          widget.onDismiss!();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF8E1), // Light gold background
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
      ),
      elevation: 3,
      child: InkWell(
        onTap: () {
          setState(() {
            _isMinimized = !_isMinimized;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.3),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          color: Color(0xFFD4AF37),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PLATINUM CHALLENGE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD4AF37),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.challenge.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Timer display
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer, size: 14, color: Colors.red),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(_remainingTime),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Minimize/expand button
                      Icon(
                        _isMinimized ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
              if (!_isMinimized) ...[
                const SizedBox(height: 16),
                Text(
                  widget.challenge.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                _buildProgressBar(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.25) return Colors.red;
    if (progress < 0.5) return Colors.orange;
    if (progress < 0.75) return Colors.amber.shade700;
    return Colors.green;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}';
    } else {
      return '${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}';
    }
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          children: [
            const Text(
              'Your progress:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(_progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _getProgressColor(_progress),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(_progress)),
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // PP reward indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFD4AF37),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD700),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '✦',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '+${widget.challenge.rewardPP} PP',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Tip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 14, color: Colors.blue.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'Tap more to earn faster!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
} 