import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/pacing_config.dart';
import '../models/game_state.dart';
import '../models/business.dart';
import '../widgets/business_item.dart';
import '../utils/responsive_utils.dart';

class BusinessScreen extends StatefulWidget {
  const BusinessScreen({Key? key}) : super(key: key);

  @override
  _BusinessScreenState createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen> {
  String _sortBy = 'default'; // default, level, income, cost

  List<Business> _getSortedBusinesses(List<Business> businesses, GameState gameState) {
    List<Business> sorted = List.from(businesses);
    
    switch (_sortBy) {
      case 'level':
        sorted.sort((a, b) => b.level.compareTo(a.level));
        break;
      case 'income':
        sorted.sort((a, b) {
          final iA = gameState.businesses.indexWhere((x) => x.id == a.id);
          final iB = gameState.businesses.indexWhere((x) => x.id == b.id);
          final incA = a.getIncomePerSecond() * (iA >= 0 ? PacingConfig.businessIncomeMultiplierForIndex(iA) : 1.0);
          final incB = b.getIncomePerSecond() * (iB >= 0 ? PacingConfig.businessIncomeMultiplierForIndex(iB) : 1.0);
          return incB.compareTo(incA);
        });
        break;
      case 'cost':
        sorted.sort((a, b) => gameState.getEffectiveBusinessUpgradeCost(a.id).compareTo(gameState.getEffectiveBusinessUpgradeCost(b.id)));
        break;
      default:
        break;
    }
    
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final layoutConstraints = responsive.layoutConstraints;
    
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        // Get list of businesses and sort based on selection
        List<Business> businesses = _getSortedBusinesses(gameState.businesses, gameState);

        return Scaffold(
          body: ResponsiveContainer(
            padding: EdgeInsets.symmetric(
              horizontal: layoutConstraints.cardPadding, 
              vertical: responsive.spacing(8.0)
            ),
            child: businesses.isEmpty
                ? Center(
                    child: ResponsiveText(
                      'No businesses available yet',
                      baseFontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  )
                : ListView.builder(
                    itemCount: businesses.length,
                    padding: EdgeInsets.only(
                      top: responsive.spacing(8.0), 
                      bottom: responsive.safeAreaBottom // Responsive bottom padding
                    ),
                    itemBuilder: (context, index) {
                      Business business = businesses[index];

                      // Only show unlocked businesses
                      if (!business.unlocked) return const SizedBox.shrink();

                      return ResponsiveContainer(
                        margin: EdgeInsets.only(bottom: layoutConstraints.listItemPadding),
                        child: BusinessItem(
                          business: business,
                        ),
                      );
                    },
                  ),
          ),
          // Responsive floating action button for sorting
          floatingActionButton: responsive.needsSpaceOptimization 
              ? null // Hide on very small screens to save space
              : _buildSortFAB(responsive),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  Widget _buildSortFAB(ResponsiveUtils responsive) {
    return FloatingActionButton(
      mini: responsive.isCompact,
      onPressed: () => _showSortDialog(),
      tooltip: 'Sort businesses',
      child: Icon(
        Icons.sort,
        size: responsive.iconSize(responsive.isCompact ? 20 : 24),
      ),
    );
  }

  void _showSortDialog() {
    final responsive = context.responsive;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: ResponsiveText(
          'Sort Businesses',
          baseFontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSortOption('Default Order', 'default', responsive),
            _buildSortOption('By Level', 'level', responsive),
            _buildSortOption('By Income', 'income', responsive),
            _buildSortOption('By Upgrade Cost', 'cost', responsive),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: ResponsiveText(
              'Close',
              baseFontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption(String title, String value, ResponsiveUtils responsive) {
    return RadioListTile<String>(
      title: ResponsiveText(
        title,
        baseFontSize: 16,
      ),
      value: value,
      groupValue: _sortBy,
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _sortBy = newValue;
          });
          Navigator.of(context).pop();
        }
      },
      contentPadding: responsive.padding(horizontal: 0),
    );
  }
}