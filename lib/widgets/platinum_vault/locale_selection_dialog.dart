import 'package:flutter/material.dart';
import '../../models/real_estate.dart';

/// Dialog for selecting a real estate locale for applying platinum items
class LocaleSelectionDialog extends StatefulWidget {
  final List<RealEstateLocale> eligibleLocales;
  final Function(String?) onConfirm;
  final String title;
  final String message;
  
  const LocaleSelectionDialog({
    Key? key,
    required this.eligibleLocales,
    required this.onConfirm,
    this.title = 'Select Location',
    this.message = 'Choose a location to apply the Foundation:',
  }) : super(key: key);

  @override
  _LocaleSelectionDialogState createState() => _LocaleSelectionDialogState();
}

class _LocaleSelectionDialogState extends State<LocaleSelectionDialog> {
  String? _selectedLocaleId;

  @override
  void initState() {
    super.initState();
    // Default to first locale if available
    if (widget.eligibleLocales.isNotEmpty) {
      _selectedLocaleId = widget.eligibleLocales.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.title,
        style: const TextStyle(
          color: Color(0xFFFFD700),
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: const Color(0xFF2D0C3E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFFFFD700),
          width: 1.5,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.message,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: DropdownButton<String>(
                value: _selectedLocaleId,
                isExpanded: true,
                dropdownColor: const Color(0xFF2D0C3E),
                style: const TextStyle(color: Colors.white),
                underline: const SizedBox(), // Remove the default underline
                items: widget.eligibleLocales.map((locale) {
                  return DropdownMenuItem<String>(
                    value: locale.id,
                    child: Row(
                      children: [
                        Icon(
                          locale.icon,
                          color: Theme.of(context).primaryColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(locale.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedLocaleId = newValue;
                  });
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: Colors.white70),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onConfirm(_selectedLocaleId);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: Colors.black,
          ),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

/// Dialog specifically for yacht docking selection
class YachtDockingSelectionDialog extends StatefulWidget {
  final List<RealEstateLocale> eligibleLocales;
  final Function(String?) onConfirm;
  
  const YachtDockingSelectionDialog({
    Key? key,
    required this.eligibleLocales,
    required this.onConfirm,
  }) : super(key: key);

  @override
  _YachtDockingSelectionDialogState createState() => _YachtDockingSelectionDialogState();
}

class _YachtDockingSelectionDialogState extends State<YachtDockingSelectionDialog> {
  String? _selectedLocaleId;

  @override
  void initState() {
    super.initState();
    // Default to first locale if available
    if (widget.eligibleLocales.isNotEmpty) {
      _selectedLocaleId = widget.eligibleLocales.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LocaleSelectionDialog(
      eligibleLocales: widget.eligibleLocales,
      onConfirm: widget.onConfirm,
      title: 'Select Docking Location',
      message: 'Choose a mega-locale to dock your Platinum Yacht:',
    );
  }
} 