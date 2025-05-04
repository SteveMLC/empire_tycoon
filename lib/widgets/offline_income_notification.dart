import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/game_state.dart';
import '../services/game_service.dart';
import '../utils/time_utils.dart';
import '../utils/number_formatter.dart';

class OfflineIncomeNotification extends StatefulWidget {
  const OfflineIncomeNotification({Key? key}) : super(key: key);

  @override
  State<OfflineIncomeNotification> createState() => _OfflineIncomeNotificationState();
}

class _OfflineIncomeNotificationState extends State<OfflineIncomeNotification> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  bool _soundPlayed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final gameService = Provider.of<GameService>(context, listen: false);
    
    // Play sound once when notification appears
    if (!_soundPlayed) {
      gameService.playOfflineIncomeSound();
      _soundPlayed = true;
    }
    
    // Format the income amount
    final formattedIncome = NumberFormatter.formatCompact(gameState.offlineIncome);
    
    // Format the time period
    String timePeriod = 'while you were away';
    if (gameState.offlineIncomeStartTime != null && gameState.offlineIncomeEndTime != null) {
      final duration = gameState.offlineIncomeEndTime!.difference(gameState.offlineIncomeStartTime!);
      if (duration.inMinutes < 60) {
        timePeriod = '${duration.inMinutes} minutes';
      } else if (duration.inHours < 24) {
        timePeriod = '${duration.inHours}h ${duration.inMinutes % 60}m';
      } else {
        // Cap at 24 hours as per spec
        timePeriod = '24 hours';
      }
    }
    
    return FadeTransition(
      opacity: _fadeInAnimation,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.blue[100],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 32, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Offline Income',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        gameState.dismissOfflineIncomeNotification();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'You earned',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formattedIncome,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'in $timePeriod',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    gameState.dismissOfflineIncomeNotification();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'COLLECT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 