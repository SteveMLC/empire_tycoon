import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../models/game_state.dart';
import '../services/game_service.dart';
import '../utils/number_formatter.dart';

// Custom painter for the toggle switch track (moved to top-level)
class ToggleTrackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw subtle sparkle pattern in the background of the toggle track
    final Paint sparkPaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.15)
      ..style = PaintingStyle.fill;
    
    final Random random = Random(12); // Fixed seed for consistency
    for (int i = 0; i < 15; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      double radius = 0.5 + random.nextDouble() * 1.0;
      
      canvas.drawCircle(
        Offset(x, y),
        radius,
        sparkPaint,
      );
    }
    
    // Draw diagonal lines for a premium pattern
    final Paint linePaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    
    for (double i = -size.height * 2; i < size.width * 2; i += 4) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  // User avatar options
  final List<String> _avatarOptions = [
    '👨‍💼', '👩‍💼', '👨‍💻', '👩‍💻', '👨‍🚀', '👩‍🚀', '👨‍🔧', '👩‍🔧',
    '😎', '🤓', '🧐', '🤠', '🥸', '🦹', '🦸', '🧙',
  ];
  
  // Add state to track if avatar selection is expanded
  bool _isAvatarSelectionExpanded = false;
  
  // Add username controller as a class variable
  late TextEditingController _usernameController;

  @override
  void initState() {
    super.initState();
    // Initialize the username controller
    final gameState = Provider.of<GameState>(context, listen: false);
    _usernameController = TextEditingController(text: gameState.username ?? 'Tycoon');
  }
  
  @override
  void dispose() {
    // Dispose the controller when the widget is disposed
    _usernameController.dispose();
    super.dispose();
  }
  
  // Add method to update controller if username changes elsewhere
  void _updateUsernameIfNeeded(GameState gameState) {
    final username = gameState.username ?? 'Tycoon';
    // Only update if different to avoid cursor jumping
    if (_usernameController.text != username) {
      _usernameController.text = username;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileSection(gameState),
                
                const SizedBox(height: 20),

                _buildGameConnectionSection(gameState),
                
                const SizedBox(height: 20),
                
                _buildSettingsSection(gameState),
                
                const SizedBox(height: 20),
                
                _buildPremiumSection(gameState),
                
                const SizedBox(height: 50),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileSection(GameState gameState) {
    // Update username controller if needed
    _updateUsernameIfNeeded(gameState);
    
    // Default avatar or user's selected avatar
    String currentAvatar = gameState.userAvatar ?? '👨‍💼';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                // Avatar display
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blue.shade300,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      currentAvatar,
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                hintText: 'Enter your name',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged: (value) {
                                gameState.username = value;
                              },
                              onEditingComplete: () {
                                // Save game when editing is done
                                Provider.of<GameService>(context, listen: false).saveGame();
                              },
                              onFieldSubmitted: (_) {
                                // Save game when field is submitted
                                Provider.of<GameService>(context, listen: false).saveGame();
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'Empire Level: ${gameState.totalReincorporations}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      
                      Text(
                        'Net Worth: ${NumberFormatter.formatCurrency(gameState.calculateNetWorth())}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Avatar selection toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Avatar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Small indicator of current avatar
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          currentAvatar,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isAvatarSelectionExpanded = !_isAvatarSelectionExpanded;
                    });
                  },
                  icon: Icon(
                    _isAvatarSelectionExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: Colors.blue,
                  ),
                  label: Text(
                    _isAvatarSelectionExpanded ? 'Collapse' : 'Change Avatar',
                    style: const TextStyle(
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            
            // Collapsible avatar selection grid
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isAvatarSelectionExpanded ? null : 0,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isAvatarSelectionExpanded ? 1.0 : 0.0,
                child: _isAvatarSelectionExpanded ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    
                    // Avatar selection grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8,
                        childAspectRatio: 1,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _avatarOptions.length,
                      itemBuilder: (context, index) {
                        final avatar = _avatarOptions[index];
                        final isSelected = avatar == currentAvatar;
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              gameState.userAvatar = avatar;
                              // Auto collapse after selection
                              _isAvatarSelectionExpanded = false;
                            });
                            
                            // Save the game to persist the avatar choice
                            Provider.of<GameService>(context, listen: false).saveGame();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                avatar,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Done button to collapse
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isAvatarSelectionExpanded = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ) : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameConnectionSection(GameState gameState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Game Connection',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Google Play Games Services login button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement Google Play Games login
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Google Play Games login coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.games),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                label: const Text('Sign in with Google Play Games'),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Cloud save status
            Row(
              children: [
                const Icon(Icons.cloud_sync, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Cloud Save:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  'Not connected',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Last played info
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Last Saved:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatLastSavedTime(gameState.lastSaved),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(GameState gameState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Game Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Consumer<GameService>(
              builder: (context, gameService, child) {
                bool soundEnabled = gameService.soundManager.isSoundEnabled();
                return SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      gameService.soundManager.toggleSound(!soundEnabled);
                      // Force rebuild to update icon
                      setState(() {});
                    },
                    icon: Icon(
                      soundEnabled ? Icons.volume_up : Icons.volume_off,
                      color: soundEnabled ? Colors.green : Colors.grey,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: soundEnabled ? Colors.green : Colors.grey,
                      ),
                    ),
                    label: Text(
                      soundEnabled ? 'Sound: ON' : 'Sound: OFF',
                      style: TextStyle(
                        color: soundEnabled ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Platinum Frame Toggle - only show if unlocked
            if (gameState.isPlatinumFrameUnlocked)
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: gameState.isPlatinumFrameActive 
                              ? const Color(0xFFFFD700).withOpacity(0.3)
                              : Colors.transparent,
                          blurRadius: 8,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          // Toggle platinum frame state
                          gameState.togglePlatinumFrame(!gameState.isPlatinumFrameActive);
                        },
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: gameState.isPlatinumFrameActive
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF3D2B5B),  // Deep royal purple
                                      Color(0xFF2E3470),  // Rich royal blue
                                    ],
                                  )
                                : null,
                            color: gameState.isPlatinumFrameActive ? null : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: gameState.isPlatinumFrameActive
                                  ? const Color(0xFFFFD700)
                                  : Colors.grey.shade300,
                              width: gameState.isPlatinumFrameActive ? 1.5 : 1.0,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            child: Row(
                              children: [
                                // Platinum icon with container
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: gameState.isPlatinumFrameActive
                                        ? const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [Color(0xFFFFD700), Color(0xFFFDCD3A)],
                                          )
                                        : null,
                                    color: gameState.isPlatinumFrameActive ? null : Colors.grey.shade200,
                                    boxShadow: gameState.isPlatinumFrameActive
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFFFFD700).withOpacity(0.5),
                                              blurRadius: 8,
                                              spreadRadius: -2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: gameState.isPlatinumFrameActive
                                        ? Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              // Shimmering effect
                                              Icon(
                                                Icons.dashboard_customize,
                                                color: Colors.white.withOpacity(0.7),
                                                size: 24,
                                              ),
                                              // Main icon
                                              const Icon(
                                                Icons.dashboard_customize,
                                                color: Colors.white,
                                                size: 22,
                                              ),
                                            ],
                                          )
                                        : Icon(
                                            Icons.dashboard_customize,
                                            color: Colors.grey.shade500,
                                            size: 22,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Text section
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Platinum UI Frame',
                                            style: TextStyle(
                                              color: gameState.isPlatinumFrameActive
                                                  ? Colors.white
                                                  : Colors.black87,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          if (gameState.isPlatinumFrameActive)
                                            Container(
                                              margin: const EdgeInsets.only(left: 8),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFD700),
                                                borderRadius: BorderRadius.circular(10),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFFFFD700).withOpacity(0.4),
                                                    blurRadius: 4,
                                                    spreadRadius: -1,
                                                  ),
                                                ],
                                              ),
                                              child: const Text(
                                                'PREMIUM',
                                                style: TextStyle(
                                                  color: Color(0xFF3D2B5B),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        gameState.isPlatinumFrameActive
                                            ? 'Active: Luxury UI enabled'
                                            : 'Inactive: Click to enable premium UI',
                                        style: TextStyle(
                                          color: gameState.isPlatinumFrameActive
                                              ? Colors.grey.shade300
                                              : Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Status toggle
                                Container(
                                  width: 56,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: gameState.isPlatinumFrameActive
                                        ? const Color(0xFFFFD700).withOpacity(0.2)
                                        : Colors.grey.shade200,
                                    border: Border.all(
                                      color: gameState.isPlatinumFrameActive
                                          ? const Color(0xFFFFD700)
                                          : Colors.grey.shade400,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      // Track overlay
                                      if (gameState.isPlatinumFrameActive)
                                        Positioned(
                                          top: 0,
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: CustomPaint(
                                            painter: ToggleTrackPainter(),
                                          ),
                                        ),
                                      // Sliding knob
                                      AnimatedPositioned(
                                        duration: const Duration(milliseconds: 200),
                                        curve: Curves.easeInOut,
                                        left: gameState.isPlatinumFrameActive ? 28 : 0,
                                        right: gameState.isPlatinumFrameActive ? 0 : 28,
                                        top: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 28,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: gameState.isPlatinumFrameActive
                                                ? const LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [Color(0xFFFFD700), Color(0xFFFDCD3A)],
                                                  )
                                                : null,
                                            color: gameState.isPlatinumFrameActive ? null : Colors.white,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.2),
                                                blurRadius: 2,
                                                spreadRadius: 0,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Icon(
                                              gameState.isPlatinumFrameActive
                                                  ? Icons.check
                                                  : Icons.close,
                                              size: 16,
                                              color: gameState.isPlatinumFrameActive
                                                  ? const Color(0xFF3D2B5B)
                                                  : Colors.grey.shade400,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            Consumer<GameService>(
              builder: (context, gameService, child) {
                return SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Saving game...'),
                          duration: Duration(seconds: 1),
                        ),
                      );

                      bool success = await gameService.saveGame();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? 'Game saved successfully!'
                              : 'Failed to save game.'),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.save,
                      color: Colors.blue,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(
                        color: Colors.blue,
                      ),
                    ),
                    label: const Text(
                      'Save Game',
                      style: TextStyle(
                        color: Colors.blue,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Platinum Vault Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                    // TODO: Add check if vault is unlocked?
                    Navigator.pushNamed(context, '/platinumVault');
                },
                icon: Container(
                  width: 20,
                  height: 20,
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
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600, // Theme color
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                label: const Text('Platinum Vault'),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showResetConfirmation(context, gameState),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Reset Game'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumSection(GameState gameState) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.purple.shade300,
          width: 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade50,
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.purple.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Premium Features',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (!gameState.isPremium)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPremiumFeatureItem('Remove all ads from the game'),
                    _buildPremiumFeatureItem('Bonus +✦1500 Platinum'),
                    _buildPremiumFeatureItem('Exclusive profile customizations'),
                    _buildPremiumFeatureItem('More features coming soon!'),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showPremiumPurchaseDialog(context, gameState),
                        icon: const Icon(Icons.star),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 3,
                        ),
                        label: const Text(
                          'Get Premium (\$4.99)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thank you for supporting Empire Tycoon!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'You have access to all premium features:',
                      style: TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    _buildPremiumFeatureItem('Ad-free gameplay', enabled: true),
                    _buildPremiumFeatureItem('Bonus +✦1500 Platinum', enabled: true),
                    _buildPremiumFeatureItem('Exclusive profile customizations', enabled: true),
                    _buildPremiumFeatureItem('Premium customer support', enabled: true),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumFeatureItem(String text, {bool enabled = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.star,
            color: enabled ? Colors.green : Colors.purple.shade300,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: enabled ? Colors.black87 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Game?'),
        content: const Text(
          'Are you sure you want to reset your game? All progress will be lost!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<GameService>(context, listen: false).resetGame();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showPremiumPurchaseDialog(BuildContext context, GameState gameState) {
    // Log hashCode of the GameState instance passed to the dialog
    print("🅿️ Dialog builder using gameState hashCode: ${gameState.hashCode}");

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
            const Text('• More features coming soon!'),
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
              print("🅿️ Premium Purchase Button Pressed."); // Log before call
              // TODO: Implement actual purchase logic with Google Play Store
              // For now, just enable premium immediately

              // Log hashCode of the gameState instance used in onPressed
              print("🅿️ onPressed using gameState hashCode: ${gameState.hashCode}");

              // Option 1: Try accessing via Provider directly
              Provider.of<GameState>(context, listen: false).enablePremium();
              print("🅿️ Called Provider.of<GameState>.enablePremium()");

              Navigator.of(context).pop();

              // Play the sound effect AFTER enabling premium
              Provider.of<GameService>(context, listen: false)
                  .soundManager
                  .playPremiumPurchaseSound();

              // Snackbar is less important now with the dedicated notification, but keep for backup
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  content: Text('Premium features activated! +1500 Platinum!'),
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

  String _formatLastSavedTime(DateTime lastSaved) {
    final now = DateTime.now();
    final difference = now.difference(lastSaved);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return '${lastSaved.month}/${lastSaved.day}/${lastSaved.year}';
    }
  }
} 