import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/sound_manager.dart';
import '../services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/game_state.dart';
import '../services/game_service.dart';
import '../utils/number_formatter.dart';
import '../models/mogul_avatar.dart';
import '../models/premium_avatar.dart';
import '../widgets/platinum_crest_avatar.dart';
import '../widgets/premium_avatar_selector.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showAdvancedSettings = false;
  
  // Add cancellation support for async operations
  final Map<String, bool> _operationCancelled = {};
  
  // Track dialog state independently of widget lifecycle
  bool _isProcessingDialogShown = false;
  OverlayEntry? _currentOverlayEntry;
  
  // CLASS-LEVEL VARIABLES for purchase dialog management
  Timer? _purchaseProcessingTimeout;
  bool _purchaseDialogClosed = false;
  NavigatorState? _navigatorForPurchaseDialog;

  // User avatar options
  final List<String> _avatarOptions = [
    '👨‍💼', '👩‍💼', '👨‍💻', '👩‍💻', '👨‍🚀', '👩‍🚀', '👨‍🔧', '👩‍🔧',
    '😎', '🤓', '🧐', '🤠', '🥸', '🦹', '🦸', '🧙',
  ];
  
  // Add state to track if avatar selection is expanded
  bool _isAvatarSelectionExpanded = false;
  bool _isMogulAvatarSectionExpanded = false;
  bool _isPremiumAvatarSectionExpanded = false;
  
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
    // Cancel all ongoing operations
    _operationCancelled.forEach((key, value) {
      _operationCancelled[key] = true;
    });
    
    // Cancel purchase processing timeout
    _purchaseProcessingTimeout?.cancel();
    
    // Force close any remaining dialogs
    _forceCloseDialog();
    _forceClosePurchaseDialog();
    
    // Dispose the controller when the widget is disposed
    _usernameController.dispose();
    
    super.dispose();
  }

  /// Force close dialog using overlay instead of navigator
  void _forceCloseDialog() {
    if (_currentOverlayEntry != null) {
      try {
        _currentOverlayEntry!.remove();
        _currentOverlayEntry = null;
        _isProcessingDialogShown = false;
        print('✅ Dialog force closed via overlay');
      } catch (e) {
        print('🔴 Error force closing dialog: $e');
      }
    }
  }
  
  /// Force close purchase processing dialog with multiple fallback methods.
  /// Uses stored NavigatorState only (no BuildContext) so it is safe from dispose/async.
  void _forceClosePurchaseDialog() {
    if (_purchaseDialogClosed) {
      print('🟡 Purchase dialog already marked as closed');
      return;
    }
    
    print('🔴 FORCE CLOSE: Attempting to close purchase dialog');
    _purchaseDialogClosed = true;
    _purchaseProcessingTimeout?.cancel();
    
    final navigator = _navigatorForPurchaseDialog;
    _navigatorForPurchaseDialog = null;
    if (navigator == null) {
      print('🟢 FORCE CLOSE: No navigator stored, nothing to close');
      return;
    }
    
    bool dialogClosed = false;
    
    try {
      if (navigator.canPop()) {
        navigator.pop();
        dialogClosed = true;
        print('✅ FORCE CLOSE: Dialog closed via Navigator.pop()');
      }
    } catch (e) {
      print('🔴 FORCE CLOSE: Navigator.pop() failed: $e');
    }
    
    if (!dialogClosed) {
      try {
        navigator.popUntil((route) => route.isFirst);
        dialogClosed = true;
        print('✅ FORCE CLOSE: Dialog closed via Navigator.popUntil()');
      } catch (e) {
        print('🔴 FORCE CLOSE: Navigator.popUntil() failed: $e');
      }
    }
    
    if (!dialogClosed) {
      try {
        navigator.maybePop();
        print('✅ FORCE CLOSE: Attempted Navigator.maybePop() as final fallback');
      } catch (e) {
        print('🔴 FORCE CLOSE: Navigator.maybePop() failed: $e');
      }
    }
    
    print('🟢 FORCE CLOSE: Purchase dialog cleanup completed');
  }

  /// Show processing dialog using overlay to avoid context issues
  void _showProcessingDialog(String message) {
    if (_isProcessingDialogShown) {
      _forceCloseDialog(); // Close any existing dialog first
    }
    
    try {
      _currentOverlayEntry = OverlayEntry(
        builder: (context) => Material(
          color: Colors.black54,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(message),
                ],
              ),
            ),
          ),
        ),
      );
      
      if (mounted) {
        Overlay.of(context).insert(_currentOverlayEntry!);
        _isProcessingDialogShown = true;
        print('✅ Processing dialog shown via overlay');
      }
    } catch (e) {
      print('🔴 Error showing processing dialog: $e');
    }
  }

  /// Close processing dialog safely
  void _closeProcessingDialog() {
    if (_currentOverlayEntry != null && _isProcessingDialogShown) {
      try {
        _currentOverlayEntry!.remove();
        _currentOverlayEntry = null;
        _isProcessingDialogShown = false;
        print('✅ Processing dialog closed successfully');
      } catch (e) {
        print('🔴 Error closing processing dialog: $e');
      }
    }
  }

  /// Show result message using overlay to avoid context issues
  void _showResultMessage(String message, bool isSuccess) {
    if (!mounted) return;
    
    try {
      final resultOverlay = OverlayEntry(
        builder: (context) => Positioned(
          top: 100,
          left: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSuccess ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isSuccess ? Icons.check_circle : Icons.error,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      
      Overlay.of(context).insert(resultOverlay);
      
      // Auto-remove after 4 seconds
      Timer(const Duration(seconds: 4), () {
        try {
          resultOverlay.remove();
        } catch (e) {
          print('🔴 Error removing result overlay: $e');
        }
      });
      
      print('✅ Result message shown via overlay');
    } catch (e) {
      print('🔴 Error showing result message: $e');
    }
  }

  /// Test a successful purchase scenario with overlay-based UI
  void _testSuccessfulPurchase(BuildContext context, GameState gameState) async {
    // Create unique operation ID
    final operationId = 'test_success_${DateTime.now().millisecondsSinceEpoch}';
    _operationCancelled[operationId] = false;
    
    try {
      // Early exit if widget is disposed
      if (!mounted) return;
      
      final gameService = Provider.of<GameService>(context, listen: false);
      
      // Close any existing dialogs first
      try {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        print('🔴 Error closing initial dialog: $e');
      }
      
      // Show processing dialog using overlay
      _showProcessingDialog('Simulating successful purchase...');
      
      // Check cancellation before async operation
      if (_operationCancelled[operationId]!) {
        _closeProcessingDialog();
        return;
      }
      
      // Simulate the purchase
      final result = await gameService.debugSimulatePremiumPurchase(
        shouldFail: false,
      );
      
      // Check if operation was cancelled while running
      if (_operationCancelled[operationId]!) {
        _closeProcessingDialog();
        return;
      }
      
      // Always close processing dialog first
      _closeProcessingDialog();
      
      // Wait a brief moment for dialog to close
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Check cancellation before UI updates
      if (_operationCancelled[operationId]!) return;
      
             if (mounted) {
         if (result['success'] == true) {
           // CRITICAL: Enable premium features first
           gameState.enablePremium();
           
           // Save the game immediately to persist premium status
           gameService.saveGame();
           
           // Show success message using overlay
           _showResultMessage(
             '✅ Test Purchase Successful! Premium Activated!',
             true,
           );
        } else {
          // Show error message using overlay
          _showResultMessage(
            '❌ Test Purchase Failed: ${result['error']}',
            false,
          );
        }
      }
    } catch (e) {
      print('🔴 Error in _testSuccessfulPurchase: $e');
      
      // Always ensure dialog is closed
      _closeProcessingDialog();
      
      if (mounted && !_operationCancelled[operationId]!) {
        _showResultMessage('❌ Debug test failed: $e', false);
      }
    } finally {
      // Clean up operation tracking
      _operationCancelled.remove(operationId);
    }
  }

  /// Test a failed purchase scenario with overlay-based UI
  void _testFailedPurchase(BuildContext context, GameState gameState) async {
    // Create unique operation ID
    final operationId = 'test_failure_${DateTime.now().millisecondsSinceEpoch}';
    _operationCancelled[operationId] = false;
    
    try {
      // Early exit if widget is disposed
      if (!mounted) return;
      
      final gameService = Provider.of<GameService>(context, listen: false);
      
      // Close any existing dialogs first
      try {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        print('🔴 Error closing initial dialog: $e');
      }
      
      // Show processing dialog using overlay
      _showProcessingDialog('Simulating failed purchase...');
      
      // Check cancellation before async operation
      if (_operationCancelled[operationId]!) {
        _closeProcessingDialog();
        return;
      }
      
      // Simulate a failed purchase
      final result = await gameService.debugSimulatePremiumPurchase(
        shouldFail: true,
      );
      
      // Check if operation was cancelled while running
      if (_operationCancelled[operationId]!) {
        _closeProcessingDialog();
        return;
      }
      
      // Always close processing dialog first
      _closeProcessingDialog();
      
      // Wait a brief moment for dialog to close
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Check cancellation before UI updates
      if (_operationCancelled[operationId]!) return;
      
      if (mounted) {
        final success = result['success'] == true;
        final message = success 
          ? '❌ Expected Failure Test Failed (this is bad!)' 
          : '✅ Failure Test Passed: ${result['error']}';
        
        _showResultMessage(message, !success);
      }
    } catch (e) {
      print('🔴 Error in _testFailedPurchase: $e');
      
      // Always ensure dialog is closed
      _closeProcessingDialog();
      
      if (mounted && !_operationCancelled[operationId]!) {
        _showResultMessage('❌ Debug test error: $e', false);
      }
    } finally {
      // Clean up operation tracking
      _operationCancelled.remove(operationId);
    }
  }

  /// Test the verification logic with overlay-based UI
  void _testVerificationLogic(BuildContext context) async {
    // Create unique operation ID
    final operationId = 'test_verification_${DateTime.now().millisecondsSinceEpoch}';
    _operationCancelled[operationId] = false;
    
    try {
      // Early exit if widget is disposed
      if (!mounted) return;
      
      final gameService = Provider.of<GameService>(context, listen: false);
      
      // Close any existing dialogs first
      try {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        print('🔴 Error closing initial dialog: $e');
      }
      
      // Show processing dialog using overlay
      _showProcessingDialog('Running verification tests...');
      
      // Check cancellation before async operation
      if (_operationCancelled[operationId]!) {
        _closeProcessingDialog();
        return;
      }
      
      final results = await gameService.debugTestPurchaseVerification();
      
      // Check if operation was cancelled while running
      if (_operationCancelled[operationId]!) {
        _closeProcessingDialog();
        return;
      }
      
      // Always close processing dialog first
      _closeProcessingDialog();
      
      // Wait a brief moment for dialog to close
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Check cancellation before UI updates
      if (_operationCancelled[operationId]!) return;
      
      // Show results in a proper dialog (not overlay for this complex content)
      if (mounted) {
        try {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.security, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(child: Text('Verification Test Results')),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (results.containsKey('error'))
                      Text(
                        'Error: ${results['error']}',
                        style: const TextStyle(color: Colors.red),
                      )
                    else ...[
                      Text(
                        'Overall Result: ${results['all_tests_passed'] == true ? '✅ ALL PASSED' : '❌ SOME FAILED'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: results['all_tests_passed'] == true ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Individual Tests:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...results.entries.where((e) => e.key != 'all_tests_passed' && e.key != 'error').map((entry) =>
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(
                                entry.value == true ? Icons.check : Icons.close,
                                color: entry.value == true ? Colors.green : Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.key.replaceAll('_', ' ').toUpperCase(),
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    try {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    } catch (e) {
                      print('🔴 Error closing results dialog: $e');
                    }
                  },
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        } catch (e) {
          print('🔴 Error showing results dialog: $e');
          _showResultMessage('Verification tests completed - check logs', true);
        }
      }
    } catch (e) {
      print('🔴 Error in _testVerificationLogic: $e');
      
      // Always ensure dialog is closed
      _closeProcessingDialog();
      
      if (mounted && !_operationCancelled[operationId]!) {
        _showResultMessage('Test failed: $e', false);
      }
    } finally {
      // Clean up operation tracking
      _operationCancelled.remove(operationId);
    }
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
                
                _buildPremiumSection(gameState),
                
                const SizedBox(height: 20),
                
                _buildSettingsSection(gameState),
                
                const SizedBox(height: 30),
                
                _buildFeedbackSection(),
                
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
      elevation: gameState.isPlatinumCrestUnlocked ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: gameState.isPlatinumCrestUnlocked 
            ? BorderSide(
                color: const Color(0xFFE5E4E2),
                width: 2.0,
              )
            : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: gameState.isPlatinumCrestUnlocked
              ? LinearGradient(
                  colors: [
                    Colors.grey.shade100,
                    Colors.white,
                    Colors.grey.shade50,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: gameState.isPlatinumCrestUnlocked
              ? [
                  BoxShadow(
                    color: const Color(0xFFE5E4E2).withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: -5,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with premium styling if crest is active
              Container(
                decoration: gameState.isPlatinumCrestUnlocked
                    ? BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFE5E4E2).withOpacity(0.7),
                            Colors.white,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                padding: gameState.isPlatinumCrestUnlocked
                    ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                    : EdgeInsets.zero,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (gameState.isPlatinumCrestUnlocked)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.verified,
                              size: 22,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        Text(
                          'My Profile',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: gameState.isPlatinumCrestUnlocked ? 0.5 : 0,
                            color: gameState.isPlatinumCrestUnlocked
                                ? Colors.grey.shade800
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // DEBUG TOOLBAR (Debug Mode Only) - Separate row to prevent overflow
              if (kDebugMode)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      // Platinum Crest Toggle
                      GestureDetector(
                        onTap: () {
                          gameState.isPlatinumCrestUnlocked = !gameState.isPlatinumCrestUnlocked;
                          Provider.of<GameService>(context, listen: false).saveGame();
                          // ScaffoldMessenger.of(context).showSnackBar(
                          //   SnackBar(
                          //     content: Text(
                          //       gameState.isPlatinumCrestUnlocked 
                          //         ? 'Platinum Crest: ENABLED' 
                          //         : 'Platinum Crest: DISABLED'
                          //     ),
                          //     duration: const Duration(seconds: 1),
                          //   ),
                          // );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: gameState.isPlatinumCrestUnlocked 
                              ? const Color(0xFFE5E4E2)
                              : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shield_moon,
                                size: 14,
                                color: gameState.isPlatinumCrestUnlocked 
                                  ? Colors.grey.shade900
                                  : Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Crest',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: gameState.isPlatinumCrestUnlocked 
                                    ? Colors.grey.shade900
                                    : Colors.grey.shade500,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Emergency Premium Activation
                      if (!gameState.isPremium)
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Emergency Premium Activation'),
                                content: const Text(
                                  'This will manually activate Premium features. '
                                  'Only use this if you have already purchased Premium '
                                  'but it was not activated due to a technical issue.\n\n'
                                  'Are you sure you want to proceed?'
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      gameState.enablePremium();
                                      Provider.of<GameService>(context, listen: false).saveGame();
                                      // ScaffoldMessenger.of(context).showSnackBar(
                                      //   const SnackBar(
                                      //     backgroundColor: Colors.green,
                                      //     content: Row(
                                      //       children: [
                                      //         Icon(Icons.check_circle, color: Colors.white),
                                      //         SizedBox(width: 8),
                                      //         Text('Premium manually activated! +1500 Platinum!'),
                                      //       ],
                                      //     ),
                                      //     duration: Duration(seconds: 4),
                                      //   ),
                                      // );
                                    },
                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    child: const Text('Activate Premium'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.emergency,
                                  size: 14,
                                  color: Colors.red.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Fix Premium',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      // Billing Debug
                      GestureDetector(
                        onTap: () {
                          final gameService = Provider.of<GameService>(context, listen: false);
                          final billingService = gameService;
                          
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Billing Debug Info'),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Premium Available: ${billingService.isPremiumAvailable()}'),
                                    Text('Premium Price: ${billingService.getPremiumPrice()}'),
                                    Text('Current Premium Status: ${gameState.isPremium}'),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Recent changes:\n'
                                      '• Relaxed purchase verification\n'
                                      '• Removed overly strict security checks\n'
                                      '• Added immediate game saving after purchase\n'
                                      '• Enhanced debug logging',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bug_report,
                                size: 14,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Billing Debug',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Test Purchase
                      GestureDetector(
                        onTap: () {
                          _showDebugPurchaseTestDialog(context, gameState);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shopping_cart,
                                size: 14,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Test Purchase',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 20),
              
              Row(
                children: [
                  // Replace the avatar container with PlatinumCrestAvatar
                  PlatinumCrestAvatar(
                    showCrest: gameState.isPlatinumCrestUnlocked,
                    userAvatar: currentAvatar,
                    mogulAvatarId: gameState.selectedMogulAvatarId,
                    premiumAvatarId: gameState.selectedPremiumAvatarId,
                    size: 80.0,
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
                            color: gameState.isPlatinumCrestUnlocked
                                ? const Color(0xFFE5E4E2)
                                : Colors.blue.shade200,
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
                                // Set the standard avatar emoji
                                gameState.userAvatar = avatar;
                                // Clear both Premium and Mogul Avatar selections to avoid conflicts
                                gameState.selectedPremiumAvatarId = null;
                                gameState.selectedMogulAvatarId = null;
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
                      
                      // Add premium avatars section if premium is purchased
                      if (gameState.isPremium) ...[  
                        const SizedBox(height: 20),
                        
                        // Premium Avatars Section Header with Purple accent
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.purple.shade700.withOpacity(0.8),
                                Colors.purple.shade300.withOpacity(0.8),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.auto_awesome, color: Colors.white),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Premium Avatars',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          offset: Offset(1, 1),
                                          blurRadius: 2,
                                          color: Color(0x80000000),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: Icon(
                                  _isPremiumAvatarSectionExpanded 
                                    ? Icons.expand_less 
                                    : Icons.expand_more,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPremiumAvatarSectionExpanded = !_isPremiumAvatarSectionExpanded;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        // Premium Avatars Section Content (collapsible)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: _isPremiumAvatarSectionExpanded ? null : 0,
                          clipBehavior: Clip.antiAlias,
                          decoration: const BoxDecoration(),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: _isPremiumAvatarSectionExpanded ? 1.0 : 0.0,
                            child: _isPremiumAvatarSectionExpanded ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 12),
                                
                                // Premium Avatar Selector
                                PremiumAvatarSelector(
                                  isPremium: gameState.isPremium,
                                  selectedPremiumAvatarId: gameState.selectedPremiumAvatarId,
                                  onAvatarSelected: (avatarId) {
                                    setState(() {
                                      // Get the premium avatar emoji for the selected avatar
                                      final avatar = getPremiumAvatars().firstWhere((a) => a.id == avatarId);
                                      // Set the selected Premium Avatar ID
                                      gameState.selectedPremiumAvatarId = avatarId;
                                      // Clear any Mogul Avatar selection to avoid conflicts
                                      gameState.selectedMogulAvatarId = null;
                                      // Update the user's avatar emoji
                                      gameState.userAvatar = avatar.emoji;
                                    });
                                    
                                    // Save the game to persist the avatar choice
                                    Provider.of<GameService>(context, listen: false).saveGame();
                                  },
                                ),
                              ],
                            ) : const SizedBox(),
                          ),
                        ),
                      ],
                      
                      // Add mogul avatars section if unlocked
                      if (gameState.isMogulAvatarsUnlocked) ...[
                        const SizedBox(height: 20),
                        
                        // Mogul Avatars Section Header with Gold accent
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber.shade700.withOpacity(0.8),
                                Colors.amber.shade300.withOpacity(0.8),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.stars, color: Colors.white),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Platinum Mogul Avatars',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          offset: Offset(1, 1),
                                          blurRadius: 2,
                                          color: Color(0x80000000),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: Icon(
                                  _isMogulAvatarSectionExpanded 
                                    ? Icons.expand_less 
                                    : Icons.expand_more,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isMogulAvatarSectionExpanded = !_isMogulAvatarSectionExpanded;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        // Mogul Avatars Section Content (collapsible)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: _isMogulAvatarSectionExpanded ? null : 0,
                          clipBehavior: Clip.antiAlias,
                          decoration: const BoxDecoration(),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: _isMogulAvatarSectionExpanded ? 1.0 : 0.0,
                            child: _isMogulAvatarSectionExpanded ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 12),
                                
                                // Display mogul avatars in a grid
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    childAspectRatio: 1,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemCount: getMogulAvatars().length,
                                  itemBuilder: (context, index) {
                                    final mogulAvatar = getMogulAvatars()[index];
                                    final isSelected = gameState.selectedMogulAvatarId == mogulAvatar.id;
                                    
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          // Set the selected Mogul Avatar ID
                                          gameState.selectedMogulAvatarId = mogulAvatar.id;
                                          // Clear any Premium Avatar selection to avoid conflicts
                                          gameState.selectedPremiumAvatarId = null;
                                          // Update the user's avatar emoji
                                          gameState.userAvatar = mogulAvatar.emoji;
                                        });
                                        
                                        // Save the game to persist the avatar choice
                                        Provider.of<GameService>(context, listen: false).saveGame();
                                      },
                                      child: Tooltip(
                                        message: mogulAvatar.description,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: isSelected ? 
                                              LinearGradient(
                                                colors: [
                                                  Colors.amber.shade200,
                                                  Colors.amber.shade100,
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
                                              color: isSelected ? Colors.amber.shade600 : Colors.grey.shade300,
                                              width: 2,
                                            ),
                                            boxShadow: isSelected ? [
                                              BoxShadow(
                                                color: Colors.amber.withOpacity(0.3),
                                                blurRadius: 5,
                                                spreadRadius: 1,
                                              ),
                                            ] : null,
                                          ),
                                          child: Column(
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
                                                  child: Image.asset(
                                                    mogulAvatar.imagePath,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Center(
                                                        child: Text(
                                                          mogulAvatar.emoji,
                                                          style: const TextStyle(fontSize: 24),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                mogulAvatar.name,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                  color: isSelected ? Colors.amber.shade800 : Colors.grey.shade700,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ) : const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ],
                  ) : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
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
            Consumer<AuthService>(
              builder: (context, authService, child) {
                // Sync AuthService state with GameState on each build
                if (authService.isSignedIn && !gameState.isGooglePlayConnected) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    gameState.isGooglePlayConnected = true;
                    gameState.googlePlayPlayerId = authService.playerId;
                    gameState.googlePlayDisplayName = authService.playerName;
                    gameState.googlePlayAvatarUrl = authService.playerAvatarUrl;
                    gameState.lastCloudSync = DateTime.now();
                    Provider.of<GameService>(context, listen: false).saveGame();
                  });
                }
                
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: authService.isInitialized 
                            ? (authService.isSignedIn 
                                ? () async {
                                    // Sign out
                                    await authService.signOut();
                                    // Update game state
                                    gameState.isGooglePlayConnected = false;
                                    gameState.googlePlayPlayerId = null;
                                    gameState.googlePlayDisplayName = null;
                                    gameState.googlePlayAvatarUrl = null;
                                    // Save the changes
                                    Provider.of<GameService>(context, listen: false).saveGame();
                                  }
                                : () async {
                                    // Show loading state
                                    // ScaffoldMessenger.of(context).showSnackBar(
                                    //   const SnackBar(
                                    //     content: Row(
                                    //       children: [
                                    //         SizedBox(
                                    //           width: 20,
                                    //           height: 20,
                                    //           child: CircularProgressIndicator(strokeWidth: 2),
                                    //         ),
                                    //         SizedBox(width: 16),
                                    //         Text('Signing in to Google Play Games...'),
                                    //       ],
                                    //     ),
                                    //     duration: Duration(seconds: 10),
                                    //   ),
                                    // );
                                    
                                    // Sign in
                                    final success = await authService.signIn();
                                    
                                    // Clear the loading message
                                    ScaffoldMessenger.of(context).clearSnackBars();
                                    
                                    if (success) {
                                      // Update game state
                                      gameState.isGooglePlayConnected = true;
                                      gameState.googlePlayPlayerId = authService.playerId;
                                      gameState.googlePlayDisplayName = authService.playerName;
                                      gameState.googlePlayAvatarUrl = authService.playerAvatarUrl;
                                      gameState.lastCloudSync = DateTime.now();
                                      // Save the changes
                                      Provider.of<GameService>(context, listen: false).saveGame();
                                      
                                      // Show success message
                                      // ScaffoldMessenger.of(context).showSnackBar(
                                      //   SnackBar(
                                      //     content: Row(
                                      //       children: [
                                      //         const Icon(Icons.check_circle, color: Colors.white),
                                      //         const SizedBox(width: 8),
                                      //         Text('Successfully signed in to Google Play Games!${authService.playerName != null ? ' Welcome, ${authService.playerName}!' : ''}'),
                                      //       ],
                                      //     ),
                                      //     backgroundColor: Colors.green,
                                      //     duration: const Duration(seconds: 4),
                                      //   ),
                                      // );
                                    } else {
                                      // Show detailed error message
                                      final errorMsg = authService.lastError ?? 'Failed to sign in to Google Play Games';
                                      // ScaffoldMessenger.of(context).showSnackBar(
                                      //   SnackBar(
                                      //     content: Row(
                                      //       children: [
                                      //         const Icon(Icons.error, color: Colors.white),
                                      //         const SizedBox(width: 8),
                                      //         Expanded(child: Text(errorMsg)),
                                      //       ],
                                      //     ),
                                      //     backgroundColor: Colors.red,
                                      //     duration: const Duration(seconds: 6),
                                      //     action: SnackBarAction(
                                      //       label: 'Debug Info',
                                      //       textColor: Colors.white,
                                      //       onPressed: () {
                                      //         // Show debug information
                                      //         showDialog(
                                      //           context: context,
                                      //           builder: (context) => AlertDialog(
                                      //             title: const Text('Debug Information'),
                                      //             content: SingleChildScrollView(
                                      //               child: Text(
                                      //                 authService.getDiagnosticInfo().entries
                                      //                     .map((e) => '${e.key}: ${e.value}')
                                      //                     .join('\n'),
                                      //                 style: const TextStyle(fontFamily: 'monospace'),
                                      //               ),
                                      //             ),
                                      //             actions: [
                                      //               TextButton(
                                      //                 onPressed: () => Navigator.of(context).pop(),
                                      //                 child: const Text('Close'),
                                      //               ),
                                      //             ],
                                      //           ),
                                      //         );
                                      //       },
                                      //     ),
                                      //   ),
                                      // );
                                    }
                                  }
                              )
                            : null, // Disabled while initializing
                        icon: Icon(
                          authService.isSignedIn ? Icons.logout : Icons.games,
                          color: Colors.white,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: authService.isSignedIn ? Colors.orange : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        label: Text(
                          authService.isInitialized 
                              ? (authService.isSignedIn 
                                  ? 'Sign out from Google Play Games${authService.playerName != null ? ' (${authService.playerName})' : ''}'
                                  : 'Sign in with Google Play Games')
                              : 'Initializing...',
                        ),
                      ),
                    ),
                    
                    // Show signed-in user info if authenticated
                    if (authService.isSignedIn) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          border: Border.all(color: Colors.green.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Google Play Games Connected',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            if (authService.playerName != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Player: ${authService.playerName}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                            if (authService.playerId != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.tag, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    'ID: ${authService.playerId}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Leaderboard: compact, fun entry (signed in only)
                      const SizedBox(height: 12),
                      Material(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () async {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Updating your rank…'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                            await authService.submitHighestNetWorth(gameState.totalLifetimeNetWorth);
                            if (!context.mounted) return;
                            await authService.showHighestNetWorthLeaderboard();
                            if (!context.mounted) return;
                            if (authService.lastError != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(authService.lastError!),
                                  backgroundColor: Colors.red.shade700,
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Icon(Icons.emoji_events, color: Colors.amber.shade700, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Highest Net Worth',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber.shade900,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'See where you rank among tycoons',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.amber.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: Colors.amber.shade700, size: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    
                    // Show error message if there's one
                    if (authService.lastError != null && !authService.isSignedIn) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red.shade700, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authService.lastError!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            // Cloud save status
            Consumer<AuthService>(
              builder: (context, authService, child) {
                return Row(
                  children: [
                    Icon(
                      authService.isSignedIn ? Icons.cloud_done : Icons.cloud_off,
                      color: authService.isSignedIn ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Cloud Save:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      authService.isSignedIn ? 'Connected' : 'Not connected',
                      style: TextStyle(
                        color: authService.isSignedIn ? Colors.green : Colors.grey.shade600,
                      ),
                    ),
                    if (authService.isSignedIn && authService.playerName != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${authService.playerName})',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                );
              },
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

            // Net Worth Ticker visibility toggle (button centered like others; info icon to the side)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      gameState.setNetWorthTickerVisible(!gameState.showNetWorthTicker);
                    },
                    icon: Icon(
                      gameState.showNetWorthTicker ? Icons.visibility : Icons.visibility_off,
                      color: gameState.showNetWorthTicker ? Colors.teal : Colors.grey,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: gameState.showNetWorthTicker ? Colors.teal : Colors.grey,
                      ),
                    ),
                    label: Text(
                      gameState.showNetWorthTicker
                          ? 'Net Worth Ticker: VISIBLE'
                          : 'Net Worth Ticker: HIDDEN',
                      style: TextStyle(
                        color: gameState.showNetWorthTicker ? Colors.teal : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 22),
                  color: gameState.showNetWorthTicker ? Colors.teal : Colors.grey,
                  tooltip: 'What is the Net Worth Ticker?',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) {
                        return AlertDialog(
                          title: const Text('Net Worth Ticker'),
                          content: const Text(
                            'The Net Worth Ticker is a draggable crown widget that shows your lifetime net worth.\n\n'
                            '- Drag it anywhere on the screen to position it.\n'
                            '- Tap the crown to expand or collapse the display.\n'
                            '- Double-tap the ticker to temporarily enlarge it for easier reading.\n\n'
                            'You can hide it here if you prefer a cleaner HUD.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Got it'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            Consumer<GameService>(
              builder: (context, gameService, child) {
                // Get sound and haptics enabled state from the SoundManager singleton
                final soundManager = SoundManager();
                final bool soundEnabled = soundManager.isSoundEnabled;
                final bool hapticsEnabled = soundManager.isHapticsEnabled;

                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          // Toggle sound using the SoundManager singleton
                          await soundManager.toggleSound(!soundEnabled);
                          // Force rebuild to update icon/text
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
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await soundManager.setHapticsEnabled(!hapticsEnabled);
                          setState(() {});
                        },
                        icon: Icon(
                          Icons.vibration,
                          color: hapticsEnabled ? Colors.orange : Colors.grey,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: hapticsEnabled ? Colors.orange : Colors.grey,
                          ),
                        ),
                        label: Text(
                          hapticsEnabled ? 'Haptics: ON' : 'Haptics: OFF',
                          style: TextStyle(
                            color: hapticsEnabled ? Colors.orange : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // Notification Settings Section
            Consumer<GameService>(
              builder: (context, gameService, child) {
                return Column(
                  children: [
                    // Offline Income Notifications Toggle
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          bool currentSetting = gameService.offlineIncomeNotificationsEnabled;
                          bool newSetting = !currentSetting;
                          
                          if (newSetting) {
                            // If enabling notifications, request permission first (force request)
                            await gameService.requestNotificationPermissions(context, forceRequest: true);
                          }
                          
                          await gameService.setOfflineIncomeNotificationsEnabled(newSetting);
                          setState(() {}); // Force rebuild to update UI
                        },
                        icon: Icon(
                          gameService.offlineIncomeNotificationsEnabled 
                              ? Icons.notifications_active 
                              : Icons.notifications_off,
                          color: gameService.offlineIncomeNotificationsEnabled 
                              ? Colors.blue 
                              : Colors.grey,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: gameService.offlineIncomeNotificationsEnabled 
                                ? Colors.blue 
                                : Colors.grey,
                          ),
                        ),
                        label: Text(
                          gameService.offlineIncomeNotificationsEnabled 
                              ? 'Offline Income Alerts: ON' 
                              : 'Offline Income Alerts: OFF',
                          style: TextStyle(
                            color: gameService.offlineIncomeNotificationsEnabled 
                                ? Colors.blue 
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Business Upgrade Notifications Toggle
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          bool currentSetting = gameService.businessUpgradeNotificationsEnabled;
                          bool newSetting = !currentSetting;
                          
                          if (newSetting) {
                            // If enabling notifications, request permission first (force request)
                            await gameService.requestNotificationPermissions(context, forceRequest: true);
                          }
                          
                          await gameService.setBusinessUpgradeNotificationsEnabled(newSetting);
                          setState(() {}); // Force rebuild to update UI
                        },
                        icon: Icon(
                          gameService.businessUpgradeNotificationsEnabled 
                              ? Icons.business_center 
                              : Icons.business_center_outlined,
                          color: gameService.businessUpgradeNotificationsEnabled 
                              ? Colors.green 
                              : Colors.grey,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: gameService.businessUpgradeNotificationsEnabled 
                                ? Colors.green 
                                : Colors.grey,
                          ),
                        ),
                        label: Text(
                          gameService.businessUpgradeNotificationsEnabled 
                              ? 'Upgrade Alerts: ON' 
                              : 'Upgrade Alerts: OFF',
                          style: TextStyle(
                            color: gameService.businessUpgradeNotificationsEnabled 
                                ? Colors.green 
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Debug-only diagnostic tools
            if (kDebugMode) ...[
              const SizedBox(height: 16),
              
              // Debug Section Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bug_report, color: Colors.purple, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'DEBUG TOOLS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Audio System Diagnostic Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    debugPrint('🔍 User requested audio system diagnostic');
                    
                    final soundManager = SoundManager();
                    final isHealthy = await soundManager.performAudioDiagnostic(verbose: true);
                    
                    if (mounted) {
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   SnackBar(
                      //     content: Text(isHealthy 
                      //       ? 'Audio system is healthy ✅ - check console for details'
                      //       : 'Audio system needs recovery ⚠️ - check console for details'),
                      //     duration: const Duration(seconds: 3),
                      //     backgroundColor: isHealthy ? Colors.green : Colors.orange,
                      //   ),
                      // );
                    }
                  },
                  icon: const Icon(Icons.volume_up, color: Colors.purple),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: Colors.purple),
                  ),
                  label: const Text(
                    'Audio System Diagnostic',
                    style: TextStyle(color: Colors.purple, fontSize: 12),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Emergency Audio Recovery Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    debugPrint('🚨 User requested emergency audio recovery');
                    
                    final soundManager = SoundManager();
                    await soundManager.emergencyAudioRecovery();
                    
                    if (mounted) {
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   const SnackBar(
                      //     content: Text('Emergency audio recovery completed 🔧'),
                      //     duration: Duration(seconds: 3),
                      //     backgroundColor: Colors.orange,
                      //   ),
                      // );
                    }
                  },
                  icon: const Icon(Icons.healing, color: Colors.red),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: Colors.red),
                  ),
                  label: const Text(
                    'Emergency Audio Recovery',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ),
            ],

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
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   const SnackBar(
                      //     content: Text('Saving game...'),
                      //     duration: Duration(seconds: 1),
                      //   ),
                      // );

                      try {
                        await gameService.saveGame();
                        
                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   const SnackBar(
                        //     content: Text('Game saved successfully!'),
                        //     backgroundColor: Colors.green,
                        //   ),
                        // );
                      } catch (e) {
                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   SnackBar(
                        //     content: Text('Failed to save game: $e'),
                        //     backgroundColor: Colors.red,
                        //   ),
                        // );
                      }
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
                    Navigator.pushNamed(context, '/platinum_vault');
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
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: gameState.isPremium 
              ? Colors.amber.shade400.withOpacity(0.6)
              : Colors.purple.shade300,
          width: gameState.isPremium ? 2.5 : 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gameState.isPremium 
                ? [
                    const Color(0xFFF8F5FF),
                    const Color(0xFFFFF8E1),
                    Colors.white,
                  ]
                : [
                    Colors.purple.shade50,
                    const Color(0xFFF3E5F5),
                    Colors.white,
                  ],
            stops: gameState.isPremium ? [0.0, 0.5, 1.0] : [0.0, 0.7, 1.0],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: gameState.isPremium 
              ? [
                  BoxShadow(
                    color: Colors.amber.shade200.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  gradient: gameState.isPremium
                      ? LinearGradient(
                          colors: [
                            Colors.amber.shade600,
                            Colors.amber.shade400,
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            Colors.purple.shade600,
                            Colors.purple.shade400,
                          ],
                        ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (gameState.isPremium ? Colors.amber.shade400 : Colors.purple.shade400)
                          .withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      gameState.isPremium ? Icons.workspace_premium : Icons.star,
                      color: Colors.white,
                      size: 24,
                      shadows: const [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      gameState.isPremium ? 'Premium Active' : 'Premium Features',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    if (gameState.isPremium) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'OWNED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              if (!gameState.isPremium)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enhanced Feature List with Better Visual Hierarchy
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.purple.shade100,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildEnhancedPremiumFeatureItem(
                            'Remove all ads from the game',
                            Icons.block,
                            'Enjoy uninterrupted gameplay',
                          ),
                          const SizedBox(height: 8),
                          _buildEnhancedPremiumFeatureItem(
                            'Bonus +✦1500 Platinum',
                            Icons.diamond,
                            'Instant boost to accelerate progress',
                          ),
                          const SizedBox(height: 8),
                          _buildEnhancedPremiumFeatureItem(
                            'Exclusive profile customizations',
                            Icons.palette,
                            'Stand out with premium avatars',
                          ),
                          const SizedBox(height: 8),
                          _buildEnhancedPremiumFeatureItem(
                            'More features coming soon!',
                            Icons.auto_awesome,
                            'Future updates included',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    const SizedBox(height: 16),

                    // Show restore premium button (always available, unless already used)
                    if (!gameState.hasUsedPremiumRestore) ...[
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade600,
                              Colors.orange.shade700,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.shade400.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showRestorePremiumDialog(context, gameState),
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.restore,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Restore Premium',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        'Already purchased? Restore here',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                    ],

                    // Enhanced Purchase Button with Better Call-to-Action
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade600,
                            Colors.purple.shade700,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.shade400.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showPremiumPurchaseDialog(context, gameState),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Get Premium',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      '\$4.99 • One-time payment',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                // Enhanced Post-Purchase Thank You Section
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.shade50,
                        Colors.orange.shade50,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.amber.shade400,
                                  Colors.orange.shade400,
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Thank you for supporting Empire Tycoon!',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'You have access to all premium features:',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildEnhancedPremiumFeatureItem('Ad-free gameplay', Icons.verified, null, enabled: true),
                      const SizedBox(height: 6),
                      _buildEnhancedPremiumFeatureItem('Bonus +✦1500 Platinum', Icons.verified, null, enabled: true),
                      const SizedBox(height: 6),
                      _buildEnhancedPremiumFeatureItem('Exclusive profile customizations', Icons.verified, null, enabled: true),
                      const SizedBox(height: 6),
                      _buildEnhancedPremiumFeatureItem('Premium customer support', Icons.verified, null, enabled: true),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedPremiumFeatureItem(
    String text, 
    IconData iconData, 
    String? subtitle, 
    {bool enabled = false}
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: enabled 
                  ? Colors.green.shade100 
                  : Colors.purple.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              enabled ? Icons.verified : iconData,
              color: enabled ? Colors.green.shade600 : Colors.purple.shade600,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: enabled ? Colors.black87 : Colors.black87,
                  ),
                ),
                if (subtitle != null && !enabled) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
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
            const Text('• Exclusive profile customizations'),
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
            onPressed: () async {
              print("🅿️ Premium Purchase Button Pressed.");
              
              final gameService = Provider.of<GameService>(context, listen: false);
              
              // Check if billing is available
              if (!gameService.isPremiumAvailable()) {
                Navigator.of(context).pop();
                // ScaffoldMessenger.of(context).showSnackBar(
                //   const SnackBar(
                //     content: Text('Purchase not available. Please try again later.'),
                //     backgroundColor: Colors.red,
                //     duration: Duration(seconds: 3),
                //   ),
                // );
                return;
              }
              
              // Close dialog first to avoid UI conflicts
              Navigator.of(context).pop();
              
              // Reset class-level dialog state
              _purchaseDialogClosed = false;
              _purchaseProcessingTimeout?.cancel();
              
              // Capture navigator before showing dialog so force-close can run without context
              _navigatorForPurchaseDialog = Navigator.of(context);
              // Show loading indicator with robust timeout protection
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processing purchase...'),
                    ],
                  ),
                  // Add manual close button as emergency exit
                  actions: [
                    TextButton(
                      onPressed: () {
                        print('🔴 USER: Manual dialog close requested');
                        _forceClosePurchaseDialog();
                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   const SnackBar(
                        //     backgroundColor: Colors.orange,
                        //     content: Text('Purchase dialog closed manually. If payment was successful, premium features should activate automatically.'),
                        //     duration: Duration(seconds: 5),
                        //   ),
                        // );
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              );
              
              // Set up robust timeout using class-level variables
              _purchaseProcessingTimeout = Timer(const Duration(seconds: 30), () {
                if (!_purchaseDialogClosed && mounted) {
                  print('🔴 TIMEOUT: Processing dialog has been open for 30 seconds - force closing');
                  _forceClosePurchaseDialog();
                  
                  // Show timeout error message
                  if (mounted) {
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   const SnackBar(
                    //     backgroundColor: Colors.orange,
                    //     content: Row(
                    //       children: [
                    //         Icon(Icons.warning, color: Colors.white),
                    //         SizedBox(width: 8),
                    //         Expanded(child: Text('Purchase processing timed out. If payment was successful, premium features should activate automatically or you can use "Restore Premium".')),
                    //       ],
                    //     ),
                    //     duration: Duration(seconds: 6),
                    //   ),
                    // );
                  }
                }
              });
              
              // Initiate actual Google Play purchase
              await gameService.purchasePremium(
                onComplete: (bool success, String? error) {
                  // Create unique operation ID for this callback
                  final operationId = 'purchase_callback_${DateTime.now().millisecondsSinceEpoch}';
                  _operationCancelled[operationId] = false;
                  
                  try {
                    // ROBUST DIALOG CLEANUP - Always attempt to close dialog
                    print('🟡 CALLBACK: Purchase callback received - success: $success, error: $error');
                    
                    // Force close the dialog using robust method
                    if (!_purchaseDialogClosed) {
                      _forceClosePurchaseDialog();
                    } else {
                      print('🟡 CALLBACK: Dialog already marked as closed');
                    }
                    
                    // Check if operation was cancelled
                    if (_operationCancelled[operationId]!) return;
                    
                    if (success) {
                      print("🟢 Premium purchase successful!");
                      
                      // Enable premium features safely
                      if (mounted && !_operationCancelled[operationId]!) {
                        try {
                          Provider.of<GameState>(context, listen: false).enablePremium();
                          
                          // CRITICAL: Save the game immediately to persist premium status
                          Provider.of<GameService>(context, listen: false).saveGame();
                          
                          // Play success sound
                          gameService.playAchievementMilestoneSound();
                          
                          // Show success message
                          // ScaffoldMessenger.of(context).showSnackBar(
                          //   SnackBar(
                          //     backgroundColor: Colors.green,
                          //     content: const Row(
                          //       children: [
                          //         Icon(Icons.check_circle, color: Colors.white),
                          //         SizedBox(width: 8),
                          //         Text('Premium features activated! +1500 Platinum!'),
                          //       ],
                          //     ),
                          //     duration: const Duration(seconds: 4),
                          //   ),
                          // );
                        } catch (e) {
                          print('🔴 Error in purchase success handler: $e');
                        }
                      }
                    } else {
                      print("🔴 Premium purchase failed: $error");
                      
                      // Play error sound
                      gameService.playFeedbackErrorSound();
                      
                      // Show error message safely
                      if (mounted && !_operationCancelled[operationId]!) {
                        try {
                          String displayError = error ?? 'Purchase failed';
                          if (displayError.toLowerCase().contains('cancel')) {
                            displayError = 'Purchase was cancelled';
                          }
                          
                          // ScaffoldMessenger.of(context).showSnackBar(
                          //   SnackBar(
                          //     backgroundColor: Colors.red,
                          //     content: Row(
                          //       children: [
                          //         const Icon(Icons.error_outline, color: Colors.white),
                          //         const SizedBox(width: 8),
                          //         Expanded(child: Text(displayError)),
                          //       ],
                          //     ),
                          //     duration: const Duration(seconds: 4),
                          //   ),
                          // );
                        } catch (e) {
                          print('🔴 Error in purchase error handler: $e');
                        }
                      }
                    }
                  } catch (e) {
                    print('🔴 Error in purchase callback: $e');
                  } finally {
                    // Clean up operation tracking
                    _operationCancelled.remove(operationId);
                  }
                },
                onOwnershipDetected: () {
                  // Create unique operation ID for this callback
                  final operationId = 'ownership_callback_${DateTime.now().millisecondsSinceEpoch}';
                  _operationCancelled[operationId] = false;
                  
                  try {
                    // User already owns premium but app doesn't recognize it - handle safely
                    if (mounted && !_operationCancelled[operationId]!) {
                      try {
                        final gameState = Provider.of<GameState>(context, listen: false);
                        gameState.isEligibleForPremiumRestore = true;
                        // Save immediately to persist the eligibility
                        Provider.of<GameService>(context, listen: false).saveGame();
                        print("🟡 User marked as eligible for premium restore");
                      } catch (e) {
                        print('🔴 Error in ownership detection handler: $e');
                      }
                    }
                  } catch (e) {
                    print('🔴 Error in ownership callback: $e');
                  } finally {
                    // Clean up operation tracking
                    _operationCancelled.remove(operationId);
                  }
                },
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.purple),
            child: const Text('Purchase \$4.99'),
          ),
        ],
      ),
    );
  }

  /// Handle premium restore with robust context management
  Future<void> _handlePremiumRestore(GameService gameService, GameState gameState) async {
    try {
      print("🟡 Starting premium restore process");
      
      // Use a timer to auto-close dialog if something goes wrong
      Timer? timeoutTimer;
      bool dialogClosed = false;
      
      // Set up timeout to prevent permanent stuck dialogs
      timeoutTimer = Timer(const Duration(seconds: 15), () {
        if (!dialogClosed && mounted) {
          print("🔴 Premium restore timed out - force closing dialog");
          try {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          } catch (e) {
            print("🔴 Error closing dialog on timeout: $e");
          }
          dialogClosed = true;
          
          // Show timeout message
          if (mounted) {
            try {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.orange,
                  content: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Premium restore timed out. Please try again.'),
                    ],
                  ),
                  duration: Duration(seconds: 4),
                ),
              );
            } catch (e) {
              print("🔴 Error showing timeout message: $e");
            }
          }
        }
      });
      
      // Perform the premium restore
      bool success = await gameService.restorePremiumForVerifiedOwner();
      
      // Cancel the timeout timer
      timeoutTimer?.cancel();
      
      // Close loading dialog if not already closed
      if (!dialogClosed && mounted) {
        try {
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        } catch (e) {
          print("🔴 Error closing dialog after restore: $e");
        }
        dialogClosed = true;
      }
      
      // Handle the result
      if (success) {
        print("🟢 Premium restore successful!");
        
        // Enable premium features
        gameState.enablePremium();
        
        // Mark restore as used to prevent future use
        gameState.hasUsedPremiumRestore = true;
        gameState.isEligibleForPremiumRestore = false;
        
        // CRITICAL: Save the changes immediately to persist premium status
        gameService.saveGame();
        
        // Play success sound
        gameService.playAchievementMilestoneSound();
        
        // Show success message only if widget still mounted
        if (mounted) {
          try {
            // ScaffoldMessenger.of(context).showSnackBar(
            //   const SnackBar(
            //     backgroundColor: Colors.green,
            //     content: Row(
            //       children: [
            //         Icon(Icons.check_circle, color: Colors.white),
            //         SizedBox(width: 8),
            //         Text('Premium features restored! +1500 Platinum!'),
            //       ],
            //     ),
            //     duration: Duration(seconds: 4),
            //   ),
            // );
          } catch (e) {
            print("🔴 Error showing success message: $e");
          }
        }
      } else {
        print("🔴 Premium restore failed");
        
        // Play error sound
        gameService.playFeedbackErrorSound();
        
        // Show error message only if widget still mounted
        if (mounted) {
          try {
            // ScaffoldMessenger.of(context).showSnackBar(
            //   const SnackBar(
            //     backgroundColor: Colors.orange,
            //     content: Row(
            //       children: [
            //         Icon(Icons.info_outline, color: Colors.white),
            //         SizedBox(width: 8),
            //         Expanded(child: Text('No premium purchase found. You can purchase premium below, or contact support if you believe this is an error.')),
            //       ],
            //     ),
            //     duration: Duration(seconds: 6),
            //   ),
            // );
          } catch (e) {
            print("🔴 Error showing error message: $e");
          }
        }
      }
    } catch (e) {
      print("🔴 Error during premium restore: $e");
      
      // Ensure dialog is closed on any error
      if (mounted) {
        try {
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        } catch (dialogError) {
          print("🔴 Error closing dialog on exception: $dialogError");
        }
      }
      
      // Show error message
      if (mounted) {
        try {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     backgroundColor: Colors.red,
          //     content: Row(
          //       children: [
          //         const Icon(Icons.error_outline, color: Colors.white),
          //         const SizedBox(width: 8),
          //         Expanded(child: Text('Failed to restore premium: ${e.toString().split('\n').first}')),
          //       ],
          //     ),
          //     duration: const Duration(seconds: 4),
          //   ),
          // );
        } catch (messageError) {
          print("🔴 Error showing error message: $messageError");
        }
      }
    }
  }

  void _showRestorePremiumDialog(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Premium Purchase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'We\'ll check if you have a valid premium purchase and restore your features if found.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Premium features include:'),
            const SizedBox(height: 8),
            const Text('• Remove all ads from the game'),
            const Text('• Bonus +✦1500 Platinum'),
            const Text('• Exclusive profile customizations'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This restore will only work if you have actually purchased premium. Each account can only use restore once.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              print("🔄 Premium Restore Button Pressed.");
              
              final gameService = Provider.of<GameService>(context, listen: false);
              final gameState = Provider.of<GameState>(context, listen: false);
              
              // Capture context references early
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              
              // Double-check that user hasn't already used restore
              if (gameState.hasUsedPremiumRestore) {
                navigator.pop();
                // scaffoldMessenger.showSnackBar(
                //   const SnackBar(
                //     backgroundColor: Colors.orange,
                //     content: Row(
                //       children: [
                //         Icon(Icons.info_outline, color: Colors.white),
                //         SizedBox(width: 8),
                //         Text('You have already used your one-time premium restore.'),
                //       ],
                //     ),
                //     duration: Duration(seconds: 4),
                //   ),
                // );
                return;
              }
              
              // Close dialog first
              navigator.pop();
              
              // Show loading indicator - use root context for stability
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) => WillPopScope(
                  onWillPop: () async => false,
                  child: const AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Checking premium ownership...'),
                      ],
                    ),
                  ),
                ),
              );
              
              // Use a more robust approach with proper context management
              _handlePremiumRestore(gameService, gameState);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text('Check & Restore'),
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

    Widget _buildFeedbackSection() {
    return Center(
      child: TextButton.icon(
        onPressed: () async {
          final url = 'https://docs.google.com/forms/d/e/1FAIpQLSdYhNSpYb0_Vrly1WXardU0tILBC8sGpmGVKF2-h1HllZAVGA/viewform?usp=header';
          try {
            if (await canLaunchUrl(Uri.parse(url))) {
              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            } else {
              throw Exception('Could not launch URL');
            }
          } catch (e) {
            // Show error message if can't launch
            if (mounted) {
              // ScaffoldMessenger.of(context).showSnackBar(
              //   const SnackBar(
              //     content: Text('Could not open feedback form. Please try again later.'),
              //     backgroundColor: Colors.orange,
              //   ),
              // );
            }
          }
        },
        icon: Icon(
          Icons.feedback_outlined,
          size: 18,
          color: Colors.grey.shade600,
        ),
        label: Text(
          'Submit Feedback',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// [DEBUG ONLY] Show dialog for testing different purchase scenarios
  void _showDebugPurchaseTestDialog(BuildContext context, GameState gameState) {
    if (!kDebugMode) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shopping_cart, color: Colors.green),
            SizedBox(width: 8),
            Expanded(child: Text('Purchase Flow Testing')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Test different purchase scenarios to validate the billing flow:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Test successful purchase
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _testSuccessfulPurchase(context, gameState),
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  label: const Text('Test Successful Purchase'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade50,
                    foregroundColor: Colors.green.shade700,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Test failed purchase
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _testFailedPurchase(context, gameState),
                  icon: const Icon(Icons.error, color: Colors.red),
                  label: const Text('Test Failed Purchase'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade700,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Test verification logic
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _testVerificationLogic(context),
                  icon: const Icon(Icons.security, color: Colors.blue),
                  label: const Text('Test Verification Logic'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade700,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Check billing status
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showBillingStatus(context),
                  icon: const Icon(Icons.info, color: Colors.orange),
                  label: const Text('Check Billing Status'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade50,
                    foregroundColor: Colors.orange.shade700,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'Debug Testing Notes:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '• These tests simulate the complete purchase flow\n'
                      '• Test data goes through the same verification as real purchases\n'
                      '• Success tests will activate premium features\n'
                      '• Only available in debug builds',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show detailed billing service status
  void _showBillingStatus(BuildContext context) {
    // Early exit if widget is disposed
    if (!mounted) return;
    
    final gameService = Provider.of<GameService>(context, listen: false);
    
    // Safely close dialog with mounted check
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    
    final status = gameService.debugGetBillingStatus();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(child: Text('Billing Service Status')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status.containsKey('error'))
                Text(
                  'Error: ${status['error']}',
                  style: const TextStyle(color: Colors.red),
                )
              else ...[
                ...status.entries.map((entry) =>
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            '${entry.key.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim()}:',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${entry.value}',
                            style: TextStyle(
                              fontSize: 12,
                              color: entry.value == true 
                                ? Colors.green 
                                : entry.value == false 
                                  ? Colors.red 
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 