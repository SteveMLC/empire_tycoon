import 'package:flutter/material.dart';
import '../../models/game_state.dart';

/// Dialog for upgrading hustle capabilities
class UpgradeDialog extends StatelessWidget {
  final GameState gameState;
  
  const UpgradeDialog({Key? key, required this.gameState}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upgrade Tapping Power'),
      content: const Text('Placeholder for upgrade dialog'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
} 