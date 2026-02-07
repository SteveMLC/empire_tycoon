import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/real_estate_manager.dart';
import '../utils/number_formatter.dart';
import '../services/game_service.dart';
import '../utils/sounds.dart';
import 'purchase_flash_overlay.dart';
import 'dart:async';

/// Badge shown on locale list items that have a manager
class ManagerBadge extends StatelessWidget {
  final bool isRegionalManager;
  
  const ManagerBadge({
    Key? key,
    this.isRegionalManager = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isRegionalManager
            ? [const Color(0xFFE040FB), const Color(0xFF7C4DFF)] // Purple gradient for premium
            : [const Color(0xFF4FC3F7), const Color(0xFF0288D1)], // Blue gradient for locale
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: (isRegionalManager ? Colors.purple : Colors.blue).withOpacity(0.4),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRegionalManager ? Icons.business_center : Icons.manage_accounts,
            color: Colors.white,
            size: 10,
          ),
          const SizedBox(width: 3),
          Text(
            isRegionalManager ? 'REGIONAL' : 'MANAGER',
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Panel shown at the top of the properties list for managed locales
class ManagerPanel extends StatelessWidget {
  final String localeId;
  final String localeName;
  
  const ManagerPanel({
    Key? key,
    required this.localeId,
    required this.localeName,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final tier = LocaleTierConfig.getTierForLocale(localeId);
    final isRegional = gameState.hasRegionalManager(tier);
    
    // Calculate stats
    final buyAllCost = gameState.calculateBuyAllCost(localeId);
    final buyAllUpgradesCost = gameState.calculateBuyAllUpgradesCost(localeId);
    final canAffordAll = gameState.money >= buyAllCost && buyAllCost > 0;
    final canAffordUpgrades = gameState.money >= buyAllUpgradesCost && buyAllUpgradesCost > 0;
    
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isRegional
            ? [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7)]
            : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRegional ? Colors.purple.shade300 : Colors.blue.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isRegional ? Colors.purple : Colors.blue).withOpacity(0.15),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isRegional ? Colors.purple.shade100 : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isRegional ? Icons.business_center : Icons.manage_accounts,
                  color: isRegional ? Colors.purple.shade700 : Colors.blue.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRegional ? 'Regional Manager' : 'Property Manager',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isRegional ? Colors.purple.shade800 : Colors.blue.shade800,
                      ),
                    ),
                    Text(
                      'Automate your $localeName investments',
                      style: TextStyle(
                        fontSize: 12,
                        color: isRegional ? Colors.purple.shade600 : Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isRegional)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'PREMIUM',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              // Buy All Properties Button
              Expanded(
                child: _ManagerActionButton(
                  icon: Icons.add_home_work,
                  label: 'Buy All',
                  cost: buyAllCost,
                  enabled: canAffordAll,
                  onPressed: () => _buyAllProperties(context, gameState),
                ),
              ),
              const SizedBox(width: 8),
              // Buy All Upgrades Button
              Expanded(
                child: _ManagerActionButton(
                  icon: Icons.upgrade,
                  label: 'All Upgrades',
                  cost: buyAllUpgradesCost,
                  enabled: canAffordUpgrades,
                  onPressed: () => _buyAllUpgrades(context, gameState),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _buyAllProperties(BuildContext context, GameState gameState) {
    final result = gameState.buyAllInLocale(localeId);
    if (result > 0) {
      SoundManager().playMediumHaptic();
      PurchaseFlashOverlay.show(context);
      final gameService = Provider.of<GameService>(context, listen: false);
      gameService.playRealEstateSound();
      unawaited(gameService.saveGame());
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchased $result properties!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  void _buyAllUpgrades(BuildContext context, GameState gameState) {
    final result = gameState.buyAllUpgradesInLocale(localeId);
    if (result > 0) {
      SoundManager().playMediumHaptic();
      PurchaseFlashOverlay.show(context);
      final gameService = Provider.of<GameService>(context, listen: false);
      gameService.playBusinessSound();
      unawaited(gameService.saveGame());
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchased $result upgrades!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

class _ManagerActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final double cost;
  final bool enabled;
  final VoidCallback onPressed;
  
  const _ManagerActionButton({
    required this.icon,
    required this.label,
    required this.cost,
    required this.enabled,
    required this.onPressed,
  });
  
  @override
  Widget build(BuildContext context) {
    final isEmpty = cost <= 0;
    
    return ElevatedButton(
      onPressed: enabled && !isEmpty ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade500,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isEmpty ? 'Complete!' : NumberFormatter.formatCurrency(cost),
            style: TextStyle(
              fontSize: 10,
              color: isEmpty ? Colors.grey.shade400 : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Unlock manager prompt shown when locale is complete but no manager
class UnlockManagerPrompt extends StatefulWidget {
  final String localeId;
  final String localeName;
  
  const UnlockManagerPrompt({
    Key? key,
    required this.localeId,
    required this.localeName,
  }) : super(key: key);
  
  @override
  State<UnlockManagerPrompt> createState() => _UnlockManagerPromptState();
}

class _UnlockManagerPromptState extends State<UnlockManagerPrompt>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final cost = gameState.calculateLocaleManagerCost(widget.localeId);
    final canAfford = gameState.money >= cost;
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.shade50,
              Colors.amber.shade100,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.amber.shade400,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.2 * _pulseAnimation.value),
              blurRadius: 12 * _pulseAnimation.value,
              spreadRadius: 2 * _pulseAnimation.value,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    color: Colors.amber.shade800,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.localeName} Complete!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                      Text(
                        'Hire a Manager to automate rebuilding',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Managers persist through re-incorporation and can buy all properties with one tap!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: canAfford ? () => _showUnlockConfirmation(context, gameState, cost) : null,
                icon: const Icon(Icons.lock_open, size: 18),
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('HIRE MANAGER'),
                    Text(
                      NumberFormatter.formatCurrency(cost),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade600,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade400,
                  disabledForegroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showUnlockConfirmation(BuildContext context, GameState gameState, double cost) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.manage_accounts, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text('Hire Manager?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hire a property manager for ${widget.localeName}?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.payments, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('Cost: ${NumberFormatter.formatCurrency(cost)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Persists through re-incorporation'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Text('One-tap "Buy All" for properties'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Text('One-tap upgrades'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _purchaseManager(context, gameState);
            },
            icon: const Icon(Icons.check),
            label: const Text('Hire Manager'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  void _purchaseManager(BuildContext context, GameState gameState) {
    final success = gameState.purchaseLocaleManager(widget.localeId);
    
    if (success) {
      SoundManager().playMediumHaptic();
      _showCelebration(context);
      
      final gameService = Provider.of<GameService>(context, listen: false);
      unawaited(gameService.saveGame());
    }
  }
  
  void _showCelebration(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _ManagerUnlockedCelebration(localeName: widget.localeName),
    );
  }
}

class _ManagerUnlockedCelebration extends StatefulWidget {
  final String localeName;
  
  const _ManagerUnlockedCelebration({required this.localeName});
  
  @override
  State<_ManagerUnlockedCelebration> createState() => _ManagerUnlockedCelebrationState();
}

class _ManagerUnlockedCelebrationState extends State<_ManagerUnlockedCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _controller.forward();
    
    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.of(context).pop();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: Opacity(
          opacity: _fadeAnimation.value,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.blue.shade50,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade700],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.manage_accounts,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Manager Hired!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.localeName} is now managed',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Persists through re-incorporation!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Alert dialog shown before reincorporation to remind about managers
class ReincorporationManagerAlert extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  
  const ReincorporationManagerAlert({
    Key? key,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final managerCount = gameState.getTotalManagerCount();
    final managedLocales = gameState.getManagedLocaleIds();
    
    if (managerCount == 0) {
      // No managers, don't show this alert
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.manage_accounts, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 8),
              Text(
                'You have $managerCount Real Estate Manager${managerCount > 1 ? 's' : ''}!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'These will persist and help you rebuild faster:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: managedLocales.map((localeId) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatLocaleName(localeId),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.flash_on, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'One-tap rebuilding available after re-incorporation!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _formatLocaleName(String localeId) {
    return localeId
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : word)
        .join(' ');
  }
}

/// Helper to get locale display name (can be expanded)
String getLocaleDisplayName(String localeId, GameState gameState) {
  final locale = gameState.realEstateLocales.firstWhere(
    (l) => l.id == localeId,
    orElse: () => gameState.realEstateLocales.first,
  );
  return locale.name;
}
