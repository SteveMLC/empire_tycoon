import 'package:flutter/material.dart';
import '../models/business.dart';
import '../models/game_state.dart';
import 'package:provider/provider.dart';

class PlatinumFacadeSelector extends StatefulWidget {
  final Function(String) onBusinessSelected;
  
  const PlatinumFacadeSelector({
    Key? key,
    required this.onBusinessSelected,
  }) : super(key: key);
  
  @override
  _PlatinumFacadeSelectorState createState() => _PlatinumFacadeSelectorState();
  
  // Helper method to show the dialog
  static Future<String?> show(BuildContext context) async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: PlatinumFacadeSelector(
            onBusinessSelected: (String businessId) {
              Navigator.of(context).pop(businessId);
            },
          ),
        );
      },
    );
  }
}

class _PlatinumFacadeSelectorState extends State<PlatinumFacadeSelector> {
  String? _selectedBusinessId;
  
  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final availableBusinesses = gameState.getBusinessesForPlatinumFacade();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title with platinum styling
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, const Color(0xFFE5E4E2), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Select a Business',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF505050),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Description text
          const Text(
            'Choose which business to upgrade with the Platinum Facade:',
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // List of businesses to select from
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: availableBusinesses.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No businesses available to upgrade.\nPurchase at least one business first.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableBusinesses.length,
                    itemBuilder: (context, index) {
                      final business = availableBusinesses[index];
                      final isSelected = business.id == _selectedBusinessId;
                      
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFE5E4E2)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            business.icon,
                            color: isSelected
                                ? const Color(0xFF505050)
                                : Colors.blue,
                          ),
                        ),
                        title: Text(
                          business.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text('Level ${business.level}'),
                        tileColor: isSelected ? Colors.grey.shade100 : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: isSelected
                              ? const BorderSide(color: Color(0xFFE5E4E2), width: 1)
                              : BorderSide.none,
                        ),
                        onTap: () {
                          setState(() {
                            _selectedBusinessId = business.id;
                          });
                        },
                      );
                    },
                  ),
          ),
          
          const SizedBox(height: 20),
          
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey,
                ),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _selectedBusinessId == null
                    ? null
                    : () {
                        widget.onBusinessSelected(_selectedBusinessId!);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5E4E2),
                  foregroundColor: const Color(0xFF505050),
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                  elevation: 2,
                ),
                child: const Text('Apply Facade'),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 