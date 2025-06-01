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
  
  // List of professional, attractive business colors
  static const List<Color> _businessColors = [
    Color(0xFF2563EB), // Professional Blue   
    Color(0xFF059669), // Professional Green
    Color(0xFF7C3AED), // Professional Purple
    Color(0xFFDC2626), // Professional Red
    Color(0xFF0891B2), // Professional Cyan
    Color(0xFFDB2777), // Professional Pink
    Color(0xFFEA580C), // Professional Orange
    Color(0xFF65A30D), // Professional Lime
    Color(0xFF4338CA), // Professional Indigo
    Color(0xFFBE185D), // Professional Rose
    Color(0xFF0369A1), // Professional Sky
    Color(0xFF7E22CE), // Professional Violet
    Color(0xFF059212), // Professional Emerald
    Color(0xFFCA8A04), // Professional Yellow
    Color(0xFF9333EA), // Professional Fuchsia
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
      // OPTIMIZED: Only call setState every 5 seconds or when upgrade completes
      // This reduces excessive UI rebuilds while still showing progress
      final remainingTime = widget.business.getRemainingUpgradeTime();
      if (remainingTime <= Duration.zero || DateTime.now().second % 5 == 0) {
        setState(() {});
      }
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
      elevation: isOwned ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: hasPlatinumFacade 
            ? BorderSide(color: const Color(0xFFE5E4E2), width: 2.0) 
            : BorderSide(
                color: isOwned 
                    ? businessBaseColor.withOpacity(0.3) 
                    : Colors.grey.shade300, 
                width: isOwned ? 2.0 : 1.0
              ),
      ),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: hasPlatinumFacade
            ? BoxDecoration(
                color: const Color(0xFFFAFAFA),
                border: Border(
                  left: BorderSide(color: const Color(0xFFE5E4E2), width: 6),
                ),
              )
            : BoxDecoration(
                color: Colors.white,
                border: Border(
                  left: BorderSide(
                    color: isOwned ? businessBaseColor : Colors.grey.shade400, 
                    width: 6
                  ),
                ),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business header section with clean design
            Container(
              decoration: BoxDecoration(
                color: hasPlatinumFacade 
                    ? const Color(0xFFF8F9FA)
                    : (isOwned 
                        ? businessBaseColor.withOpacity(0.03) 
                        : Colors.grey.shade50),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Business icon with premium styling
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: hasPlatinumFacade 
                          ? Colors.white
                          : (isOwned 
                              ? businessBaseColor.withOpacity(0.1) 
                              : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hasPlatinumFacade 
                            ? const Color(0xFFE5E4E2)
                            : (isOwned 
                                ? businessBaseColor.withOpacity(0.2) 
                                : Colors.grey.shade300), 
                        width: 2
                      ),
                      boxShadow: isOwned ? [
                        BoxShadow(
                          color: businessBaseColor.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Icon(
                      business.icon,
                      color: hasPlatinumFacade 
                          ? const Color(0xFF666666)
                          : (isOwned ? businessBaseColor : Colors.grey.shade500),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Business name and level
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          business.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: hasPlatinumFacade 
                                ? const Color(0xFF333333)
                                : (isOwned ? Colors.grey.shade800 : Colors.grey.shade600),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: hasPlatinumFacade 
                                    ? Colors.white
                                    : (isOwned 
                                        ? businessBaseColor.withOpacity(0.1) 
                                        : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: hasPlatinumFacade 
                                      ? const Color(0xFFE5E4E2)
                                      : (isOwned 
                                          ? businessBaseColor.withOpacity(0.3) 
                                          : Colors.grey.shade300),
                                  width: 1
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isOwned ? Icons.star : Icons.star_border,
                                    size: 14,
                                    color: hasPlatinumFacade 
                                        ? const Color(0xFF666666)
                                        : (isOwned ? businessBaseColor : Colors.grey.shade500),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isOwned ? 'Level ${business.level}' : 'Not Owned',
                                    style: TextStyle(
                                      color: hasPlatinumFacade 
                                          ? const Color(0xFF666666)
                                          : (isOwned ? businessBaseColor : Colors.grey.shade600),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isOwned && business.level > 0)
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300, width: 1),
                                  ),
                                  child: Text(
                                    business.getCurrentLevelDescription(),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 10,
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
            
            // Business stats section
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildBusinessStats(context),
            ),
            
            // Income progress indicator (only if business is owned and not upgrading)
            if (business.level > 0 && !isUpgrading) 
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildIncomeProgressIndicator(),
              ),
            
            // Upgrade info section (only for owned businesses)
            if (!business.isMaxLevel() && !isUpgrading && business.level > 0)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: businessBaseColor.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: businessBaseColor.withOpacity(0.15), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.upgrade, size: 16, color: businessBaseColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Next: ${business.getNextLevelDescription()}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: businessBaseColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.trending_up, size: 14, color: businessBaseColor.withOpacity(0.7)),
                        const SizedBox(width: 6),
                        Text(
                          'Income Boost: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '+${NumberFormatter.formatCurrency(incomeIncrease)}/s',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: businessBaseColor,
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
                  ? const SizedBox.shrink()
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
    final isInitialPurchase = business.level == 0;
    final businessBaseColor = _getBusinessColor(business.id);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: business.isMaxLevel() ? null : (canAfford
            ? () {
                if (gameState.buyBusiness(business.id)) {
                  try {
                    final gameService = Provider.of<GameService>(context, listen: false);
                    if (isInitialPurchase) {
                      gameService.playSound(() => gameService.soundManager.playBusinessPurchaseSound());
                    } else {
                      gameService.playBusinessSound();
                    }
                  } catch (e) {
                    // Only log sound errors occasionally to reduce spam
                    if (DateTime.now().second % 30 == 0) {
                      print("Error playing business sound: $e");
                    }
                  }
                }
              }
            : null
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: business.isMaxLevel()
              ? Colors.grey.shade400
              : (canAfford 
                  ? (isInitialPurchase ? businessBaseColor : Colors.green.shade600)
                  : Colors.grey.shade400),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          elevation: canAfford ? 2 : 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          shadowColor: canAfford 
              ? (isInitialPurchase ? businessBaseColor.withOpacity(0.3) : Colors.green.withOpacity(0.3))
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (business.isMaxLevel())
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'MAX LEVEL REACHED',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isInitialPurchase ? Icons.shopping_cart : Icons.upgrade,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isInitialPurchase
                              ? 'Purchase for ${NumberFormatter.formatCurrency(cost)}'
                              : 'Upgrade to Level ${business.level + 1}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!isInitialPurchase)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${NumberFormatter.formatCurrency(cost)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          if (canAfford && incomeIncreasePercentage > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '+${incomeIncreasePercentage.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (timerSeconds > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.schedule, size: 12, color: Colors.white.withOpacity(0.8)),
                          const SizedBox(width: 3),
                          Text(
                            'Takes ${TimeFormatter.formatDuration(Duration(seconds: timerSeconds))}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUpgradeTimerSection(BuildContext context, GameState gameState, Business business, Duration remainingTime) {
    double progress = business.getUpgradeProgress();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade300, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.construction, size: 16, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'UPGRADING TO: ${business.getNextLevelDescription()}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Completion:',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                TimeFormatter.formatDuration(remainingTime),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.orange.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade500),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.fast_forward, size: 18),
              label: const Text('Speed Up (Watch AD)', style: TextStyle(fontWeight: FontWeight.w600)),
              onPressed: () {
                print("UI: Speed Up button pressed for ${business.id}");
                gameState.speedUpUpgradeWithAd(business.id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    final Color incomeColor = isOwned ? Colors.green.shade600 : Colors.grey.shade500;
    final Color roiColor = isOwned ? businessBaseColor : Colors.grey.shade500;
    
    return Column(
      children: [
        // Income display - styled differently for owned vs unowned
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isOwned ? Colors.green.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isOwned ? Colors.green.shade200 : Colors.grey.shade300, 
              width: 1
            ),
          ),
          child: Row(
            children: [
              Icon(
                isOwned ? Icons.attach_money : Icons.monetization_on_outlined, 
                size: 18, 
                color: incomeColor
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOwned ? 'CURRENT INCOME' : 'POTENTIAL INCOME',
                      style: TextStyle(
                        fontSize: 11, 
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
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
                            child: Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 10),
        
        // ROI and Payback Period - only show for owned businesses
        if (isOwned && !isUpgrading)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: businessBaseColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: businessBaseColor.withOpacity(0.2), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_up, size: 16, color: roiColor),
                    const SizedBox(width: 6),
                    Text(
                      'Return on Investment',
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.w600,
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
        
        // Payback period for unowned businesses
        if (!isOwned)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(
                      'Payback Time',
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
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
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
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