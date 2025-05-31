import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../models/game_state.dart';
import '../../themes/stats_themes.dart';
import '../../utils/number_formatter.dart';
import 'stats_utils.dart';

/// Widget that displays a breakdown of events solved by the player
class EventsBreakdownCard extends StatelessWidget {
  final GameState gameState;
  final StatsTheme theme;
  final String sectionId;

  const EventsBreakdownCard({
    Key? key,
    required this.gameState,
    required this.theme,
    this.sectionId = 'events',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isExecutive = theme.id == 'executive';
    
    // Calculate fees paid specifically for fee-based resolutions
    // This is the source of truth for all fee-related stats
    double feeBasedTotal = 0.0;
    for (var event in gameState.resolvedEvents) {
      if (event.resolution.type == EventResolutionType.feeBased && 
          event.resolutionFeePaid != null) {
        feeBasedTotal += event.resolutionFeePaid!;
      }
    }

    // Count events by type
    Map<EventType, int> eventsByType = {};
    for (var type in EventType.values) {
      eventsByType[type] = 0;
    }
    
    // Count events by resolution type
    Map<EventResolutionType, int> eventsByResolutionType = {};
    for (var type in EventResolutionType.values) {
      eventsByResolutionType[type] = 0;
    }
    
    // Populate counts from resolved events
    for (var event in gameState.resolvedEvents) {
      eventsByType[event.type] = (eventsByType[event.type] ?? 0) + 1;
      eventsByResolutionType[event.resolution.type] = (eventsByResolutionType[event.resolution.type] ?? 0) + 1;
    }

    return Card(
      elevation: theme.elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.borderRadius),
        side: BorderSide(
          color: isExecutive 
              ? const Color(0xFF2A3142)
              : theme.cardBorderColor,
        ),
      ),
      color: theme.cardBackgroundColor,
      shadowColor: theme.cardShadow?.color ?? Colors.black26,
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section ID for scrolling
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Opacity(
                opacity: 0,
                child: Text(sectionId, style: const TextStyle(height: 0, fontSize: 1)),
              ),
            ),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bolt, // More exciting icon for events - lightning bolt represents action and energy
                      color: isExecutive ? Colors.orange.shade300 : Colors.orange.shade700,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Events Solved',
                      style: isExecutive 
                          ? theme.cardTitleStyle
                          : TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                    ),
                  ],
                ),
              ],
            ),

            Divider(
              height: 30,
              thickness: 1,
              color: isExecutive
                  ? const Color(0xFF2A3142)
                  : Colors.orange.withOpacity(0.2),
            ),

            // Main stats overview
            _buildMainStats(isExecutive),

            const SizedBox(height: 20),

            // Events by type
            _buildEventsByTypeSection(isExecutive, eventsByType),

            const SizedBox(height: 20),

            // Events by resolution method
            _buildEventsByResolutionSection(isExecutive, eventsByResolutionType),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStats(bool isExecutive) {
    // Calculate fees paid specifically for fee-based resolutions
    double feeBasedTotal = 0.0;
    int feeBasedCount = 0;
    
    for (var event in gameState.resolvedEvents) {
      if (event.resolution.type == EventResolutionType.feeBased && 
          event.resolutionFeePaid != null) {
        feeBasedTotal += event.resolutionFeePaid!;
        feeBasedCount++;
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overall Event Statistics',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isExecutive ? theme.titleColor : Colors.orange.shade700,
          ),
        ),
        const SizedBox(height: 12),
        StatsUtils.buildStatRowWithIcon(
          'Total Events Solved', 
          '${gameState.totalEventsResolved}',
          Icons.check_circle_outline,
          isExecutive ? Colors.green.shade300 : Colors.green.shade600,
          theme
        ),
        StatsUtils.buildStatRowWithIcon(
          'Money Spent on Resolutions', 
          NumberFormatter.formatCurrency(feeBasedTotal),
          Icons.attach_money,
          isExecutive ? Colors.amber.shade300 : Colors.amber.shade600,
          theme
        ),
        if (gameState.totalEventsResolved > 0)
          StatsUtils.buildStatRowWithIcon(
            'Average Cost per Event', 
            NumberFormatter.formatCurrency(feeBasedCount > 0 ? feeBasedTotal / feeBasedCount : 0.0),
            Icons.calculate,
            isExecutive ? Colors.blue.shade300 : Colors.blue.shade600,
            theme
          ),
      ],
    );
  }

  Widget _buildEventsByTypeSection(bool isExecutive, Map<EventType, int> eventsByType) {
    // Map event types to friendly names and icons
    final Map<EventType, String> typeNames = {
      EventType.disaster: 'Natural Disasters',
      EventType.economic: 'Economic Crises',
      EventType.security: 'Security Incidents',
      EventType.utility: 'Utility Issues',
      EventType.staff: 'Staff Problems',
    };
    
    final Map<EventType, IconData> typeIcons = {
      EventType.disaster: Icons.local_fire_department,
      EventType.economic: Icons.trending_down,
      EventType.security: Icons.security,
      EventType.utility: Icons.power,
      EventType.staff: Icons.people,
    };
    
    final Map<EventType, Color> typeColors = {
      EventType.disaster: Colors.red,
      EventType.economic: Colors.purple,
      EventType.security: Colors.blue,
      EventType.utility: Colors.amber,
      EventType.staff: Colors.teal,
    };

    // Count events by affected entity (business vs real estate)
    int businessEvents = 0;
    int realEstateEvents = 0;
    
    for (var event in gameState.resolvedEvents) {
      if (event.affectedBusinessIds.isNotEmpty && event.affectedLocaleIds.isEmpty) {
        businessEvents++;
      } else if (event.affectedLocaleIds.isNotEmpty && event.affectedBusinessIds.isEmpty) {
        realEstateEvents++;
      }
      // Some events might affect both or neither, which we don't count in these specific categories
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Events by Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isExecutive ? theme.titleColor : Colors.orange.shade700,
          ),
        ),
        const SizedBox(height: 12),
        ...EventType.values.map((type) {
          final count = eventsByType[type] ?? 0;
          if (count == 0) return const SizedBox.shrink(); // Skip types with no events
          
          return StatsUtils.buildStatRowWithIcon(
            typeNames[type] ?? type.toString(), 
            '$count',
            typeIcons[type] ?? Icons.warning,
            isExecutive 
                ? typeColors[type]?.withOpacity(0.7) ?? Colors.grey 
                : typeColors[type] ?? Colors.grey,
            theme
          );
        }).toList(),
        
        const SizedBox(height: 20),
        
        // Events by Location section
        Text(
          'Events by Location',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isExecutive ? theme.titleColor : Colors.orange.shade700,
          ),
        ),
        const SizedBox(height: 12),
        
        // Business Events
        if (businessEvents > 0)
          StatsUtils.buildStatRowWithIcon(
            'Business Events', 
            '$businessEvents',
            Icons.business_center,
            isExecutive ? Colors.blue.shade300 : Colors.blue.shade600,
            theme
          ),
          
        // Real Estate Events
        if (realEstateEvents > 0)
          StatsUtils.buildStatRowWithIcon(
            'Real Estate Events', 
            '$realEstateEvents',
            Icons.home_work,
            isExecutive ? Colors.green.shade300 : Colors.green.shade600,
            theme
          ),
      ],
    );
  }

  Widget _buildEventsByResolutionSection(
    bool isExecutive, 
    Map<EventResolutionType, int> eventsByResolutionType
  ) {
    // Calculate fees paid specifically for fee-based resolutions
    double feeBasedTotal = 0.0;
    for (var event in gameState.resolvedEvents) {
      if (event.resolution.type == EventResolutionType.feeBased && 
          event.resolutionFeePaid != null) {
        feeBasedTotal += event.resolutionFeePaid!;
      }
    }
    // Map resolution types to friendly names and icons
    final Map<EventResolutionType, String> resolutionNames = {
      EventResolutionType.timeBased: 'Resolved by Time',
      EventResolutionType.adBased: 'Resolved by Ads',
      EventResolutionType.feeBased: 'Resolved by Payment',
      EventResolutionType.tapChallenge: 'Resolved by Tapping',
    };
    
    final Map<EventResolutionType, IconData> resolutionIcons = {
      EventResolutionType.timeBased: Icons.timer,
      EventResolutionType.adBased: Icons.movie,
      EventResolutionType.feeBased: Icons.payments,
      EventResolutionType.tapChallenge: Icons.touch_app,
    };
    
    final Map<EventResolutionType, Color> resolutionColors = {
      EventResolutionType.timeBased: Colors.blue,
      EventResolutionType.adBased: Colors.purple,
      EventResolutionType.feeBased: Colors.green,
      EventResolutionType.tapChallenge: Colors.orange,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Events by Resolution Method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isExecutive ? theme.titleColor : Colors.orange.shade700,
          ),
        ),
        const SizedBox(height: 12),
        ...EventResolutionType.values.map((type) {
          final count = eventsByResolutionType[type] ?? 0;
          if (count == 0) return const SizedBox.shrink(); // Skip types with no events
          
          String valueText = '$count';
          if (type == EventResolutionType.feeBased && count > 0) {
            valueText = '$count (${NumberFormatter.formatCurrency(feeBasedTotal)})';
          } else if (type == EventResolutionType.tapChallenge && count > 0) {
            // Assuming each tap challenge requires an average of 200 taps
            valueText = '$count (~${NumberFormatter.formatInt((count * 200).toInt())} taps)';
          }
          
          return StatsUtils.buildStatRowWithIcon(
            resolutionNames[type] ?? type.toString(), 
            valueText,
            resolutionIcons[type] ?? Icons.check_circle,
            isExecutive 
                ? resolutionColors[type]?.withOpacity(0.7) ?? Colors.grey 
                : resolutionColors[type] ?? Colors.grey,
            theme
          );
        }).toList(),
        
        if ((eventsByResolutionType[EventResolutionType.feeBased] ?? 0) > 0)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isExecutive 
                    ? const Color(0xFF242C3B).withOpacity(0.5) 
                    : Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isExecutive 
                      ? const Color(0xFF2A3142) 
                      : Colors.orange.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: isExecutive ? Colors.amber.shade300 : Colors.amber.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Empire Insight',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isExecutive ? Colors.amber.shade300 : Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ve spent ${NumberFormatter.formatCurrency(feeBasedTotal)} resolving events. Visit the Platinum Vault to purchase preventative measures!',
                    style: TextStyle(
                      fontSize: 13,
                      color: isExecutive ? theme.textColor.withOpacity(0.9) : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
