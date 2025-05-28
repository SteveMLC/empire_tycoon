import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/business.dart';
import '../models/game_state.dart';
import '../services/game_service.dart';
import '../utils/number_formatter.dart';
import '../utils/time_formatter.dart';

class BusinessItem extends StatefulWidget {
  final Business business;
  
  const BusinessItem({
    Key? key,
    required this.business,
  }) : super(key: key);

  @override
  _BusinessItemState createState() => _BusinessItemState();
}

class _BusinessItemState extends State<BusinessItem> {
  Timer? _timer;
  
  // List of more balanced business colors - vibrant but not overwhelming
  static const List<Color> _businessColors = [
    Color(0xFF5D8CAE), // Muted Blue   
    Color(0xFF5BA587), // Muted Green
    Color(0xFF9178B2), // Muted Purple
    Color(0xFFD28B5A), // Muted Orange
    Color(0xFF4A8C8C), // Teal
    Color(0xFF7D6B9E), // Muted Wisteria
    Color(0xFFBF7E52), // Muted Pumpkin
    Color(0xFF5C85AD), // Muted Belize Blue
    Color(0xFF5E9E75), // Muted Green
    Color(0xFFB86A65), // Muted Red
    Color(0xFF4A9C96), // Muted Turquoise
    Color(0xFFD2A75A), // Muted Yellow
    Color(0xFF7F8C8D), // Asbestos
    Color(0xFF6A89B0), // Muted Peter River
    Color(0xFFA67D53), // Muted Brown
    // Color(0xFF2ECC71), // Emerald Green
    // Color(0xFF9B59B6), // Amethyst Purple
    // Color(0xFFE67E22), // Carrot Orange
    // Color(0xFF16A085), // Green Sea
    // Color(0xFF8E44AD), // Wisteria Purple
    // Color(0xFFD35400), // Pumpkin Orange
    // Color(0xFF2980B9), // Belize Blue
    // Color(0xFF27AE60), // Nephritis Green
    // Color(0xFFE74C3C), // Alizarin Red
    // Color(0xFF1ABC9C), // Turquoise
    // Color(0xFFF39C12), // Orange
  ];
  
  // Map to track which businesses have been assigned which colors
  static final Map<String, int> _businessColorAssignments = {};  
  // Counter to track the next color to assign
  static int _nextColorIndex = 0;
  
  // Get a consistent color based on business ID, ensuring no duplicates
  Color _getBusinessColor(String id) {
    // If this business already has an assigned color, use it
    if (_businessColorAssignments.containsKey(id)) {
      return _businessColors[_businessColorAssignments[id]!];
    }
    
    // Assign the next available color to this business
    int colorIndex = _nextColorIndex;
    _businessColorAssignments[id] = colorIndex;
    
    // Move to the next color for the next business
    _nextColorIndex = (_nextColorIndex + 1) % _businessColors.length;
    
    return _businessColors[colorIndex];
  }

  @override
  void initState() {
    super.initState();
    if (widget.business.isUpgrading) {
      _startUiUpdateTimer();
    }
  }

