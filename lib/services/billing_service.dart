import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

/// Service that handles Google Play Billing and App Store purchases
/// Implements secure purchase validation and proper error handling
class BillingService {
  static final BillingService _instance = BillingService._internal();
  factory BillingService() => _instance;
  BillingService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  /// Product IDs for in-app purchases
  static const String premiumProductId = 'premium_purchase';
  static const Set<String> _productIds = {premiumProductId};
  
  /// Available products from the store
  List<ProductDetails> _products = [];
  
  /// Purchase state callbacks
  Function(bool success, String? error)? _onPurchaseComplete;
  Function(bool success, String? error)? _onRestoreComplete;
  Function()? _onPremiumOwnershipDetected;
  
  /// Service initialization state
  bool _isInitialized = false;
  bool _isStoreAvailable = false;
  bool _isRestoringPurchases = false;
  
  /// Initialize the billing service
  Future<bool> initialize() async {
    try {
      // Check if the store is available
      _isStoreAvailable = await _inAppPurchase.isAvailable();
      
      if (!_isStoreAvailable) {
        print('🔴 Billing Service: Store not available');
        return false;
      }
      
      // Initialize platform-specific configurations
      if (Platform.isAndroid) {
        await _initializeAndroid();
      } else if (Platform.isIOS) {
        await _initializeIOS();
      }
      
      // Listen to purchase updates
      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => print('🟡 Billing Service: Purchase stream done'),
        onError: (error) => print('🔴 Billing Service: Purchase stream error: $error'),
      );
      
      // Load available products
      await _loadProducts();
      
      _isInitialized = true;
      print('🟢 Billing Service: Initialized successfully');
      return true;
      
    } catch (e) {
      print('🔴 Billing Service: Initialization failed: $e');
      return false;
    }
  }
  
  /// Initialize Android-specific billing
  Future<void> _initializeAndroid() async {
    if (Platform.isAndroid) {
      // Note: Pending purchases are automatically enabled in newer versions
      // of the in_app_purchase plugin, so no explicit call needed
      print('🟢 Android Billing: Platform initialized');
    }
  }
  
  /// Initialize iOS-specific billing
  Future<void> _initializeIOS() async {
    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosAddition =
          _inAppPurchase.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      
      // Set delegate for iOS
      await iosAddition.setDelegate(ExamplePaymentQueueDelegate());
      
      print('🟢 iOS Billing: Set payment queue delegate');
    }
  }
  
  /// Load products from the store
  Future<void> _loadProducts() async {
    try {
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(_productIds);
      
      if (response.error != null) {
        print('🔴 Billing Service: Failed to load products: ${response.error}');
        return;
      }
      
      _products = response.productDetails;
      
      print('🟢 Billing Service: Loaded ${_products.length} products');
      for (final product in _products) {
        print('   - ${product.id}: ${product.title} - ${product.price}');
      }
      
      // Verify our premium product is available
      final premiumProduct = _products.firstWhere(
        (product) => product.id == premiumProductId,
        orElse: () => throw Exception('Premium product not found in store'),
      );
      
      print('🟢 Premium Product Available: ${premiumProduct.title} for ${premiumProduct.price}');
      
    } catch (e) {
      print('🔴 Billing Service: Error loading products: $e');
    }
  }
  
  /// Get the premium product details
  ProductDetails? getPremiumProduct() {
    if (_products.isEmpty) return null;
    
    try {
      return _products.firstWhere((product) => product.id == premiumProductId);
    } catch (e) {
      print('🔴 Billing Service: Premium product not found');
      return null;
    }
  }
  
  /// Check if premium product is available for purchase
  bool isPremiumAvailable() {
    return _isInitialized && _isStoreAvailable && getPremiumProduct() != null;
  }
  
  /// Purchase the premium product
  Future<void> purchasePremium({
    required Function(bool success, String? error) onComplete,
    Function()? onOwnershipDetected,
  }) async {
    if (!_isInitialized) {
      onComplete(false, 'Billing service not initialized');
      return;
    }
    
    if (!_isStoreAvailable) {
      onComplete(false, 'Store not available');
      return;
    }
    
    final premiumProduct = getPremiumProduct();
    if (premiumProduct == null) {
      onComplete(false, 'Premium product not available');
      return;
    }
    
    // Set callbacks for purchase completion and ownership detection
    _onPurchaseComplete = onComplete;
    _onPremiumOwnershipDetected = onOwnershipDetected;
    
    try {
      // Create purchase parameters
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: premiumProduct,
        applicationUserName: null, // Can be set to user ID for tracking
      );
      
      print('🟡 Billing Service: Starting premium purchase for ${premiumProduct.price}');
      
      // Initiate the purchase
      final bool purchaseResult = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      
      if (!purchaseResult) {
        _onPurchaseComplete = null;
        _onPremiumOwnershipDetected = null;
        onComplete(false, 'Failed to initiate purchase');
      }
      
    } catch (e) {
      _onPurchaseComplete = null;
      _onPremiumOwnershipDetected = null;
      print('🔴 Billing Service: Purchase error: $e');
      onComplete(false, 'Purchase failed: $e');
    }
  }
  
  /// Handle purchase updates from the store
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      print('🟡 Billing Service: Processing purchase: ${purchaseDetails.productID}');
      
      if (purchaseDetails.status == PurchaseStatus.pending) {
        print('🟡 Purchase pending: ${purchaseDetails.productID}');
        // Handle pending purchase (show loading state)
        continue;
      }
      
      if (purchaseDetails.status == PurchaseStatus.error) {
        print('🔴 Purchase error: ${purchaseDetails.error}');
        _handlePurchaseError(purchaseDetails);
        continue;
      }
      
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        print('🟢 Purchase successful: ${purchaseDetails.productID}');
        _handlePurchaseSuccess(purchaseDetails);
        continue;
      }
      
      if (purchaseDetails.status == PurchaseStatus.restored) {
        print('🟢 Purchase restored: ${purchaseDetails.productID}');
        _handlePurchaseSuccess(purchaseDetails, isRestore: true);
        continue;
      }
      
      if (purchaseDetails.status == PurchaseStatus.canceled) {
        print('🟡 Purchase canceled: ${purchaseDetails.productID}');
        _handlePurchaseCancel(purchaseDetails);
        continue;
      }
      
      // Always complete the purchase for the store
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }
  
  /// Handle successful purchase
  void _handlePurchaseSuccess(PurchaseDetails purchaseDetails, {bool isRestore = false}) {
    if (purchaseDetails.productID == premiumProductId) {
      print('🟢 Premium ${isRestore ? 'restored' : 'purchase'} successful - activating features');
      
      // Verify the purchase (important for security)
      if (_verifyPurchase(purchaseDetails)) {
        // Call the appropriate callback based on whether this is a restore or new purchase
        if (isRestore && _onRestoreComplete != null) {
          _onRestoreComplete?.call(true, null);
        } else if (!isRestore && _onPurchaseComplete != null) {
          _onPurchaseComplete?.call(true, null);
        } else if (_onPurchaseComplete != null) {
          // Fallback to purchase callback if restore callback not set
          _onPurchaseComplete?.call(true, null);
        }
      } else {
        print('🔴 Purchase verification failed');
        if (isRestore && _onRestoreComplete != null) {
          _onRestoreComplete?.call(false, 'Purchase verification failed');
        } else {
          _onPurchaseComplete?.call(false, 'Purchase verification failed');
        }
      }
    }
    
    // Complete the purchase
    if (purchaseDetails.pendingCompletePurchase) {
      _inAppPurchase.completePurchase(purchaseDetails);
    }
    
    // Clear callbacks after use
    if (!isRestore) {
      _onPurchaseComplete = null;
      _onPremiumOwnershipDetected = null;
    }
  }
  
  /// Handle purchase error
  void _handlePurchaseError(PurchaseDetails purchaseDetails) {
    String errorMessage = 'Purchase failed';
    bool isAlreadyOwnedError = false;
    
    if (purchaseDetails.error != null) {
      final error = purchaseDetails.error!;
      errorMessage = error.message;
      
      // Handle specific error codes
      if (Platform.isAndroid) {
        switch (error.code) {
          case 'BillingResponse.USER_CANCELED':
            errorMessage = 'Purchase canceled';
            break;
          case 'BillingResponse.BILLING_UNAVAILABLE':
            errorMessage = 'Billing unavailable';
            break;
          case 'BillingResponse.ITEM_UNAVAILABLE':
            errorMessage = 'Item unavailable';
            break;
          case 'BillingResponse.DEVELOPER_ERROR':
            errorMessage = 'Configuration error';
            break;
          case 'BillingResponse.ERROR':
            errorMessage = 'Billing error occurred';
            break;
          case 'BillingResponse.ITEM_ALREADY_OWNED':
            errorMessage = 'You already own this item';
            isAlreadyOwnedError = true;
            print('🟡 Billing Service: User owns premium but app doesn\'t recognize it - marking as eligible for restore');
            break;
          case 'BillingResponse.ITEM_NOT_OWNED':
            errorMessage = 'Item not owned';
            break;
        }
      }
    }
    
    print('🔴 Purchase error: $errorMessage');
    
    // If user already owns the item, they're eligible for restore
    if (isAlreadyOwnedError && _onPremiumOwnershipDetected != null) {
      _onPremiumOwnershipDetected?.call();
    }
    
    _onPurchaseComplete?.call(false, errorMessage);
    _onPurchaseComplete = null;
    _onPremiumOwnershipDetected = null;
    
    // Complete the purchase
    if (purchaseDetails.pendingCompletePurchase) {
      _inAppPurchase.completePurchase(purchaseDetails);
    }
  }
  
  /// Handle purchase cancellation
  void _handlePurchaseCancel(PurchaseDetails purchaseDetails) {
    print('🟡 Purchase canceled by user');
    _onPurchaseComplete?.call(false, 'Purchase canceled');
    _onPurchaseComplete = null;
    _onPremiumOwnershipDetected = null;
    
    // Complete the purchase
    if (purchaseDetails.pendingCompletePurchase) {
      _inAppPurchase.completePurchase(purchaseDetails);
    }
  }
  
  /// Verify purchase (enhanced client-side verification with deep validation)
  /// For production, implement server-side verification
  bool _verifyPurchase(PurchaseDetails purchaseDetails) {
    print('🔍 SECURITY: Starting comprehensive purchase verification');
    
    // Check 1: Basic validation
    if (purchaseDetails.productID != premiumProductId) {
      print('🔴 SECURITY: Product ID mismatch in verification');
      return false;
    }
    
    // Check 2: Verify billing is available (prevent phantom purchases)
    if (!_isStoreAvailable) {
      print('🔴 SECURITY: Store not available - rejecting purchase verification');
      return false;
    }
    
    // Check 3: Verify verification data exists
    if (purchaseDetails.verificationData.localVerificationData.isEmpty ||
        purchaseDetails.verificationData.serverVerificationData.isEmpty) {
      print('🔴 SECURITY: Missing verification data - rejecting purchase');
      return false;
    }
    
    // Check 4: Verify purchase is not null or empty
    if (purchaseDetails.purchaseID == null || purchaseDetails.purchaseID!.isEmpty) {
      print('🔴 SECURITY: Invalid purchase ID - rejecting purchase');
      return false;
    }
    
    // Check 5: DEEP VALIDATION - Detect mock/test/cached purchase data
    if (!_deepValidatePurchaseData(purchaseDetails)) {
      print('🔴 SECURITY: Deep validation failed - purchase data appears to be mock/test/cached');
      return false;
    }
    
    print('🟢 SECURITY: Purchase verification passed all security checks');
    return true;
  }
  
  /// Deep validation to detect mock/test/cached purchase data
  bool _deepValidatePurchaseData(PurchaseDetails purchaseDetails) {
    try {
      // CRITICAL: Check if purchase token looks like real Google Play token
      final String localData = purchaseDetails.verificationData.localVerificationData;
      final String serverData = purchaseDetails.verificationData.serverVerificationData;
      
      // Real Google Play tokens have specific characteristics
      if (Platform.isAndroid) {
        // Android Google Play purchase tokens are typically long base64-encoded strings
        // Test/mock tokens often have simple patterns or are too short
        if (localData.length < 20 || serverData.length < 20) {
          print('🔴 SECURITY: Verification data too short - likely mock data');
          return false;
        }
        
        // Check for obvious test patterns
        if (localData.contains('test') || localData.contains('mock') || localData.contains('fake') ||
            serverData.contains('test') || serverData.contains('mock') || serverData.contains('fake')) {
          print('🔴 SECURITY: Verification data contains test patterns');
          return false;
        }
        
        // Real Google Play tokens are typically base64 encoded
        // Simple validation: check if it looks like base64
        final RegExp base64Pattern = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
        if (!base64Pattern.hasMatch(localData) || !base64Pattern.hasMatch(serverData)) {
          print('🔴 SECURITY: Verification data does not match expected format');
          return false;
        }
      }
      
      // Check purchase timestamp if available
      if (purchaseDetails.transactionDate != null) {
        final DateTime purchaseTime = DateTime.fromMillisecondsSinceEpoch(
          int.parse(purchaseDetails.transactionDate!)
        );
        final DateTime now = DateTime.now();
        
        // Check if purchase is from the future (invalid)
        if (purchaseTime.isAfter(now)) {
          print('🔴 SECURITY: Purchase timestamp is in the future - invalid data');
          return false;
        }
        
        // Check if purchase is extremely old (possibly cached test data)
        final Duration age = now.difference(purchaseTime);
        if (age.inDays > 365) {
          print('🔴 SECURITY: Purchase timestamp is over 1 year old - possibly cached test data');
          return false;
        }
      }
      
      // Additional check: Verify purchase ID format
      final String purchaseId = purchaseDetails.purchaseID!;
      if (Platform.isAndroid) {
        // Google Play order IDs have specific format: GPA.xxxx-xxxx-xxxx-xxxxx
        if (!purchaseId.startsWith('GPA.') && !purchaseId.contains('.')) {
          print('🔴 SECURITY: Purchase ID format does not match Google Play pattern');
          return false;
        }
      }
      
      print('🟢 SECURITY: Deep validation passed - purchase data appears legitimate');
      return true;
      
         } catch (e) {
       print('🔴 SECURITY: Error during deep validation: $e');
       return false;
     }
   }
   
   /// Test real billing capability by attempting a safe operation
   /// This detects if we're in a mock/test environment vs real billing
   Future<bool> _testRealBillingCapability() async {
     try {
       print('🔍 SECURITY: Testing real billing capability');
       
       // For Android, try to query the connection state
       if (Platform.isAndroid) {
         // Attempt to query product details again with a timeout
         // Real Google Play will respond, mock systems often fail or timeout
         final Future<ProductDetailsResponse> queryFuture = _inAppPurchase.queryProductDetails(_productIds);
         
         // Add a short timeout - real Google Play responds quickly
         final ProductDetailsResponse response = await queryFuture.timeout(
           const Duration(seconds: 3),
           onTimeout: () {
             print('🔴 SECURITY: Product query timed out - likely no real billing access');
             throw TimeoutException('Product query timeout', const Duration(seconds: 3));
           },
         );
         
         // Check if the response indicates real billing access
         if (response.error != null) {
           print('🔴 SECURITY: Product query returned error: ${response.error}');
           // Check for specific errors that indicate no real billing
           final String errorMessage = response.error!.message.toLowerCase();
           if (errorMessage.contains('not configured') || 
               errorMessage.contains('not available') ||
               errorMessage.contains('billing') ||
               errorMessage.contains('play store')) {
             print('🔴 SECURITY: Error message indicates no real billing capability');
             return false;
           }
         }
         
         // Additional check: Verify products match what we loaded initially
         if (response.productDetails.length != _products.length) {
           print('🔴 SECURITY: Product count mismatch - inconsistent billing state');
           return false;
         }
       }
       
       print('🟢 SECURITY: Real billing capability test passed');
       return true;
       
     } catch (e) {
       print('🔴 SECURITY: Billing capability test failed: $e');
       // If we get any errors during the test, assume no real billing access
       return false;
     }
   }
  
  /// Restore previous purchases with proper ownership verification
  /// This method now properly verifies the user actually owns premium before activating
  /// Returns true if premium was found and restored, false otherwise
  Future<bool> restorePremiumForVerifiedOwner() async {
    // CRITICAL SECURITY: Enhanced validation before attempting restore
    
    if (!_isInitialized) {
      print('🔴 SECURITY: Billing service not initialized - cannot restore');
      return false;
    }
    
    if (!_isStoreAvailable) {
      print('🔴 SECURITY: Store not available - cannot restore purchases');
      print('🔴 SECURITY: This prevents false positive premium restoration');
      return false;
    }
    
    if (_isRestoringPurchases) {
      print('🔴 SECURITY: Restore already in progress - preventing duplicate');
      return false;
    }
    
    // Additional security check: Verify premium product is available
    final premiumProduct = getPremiumProduct();
    if (premiumProduct == null) {
      print('🔴 SECURITY: Premium product not available in store');
      print('🔴 SECURITY: Cannot verify legitimate ownership without product access');
      return false;
    }
    
    print('🟢 SECURITY: All pre-restore security checks passed');
    
    try {
      print('🟡 Billing Service: Starting VERIFIED premium restoration');
      _isRestoringPurchases = true;
      
      // Use queryPurchases to check what the user actually owns
      bool result;
      if (Platform.isAndroid) {
        // For Android, we'll use the purchaseStream which already handles ownership verification
        result = await _checkAndroidPurchaseHistorySync();
      } else if (Platform.isIOS) {
        // For iOS, use restorePurchases
        result = await _checkiOSPurchaseHistorySync();
      } else {
        _isRestoringPurchases = false;
        print('🔴 Platform not supported for restore');
        return false;
      }
      
      _isRestoringPurchases = false;
      return result;
      
    } catch (e) {
      print('🔴 Billing Service: Restore purchases failed: $e');
      _isRestoringPurchases = false;
      return false;
    }
  }
  
  /// Check Android purchase history using purchase stream (callback version)
  Future<void> _checkAndroidPurchaseHistory(Function(bool success, String? error) onComplete) async {
    print('🟡 Billing Service: Checking Android purchase history');
    
    // Set up temporary callback to catch restore events
    bool premiumFound = false;
    Function(bool, String?)? originalCallback = _onRestoreComplete;
    
    _onRestoreComplete = (bool success, String? error) {
      if (success) {
        premiumFound = true;
        print('🟢 Billing Service: Premium ownership verified on Android');
      }
    };
    
    try {
      // Trigger a restore to activate the purchase stream
      await _inAppPurchase.restorePurchases();
      
      // Wait a brief moment for any purchases to be processed
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Clean up
      _onRestoreComplete = originalCallback;
      _isRestoringPurchases = false;
      
      if (premiumFound) {
        print('🟢 Billing Service: Android premium restoration successful');
        onComplete(true, null);
      } else {
        print('🟡 Billing Service: No premium purchases found on Android');
        onComplete(false, 'No premium purchase found. You may not have purchased premium or the purchase may not be properly recorded.');
      }
      
    } catch (e) {
      _onRestoreComplete = originalCallback;
      _isRestoringPurchases = false;
      print('🔴 Billing Service: Android restore failed: $e');
      onComplete(false, 'Failed to check purchase history: $e');
    }
  }
  
  /// Check Android purchase history synchronously (returns boolean)
  Future<bool> _checkAndroidPurchaseHistorySync() async {
    print('🟡 Billing Service: Checking Android purchase history (sync)');
    
    // CRITICAL SECURITY CHECK: Verify billing is actually available
    if (!_isStoreAvailable) {
      print('🔴 SECURITY: Billing not available - cannot restore purchases');
      print('🔴 SECURITY: Preventing false positive premium restoration');
      return false;
    }
    
    // Additional check: Verify we can actually access premium product
    final premiumProduct = getPremiumProduct();
    if (premiumProduct == null) {
      print('🔴 SECURITY: Premium product not available - cannot verify ownership');
      print('🔴 SECURITY: Preventing false positive premium restoration'); 
      return false;
    }
    
    // ULTRA-CRITICAL: Test real billing capability before proceeding
    if (!await _testRealBillingCapability()) {
      print('🔴 SECURITY: Real billing capability test failed - preventing false restoration');
      return false;
    }
    
    print('🟢 SECURITY: All security checks passed, proceeding with legitimate restore check');
    
    // Set up temporary callback to catch restore events
    bool premiumFound = false;
    Function(bool, String?)? originalCallback = _onRestoreComplete;
    
    _onRestoreComplete = (bool success, String? error) {
      if (success) {
        premiumFound = true;
        print('🟢 Billing Service: Premium ownership verified on Android');
      }
    };
    
    try {
      // Trigger a restore to activate the purchase stream
      await _inAppPurchase.restorePurchases();
      
      // Wait a brief moment for any purchases to be processed
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Clean up
      _onRestoreComplete = originalCallback;
      
      if (premiumFound) {
        print('🟢 Billing Service: Android premium restoration successful');
        return true;
      } else {
        print('🟡 Billing Service: No premium purchases found on Android');
        return false;
      }
      
    } catch (e) {
      _onRestoreComplete = originalCallback;
      print('🔴 Billing Service: Android restore failed: $e');
      return false;
    }
  }
  
  /// Check iOS purchase history (callback version)
  Future<void> _checkiOSPurchaseHistory(Function(bool success, String? error) onComplete) async {
    print('🟡 Billing Service: Checking iOS purchase history');
    
    // Set up temporary callback to catch restore events
    bool premiumFound = false;
    Function(bool, String?)? originalCallback = _onRestoreComplete;
    
    _onRestoreComplete = (bool success, String? error) {
      if (success) {
        premiumFound = true;
        print('🟢 Billing Service: Premium ownership verified on iOS');
      }
    };
    
    try {
      // Use iOS restore purchases
      await _inAppPurchase.restorePurchases();
      
      // Wait a brief moment for any purchases to be processed
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Clean up
      _onRestoreComplete = originalCallback;
      _isRestoringPurchases = false;
      
      if (premiumFound) {
        print('🟢 Billing Service: iOS premium restoration successful');
        onComplete(true, null);
      } else {
        print('🟡 Billing Service: No premium purchases found on iOS');
        onComplete(false, 'No premium purchase found. You may not have purchased premium or the purchase may not be properly recorded.');
      }
      
    } catch (e) {
      _onRestoreComplete = originalCallback;
      _isRestoringPurchases = false;
      print('🔴 Billing Service: iOS restore failed: $e');
      onComplete(false, 'Failed to check purchase history: $e');
    }
  }
  
  /// Check iOS purchase history synchronously (returns boolean)
  Future<bool> _checkiOSPurchaseHistorySync() async {
    print('🟡 Billing Service: Checking iOS purchase history (sync)');
    
    // CRITICAL SECURITY CHECK: Verify billing is actually available
    if (!_isStoreAvailable) {
      print('🔴 SECURITY: Billing not available - cannot restore purchases');
      print('🔴 SECURITY: Preventing false positive premium restoration');
      return false;
    }
    
    // Additional check: Verify we can actually access premium product
    final premiumProduct = getPremiumProduct();
    if (premiumProduct == null) {
      print('🔴 SECURITY: Premium product not available - cannot verify ownership');
      print('🔴 SECURITY: Preventing false positive premium restoration'); 
      return false;
    }
    
    // ULTRA-CRITICAL: Test real billing capability before proceeding
    if (!await _testRealBillingCapability()) {
      print('🔴 SECURITY: Real billing capability test failed - preventing false restoration');
      return false;
    }
    
    print('🟢 SECURITY: All security checks passed, proceeding with legitimate restore check');
    
    // Set up temporary callback to catch restore events
    bool premiumFound = false;
    Function(bool, String?)? originalCallback = _onRestoreComplete;
    
    _onRestoreComplete = (bool success, String? error) {
      if (success) {
        premiumFound = true;
        print('🟢 Billing Service: Premium ownership verified on iOS');
      }
    };
    
    try {
      // Use iOS restore purchases
      await _inAppPurchase.restorePurchases();
      
      // Wait a brief moment for any purchases to be processed
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Clean up
      _onRestoreComplete = originalCallback;
      
      if (premiumFound) {
        print('🟢 Billing Service: iOS premium restoration successful');
        return true;
      } else {
        print('🟡 Billing Service: No premium purchases found on iOS');
        return false;
      }
      
    } catch (e) {
      _onRestoreComplete = originalCallback;
      print('🔴 Billing Service: iOS restore failed: $e');
      return false;
    }
  }
  
  /// Legacy restore method - now redirects to verified restore
  Future<void> restorePurchases({required Function(bool success, String? error) onComplete}) async {
    print('🟡 Billing Service: Legacy restorePurchases called - redirecting to verified restore');
    bool success = await restorePremiumForVerifiedOwner();
    if (success) {
      onComplete(true, null);
    } else {
      onComplete(false, 'No premium purchase found or verification failed');
    }
  }
  
  /// Check if user has purchased premium (for app startup)
  Future<bool> checkPremiumOwnership() async {
    if (!_isInitialized) {
      print('🔴 Billing Service: Cannot check premium ownership - not initialized');
      return false;
    }
    
    if (!_isStoreAvailable) {
      print('🔴 Billing Service: Cannot check premium ownership - store not available');
      return false;
    }
    
    try {
      print('🟡 Billing Service: Checking for existing premium ownership');
      
      // IMPORTANT: DO NOT call restorePurchases() here as it can trigger false positives
      // Instead, we should rely on the normal purchase stream that's already set up
      
      // For now, return false and let the manual "Restore Purchases" button handle restoration
      // This prevents automatic false premium activation on app startup
      print('🟡 Billing Service: Skipping automatic ownership check to prevent false positives');
      print('🟡 Billing Service: Users can manually restore purchases if needed');
      
      // TODO: Implement proper ownership checking using platform-specific methods
      // For Android: Use queryPurchases() when available  
      // For iOS: Use proper StoreKit queries
      
      return false;
      
    } catch (e) {
      print('🔴 Billing Service: Error checking premium ownership: $e');
      return false;
    }
  }
  
  /// Get localized price for premium product
  String getPremiumPrice() {
    final product = getPremiumProduct();
    return product?.price ?? '\$4.99';
  }
  
  /// Cleanup resources
  void dispose() {
    _subscription.cancel();
    _onPurchaseComplete = null;
    print('🟡 Billing Service: Disposed');
  }
}

/// iOS Payment Queue Delegate
class ExamplePaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {
    return true;
  }

  @override  
  bool shouldShowPriceConsent() {
    return false;
  }
} 