import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/game_state.dart';
import '../utils/number_formatter.dart';

/// A draggable Net Worth Ticker widget that displays lifetime earnings
/// 
/// This widget has two states:
/// - **Collapsed**: Shows just a crown icon
/// - **Expanded**: Shows "LIFETIME NET WORTH" label with animated dollar amount
/// 
/// Features:
/// - Draggable anywhere on screen
/// - Tap crown icon to toggle between collapsed/expanded
/// - Smooth number animation as earnings increase
/// - Position persists in GameState
/// - Semi-transparent to not block gameplay
/// - High z-index to render on top of everything
class NetWorthTicker extends StatefulWidget {
  const NetWorthTicker({Key? key}) : super(key: key);

  @override
  State<NetWorthTicker> createState() => _NetWorthTickerState();
}

class _NetWorthTickerState extends State<NetWorthTicker> with TickerProviderStateMixin {
  late AnimationController _numberAnimationController;
  late Animation<double> _numberAnimation;
  double _previousValue = 0.0;
  double _targetValue = 0.0;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    
    // Animation controller for smooth number transitions
    _numberAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _numberAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _numberAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Update the ticker periodically to animate earnings changes
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateTickerValue();
      }
    });
    
    // Initialize with current value
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final gameState = Provider.of<GameState>(context, listen: false);
        _previousValue = gameState.totalEarned;
        _targetValue = gameState.totalEarned;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _numberAnimationController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  void _updateTickerValue() {
    final gameState = Provider.of<GameState>(context, listen: false);
    final currentValue = gameState.totalEarned;
    
    // Only animate if there's a meaningful change (more than $1)
    if ((currentValue - _targetValue).abs() > 1.0) {
      setState(() {
        _previousValue = _targetValue;
        _targetValue = currentValue;
      });
      
      // Animate from previous to new value
      _numberAnimation = Tween<double>(
        begin: _previousValue,
        end: _targetValue,
      ).animate(CurvedAnimation(
        parent: _numberAnimationController,
        curve: Curves.easeOutCubic,
      ));
      
      _numberAnimationController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        // Get position from GameState, default to top-right if not set
        final position = gameState.netWorthTickerPosition ?? const Offset(20, 100);
        final isExpanded = gameState.isNetWorthTickerExpanded;
        
        return Positioned(
          left: position.dx,
          top: position.dy,
          child: Draggable(
            feedback: _buildTickerContent(isExpanded, gameState, isDragging: true),
            childWhenDragging: Container(), // Hide original while dragging
            onDragEnd: (details) {
              // Save new position to GameState
              final RenderBox renderBox = context.findRenderObject() as RenderBox;
              final screenSize = MediaQuery.of(context).size;
              
              // Calculate new position, ensuring it stays within screen bounds
              double newX = details.offset.dx;
              double newY = details.offset.dy;
              
              // Get widget size to prevent it from going off-screen
              final widgetWidth = isExpanded ? 280.0 : 60.0;
              final widgetHeight = isExpanded ? 100.0 : 60.0;
              
              // Clamp to screen bounds with padding
              newX = newX.clamp(10.0, screenSize.width - widgetWidth - 10);
              newY = newY.clamp(50.0, screenSize.height - widgetHeight - 10);
              
              gameState.setNetWorthTickerPosition(Offset(newX, newY));
            },
            child: _buildTickerContent(isExpanded, gameState),
          ),
        );
      },
    );
  }

  Widget _buildTickerContent(bool isExpanded, GameState gameState, {bool isDragging = false}) {
    return GestureDetector(
      onTap: () {
        // Toggle expanded state when tapping the crown icon
        gameState.toggleNetWorthTicker();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isExpanded ? 16 : 8,
          vertical: isExpanded ? 12 : 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.85),
              Colors.black.withOpacity(0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isExpanded ? 16 : 30),
          border: Border.all(
            color: Colors.amber.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(isDragging ? 0.4 : 0.2),
              blurRadius: isDragging ? 20 : 12,
              spreadRadius: isDragging ? 2 : 0,
            ),
          ],
        ),
        child: isExpanded ? _buildExpandedView(gameState) : _buildCollapsedView(),
      ),
    );
  }

  Widget _buildCollapsedView() {
    return Container(
      width: 44,
      height: 44,
      child: const Center(
        child: Text(
          '👑',
          style: TextStyle(fontSize: 32),
        ),
      ),
    );
  }

  Widget _buildExpandedView(GameState gameState) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown icon (tap to collapse)
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.amber.withOpacity(0.2),
          ),
          child: const Center(
            child: Text(
              '👑',
              style: TextStyle(fontSize: 28),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Net worth display
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LIFETIME NET WORTH',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade300,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedBuilder(
              animation: _numberAnimation,
              builder: (context, child) {
                final displayValue = _numberAnimation.value > 0 
                    ? _numberAnimation.value 
                    : gameState.totalEarned;
                
                return ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: [
                        Colors.amber.shade200,
                        Colors.amber.shade400,
                        Colors.yellow.shade300,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ).createShader(bounds);
                  },
                  child: Text(
                    '\$${formatNumber(displayValue)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.0,
                      letterSpacing: 0.5,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
