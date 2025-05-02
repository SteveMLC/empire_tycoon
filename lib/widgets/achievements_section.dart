import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/achievement.dart';
import '../models/game_state.dart';
import '../utils/number_formatter.dart';
import '../models/achievement_data.dart';
import '../themes/stats_themes.dart';

class AchievementsSection extends StatelessWidget {
  final StatsTheme? theme;
  
  const AchievementsSection({Key? key, this.theme}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isExecutive = theme?.id == 'executive' ?? false;
    final defaultTheme = defaultStatsTheme; // Fallback theme
    
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final achievementManager = gameState.achievementManager;
        
        // Get counts for each tab
        final totalEarned = achievementManager.getCompletedAchievements().length;
        final totalPending = achievementManager.achievements.isEmpty 
            ? 0 
            : achievementManager.achievements.length - totalEarned;
        final progressPercent = achievementManager.achievements.isEmpty 
            ? 0.0 
            : (totalEarned / achievementManager.achievements.length) * 100;
        
        return Card(
          elevation: theme?.elevation ?? defaultTheme.elevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme?.borderRadius ?? defaultTheme.borderRadius),
            side: BorderSide(
              color: theme?.id == 'executive' 
                  ? const Color(0xFF2A3142)
                  : theme?.cardBorderColor ?? defaultTheme.cardBorderColor,
            ),
          ),
          color: theme?.cardBackgroundColor ?? defaultTheme.cardBackgroundColor,
          shadowColor: theme?.cardShadow?.color ?? Colors.black26,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      // Always use gold for achievements header
                      color: isExecutive ? theme?.titleColor : const Color(0xFFE5B100),
                      size: 24, 
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Achievements',
                      style: isExecutive
                          ? theme?.cardTitleStyle
                          : TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFE5B100), // Gold for achievements header
                            ),
                    ),
                  ],
                ),
                
                Divider(
                  height: 30,
                  thickness: 1,
                  color: theme?.id == 'executive'
                      ? const Color(0xFF2A3142)
                      : Colors.blue.withOpacity(0.2),
                ),
                
                // Stats cards with enhanced styling
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      _buildAchievementStatCard(
                        theme?.id == 'executive' ?? false,
                        Icons.check_circle,
                        'Earned',
                        totalEarned.toString(),
                        theme?.id == 'executive' ? const Color(0xFF4CD97B) : Colors.green.shade600,
                        theme ?? defaultTheme,
                        backgroundColor: isExecutive ? null : Colors.green.shade50,
                        borderColor: isExecutive ? null : Colors.green.shade200,
                      ),
                      const SizedBox(width: 16),
                      _buildAchievementStatCard(
                        theme?.id == 'executive' ?? false,
                        Icons.pending_actions,
                        'Pending',
                        totalPending.toString(),
                        theme?.id == 'executive' ? const Color(0xFF4B9FFF) : Colors.blue.shade600,
                        theme ?? defaultTheme,
                        backgroundColor: isExecutive ? null : Colors.blue.shade50,
                        borderColor: isExecutive ? null : Colors.blue.shade200,
                      ),
                      const SizedBox(width: 16),
                      _buildAchievementStatCard(
                        theme?.id == 'executive' ?? false,
                        Icons.trending_up,
                        'Progress',
                        '${progressPercent.toStringAsFixed(0)}%',
                        theme?.id == 'executive' ? const Color(0xFFFFB648) : Colors.amber.shade600,
                        theme ?? defaultTheme,
                        backgroundColor: isExecutive ? null : Colors.amber.shade50,
                        borderColor: isExecutive ? null : Colors.amber.shade200,
                      ),
                    ],
                  ),
                ),
                
                // Categories
                _buildTabBar(context, achievementManager, gameState),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAchievementStatCard(
    bool isExecutive,
    IconData icon,
    String label,
    String value,
    Color accentColor,
    StatsTheme theme, {
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isExecutive
              ? const Color(0xFF242C3B)
              : backgroundColor ?? theme.backgroundColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExecutive
                ? const Color(0xFF2A3142)
                : borderColor ?? Colors.transparent,
            width: 1,
          ),
          boxShadow: isExecutive ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ] : [
            BoxShadow(
              color: accentColor.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: accentColor,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isExecutive ? theme.textColor.withOpacity(0.8) : accentColor.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Convert category enum to display name
  String _getCategoryName(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.progress:
        return 'Progress';
      case AchievementCategory.wealth:
        return 'Wealth';
      case AchievementCategory.regional:
        return 'Regional';
    }
  }

  // Get color for category tab
  Color _getCategoryColor(AchievementCategory category, bool isExecutive) {
    if (isExecutive) return const Color(0xFFE5B100);
    
    switch (category) {
      case AchievementCategory.progress:
        return Colors.blue.shade700;
      case AchievementCategory.wealth:
        return Colors.green.shade700;
      case AchievementCategory.regional:
        return Colors.purple.shade700;
    }
  }
  
  // Get colors based on achievement rarity
  Map<String, dynamic> _getRarityColors(AchievementRarity rarity, bool isCompleted) {
    if (!isCompleted) {
      return {
        'backgroundColor': Colors.grey.shade50,
        'borderColor': Colors.grey.shade300,
        'iconBackgroundColor': Colors.grey.shade100,
        'iconColor': Colors.grey.shade600,
        'textColor': Colors.grey.shade800,
      };
    }
    
    switch (rarity) {
      case AchievementRarity.milestone:
        return {
          'backgroundColor': Colors.purple.shade50,
          'borderColor': Colors.amber.shade400,
          'iconBackgroundColor': Colors.amber.shade100,
          'iconColor': Colors.amber.shade800,
          'textColor': Colors.purple.shade900,
        };
      
      case AchievementRarity.rare:
        return {
          'backgroundColor': Colors.blue.shade50,
          'borderColor': Colors.blue.shade400,
          'iconBackgroundColor': Colors.blue.shade100,
          'iconColor': Colors.blue.shade700,
          'textColor': Colors.blue.shade900,
        };
      
      case AchievementRarity.basic:
      default:
        return {
          'backgroundColor': Colors.green.shade50,
          'borderColor': Colors.green.shade400,
          'iconBackgroundColor': Colors.green.shade100,
          'iconColor': Colors.green.shade700,
          'textColor': Colors.green.shade900,
        };
    }
  }
  
  // Build a list of achievements for a specific category
  Widget _buildAchievementList(
    BuildContext context,
    AchievementCategory category,
    AchievementManager achievementManager,
    GameState gameState,
    StatsTheme theme,
  ) {
    final achievements = achievementManager.getAchievementsByCategory(category);
    final defaultTheme = defaultStatsTheme; // Fallback theme
    final bool isExecutive = theme.id == 'executive';
    
    return ListView.builder(
      itemCount: achievements.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        final double progress = achievementManager.calculateProgress(achievement.id, gameState);
        
        // Get colors based on achievement rarity and completion status
        final rarityColors = _getRarityColors(achievement.rarity, achievement.completed);
        
        return Card(
          elevation: achievement.completed ? 1 : 0,
          margin: const EdgeInsets.only(bottom: 12),
          color: isExecutive 
              ? (achievement.completed 
                  ? theme.backgroundColor.withOpacity(0.2)
                  : theme.backgroundColor.withOpacity(0.1))
              : rarityColors['backgroundColor'],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isExecutive
                  ? (achievement.completed
                      ? _getExecutiveRarityColor(achievement.rarity).withOpacity(0.6)
                      : Colors.transparent)
                  : rarityColors['borderColor'],
              width: achievement.completed ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon with improved styling based on rarity
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isExecutive
                        ? (achievement.completed
                            ? _getExecutiveRarityColor(achievement.rarity).withOpacity(0.2)
                            : theme.backgroundColor.withOpacity(0.3))
                        : rarityColors['iconBackgroundColor'],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isExecutive
                          ? (achievement.completed
                              ? _getExecutiveRarityColor(achievement.rarity).withOpacity(0.5)
                              : Colors.transparent)
                          : rarityColors['borderColor'],
                      width: 1,
                    ),
                    boxShadow: achievement.completed ? [
                      BoxShadow(
                        color: isExecutive
                            ? _getExecutiveRarityColor(achievement.rarity).withOpacity(0.2)
                            : rarityColors['iconColor'].withOpacity(0.2),
                        blurRadius: 4,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Icon(
                    achievement.icon,
                    color: isExecutive
                        ? (achievement.completed
                            ? _getExecutiveRarityColor(achievement.rarity)
                            : theme.textColor.withOpacity(0.7))
                        : rarityColors['iconColor'],
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Achievement details with improved styling
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Add rarity badge for rare and milestone achievements
                          if (achievement.rarity != AchievementRarity.basic && !isExecutive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(right: 8, bottom: 4),
                              decoration: BoxDecoration(
                                color: achievement.rarity == AchievementRarity.milestone
                                    ? Colors.amber.shade400
                                    : Colors.blue.shade400,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                achievement.rarity == AchievementRarity.milestone
                                    ? 'MILESTONE'
                                    : 'RARE',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          
                          Expanded(
                            child: Text(
                              achievement.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isExecutive
                                    ? (achievement.completed
                                        ? _getExecutiveRarityColor(achievement.rarity)
                                        : theme.textColor)
                                    : rarityColors['textColor'],
                              ),
                            ),
                          ),
                          if (achievement.completed)
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isExecutive 
                                    ? _getExecutiveRarityColor(achievement.rarity).withOpacity(0.1)
                                    : rarityColors['backgroundColor'],
                              ),
                              child: Icon(
                                Icons.check_circle,
                                color: isExecutive
                                    ? _getExecutiveRarityColor(achievement.rarity)
                                    : rarityColors['iconColor'],
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        achievement.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isExecutive
                              ? theme.textColor.withOpacity(0.8)
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Display PP Reward with enhanced styling
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFFD700), // Solid gold background
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withOpacity(0.6),
                                  blurRadius: 4,
                                  spreadRadius: 0,
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white,
                                width: 1,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                '✦',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '+${achievement.ppReward} P!',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFE5B100), // Gold for PP rewards
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      
                      // Progress bar with improved styling
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: isExecutive
                              ? theme.backgroundColor.withOpacity(0.3)
                              : rarityColors['backgroundColor'].withOpacity(0.5),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isExecutive
                                ? (achievement.completed
                                    ? _getExecutiveRarityColor(achievement.rarity)
                                    : theme.textColor.withOpacity(0.7))
                                : rarityColors['iconColor'],
                          ),
                          minHeight: 8,
                        ),
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // Progress text with improved styling
                      Text(
                        achievement.completed
                            ? 'Earned'
                            : '${(progress * 100).toStringAsFixed(0)}% complete',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isExecutive
                              ? (achievement.completed
                                  ? _getExecutiveRarityColor(achievement.rarity)
                                  : theme.textColor.withOpacity(0.7))
                              : rarityColors['iconColor'],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Get executive theme colors based on rarity
  Color _getExecutiveRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.milestone:
        return const Color(0xFFE5B100);
      case AchievementRarity.rare:
        return const Color(0xFF4B9FFF);
      case AchievementRarity.basic:
      default:
        return const Color(0xFF4CD97B);
    }
  }

  // Modified _buildTabBar method to fix text wrapping issues on mobile
Widget _buildTabBar(BuildContext context, AchievementManager achievementManager, GameState gameState) {
  final bool isExecutive = theme?.id == 'executive' ?? false;
  final defaultTheme = defaultStatsTheme; // Fallback theme
  
  return DefaultTabController(
    length: AchievementCategory.values.length,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Enhanced tab bar with better styling and colors
        Container(
          decoration: BoxDecoration(
            color: isExecutive 
                ? const Color(0xFF1E2430) 
                : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isExecutive 
                  ? const Color(0xFF2A3142) 
                  : Colors.blue.shade200,
              width: 1,
            ),
            boxShadow: isExecutive ? null : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                spreadRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TabBar(
            labelColor: isExecutive 
                ? (theme?.titleColor ?? defaultTheme.titleColor)
                : Colors.blue.shade800,
            unselectedLabelColor: isExecutive
                ? ((theme?.textColor ?? defaultTheme.textColor).withOpacity(0.5))
                : Colors.blue.shade300,
            indicatorColor: isExecutive
                ? (theme?.titleColor ?? defaultTheme.titleColor)
                : Colors.blue.shade700,
            indicatorSize: TabBarIndicatorSize.label,
            padding: const EdgeInsets.symmetric(vertical: 4),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.3,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            // NEW: Make tabs use all available width
            isScrollable: false,
            // NEW: Added tab bar indicator weight
            indicatorWeight: 3,
            tabs: [
              for (final category in AchievementCategory.values)
                Tab(
                  child: Container(
                    // MODIFIED: Reduced horizontal padding to prevent text wrapping
                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: isExecutive ? null : Border.all(
                        color: Colors.transparent,
                        width: 1,
                      ),
                    ),
                    // MODIFIED: Added constraints to prevent text wrapping
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _getCategoryName(category),
                        style: TextStyle(
                          color: isExecutive 
                              ? null
                              : _getCategoryColor(category, isExecutive),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Achievement list with fixed height
        SizedBox(
          height: 370,
          child: TabBarView(
            children: [
              for (final category in AchievementCategory.values)
                _buildAchievementList(context, category, achievementManager, gameState, theme ?? defaultTheme),
            ],
          ),
        ),
      ],
    ),
  );
}
}
