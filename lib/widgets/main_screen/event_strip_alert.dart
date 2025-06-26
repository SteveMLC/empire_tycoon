import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_state.dart';
import '../../models/event.dart';
import '../events_widget.dart';

/// Thin strip alert that shows when events are active
/// Replaces the bulky event cards for a cleaner main screen
class EventStripAlert extends StatelessWidget {
  const EventStripAlert({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    
    // If no active events, return empty widget
    final activeEvents = gameState.activeEvents.where((e) => !e.isResolved).toList();
    if (activeEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    final eventCount = activeEvents.length;
    final firstEvent = activeEvents.first;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openEventsWidget(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  _getEventTypeColor(firstEvent.type).withOpacity(0.9),
                  _getEventTypeColor(firstEvent.type).withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getEventTypeColor(firstEvent.type),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getEventTypeColor(firstEvent.type).withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Event icon with animation
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getEventTypeIcon(firstEvent.type),
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Event text and count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          eventCount == 1 
                            ? firstEvent.name
                            : '$eventCount Active Events',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (eventCount == 1)
                          Text(
                            _getEventDescription(firstEvent),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w300,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          Text(
                            'Tap to manage events',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Indicator showing there are events to manage
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      eventCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Arrow indicating clickable
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
        return Icons.local_fire_department;
      case EventType.economic:
        return Icons.trending_down;
      case EventType.security:
        return Icons.security;
      case EventType.utility:
        return Icons.power;
      case EventType.staff:
        return Icons.people;
    }
  }

  String _getEventDescription(GameEvent event) {
    // Get affected entities for single event
    if (event.affectedBusinessIds.isNotEmpty) {
      return 'Business affected';
    } else if (event.affectedLocaleIds.isNotEmpty) {
      return 'Location affected';
    }
    return 'Tap to resolve';
  }
} 