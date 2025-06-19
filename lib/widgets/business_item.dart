import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/business.dart';
import '../models/game_state.dart';
import '../services/game_service.dart';
import '../services/admob_service.dart';
import '../utils/number_formatter.dart';
import '../utils/time_formatter.dart';
import '../utils/asset_loader.dart';

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
    
    return Card(
      elevation: isOwned ? 3 : 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: hasPlatinumFacade 
            ? BorderSide(color: const Color(0xFFE5E4E2), width: 1.5) 
            : BorderSide(
                color: isOwned 
                    ? businessBaseColor.withOpacity(0.3) 
                    : Colors.grey.shade300, 
                width: 1.0
              ),
      ),
      child: Container(
        decoration: hasPlatinumFacade
            ? BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(color: const Color(0xFFE5E4E2), width: 4),
                ),
              )
            : BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(
                    color: isOwned ? businessBaseColor : Colors.grey.shade400, 
                    width: 4
                  ),
                ),
              ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compact header with icon, name, level and description
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Business icon - smaller and more compact
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: hasPlatinumFacade 
                          ? Colors.white
                          : (isOwned 
                              ? businessBaseColor.withOpacity(0.1) 
                              : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasPlatinumFacade 
                            ? const Color(0xFFE5E4E2)
                            : (isOwned 
                                ? businessBaseColor.withOpacity(0.3) 
                                : Colors.grey.shade300), 
                        width: 1.5
                      ),
                    ),
                    child: Icon(
                      business.icon,
                      color: hasPlatinumFacade 
                          ? const Color(0xFF666666)
                          : (isOwned ? businessBaseColor : Colors.grey.shade500),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Business info - name, level, and description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and level in one line
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                business.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: hasPlatinumFacade 
                                      ? const Color(0xFF333333)
                                      : (isOwned ? Colors.grey.shade800 : Colors.grey.shade600),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Level badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: hasPlatinumFacade 
                                    ? Colors.white
                                    : (isOwned 
                                        ? businessBaseColor.withOpacity(0.1) 
                                        : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: hasPlatinumFacade 
                                      ? const Color(0xFFE5E4E2)
                                      : (isOwned 
                                          ? businessBaseColor.withOpacity(0.3) 
                                          : Colors.grey.shade300),
                                  width: 1
                                ),
                              ),
                              child: Text(
                                isOwned ? 'Level ${business.level}' : 'Level 0',
                                style: TextStyle(
                                  color: hasPlatinumFacade 
                                      ? const Color(0xFF666666)
                                      : (isOwned ? businessBaseColor : Colors.grey.shade600),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Business description - key addition from old UI
                        Text(
                          business.description,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Current status for owned businesses
                        if (isOwned && business.level > 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.info_outline, size: 12, color: Colors.blue.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  'Current: ${business.getCurrentLevelDescription()}',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Next upgrade for owned businesses
                        if (isOwned && !business.isMaxLevel() && !isUpgrading) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.trending_up, size: 12, color: Colors.green.shade600),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Next: ${business.getNextLevelDescription()}',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Compact stats row - Income and ROI side by side
              Row(
                children: [
                  // Income section
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isOwned ? Colors.green.shade50 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isOwned ? Colors.green.shade200 : Colors.grey.shade300, 
                          width: 1
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.attach_money, 
                                size: 14, 
                                color: isOwned ? Colors.green.shade600 : Colors.grey.shade500
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Income',
                                style: TextStyle(
                                  fontSize: 10, 
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isOwned 
                              ? '${NumberFormatter.formatCurrency(currentIncome)}/s'
                              : '${NumberFormatter.formatCurrency(expectedDisplayedIncome)}/s',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: gameState.hasActiveEventForBusiness(business.id) 
                                  ? Colors.red 
                                  : (isOwned ? Colors.green.shade700 : Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // ROI section - made more prominent
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isOwned 
                            ? businessBaseColor.withOpacity(0.1) 
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isOwned 
                              ? businessBaseColor.withOpacity(0.3) 
                              : Colors.grey.shade300, 
                          width: 1
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.trending_up, 
                                size: 14, 
                                color: isOwned ? businessBaseColor : Colors.grey.shade500
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ROI',
                                style: TextStyle(
                                  fontSize: 10, 
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isOwned 
                                ? '${(business.getROI() * gameState.incomeMultiplier).toStringAsFixed(2)}%'
                                : '${(business.getROI()).toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isOwned ? businessBaseColor : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // Income progress indicator (only if business is owned and not upgrading)
              if (business.level > 0 && !isUpgrading) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: business.getIncomeProgress(),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(businessBaseColor),
                    minHeight: 3,
                  ),
                ),
              ],
              
              // Upgrading status section
              if (isUpgrading) ...[
                const SizedBox(height: 12),
                _buildUpgradeTimerSection(context, gameState, business, remainingUpgradeTime),
              ],
              
              // Action button
              if (!isUpgrading) ...[
                const SizedBox(height: 12),
                _buildBuyUpgradeButton(context, gameState, business, canAfford, incomeIncreasePercentage),
              ],
            ],
          ),
        ),
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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          elevation: canAfford ? 2 : 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  Icon(Icons.star, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'MAX LEVEL',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isInitialPurchase
                              ? 'Purchase - ${NumberFormatter.formatCurrency(cost)}'
                              : 'Upgrade to Level ${business.level + 1} - ${NumberFormatter.formatCurrency(cost)}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!isInitialPurchase && incomeIncreasePercentage > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: canAfford 
                              ? Colors.white.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: !canAfford 
                              ? Border.all(color: Colors.grey.withOpacity(0.3), width: 0.5)
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!canAfford) ...[
                              Icon(
                                Icons.lock_outline,
                                size: 8,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 2),
                            ],
                            Text(
                              '+${incomeIncreasePercentage.toStringAsFixed(0)}% Income',
                              style: TextStyle(
                                fontSize: 10,
                                color: canAfford 
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
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
                              fontSize: 10,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.construction, size: 16, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Upgrading to: ${business.getNextLevelDescription()}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.orange.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                TimeFormatter.formatDuration(remainingTime),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                  fontSize: 12,
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
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.fast_forward, size: 16),
              label: Text(
                gameState.isPremium ? 'Speed Up (Premium)' : 'Speed Up (Watch AD)', 
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)
              ),
              onPressed: () {
                print("UI: Speed Up button pressed for ${business.id}");
                final adMobService = Provider.of<AdMobService>(context, listen: false);
                
                if (gameState.isPremium) {
                  // Premium users get immediate speed up
                  gameState.speedUpUpgradeWithAd(
                    business.id,
                    onAdCompleted: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Premium speed up applied! 15 minutes reduced.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    onAdFailed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Speed up failed. Please try again.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  );
                } else {
                  // Regular users need to watch an ad
                  adMobService.showBuildSkipAd(
                    onRewardEarned: (String rewardType) {
                      // Verify we received the correct reward type
                      if (rewardType == 'BuildingUpgradeBoost') {
                        // User successfully watched the ad
                        gameState.speedUpUpgradeWithAd(
                          business.id,
                          onAdCompleted: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Speed up successful! 15 minutes reduced.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          onAdFailed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Speed up failed. Please try again.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        );
                      } else {
                        print('Warning: Expected BuildingUpgradeBoost reward but received: $rewardType');
                      }
                    },
                    onAdFailure: () {
                      // Ad failed to show
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ad not available. Please try again later.'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}