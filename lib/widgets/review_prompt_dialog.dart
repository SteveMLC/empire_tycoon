import 'package:flutter/material.dart';

class ReviewPromptDialog extends StatelessWidget {
  final VoidCallback onLoveIt;
  final VoidCallback onNotReally;
  final VoidCallback? onNeverShowAgain;

  const ReviewPromptDialog({
    Key? key,
    required this.onLoveIt,
    required this.onNotReally,
    this.onNeverShowAgain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(Icons.emoji_events, color: theme.colorScheme.primary, size: 26),
          const SizedBox(width: 8),
          const Text(
            'Great progress!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: const Text(
        'Are you enjoying Empire Tycoon?',
        style: TextStyle(fontSize: 16, height: 1.3),
      ),
      actions: [
        if (onNeverShowAgain != null)
          TextButton(
            onPressed: onNeverShowAgain,
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text('Never ask again'),
          ),
        TextButton(
          onPressed: onNotReally,
          child: const Text('Not Really'),
        ),
        ElevatedButton(
          onPressed: onLoveIt,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: const Text('Love It!'),
        ),
      ],
    );
  }
}
