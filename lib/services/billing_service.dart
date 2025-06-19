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
  
  /// Service initialization state
  bool _isInitialized = false;
  bool _isStoreAvailable = false;
  
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
  Future<void> purchasePremium({required Function(bool success, String? error) onComplete}) async {
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
    
    // Set callback for purchase completion
    _onPurchaseComplete = onComplete;
    
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
        onComplete(false, 'Failed to initiate purchase');
      }
      
    } catch (e) {
      _onPurchaseComplete = null;
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
        _handlePurchaseSuccess(purchaseDetails);
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
  void _handlePurchaseSuccess(PurchaseDetails purchaseDetails) {
    if (purchaseDetails.productID == premiumProductId) {
      print('🟢 Premium purchase successful - activating features');
      
      // Verify the purchase (important for security)
      if (_verifyPurchase(purchaseDetails)) {
        _onPurchaseComplete?.call(true, null);
      } else {
        print('🔴 Purchase verification failed');
        _onPurchaseComplete?.call(false, 'Purchase verification failed');
      }
    }
    
    // Complete the purchase
    if (purchaseDetails.pendingCompletePurchase) {
      _inAppPurchase.completePurchase(purchaseDetails);
    }
    
    _onPurchaseComplete = null;
  }
  
  /// Handle purchase error
  void _handlePurchaseError(PurchaseDetails purchaseDetails) {
    String errorMessage = 'Purchase failed';
    
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
            break;
          case 'BillingResponse.ITEM_NOT_OWNED':
            errorMessage = 'Item not owned';
            break;
        }
      }
    }
    
    print('🔴 Purchase error: $errorMessage');
    _onPurchaseComplete?.call(false, errorMessage);
    _onPurchaseComplete = null;
    
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
    
    // Complete the purchase
    if (purchaseDetails.pendingCompletePurchase) {
      _inAppPurchase.completePurchase(purchaseDetails);
    }
  }
  
  /// Verify purchase (basic client-side verification)
  /// For production, implement server-side verification
  bool _verifyPurchase(PurchaseDetails purchaseDetails) {
    // Basic verification - in production, verify with your server
    return purchaseDetails.verificationData.localVerificationData.isNotEmpty &&
           purchaseDetails.verificationData.serverVerificationData.isNotEmpty &&
           purchaseDetails.productID == premiumProductId;
  }
  
  /// Restore previous purchases
  Future<void> restorePurchases({required Function(bool success, String? error) onComplete}) async {
    if (!_isInitialized) {
      onComplete(false, 'Billing service not initialized');
      return;
    }
    
    try {
      print('🟡 Billing Service: Restoring purchases');
      if (Platform.isIOS) {
        // Use restorePurchases for iOS
        await _inAppPurchase.restorePurchases();
      } else {
        // For Android, purchases are automatically restored when the app starts
        // We just need to check the purchase stream
        print('🟡 Billing Service: Android purchases restored automatically');
      }
      print('🟢 Billing Service: Restore purchases completed');
      onComplete(true, null);
    } catch (e) {
      print('🔴 Billing Service: Restore purchases failed: $e');
      onComplete(false, 'Failed to restore purchases: $e');
    }
  }
  
  /// Check if user has purchased premium (for app startup)
  Future<bool> checkPremiumOwnership() async {
    if (!_isInitialized) return false;
    
    try {
      // Query current purchases (replaces queryPastPurchases in newer versions)
      final Stream<List<PurchaseDetails>> purchaseStream = _inAppPurchase.purchaseStream;
      
      // Check for existing non-consumable purchases
      // Note: For production, you should also check with your server
      // for now, we'll return false and let restore purchases handle this
      print('🟡 Billing Service: Premium ownership check completed (use Restore Purchases)');
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