import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../models/real_estate.dart';
import '../widgets/money_display.dart';
import '../widgets/property_gallery_dialog.dart';
import '../utils/number_formatter.dart';
import '../services/game_service.dart';

class RealEstateScreen extends StatefulWidget {
  const RealEstateScreen({Key? key}) : super(key: key);

  @override
  State<RealEstateScreen> createState() => _RealEstateScreenState();
}

class _RealEstateScreenState extends State<RealEstateScreen> {
  RealEstateLocale? _selectedLocale;
  
  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    // Use a custom theme with green as primary color
    final theme = Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: Colors.green.shade700,
      ),
    );
    
    return Scaffold(
      body: Column(
        children: [
          // Header with real estate income display
          Container(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            width: double.infinity,
            child: Column(
              children: [
                // Main income display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.home, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Real Estate Income',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Income value with animation - including multipliers
                Text(
                  '\$${NumberFormatter.formatCompact(
                    gameState.getRealEstateIncomePerSecond() * 
                    gameState.incomeMultiplier * 
                    gameState.prestigeMultiplier
                  )}/sec',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                
                // Portfolio summary if there are properties - now clickable
                if (gameState.getTotalOwnedProperties() > 0) Column(children: [
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      // Get all owned properties with details
                      List<Map<String, dynamic>> ownedProperties = gameState.getAllOwnedPropertiesWithDetails();
                      
                      // Show the property gallery dialog
                      showDialog(
                        context: context,
                        builder: (context) => PropertyGalleryDialog(
                          ownedProperties: ownedProperties,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Portfolio: ${gameState.getTotalOwnedProperties()} Properties',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.visibility,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          
          // Real Estate content
          Expanded(
            child: Row(
              children: [
                // Map/Locales list (left side)
                Expanded(
                  flex: 3,
                  child: Container(
                    color: Colors.grey.shade50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Locations header
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.map,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Global',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Description text
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            'Select a locale',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        
                        // List of locales
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: _getSortedLocales(gameState.realEstateLocales).map((locale) => 
                              _buildLocaleItem(locale, gameState, theme)
                            ).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Vertical divider between panels
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.grey.shade300,
                ),
                
                // Properties in selected locale (right side)
                Expanded(
                  flex: 4,
                  child: Container(
                    color: Colors.white,
                    child: _selectedLocale != null 
                      ? _buildPropertiesList(_selectedLocale!, gameState, theme)
                      : _buildEmptyStateMessage(theme),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLocaleItem(RealEstateLocale locale, GameState gameState, ThemeData theme) {
    // If not unlocked, show locked indicator with appropriate unlock message
    if (!locale.unlocked) {
      // Determine unlock message based on locale id
      String unlockMessage = '';
      
      // Check business condition first - required for all locales
      bool hasAnyBusiness = gameState.businesses.any((business) => business.level > 0);
      if (!hasAnyBusiness) {
        unlockMessage = 'Unlock by purchasing first business';
      } else {
        // If has business, check money thresholds based on tiers
        if (locale.id == 'rural_kenya') {
          unlockMessage = 'Unlock by purchasing first business';
        } else if (['lagos_nigeria', 'rural_thailand', 'rural_mexico'].contains(locale.id)) {
          unlockMessage = 'Unlock at \$10,000';
        } else if (['cape_town_sa', 'mumbai_india', 'ho_chi_minh_city', 'bucharest_romania', 'lima_peru', 'sao_paulo_brazil'].contains(locale.id)) {
          unlockMessage = 'Unlock at \$50,000';
        } else if (['lisbon_portugal', 'berlin_germany', 'mexico_city'].contains(locale.id)) {
          unlockMessage = 'Unlock at \$250,000';
        } else if (['singapore', 'london_uk', 'miami_florida', 'new_york_city', 'los_angeles'].contains(locale.id)) {
          unlockMessage = 'Unlock at \$1,000,000';
        } else if (['hong_kong', 'dubai_uae'].contains(locale.id)) {
          unlockMessage = 'Unlock at \$5,000,000';
        } else {
          unlockMessage = 'Unlock by progressing further';
        }
      }
      
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.lock, color: Colors.grey.shade600, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Consumer<GameState>(
                builder: (context, gameState, child) {
                  String message = 'Unlock by progressing further';
                  
                  // Check business condition first - required for all locales
                  bool hasAnyBusiness = gameState.businesses.any((business) => business.level > 0);
                  if (!hasAnyBusiness) {
                    message = 'Unlock by purchasing first business';
                  } else {
                    // If has business, check money thresholds based on tiers
                    if (locale.id == 'rural_kenya') {
                      message = 'Unlock by purchasing first business';
                    } else if (['lagos_nigeria', 'rural_thailand', 'rural_mexico'].contains(locale.id)) {
                      message = 'Unlock at \$10,000';
                    } else if (['cape_town_sa', 'mumbai_india', 'ho_chi_minh_city', 'bucharest_romania', 'lima_peru', 'sao_paulo_brazil'].contains(locale.id)) {
                      message = 'Unlock at \$50,000';
                    } else if (['lisbon_portugal', 'berlin_germany', 'mexico_city'].contains(locale.id)) {
                      message = 'Unlock at \$250,000';
                    } else if (['singapore', 'london_uk', 'miami_florida', 'new_york_city', 'los_angeles'].contains(locale.id)) {
                      message = 'Unlock at \$1,000,000';
                    } else if (['hong_kong', 'dubai_uae'].contains(locale.id)) {
                      message = 'Unlock at \$5,000,000';
                    }
                  }
                  
                  return Text(
                    message,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ),
          ],
        )
      );
    }
    
    // Count owned properties
    int ownedProperties = locale.properties.where((p) => p.owned > 0).length;
    bool isSelected = _selectedLocale?.id == locale.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: isSelected ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          width: isSelected ? 2.0 : 0,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedLocale = locale;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              // Locale icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  locale.icon,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Locale name
              Expanded(
                child: Text(
                  locale.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? theme.colorScheme.primary : Colors.black87,
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Properties counter badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '$ownedProperties/${locale.properties.length}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPropertiesList(RealEstateLocale locale, GameState gameState, ThemeData theme) {
    return ListView(
      key: ValueKey<String>(locale.id),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Header with back button and locale info
        Container(
          padding: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button and locale name
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _selectedLocale = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      locale.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Locale theme description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  locale.theme,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              
              // Properties count summary
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.home,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${locale.getTotalPropertiesOwned()} owned',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.attach_money,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${NumberFormatter.formatCompact(
                              locale.getTotalIncomePerSecond() * 
                              gameState.incomeMultiplier * 
                              gameState.prestigeMultiplier
                            )}/sec',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Property list
        ...locale.properties.map((property) => _buildPropertyItem(property, gameState, theme)).toList(),
      ],
    );
  }
  
  // Sort locales based on their unlock thresholds
  List<RealEstateLocale> _getSortedLocales(List<RealEstateLocale> locales) {
    // Create a copy of the locales list so we don't modify the original
    List<RealEstateLocale> sortedLocales = List.from(locales);
    
    // Sort locales based on their unlock requirements
    sortedLocales.sort((a, b) {
      // First prioritize unlocked locales
      if (a.unlocked && !b.unlocked) return -1;
      if (!a.unlocked && b.unlocked) return 1;
      
      // If both are locked or both are unlocked, sort by unlock threshold
      int aThreshold = _getUnlockThreshold(a.id);
      int bThreshold = _getUnlockThreshold(b.id);
      
      return aThreshold.compareTo(bThreshold);
    });
    
    return sortedLocales;
  }
  
  // Helper method to determine the unlock threshold for a locale based on its ID
  int _getUnlockThreshold(String localeId) {
    if (localeId == 'rural_kenya') {
      return 1; // Tier 1: First business
    } else if (['lagos_nigeria', 'rural_thailand', 'rural_mexico'].contains(localeId)) {
      return 2; // Tier 2: $10,000
    } else if (['cape_town_sa', 'mumbai_india', 'ho_chi_minh_city', 'bucharest_romania', 'lima_peru', 'sao_paulo_brazil'].contains(localeId)) {
      return 3; // Tier 3: $50,000
    } else if (['lisbon_portugal', 'berlin_germany', 'mexico_city'].contains(localeId)) {
      return 4; // Tier 4: $250,000
    } else if (['singapore', 'london_uk', 'miami_florida', 'new_york_city', 'los_angeles'].contains(localeId)) {
      return 5; // Tier 5: $1,000,000
    } else if (['hong_kong', 'dubai_uae'].contains(localeId)) {
      return 6; // Tier 6: $5,000,000
    }
    
    return 999; // Unknown locale, place at the end
  }
  
  Widget _buildEmptyStateMessage(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.real_estate_agent,
                size: 68,
                color: theme.colorScheme.primary,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Title
            Text(
              'Your Real Estate Portfolio',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Description
            Container(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                'Invest in properties around the world to generate passive income. Select a location from the left panel to view available properties.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tips_and_updates,
                    color: Colors.amber.shade800,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Tip: Properties provide a steady income stream. Select a location to get started!',
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Action button
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.arrow_back),
              label: const Text('SELECT A LOCATION'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                backgroundColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPropertyItem(RealEstateProperty property, GameState gameState, ThemeData theme) {
    // Determine if the property is owned
    bool isOwned = property.owned > 0;
    bool canAfford = gameState.money >= property.purchasePrice;
    
    // Get the locale ID for image path
    String localeId = _selectedLocale!.id;
    
    // Get next available upgrade if property is owned
    RealEstateUpgrade? nextUpgrade = isOwned ? property.getNextAvailableUpgrade() : null;
    bool hasUpgrade = nextUpgrade != null;
    bool canAffordUpgrade = hasUpgrade && gameState.money >= nextUpgrade.cost;
    bool allUpgradesPurchased = isOwned && property.allUpgradesPurchased;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOwned ? theme.colorScheme.primary.withOpacity(0.3) : Colors.grey.shade200,
          width: isOwned ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property image at the top
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            child: Image.asset(
              'assets/images/$localeId/${property.id}.jpg',
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to a placeholder if image can't be loaded
                return Container(
                  height: 180,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Icon(
                      Icons.home_work,
                      size: 50,
                      color: Colors.grey.shade400,
                    ),
                  ),
                );
              },
            ),
          ),
          // Property details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property name and owned badge in a row that wraps if needed
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      property.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isOwned ? theme.colorScheme.primary : Colors.black87,
                      ),
                    ),
                    if (isOwned) 
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'Owned',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (isOwned && allUpgradesPurchased)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.amber.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'Max Level',
                          style: TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Income info
                Row(
                  children: [
                    Icon(
                      isOwned ? Icons.monetization_on : Icons.attach_money, 
                      size: 16, 
                      color: Colors.green.shade700
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOwned 
                        ? '${NumberFormatter.formatCompact(
                            property.getTotalIncomePerSecond() * 
                            gameState.incomeMultiplier * 
                            gameState.prestigeMultiplier
                          )}/sec'
                        : '${NumberFormatter.formatCompact(
                            property.cashFlowPerSecond * 
                            gameState.incomeMultiplier * 
                            gameState.prestigeMultiplier
                          )}/sec',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Divider(height: 1, color: Colors.grey.shade200),
          
          // Purchase section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price/Value display
                Row(
                  children: [
                    const Icon(Icons.payments, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      isOwned 
                        ? 'Value: ${NumberFormatter.formatCurrency(property.totalValue)}'
                        : 'Price: ${NumberFormatter.formatCurrency(property.purchasePrice)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Action button - full width
                SizedBox(
                  width: double.infinity,
                  child: isOwned
                    ? hasUpgrade 
                      ? _buildUpgradeButton(
                          property, 
                          nextUpgrade!, 
                          canAffordUpgrade, 
                          gameState, 
                          theme
                        )
                      : ElevatedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('FULLY UPGRADED'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade200,
                            foregroundColor: Colors.amber.shade800,
                            disabledBackgroundColor: Colors.amber.shade200,
                            disabledForegroundColor: Colors.amber.shade800,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        )
                    : ElevatedButton.icon(
                        onPressed: canAfford 
                          ? () {
                              // Try to buy the property
                              if (gameState.buyRealEstateProperty(_selectedLocale!.id, property.id)) {
                                // Play real estate purchase sound
                                final gameService = Provider.of<GameService>(context, listen: false);
                                gameService.soundManager.playRealEstatePurchaseSound();
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Purchased ${property.name}'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                // Play error sound
                                final gameService = Provider.of<GameService>(context, listen: false);
                                gameService.soundManager.playErrorSound();
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Not enough money!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            } 
                          : null,
                        icon: const Icon(Icons.shopping_cart, size: 18),
                        label: Text(canAfford ? 'BUY PROPERTY' : 'INSUFFICIENT FUNDS'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade400,
                          disabledForegroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                ),
                
                // Display upgrade information if property is owned and has upgrades
                if (isOwned && hasUpgrade) ...[
                  const SizedBox(height: 16),
                  _buildUpgradeInfo(property, nextUpgrade!, theme),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to build upgrade button
  Widget _buildUpgradeButton(
    RealEstateProperty property, 
    RealEstateUpgrade upgrade, 
    bool canAffordUpgrade, 
    GameState gameState, 
    ThemeData theme
  ) {
    return ElevatedButton.icon(
      onPressed: canAffordUpgrade 
        ? () {
            // Try to purchase the upgrade
            if (gameState.purchasePropertyUpgrade(_selectedLocale!.id, property.id, upgrade.id)) {
              // Play property upgrade sound - using the dedicated real estate upgrade sound
              final gameService = Provider.of<GameService>(context, listen: false);
              gameService.soundManager.playRealEstateUpgradeSound();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Upgraded ${property.name}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            } else {
              // Play error sound
              final gameService = Provider.of<GameService>(context, listen: false);
              gameService.soundManager.playErrorSound();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to upgrade property'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } 
        : null,
      icon: const Icon(Icons.upgrade, size: 18),
      label: Text(canAffordUpgrade ? 'UPGRADE PROPERTY' : 'INSUFFICIENT FUNDS'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade400,
        disabledForegroundColor: Colors.white70,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
  
  // Helper method to build upgrade information
  Widget _buildUpgradeInfo(RealEstateProperty property, RealEstateUpgrade upgrade, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.deepPurple.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upgrade title
          Text(
            'Upgrade: ${upgrade.description}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 8),
          
          // Upgrade cost
          Row(
            children: [
              const Icon(Icons.attach_money, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Cost: ${NumberFormatter.formatCurrency(upgrade.cost)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // Income comparison
          Row(
            children: [
              const Icon(Icons.trending_up, size: 16, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                'Current: \$${NumberFormatter.formatCompact(property.cashFlowPerSecond)}/sec',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.arrow_upward, size: 16, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                'New: \$${NumberFormatter.formatCompact(upgrade.newIncomePerSecond)}/sec',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '+${((upgrade.newIncomePerSecond / property.cashFlowPerSecond - 1) * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}