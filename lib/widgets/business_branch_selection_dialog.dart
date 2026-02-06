import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/business.dart';
import '../models/business_branch.dart';
import '../models/game_state.dart';
import '../services/game_service.dart';
import '../utils/number_formatter.dart';

/// A redesigned dialog for selecting a business specialization branch
/// Features horizontal scrolling cards with visual differentiation
class BusinessBranchSelectionDialog extends StatefulWidget {
  final Business business;
  final VoidCallback? onBranchSelected;

  const BusinessBranchSelectionDialog({
    Key? key,
    required this.business,
    this.onBranchSelected,
  }) : super(key: key);

  @override
  State<BusinessBranchSelectionDialog> createState() => _BusinessBranchSelectionDialogState();

  /// Static method to show the dialog
  static void show(BuildContext context, Business business, {VoidCallback? onBranchSelected}) {
    showDialog(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      builder: (context) => BusinessBranchSelectionDialog(
        business: business,
        onBranchSelected: onBranchSelected,
      ),
    );
  }
}

class _BusinessBranchSelectionDialogState extends State<BusinessBranchSelectionDialog> {
  int _selectedIndex = 1; // Default to middle (Burger Bar - balanced)
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.85,
      initialPage: _selectedIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branches = widget.business.getAvailableBranches();
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: screenHeight * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(context),
            
            // Horizontal scrolling branch cards
            SizedBox(
              height: 420,
              child: PageView.builder(
                controller: _pageController,
                itemCount: branches.length,
                onPageChanged: (index) {
                  setState(() => _selectedIndex = index);
                },
                itemBuilder: (context, index) {
                  return _buildBranchCard(context, branches[index], index == _selectedIndex);
                },
              ),
            ),
            
            // Page indicator dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(branches.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _selectedIndex ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _selectedIndex 
                          ? branches[index].themeColor 
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            
            // Select button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _showConfirmationDialog(context, branches[_selectedIndex]),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: branches[_selectedIndex].themeColor,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: branches[_selectedIndex].themeColor.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(branches[_selectedIndex].icon, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Choose ${branches[_selectedIndex].name}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade600,
            Colors.orange.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose Your Path',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.business.name,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Close button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.swipe,
                  color: Colors.white.withOpacity(0.9),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Swipe to explore • Tap to select',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchCard(BuildContext context, BusinessBranch branch, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: isSelected ? 8 : 16,
      ),
      child: GestureDetector(
        onTap: () => _showConfirmationDialog(context, branch),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? branch.themeColor : Colors.grey.shade200,
              width: isSelected ? 3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected 
                    ? branch.themeColor.withOpacity(0.25)
                    : Colors.black.withOpacity(0.08),
                blurRadius: isSelected ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Branch header with gradient
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      branch.themeColor.withOpacity(0.15),
                      branch.themeColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Column(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: branch.themeColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: branch.themeColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        branch.icon,
                        color: branch.themeColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Name
                    Text(
                      branch.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Type badge
                    _buildBranchTypeBadge(branch),
                  ],
                ),
              ),
              
              // Stats section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    _buildStatChip('Cost', branch.costMultiplier, isLowerBetter: true),
                    const SizedBox(width: 6),
                    _buildStatChip('Income', branch.incomeMultiplier, isLowerBetter: false),
                    const SizedBox(width: 6),
                    _buildStatChip('Speed', branch.speedMultiplier, isLowerBetter: true),
                  ],
                ),
              ),
              
              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  branch.description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const Spacer(),
              
              // Max level preview - constrained to prevent overflow
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: branch.themeColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: branch.themeColor.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events, size: 14, color: branch.themeColor),
                        const SizedBox(width: 4),
                        Text(
                          'Max Level (Lv 10)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: branch.themeColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (branch.levels.isNotEmpty)
                      Text(
                        branch.levels.last.description,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 2),
                    if (branch.levels.isNotEmpty)
                      Text(
                        '${NumberFormatter.formatCurrency(branch.levels.last.incomePerSecond)}/sec',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBranchTypeBadge(BusinessBranch branch) {
    String typeLabel;
    IconData typeIcon;
    
    switch (branch.type) {
      case BusinessBranchType.speed:
        typeLabel = 'Speed';
        typeIcon = Icons.flash_on;
        break;
      case BusinessBranchType.balanced:
        typeLabel = 'Balanced';
        typeIcon = Icons.balance;
        break;
      case BusinessBranchType.premium:
        typeLabel = 'Premium';
        typeIcon = Icons.diamond;
        break;
      case BusinessBranchType.innovation:
        typeLabel = 'Innovation';
        typeIcon = Icons.lightbulb;
        break;
      case BusinessBranchType.scaling:
        typeLabel = 'Scaling';
        typeIcon = Icons.trending_up;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: branch.themeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: branch.themeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(typeIcon, size: 14, color: branch.themeColor),
          const SizedBox(width: 4),
          Text(
            typeLabel,
            style: TextStyle(
              color: branch.themeColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, double multiplier, {required bool isLowerBetter}) {
    Color color;
    String valueText;
    IconData icon;
    
    if (multiplier == 1.0) {
      color = Colors.grey.shade500;
      valueText = 'Normal';
      icon = Icons.remove;
    } else if ((multiplier < 1.0 && isLowerBetter) || (multiplier > 1.0 && !isLowerBetter)) {
      color = Colors.green.shade600;
      valueText = multiplier < 1.0 
          ? '-${((1 - multiplier) * 100).round()}%'
          : '+${((multiplier - 1) * 100).round()}%';
      icon = multiplier < 1.0 ? Icons.arrow_downward : Icons.arrow_upward;
    } else {
      color = Colors.orange.shade600;
      valueText = multiplier < 1.0 
          ? '-${((1 - multiplier) * 100).round()}%'
          : '+${((multiplier - 1) * 100).round()}%';
      icon = multiplier < 1.0 ? Icons.arrow_downward : Icons.arrow_upward;
    }
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (multiplier != 1.0)
                  Icon(icon, size: 10, color: color),
                Text(
                  valueText,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, BusinessBranch branch) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: branch.themeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(branch.icon, color: branch.themeColor, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Confirm Selection',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Specialize your ${widget.business.name} as:',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    branch.themeColor.withOpacity(0.15),
                    branch.themeColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: branch.themeColor.withOpacity(0.3), width: 2),
              ),
              child: Row(
                children: [
                  Icon(branch.icon, color: branch.themeColor, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          branch.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          branch.characteristicsSummary,
                          style: TextStyle(
                            fontSize: 13,
                            color: branch.themeColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade700, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This choice is permanent until reincorporation.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _selectBranch(context, branch);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: branch.themeColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _selectBranch(BuildContext context, BusinessBranch branch) {
    final gameState = Provider.of<GameState>(context, listen: false);
    
    if (gameState.selectBusinessBranch(widget.business.id, branch.id)) {
      try {
        final gameService = Provider.of<GameService>(context, listen: false);
        gameService.playBusinessSound();
        unawaited(gameService.saveGame());
      } catch (e) {
        print("Error playing sound: $e");
      }
      
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(branch.icon, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${widget.business.name} is now a ${branch.name}!',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: branch.themeColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
      
      widget.onBranchSelected?.call();
    }
  }
}
