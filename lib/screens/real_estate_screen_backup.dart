import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math'; // Added for Random class
import 'dart:async';
import 'dart:math'; // Added for custom painters
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

class RealEstateScreen extends StatefulWidget {
  const RealEstateScreen({Key? key}) : super(key: key);

  @override
  State<RealEstateScreen> createState() => _RealEstateScreenState();
}

class _RealEstateScreenState extends State<RealEstateScreen> with TickerProviderStateMixin {
  RealEstateLocale? _selectedLocale;
  
  // Animation controllers for the interactive landing page
  late AnimationController _globeAnimationController;
  late AnimationController _typewriterController;
  late AnimationController _statsAnimationController;
  
  final Map<String, bool> _expandedLocales = {};
  final ScrollController _scrollController = ScrollController();
  
  // List of featured locations with images and descriptions
  final List<Map<String, dynamic>> featuredLocations = [
    {
      'name': 'New York',
      'description': 'Skyscrapers with high ROI',
      'icon': Icons.location_city,
      'color': Colors.blue.shade700
    },
    {
      'name': 'Tokyo',
      'description': 'Tech hubs with steady growth',
      'icon': Icons.business,
      'color': Colors.red.shade700
    },
    {
      'name': 'London',
      'description': 'Historic properties with value',
      'icon': Icons.account_balance,
      'color': Colors.purple.shade700
    },
    {
      'name': 'Dubai',
      'description': 'Luxury properties with high returns',
      'icon': Icons.hotel,
      'color': Colors.amber.shade700
    },
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _globeAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _typewriterController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _statsAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Start animations
    _typewriterController.forward();
    _statsAnimationController.forward();
  }

