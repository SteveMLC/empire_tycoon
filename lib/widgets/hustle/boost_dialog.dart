import 'package:flutter/material.dart';
import '../../models/game_state.dart';

/// Dialog for activating hustle boosts
class BoostDialog extends StatelessWidget {
  final GameState gameState;
  
  const BoostDialog({Key? key, required this.gameState}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Activate Tap Boost'),
      content: const Text('Placeholder for boost dialog'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
} 