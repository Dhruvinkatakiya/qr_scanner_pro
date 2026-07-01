import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../utils/constants.dart';

/// Wraps Google Play Billing (`in_app_purchase`) for the Pro subscriptions.
///
/// Degrades gracefully: on a device/emulator without the products configured in
/// Play Console, [available] is false and [products] stays empty — the paywall
/// then shows a friendly "temporarily unavailable" state instead of crashing.
class BillingService {
  BillingService([InAppPurchase? iap]) : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool available = false;
  List<ProductDetails> products = const [];

  /// Starts listening to the purchase stream. [onPurchase] is invoked for every
  /// purchase/restore update so the subscription provider can update
  /// entitlement and complete the transaction.
  Future<void> init(
      {required void Function(PurchaseDetails details) onPurchase}) async {
    try {
      available = await _iap.isAvailable();
    } catch (e) {
      debugPrint('Billing unavailable: $e');
      available = false;
    }
    if (!available) return;

    _subscription = _iap.purchaseStream.listen(
      (purchases) {
        for (final p in purchases) {
          onPurchase(p);
        }
      },
      onError: (Object e) => debugPrint('Purchase stream error: $e'),
    );

    await loadProducts();
  }

  Future<void> loadProducts() async {
    if (!available) return;
    try {
      final response = await _iap.queryProductDetails(AppConstants.productIds);
      products = response.productDetails;
      if (response.error != null) {
        debugPrint('queryProductDetails error: ${response.error}');
      }
    } catch (e) {
      debugPrint('loadProducts failed: $e');
    }
  }

  ProductDetails? productById(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Kicks off the Play purchase flow. Result arrives asynchronously on the
  /// purchase stream handled in [init].
  Future<bool> buy(ProductDetails product) async {
    if (!available) return false;
    final param = PurchaseParam(productDetails: product);
    // Subscriptions are modelled as non-consumables by the plugin.
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() async {
    if (!available) return;
    await _iap.restorePurchases();
  }

  /// Must be called by the platform after granting entitlement.
  Future<void> complete(PurchaseDetails details) async {
    if (details.pendingCompletePurchase) {
      await _iap.completePurchase(details);
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
