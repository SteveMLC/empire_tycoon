import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/investment.dart';
import '../screens/investment_detail_screen.dart';
import '../utils/number_formatter.dart';
import '../services/game_service.dart';
import '../utils/sound_assets.dart';

class InvestmentPortfolioScreen extends StatefulWidget {
  const InvestmentPortfolioScreen({Key? key}) : super(key: key);

  @override
  State<InvestmentPortfolioScreen> createState() => _InvestmentPortfolioScreenState();
}

class _InvestmentPortfolioScreenState extends State<InvestmentPortfolioScreen> {
  String _sortMode = 'value';
  String _viewMode = 'list';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Consumer<GameState>(
        builder: (context, gameState, _) {
          List<Investment> ownedInvestments = gameState.investments
              .where((investment) => investment.owned > 0)
              .toList();

          _sortInvestments(ownedInvestments);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Enhanced App Bar with Empire Tycoon styling
              _buildEmpireAppBar(gameState, ownedInvestments),
              
              // Portfolio Summary Cards
              _buildPortfolioSummary(gameState, ownedInvestments),
              
              // Controls Header
              _buildControlsHeader(ownedInvestments.length),
              
              // Main Content - Investments List/Grid
              if (ownedInvestments.isEmpty)
                _buildEmptyState()
              else if (_viewMode == 'grid')
                _buildInvestmentsGrid(ownedInvestments)
              else
                _buildInvestmentsList(ownedInvestments),
              
              // Performance Analytics
              if (ownedInvestments.isNotEmpty)
                _buildPerformanceAnalytics(ownedInvestments),
              
              // Bottom padding for better scrolling
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmpireAppBar(GameState gameState, List<Investment> ownedInvestments) {
    double totalValue = ownedInvestments.fold(0.0, (sum, inv) => sum + inv.getCurrentValue());
    double totalProfit = ownedInvestments.fold(0.0, (sum, inv) => sum + inv.getProfitLoss());
    double profitPercentage = totalValue > 0 ? (totalProfit / (totalValue - totalProfit)) * 100 : 0;
    
    return SliverAppBar(
      expandedHeight: 200, // Increased to 200 to provide more space
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF1A237E),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16), // Proper title positioning
        title: const Text(
          'Investment Portfolio',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 2,
                color: Colors.black26,
              ),
            ],
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A237E),
                Color(0xFF3949AB),
                Color(0xFF5C6BC0),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 100, 16, 60), // Adjusted to prevent overlap with title
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAppBarStat(
                    'Portfolio Value',
                    '\$${NumberFormatter.formatCompact(totalValue)}',
                    Icons.account_balance_wallet_outlined,
                    Colors.white,
                  ),
                  Container(
                    width: 1,
                    height: 30, // Further reduced height
                    color: Colors.white.withOpacity(0.3),
                  ),
                  _buildAppBarStat(
                    'Total P&L',
                    '${totalProfit >= 0 ? '+' : ''}\$${NumberFormatter.formatCompact(totalProfit)}',
                    totalProfit >= 0 ? Icons.trending_up : Icons.trending_down,
                    totalProfit >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                  ),
                  Container(
                    width: 1,
                    height: 30, // Further reduced height
                    color: Colors.white.withOpacity(0.3),
                  ),
                  _buildAppBarStat(
                    'Return %',
                    '${profitPercentage >= 0 ? '+' : ''}${profitPercentage.toStringAsFixed(1)}%',
                    profitPercentage >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    profitPercentage >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 50), // Constrain height to prevent overflow
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16), // Further reduced icon size
            const SizedBox(height: 2), // Minimal spacing
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 8, // Further reduced font size
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1), // Minimal spacing
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 10, // Further reduced font size
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioSummary(GameState gameState, List<Investment> ownedInvestments) {
    if (ownedInvestments.isEmpty) return const SliverToBoxAdapter(child: SizedBox());
    
    double totalInvested = ownedInvestments.fold(0.0, (sum, inv) => sum + (inv.purchasePrice * inv.owned));
    double totalDividends = ownedInvestments.fold(0.0, (sum, inv) => sum + (inv.hasDividends() ? inv.getDividendIncomePerSecond() : 0));
    int winnersCount = ownedInvestments.where((inv) => inv.getProfitLoss() > 0).length;
    int losersCount = ownedInvestments.where((inv) => inv.getProfitLoss() < 0).length;
    int breakEvenCount = ownedInvestments.where((inv) => inv.getProfitLoss() == 0).length;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          children: [
            // Compact summary cards
            Row(
              children: [
                Expanded(
                  child: _buildCompactSummaryCard(
                    'Total Invested',
                    '\$${NumberFormatter.formatCompact(totalInvested)}',
                    Icons.savings_outlined,
                    const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 8),
                if (totalDividends > 0)
                  Expanded(
                    child: _buildCompactSummaryCard(
                      'Dividend Income',
                      '\$${NumberFormatter.formatCompact(totalDividends)}/s',
                      Icons.attach_money,
                      const Color(0xFF4CAF50),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Compact performance breakdown
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Performance Breakdown',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCompactPerformanceItem(
                        'Winners',
                        winnersCount.toString(),
                        Icons.trending_up,
                        const Color(0xFF4CAF50),
                      ),
                      _buildCompactPerformanceItem(
                        'Break Even',
                        breakEvenCount.toString(),
                        Icons.remove,
                        const Color(0xFFFF9800),
                      ),
                      _buildCompactPerformanceItem(
                        'Losers',
                        losersCount.toString(),
                        Icons.trending_down,
                        const Color(0xFFE53935),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPerformanceItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildControlsHeader(int investmentCount) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Text(
              'Your Investments',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            const Spacer(),
            // Sort Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButton<String>(
                value: _sortMode,
                underline: const SizedBox(),
                icon: Icon(Icons.sort, color: const Color(0xFF1A237E), size: 16),
                style: const TextStyle(fontSize: 13, color: Colors.black),
                items: const [
                  DropdownMenuItem(value: 'value', child: Text('Value')),
                  DropdownMenuItem(value: 'profit', child: Text('P&L')),
                  DropdownMenuItem(value: 'percentage', child: Text('P&L %')),
                  DropdownMenuItem(value: 'name', child: Text('Name')),
                ],
                onChanged: (value) => setState(() => _sortMode = value!),
              ),
            ),
            const SizedBox(width: 12),
            // View Mode Toggle
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildViewModeButton(Icons.list, 'list'),
                  _buildViewModeButton(Icons.grid_view, 'grid'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeButton(IconData icon, String mode) {
    bool isSelected = _viewMode == mode;
    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A237E) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey.shade600,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Investments Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start building your empire by\ninvesting in promising opportunities!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.trending_up),
              label: const Text('Browse Investments'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestmentsList(List<Investment> investments) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildInvestmentListCard(investments[index]),
          ),
          childCount: investments.length,
        ),
      ),
    );
  }

  Widget _buildInvestmentListCard(Investment investment) {
    double profitLoss = investment.getProfitLoss();
    double profitPercentage = investment.getProfitLossPercentage();
    double currentValue = investment.getCurrentValue();
    double marketChange = investment.getPriceChangePercent();
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InvestmentDetailScreen(investment: investment),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
              child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            // Header Row
            Row(
              children: [
                // Investment Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: investment.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    investment.icon,
                    color: investment.color,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 10),
                
                // Investment Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              investment.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (investment.hasDividends())
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'DIV',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF4CAF50),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${investment.owned} shares',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${investment.currentPrice.toStringAsFixed(2)}/share',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Current Value
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${NumberFormatter.formatCompact(currentValue)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    Text(
                      'Current Value',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Performance Row
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  // Your P&L (Dollar Amount)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              profitLoss >= 0 ? Icons.trending_up : Icons.trending_down,
                              size: 12,
                              color: profitLoss >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Your P&L',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${profitLoss >= 0 ? '+' : ''}\$${NumberFormatter.formatCompact(profitLoss.abs())}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: profitLoss >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Your P&L (Percentage)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Return %',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: profitPercentage >= 0 
                                ? const Color(0xFF4CAF50).withOpacity(0.1)
                                : const Color(0xFFE53935).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${profitPercentage >= 0 ? '+' : ''}${profitPercentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: profitPercentage >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Market Performance
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Market',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              marketChange >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                              size: 12,
                              color: marketChange >= 0 ? const Color(0xFF2196F3) : const Color(0xFFFF9800),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${marketChange >= 0 ? '+' : ''}${marketChange.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: marketChange >= 0 ? const Color(0xFF2196F3) : const Color(0xFFFF9800),
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
            
            const SizedBox(height: 10),
            
            // Quick Buy/Sell Actions
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'Buy More',
                    Icons.add_circle_outline,
                    const Color(0xFF4CAF50),
                    () => _showQuickTradeDialog(investment, true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    'Sell',
                    Icons.remove_circle_outline,
                    const Color(0xFFE53935),
                    () => _showQuickTradeDialog(investment, false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestmentsGrid(List<Investment> investments) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildInvestmentGridCard(investments[index]),
          childCount: investments.length,
        ),
      ),
    );
  }

  Widget _buildInvestmentGridCard(Investment investment) {
    double profitLoss = investment.getProfitLoss();
    double profitPercentage = investment.getProfitLossPercentage();
    double currentValue = investment.getCurrentValue();
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InvestmentDetailScreen(investment: investment),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and dividend badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: investment.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      investment.icon,
                      color: investment.color,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  if (investment.hasDividends())
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'DIV',
                        style: TextStyle(
                          fontSize: 8,
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Investment name
              Text(
                investment.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 4),
              
              // Shares owned
              Text(
                '${investment.owned} shares',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
              
              const Spacer(),
              
              // Current value
              Text(
                '\$${NumberFormatter.formatCompact(currentValue)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
              
              const SizedBox(height: 4),
              
              // P&L
              Row(
                children: [
                  Icon(
                    profitLoss >= 0 ? Icons.trending_up : Icons.trending_down,
                    size: 12,
                    color: profitLoss >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${profitLoss >= 0 ? '+' : ''}\$${NumberFormatter.formatCompact(profitLoss.abs())} (${profitPercentage >= 0 ? '+' : ''}${profitPercentage.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: profitLoss >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceAnalytics(List<Investment> investments) {
    // Find best and worst performers
    Investment? bestPerformer;
    Investment? worstPerformer;
    double bestPerformance = double.negativeInfinity;
    double worstPerformance = double.infinity;
    
    for (var investment in investments) {
      double performance = investment.getProfitLossPercentage();
      if (performance > bestPerformance) {
        bestPerformance = performance;
        bestPerformer = investment;
      }
      if (performance < worstPerformance) {
        worstPerformance = performance;
        worstPerformer = investment;
      }
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Highlights',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 12),
            if (bestPerformer != null && worstPerformer != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildPerformanceHighlight(
                      'Best Performer',
                      bestPerformer!.name,
                      '${bestPerformance >= 0 ? '+' : ''}${bestPerformance.toStringAsFixed(1)}%',
                      bestPerformer!.icon,
                      bestPerformer!.color,
                      const Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPerformanceHighlight(
                      'Worst Performer',
                      worstPerformer!.name,
                      '${worstPerformance >= 0 ? '+' : ''}${worstPerformance.toStringAsFixed(1)}%',
                      worstPerformer!.icon,
                      worstPerformer!.color,
                      const Color(0xFFE53935),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceHighlight(String title, String name, String performance, IconData icon, Color iconColor, Color performanceColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: performanceColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: performanceColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, color: iconColor, size: 14),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            performance,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: performanceColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  void _showQuickTradeDialog(Investment investment, bool isBuying) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<GameState>(
          builder: (context, gameState, _) {
            int quantity = 1;
            int maxAffordable = isBuying 
                ? (gameState.money / investment.currentPrice).floor()
                : investment.owned;
            
            return StatefulBuilder(
              builder: (context, setState) {
                double totalCost = investment.currentPrice * quantity;
                bool canAfford = isBuying 
                    ? gameState.money >= totalCost && quantity <= investment.availableShares
                    : investment.owned >= quantity;
                
                return AlertDialog(
                  title: Text(
                    '${isBuying ? 'Buy' : 'Sell'} ${investment.name}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: investment.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(investment.icon, color: investment.color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '\$${investment.currentPrice.toStringAsFixed(2)}/share',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                if (isBuying)
                                  Text(
                                    'Available: ${investment.availableShares} shares',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  )
                                else
                                  Text(
                                    'Owned: ${investment.owned} shares',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          IconButton(
                            onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                            icon: const Icon(Icons.remove_circle_outline),
                            color: const Color(0xFF1A237E),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                quantity.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: quantity < maxAffordable ? () => setState(() => quantity++) : null,
                            icon: const Icon(Icons.add_circle_outline),
                            color: const Color(0xFF1A237E),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (maxAffordable > 1)
                        TextButton(
                          onPressed: () => setState(() => quantity = maxAffordable),
                          child: Text('MAX (${maxAffordable})'),
                        ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total:',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '\$${NumberFormatter.formatCompact(totalCost)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isBuying ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: canAfford ? () {
                        final gameService = Provider.of<GameService>(context, listen: false);
                        bool success = isBuying 
                            ? gameState.buyInvestment(investment.id, quantity)
                            : gameState.sellInvestment(investment.id, quantity);
                        
                        if (success) {
                          // Play the same sound effects as investment detail screen
                          try {
                            if (isBuying) {
                              gameService.soundManager.playInvestmentBuyStockSound();
                            } else {
                              gameService.soundManager.playInvestmentSellStockSound();
                            }
                          } catch (e) {
                            // Continue with the transaction process even if sound fails
                            print("Error playing investment ${isBuying ? 'buy' : 'sell'} sound: $e");
                          }
                        } else {
                          // Play error sound for failed transactions
                          try {
                            gameService.soundManager.playFeedbackErrorSound();
                          } catch (e) {
                            // Continue with the error handling even if sound fails
                            print("Error playing error sound: $e");
                          }
                        }
                        
                        Navigator.pop(context);
                        
                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   SnackBar(
                        //     content: Text(
                        //       success 
                        //           ? '${isBuying ? 'Bought' : 'Sold'} $quantity shares of ${investment.name}'
                        //           : 'Transaction failed',
                        //     ),
                        //     backgroundColor: success 
                        //         ? (isBuying ? const Color(0xFF4CAF50) : const Color(0xFF2196F3))
                        //         : const Color(0xFFE53935),
                        //   ),
                        // );
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBuying ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                      ),
                      child: Text('${isBuying ? 'Buy' : 'Sell'} $quantity'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _sortInvestments(List<Investment> investments) {
    switch (_sortMode) {
      case 'value':
        investments.sort((a, b) => b.getCurrentValue().compareTo(a.getCurrentValue()));
        break;
      case 'profit':
        investments.sort((a, b) => b.getProfitLoss().compareTo(a.getProfitLoss()));
        break;
      case 'percentage':
        investments.sort((a, b) => b.getProfitLossPercentage().compareTo(a.getProfitLossPercentage()));
        break;
      case 'name':
        investments.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
  }
} 