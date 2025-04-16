import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/achievement.dart';
import '../models/game_state.dart';
import '../utils/number_formatter.dart';
import '../models/achievement_data.dart';

class AchievementsSection extends StatelessWidget {
  const AchievementsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final achievementManager = gameState.achievementManager;
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header
                Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                    const SizedBox(width: 10),
                    const Text(
                      'Achievements',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
              
                // Summary
                Row(
                  children: [
                    _buildSummaryCard(
                      context,
                      title: 'Earned',
                      value: '${achievementManager.getCompletedAchievements().length}',
                      color: Colors.green.shade600,
                      iconData: Icons.check_circle,
                    ),
                    const SizedBox(width: 12),
                    _buildSummaryCard(
                      context,
                      title: 'Pending',
                      value: '${achievementManager.achievements.length - achievementManager.getCompletedAchievements().length}',
                      color: Colors.blue.shade600,
                      iconData: Icons.pending_actions,
                    ),
                    const SizedBox(width: 12),
                    _buildSummaryCard(
                      context,
                      title: 'Progress',
                      value: '${(achievementManager.getCompletedAchievements().length / achievementManager.achievements.length * 100).toStringAsFixed(0)}%',
                      color: Colors.purple.shade600,
                      iconData: Icons.insights,
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Achievement Tabs for categories
                DefaultTabController(
                  length: AchievementCategory.values.length,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TabBar(
                          labelColor: Colors.blue.shade700,
                          unselectedLabelColor: Colors.grey.shade600,
                          indicatorColor: Colors.blue.shade700,
                          indicatorSize: TabBarIndicatorSize.label,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          tabs: [
                            for (final category in AchievementCategory.values)
                              Tab(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: Text(
                                    _getCategoryName(category),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 370, // Slightly shorter to help avoid scroll issues
                          maxWidth: 500, // Control max width to prevent excessive width
                        ),
                        child: TabBarView(
                          children: [
                            for (final category in AchievementCategory.values)
                              _buildAchievementList(context, category, achievementManager, gameState),
                          ],
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
  
  // Helper to build the summary cards
  Widget _buildSummaryCard(BuildContext context, {
    required String title,
    required String value,
    required Color color,
    required IconData iconData,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconData, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
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
  ) {
    final achievements = achievementManager.getAchievementsByCategory(category);
    
    return ListView.builder(
      itemCount: achievements.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        final progress = achievementManager.calculateProgress(achievement.id, gameState);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shadowColor: achievement.completed 
              ? Colors.green.withOpacity(0.3)
              : Colors.blue.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: achievement.completed
                  ? Colors.green.shade200
                  : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: achievement.completed
                    ? [Colors.white, Colors.green.shade50]
                    : [Colors.white, Colors.grey.shade50],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Achievement icon/badge with improved styling
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: achievement.completed
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: achievement.completed
                              ? Colors.green.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: achievement.completed
                            ? Colors.green.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      achievement.icon,
                      color: achievement.completed
                          ? Colors.green
                          : Colors.grey,
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
                                      ? Colors.green.shade800
                                      : Colors.grey.shade800,
                                ),
                              ),
                            ),
                            if (achievement.completed)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 16,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          achievement.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Display PP Reward
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.purple.shade300, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Reward: ${achievement.ppReward} PP',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.purple.shade600,
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
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(
                              achievement.completed
                                  ? Colors.green.shade600
                                  : Colors.blue.shade600,
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
                                ? Colors.green.shade600
                                : Colors.blue.shade600,
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
      },
    );
  }
}
