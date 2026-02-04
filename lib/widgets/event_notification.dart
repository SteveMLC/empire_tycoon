import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';
import '../models/game_state.dart';

import '../services/admob_service.dart';
import 'package:flutter/foundation.dart';

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
  Timer? _countdownTimer;
  Timer? _autoClickHoldTimer;
  static const int _eventPPSkipCost = 5;

  // Fail-open rewarded ad UX state
  bool _isResolvingViaAd = false;

  static const String _adWatchCountKey = 'event_ad_watch_count';
  static const String _premiumPromoAfterAdShownKey = 'premium_promo_after_ad_shown';

  @override
  void initState() {
    super.initState();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _autoClickHoldTimer?.cancel();
    _autoClickHoldTimer = null;
    super.dispose();
  }

  void _stopAutoClickHoldTimer() {
    _autoClickHoldTimer?.cancel();
    _autoClickHoldTimer = null;
  }

  void _onTapChallengeAutoClickTick() {
    if (!mounted) {
      _stopAutoClickHoldTimer();
      return;
    }
    final gs = widget.gameState;
    if (!gs.isAutoClickerActive || widget.event.isResolved) {
      _stopAutoClickHoldTimer();
      return;
    }
    gs.processTapForEvent(widget.event);
    gs.tap();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      // Update UI every second to show countdown progress
      setState(() {});
      
      // If event has expired, cancel timer
      if (widget.event.hasExpired) {
        timer.cancel();
      }
    });
  }

  /// Get affected business names from IDs
  List<String> _getAffectedBusinessNames() {
    List<String> businessNames = [];
    for (String businessId in widget.event.affectedBusinessIds) {
      try {
        final matchingBusinesses = widget.gameState.businesses
            .where((b) => b.id == businessId)
            .toList();
        if (matchingBusinesses.isNotEmpty) {
          businessNames.add(matchingBusinesses.first.name);
        }
      } catch (e) {
        print('Error getting business name for ID $businessId: $e');
      }
    }
    return businessNames;
  }

  /// Get affected locale names from IDs
  List<String> _getAffectedLocaleNames() {
    List<String> localeNames = [];
    for (String localeId in widget.event.affectedLocaleIds) {
      try {
        final matchingLocales = widget.gameState.realEstateLocales
            .where((l) => l.id == localeId)
            .toList();
        if (matchingLocales.isNotEmpty) {
          localeNames.add(matchingLocales.first.name);
        }
      } catch (e) {
        print('Error getting locale name for ID $localeId: $e');
      }
    }
    return localeNames;
  }

  /// Get a comprehensive affected entities description
  String _getAffectedEntitiesDescription() {
    final businessNames = _getAffectedBusinessNames();
    final localeNames = _getAffectedLocaleNames();
    
    List<String> descriptions = [];
    
    if (businessNames.isNotEmpty) {
      descriptions.add("Business: ${businessNames.join(', ')}");
    }
    
    if (localeNames.isNotEmpty) {
      descriptions.add("Location: ${localeNames.join(', ')}");
    }
    
    return descriptions.join(' • ');
  }

  void _resolveEventWithTracking(String method, {int ppSpent = 0}) {
    if (widget.event.isResolved) return;

    widget.event.resolve();
    widget.gameState.totalEventsResolved++;

    if (method == 'ad') {
      widget.gameState.eventsResolvedByAd++;
    } else if (method == 'fallback') {
      widget.gameState.eventsResolvedByFallback++;
    } else if (method == 'pp') {
      widget.gameState.eventsResolvedByPP++;
      widget.gameState.ppSpentOnEventSkips += ppSpent;
    }

    widget.gameState.trackEventResolution(widget.event, method);
    widget.onResolved();
  }

  Future<void> _handleAdFailure(AdMobService adMobService) async {
    if (!mounted) return;

    setState(() {
      _isResolvingViaAd = false;
    });

    final canFallback = await adMobService.canUseEventFailOpenNow();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Ad not available'),
          content: Text(
            canFallback
                ? 'We couldn\'t load a rewarded ad right now. You can try again, or use a limited fallback to resolve this event.'
                : 'We couldn\'t load a rewarded ad right now. Please try again in a bit, or let the event auto-resolve.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Try again'),
            ),
            if (canFallback)
              TextButton(
                onPressed: () async {
                  try {
                    _resolveEventWithTracking('fallback');
                    await adMobService.markEventFailOpenUsed();
                  } catch (_) {}

                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                  }
                },
                child: const Text('Use fallback'),
              ),
          ],
        );
      },
    );
  }

  Future<void> _onEventAdWatched() async {
    if (!mounted || widget.gameState.isPremium) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt(_adWatchCountKey) ?? 0;
      final newCount = count + 1;
      await prefs.setInt(_adWatchCountKey, newCount);

      final promoShown = prefs.getBool(_premiumPromoAfterAdShownKey) ?? false;
      if (newCount >= 2 && !promoShown) {
        await prefs.setBool(_premiumPromoAfterAdShownKey, true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tired of ads? Premium lets you skip them.'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Learn more',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushNamed(context, '/user_profile');
              },
            ),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _handleWatchAdPressed() async {
    if (_isResolvingViaAd || widget.event.isResolved) return;
    final adMobService = Provider.of<AdMobService>(context, listen: false);

    if (kDebugMode) {
      print('🎯 === EVENT AD BUTTON PRESSED ===');
      print('🎯 Event: ${widget.event.name}');
      print('🎯 Event ID: ${widget.event.id}');
      print('🎯 Event IsResolved: ${widget.event.isResolved}');
    }

    _isResolvingViaAd = true;
    if (mounted) setState(() {});

    try {
      await adMobService.showEventClearAd(
        onRewardEarned: (String rewardType) {
          if (!mounted) return;
          setState(() {
            _isResolvingViaAd = false;
          });

          if (kDebugMode) {
            print('🎁 === EVENT AD REWARD CALLBACK ===');
            print('🎁 Received reward type: $rewardType');
            print('🎁 Expected: EventAdSkip');
          }

          if (rewardType != 'EventAdSkip') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Unexpected reward type: $rewardType. Please try again.'),
                duration: const Duration(seconds: 3),
              ),
            );
            return;
          }

          try {
            _resolveEventWithTracking('ad');
            if (kDebugMode) {
              print('🎁 === EVENT AD SKIP COMPLETE ===');
            }
            _onEventAdWatched();
          } catch (e) {
            if (kDebugMode) {
              print('❌ Error in event resolution: $e');
            }
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error resolving event. Please try again.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        },
        onAdFailure: () async {
          await _handleAdFailure(adMobService);
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ showEventClearAd threw an error: $e');
      }
      await _handleAdFailure(adMobService);
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingViaAd = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    
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
            mainAxisSize: MainAxisSize.min,
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
                      mainAxisSize: MainAxisSize.min,
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Add affected entities information with financial impact
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getAffectedEntitiesDescription(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                                                             Text(
                                 _getFinancialImpactDescription(),
                                 style: TextStyle(
                                   fontSize: 11,
                                   color: Colors.red.shade100,
                                   fontWeight: FontWeight.w400,
                                 ),
                               ),
                            ],
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
                    // Auto-expiry timer for all events
                    _buildAutoExpiryTimer(),
                    
                    const SizedBox(height: 8),
                    
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
        
        // Event name and affected entities
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.event.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _getAffectedEntitiesDescription(),
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Mini timer display
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, size: 10, color: Colors.white70),
                    const SizedBox(width: 2),
                    Text(
                      _getTimeRemainingFormatted(),
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
        // Just show the tap icon with current/total; support hold-to-auto-click when Auto Clicker is active
        final int requiredTaps = widget.event.requiredTaps;
        final int currentTaps = (widget.event.resolution.value is Map) ?
            widget.event.resolution.value['current'] ?? 0 : 0;
        final bool autoClickerActive = widget.gameState.isAutoClickerActive;

        final tapChallengeChild = InkWell(
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
                if (autoClickerActive) ...[
                  const SizedBox(width: 4),
                  Text(
                    '(hold)',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
        );

        if (!autoClickerActive) {
          return tapChallengeChild;
        }
        return GestureDetector(
          onTapDown: (_) {
            _autoClickHoldTimer?.cancel();
            _autoClickHoldTimer = Timer.periodic(const Duration(milliseconds: 100), (_) => _onTapChallengeAutoClickTick());
          },
          onTapUp: (_) => _stopAutoClickHoldTimer(),
          onTapCancel: _stopAutoClickHoldTimer,
          behavior: HitTestBehavior.opaque,
          child: tapChallengeChild,
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
            widget.gameState.eventFeesSpent += fee;
            widget.gameState.trackEventResolution(widget.event, "fee");
            widget.onResolved();
          } : () {
            // Show cannot afford message
            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(
            //     content: Text('You need \$${fee.toStringAsFixed(0)} to resolve this event.'),
            //     duration: const Duration(seconds: 2),
            //   ),
            // );
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
        // Ad button with premium bypass and PP skip option (minimized)
        final bool isPremium = widget.gameState.isPremium;
        final int ppCost = _eventPPSkipCost;
        final bool canAffordPP = widget.gameState.platinumPoints >= ppCost;
        final bool canUsePP = canAffordPP && !_isResolvingViaAd;
        
        // Premium users just see skip button
        if (isPremium) {
          return InkWell(
            onTap: () {
              _resolveEventWithTracking('ad');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('SKIP', style: TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
            ),
          );
        }
        
        // Non-premium: show AD + PP option; Wrap to avoid overflow on narrow width
        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            // Watch AD button (compact)
            InkWell(
              onTap: _isResolvingViaAd ? null : _handleWatchAdPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.video_library, color: Colors.black, size: 16),
                    SizedBox(width: 4),
                    Text('AD', style: TextStyle(color: Colors.black, fontSize: 14)),
                  ],
                ),
              ),
            ),
            // PP Skip button (compact pill)
            InkWell(
              onTap: canUsePP ? () {
                if (widget.gameState.platinumPoints < ppCost) return;
                widget.gameState.platinumPoints -= ppCost;
                _resolveEventWithTracking('pp', ppSpent: ppCost);
                
                if (kDebugMode) {
                  print('💎 === EVENT PP SKIP (minimized) ===');
                  print('💎 Spent $ppCost PP to skip event');
                }
              } : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: canUsePP ? Colors.cyan.shade600 : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.diamond,
                      color: canUsePP ? Colors.white : Colors.grey.shade600,
                      size: 14,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$ppCost',
                      style: TextStyle(
                        color: canUsePP ? Colors.white : Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
        // Tap challenge button - Shows tap count; support hold-to-auto-click when Auto Clicker is active
        final int requiredTaps = widget.event.requiredTaps;
        final int currentTaps = (widget.event.resolution.value is Map) ?
            widget.event.resolution.value['current'] ?? 0 : 0;
        final bool autoClickerActive = widget.gameState.isAutoClickerActive;

        final tapChallengeButton = ElevatedButton.icon(
          onPressed: widget.onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(100, 36),
          ),
          icon: const Icon(Icons.touch_app, size: 18),
          label: Text(autoClickerActive ? 'TAP ${currentTaps}/${requiredTaps} (hold)' : 'TAP ${currentTaps}/${requiredTaps}'),
        );

        if (!autoClickerActive) {
          return tapChallengeButton;
        }
        return GestureDetector(
          onTapDown: (_) {
            _autoClickHoldTimer?.cancel();
            _autoClickHoldTimer = Timer.periodic(const Duration(milliseconds: 100), (_) => _onTapChallengeAutoClickTick());
          },
          onTapUp: (_) => _stopAutoClickHoldTimer(),
          onTapCancel: _stopAutoClickHoldTimer,
          behavior: HitTestBehavior.opaque,
          child: tapChallengeButton,
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
        // Ad-based button with premium bypass and PP skip option
        final bool isPremium = widget.gameState.isPremium;
        final int ppCost = _eventPPSkipCost;
        final bool canAffordPP = widget.gameState.platinumPoints >= ppCost;
        final bool canUsePP = canAffordPP && !_isResolvingViaAd;
        
        // For premium users, just show the skip button
        if (isPremium) {
          return ElevatedButton.icon(
            onPressed: () {
              _resolveEventWithTracking('ad');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              minimumSize: const Size(100, 36),
            ),
            icon: const Icon(Icons.star, size: 18),
            label: const Text('SKIP AD'),
          );
        }
        
        // For non-premium users, show Watch AD + PP skip option; Wrap to avoid overflow on narrow width
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Watch AD button
            ElevatedButton.icon(
              onPressed: _isResolvingViaAd
                  ? null
                  : _handleWatchAdPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                minimumSize: const Size(90, 36),
              ),
              icon: const Icon(Icons.video_library, size: 18),
              label: const Text('WATCH AD'),
            ),
            // PP Skip button - compact pill design
            Material(
              color: canUsePP ? Colors.cyan.shade600 : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: canUsePP ? () {
                  if (widget.gameState.platinumPoints < ppCost) return;
                  // Deduct PP and resolve
                  widget.gameState.platinumPoints -= ppCost;
                  _resolveEventWithTracking('pp', ppSpent: ppCost);
                  
                  if (kDebugMode) {
                    print('💎 === EVENT PP SKIP ===');
                    print('💎 Spent $ppCost PP to skip event');
                    print('💎 Remaining PP: ${widget.gameState.platinumPoints}');
                  }
                } : null,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.diamond,
                        size: 16,
                        color: canUsePP ? Colors.white : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$ppCost PP',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: canUsePP ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
        
      case EventResolutionType.timeBased:
        // Show timer for time-based events
        final timeRemaining = _getTimeRemainingFormatted();
        
        return ElevatedButton.icon(
          onPressed: null, // Not user-controllable
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade700,
            foregroundColor: Colors.white,
            minimumSize: const Size(100, 36),
          ),
          icon: const Icon(Icons.timer, size: 18),
          label: Text(timeRemaining.isNotEmpty ? timeRemaining : 'RESOLVING...'),
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
        final bool canAffordPP = widget.gameState.platinumPoints >= _eventPPSkipCost;
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
                  : canAffordPP
                    ? 'Watch a short ad or spend $_eventPPSkipCost PP to resolve this issue.'
                    : 'Watch a short ad to immediately resolve this issue.',
                style: TextStyle(
                  fontWeight: isPremium ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        );
        
      case EventResolutionType.timeBased:
        final timeRemaining = _getTimeRemainingFormatted();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'This issue will resolve automatically over time.',
                  ),
                ),
              ],
            ),
            if (timeRemaining.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Time remaining: $timeRemaining',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

  /// Get detailed financial impact description showing income loss
  String _getFinancialImpactDescription() {
    List<String> impacts = [];
    
    // Calculate business impact
    for (String businessId in widget.event.affectedBusinessIds) {
      try {
        final business = widget.gameState.businesses
            .firstWhere((b) => b.id == businessId);
        
        if (business.level > 0) {
          double normalIncome = business.levels[business.level - 1].incomePerSecond;
          double lostIncome = normalIncome * 0.25; // 25% loss
          impacts.add('Business: -\$${lostIncome.toStringAsFixed(2)}/s');
        }
      } catch (e) {
        print('Error calculating business impact for $businessId: $e');
      }
    }
    
    // Calculate real estate impact
    for (String localeId in widget.event.affectedLocaleIds) {
      try {
        final locale = widget.gameState.realEstateLocales
            .firstWhere((l) => l.id == localeId);
        
        double normalIncome = locale.getTotalIncomePerSecond();
        double lostIncome = normalIncome * 0.25; // 25% loss
        impacts.add('Location: -\$${lostIncome.toStringAsFixed(2)}/s');
      } catch (e) {
        print('Error calculating locale impact for $localeId: $e');
      }
    }
    
    return impacts.isNotEmpty 
        ? 'Income Impact: ${impacts.join(' • ')}'
        : 'Income reduced by 25%';
  }

  /// Get time remaining for ALL events formatted as MM:SS
  String _getTimeRemainingFormatted() {
    final int secondsRemaining = widget.event.timeRemaining;
    if (secondsRemaining <= 0) {
      return 'Resolving...';
    }
    
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  /// Build auto-expiry timer display for all events
  Widget _buildAutoExpiryTimer() {
    final timeRemaining = _getTimeRemainingFormatted();
    final bool isExpiring = widget.event.timeRemaining < 300; // Last 5 minutes
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isExpiring ? Colors.red.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isExpiring ? Colors.red.shade200 : Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            size: 16,
            color: isExpiring ? Colors.red.shade600 : Colors.blue.shade600,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Auto-resolves in: $timeRemaining',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isExpiring ? Colors.red.shade700 : Colors.blue.shade700,
              ),
            ),
          ),
          if (isExpiring)
            Icon(
              Icons.warning,
              size: 14,
              color: Colors.red.shade600,
            ),
        ],
      ),
    );
  }
}
