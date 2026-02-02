import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages premium unlock state via Google Play in-app purchase.
class PremiumService {
  static const String productId = 'premium_unlock';
  static const String _prefKey = 'is_premium';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  ProductDetails? _product;
  ProductDetails? get product => _product;

  String? _error;
  String? get error => _error;

  /// Callback when premium status changes.
  VoidCallback? onStatusChanged;

  Future<void> init() async {
    // Load cached status first (instant UI)
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_prefKey) ?? false;

    final available = await _iap.isAvailable();
    if (!available) {
      debugPrint('PremiumService: In-app purchases not available');
      return;
    }

    // Listen for purchase updates
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (error) {
        debugPrint('PremiumService: Purchase stream error: $error');
      },
    );

    // Load product details
    final response = await _iap.queryProductDetails({productId});
    if (response.productDetails.isNotEmpty) {
      _product = response.productDetails.first;
    } else {
      debugPrint(
          'PremiumService: Product not found. Errors: ${response.error}');
    }
  }

  Future<void> purchase() async {
    if (_product == null) {
      _error = 'Product not available. Please try again later.';
      onStatusChanged?.call();
      return;
    }

    _error = null;
    final purchaseParam = PurchaseParam(productDetails: _product!);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    _error = null;
    await _iap.restorePurchases();
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _grantPremium();
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.error:
          _error = purchase.error?.message ?? 'Purchase failed.';
          onStatusChanged?.call();
          break;
        case PurchaseStatus.canceled:
          // User cancelled — no error
          break;
        case PurchaseStatus.pending:
          // Waiting for payment processing
          break;
      }
    }
  }

  Future<void> _grantPremium() async {
    _isPremium = true;
    _error = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
    onStatusChanged?.call();
  }

  void dispose() {
    _subscription?.cancel();
  }
}
