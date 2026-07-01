import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/user_subscription.dart';
import '../utils/constants.dart';
import 'service_providers.dart';

final subscriptionProvider =
    NotifierProvider<SubscriptionNotifier, UserSubscription>(
        SubscriptionNotifier.new);

/// Owns the user's Pro entitlement: loads the cached value, listens to Play
/// Billing purchase updates, and keeps the ads service in sync.
class SubscriptionNotifier extends Notifier<UserSubscription> {
  @override
  UserSubscription build() {
    final storage = ref.read(storageServiceProvider);
    final raw = storage.getSetting<String>(AppConstants.kSubscription);
    UserSubscription sub = UserSubscription.free;
    if (raw != null) {
      try {
        sub = UserSubscription.fromJson(
            Map<String, dynamic>.from(jsonDecode(raw) as Map));
      } catch (_) {}
    }
    ref.read(adsServiceProvider).enabled = !sub.isPro;
    // Connect to the store (safe no-op when unavailable).
    Future.microtask(_initBilling);
    return sub;
  }

  bool get isPro => state.isPro;

  Future<void> _initBilling() async {
    final billing = ref.read(billingServiceProvider);
    await billing.init(onPurchase: _handlePurchase);
  }

  Future<void> _handlePurchase(PurchaseDetails details) async {
    final billing = ref.read(billingServiceProvider);
    switch (details.status) {
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        if (AppConstants.productIds.contains(details.productID)) {
          _grant(UserSubscription.fromProductId(details.productID));
        }
        break;
      case PurchaseStatus.error:
        debugPrint('Purchase error: ${details.error}');
        break;
      case PurchaseStatus.pending:
      case PurchaseStatus.canceled:
        break;
    }
    await billing.complete(details);
  }

  void _grant(UserSubscription sub) {
    ref
        .read(storageServiceProvider)
        .setSetting(AppConstants.kSubscription, jsonEncode(sub.toJson()));
    ref.read(adsServiceProvider).enabled = !sub.isPro;
    state = sub;
  }

  /// Returns whether the purchase flow was launched successfully. Entitlement
  /// itself is granted asynchronously via [_handlePurchase].
  Future<bool> purchase(String productId) async {
    final billing = ref.read(billingServiceProvider);
    final product = billing.productById(productId);
    if (product == null) return false;
    return billing.buy(product);
  }

  Future<void> restore() => ref.read(billingServiceProvider).restore();

  /// Clears entitlement locally (used when Play reports a lapsed subscription,
  /// and available in debug for testing the free experience).
  void downgradeToFree() => _grant(UserSubscription.free);
}