  @override
  void didUpdateWidget(covariant BusinessItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.business.isUpgrading != oldWidget.business.isUpgrading) {
      if (widget.business.isUpgrading) {
        _startUiUpdateTimer();
      } else {
        _stopUiUpdateTimer();
      }
    }
  }

  @override
  void dispose() {
    _stopUiUpdateTimer();
    super.dispose();
  }

  void _startUiUpdateTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !widget.business.isUpgrading) {
        timer.cancel();
        return;
      }
      setState(() {});
    });
  }

  void _stopUiUpdateTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final business = widget.business;
    final bool isUpgrading = business.isUpgrading;
    final Duration remainingUpgradeTime = business.getRemainingUpgradeTime();
    final bool isOwned = business.level > 0;
    
    // Determine if business can be afforded
    double cost = business.getNextUpgradeCost();
    bool canAfford = gameState.money >= cost && !business.isMaxLevel();
    
    // Calculate next level income increase if not at max level
    double baseIncome = business.getIncomePerSecond();
    double nextLevelIncome = !business.isMaxLevel() ? business.getNextLevelIncomePerSecond() : baseIncome;
    
    // Get expected income for unpurchased businesses
    double expectedIncome = business.getExpectedIncomeAfterPurchase();
    
    double businessEfficiencyMultiplier = gameState.isPlatinumEfficiencyActive ? 1.05 : 1.0;
    double permanentIncomeBoostMultiplier = gameState.isPermanentIncomeBoostActive ? 1.05 : 1.0;
    
    double currentIncome = baseIncome * 
                          businessEfficiencyMultiplier * 
                          gameState.incomeMultiplier * 
                          gameState.prestigeMultiplier * 
                          permanentIncomeBoostMultiplier;
    
    // Calculate expected income with all multipliers for unpurchased businesses
    double expectedDisplayedIncome = expectedIncome * 
                                  businessEfficiencyMultiplier * 
                                  gameState.incomeMultiplier * 
                                  gameState.prestigeMultiplier * 
                                  permanentIncomeBoostMultiplier;
                          
    double nextLevelDisplayedIncome = nextLevelIncome * 
                                     businessEfficiencyMultiplier * 
                                     gameState.incomeMultiplier * 
                                     gameState.prestigeMultiplier * 
                                     permanentIncomeBoostMultiplier;
                                     
    double incomeIncrease = nextLevelDisplayedIncome - currentIncome;
    double incomeIncreasePercentage = currentIncome > 0 
                                    ? (incomeIncrease / currentIncome) * 100 
                                    : 0;
    
    // Check if business has platinum facade
    final bool hasPlatinumFacade = business.hasPlatinumFacade;
    
    // Generate a unique color for each business based on its ID
    final Color businessBaseColor = _getBusinessColor(business.id);
    final Color businessLightColor = businessBaseColor.withOpacity(0.15);
    final Color businessMediumColor = businessBaseColor.withOpacity(0.3);
    final Color businessDarkColor = businessBaseColor.withOpacity(0.8);
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasPlatinumFacade 
            ? BorderSide(color: const Color(0xFFE5E4E2), width: 2.0) 
            : BorderSide(color: businessMediumColor, width: 1.5),
      ),
      color: hasPlatinumFacade ? null : Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: hasPlatinumFacade
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFF5F5F5),
                    const Color(0xFFE5E4E2),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              )
            : BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Colors.white,
                  businessLightColor.withOpacity(0.5),
                ],
                stops: const [0.8, 1.0],
              ),
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business header section with colored background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    businessBaseColor,
                    businessBaseColor.withOpacity(0.7),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: businessBaseColor.withOpacity(0.2),
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Business icon with enhanced styling
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      business.icon,
                      color: businessBaseColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Business name and level
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          business.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 14,
                                    color: businessBaseColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Level ${business.level}',
                                    style: TextStyle(
                                      color: businessBaseColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (business.level > 0 && !business.isMaxLevel())
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    business.getCurrentLevelDescription(),
                                    style: TextStyle(
                                      color: businessBaseColor.withOpacity(0.8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Business stats section with more padding
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _buildBusinessStats(context),
            ),
            
            // Income progress indicator (subtle, only if business is owned and not upgrading)
            if (business.level > 0 && !isUpgrading) 
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildIncomeProgressIndicator(),
              ),
            
            // Upgrade info section
            if (!business.isMaxLevel() && !isUpgrading && business.level > 0)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.upgrade, size: 16, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'NEXT UPGRADE: ${business.getNextLevelDescription()}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.green.shade800,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.trending_up, size: 14, color: Colors.green.shade700),
                              const SizedBox(width: 4),
                              Text(
                                'Income Increase:',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '+${NumberFormatter.formatCurrency(incomeIncrease)}/s',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '+${incomeIncreasePercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            
            // Upgrading status section
            if (isUpgrading)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _buildUpgradeTimerSection(context, gameState, business, remainingUpgradeTime),
              ),
            
            // Button section
            Padding(
              padding: const EdgeInsets.all(16),
              child: isUpgrading
                  ? const SizedBox.shrink() // No button when upgrading
                  : _buildBuyUpgradeButton(context, gameState, business, canAfford, incomeIncreasePercentage),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoBox({required IconData icon, required Color color, required String text, double marginTop = 0, Widget? trailing}) {
    return Container(
      margin: EdgeInsets.only(top: marginTop),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
  
  Widget _buildBuyUpgradeButton(BuildContext context, GameState gameState, Business business, bool canAfford, double incomeIncreasePercentage) {
    final cost = business.getNextUpgradeCost();
    final timerSeconds = business.getNextUpgradeTimerSeconds();
    final isInitialPurchase = business.level == 0;  // Store the initial state

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: business.isMaxLevel() ? null : (canAfford
            ? () {
                if (gameState.buyBusiness(business.id)) {
                  // Play different sounds for purchase vs upgrade based on the initial state
                  try {
                    final gameService = Provider.of<GameService>(context, listen: false);
                    if (isInitialPurchase) {
                      // Play purchase sound for new business
                      gameService.playSound(() => gameService.soundManager.playBusinessPurchaseSound());
                    } else {
                      // Play upgrade sound for existing business
                      gameService.playBusinessSound();
                    }
                  } catch (e) {
                    print("Error playing business sound: $e");
                  }
                }
              }
            : null
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: business.isMaxLevel()
              ? Colors.grey.shade400
              : (canAfford ? Colors.green.shade600 : Colors.grey.shade400),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          shadowColor: canAfford ? Colors.green.withOpacity(0.4) : Colors.grey.withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Main button content
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (business.isMaxLevel())
                    const Text(
                      'MAX LEVEL',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            business.level == 0
                                ? 'Buy: ${NumberFormatter.formatCurrency(cost)}'
                                : 'Upgrade to Lvl ${business.level + 1}: ${NumberFormatter.formatCurrency(cost)}',
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.visible,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (!business.isMaxLevel() && business.level > 0 && canAfford)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '+${incomeIncreasePercentage.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  if (!business.isMaxLevel() && timerSeconds > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '(Takes ${TimeFormatter.formatDuration(Duration(seconds: timerSeconds))})',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUpgradeTimerSection(BuildContext context, GameState gameState, Business business, Duration remainingTime) {
    double progress = business.getUpgradeProgress();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.construction, size: 16, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'UPGRADING TO: ${business.getNextLevelDescription()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.orange.shade800,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Completion:',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                TimeFormatter.formatDuration(remainingTime),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.orange.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade500),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.fast_forward, size: 18),
              label: const Text('Speed Up (Watch AD)'),
              onPressed: () {
                print("UI: Speed Up button pressed for ${business.id}");
                gameState.speedUpUpgradeWithAd(business.id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                shadowColor: Colors.orange.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBusinessStats(BuildContext context) {
    final gameState = Provider.of<GameState>(context, listen: false);
    final business = widget.business;
    final bool isUpgrading = business.isUpgrading;
    final bool isOwned = business.level > 0;
    
    // Get business-specific color for consistent styling
    final Color businessBaseColor = _getBusinessColor(business.id);
    
    // Calculate displayed income per second with all multipliers
    double baseIncomePerSecond = business.getIncomePerSecond();
    double expectedIncomePerSecond = business.getExpectedIncomeAfterPurchase();
    
    double businessEfficiencyMultiplier = gameState.isPlatinumEfficiencyActive ? 1.05 : 1.0;
    double permanentIncomeBoostMultiplier = gameState.isPermanentIncomeBoostActive ? 1.05 : 1.0;
    
    double displayedIncomePerSecond = baseIncomePerSecond * 
                                     businessEfficiencyMultiplier * 
                                     gameState.incomeMultiplier * 
                                     gameState.prestigeMultiplier * 
                                     permanentIncomeBoostMultiplier;
                                     
    double expectedDisplayedIncomePerSecond = expectedIncomePerSecond * 
                                           businessEfficiencyMultiplier * 
                                           gameState.incomeMultiplier * 
                                           gameState.prestigeMultiplier * 
                                           permanentIncomeBoostMultiplier;
    
    // Define colors for consistent styling
    final Color incomeColor = Colors.green.shade600;
    final Color roiColor = businessBaseColor;
    
    return Column(
      children: [
        // Income display - full width
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.attach_money, size: 18, color: incomeColor),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isOwned ? 'INCOME:' : 'EXPECTED INCOME:',
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          isOwned 
                            ? '${NumberFormatter.formatCurrency(displayedIncomePerSecond)}/s'
                            : '${NumberFormatter.formatCurrency(expectedDisplayedIncomePerSecond)}/s',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: gameState.hasActiveEventForBusiness(business.id) ? Colors.red : incomeColor,
                          ),
                        ),
                        if (gameState.hasActiveEventForBusiness(business.id))
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.warning_amber_rounded, color: Colors.red, size: 14),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // ROI and Payback Period in a row - more compact
        Row(
          children: [
            // ROI display (only if business is owned and not upgrading)
            if (!isUpgrading && isOwned)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: businessBaseColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: businessBaseColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.trending_up, size: 16, color: roiColor),
                          const SizedBox(width: 6),
                          Text('ROI:', 
                            style: TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${(business.getROI() * gameState.incomeMultiplier).toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: roiColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // For unpurchased businesses, show payback period
            if (!isOwned)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: businessBaseColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: businessBaseColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 16, color: roiColor),
                          const SizedBox(width: 6),
                          Text('PAYBACK:', 
                            style: TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        expectedDisplayedIncomePerSecond > 0
                          ? '${TimeFormatter.formatDuration(Duration(seconds: (business.getNextUpgradeCost() / expectedDisplayedIncomePerSecond).ceil()))}'
                          : 'N/A',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: roiColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildIncomeProgressIndicator() {
    final business = widget.business;
    
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: business.getIncomeProgress(),
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(_getBusinessColor(business.id)),
          minHeight: 3,
        ),
      ),
    );
  }
}