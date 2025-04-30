import 'package:flutter/material.dart';
import 'dart:math';
import '../models/event.dart';
import '../models/game_state.dart';
import '../models/game_state_events.dart';

class EventNotification extends StatefulWidget {
  final GameEvent event;
  final GameState gameState;
  final VoidCallback onResolved;
  final VoidCallback? onTap;

  const EventNotification({
    Key? key,
    required this.event,
    required this.gameState,
    required this.onResolved,
    this.onTap,
  }) : super(key: key);

  @override
  State<EventNotification> createState() => _EventNotificationState();
}

class _EventNotificationState extends State<EventNotification> {
  bool _isMinimized = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _getBackgroundColor(),
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 2,
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: _isMinimized ? _buildMinimizedView() : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row with event name and minimize button
              Row(
                children: [
                  _getEventIcon(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.event.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.event.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                      icon: Icon(_isMinimized ? Icons.expand_more : Icons.expand_less, 
                        color: Colors.white,
                        size: 20,
                      ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        _isMinimized = !_isMinimized;
                      });
                    },
                  ),
                ],
              ),
              
              // Resolution panel - more compact now with just one resolution option
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resolution explanation
                    _buildResolutionProgress(),
                    
                    const SizedBox(height: 8),
                    
                    // Resolution button - centered for better visibility
                    Center(child: _buildResolutionButton()),
                  ],
                ),
              ),
            ],
            ),
          ),
        ),
      );
  }
  
  // Build minimized view with just the essential info
  Widget _buildMinimizedView() {
    return Row(
      children: [
        // Event icon
        _getEventIcon(),
        const SizedBox(width: 8),
        
        // Event name
        Expanded(
          child: Text(
            widget.event.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        // Single resolution button - use smaller version of the main resolution button
        _buildMinimizedResolutionButton(),
        
        // Expand/collapse button
        IconButton(
          icon: Icon(_isMinimized ? Icons.expand_more : Icons.expand_less, 
            color: Colors.white,
            size: 20,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            setState(() {
              _isMinimized = !_isMinimized;
            });
          },
        ),
      ],
    );
  }
  
  // Compact resolution button for minimized view
  Widget _buildMinimizedResolutionButton() {
    switch (widget.event.resolution.type) {
      case EventResolutionType.tapChallenge:
        // Just show the tap icon with current/total
        final int requiredTaps = widget.event.requiredTaps;
        final int currentTaps = (widget.event.resolution.value is Map) ? 
            widget.event.resolution.value['current'] ?? 0 : 0;
        
        return InkWell(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.touch_app, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$currentTaps/$requiredTaps',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        );
        
      case EventResolutionType.feeBased:
        // Compact fee button
        final double fee = widget.event.resolutionFee;
        final bool canAfford = widget.gameState.money >= fee;
        
        return InkWell(
          onTap: canAfford ? () {
            widget.gameState.money -= fee;
            widget.event.resolve(feePaid: fee);
            // Update event achievement tracking
            widget.gameState.totalEventsResolved++;
            widget.gameState.eventsResolvedByFee++;
            widget.gameState.eventFeesSpent += fee;
            widget.gameState.trackEventResolution(widget.event, "fee");
            widget.onResolved();
          } : () {
            // Show cannot afford message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('You need \$${fee.toStringAsFixed(0)} to resolve this event.'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: canAfford ? Colors.green : Colors.grey.shade500,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.attach_money, color: Colors.white, size: 16),
                const SizedBox(width: 2),
                Text(
                  '${fee.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        );
        
      case EventResolutionType.adBased:
        // Ad button with premium bypass
        final bool isPremium = widget.gameState.isPremium;
        return InkWell(
          onTap: () {
            widget.event.resolve();
            // Update event achievement tracking
            widget.gameState.totalEventsResolved++;
            widget.gameState.eventsResolvedByAd++;
            widget.gameState.trackEventResolution(widget.event, "ad");
            widget.onResolved();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPremium ? Colors.purple : Colors.amber,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPremium ? Icons.star : Icons.video_library, 
                  color: isPremium ? Colors.white : Colors.black, 
                  size: 16
                ),
                SizedBox(width: 4),
                Text(
                  isPremium ? 'SKIP' : 'AD',
                  style: TextStyle(
                    color: isPremium ? Colors.white : Colors.black, 
                    fontSize: 14
                  ),
                ),
              ],
            ),
          ),
        );
        
      case EventResolutionType.timeBased:
        // Timer info (very compact)
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade700,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.access_time, color: Colors.white, size: 16),
        );
        
      default:
        return const SizedBox();
    }
  }

  // Build single resolution button based on event type
  Widget _buildResolutionButton() {
    // Display only one resolution button based on the event's resolution type
    switch (widget.event.resolution.type) {
      case EventResolutionType.tapChallenge:
        // Tap challenge button - Shows tap count
        final int requiredTaps = widget.event.requiredTaps;
        final int currentTaps = (widget.event.resolution.value is Map) ? 
            widget.event.resolution.value['current'] ?? 0 : 0;
            
        return ElevatedButton.icon(
          onPressed: widget.onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(100, 36),
          ),
          icon: const Icon(Icons.touch_app, size: 18),
          label: Text('TAP ${currentTaps}/${requiredTaps}'),
        );
        
      case EventResolutionType.feeBased:
        // Fee-based button - Shows cost
        final double fee = widget.event.resolutionFee;
        final bool canAfford = widget.gameState.money >= fee;
        
        return ElevatedButton.icon(
          onPressed: canAfford ? () {
            widget.gameState.money -= fee;
            widget.event.resolve(feePaid: fee);
            // Update event achievement tracking
            widget.gameState.totalEventsResolved++;
            widget.gameState.eventsResolvedByFee++;
            widget.gameState.eventFeesSpent += fee;
            widget.gameState.trackEventResolution(widget.event, "fee");
            widget.onResolved();
          } : null, // Disable if can't afford
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(100, 36),
            disabledBackgroundColor: Colors.grey.shade400,
          ),
          icon: const Icon(Icons.attach_money, size: 18),
          label: Text('\$${fee.toStringAsFixed(0)}'),
        );
        
      case EventResolutionType.adBased:
        // Ad-based button with premium bypass
        final bool isPremium = widget.gameState.isPremium;
        return ElevatedButton.icon(
          onPressed: () {
            // If premium, bypass ad and resolve immediately
            // If not premium, would show ad here in a real app
            widget.event.resolve();
            // Update event achievement tracking
            widget.gameState.totalEventsResolved++;
            widget.gameState.eventsResolvedByAd++;
            widget.gameState.trackEventResolution(widget.event, "ad");
            widget.onResolved();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isPremium ? Colors.purple : Colors.amber,
            foregroundColor: isPremium ? Colors.white : Colors.black,
            minimumSize: const Size(100, 36),
          ),
          icon: Icon(isPremium ? Icons.star : Icons.video_library, size: 18),
          label: Text(isPremium ? 'SKIP AD' : 'WATCH AD'),
        );
        
      case EventResolutionType.timeBased:
        // For time-based events - normally we'd show a timer, but the requirement is to not show timer UI
        return ElevatedButton.icon(
          onPressed: null, // Not user-controllable
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade700,
            foregroundColor: Colors.white,
            minimumSize: const Size(100, 36),
          ),
          icon: const Icon(Icons.access_time, size: 18),
          label: const Text('RESOLVING...'),
        );
        
      default:
        return const SizedBox(); // Should never happen
    }
  }
  
  // Helper function to calculate a resolution fee
  double _calculateResolutionFee() {
    // Default fee
    double fee = 1000.0;
    
    // If the event has a predefined fee, use it
    if (widget.event.resolution.type == EventResolutionType.feeBased) {
      return widget.event.resolutionFee;
    }
    
    // Otherwise calculate based on event type
    switch (widget.event.type) {
      case EventType.disaster:
        fee = max(widget.gameState.money * 0.1, 1000); // 10% of money or minimum 1000
        break;
      case EventType.economic:
        fee = max(widget.gameState.money * 0.05, 500); // 5% of money or minimum 500
        break;
      case EventType.security:
        fee = max(widget.gameState.money * 0.08, 800); // 8% of money or minimum 800
        break;
      case EventType.utility:
        fee = max(widget.gameState.money * 0.06, 600); // 6% of money or minimum 600
        break;
      case EventType.staff:
        fee = max(widget.gameState.money * 0.04, 400); // 4% of money or minimum 400
        break;
    }
    
    // Round to make it cleaner
    return (fee / 100).round() * 100;
  }

  Widget _buildResolutionProgress() {
    // Show a concise message for the specific resolution type
    switch (widget.event.resolution.type) {
      case EventResolutionType.tapChallenge:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tap repeatedly to resolve:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: widget.event.requiredTaps > 0 ? 
                  ((widget.event.resolution.value is Map) ? 
                  (widget.event.resolution.value['current'] ?? 0) : 0) / widget.event.requiredTaps : 0,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ],
        );
        
      case EventResolutionType.feeBased:
        final fee = widget.event.resolutionFee;
        final canAfford = widget.gameState.money >= fee;
        
        return Row(
          children: [
            Icon(
              Icons.info_outline, 
              size: 16, 
              color: canAfford ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                canAfford 
                  ? 'Pay a fee to immediately resolve this issue.'
                  : 'You need \$${fee.toStringAsFixed(0)} to resolve this issue.',
                style: TextStyle(
                  color: canAfford ? Colors.black87 : Colors.red,
                  fontWeight: canAfford ? FontWeight.normal : FontWeight.bold,
                ),
              ),
            ),
          ],
        );
        
      case EventResolutionType.adBased:
        final bool isPremium = widget.gameState.isPremium;
        return Row(
          children: [
            Icon(
              Icons.info_outline, 
              size: 16, 
              color: isPremium ? Colors.purple : Colors.amber
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                isPremium 
                  ? 'Premium feature: Skip the ad to resolve this issue immediately.' 
                  : 'Watch a short ad to immediately resolve this issue.',
                style: TextStyle(
                  fontWeight: isPremium ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        );
        
      case EventResolutionType.timeBased:
        return const Row(
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.grey),
            SizedBox(width: 4),
            Expanded(
              child: Text(
                'This issue will resolve automatically over time.',
              ),
            ),
          ],
        );
        
      default:
        return const SizedBox();
    }
  }

  Widget _getEventIcon() {
    // Initialize with a default value
    IconData icon = Icons.event;
    
    switch (widget.event.type) {
      case EventType.disaster:
        icon = Icons.warning_amber_rounded;
        break;
      case EventType.economic:
        icon = Icons.trending_down;
        break;
      case EventType.security:
        icon = Icons.security;
        break;
      case EventType.utility:
        icon = Icons.electrical_services;
        break;
      case EventType.staff:
        icon = Icons.people;
        break;
      default:
        // Default icon already set
        break;
    }
    
    return Icon(
      icon,
      color: Colors.white,
      size: 24,
    );
  }

  Color _getBackgroundColor() {
    switch (widget.event.type) {
      case EventType.disaster:
        return Colors.red[700]!;
      case EventType.economic:
        return Colors.orange[800]!;
      case EventType.security:
        return Colors.purple[700]!;
      case EventType.utility:
        return Colors.blue[700]!;
      case EventType.staff:
        return Colors.teal[700]!;
      default:
        return Colors.grey[700]!; // Fallback color
    }
  }
}