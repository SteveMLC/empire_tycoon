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
  bool _hasRestoredLocale = false; // Track if we've restored the locale from GameState

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final theme = Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: Colors.green.shade700,
      ),
    );

    // Restore last selected locale from GameState on first build
    if (!_hasRestoredLocale && gameState.lastSelectedRealEstateLocaleId != null) {
      final savedLocaleId = gameState.lastSelectedRealEstateLocaleId;
      final savedLocale = gameState.realEstateLocales.firstWhere(
        (locale) => locale.id == savedLocaleId && locale.unlocked,
        orElse: () => gameState.realEstateLocales.firstWhere(
          (locale) => locale.unlocked,
          orElse: () => gameState.realEstateLocales.first,
        ),
      );
      // Only restore if the locale is unlocked
      if (savedLocale.unlocked) {
        _selectedLocale = savedLocale;
      }
      _hasRestoredLocale = true;
    } else if (!_hasRestoredLocale) {
      _hasRestoredLocale = true;
    }

    // Calculate displayed total RE income
    double permanentIncomeBoostMultiplier = gameState.isPermanentIncomeBoostActive ? 1.05 : 1.0;
    double displayedTotalREIncome = gameState.getRealEstateIncomePerSecond() *
                                    gameState.incomeMultiplier *
                                    permanentIncomeBoostMultiplier;

    return Scaffold(
      body: Column(
        children: [
          // Compact Real Estate Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
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
            child: Row(
              children: [
                // Icon and title - more compact
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.home, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  'Real Estate',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Income display - inline and compact
                Expanded(
                  child: Text(
                    displayedTotalREIncome < 0
                        ? '(\$${NumberFormatter.formatCompact(displayedTotalREIncome.abs())})/sec'
                        : '\$${NumberFormatter.formatCompact(displayedTotalREIncome)}/sec',
                    style: TextStyle(
                      color: displayedTotalREIncome < 0 ? Colors.red.shade300 : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                // Portfolio button - compact on the right
                if (gameState.getTotalOwnedProperties() > 0)
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
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${gameState.getTotalOwnedProperties()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.visibility,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: Row(
              children: [
                // Reduced navigation width for more space for properties
                Expanded(
                  flex: 2, // Reduced from 3
                  child: Container(
                    color: Colors.grey.shade50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Simplified header
                        Container(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.map,
                                color: theme.colorScheme.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Locations',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
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

                // Increased properties panel width
                Expanded(
                  flex: 5, // Increased from 4
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
    // If not unlocked, show minimal locked indicator
    if (!locale.unlocked) {
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Row(
          children: [
            Icon(
              locale.icon,
              color: Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.lock,
              color: Colors.grey.shade400,
              size: 16,
            ),
            const Spacer(),
            Text(
              '0/10',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    int ownedProperties = locale.properties.where((p) => p.owned > 0).length;
    int totalProperties = locale.properties.length;
    bool isSelected = _selectedLocale?.id == locale.id;
    
    // Check completion status for visual styling
    bool isFullyPurchased = ownedProperties == totalProperties;
    bool isFullyMaxed = isFullyPurchased && locale.properties.every((p) => p.owned > 0 && p.allUpgradesPurchased);
    
    // Check if yacht is docked at this locale
    bool isYachtDocked = gameState.platinumYachtDockedLocaleId == locale.id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLocale = locale;
          // Persist the selection to GameState so it survives navigation
          gameState.lastSelectedRealEstateLocaleId = locale.id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          // Add special glow effect for yacht docking
          boxShadow: isYachtDocked ? [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ] : null,
        ),
        child: Row(
          children: [
            Icon(
              locale.icon,
              color: isSelected ? theme.colorScheme.primary : Colors.grey.shade700,
              size: 20,
            ),
            const SizedBox(width: 8),
            
            // Yacht indicator with tooltip
            if (isYachtDocked) ...[
              Tooltip(
                message: 'Platinum Yacht Docked (+5% Income)',
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.shade300, width: 1),
                  ),
                  child: Icon(
                    Icons.sailing,
                    color: Colors.blue.shade700,
                    size: 14,
                    shadows: [
                      Shadow(
                        color: Colors.blue.withOpacity(0.5),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            
            const Spacer(),
            
            // Enhanced completion status display
            if (isFullyMaxed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'MAX',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else if (isFullyPurchased)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade500,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade600, width: 1),
                ),
                child: const Text(
                  'FULL',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Text(
                '$ownedProperties/$totalProperties',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? theme.colorScheme.primary : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertiesList(RealEstateLocale locale, GameState gameState, ThemeData theme) {
    // Calculate completion status for header display
    int ownedProperties = locale.properties.where((p) => p.owned > 0).length;
    int totalProperties = locale.properties.length;
    bool isFullyPurchased = ownedProperties == totalProperties;
    bool isFullyMaxed = isFullyPurchased && locale.properties.every((p) => p.owned > 0 && p.allUpgradesPurchased);
    
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
        // Compact header for the selected locale
        Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          decoration: BoxDecoration(
            color: Colors.white,
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
              // Header with back button and locale info
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() => _selectedLocale = null),
                  ),
                  const SizedBox(width: 8),
                  Icon(locale.icon, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      locale.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Yacht indicator in header
                  if (gameState.platinumYachtDockedLocaleId == locale.id) ...[
                    Tooltip(
                      message: 'Platinum Yacht Docked\n+5% Income Boost Active',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade100, Colors.blue.shade50],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade300, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.2),
                              blurRadius: 4,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sailing,
                              color: Colors.blue.shade700,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '+5%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Completion status in header
                  if (isFullyMaxed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.4),
                            blurRadius: 6,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'MAX',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isFullyPurchased)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade500,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade600, width: 1),
                      ),
                      child: const Text(
                        'FULL',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              // Check if this locale has the Platinum Spire Trophy
              if (gameState.platinumSpireLocaleId == locale.id)
                _buildPlatinumSpireTrophyDisplay(locale, gameState),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Properties list
        ...locale.properties.map((property) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _buildPropertyItem(locale, property, gameState, theme)
        )).toList(),
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOwned ? theme.colorScheme.primary.withOpacity(0.3) : Colors.grey.shade200,
          width: isOwned ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced large image as focal point
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Stack(
              children: [
                Image.asset(
                  'assets/images/$localeId/${property.id}.jpg',
                  height: 280, // Significantly increased from 180
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 280,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Icon(
                          Icons.home_work,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    );
                  },
                ),
                // Overlay with property name and status
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                property.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 1),
                                      blurRadius: 3,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isOwned)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'OWNED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            if (allUpgradesPurchased && isOwned)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                margin: const EdgeInsets.only(left: 6),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'MAX',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.monetization_on,
                              size: 16,
                              color: isLocaleAffectedByEvent ? Colors.red.shade300 : Colors.green.shade300,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isLocaleAffectedByEvent && displayedIncome < 0
                                  ? '(\$${NumberFormatter.formatCompact(displayedIncome.abs())})/sec'
                                  : '\$${NumberFormatter.formatCompact(displayedIncome)}/sec',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isLocaleAffectedByEvent ? Colors.red.shade300 : Colors.green.shade300,
                                shadows: const [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Compact information panel
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price/Value row
                Row(
                  children: [
                    Icon(
                      Icons.payments, 
                      size: 16, 
                      color: Colors.grey.shade600
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOwned
                        ? 'Value: ${NumberFormatter.formatCurrency(property.totalValue)}'
                        : 'Price: ${NumberFormatter.formatCurrency(property.purchasePrice)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Action button
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
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('FULLY UPGRADED'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade200,
                            foregroundColor: Colors.amber.shade800,
                            disabledBackgroundColor: Colors.amber.shade200,
                            disabledForegroundColor: Colors.amber.shade800,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        )
                    : ElevatedButton.icon(
                        onPressed: canAfford
                          ? () {
                              if (gameState.buyRealEstateProperty(locale.id, property.id)) {
                                final gameService = Provider.of<GameService>(context, listen: false);
                                try {
                                  final assetLoader = AssetLoader();
                                  unawaited(assetLoader.preloadSound(SoundAssets.realEstatePurchase));
                                  gameService.playRealEstateSound();
                                } catch (e) {
                                  if (DateTime.now().second % 30 == 0) {
                                    print("Error playing real estate purchase sound: $e");
                                  }
                                }
                              } else {
                                final gameService = Provider.of<GameService>(context, listen: false);
                                gameService.playSound(() => gameService.soundManager.playFeedbackErrorSound());
                              }
                            }
                          : null,
                        icon: const Icon(Icons.shopping_cart, size: 16),
                        label: Text(canAfford ? 'BUY PROPERTY' : 'INSUFFICIENT FUNDS'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade400,
                          disabledForegroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                ),

                if (isOwned && hasUpgrade) ...[
                  const SizedBox(height: 12),
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
              // ScaffoldMessenger.of(context).showSnackBar(
              //   SnackBar(
              //     content: Text('Upgrade purchased: ${upgrade.description}'),
              //     duration: const Duration(seconds: 2),
              //     backgroundColor: Colors.green,
              //   ),
              // );
            } else {
              gameService.soundManager.playSound(SoundAssets.feedbackError, priority: SoundPriority.normal);
              // ScaffoldMessenger.of(context).showSnackBar(
              //   const SnackBar(
              //     content: Text('Upgrade failed. Please try again.'),
              //     duration: Duration(seconds: 2),
              //     backgroundColor: Colors.red,
              //   ),
              // );
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