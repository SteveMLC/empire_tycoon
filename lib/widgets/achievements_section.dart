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
                      color: theme?.titleColor ?? defaultTheme.titleColor,
                      size: 22, 
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Achievements',
                      style: theme?.cardTitleStyle ?? defaultTheme.cardTitleStyle,
                    ),
                  ],
                ),
                
                Divider(
                  height: 30,
                  thickness: 1,
                  color: theme?.id == 'executive'
                      ? const Color(0xFF2A3142)
                      : Colors.grey.withOpacity(0.2),
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
                        theme?.id == 'executive' ? const Color(0xFF4CD97B) : Colors.green,
                        theme ?? defaultTheme,
                      ),
                      const SizedBox(width: 16),
                      _buildAchievementStatCard(
                        theme?.id == 'executive' ?? false,
                        Icons.pending_actions,
                        'Pending',
                        totalPending.toString(),
                        theme?.id == 'executive' ? const Color(0xFF4B9FFF) : Colors.blue,
                        theme ?? defaultTheme,
                      ),
                      const SizedBox(width: 16),
                      _buildAchievementStatCard(
                        theme?.id == 'executive' ?? false,
                        Icons.trending_up,
                        'Progress',
                        '${progressPercent.toStringAsFixed(0)}%',
                        theme?.id == 'executive' ? const Color(0xFFFFB648) : Colors.orange,
                        theme ?? defaultTheme,
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
    StatsTheme theme,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isExecutive
              ? const Color(0xFF242C3B)
              : theme.backgroundColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExecutive
                ? const Color(0xFF2A3142)
                : Colors.transparent,
            width: 1,
          ),
          boxShadow: isExecutive ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ] : null,
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
                color: theme.textColor.withOpacity(0.8),
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
    
    return ListView.builder(
      itemCount: achievements.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        final double progress = achievementManager.calculateProgress(achievement.id, gameState);
        final completedColor = achievement.completed 
            ? const Color(0xFF4CD97B) // Rich green for completed
            : theme.titleColor;
        final incompleteColor = theme.textColor.withOpacity(0.7);
        
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          color: theme.backgroundColor.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: achievement.completed
                  ? completedColor.withOpacity(0.3)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon with improved styling
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: achievement.completed
                        ? completedColor.withOpacity(0.2)
                        : theme.backgroundColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: achievement.completed
                          ? completedColor.withOpacity(0.3)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    achievement.icon,
                    color: achievement.completed
                        ? completedColor
                        : theme.textColor.withOpacity(0.7),
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
                          Expanded(
                            child: Text(
                              achievement.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: achievement.completed
                                    ? completedColor
                                    : theme.textColor,
                              ),
                            ),
                          ),
                          if (achievement.completed)
                            Icon(
                              Icons.check_circle,
                              color: completedColor,
                              size: 16,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        achievement.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textColor.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Display PP Reward
                      Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
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
                            '${achievement.ppReward}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textColor,
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
                          backgroundColor: theme.backgroundColor.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            achievement.completed
                                ? completedColor
                                : incompleteColor,
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
                          color: achievement.completed
                              ? completedColor
                              : incompleteColor,
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

  Widget _buildTabBar(BuildContext context, AchievementManager achievementManager, GameState gameState) {
    final bool isExecutive = theme?.id == 'executive' ?? false;
    final defaultTheme = defaultStatsTheme; // Fallback theme
    
    return DefaultTabController(
      length: AchievementCategory.values.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Enhanced tab bar with better styling
          Container(
            decoration: BoxDecoration(
              color: isExecutive 
                  ? const Color(0xFF1E2430) 
                  : (theme?.backgroundColor ?? defaultTheme.backgroundColor).withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isExecutive 
                    ? const Color(0xFF2A3142) 
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: TabBar(
              labelColor: theme?.titleColor ?? defaultTheme.titleColor,
              unselectedLabelColor: (theme?.textColor ?? defaultTheme.textColor).withOpacity(0.5),
              indicatorColor: theme?.titleColor ?? defaultTheme.titleColor,
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
              tabs: [
                for (final category in AchievementCategory.values)
                  Tab(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                      child: Text(_getCategoryName(category)),
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
