import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../services/game_service.dart';
import '../utils/number_formatter.dart';
import '../utils/time_utils.dart';
import '../utils/sounds.dart';
import '../widgets/achievements_section.dart';
import '../themes/stats_themes.dart';
import '../widgets/stats/overview_card.dart';
import '../widgets/stats/earnings_breakdown_card.dart';
import '../widgets/stats/assets_breakdown_card.dart';
import '../widgets/stats/hourly_earnings_chart.dart';
import '../widgets/stats/net_worth_chart.dart';
import '../widgets/stats/theme_dialog.dart';
import '../widgets/stats/reincorporation_utils.dart';
import '../widgets/stats/stats_utils.dart';
import '../widgets/stats/events_breakdown_card.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  // Using NumberFormatter utility instead of duplicating formatting logic
  final Map<String, GlobalKey> _sectionKeys = {
    'events': GlobalKey(),
    'achievements': GlobalKey(),
  };
  
  // Method to scroll to a specific section by ID
  void _scrollToSection(String sectionId) {
    if (_sectionKeys.containsKey(sectionId)) {
      Scrollable.ensureVisible(
        _sectionKeys[sectionId]!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        // Get the appropriate theme based on user selection and unlock status
        final StatsTheme theme = getStatsTheme(
          gameState.selectedStatsTheme, 
          gameState.isExecutiveStatsThemeUnlocked
        );
        
        return Container(
          color: theme.backgroundColor,
          child: Padding(
            padding: theme.padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Overview Card
                        OverviewCard(
                          gameState: gameState,
                          theme: theme,
                          showReincorporateConfirmation: (context) => 
                              ReincorporationUtils.showReincorporateConfirmation(context, gameState),
                          showReincorporateInfo: (context) => 
                              ReincorporationUtils.showReincorporateInfo(context),
                          buildThemeToggle: ThemeDialogUtils.buildThemeToggle,
                          scrollToSection: _scrollToSection,
                        ),

                        const SizedBox(height: 20),

                        // Net Worth Chart (lifetime vs current run)
                        NetWorthChart(
                          gameState: gameState,
                          theme: theme,
                        ),

                        const SizedBox(height: 20),

                        // Hourly Earnings Chart
                        HourlyEarningsChart(
                          gameState: gameState,
                          theme: theme,
                        ),

                        const SizedBox(height: 20),

                        // Earnings Breakdown Card
                        EarningsBreakdownCard(
                          gameState: gameState,
                          theme: theme,
                        ),

                        const SizedBox(height: 20),

                        // Assets Breakdown Card
                        AssetsBreakdownCard(
                          gameState: gameState,
                          theme: theme,
                        ),

                        // Achievements Section (already a separate widget)
                        AchievementsSection(
                          key: _sectionKeys['achievements'],
                          theme: theme,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Events Breakdown Card
                        EventsBreakdownCard(
                          key: _sectionKeys['events'],
                          gameState: gameState,
                          theme: theme,
                        ),

                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeToggle(BuildContext context, GameState gameState, StatsTheme currentTheme) {
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
            _showThemeSelectionDialog(context, gameState, currentTheme);
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

  void _showThemeSelectionDialog(BuildContext context, GameState gameState, StatsTheme currentTheme) {
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

  Widget _buildThemeOptionCard(
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

  Widget _buildOverviewCard(GameState gameState, StatsTheme theme) {
    double netWorth = gameState.calculateNetWorth();
    double minNetWorthRequired = gameState.getMinimumNetWorthForReincorporation();
    final bool isExecutive = theme.id == 'executive';

    // Can reincorporate only if there are uses available AND we meet the net worth requirement
    bool canReincorporate = gameState.reincorporationUsesAvailable > 0 && netWorth >= minNetWorthRequired;

    return Card(
      elevation: theme.elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.borderRadius),
        side: BorderSide(
          color: isExecutive 
              ? const Color(0xFF2A3142)
              : theme.cardBorderColor,
        ),
      ),
      color: theme.cardBackgroundColor,
      shadowColor: theme.cardShadow?.color ?? Colors.black26,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: isExecutive ? theme.titleColor : Colors.blue.shade700,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Overview',
                      style: isExecutive 
                          ? theme.cardTitleStyle
                          : TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                    ),
                  ],
                ),
                
                // Move theme toggle button inline with Overview header
                if (gameState.isExecutiveStatsThemeUnlocked)
                  _buildThemeToggle(context, gameState, theme),
              ],
            ),

            Divider(
              height: 30,
              thickness: 1,
              color: isExecutive
                  ? const Color(0xFF2A3142)
                  : Colors.blue.withOpacity(0.2),
            ),

            // Enhanced stat rows with icons
            StatsUtils.buildStatRowWithIcon(
              'Net Worth', 
              NumberFormatter.formatCurrency(netWorth),
              Icons.account_balance_wallet,
              isExecutive ? theme.primaryChartColor : Colors.blue.shade500,
              theme
            ),

            if (gameState.incomeMultiplier > 1.0)
              Builder(builder: (context) {
                // Calculate the current prestige level using the same formula as in _showReincorporateConfirmation
                int currentPrestigeLevel = 0;
                if (gameState.networkWorth > 0) {
                  currentPrestigeLevel = (log(gameState.networkWorth * 100 + 1) / log(10)).floor();
                }
                return StatsUtils.buildStatRowWithIcon(
                  'Prestige Multiplier', 
                  '${gameState.incomeMultiplier.toStringAsFixed(2)}x (1.2 compounded ${currentPrestigeLevel}x)',
                  Icons.star,
                  isExecutive ? theme.secondaryChartColor : Colors.amber.shade600,
                  theme
                );
              }),

            // Show network worth as lifetime stat with icon
            StatsUtils.buildStatRowWithIcon(
              'Lifetime Network Worth', 
              NumberFormatter.formatCurrency(gameState.lifetimeNetworkWorth + gameState.calculateNetWorth()),
              Icons.show_chart,
              isExecutive ? theme.tertiaryChartColor : Colors.green.shade600,
              theme
            ),

            StatsUtils.buildStatRowWithIcon(
              'Total Money Earned', 
              NumberFormatter.formatCurrency(gameState.totalEarned),
              Icons.monetization_on,
              isExecutive ? theme.primaryChartColor : Colors.orange.shade600,
              theme
            ),
            
            StatsUtils.buildStatRowWithIcon(
              'Lifetime Taps', 
              gameState.lifetimeTaps.toString(),
              Icons.touch_app,
              isExecutive ? theme.secondaryChartColor : Colors.purple.shade500,
              theme
            ),
            
            StatsUtils.buildStatRowWithIcon(
              'Time Playing', 
              StatsUtils.calculateTimePlayed(gameState),
              Icons.timer,
              isExecutive ? theme.quaternaryChartColor : Colors.indigo.shade500,
              theme
            ),

            const SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isExecutive 
                    ? const Color(0xFF242C3B)
                    : Colors.blue.withOpacity(0.05),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: canReincorporate
                          ? () => _showReincorporateConfirmation(context, gameState)
                          : null,
                      icon: Icon(
                        Icons.refresh,
                        color: canReincorporate ? Colors.white : Colors.grey[400],
                        size: 18,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isExecutive 
                            ? const Color(0xFF1A56DB) // Rich blue for executive theme
                            : Colors.indigo,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: isExecutive 
                            ? const Color(0xFF1E2430) 
                            : Colors.grey[300],
                        disabledForegroundColor: isExecutive 
                            ? Colors.grey[600] 
                            : Colors.grey[600],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: isExecutive ? 2 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      label: Text(
                          gameState.reincorporationUsesAvailable > 0
                            ? 'Re-Incorporate (${gameState.reincorporationUsesAvailable} use${gameState.reincorporationUsesAvailable > 1 ? 's' : ''} available)'
                            : gameState.totalReincorporations >= 9
                              ? 'Re-Incorporate (Maxed Out)'
                              : netWorth >= minNetWorthRequired
                                ? 'Re-Incorporate (No uses available)'
                                : 'Re-Incorporate (${NumberFormatter.formatCurrency(minNetWorthRequired)} needed)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isExecutive 
                          ? const Color(0xFF1E2430) 
                          : Colors.white,
                      border: Border.all(
                        color: isExecutive
                            ? theme.cardBorderColor
                            : Colors.blue.shade100,
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.info_outline,
                        color: isExecutive ? Colors.blue.shade300 : Colors.blue,
                        size: 22,
                      ),
                      onPressed: () => _showReincorporateInfo(context),
                      tooltip: 'About Re-Incorporation',
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

  Widget _buildEarningsBreakdown(GameState gameState, StatsTheme theme) {
    final bool isExecutive = theme.id == 'executive';
    double totalEarned = gameState.manualEarnings +
                         gameState.passiveEarnings +
                         gameState.investmentEarnings +
                         gameState.investmentDividendEarnings +
                         gameState.realEstateEarnings;

    double manualPercent = totalEarned > 0 ? (gameState.manualEarnings / totalEarned) * 100 : 0;
    double passivePercent = totalEarned > 0 ? (gameState.passiveEarnings / totalEarned) * 100 : 0;
    double investmentPercent = totalEarned > 0 ? ((gameState.investmentEarnings + gameState.investmentDividendEarnings) / totalEarned) * 100 : 0;
    double realEstatePercent = totalEarned > 0 ? (gameState.realEstateEarnings / totalEarned) * 100 : 0;

    return Card(
      elevation: theme.elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.borderRadius),
        side: BorderSide(
          color: isExecutive 
              ? const Color(0xFF2A3142)
              : theme.cardBorderColor,
        ),
      ),
      color: theme.cardBackgroundColor,
      shadowColor: theme.cardShadow?.color ?? Colors.black26,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: isExecutive ? theme.titleColor : Colors.blue.shade700,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Earnings Breakdown',
                  style: isExecutive 
                      ? theme.cardTitleStyle
                      : TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                ),
              ],
            ),

            Divider(
              height: 30,
              thickness: 1,
              color: isExecutive
                  ? const Color(0xFF2A3142)
                  : Colors.blue.withOpacity(0.2),
            ),

            // Enhanced earnings breakdown with icons
            StatsUtils.buildStatRowWithIcon(
              'Hustle Earnings',
              '${NumberFormatter.formatCurrency(gameState.manualEarnings)} (${manualPercent.toStringAsFixed(1)}%)', 
              Icons.touch_app,
              isExecutive ? theme.primaryChartColor : Colors.blue.shade500,
              theme
            ),
            
            StatsUtils.buildStatRowWithIcon(
              'Business Earnings',
              '${NumberFormatter.formatCurrency(gameState.passiveEarnings)} (${passivePercent.toStringAsFixed(1)}%)', 
              Icons.business,
              isExecutive ? theme.secondaryChartColor : Colors.amber.shade600,
              theme
            ),
            
            StatsUtils.buildStatRowWithIcon(
              'Investment Earnings',
              '${NumberFormatter.formatCurrency(gameState.investmentEarnings + gameState.investmentDividendEarnings)} (${investmentPercent.toStringAsFixed(1)}%)', 
              Icons.trending_up,
              isExecutive ? theme.tertiaryChartColor : Colors.green.shade600,
              theme
            ),
            
            StatsUtils.buildStatRowWithIcon(
              'Real Estate Earnings',
              '${NumberFormatter.formatCurrency(gameState.realEstateEarnings)} (${realEstatePercent.toStringAsFixed(1)}%)', 
              Icons.home,
              isExecutive ? theme.quaternaryChartColor : Colors.red.shade600,
              theme
            ),

            const SizedBox(height: 16),

            // Enhanced bar chart visualization
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  color: isExecutive
                      ? const Color(0xFF242C3B)
                      : theme.backgroundColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    StatsUtils.buildBreakdownSegment(manualPercent / 100, theme.primaryChartColor, isExecutive),
                    StatsUtils.buildBreakdownSegment(passivePercent / 100, theme.secondaryChartColor, isExecutive),
                    StatsUtils.buildBreakdownSegment(investmentPercent / 100, theme.tertiaryChartColor, isExecutive),
                    StatsUtils.buildBreakdownSegment(realEstatePercent / 100, theme.quaternaryChartColor, isExecutive),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Legend with better styling
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                StatsUtils.buildEnhancedLegendItem(theme.primaryChartColor, 'Hustle', theme),
                StatsUtils.buildEnhancedLegendItem(theme.secondaryChartColor, 'Business', theme),
                StatsUtils.buildEnhancedLegendItem(theme.tertiaryChartColor, 'Investment', theme),
                StatsUtils.buildEnhancedLegendItem(theme.quaternaryChartColor, 'Real Estate', theme),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Using shared StatsUtils.buildBreakdownSegment method instead of duplicating code
  
  // Using shared StatsUtils.buildEnhancedLegendItem method instead of duplicating code

  Widget _buildAssetsBreakdown(GameState gameState, StatsTheme theme) {
    final bool isExecutive = theme.id == 'executive';
    double cash = gameState.money;
    double businessValue = gameState.businesses.fold(0.0, (sum, business) => sum + business.getCurrentValue());
    double investmentValue = gameState.investments.fold(0.0, (sum, investment) => sum + investment.getCurrentValue());

    // Calculate real estate value using the corrected locale method
    double realEstateValue = 0.0;
    for (var locale in gameState.realEstateLocales) {
      realEstateValue += locale.getTotalValue(); // Use corrected method
    }

    double totalAssets = cash + businessValue + investmentValue + realEstateValue;

    double cashPercent = totalAssets > 0 ? (cash / totalAssets) * 100 : 0;
    double businessPercent = totalAssets > 0 ? (businessValue / totalAssets) * 100 : 0;
    double investmentPercent = totalAssets > 0 ? (investmentValue / totalAssets) * 100 : 0;
    double realEstatePercent = totalAssets > 0 ? (realEstateValue / totalAssets) * 100 : 0;

    return Card(
      elevation: theme.elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.borderRadius),
        side: BorderSide(
          color: isExecutive 
              ? const Color(0xFF2A3142)
              : theme.cardBorderColor,
        ),
      ),
      color: theme.cardBackgroundColor,
      shadowColor: theme.cardShadow?.color ?? Colors.black26,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: isExecutive ? theme.titleColor : Colors.blue.shade700,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Assets Breakdown',
                  style: isExecutive 
                      ? theme.cardTitleStyle
                      : TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                ),
              ],
            ),

            Divider(
              height: 30,
              thickness: 1,
              color: isExecutive
                  ? const Color(0xFF2A3142)
                  : Colors.blue.withOpacity(0.2),
            ),

            // Enhanced assets breakdown with icons
            StatsUtils.buildStatRowWithIcon(
              'Cash',
              '${NumberFormatter.formatCurrency(cash)} (${cashPercent.toStringAsFixed(1)}%)', 
              Icons.attach_money,
              isExecutive ? theme.primaryChartColor : Colors.blue.shade500,
              theme
            ),
            
            StatsUtils.buildStatRowWithIcon(
              'Business Value',
              '${NumberFormatter.formatCurrency(businessValue)} (${businessPercent.toStringAsFixed(1)}%)', 
              Icons.store,
              isExecutive ? theme.secondaryChartColor : Colors.amber.shade600,
              theme
            ),
            
            StatsUtils.buildStatRowWithIcon(
              'Investment Value',
              '${NumberFormatter.formatCurrency(investmentValue)} (${investmentPercent.toStringAsFixed(1)}%)', 
              Icons.insert_chart,
              isExecutive ? theme.tertiaryChartColor : Colors.green.shade600,
              theme
            ),
            
            StatsUtils.buildStatRowWithIcon(
              'Real Estate Value',
              '${NumberFormatter.formatCurrency(realEstateValue)} (${realEstatePercent.toStringAsFixed(1)}%)', 
              Icons.apartment,
              isExecutive ? theme.quaternaryChartColor : Colors.red.shade600,
              theme
            ),

            const SizedBox(height: 16),

            // Enhanced bar chart visualization
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  color: isExecutive
                      ? const Color(0xFF242C3B)
                      : theme.backgroundColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    StatsUtils.buildBreakdownSegment(cashPercent / 100, theme.primaryChartColor, isExecutive),
                    StatsUtils.buildBreakdownSegment(businessPercent / 100, theme.secondaryChartColor, isExecutive),
                    StatsUtils.buildBreakdownSegment(investmentPercent / 100, theme.tertiaryChartColor, isExecutive),
                    StatsUtils.buildBreakdownSegment(realEstatePercent / 100, theme.quaternaryChartColor, isExecutive),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Legend with better styling
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                StatsUtils.buildEnhancedLegendItem(theme.primaryChartColor, 'Cash', theme),
                StatsUtils.buildEnhancedLegendItem(theme.secondaryChartColor, 'Business', theme),
                StatsUtils.buildEnhancedLegendItem(theme.tertiaryChartColor, 'Investment', theme),
                StatsUtils.buildEnhancedLegendItem(theme.quaternaryChartColor, 'Real Estate', theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyEarningsChart(GameState gameState, StatsTheme theme) {
    final bool isExecutive = theme.id == 'executive';
    final now = DateTime.now();
    Map<String, double> hourlyDataMap = {};

    for (int i = 23; i >= 0; i--) {
      final hour = now.subtract(Duration(hours: i));
      final hourKey = TimeUtils.getHourKey(hour);
      final earnings = gameState.hourlyEarnings[hourKey] ?? 0.0;
      hourlyDataMap[hourKey] = earnings;
    }

    // Sort keys chronologically (YYYY-MM-DD-HH)
    List<String> sortedKeys = hourlyDataMap.keys.toList()..sort();
    List<MapEntry<String, double>> hourlyData = sortedKeys
        .map((key) => MapEntry(key, hourlyDataMap[key]!))
        .toList();

    return Card(
      elevation: theme.elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.borderRadius),
        side: BorderSide(
          color: isExecutive 
              ? const Color(0xFF2A3142)
              : theme.cardBorderColor,
        ),
      ),
      color: theme.cardBackgroundColor,
      shadowColor: theme.cardShadow?.color ?? Colors.black26,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: isExecutive ? theme.titleColor : Colors.blue.shade700,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Hourly Earnings (Last 24h)',
                  style: isExecutive 
                      ? theme.cardTitleStyle
                      : TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                ),
              ],
            ),

            Divider(
              height: 30,
              thickness: 1,
              color: isExecutive
                  ? const Color(0xFF2A3142)
                  : Colors.blue.withOpacity(0.2),
            ),

            SizedBox(
              height: 200,
              child: hourlyData.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            color: theme.textColor.withOpacity(0.5),
                            size: 40,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No earnings data available yet',
                            style: TextStyle(
                              color: theme.textColor.withOpacity(0.7),
                              fontWeight: isExecutive ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Earnings will be tracked hourly as you play',
                            style: TextStyle(
                              color: theme.textColor.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildBarChart(hourlyData, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetWorthChart(GameState gameState, StatsTheme theme) {
    final bool isExecutive = theme.id == 'executive';
    Map<int, double> historyMap = gameState.persistentNetWorthHistory;

    // Sort by timestamp (key)
    List<int> sortedTimestamps = historyMap.keys.toList()..sort();
    List<double> history = sortedTimestamps.map((ts) => historyMap[ts]!).toList();

    // Removed dynamic timeframe logic
    String timeframeText = 'Net Worth History';

    return Card(
      elevation: theme.elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.borderRadius),
        side: BorderSide(
          color: isExecutive 
              ? const Color(0xFF2A3142)
              : theme.cardBorderColor,
        ),
      ),
      color: theme.cardBackgroundColor,
      shadowColor: theme.cardShadow?.color ?? Colors.black26,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.area_chart,
                      color: isExecutive ? theme.titleColor : Colors.blue.shade700,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      timeframeText,
                      style: isExecutive 
                          ? theme.cardTitleStyle
                          : TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                    ),
                  ],
                ),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isExecutive 
                        ? const Color(0xFF242C3B)
                        : theme.backgroundColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isExecutive
                          ? const Color(0xFF2A3142)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Persistent',
                    style: TextStyle(
                      color: isExecutive
                          ? const Color(0xFFE5B100)
                          : theme.primaryChartColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            Divider(
              height: 30,
              thickness: 1,
              color: isExecutive
                  ? const Color(0xFF2A3142)
                  : Colors.blue.withOpacity(0.2),
            ),

            SizedBox(
              height: 200,
              child: history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.show_chart,
                            color: theme.textColor.withOpacity(0.5),
                            size: 40,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No net worth history available yet',
                            style: TextStyle(
                              color: theme.textColor.withOpacity(0.7),
                              fontWeight: isExecutive ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your net worth will be tracked as you play',
                            style: TextStyle(
                              color: theme.textColor.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildLineChart(history, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<MapEntry<String, double>> data, StatsTheme theme) {
    final bool isExecutive = theme.id == 'executive';
    double maxValue = 0;
    for (var entry in data) {
      if (entry.value > maxValue) {
        maxValue = entry.value;
      }
    }

    maxValue = maxValue == 0 ? 1 : maxValue;

    // Add subtle grid lines for executive theme
    return Stack(
      children: [
        // Background grid for executive theme
        if (isExecutive)
          Column(
            children: List.generate(5, (i) {
              return Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: i < 4 ? BorderSide(
                        color: const Color(0xFF2A3142).withOpacity(0.5),
                        width: 0.5,
                      ) : BorderSide.none,
                    ),
                  ),
                ),
              );
            }),
          ),
        
        // Bars
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: data.map((entry) {
            double heightPercent = entry.value / maxValue;
            
            // Make very small values still visible
            if (heightPercent > 0 && heightPercent < 0.02) {
              heightPercent = 0.02;
            }
    
            String hour = entry.key.substring(entry.key.length - 2);
    
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: 160 * heightPercent,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isExecutive
                              ? [
                                  theme.primaryChartColor,
                                  theme.primaryChartColor.withOpacity(0.7),
                                ]
                              : [
                                  theme.primaryChartColor,
                                  theme.primaryChartColor.withOpacity(0.8),
                                ],
                        ),
                        borderRadius: theme.barChartBorderRadius,
                        boxShadow: isExecutive
                            ? [
                                BoxShadow(
                                  color: theme.primaryChartColor.withOpacity(0.2),
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Hour label with better styling
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: isExecutive
                          ? BoxDecoration(
                              color: const Color(0xFF1E2430),
                              borderRadius: BorderRadius.circular(4),
                            )
                          : null,
                      child: Text(
                        hour,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isExecutive ? FontWeight.bold : FontWeight.normal,
                          color: theme.textColor.withOpacity(isExecutive ? 0.9 : 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLineChart(List<double> data, StatsTheme theme) {
    if (data.length < 2) {
      return Center(child: Text('Not enough data for chart', style: TextStyle(color: theme.textColor)));
    }

    double maxValue = data.reduce((a, b) => a > b ? a : b);
    double minValue = data.reduce((a, b) => a < b ? a : b);

    double range = maxValue - minValue;
    if (range <= 0) range = maxValue > 0 ? maxValue : 1;

    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: ChartPainter(
        data: data,
        minValue: minValue,
        maxValue: maxValue,
        theme: theme,
      ),
    );
  }

  // Using shared StatsUtils.calculateTimePlayed method instead of duplicating code

  void _showReincorporateConfirmation(BuildContext context, GameState gameState) {
    double currentNetWorth = gameState.calculateNetWorth();

    // Calculate passive income bonus (20% compounding per prestige level)
    double passiveBonus = 1.0;
    int currentPrestigeLevels = 0;

    // Count how many threshold levels we've currently used based on networkWorth
    if (gameState.networkWorth > 0) {
      // $1M threshold
      if (gameState.networkWorth >= 0.01) currentPrestigeLevels++;
      // $10M threshold
      if (gameState.networkWorth >= 0.1) currentPrestigeLevels++;
      // $100M threshold
      if (gameState.networkWorth >= 1.0) currentPrestigeLevels++;
      // $1B threshold
      if (gameState.networkWorth >= 10.0) currentPrestigeLevels++;
      // $10B threshold
      if (gameState.networkWorth >= 100.0) currentPrestigeLevels++;
      // $100B threshold
      if (gameState.networkWorth >= 1000.0) currentPrestigeLevels++;
      // $1T threshold
      if (gameState.networkWorth >= 10000.0) currentPrestigeLevels++;
      // $10T threshold
      if (gameState.networkWorth >= 100000.0) currentPrestigeLevels++;
      // $100T threshold
      if (gameState.networkWorth >= 1000000.0) currentPrestigeLevels++;

      // Calculate passive bonus with 20% compounding per prestige level
      passiveBonus = pow(1.2, currentPrestigeLevels).toDouble();
    }

    // Calculate the new prestige level after this reincorporation
    double baseRequirement = 1000000.0; // $1 million
    int newThresholdLevel = 0;

    if (currentNetWorth >= baseRequirement) {
      newThresholdLevel = (log(currentNetWorth / baseRequirement) / log(10)).floor() + 1;
    }

    // Calculate the expected new network worth after this reincorporation
    double networkWorthIncrement = newThresholdLevel > 0 ? pow(10, newThresholdLevel - 1).toDouble() / 100 : 0;
    double newNetworkWorth = gameState.networkWorth + networkWorthIncrement;

    // Count how many threshold levels we'll have used after this reincorporation
    int newTotalPrestigeLevels = 0;
    if (newNetworkWorth > 0) {
      if (newNetworkWorth >= 0.01) newTotalPrestigeLevels++;  // $1M threshold
      if (newNetworkWorth >= 0.1) newTotalPrestigeLevels++;   // $10M threshold
      if (newNetworkWorth >= 1.0) newTotalPrestigeLevels++;   // $100M threshold
      if (newNetworkWorth >= 10.0) newTotalPrestigeLevels++;  // $1B threshold
      if (newNetworkWorth >= 100.0) newTotalPrestigeLevels++; // $10B threshold
      if (newNetworkWorth >= 1000.0) newTotalPrestigeLevels++; // $100B threshold
      if (newNetworkWorth >= 10000.0) newTotalPrestigeLevels++; // $1T threshold
      if (newNetworkWorth >= 100000.0) newTotalPrestigeLevels++; // $10T threshold
      if (newNetworkWorth >= 1000000.0) newTotalPrestigeLevels++; // $100T threshold
    }

    // Calculate new passive bonus with 20% compounding per prestige level
    double newPassiveBonus = pow(1.2, newTotalPrestigeLevels).toDouble();

    // We already calculated these values above, so we can use them for the click multiplier calculation
    double newNetworkValue = newNetworkWorth; // Reuse value from passive calculation

    // Count total prestige levels that will be used, which determines the multiplier
    int totalPrestigeLevels = 0;
    if (newNetworkValue > 0) {
      if (newNetworkValue >= 0.01) totalPrestigeLevels++;  // $1M threshold
      if (newNetworkValue >= 0.1) totalPrestigeLevels++;   // $10M threshold
      if (newNetworkValue >= 1.0) totalPrestigeLevels++;   // $100M threshold
      if (newNetworkValue >= 10.0) totalPrestigeLevels++;  // $1B threshold
      if (newNetworkValue >= 100.0) totalPrestigeLevels++; // $10B threshold
      if (newNetworkValue >= 1000.0) totalPrestigeLevels++; // $100B threshold
      if (newNetworkValue >= 10000.0) totalPrestigeLevels++; // $1T threshold
      if (newNetworkValue >= 100000.0) totalPrestigeLevels++; // $10T threshold
      if (newNetworkValue >= 1000000.0) totalPrestigeLevels++; // $100T threshold
    }

    // Calculate the new click multiplier (1.0 + 0.1 per level)
    double newClickMultiplier = 1.0 + (0.1 * totalPrestigeLevels);
    if (totalPrestigeLevels > 0 && newClickMultiplier < 1.2) {
      newClickMultiplier = 1.2; // First level should be 1.2x instead of 1.1x
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Re-Incorporate Business?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Re-incorporating will reset most of your progress but grants permanent multipliers to income and clicks.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Available Re-Incorporation uses: ${gameState.reincorporationUsesAvailable}'),
            Text('Your net worth: ${NumberFormatter.formatCurrency(currentNetWorth)}'),
            const SizedBox(height: 8),
            Text('Current click multiplier: ${gameState.prestigeMultiplier.toStringAsFixed(2)}x'),
            Text('Current passive bonus: ${passiveBonus.toStringAsFixed(2)}x'),
            const SizedBox(height: 8),
            Text('New click multiplier: ${newClickMultiplier.toStringAsFixed(2)}x'),
            Text('New passive bonus: ${newPassiveBonus.toStringAsFixed(2)}x (+${(newPassiveBonus - passiveBonus).toStringAsFixed(2)}x)',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              bool success = gameState.reincorporate();
              Navigator.of(context).pop();

              if (success) {
                // ScaffoldMessenger.of(context).showSnackBar(
                //   SnackBar(
                //     content: Text('Successfully re-incorporated! New passive bonus: ${gameState.incomeMultiplier.toStringAsFixed(2)}x'),
                //     backgroundColor: Colors.green,
                //   ),
                // );

                Provider.of<GameService>(context, listen: false).playSound(() => Provider.of<GameService>(context, listen: false).soundManager.playEventReincorporationSound());
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Re-Incorporate'),
          ),
        ],
      ),
    );
  }

  void _showReincorporateInfo(BuildContext context) {
    final gameState = Provider.of<GameState>(context, listen: false);
    double nextThreshold = gameState.getMinimumNetWorthForReincorporation();

    String formattedThreshold = NumberFormatter.formatCurrency(nextThreshold);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Re-Incorporation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Re-Incorporation is a prestige system that allows you to:'),
            const SizedBox(height: 8),
            const Text('• Reset your progress for permanent bonuses'),
            const Text('• Earn tap multipliers based on your net worth'),
            const Text('• Gain 20% compounding bonus to passive income'),
            const Text('• Start over with boosted earnings'),
            const SizedBox(height: 16),
            const Text('How it works:'),
            Text('1. Re-Incorporation uses unlock at \$1M, \$10M, \$100M, \$1B up to \$100T (9 total)'),
            Text('2. You have ${gameState.reincorporationUsesAvailable} use(s) available now'),
            Text('3. Next unlock at $formattedThreshold net worth'),
            const Text('4. Each use provides permanent 20% passive income bonus'),
            const Text('5. Tap value increases with each prestige level'),
            const SizedBox(height: 16),
            const Text('Your prestige level and multipliers are kept forever, even if you reset your game!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

// Chart painter for line charts
class ChartPainter extends CustomPainter {
  final List<double> data;
  final double minValue;
  final double maxValue;
  final StatsTheme theme;

  ChartPainter({
    required this.data,
    required this.minValue,
    required this.maxValue,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bool isExecutiveTheme = theme.id == 'executive';
    
    final paint = Paint()
      ..color = theme.primaryChartColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Create gradient paint for the path with enhanced colors
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        colors: theme.chartGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Create enhanced fill paint for area under the curve
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          theme.primaryChartColor.withOpacity(isExecutiveTheme ? 0.3 : 0.2),
          theme.primaryChartColor.withOpacity(isExecutiveTheme ? 0.03 : 0.05),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Add subtle grid lines for executive theme
    if (isExecutiveTheme) {
      final gridPaint = Paint()
        ..color = const Color(0xFF2A3142).withOpacity(0.5)
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke;
        
      // Draw horizontal grid lines
      for (int i = 1; i < 5; i++) {
        final y = (size.height - 20) * i / 5;
        canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          gridPaint,
        );
      }
      
      // Draw vertical grid lines
      for (int i = 1; i < data.length; i += 2) {
        final x = size.width * i / (data.length - 1);
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height - 20),
          gridPaint,
        );
      }
    }

    final textStyle = TextStyle(
      color: theme.textColor.withOpacity(0.7),
      fontSize: 10,
    );
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final path = Path();
    final width = size.width;
    final height = size.height - 20; // Reserve space for labels at bottom

    final double xStep = width / (data.length - 1);

    final range = (maxValue - minValue) == 0 ? 1 : maxValue - minValue;

    // Create fill path (start from bottom)
    final fillPath = Path();
    
    // Add the points for the line path and fill path
    for (int i = 0; i < data.length; i++) {
      final x = i * xStep;
      final y = height - ((data[i] - minValue) / range * height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, y);
      } else {
        // Use a smoother curve for Executive theme
        if (isExecutiveTheme && i > 0 && i < data.length - 1) {
          final prevX = (i - 1) * xStep;
          final prevY = height - ((data[i - 1] - minValue) / range * height);
          final controlX = (x + prevX) / 2;
          
          path.quadraticBezierTo(controlX, prevY, x, y);
          fillPath.quadraticBezierTo(controlX, prevY, x, y);
        } else {
          path.lineTo(x, y);
          fillPath.lineTo(x, y);
        }
      }
    }
    
    // Complete the fill path by drawing down to the bottom and back to start
    fillPath.lineTo((data.length - 1) * xStep, height);
    fillPath.lineTo(0, height);
    fillPath.close();

    // Draw the filled area under the curve
    canvas.drawPath(fillPath, fillPaint);
    
    // Draw the main line with gradient
    canvas.drawPath(path, gradientPaint);

    // Draw enhanced points on the line with subtle glow for executive theme
    final pointPaint = Paint()
      ..color = isExecutiveTheme ? Colors.white : theme.primaryChartColor
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;
      
    // For glowing effect in executive theme
    final glowPaint = isExecutiveTheme ? (Paint()
      ..color = theme.primaryChartColor.withOpacity(0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.fill) : null;

    // Draw fewer points for a cleaner look
    final pointInterval = data.length > 20 ? 3 : 2;
    
    for (int i = 0; i < data.length; i += pointInterval) {
      final x = i * xStep;
      final y = height - ((data[i] - minValue) / range * height);

      // For executive theme, add subtle point glow
      if (isExecutiveTheme && glowPaint != null) {
        canvas.drawCircle(Offset(x, y), 5, glowPaint);
      }
      
      // Draw the actual point
      canvas.drawCircle(
        Offset(x, y), 
        isExecutiveTheme ? 3 : 4, 
        pointPaint
      );
      
      // Add white center for executive theme points
      if (isExecutiveTheme) {
        final centerPaint = Paint()
          ..color = theme.primaryChartColor
          ..strokeWidth = 2
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 1.5, centerPaint);
      }
    }

    // Draw min and max value labels on y-axis with enhanced styling
    if (maxValue > minValue) {
      // Draw background for labels in executive theme
      if (isExecutiveTheme) {
        final labelBgPaint = Paint()
          ..color = const Color(0xFF1E2430)
          ..style = PaintingStyle.fill;
          
        canvas.drawRect(
          Rect.fromLTWH(0, 0, 50, 16),
          labelBgPaint
        );
        
        canvas.drawRect(
          Rect.fromLTWH(0, height / 2 - 8, 50, 16),
          labelBgPaint
        );
        
        canvas.drawRect(
          Rect.fromLTWH(0, height - 16, 50, 16),
          labelBgPaint
        );
      }
    
      String maxLabel = _formatValue(maxValue);
      textPainter.text = TextSpan(
        text: maxLabel, 
        style: textStyle.copyWith(
          fontWeight: isExecutiveTheme ? FontWeight.bold : FontWeight.normal,
          fontSize: isExecutiveTheme ? 11 : 10,
        )
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(4, 4));

      String midLabel = _formatValue(minValue + range / 2);
      textPainter.text = TextSpan(
        text: midLabel, 
        style: textStyle.copyWith(
          fontWeight: isExecutiveTheme ? FontWeight.bold : FontWeight.normal,
          fontSize: isExecutiveTheme ? 11 : 10,
        )
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(4, height / 2 - textPainter.height / 2));

      String minLabel = _formatValue(minValue);
      textPainter.text = TextSpan(
        text: minLabel, 
        style: textStyle.copyWith(
          fontWeight: isExecutiveTheme ? FontWeight.bold : FontWeight.normal,
          fontSize: isExecutiveTheme ? 11 : 10,
        )
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(4, height - textPainter.height - 4));
    }
  }

  String _formatValue(double value) {
    return NumberFormatter.formatCurrency(value);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}