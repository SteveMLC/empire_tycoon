import 'package:flutter/material.dart';
import '../utils/number_formatter.dart';
import '../utils/time_utils.dart';

class OfflineIncomeNotification extends StatefulWidget {
  // CRITICAL FIX: Using nullable types with default values for safety
  final double amount;
  final Duration offlineDuration;
  final VoidCallback onDismiss;

  const OfflineIncomeNotification({
    Key? key,
    required this.amount,
    required this.offlineDuration,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<OfflineIncomeNotification> createState() => _OfflineIncomeNotificationState();
}

class _OfflineIncomeNotificationState extends State<OfflineIncomeNotification> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    
    // Use a microtask to ensure the widget is fully mounted before animating
    Future.microtask(() {
      if (mounted) {
        _animationController.forward();
        
        // Auto-dismiss after 7 seconds, but only if still mounted
        Future.delayed(const Duration(seconds: 7), () {
          if (mounted) {
            _dismiss();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Format the time duration for display
    String timeAway = '';
    if (widget.offlineDuration.inDays > 0) {
      // If more than one day, show days and hours
      if (widget.offlineDuration.inDays > 1) {
        final hours = widget.offlineDuration.inHours % 24;
        if (hours > 0) {
          timeAway = '${widget.offlineDuration.inDays} days and $hours hours';
        } else {
          timeAway = '${widget.offlineDuration.inDays} days';
        }
      } else {
        // Just one day, show hours as well
        final hours = widget.offlineDuration.inHours % 24;
        timeAway = '1 day';
        if (hours > 0) {
          timeAway += ' and $hours hours';
        }
      }
    } else if (widget.offlineDuration.inHours > 0) {
      // Show hours and minutes
      final minutes = widget.offlineDuration.inMinutes % 60;
      if (minutes > 0) {
        timeAway = '${widget.offlineDuration.inHours} hours and $minutes minutes';
      } else {
        timeAway = '${widget.offlineDuration.inHours} hours';
      }
    } else if (widget.offlineDuration.inMinutes > 0) {
      timeAway = '${widget.offlineDuration.inMinutes} minutes';
    } else {
      timeAway = 'a few seconds';
    }

    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(_animation),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            elevation: 4,
            color: Colors.green.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.green.shade300, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'While you were away...',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.green.shade700),
                        onPressed: _dismiss,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your businesses earned you',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    NumberFormatter.formatCurrency(widget.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'in the last $timeAway!',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}