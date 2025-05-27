import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../models/game_state.dart';
import '../services/game_service.dart';
import '../utils/number_formatter.dart';

class OfflineIncomeNotification extends StatefulWidget {
  const OfflineIncomeNotification({Key? key}) : super(key: key);

  @override
  State<OfflineIncomeNotification> createState() => _OfflineIncomeNotificationState();
}

class _OfflineIncomeNotificationState extends State<OfflineIncomeNotification> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _incomeScaleAnimation;
  bool _soundPlayed = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _animationController.forward();
  }
  
  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    
    _incomeScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController, 
        curve: const Interval(0.3, 0.7, curve: Curves.elasticOut),
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
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
    final String timePeriod = _formatTimePeriod(gameState);
    
    return FadeTransition(
      opacity: _fadeInAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main Card
              Card(
                elevation: 10,
                shadowColor: const Color(0xFF4CAF50).withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: Colors.greenAccent.shade200,
                    width: 1.5,
                  ),
                ),
                color: const Color(0xFFF1F8E9), // Light green background
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          // Money Icon in Circle
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade300,
                                  Colors.green.shade500,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.shade200.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.account_balance,
                              size: 26,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 14),
                          
                          // Title
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'WELCOME BACK',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF689F38),
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Icon(
                                    Icons.wb_sunny,
                                    size: 12,
                                    color: Colors.amber.shade600,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Offline Income',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF33691E),
                                ),
                              ),
                            ],
                          ),
                          
                          const Spacer(),
                          
                          // Close Button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                gameState.dismissOfflineIncomeNotification();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.red.shade400,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 22),
                      
                      // Money Amount Section
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'You earned',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF558B2F),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Animated Income Text
                            ScaleTransition(
                              scale: _incomeScaleAnimation,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildGlowingDollarSign(),
                                  const SizedBox(width: 6),
                                  Text(
                                    formattedIncome,
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800,
                                      letterSpacing: 0.5,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 2,
                                          color: Colors.green.withOpacity(0.3),
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Time period with clock icon
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue.shade100,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_filled,
                                    size: 16,
                                    color: Colors.blue.shade400,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'in $timePeriod',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      // Watch Ad Button (only if not already watched)
                       if (!gameState.offlineIncomeAdWatched)
                         Padding(
                           padding: const EdgeInsets.only(bottom: 12.0),
                           child: ElevatedButton.icon(
                             style: ElevatedButton.styleFrom(
                               foregroundColor: Colors.white,
                               backgroundColor: Colors.orange.shade700,
                               elevation: 2,
                               minimumSize: const Size(double.infinity, 44),
                               shape: RoundedRectangleBorder(
                                 borderRadius: BorderRadius.circular(10),
                               ),
                             ),
                             icon: const Icon(Icons.play_circle_filled),
                             label: const Text(
                               'Watch Ad for 2x Income',
                               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                             ),
                             onPressed: () async {
                               // TODO: Integrate real ad logic here
                               // Simulate ad watch for demo
                               await showDialog(
                                 context: context,
                                 builder: (context) => AlertDialog(
                                   title: const Text('Watch Ad'),
                                   content: const Text('Simulate watching a rewarded ad.'),
                                   actions: [
                                     TextButton(
                                       onPressed: () => Navigator.of(context).pop(),
                                       child: const Text('OK'),
                                     ),
                                   ],
                                 ),
                               );
                               gameState.setOfflineIncomeAdWatched(true);
                             },
                           ),
                         ),
                       // Collect Button
                       ElevatedButton(
                         style: ElevatedButton.styleFrom(
                           foregroundColor: Colors.white,
                           backgroundColor: gameState.offlineIncomeAdWatched ? Colors.orange.shade700 : const Color(0xFF4CAF50),
                           elevation: 4,
                           minimumSize: const Size(double.infinity, 48),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(12),
                           ),
                           shadowColor: const Color(0xFF4CAF50).withOpacity(0.4),
                         ),
                         onPressed: () {
                           gameState.collectOfflineIncome();
                         },
                         child: Row(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             Container(
                               padding: const EdgeInsets.all(4),
                               decoration: BoxDecoration(
                                 color: Colors.white.withOpacity(0.2),
                                 shape: BoxShape.circle,
                               ),
                               child: const Icon(
                                 Icons.monetization_on,
                                 size: 18,
                               ),
                             ),
                             const SizedBox(width: 8),
                             Text(
                               gameState.offlineIncomeAdWatched ? 'COLLECT 2x INCOME' : 'COLLECT',
                               style: const TextStyle(
                                 fontSize: 16,
                                 fontWeight: FontWeight.bold,
                                 letterSpacing: 1,
                               ),
                             ),
                           ],
                         ),
                       ),
                    ],
                  ),
                ),
              ),
              
              // Optional: Decorative Elements
              Positioned(
                top: -12,
                right: 20,
                child: _buildDecorationElement(),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildGlowingDollarSign() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF66BB6A), // Predefined shade400
            Color(0xFF43A047), // Predefined shade600
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x9981C784), // Predefined shade300 with opacity
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '\$',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.1,
          ),
        ),
      ),
    );
  }
  
  Widget _buildDecorationElement() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFD54F), // Predefined amber.shade300
            Color(0xFFFFCA28), // Predefined amber.shade500
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80FFE082), // Predefined amber.shade200 with opacity
            blurRadius: 6,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            color: Colors.white,
            size: 14,
          ),
          SizedBox(width: 4),
          Text(
            'Bonus - 2x Income by watching an AD!',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to format time period string
  String _formatTimePeriod(GameState gameState) {
    if (gameState.offlineIncomeStartTime == null || gameState.offlineIncomeEndTime == null) {
      return 'while you were away';
    }
    
    final duration = gameState.offlineIncomeEndTime!.difference(gameState.offlineIncomeStartTime!);
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} minutes';
    } else if (duration.inHours < 24) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      // Cap at 4 hours as per spec
      return '4 hours';
    }
  }
} 