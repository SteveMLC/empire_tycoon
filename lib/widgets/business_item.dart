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
    
    // Determine if business can be afforded
    double cost = business.getNextUpgradeCost();
    bool canAfford = gameState.money >= cost && !business.isMaxLevel();
    
    // ADDED: Check if business has platinum facade
    final bool hasPlatinumFacade = business.hasPlatinumFacade;
    
    return Card(
      elevation: 3,
      // ADDED: Add platinum styling to card when facade is applied
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasPlatinumFacade 
            ? BorderSide(color: const Color(0xFFE5E4E2), width: 2.0) 
            : BorderSide.none,
      ),
      // ADDED: Apply platinum gradient background when facade is applied
      color: hasPlatinumFacade 
          ? null
          : Colors.white,
      // ADDED: Add gradient decoration for platinum facade
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // ADDED: Add platinum tint to the icon when facade is applied
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: hasPlatinumFacade 
                        ? const Color(0xFFE5E4E2).withOpacity(0.3)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    business.icon,
                    color: hasPlatinumFacade
                        ? const Color(0xFF8E8E8E)
                        : Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ADDED: Enhance text style for platinum facade
                      Text(
                        business.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          // Add platinum styling to title when facade is applied
                          color: hasPlatinumFacade ? const Color(0xFF505050) : Colors.black87,
                          // Add subtle text shadow for platinum businesses
                          shadows: hasPlatinumFacade
                              ? [
                                  Shadow(
                                    color: Colors.white.withOpacity(0.7),
                                    blurRadius: 1,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Level ${business.level}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (business.isMaxLevel())
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                // ADDED: Change max level badge color for platinum facade
                                color: hasPlatinumFacade 
                                    ? const Color(0xFFE5E4E2) 
                                    : Colors.green.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'MAX',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  // ADDED: Change text color for platinum facade
                                  color: hasPlatinumFacade
                                      ? const Color(0xFF505050)
                                      : Colors.green.shade700,
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
            
            const SizedBox(height: 16),
            
            Text(
              business.description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            
            const SizedBox(height: 10),
            
            if (business.level > 0 && !isUpgrading)
              _buildInfoBox(
                icon: Icons.info_outline,
                color: Colors.blue,
                text: 'Current: ${business.getCurrentLevelDescription()}',
              ),
            
            if (!business.isMaxLevel() && !isUpgrading)
              _buildInfoBox(
                icon: Icons.upgrade,
                color: Colors.green,
                text: business.level == 0
                    ? 'Unlock: ${business.getNextLevelDescription()}'
                    : 'Next: ${business.getNextLevelDescription()}',
                marginTop: 8,
              ),
            
            if (isUpgrading)
               _buildInfoBox(
                icon: Icons.construction,
                color: Colors.orange,
                text: 'Upgrading to: ${business.getNextLevelDescription()}',
                marginTop: 8,
              ),
            
            const SizedBox(height: 15),
            
            _buildBusinessStats(context),
            
            if (business.level > 0 && !isUpgrading) _buildIncomeProgressIndicator(),
            
            const SizedBox(height: 10),
            isUpgrading
                ? _buildUpgradeTimerSection(context, gameState, business, remainingUpgradeTime)
                : _buildBuyUpgradeButton(context, gameState, business, canAfford),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoBox({required IconData icon, required Color color, required String text, double marginTop = 0}) {
    return Container(
      margin: EdgeInsets.only(top: marginTop),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: color.withOpacity(0.1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
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
        ],
      ),
    );
  }
  
  Widget _buildBuyUpgradeButton(BuildContext context, GameState gameState, Business business, bool canAfford) {
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
                      gameService.soundManager.playBusinessPurchaseSound();
                    } else {
                      // Play upgrade sound for existing business
                      gameService.soundManager.playBusinessUpgradeSound();
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
              ? Colors.grey
              : (canAfford ? Colors.green : Colors.grey),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Column(
          children: [
            Text(
              business.isMaxLevel()
                  ? 'MAX LEVEL'
                  : business.level == 0
                      ? 'Buy: ${NumberFormatter.formatCurrency(cost)}'
                      : 'Upgrade to Lvl ${business.level + 1}: ${NumberFormatter.formatCurrency(cost)}',
              textAlign: TextAlign.center,
            ),
            if (!business.isMaxLevel() && timerSeconds > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  '(Takes ${TimeFormatter.formatDuration(Duration(seconds: timerSeconds))})',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUpgradeTimerSection(BuildContext context, GameState gameState, Business business, Duration remainingTime) {
    double progress = business.getUpgradeProgress();

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
          minHeight: 8,
        ),
        const SizedBox(height: 8),
        Text(
          'Upgrade Complete In: ${TimeFormatter.formatDuration(remainingTime)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.fast_forward),
            label: const Text('Speed Up (Watch AD)'),
            onPressed: () {
              print("UI: Speed Up button pressed for ${business.id}");
              gameState.speedUpUpgradeWithAd(business.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildBusinessStats(BuildContext context) {
    final gameState = Provider.of<GameState>(context, listen: false);
    final business = widget.business;
    
    double baseIncome = business.getIncomePerSecond();

    double businessEfficiencyMultiplier = gameState.isPlatinumEfficiencyActive ? 1.05 : 1.0;
    double permanentIncomeBoostMultiplier = gameState.isPermanentIncomeBoostActive ? 1.05 : 1.0;

    double displayedIncomePerSecond = baseIncome * 
                                      businessEfficiencyMultiplier * 
                                      gameState.incomeMultiplier * 
                                      gameState.prestigeMultiplier * 
                                      permanentIncomeBoostMultiplier;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Income:'),
            Row(
              children: [
                Text(
                  '${NumberFormatter.formatCurrency(displayedIncomePerSecond)}/s',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: gameState.hasActiveEventForBusiness(business.id) ? Colors.red : null,
                  ),
                ),
                if (gameState.hasActiveEventForBusiness(business.id))
                  const Icon(Icons.warning_amber_rounded, 
                    color: Colors.red, 
                    size: 16,
                  ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 6),
        
        if (!business.isUpgrading)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ROI:'),
              Text(
                '${(business.getROI() * gameState.incomeMultiplier).toStringAsFixed(2)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Next income in ${business.getTimeToNextIncome()} seconds',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: business.getIncomeProgress(),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ],
      ),
    );
  }
}