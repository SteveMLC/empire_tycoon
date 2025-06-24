import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/business.dart';
import '../models/game_state.dart';
import '../services/game_service.dart';
import '../widgets/business_item.dart';

class BusinessScreen extends StatefulWidget {
  const BusinessScreen({Key? key}) : super(key: key);

  @override
  _BusinessScreenState createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen> {
  // Sort options for businesses
  final List<String> _sortOptions = [
    'Default',
    'Price (Low to High)',
    'Price (High to Low)',
    'ROI (High to Low)',
    'Income (High to Low)',
    'Level (High to Low)',
  ];

  String _currentSort = 'Default';

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        // Get list of businesses and sort based on selection
        List<Business> businesses = _getSortedBusinesses(gameState.businesses);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sort dropdown with improved styling
              _buildSortDropdown(),
              
              // Businesses list
              Expanded(
                child: businesses.isEmpty
                    ? const Center(child: Text('No businesses available yet'))
                    : ListView.builder(
                        itemCount: businesses.length,
                        padding: const EdgeInsets.only(top: 8.0, bottom: 80.0), // Add bottom padding to prevent Android UI overlap
                        itemBuilder: (context, index) {
                          Business business = businesses[index];

                          // Only show unlocked businesses
                          if (!business.unlocked) return const SizedBox.shrink();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0), // Reduced from 12.0 to 8.0 for more compact layout
                            child: BusinessItem(
                              business: business,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0), // Reduced bottom margin
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,  // Add background color
        boxShadow: [  // Add subtle shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: _currentSort,
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(Icons.sort, color: Colors.blue),  // Changed icon color to match theme
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _currentSort = newValue;
            });
          }
        },
        items: _sortOptions.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Business> _getSortedBusinesses(List<Business> businesses) {
    // Create a copy of the list to avoid modifying the original
    List<Business> sorted = List.from(businesses);

    switch (_currentSort) {
      case 'Price (Low to High)':
        sorted.sort((a, b) => a.getNextUpgradeCost().compareTo(b.getNextUpgradeCost()));
        break;
      case 'Price (High to Low)':
        sorted.sort((a, b) => b.getNextUpgradeCost().compareTo(a.getNextUpgradeCost()));
        break;
      case 'ROI (High to Low)':
        sorted.sort((a, b) => b.getROI().compareTo(a.getROI()));
        break;
      case 'Income (High to Low)':
        sorted.sort((a, b) => b.getIncomePerSecond().compareTo(a.getIncomePerSecond()));
        break;
      case 'Level (High to Low)':
        sorted.sort((a, b) => b.level.compareTo(a.level));
        break;
      default:
        // Default is the original order
        break;
    }

    return sorted;
  }
}