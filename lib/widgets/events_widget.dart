import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/event.dart';
import '../services/game_service.dart';
import 'event_notification.dart';

/// Refined events management widget with polished command center styling
/// Features sophisticated design that matches app theming while being informative
class EventsWidget extends StatelessWidget {
  const EventsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: _buildBackgroundColor(gameState),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Refined header
              _buildRefinedHeader(context, gameState),
              
              // Impact summary section
              _buildImpactSummary(context, gameState),
              
              // Events list
              Expanded(
                child: _buildEventsList(context, gameState, scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _buildBackgroundColor(GameState gameState) {
    if (gameState.isPlatinumFrameActive) {
      return const Color(0xFF1E1E2E); // Darker, more sophisticated
    } else {
      return const Color(0xFFFAFAFA); // Softer white
    }
  }

  Widget _buildRefinedHeader(BuildContext context, GameState gameState) {
    final activeEvents = gameState.activeEvents.where((e) => !e.isResolved).toList();
    final isPlatinum = gameState.isPlatinumFrameActive;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isPlatinum 
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Refined drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: isPlatinum 
                ? Colors.white.withOpacity(0.3)
                : Colors.grey.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header content
          Row(
            children: [
              // Refined status icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getStatusColor(activeEvents.isEmpty, isPlatinum).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getStatusColor(activeEvents.isEmpty, isPlatinum).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  activeEvents.isEmpty ? Icons.verified_outlined : Icons.warning_amber_outlined,
                  color: _getStatusColor(activeEvents.isEmpty, isPlatinum),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Empire Status Center',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isPlatinum ? Colors.white : const Color(0xFF2D3748),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activeEvents.isEmpty 
                        ? 'All Systems Operational' 
                        : '${activeEvents.length} Active Issue${activeEvents.length > 1 ? 's' : ''} Requiring Attention',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: activeEvents.isEmpty
                          ? (isPlatinum ? const Color(0xFF68D391) : const Color(0xFF38A169))
                          : (isPlatinum ? const Color(0xFFFBB6CE) : const Color(0xFFE53E3E)),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Close button
              Container(
                decoration: BoxDecoration(
                  color: isPlatinum 
                    ? Colors.white.withOpacity(0.05) 
                    : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isPlatinum 
                      ? Colors.white.withOpacity(0.7)
                      : Colors.grey.shade600,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(bool isAllClear, bool isPlatinum) {
    if (isAllClear) {
      return isPlatinum ? const Color(0xFF68D391) : const Color(0xFF38A169);
    } else {
      return isPlatinum ? const Color(0xFFFBB6CE) : const Color(0xFFE53E3E);
    }
  }

  Widget _buildImpactSummary(BuildContext context, GameState gameState) {
    final activeEvents = gameState.activeEvents.where((e) => !e.isResolved).toList();
    final isPlatinum = gameState.isPlatinumFrameActive;
    
    if (activeEvents.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPlatinum 
            ? const Color(0xFF2D4A3A).withOpacity(0.3)
            : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPlatinum 
              ? const Color(0xFF68D391).withOpacity(0.2)
              : const Color(0xFFC6F6D5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isPlatinum 
                  ? const Color(0xFF68D391).withOpacity(0.2)
                  : const Color(0xFF38A169).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.check_circle_outline,
                color: isPlatinum 
                  ? const Color(0xFF68D391)
                  : const Color(0xFF38A169),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Empire Operating at Full Capacity',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isPlatinum 
                        ? const Color(0xFF68D391)
                        : const Color(0xFF2F855A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'All businesses and properties generating optimal income',
                    style: TextStyle(
                      fontSize: 13,
                      color: isPlatinum 
                        ? Colors.white.withOpacity(0.7)
                        : const Color(0xFF4A5568),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Calculate total financial impact
    double totalImpactPerSecond = 0;
    for (final event in activeEvents) {
      // Get affected business income
      for (final businessId in event.affectedBusinessIds) {
        final business = gameState.businesses.firstWhere(
          (b) => b.id == businessId,
          orElse: () => gameState.businesses.first,
        );
        totalImpactPerSecond += business.getIncomePerSecond() * 0.25; // 25% penalty
      }
      
      // Get affected locale income  
      for (final localeId in event.affectedLocaleIds) {
        final locale = gameState.realEstateLocales.firstWhere(
          (l) => l.id == localeId,
          orElse: () => gameState.realEstateLocales.first,
        );
        totalImpactPerSecond += locale.getTotalIncomePerSecond() * 0.25; // 25% penalty
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPlatinum 
          ? const Color(0xFF4A1E23).withOpacity(0.3)
          : const Color(0xFFFEF5E7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPlatinum 
            ? const Color(0xFFFBB6CE).withOpacity(0.2)
            : const Color(0xFFFBD38D),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isPlatinum 
                    ? const Color(0xFFFBB6CE).withOpacity(0.2)
                    : const Color(0xFFED8936).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.trending_down_outlined,
                  color: isPlatinum 
                    ? const Color(0xFFFBB6CE)
                    : const Color(0xFFED8936),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Income Impact Analysis',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isPlatinum 
                          ? Colors.white.withOpacity(0.8)
                          : const Color(0xFF4A5568),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '-\$${totalImpactPerSecond.toStringAsFixed(2)}/sec',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isPlatinum 
                          ? const Color(0xFFFBB6CE)
                          : const Color(0xFFE53E3E),
                      ),
                    ),
                  ],
                ),
              ),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPlatinum 
                    ? const Color(0xFFFBB6CE).withOpacity(0.2)
                    : const Color(0xFFE53E3E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPlatinum 
                      ? const Color(0xFFFBB6CE).withOpacity(0.3)
                      : const Color(0xFFE53E3E).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  '-25%',
                  style: TextStyle(
                    color: isPlatinum 
                      ? const Color(0xFFFBB6CE)
                      : const Color(0xFFE53E3E),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPlatinum 
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: isPlatinum 
                    ? const Color(0xFFFBD38D)
                    : const Color(0xFFED8936),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Resolve issues quickly to restore full income capacity',
                    style: TextStyle(
                      fontSize: 12,
                      color: isPlatinum 
                        ? Colors.white.withOpacity(0.8)
                        : const Color(0xFF4A5568),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(BuildContext context, GameState gameState, ScrollController scrollController) {
    final activeEvents = gameState.activeEvents.where((e) => !e.isResolved).toList();
    
    if (activeEvents.isEmpty) {
      return _buildNoEventsState(gameState);
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: activeEvents.length,
      itemBuilder: (context, index) {
        final event = activeEvents[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildRefinedEventCard(context, event, gameState, index),
        );
      },
    );
  }

  Widget _buildRefinedEventCard(BuildContext context, GameEvent event, GameState gameState, int index) {
    final isPlatinum = gameState.isPlatinumFrameActive;
    
    return Container(
      decoration: BoxDecoration(
        color: _getEventCardColor(event.type, isPlatinum),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getEventTypeAccent(event.type, isPlatinum),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _getEventTypeAccent(event.type, isPlatinum).withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: EventNotification(
        event: event,
        gameState: gameState,
        onResolved: () {
          // Event resolved, GameState's notifyListeners will trigger rebuild
        },
        onTap: event.resolution.type == EventResolutionType.tapChallenge ? () {
          HapticFeedback.lightImpact();
          try {
            Provider.of<GameService>(context, listen: false).playTapSound();
          } catch (_) {}
          gameState.processTapForEvent(event);
        } : null,
      ),
    );
  }

  Color _getEventCardColor(EventType type, bool isPlatinum) {
    if (isPlatinum) {
      switch (type) {
        case EventType.disaster:
          return const Color(0xFF4A1E23).withOpacity(0.3);
        case EventType.economic:
          return const Color(0xFF3D2A4A).withOpacity(0.3);
        case EventType.security:
          return const Color(0xFF1E3A4A).withOpacity(0.3);
        case EventType.utility:
          return const Color(0xFF4A331E).withOpacity(0.3);
        case EventType.staff:
          return const Color(0xFF1E4A3D).withOpacity(0.3);
      }
    } else {
      switch (type) {
        case EventType.disaster:
          return const Color(0xFFFEF5E7);
        case EventType.economic:
          return const Color(0xFFF7FAFC);
        case EventType.security:
          return const Color(0xFFEBF8FF);
        case EventType.utility:
          return const Color(0xFFFFFAF0);
        case EventType.staff:
          return const Color(0xFFF0FDF4);
      }
    }
  }

  Color _getEventTypeAccent(EventType type, bool isPlatinum) {
    if (isPlatinum) {
      switch (type) {
        case EventType.disaster:
          return const Color(0xFFFBB6CE);
        case EventType.economic:
          return const Color(0xFFD6BCFA);
        case EventType.security:
          return const Color(0xFF90CDF4);
        case EventType.utility:
          return const Color(0xFFFBD38D);
        case EventType.staff:
          return const Color(0xFF9AE6B4);
      }
    } else {
      switch (type) {
        case EventType.disaster:
          return const Color(0xFFE53E3E);
        case EventType.economic:
          return const Color(0xFF805AD5);
        case EventType.security:
          return const Color(0xFF3182CE);
        case EventType.utility:
          return const Color(0xFFED8936);
        case EventType.staff:
          return const Color(0xFF38A169);
      }
    }
  }

  Widget _buildNoEventsState(GameState gameState) {
    final isPlatinum = gameState.isPlatinumFrameActive;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isPlatinum 
                  ? const Color(0xFF2D4A3A).withOpacity(0.3)
                  : const Color(0xFFF0FDF4),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isPlatinum 
                    ? const Color(0xFF68D391).withOpacity(0.3)
                    : const Color(0xFF38A169).withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.verified_outlined,
                size: 48,
                color: isPlatinum 
                  ? const Color(0xFF68D391)
                  : const Color(0xFF38A169),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Empire Secured',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: isPlatinum ? Colors.white : const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'All systems operational\nMaximum income potential achieved',
              style: TextStyle(
                fontSize: 15,
                color: isPlatinum 
                  ? Colors.white.withOpacity(0.7)
                  : const Color(0xFF4A5568),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Builder(
              builder: (context) => ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Return to Empire'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPlatinum 
                    ? const Color(0xFF68D391)
                    : const Color(0xFF38A169),
                  foregroundColor: isPlatinum 
                    ? const Color(0xFF1A202C)
                    : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 