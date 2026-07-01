import '../utils/constants.dart';

enum SubscriptionTier { free, proMonthly, proYearly }

/// Local snapshot of the user's entitlement. The source of truth is Google Play
/// Billing; this is the cached view the UI reads synchronously.
class UserSubscription {
  const UserSubscription({
    this.tier = SubscriptionTier.free,
    this.expiryDate,
    this.productId,
    this.purchaseToken,
  });

  final SubscriptionTier tier;
  final DateTime? expiryDate;
  final String? productId;
  final String? purchaseToken;

  static const UserSubscription free = UserSubscription();

  /// True while the user is entitled to Pro features. We treat a missing expiry
  /// as "active" because Play manages renewal; expiry is only used as a soft
  /// local guard when we happen to know it.
  bool get isPro {
    if (tier == SubscriptionTier.free) return false;
    if (expiryDate == null) return true;
    return expiryDate!.isAfter(DateTime.now());
  }

  String get displayName {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.proMonthly:
        return 'Pro (Monthly)';
      case SubscriptionTier.proYearly:
        return 'Pro (Yearly)';
    }
  }

  factory UserSubscription.fromProductId(String productId, {DateTime? expiry}) {
    final tier = productId == AppConstants.proYearlyId
        ? SubscriptionTier.proYearly
        : SubscriptionTier.proMonthly;
    return UserSubscription(
      tier: tier,
      productId: productId,
      expiryDate: expiry,
    );
  }

  Map<String, dynamic> toJson() => {
        'tier': tier.name,
        'expiryDate': expiryDate?.toIso8601String(),
        'productId': productId,
        'purchaseToken': purchaseToken,
      };

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      tier: SubscriptionTier.values.firstWhere(
        (t) => t.name == json['tier'],
        orElse: () => SubscriptionTier.free,
      ),
      expiryDate: DateTime.tryParse(json['expiryDate'] as String? ?? ''),
      productId: json['productId'] as String?,
      purchaseToken: json['purchaseToken'] as String?,
    );
  }
}
