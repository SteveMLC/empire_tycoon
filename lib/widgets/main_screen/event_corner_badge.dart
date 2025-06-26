import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/game_state.dart';
import '../../models/event.dart';
import '../events_widget.dart';

/// Ultra-minimal corner badge for event notifications
/// Appears as a small floating badge when events are active
/// Can be dragged to any position on screen
class EventCornerBadge extends StatefulWidget {
  const EventCornerBadge({Key? key}) : super(key: key);

  @override
  State<EventCornerBadge> createState() => _EventCornerBadgeState();
}

class _EventCornerBadgeState extends State<EventCornerBadge> {
  static const String _positionXKey = 'event_badge_position_x';
  static const String _positionYKey = 'event_badge_position_y';
  static const String _tutorialShownKey = 'event_tutorial_shown';
  
  // Default position (top-left area, but not over cash balance)
  double _badgeX = 16.0; // From left edge
  double _badgeY = 180.0; // From top edge (lower to avoid cash balance)
  bool _isLoaded = false;
  bool _tutorialShown = false;

  @override
  void initState() {
    super.initState();
    _loadPosition();
  }

  Future<void> _loadPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedX = prefs.getDouble(_positionXKey);
      final savedY = prefs.getDouble(_positionYKey);
      final tutorialShown = prefs.getBool(_tutorialShownKey) ?? false;
      
      if (savedX != null || savedY != null) {
        print('🔄 EventCornerBadge: Loading saved position - X: $savedX, Y: $savedY');
      }
      
      setState(() {
        _badgeX = savedX ?? 16.0;
        _badgeY = savedY ?? 180.0;
        _tutorialShown = tutorialShown;
        _isLoaded = true;
      });
    } catch (e) {
      print('❌ EventCornerBadge: Error loading position: $e');
      setState(() {
        _badgeX = 16.0;
        _badgeY = 180.0;
        _tutorialShown = false;
        _isLoaded = true;
      });
    }
  }

  Future<void> _savePosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      print('💾 EventCornerBadge: Saving position - X: $_badgeX, Y: $_badgeY');
      
      final saveXResult = await prefs.setDouble(_positionXKey, _badgeX);
      final saveYResult = await prefs.setDouble(_positionYKey, _badgeY);
      
      if (!saveXResult || !saveYResult) {
        print('⚠️ EventCornerBadge: Position save may have failed');
      }
    } catch (e) {
      print('❌ EventCornerBadge: Error saving position: $e');
    }
  }

  Future<void> _markTutorialAsShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_tutorialShownKey, true);
      setState(() {
        _tutorialShown = true;
      });
    } catch (e) {
      print('Error saving tutorial state: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    
    // If position not loaded yet, return empty widget
    if (!_isLoaded) {
      return const SizedBox.shrink();
    }
    
    // If no active events, return empty widget
    final activeEvents = gameState.activeEvents.where((e) => !e.isResolved).toList();
    if (activeEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    final eventCount = activeEvents.length;
    final firstEvent = activeEvents.first;
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: _badgeX,
      top: _badgeY,
      child: Draggable(
        feedback: _buildBadge(firstEvent, eventCount, isDragging: true),
        childWhenDragging: const SizedBox.shrink(),
        onDragEnd: (details) {
          final newX = details.offset.dx;
          final newY = details.offset.dy;
          
          setState(() {
            // Calculate new position relative to screen
            _badgeX = newX;
            _badgeY = newY;
            
            // Keep badge within screen bounds
            const badgeSize = 24.0;
            final maxX = screenSize.width - badgeSize;
            final maxY = screenSize.height - badgeSize;
            
            _badgeX = _badgeX.clamp(0, maxX);
            _badgeY = _badgeY.clamp(0, maxY);
            
            print('📍 EventCornerBadge: Moved to position X: $_badgeX, Y: $_badgeY');
          });
          
          // Save position with a small delay to ensure state is updated
          Future.delayed(const Duration(milliseconds: 100), () {
            _savePosition();
          });
        },
        child: _buildBadge(firstEvent, eventCount),
      ),
    );
  }

  Widget _buildBadge(GameEvent firstEvent, int eventCount, {bool isDragging = false}) {
    return GestureDetector(
      onTap: isDragging ? null : () => _handleBadgeTap(context),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: _getEventTypeColor(firstEvent.type),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDragging ? 0.5 : 0.3),
              blurRadius: isDragging ? 8 : 4,
              offset: Offset(0, isDragging ? 4 : 2),
            ),
          ],
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            // Event type icon
            Center(
              child: Icon(
                _getEventTypeIcon(firstEvent.type),
                color: Colors.white,
                size: 12,
              ),
            ),
            
            // Event count badge (if multiple events)
            if (eventCount > 1)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      eventCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              
            // Drag hint indicator (subtle dots)
            if (!isDragging)
              Positioned(
                bottom: -1,
                right: -1,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleBadgeTap(BuildContext context) {
    if (!_tutorialShown) {
      _showEventTutorial(context);
    } else {
      _openEventsWidget(context);
    }
  }

  void _showEventTutorial(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber.shade600,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text(
                'Empire Events',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This alert indicates events happening in your Empire.',
                style: TextStyle(fontSize: 16, height: 1.4),
              ),
              SizedBox(height: 12),
              Text(
                'Events cause you to lose money.',
                style: TextStyle(fontSize: 16, height: 1.4),
              ),
              SizedBox(height: 12),
              Text(
                'Complete challenges to fix them or let them expire.',
                style: TextStyle(fontSize: 16, height: 1.4),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.blue,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'TIP:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                'Drag the alert button to place it where you\'d like!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _markTutorialAsShown();
                _openEventsWidget(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Got it!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openEventsWidget(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EventsWidget(),
    );
  }

  Color _getEventTypeColor(EventType type) {
    switch (type) {
      case EventType.disaster:
        return Colors.red.shade600;
      case EventType.economic:
        return Colors.purple.shade600;
      case EventType.security:
        return Colors.blue.shade600;
      case EventType.utility:
        return Colors.amber.shade600;
      case EventType.staff:
        return Colors.teal.shade600;
    }
  }

  IconData _getEventTypeIcon(EventType type) {
    switch (type) {
      case EventType.disaster:
        return Icons.warning;
      case EventType.economic:
        return Icons.trending_down;
      case EventType.security:
        return Icons.security;
      case EventType.utility:
        return Icons.flash_on;
      case EventType.staff:
        return Icons.people;
    }
  }
} 