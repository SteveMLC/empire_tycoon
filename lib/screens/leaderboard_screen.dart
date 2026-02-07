import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../models/leaderboard_entry.dart';
import '../services/leaderboard_service.dart';
import '../themes/stats_themes.dart';
import '../widgets/leaderboard_widgets.dart';
import '../utils/number_formatter.dart';

/// Full-screen leaderboard with category tabs and real-time updates
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LeaderboardService _leaderboardService = LeaderboardService();
  final GlobalKey _shareRepaintKey = GlobalKey();

  // Current state
  LeaderboardCategory _selectedCategory = LeaderboardCategory.tycoonRanking;
  List<LeaderboardEntry> _entries = [];
  LeaderboardEntry? _currentPlayerEntry;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  // Real-time subscription
  StreamSubscription<List<LeaderboardEntry>>? _realtimeSubscription;

  // Display name prompt state
  bool _hasPromptedDisplayName = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: LeaderboardCategory.values.length,
      vsync: this,
      initialIndex: LeaderboardCategory.values.indexOf(_selectedCategory),
    );

    _tabController.addListener(_onTabChanged);

    // Load initial data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLeaderboard();
      _subscribeToRealtime();
      _checkDisplayNamePrompt();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;

    final newCategory = LeaderboardCategory.values[_tabController.index];
    if (newCategory != _selectedCategory) {
      setState(() {
        _selectedCategory = newCategory;
        _isLoading = true;
        _entries = [];
      });
      _loadLeaderboard();
      _subscribeToRealtime();
    }
  }

  void _subscribeToRealtime() {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = _leaderboardService
        .watchTopPlayers(category: _selectedCategory, limit: 10)
        .listen((entries) {
      if (mounted) {
        // Only update top 10 with real-time data
        setState(() {
          for (int i = 0; i < entries.length && i < _entries.length; i++) {
            // Animate rank changes
            final oldEntry = _entries[i];
            final newEntry = entries[i];
            if (oldEntry.playerId != newEntry.playerId ||
                oldEntry.score != newEntry.score) {
              _entries[i] = newEntry;
            }
          }
        });
      }
    });
  }

  Future<void> _loadLeaderboard() async {
    if (!mounted) return;

    setState(() {
      _isLoading = _entries.isEmpty;
      _error = null;
    });

    try {
      final result = await _leaderboardService.getTopScores(
        category: _selectedCategory,
        limit: 50,
      );

      if (!mounted) return;

      if (result.error != null) {
        setState(() {
          _error = result.error;
          _isLoading = false;
        });
        return;
      }

      // Get current player's entry
      final playerId = _leaderboardService.currentPlayerId;
      LeaderboardEntry? playerEntry;

      if (playerId != null) {
        final rankResult = await _leaderboardService.getPlayerRank(_selectedCategory);
        if (rankResult.rank > 0) {
          final gameState = Provider.of<GameState>(context, listen: false);
          playerEntry = LeaderboardEntry(
            playerId: playerId,
            displayName: gameState.username ?? 'Tycoon#${playerId.hashCode.abs() % 100000}',
            avatarUrl: gameState.userAvatar,
            score: rankResult.score,
            rank: rankResult.rank,
            percentile: rankResult.percentile,
            updatedAt: DateTime.now(),
            tier: _leaderboardService.getTierFromScore(rankResult.score),
          );
        }
      }

      setState(() {
        _entries = result.entries;
        _currentPlayerEntry = playerEntry;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load leaderboard';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    HapticFeedback.lightImpact();

    // Submit current scores first
    final gameState = Provider.of<GameState>(context, listen: false);
    await _leaderboardService.submitScores(gameState);

    await _loadLeaderboard();

    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  void _checkDisplayNamePrompt() {
    if (_hasPromptedDisplayName) return;

    final gameState = Provider.of<GameState>(context, listen: false);
    if (gameState.username == null || gameState.username!.isEmpty) {
      // Show display name prompt after a delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showDisplayNameDialog();
        }
      });
    }
    _hasPromptedDisplayName = true;
  }

  void _showDisplayNameDialog() {
    final bool isExecutive = _getTheme().id == 'executive';
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isExecutive ? const Color(0xFF1E2430) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isExecutive ? const Color(0xFF2A3142) : Colors.grey.shade300,
          ),
        ),
        title: Row(
          children: [
            Icon(
              Icons.person,
              color: isExecutive ? const Color(0xFFFFD700) : Colors.amber.shade700,
            ),
            const SizedBox(width: 10),
            Text(
              'Set Display Name',
              style: TextStyle(
                color: isExecutive ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a name that other players will see on the leaderboard.',
              style: TextStyle(
                color: isExecutive ? Colors.grey.shade400 : Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLength: 20,
              style: TextStyle(
                color: isExecutive ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Enter your name',
                hintStyle: TextStyle(
                  color: isExecutive ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
                filled: true,
                fillColor: isExecutive ? const Color(0xFF242C3B) : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isExecutive ? Colors.blue.shade400 : Colors.blue,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Skip',
              style: TextStyle(
                color: isExecutive ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final gameState = Provider.of<GameState>(context, listen: false);
                gameState.username = name;
                Navigator.pop(context);
                _loadLeaderboard(); // Refresh with new name
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isExecutive ? const Color(0xFF1A56DB) : Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  StatsTheme _getTheme() {
    final gameState = Provider.of<GameState>(context, listen: false);
    return getStatsTheme(
      gameState.selectedStatsTheme,
      gameState.isExecutiveStatsThemeUnlocked,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final theme = getStatsTheme(
          gameState.selectedStatsTheme,
          gameState.isExecutiveStatsThemeUnlocked,
        );
        final bool isExecutive = theme.id == 'executive';

        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: _buildAppBar(theme, isExecutive),
          body: Column(
            children: [
              // Category tabs
              _buildCategoryTabs(theme, isExecutive),

              // Leaderboard content
              Expanded(
                child: _buildLeaderboardContent(theme, isExecutive),
              ),

              // Current player's rank bar (if not in visible list)
              if (_currentPlayerEntry != null &&
                  !_isCurrentPlayerVisible())
                CurrentPlayerRankBar(
                  entry: _currentPlayerEntry!,
                  theme: theme,
                  onTap: () => _scrollToPlayer(),
                ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(StatsTheme theme, bool isExecutive) {
    return AppBar(
      backgroundColor: isExecutive ? const Color(0xFF1E2430) : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: isExecutive ? Colors.white : Colors.black87,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isExecutive
                    ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
                    : [Colors.amber.shade400, Colors.amber.shade600],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Global Leaderboard',
            style: TextStyle(
              color: isExecutive ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        // Share button
        if (_currentPlayerEntry != null)
          ShareRankCard(
            playerEntry: _currentPlayerEntry!,
            category: _selectedCategory,
            theme: theme,
            repaintKey: _shareRepaintKey,
          ),
        // Refresh button
        IconButton(
          icon: _isRefreshing
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isExecutive ? Colors.white : Colors.blue,
                  ),
                )
              : Icon(
                  Icons.refresh,
                  color: isExecutive ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
          onPressed: _isRefreshing ? null : _onRefresh,
        ),
      ],
    );
  }

  Widget _buildCategoryTabs(StatsTheme theme, bool isExecutive) {
    return Container(
      color: isExecutive ? const Color(0xFF1E2430) : Colors.white,
      child: Column(
        children: [
          SizedBox(
            height: 50,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: isExecutive ? const Color(0xFFFFD700) : Colors.amber,
              indicatorWeight: 3,
              labelColor: isExecutive ? Colors.white : Colors.black87,
              unselectedLabelColor: isExecutive ? Colors.grey.shade500 : Colors.grey.shade600,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: LeaderboardCategory.values.map((category) {
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(category.icon),
                      const SizedBox(width: 6),
                      Text(category.displayName),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          Divider(
            height: 1,
            color: isExecutive ? const Color(0xFF2A3142) : Colors.grey.shade200,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardContent(StatsTheme theme, bool isExecutive) {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: 10,
        itemBuilder: (context, index) => LeaderboardEntrySkeleton(theme: theme),
      );
    }

    if (_error != null) {
      return LeaderboardEmptyState(
        theme: theme,
        message: _error!,
        onRetry: _loadLeaderboard,
      );
    }

    if (_entries.isEmpty) {
      return LeaderboardEmptyState(
        theme: theme,
        message: 'No players on the leaderboard yet.\nBe the first!',
        onRetry: _loadLeaderboard,
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: isExecutive ? const Color(0xFFFFD700) : Colors.amber,
      backgroundColor: isExecutive ? const Color(0xFF1E2430) : Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          final entry = _entries[index];
          final isCurrentPlayer =
              _currentPlayerEntry?.playerId == entry.playerId;

          return LeaderboardEntryWidget(
            entry: entry,
            isCurrentPlayer: isCurrentPlayer,
            isTopThree: entry.rank <= 3,
            theme: theme,
            onTap: () => _showPlayerProfile(entry),
          );
        },
      ),
    );
  }

  bool _isCurrentPlayerVisible() {
    if (_currentPlayerEntry == null) return true;
    return _entries.any((e) => e.playerId == _currentPlayerEntry!.playerId);
  }

  void _scrollToPlayer() {
    // In a real implementation, would scroll to player's position
    // For now, show a dialog with their rank details
    if (_currentPlayerEntry == null) return;

    _showPlayerProfile(_currentPlayerEntry!);
  }

  void _showPlayerProfile(LeaderboardEntry entry) {
    final theme = _getTheme();
    final bool isExecutive = theme.id == 'executive';
    final bool isCurrentPlayer =
        _currentPlayerEntry?.playerId == entry.playerId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isExecutive ? const Color(0xFF1E2430) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isExecutive ? Colors.grey.shade600 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: entry.rank <= 3
                        ? (entry.rank == 1
                            ? const Color(0xFFFFD700)
                            : entry.rank == 2
                                ? const Color(0xFFC0C0C0)
                                : const Color(0xFFCD7F32))
                        : (isExecutive ? Colors.blue.shade400 : Colors.blue.shade300),
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: entry.avatarUrl != null
                      ? Image.network(entry.avatarUrl!, fit: BoxFit.cover)
                      : Container(
                          color: isExecutive
                              ? const Color(0xFF2A3142)
                              : Colors.grey.shade200,
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: isExecutive
                                ? Colors.grey.shade400
                                : Colors.grey.shade500,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Name
              Text(
                entry.displayName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isExecutive ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),

              // Tier
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    entry.tierBadge,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.tierDisplayName,
                    style: TextStyle(
                      fontSize: 14,
                      color: isExecutive
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Stats grid
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isExecutive
                      ? const Color(0xFF242C3B)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildProfileStat(
                      'Rank',
                      '#${entry.rank}',
                      Icons.leaderboard,
                      isExecutive,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: isExecutive
                          ? const Color(0xFF2A3142)
                          : Colors.grey.shade300,
                    ),
                    _buildProfileStat(
                      _selectedCategory.displayName,
                      NumberFormatter.formatCompact(entry.score),
                      Icons.star,
                      isExecutive,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: isExecutive
                          ? const Color(0xFF2A3142)
                          : Colors.grey.shade300,
                    ),
                    _buildProfileStat(
                      'Percentile',
                      'Top ${entry.percentile.toStringAsFixed(1)}%',
                      Icons.trending_up,
                      isExecutive,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              if (isCurrentPlayer) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showDisplayNameDialog();
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit Name'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isExecutive
                              ? const Color(0xFF2A3A5A)
                              : Colors.grey.shade200,
                          foregroundColor:
                              isExecutive ? Colors.white : Colors.black87,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // Share functionality - copy to clipboard
                          final shareText = '🏆 I\'m ranked #${entry.rank} in ${_selectedCategory.displayName} '
                              'on Empire Tycoon with ${NumberFormatter.formatCompact(entry.score)}!\n\n'
                              'Think you can beat me? 🎮';
                          await Clipboard.setData(ClipboardData(text: shareText));
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Rank copied! Share it anywhere 🎉'),
                                backgroundColor: Colors.green.shade700,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Share'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isExecutive
                              ? const Color(0xFFFFD700)
                              : Colors.amber,
                          foregroundColor:
                              isExecutive ? Colors.black : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Could implement challenge feature here
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Challenge sent to ${entry.displayName}!'),
                          backgroundColor: Colors.green.shade700,
                        ),
                      );
                    },
                    icon: const Icon(Icons.sports_kabaddi, size: 18),
                    label: Text('Challenge ${entry.displayName}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isExecutive
                          ? const Color(0xFF1A56DB)
                          : Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStat(
    String label,
    String value,
    IconData icon,
    bool isExecutive,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: isExecutive ? const Color(0xFFFFD700) : Colors.amber.shade700,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isExecutive ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isExecutive ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