  @override
  void dispose() {
    _globeAnimationController.dispose();
    _typewriterController.dispose();
    _statsAnimationController.dispose();
    super.dispose();
  }

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
    final gameState = Provider.of<GameState>(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade50,
            Colors.blue.shade50,
          ],
        ),
      ),
      child: Column(
        children: [
          // Header with info button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Real Estate Empire',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              IconButton(
                onPressed: () => _showRealEstateTutorial(context),
                icon: Icon(
                  Icons.help_outline,
                  color: theme.colorScheme.primary,
                ),
                tooltip: 'How Real Estate Works',
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Quick start guide
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.play_circle_filled,
                      color: Colors.green.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Start Guide',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '1. Start with Rural Kenya (always unlocked)\n2. Buy your first property to begin earning\n3. Unlock new locations as you grow\n4. Properties earn income 24/7, even offline!',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Current player stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Your Real Estate Portfolio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRealStat(
                      'Locations',
                      '${gameState.realEstateLocales.where((l) => l.unlocked).length}/${gameState.realEstateLocales.length}',
                      Icons.location_on,
                      Colors.blue,
                    ),
                    _buildRealStat(
                      'Properties',
                      '${_getTotalOwnedProperties(gameState)}',
                      Icons.home,
                      Colors.green,
                    ),
                    _buildRealStat(
                      'Income/sec',
                      _formatIncome(gameState.getRealEstateIncomePerSecond()),
                      Icons.attach_money,
                      Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Next steps section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Next Steps',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _getNextStepRecommendation(gameState),
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Column(
            children: [
              // Primary action - Start with Rural Kenya
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _selectRuralKenya(gameState),
                  icon: const Icon(Icons.home, size: 24),
                  label: const Text(
                    'START WITH RURAL KENYA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Secondary action - View all locations
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showLocationOverview(context, gameState),
                  icon: const Icon(Icons.map, size: 20),
                  label: const Text(
                    'VIEW ALL LOCATIONS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to get featured locales for the landing page
  List<Map<String, dynamic>> _getFeaturedLocales() {
    return [
      {
        'id': 'rural_kenya',
        'name': 'Rural Kenya',
        'theme': 'Traditional African homes',
        'icon': Icons.cabin,
        'propertyCount': 10,
      },
      {
        'id': 'new_york_city',
        'name': 'New York City',
        'theme': 'Iconic skyscrapers & penthouses',
        'icon': Icons.location_city,
        'propertyCount': 30,
      },
      {
        'id': 'dubai_uae',
        'name': 'Dubai, UAE',
        'theme': 'Luxury towers & desert villas',
        'icon': Icons.apartment,
        'propertyCount': 30,
      },
      {
        'id': 'london_uk',
        'name': 'London, UK',
        'theme': 'Historic estates & modern flats',
        'icon': Icons.account_balance,
        'propertyCount': 30,
      },
      {
        'id': 'singapore',
        'name': 'Singapore',
        'theme': 'Modern condos & garden cities',
        'icon': Icons.business,
        'propertyCount': 30,
      },
      {
        'id': 'platinum_islands',
        'name': 'Platinum Islands',
        'theme': 'Exclusive private islands',
        'icon': Icons.beach_access,
        'propertyCount': 30,
      },
    ];
  }

  // Helper method to get color for each locale
  Color _getLocaleColor(String localeId) {
    switch (localeId) {
      case 'rural_kenya':
        return Colors.brown.shade600;
      case 'new_york_city':
        return Colors.blue.shade700;
      case 'dubai_uae':
        return Colors.amber.shade700;
      case 'london_uk':
        return Colors.purple.shade700;
      case 'singapore':
        return Colors.green.shade700;
      case 'platinum_islands':
        return Colors.cyan.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  // Helper method to build stat items
  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
  List<RealEstateProperty> _getOwnedProperties() {
    final gameState = Provider.of<GameState>(context, listen: false);
    List<RealEstateProperty> ownedProperties = [];
    for (final locale in gameState.realEstateLocales) {
      ownedProperties.addAll(locale.properties.where((p) => p.owned > 0));
    }
    return ownedProperties;
  }
  
  // Helper methods for functional landing page
  Widget _buildRealStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  int _getTotalOwnedProperties(GameState gameState) {
    int total = 0;
    for (final locale in gameState.realEstateLocales) {
      for (final property in locale.properties) {
        total += property.owned;
      }
    }
    return total;
  }
  
  String _formatIncome(double income) {
    if (income == 0) return '\$0';
    if (income < 1000) return '\$${income.toStringAsFixed(2)}';
    if (income < 1000000) return '\$${(income / 1000).toStringAsFixed(1)}K';
    return '\$${(income / 1000000).toStringAsFixed(1)}M';
  }
  
  String _getNextStepRecommendation(GameState gameState) {
    final totalProperties = _getTotalOwnedProperties(gameState);
    final unlockedLocations = gameState.realEstateLocales.where((l) => l.unlocked).length;
    
    if (totalProperties == 0) {
      return 'Start your empire! Click "START WITH RURAL KENYA" below to buy your first property and begin earning passive income.';
    } else if (totalProperties < 5) {
      return 'Great start! Buy more properties in Rural Kenya to increase your income, then save up to unlock new locations.';
    } else if (unlockedLocations == 1) {
      return 'Time to expand! You have enough properties to unlock a new location. Check the locations list to see what\'s available.';
    } else if (totalProperties < 20) {
      return 'Keep growing! Diversify your portfolio across multiple locations to maximize your income potential.';
    } else {
      return 'You\'re building a real empire! Focus on high-value properties and unlock premium locations for maximum returns.';
    }
  }
  
  void _selectRuralKenya(GameState gameState) {
    // Find Rural Kenya locale
    final ruralKenya = gameState.realEstateLocales.firstWhere(
      (locale) => locale.id == 'rural_kenya',
      orElse: () => gameState.realEstateLocales.first,
    );
    
    setState(() {
      _selectedLocale = ruralKenya;
    });
  }
  
  void _showLocationOverview(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Global Locations'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: gameState.realEstateLocales.length,
            itemBuilder: (context, index) {
              final locale = gameState.realEstateLocales[index];
              return ListTile(
                leading: Icon(
                  locale.icon,
                  color: locale.unlocked ? Colors.green : Colors.grey,
                ),
                title: Text(locale.name),
                subtitle: Text(locale.theme),
                trailing: locale.unlocked 
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.lock, color: Colors.grey),
                onTap: locale.unlocked ? () {
                  Navigator.of(context).pop();
                  setState(() {
                    _selectedLocale = locale;
                  });
                } : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showRealEstateTutorial(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Real Estate Guide'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome to Real Estate!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                '🏠 How it works:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Buy properties to earn passive income\n'
                '• Properties generate money 24/7, even offline\n'
                '• Unlock new locations as you grow\n'
                '• Each location has unique property types',
              ),
              SizedBox(height: 16),
              Text(
                '🌍 20+ Global Locations:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Rural Kenya (always unlocked)\n'
                '• Lagos, Nigeria\n'
                '• Coastal Morocco\n'
                '• Cairo, Egypt\n'
                '• And many more!',
              ),
              SizedBox(height: 16),
              Text(
                '💡 Pro Tips:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Start with Rural Kenya - it\'s always available\n'
                '• Buy multiple properties to increase income\n'
                '• Save money to unlock premium locations\n'
                '• Check back regularly for new opportunities',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}