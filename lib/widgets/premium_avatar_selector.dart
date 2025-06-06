import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../models/premium_avatar.dart';
import '../models/game_state.dart';
import '../services/game_service.dart';

/// A widget that displays premium avatars in a grid with selection functionality
class PremiumAvatarSelector extends StatefulWidget {
  final bool isPremium;
  final String? selectedPremiumAvatarId;
  final Function(String) onAvatarSelected;

  const PremiumAvatarSelector({
    Key? key,
    required this.isPremium,
    this.selectedPremiumAvatarId,
    required this.onAvatarSelected,
  }) : super(key: key);

  @override
  State<PremiumAvatarSelector> createState() => _PremiumAvatarSelectorState();
}

class _PremiumAvatarSelectorState extends State<PremiumAvatarSelector> with SingleTickerProviderStateMixin {
  bool _isSectionExpanded = false;
  late AnimationController _controller;
  late Animation<double> _animation;
  
  // Group avatars by category
  final Map<PremiumAvatarCategory, List<PremiumAvatar>> _groupedAvatars = {};
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Create a curved animation
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    
    // Group avatars by category
    _groupAvatars();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _groupAvatars() {
    final avatars = getPremiumAvatars();
    
    for (final avatar in avatars) {
      if (!_groupedAvatars.containsKey(avatar.category)) {
        _groupedAvatars[avatar.category] = [];
      }
      _groupedAvatars[avatar.category]!.add(avatar);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return _buildAvatarContent();
  }
  
  Widget _buildAvatarContent() {
    if (!widget.isPremium) {
      return _buildPremiumLockedContent();
    }
    
    // Flatten all avatars into a single list for the grid
    final List<PremiumAvatar> allAvatars = getPremiumAvatars();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        
        // Display all premium avatars in a single grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: allAvatars.length,
          itemBuilder: (context, index) {
            final avatar = allAvatars[index];
            final isSelected = widget.selectedPremiumAvatarId == avatar.id;
            final category = avatar.category;
            
            return GestureDetector(
              onTap: () {
                widget.onAvatarSelected(avatar.id);
              },
              child: Tooltip(
                message: "${category.displayName}: ${avatar.description}",
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isSelected ? 
                      LinearGradient(
                        colors: [
                          Colors.purple.shade200,
                          Colors.purple.shade100,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ) : 
                      LinearGradient(
                        colors: [
                          Colors.grey.shade100,
                          Colors.white,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      // Use category color for the border to indicate category
                      color: isSelected ? Colors.purple.shade600 : category.color.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ] : null,
                  ),
                  child: Stack(
                    children: [
                      // Main avatar content
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Image container with fixed size
                          Container(
                            width: 64,
                            height: 64,
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade200,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Center(
                                child: Image.asset(
                                  avatar.imagePath,
                                  fit: BoxFit.contain,
                                  width: 60,
                                  height: 60,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Text(
                                        avatar.emoji,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              avatar.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.purple.shade800 : Colors.grey.shade700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      // Category indicator (small badge in top-right corner)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: category.color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        
        // Legend for category colors (small and subtle)
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PremiumAvatarCategory.values.map((category) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: category.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  category.displayName,
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            )).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPremiumLockedContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.lock,
            size: 48,
            color: Colors.purple,
          ),
          const SizedBox(height: 12),
          const Text(
            'Premium Avatars Locked',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Purchase Premium to unlock exclusive avatar customizations!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Show premium purchase dialog
              final gameState = Provider.of<GameState>(context, listen: false);
              _showPremiumPurchaseDialog(context, gameState);
            },
            icon: const Icon(Icons.star),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            label: const Text('Get Premium'),
          ),
        ],
      ),
    );
  }
  
  void _showPremiumPurchaseDialog(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Purchase Premium'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'For \$4.99, you will get lifetime access to premium features:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Remove all ads from the game'),
            const Text('• Bonus +✦1500 Platinum'),
            const Text('• Exclusive profile customizations'),
            const Text('• Premium customer support'),
            const SizedBox(height: 16),
            const Text(
              'This is a one-time purchase and will remain active even if you reset your game progress.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Enable premium
              Provider.of<GameState>(context, listen: false).enablePremium();
              Navigator.of(context).pop();
              
              // Play sound effect
              Provider.of<GameService>(context, listen: false)
                  .soundManager
                  .playAchievementMilestoneSound();
              
              // Show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  content: const Text('Premium features activated! +1500 Platinum!'),
                  duration: const Duration(seconds: 4),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.purple),
            child: const Text('Purchase \$4.99'),
          ),
        ],
      ),
    );
  }
}
