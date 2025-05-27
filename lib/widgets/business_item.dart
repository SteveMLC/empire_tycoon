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
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasPlatinumFacade 
            ? BorderSide(color: const Color(0xFFE5E4E2), width: 2.0) 
            : BorderSide.none,
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
                    Colors.white,
                    const Color(0xFFE5E4E2),
                    Colors.white,
                  ],
                ),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business header section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Business icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: hasPlatinumFacade 
                          ? const Color(0xFFE5E4E2).withOpacity(0.3)
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      business.icon,
                      color: hasPlatinumFacade
                          ? const Color(0xFF8E8E8E)
                          : Colors.blue,
                      size: 26,
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
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Level ${business.level}',
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (business.level > 0 && !business.isMaxLevel())
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    business.getCurrentLevelDescription(),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.upgrade, size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Next Upgrade: ${business.getNextLevelDescription()}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.green.shade800,
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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.construction, size: 16, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                'Upgrading to: ${business.getNextLevelDescription()}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
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
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    
    return Row(
      children: [
        // Income display
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.attach_money, size: 18, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOwned ? 'Income' : 'Expected Income', 
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
                              color: gameState.hasActiveEventForBusiness(business.id) ? Colors.red : Colors.green.shade800,
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
        ),
        
        const SizedBox(width: 8),
        
        // ROI display (only if business is owned and not upgrading)
        if (!isUpgrading && isOwned)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, size: 18, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ROI', 
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(business.getROI() * gameState.incomeMultiplier).toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
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
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 18, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payback Period', 
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          expectedDisplayedIncomePerSecond > 0
                            ? '${TimeFormatter.formatDuration(Duration(seconds: (business.getNextUpgradeCost() / expectedDisplayedIncomePerSecond).ceil()))}'
                            : 'N/A',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
          minHeight: 3,
        ),
      ),
    );
  }
}