import 'package:flutter/material.dart';

class StarRatingDialog extends StatefulWidget {
  final void Function(int rating) onRatingSelected;
  final VoidCallback onCancel;

  const StarRatingDialog({
    Key? key,
    required this.onRatingSelected,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<StarRatingDialog> createState() => _StarRatingDialogState();
}

class _StarRatingDialogState extends State<StarRatingDialog> {
  int _selectedRating = 0;
  int _hoverRating = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        children: [
          Icon(Icons.star, color: Colors.amber, size: 26),
          SizedBox(width: 8),
          Text(
            'Rate Us',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'How would you rate Empire Tycoon?',
            style: TextStyle(fontSize: 16, height: 1.3),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starNumber = index + 1;
              final isSelected = starNumber <= (_hoverRating > 0 ? _hoverRating : _selectedRating);
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRating = starNumber;
                  });
                },
                onTapDown: (_) {
                  setState(() {
                    _hoverRating = starNumber;
                  });
                },
                onTapUp: (_) {
                  setState(() {
                    _hoverRating = 0;
                  });
                },
                onTapCancel: () {
                  setState(() {
                    _hoverRating = 0;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedScale(
                    scale: isSelected ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      isSelected ? Icons.star : Icons.star_border,
                      color: isSelected ? Colors.amber : Colors.grey,
                      size: 40,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _getRatingLabel(),
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedRating > 0 
              ? () => widget.onRatingSelected(_selectedRating)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: const Text('Submit'),
        ),
      ],
    );
  }

  String _getRatingLabel() {
    final rating = _hoverRating > 0 ? _hoverRating : _selectedRating;
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Great';
      case 5:
        return 'Excellent!';
      default:
        return 'Tap a star to rate';
    }
  }
}
