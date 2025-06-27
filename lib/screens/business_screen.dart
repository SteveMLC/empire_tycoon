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

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
          // Compact floating action button for sorting
          floatingActionButton: _buildSortFAB(),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  Widget _buildSortFAB() {
    return FloatingActionButton.small(
      onPressed: _showSortBottomSheet,
      backgroundColor: Colors.white,
      foregroundColor: Colors.blue,
      elevation: 4,
      child: Stack(
        children: [
          const Icon(Icons.sort, size: 20),
          // Small indicator dot if not on default sort
          if (_currentSort != 'Default')
            Positioned(
              right: 0,
              top: 0,
                             child: Container(
                 width: 8,
                 height: 8,
                 decoration: const BoxDecoration(
                   color: Colors.orange,
                   shape: BoxShape.circle,
                 ),
               ),
            ),
        ],
      ),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.sort, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Sort Businesses',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Sort options
              ..._sortOptions.map((option) => _buildSortOption(option)),
              
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String option) {
    final isSelected = _currentSort == option;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentSort = option;
            });
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.shade50 : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getSortIcon(option),
                  color: isSelected ? Colors.blue : Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      color: isSelected ? Colors.blue : Colors.grey.shade800,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Colors.blue,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getSortIcon(String option) {
    switch (option) {
      case 'Default':
        return Icons.list;
      case 'Price (Low to High)':
        return Icons.arrow_upward;
      case 'Price (High to Low)':
        return Icons.arrow_downward;
      case 'ROI (High to Low)':
        return Icons.trending_up;
      case 'Income (High to Low)':
        return Icons.attach_money;
      case 'Level (High to Low)':
        return Icons.bar_chart;
      default:
        return Icons.sort;
    }
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