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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Row with sort dropdown and reset button
              Row(
                children: [
                  // Sort dropdown
                  Expanded(child: _buildSortDropdown()),
                ],
              ),

              const SizedBox(height: 10),

              // Businesses list
              Expanded(
                child: businesses.isEmpty
                    ? const Center(child: Text('No businesses available yet'))
                    : ListView.builder(
                        itemCount: businesses.length,
                        itemBuilder: (context, index) {
                          Business business = businesses[index];

                          // Only show unlocked businesses
                          if (!business.unlocked) return const SizedBox.shrink();

                          return BusinessItem(
                            business: business,
                            onBuy: () {
                              bool purchased = gameState.buyBusiness(business.id);
                              if (purchased) {
                                // Play appropriate sound based on current level
                                final gameService = Provider.of<GameService>(context, listen: false);
                                if (business.level <= 1) {
                                  // If it was just purchased (level went from 0 to 1)
                                  gameService.soundManager.playBusinessPurchaseSound();
                                } else {
                                  // If it was upgraded (level > 1)
                                  gameService.soundManager.playBusinessUpgradeSound();
                                }
                              } else {
                                // Play error sound if not enough money
                                final gameService = Provider.of<GameService>(context, listen: false);
                                gameService.soundManager.playErrorSound();
                              }
                            },
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: _currentSort,
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(Icons.sort),
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
            child: Text(value),
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