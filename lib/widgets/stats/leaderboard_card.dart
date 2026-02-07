import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../models/game_state.dart';
import '../../themes/stats_themes.dart';
import '../../utils/number_formatter.dart';

/// Leaderboard card for the Stats screen
/// Shows current ranking and provides quick access to Google Play leaderboards
class LeaderboardCard extends StatefulWidget {
  final GameState gameState;
  final StatsTheme theme;

  const LeaderboardCard({
    Key? key,
    required this.gameState,
    required this.theme,
  }) : super(key: key);

  @override
  State<LeaderboardCard> createState() => _LeaderboardCardState();
}

class _LeaderboardCardState extends State<LeaderboardCard> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final bool isExecutive = widget.theme.id == 'executive';

    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return Card(
          elevation: widget.theme.elevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.theme.borderRadius),
            side: BorderSide(
              color: isExecutive
                  ? const Color(0xFF2A3142)
                  : widget.theme.cardBorderColor,
            ),
          ),
          color: widget.theme.cardBackgroundColor,
          shadowColor: widget.theme.cardShadow?.color ?? Colors.black26,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isExecutive
                              ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
                              : [Colors.amber.shade400, Colors.amber.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Global Leaderboard',
                      style: isExecutive
                          ? widget.theme.cardTitleStyle
                          : TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                    ),
                    const Spacer(),
                    // Google Play Games badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isExecutive
                            ? const Color(0xFF242C3B)
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isExecutive
                              ? const Color(0xFF2A3142)
                              : Colors.green.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sports_esports,
                            size: 14,
                            color: isExecutive
                                ? Colors.green.shade300
                                : Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Play Games',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isExecutive
                                  ? Colors.green.shade300
                                  : Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                Divider(
                  height: 30,
                  thickness: 1,
                  color: isExecutive
                      ? const Color(0xFF2A3142)
                      : Colors.amber.withOpacity(0.2),
                ),

                // Content based on auth state
                if (!authService.isSignedIn)
                  _buildSignInPrompt(authService, isExecutive)
                else
                  _buildLeaderboardContent(authService, isExecutive),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSignInPrompt(AuthService authService, bool isExecutive) {
    return Column(
      children: [
        // Motivational message
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isExecutive
                  ? [const Color(0xFF242C3B), const Color(0xFF1E2430)]
                  : [Colors.amber.shade50, Colors.orange.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isExecutive
                  ? const Color(0xFFFFD700).withOpacity(0.3)
                  : Colors.amber.shade200,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.leaderboard,
                size: 48,
                color: isExecutive
                    ? const Color(0xFFFFD700)
                    : Colors.amber.shade600,
              ),
              const SizedBox(height: 12),
              Text(
                'Compete with Tycoons Worldwide!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isExecutive ? Colors.white : Colors.amber.shade900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to see your global ranking and compete for the top spot.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isExecutive
                      ? Colors.grey.shade400
                      : Colors.amber.shade700,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Sign in button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading
                ? null
                : () async {
                    setState(() => _isLoading = true);
                    await authService.signIn();
                    if (mounted) setState(() => _isLoading = false);
                  },
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.login, size: 20),
            label: Text(_isLoading ? 'Connecting...' : 'Sign in with Google Play'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isExecutive
                  ? const Color(0xFF1A56DB)
                  : Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Your current score preview
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isExecutive
                ? const Color(0xFF1E2430)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.trending_up,
                size: 16,
                color: isExecutive ? Colors.green.shade300 : Colors.green.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Your lifetime net worth: ',
                style: TextStyle(
                  fontSize: 13,
                  color: isExecutive ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
              ),
              Text(
                NumberFormatter.formatCurrency(widget.gameState.totalLifetimeNetWorth),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isExecutive ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardContent(AuthService authService, bool isExecutive) {
    return Column(
      children: [
        // Player's score display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isExecutive
                  ? [const Color(0xFF242C3B), const Color(0xFF1E2430)]
                  : [Colors.amber.shade50, Colors.orange.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isExecutive
                  ? const Color(0xFFFFD700).withOpacity(0.3)
                  : Colors.amber.shade200,
            ),
          ),
          child: Column(
            children: [
              // Signed in user info
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isExecutive
                            ? const Color(0xFFFFD700)
                            : Colors.amber.shade400,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: authService.playerAvatarUrl != null
                          ? Image.network(
                              authService.playerAvatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildDefaultAvatar(isExecutive),
                            )
                          : _buildDefaultAvatar(isExecutive),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authService.playerName ?? 'Tycoon',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isExecutive ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.verified,
                              size: 14,
                              color: isExecutive
                                  ? Colors.green.shade300
                                  : Colors.green.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Connected to Google Play',
                              style: TextStyle(
                                fontSize: 12,
                                color: isExecutive
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Score display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isExecutive
                      ? const Color(0xFF1E2430)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isExecutive
                        ? const Color(0xFF2A3142)
                        : Colors.amber.shade100,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Highest Net Worth',
                          style: TextStyle(
                            fontSize: 12,
                            color: isExecutive
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          NumberFormatter.formatCurrency(
                              widget.gameState.totalLifetimeNetWorth),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isExecutive
                                ? const Color(0xFFFFD700)
                                : Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.emoji_events,
                      size: 32,
                      color: isExecutive
                          ? const Color(0xFFFFD700).withOpacity(0.7)
                          : Colors.amber.shade300,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // View leaderboard buttons
        Row(
          children: [
            // In-app leaderboard button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/leaderboard');
                },
                icon: const Icon(Icons.emoji_events, size: 18),
                label: const Text('Full Leaderboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isExecutive
                      ? const Color(0xFFFFD700)
                      : Colors.amber.shade600,
                  foregroundColor: isExecutive ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Google Play leaderboard button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() => _isLoading = true);
                        
                        // Submit latest score first
                        await authService.submitHighestNetWorth(
                            widget.gameState.totalLifetimeNetWorth);
                        
                        // Show leaderboard
                        await authService.showHighestNetWorthLeaderboard();
                        
                        if (mounted) setState(() => _isLoading = false);
                        
                        // Show error if any
                        if (authService.lastError != null && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(authService.lastError!),
                              backgroundColor: Colors.red.shade700,
                            ),
                          );
                        }
                      },
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.sports_esports, size: 18),
                label: Text(_isLoading ? '...' : 'Play Games'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isExecutive
                      ? const Color(0xFF1A56DB)
                      : Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Tips
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isExecutive
                ? const Color(0xFF1E2430)
                : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: isExecutive ? Colors.blue.shade300 : Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tip: Your lifetime net worth persists across reincorporations!',
                  style: TextStyle(
                    fontSize: 12,
                    color: isExecutive
                        ? Colors.grey.shade400
                        : Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar(bool isExecutive) {
    return Container(
      color: isExecutive ? const Color(0xFF2A3142) : Colors.grey.shade200,
      child: Icon(
        Icons.person,
        size: 24,
        color: isExecutive ? Colors.grey.shade400 : Colors.grey.shade500,
      ),
    );
  }
}
