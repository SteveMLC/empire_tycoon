import 'package:flutter/material.dart';
import '../../models/game_state.dart';
import '../../themes/stats_themes.dart';

/// Utility class for theme selection dialog and related functions
class ThemeDialogUtils {
  /// Shows the theme selection dialog
  static void showThemeSelectionDialog(
    BuildContext context, 
    GameState gameState, 
    StatsTheme currentTheme
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Select Stats Theme',
            style: TextStyle(
              color: currentTheme.id == 'executive' ? const Color(0xFFE5C100) : Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choose a visual theme for your statistics screen:'),
              const SizedBox(height: 16),
              
              // Default theme option
              _buildThemeOptionCard(
                context,
                'Default',
                'Standard clean look',
                isSelected: gameState.selectedStatsTheme == null || gameState.selectedStatsTheme == 'default',
                onTap: () {
                  gameState.selectStatsTheme('default');
                  Navigator.of(dialogContext).pop();
                },
                icon: Icons.auto_awesome_mosaic,
                theme: currentTheme,
              ),
              
              const SizedBox(height: 12),
              
              // Executive theme option
              _buildThemeOptionCard(
                context,
                'Executive',
                'Premium dark theme with gold accents',
                isSelected: gameState.selectedStatsTheme == 'executive',
                onTap: () {
                  if (gameState.isExecutiveStatsThemeUnlocked) {
                    gameState.selectStatsTheme('executive');
                    Navigator.of(dialogContext).pop();
                  } else {
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   const SnackBar(
                    //     content: Text('This theme is locked. Purchase it from the Platinum Vault.'),
                    //     backgroundColor: Colors.orange,
                    //   ),
                    // );
                    Navigator.of(dialogContext).pop();
                  }
                },
                icon: Icons.star,
                isLocked: !gameState.isExecutiveStatsThemeUnlocked,
                theme: currentTheme,
              ),
            ],
          ),
          backgroundColor: currentTheme.id == 'executive' ? const Color(0xFF2D2D3A) : Colors.white,
          contentTextStyle: TextStyle(
            color: currentTheme.id == 'executive' ? Colors.white : Colors.black87
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: currentTheme.id == 'executive' ? const Color(0xFFE5C100) : Colors.blue.shade200,
              width: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                foregroundColor: currentTheme.id == 'executive' ? Colors.white70 : Colors.blue,
              ),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /// Builds a theme option card for the selection dialog
  static Widget _buildThemeOptionCard(
    BuildContext context, 
    String name, 
    String description,
    {required bool isSelected, 
    required VoidCallback onTap,
    required IconData icon,
    bool isLocked = false,
    required StatsTheme theme}
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? (theme.id == 'executive' ? const Color(0xFF3E3E4E) : Colors.blue.withOpacity(0.1))
              : (theme.id == 'executive' ? const Color(0xFF232330) : Colors.grey.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? (theme.id == 'executive' ? const Color(0xFFE5C100) : Colors.blue)
                : (theme.id == 'executive' ? const Color(0xFF3D3D4D) : Colors.grey.shade300),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? (theme.id == 'executive' ? const Color(0xFFE5C100) : Colors.blue)
                    : (theme.id == 'executive' ? const Color(0xFF3D3D4D) : Colors.grey.shade300),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected 
                    ? (theme.id == 'executive' ? Colors.black : Colors.white)
                    : (theme.id == 'executive' ? Colors.white : Colors.black54),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.id == 'executive' ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (isLocked) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.lock,
                          size: 14,
                          color: theme.id == 'executive' ? Colors.grey : Colors.grey,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.id == 'executive' ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.id == 'executive' ? const Color(0xFFE5C100) : Colors.blue,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  /// Builds a theme toggle button
  static Widget buildThemeToggle(
    BuildContext context, 
    GameState gameState, 
    StatsTheme currentTheme
  ) {
    final bool isExecutive = currentTheme.id == 'executive';
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: isExecutive 
            ? const Color(0xFF1E2430).withOpacity(0.8) 
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExecutive 
              ? const Color(0xFFE5B100).withOpacity(0.6) 
              : Colors.blue.shade300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isExecutive 
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            showThemeSelectionDialog(context, gameState, currentTheme);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isExecutive ? Icons.workspace_premium : Icons.format_paint,
                  color: isExecutive 
                      ? const Color(0xFFE5B100)
                      : Colors.blue,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  isExecutive ? 'Executive' : 'Default',
                  style: TextStyle(
                    color: isExecutive 
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_drop_down,
                  color: isExecutive 
                      ? Colors.white.withOpacity(0.7)
                      : Colors.black54,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 