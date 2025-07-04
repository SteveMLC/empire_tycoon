import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../models/real_estate.dart';
import '../widgets/money_display.dart';
import '../widgets/property_gallery_dialog.dart';
import '../utils/number_formatter.dart';
import '../services/game_service.dart';
import '../utils/asset_loader.dart';
import '../utils/sound_assets.dart';
import '../utils/sounds.dart';
import '../widgets/platinum_spire_trophy.dart';
import 'dart:async';

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
    final theme = Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: Colors.green.shade700,
      ),
    );

    // Calculate displayed total RE income
    double permanentIncomeBoostMultiplier = gameState.isPermanentIncomeBoostActive ? 1.05 : 1.0;
    double displayedTotalREIncome = gameState.getRealEstateIncomePerSecond() *
                                    gameState.incomeMultiplier *
                                    permanentIncomeBoostMultiplier;

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
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

                const SizedBox(height: 6),

                Text(
                  displayedTotalREIncome < 0
                      ? '(\$${NumberFormatter.formatCompact(displayedTotalREIncome.abs())})/sec'
                      : '\$${NumberFormatter.formatCompact(displayedTotalREIncome)}/sec',
                  style: TextStyle(
                    color: displayedTotalREIncome < 0 ? Colors.red.shade300 : Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),

                if (gameState.getTotalOwnedProperties() > 0) Column(children: [
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      List<Map<String, dynamic>> ownedProperties = gameState.getAllOwnedPropertiesWithDetails();

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

          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    color: Colors.grey.shade50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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

                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                            children: _getSortedLocales(gameState.realEstateLocales).map((locale) =>
                              _buildLocaleItem(locale, gameState, theme)
                            ).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.grey.shade300,
                ),

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
                  // Determine unlock message based purely on monetary thresholds
                  String message = 'Unlock by progressing further'; // Default message

                  // Check money thresholds based on tiers
                  // NOTE: We are removing the 'hasAnyBusiness' check as per user feedback
                  if (locale.id == 'rural_kenya') {
                     // Assuming rural_kenya is unlocked by default or another condition not monetary
                     // If it should have a monetary condition, adjust here.
                     // For now, keeping a placeholder or specific message if needed.
                     message = 'Unlock criteria TBD'; // Placeholder - adjust as needed
                  } else if (['lagos_nigeria', 'rural_thailand', 'rural_mexico'].contains(locale.id)) {
                    message = 'Unlock at ${NumberFormatter.formatCurrency(10000)}';
                  } else if (['cape_town_sa', 'mumbai_india', 'ho_chi_minh_city', 'bucharest_romania', 'lima_peru', 'sao_paulo_brazil'].contains(locale.id)) {
                    message = 'Unlock at ${NumberFormatter.formatCurrency(50000)}';
                  } else if (['lisbon_portugal', 'berlin_germany', 'mexico_city'].contains(locale.id)) {
                    message = 'Unlock at ${NumberFormatter.formatCurrency(250000)}';
                  } else if (['singapore', 'london_uk', 'miami_florida', 'new_york_city', 'los_angeles'].contains(locale.id)) {
                    message = 'Unlock at ${NumberFormatter.formatCurrency(1000000)}';
                  } else if (['hong_kong', 'dubai_uae'].contains(locale.id)) {
                    message = 'Unlock at ${NumberFormatter.formatCurrency(5000000)}';
                  }
                  // Removed the `hasAnyBusiness` check block entirely

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

              // ADDED: Platinum Yacht Indicator
              if (gameState.platinumYachtDockedLocaleId == locale.id)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0), // Add some spacing
                  child: Tooltip(
                    message: 'Platinum Yacht Docked (+5% Income)',
                    child: Icon(
                      Icons.directions_boat, // Yacht icon
                      size: 20,
                      color: Colors.blue.shade700, // Example color
                      shadows: [
                        Shadow(
                          color: Colors.blue.withOpacity(0.5),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              // END ADDED

              if (gameState.platinumFoundationsApplied.containsKey(locale.id))
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Tooltip(
                    message: 'Platinum Foundation Applied (+5% Income)',
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFD700),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.6),
                            blurRadius: 4,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '✦',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(width: 8),

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
    // Calculate displayed total RE income
    double permanentIncomeBoostMultiplier = gameState.isPermanentIncomeBoostActive ? 1.05 : 1.0;
    double displayedTotalREIncome = gameState.getRealEstateIncomePerSecond() *
                                    gameState.incomeMultiplier *
                                    permanentIncomeBoostMultiplier;

    // Check if this locale is affected by an event
    bool isLocaleAffectedByEvent = gameState.hasActiveEventForLocale(locale.id);
    
    // Calculate displayed locale income
    double baseLocaleIncome = locale.getTotalIncomePerSecond();
    
    // Apply event penalty if locale is affected
    if (isLocaleAffectedByEvent) {
      baseLocaleIncome += baseLocaleIncome * -0.25; // Apply -25% penalty
    }
    
    double displayedLocaleIncome = baseLocaleIncome *
                                     gameState.incomeMultiplier *
                                     permanentIncomeBoostMultiplier;

    return ListView(
      key: ValueKey<String>(locale.id),
      padding: const EdgeInsets.only(bottom: 80),
      children: [
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

              // Check if this locale has the Platinum Spire Trophy
              if (gameState.platinumSpireLocaleId == locale.id)
                _buildPlatinumSpireTrophyDisplay(locale, gameState),

              const SizedBox(height: 16),

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
                        color: isLocaleAffectedByEvent 
                            ? Colors.red.withOpacity(0.1) 
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isLocaleAffectedByEvent 
                              ? Colors.red.withOpacity(0.3) 
                              : Colors.green.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 14,
                            color: isLocaleAffectedByEvent ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isLocaleAffectedByEvent && displayedLocaleIncome < 0
                                ? '(\$${NumberFormatter.formatCompact(displayedLocaleIncome.abs())})/sec'
                                : '\$${NumberFormatter.formatCompact(displayedLocaleIncome)}/sec',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isLocaleAffectedByEvent ? Colors.red : Colors.green,
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

        ...locale.properties.map((property) => _buildPropertyItem(locale, property, gameState, theme)).toList(),
      ],
    );
  }

  List<RealEstateLocale> _getSortedLocales(List<RealEstateLocale> locales) {
    List<RealEstateLocale> sortedLocales = List.from(locales);

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

  int _getUnlockThreshold(String localeId) {
    if (localeId == 'rural_kenya') {
      return 1;
    } else if (['lagos_nigeria', 'rural_thailand', 'rural_mexico'].contains(localeId)) {
      return 2;
    } else if (['cape_town_sa', 'mumbai_india', 'ho_chi_minh_city', 'bucharest_romania', 'lima_peru', 'sao_paulo_brazil'].contains(localeId)) {
      return 3;
    } else if (['lisbon_portugal', 'berlin_germany', 'mexico_city'].contains(localeId)) {
      return 4;
    } else if (['singapore', 'london_uk', 'miami_florida', 'new_york_city', 'los_angeles'].contains(localeId)) {
      return 5;
    } else if (['hong_kong', 'dubai_uae'].contains(localeId)) {
      return 6;
    }

    return 999; // Unknown locale, place at the end
  }

  Widget _buildEmptyStateMessage(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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

              Text(
                'Your Real Estate Portfolio',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),

              const SizedBox(height: 16),

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
      ),
    );
  }

  Widget _buildPropertyItem(RealEstateLocale locale, RealEstateProperty property, GameState gameState, ThemeData theme) {
    bool isOwned = property.owned > 0;
    bool canAfford = gameState.money >= property.purchasePrice;

    String localeId = locale.id;

    RealEstateUpgrade? nextUpgrade = isOwned ? property.getNextAvailableUpgrade() : null;
    bool hasUpgrade = nextUpgrade != null;
    bool canAffordUpgrade = hasUpgrade && gameState.money >= nextUpgrade.cost;
    bool allUpgradesPurchased = isOwned && property.allUpgradesPurchased;

    // Check if this property's locale is affected by an event
    bool isLocaleAffectedByEvent = gameState.hasActiveEventForLocale(locale.id);
    
    // Calculate displayed property income
    double permanentIncomeBoostMultiplier = gameState.isPermanentIncomeBoostActive ? 1.05 : 1.0;
    double baseIncome = isOwned ? property.getTotalIncomePerSecond() : property.cashFlowPerSecond;
    
    // Apply event penalty if locale is affected
    if (isLocaleAffectedByEvent) {
      baseIncome += baseIncome * -0.25; // Apply -25% penalty
    }
    
    double displayedIncome = baseIncome *
                               gameState.incomeMultiplier *
                               permanentIncomeBoostMultiplier;

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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                Row(
                  children: [
                    Icon(
                      isOwned ? Icons.monetization_on : Icons.attach_money,
                      size: 16,
                      color: isLocaleAffectedByEvent ? Colors.red.shade700 : Colors.green.shade700
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isLocaleAffectedByEvent && displayedIncome < 0
                          ? '(\$${NumberFormatter.formatCompact(displayedIncome.abs())})/sec'
                          : '\$${NumberFormatter.formatCompact(displayedIncome)}/sec',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isLocaleAffectedByEvent ? Colors.red.shade700 : Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade200),

          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                SizedBox(
                  width: double.infinity,
                  child: isOwned
                    ? hasUpgrade
                      ? _buildUpgradeButton(
                          locale,
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
                              // Use the passed locale's ID here too for consistency
                              if (gameState.buyRealEstateProperty(locale.id, property.id)) {
                                final gameService = Provider.of<GameService>(context, listen: false);
                                try {
                                  // Preload sound first
                                  final assetLoader = AssetLoader();
                                  unawaited(assetLoader.preloadSound(SoundAssets.realEstatePurchase));
                                  // Use the playRealEstateSound method
                                  gameService.playRealEstateSound();
                                } catch (e) {
                                  // Only log real estate sound errors occasionally to reduce spam
                                  if (DateTime.now().second % 30 == 0) {
                                    print("Error playing real estate purchase sound: $e");
                                  }
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Purchased ${property.name}'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                final gameService = Provider.of<GameService>(context, listen: false);
                                // Use generic playSound for error
                                gameService.playSound(() => gameService.soundManager.playFeedbackErrorSound());

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

  Widget _buildUpgradeButton(
    RealEstateLocale locale,
    RealEstateProperty property,
    RealEstateUpgrade upgrade,
    bool canAffordUpgrade,
    GameState gameState,
    ThemeData theme
  ) {
    return ElevatedButton.icon(
      onPressed: canAffordUpgrade
        ? () {
            final gameState = context.read<GameState>();
            final gameService = Provider.of<GameService>(context, listen: false);

            // Attempt to purchase the upgrade - use the PASSED locale.id
            if (gameState.purchasePropertyUpgrade(locale.id, property.id, upgrade.id)) {
              try {
                // Preload sound first
                final assetLoader = AssetLoader();
                unawaited(assetLoader.preloadSound(SoundAssets.businessUpgrade));
                // Use the business sound method as it uses the same sound
                gameService.playBusinessSound();
              } catch (e) {
                // Only log real estate sound errors occasionally to reduce spam
                if (DateTime.now().second % 30 == 0) {
                  print("Error playing real estate upgrade sound: $e");
                }
                // Continue with the upgrade process even if sound fails
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Upgrade purchased: ${upgrade.description}'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              gameService.soundManager.playSound(SoundAssets.feedbackError, priority: SoundPriority.normal);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Upgrade failed. Please try again.'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.red,
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

  Widget _buildUpgradeInfo(RealEstateProperty property, RealEstateUpgrade upgrade, ThemeData theme) {
  // Get the GameState to access multipliers
  final gameState = Provider.of<GameState>(context);
  
  // Calculate all multipliers that affect income
  double permanentIncomeBoostMultiplier = gameState.isPermanentIncomeBoostActive ? 1.05 : 1.0;
  
  // We can't directly access the locale from the property, so we'll just use the multipliers
  // without the event penalty for now - the event penalty will be applied when the property is displayed
  // in the main property item widget
  
  // Calculate current income with all multipliers (same way as in _buildPropertyItem)
  double currentBaseIncome = property.cashFlowPerSecond;
  double currentDisplayedIncome = currentBaseIncome * gameState.incomeMultiplier * permanentIncomeBoostMultiplier;
  
  // Calculate new income with all multipliers
  double newBaseIncome = upgrade.newIncomePerSecond;
  double newDisplayedIncome = newBaseIncome * gameState.incomeMultiplier * permanentIncomeBoostMultiplier;
  
  // Calculate percentage increase based on the displayed values (with multipliers)
  double percentageIncrease = ((newDisplayedIncome / currentDisplayedIncome) - 1) * 100;
  
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
          Text(
            'Upgrade: ${upgrade.description}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 8),

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

          Row(
            children: [
              const Icon(Icons.trending_up, size: 16, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                'Current: \$${NumberFormatter.formatCompact(currentDisplayedIncome)}/sec',
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
                'New: \$${NumberFormatter.formatCompact(newDisplayedIncome)}/sec',
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
                  '+${percentageIncrease.toStringAsFixed(0)}%',
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

  Widget _buildPlatinumSpireTrophyDisplay(RealEstateLocale locale, GameState gameState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFE5E4E2), // Platinum color
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Platinum Spire Trophy',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PlatinumSpireTrophy(
              size: 120,
              username: gameState.username, // Pass user's name to the trophy
              showEmergenceAnimation: false, // Emergence animation only on first view
              onTap: () {
                // Show property gallery dialog when trophy is tapped
                final ownedProperties = _getOwnedProperties();
                showDialog(
                  context: context,
                  builder: (context) => PropertyGalleryDialog(
                    ownedProperties: ownedProperties,
                    showSpireTrophy: true,
                    spireTrophyLocaleId: locale.id,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to get owned properties for the PropertyGalleryDialog
  List<Map<String, dynamic>> _getOwnedProperties() {
    // Get the game state from the context
    final gameState = Provider.of<GameState>(context, listen: false);
    // Use the existing method in gameState to get all owned properties with details
    return gameState.getAllOwnedPropertiesWithDetails();
  }
}