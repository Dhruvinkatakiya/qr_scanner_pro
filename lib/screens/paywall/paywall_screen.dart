import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/service_providers.dart';
import '../../providers/subscription_provider.dart';
import '../../utils/constants.dart';

class _Feature {
  const _Feature(this.icon, this.labelKey);
  final IconData icon;
  final String labelKey;
}

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String _selected = AppConstants.proYearlyId;
  bool _busy = false;

  static const _features = [
    _Feature(Icons.block_rounded, 'paywall.feature_noads'),
    _Feature(Icons.palette_rounded, 'paywall.feature_style'),
    _Feature(Icons.cloud_sync_rounded, 'paywall.feature_cloud'),
    _Feature(Icons.dynamic_feed_rounded, 'paywall.feature_batch'),
    _Feature(Icons.folder_rounded, 'paywall.feature_folders'),
  ];

  Future<void> _purchase() async {
    setState(() => _busy = true);
    final ok = await ref.read(subscriptionProvider.notifier).purchase(_selected);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('paywall.unavailable'.tr())));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Close automatically once entitlement is granted.
    ref.listen(subscriptionProvider, (prev, next) {
      if (next.isPro && (prev == null || !prev.isPro)) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('paywall.success'.tr())));
        Navigator.of(context).maybePop();
      }
    });

    final billing = ref.watch(billingServiceProvider);
    final scheme = Theme.of(context).colorScheme;
    final alreadyPro = ref.watch(subscriptionProvider).isPro;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFF7B733), Color(0xFFF7931A)]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: Colors.white, size: 44),
              ),
            ),
            const SizedBox(height: 20),
            Text('paywall.title'.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('paywall.subtitle'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            ..._features.map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(f.icon, size: 20, color: scheme.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(f.labelKey.tr(),
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF23A455)),
                    ],
                  ),
                )),
            const SizedBox(height: 24),
            if (alreadyPro)
              _AlreadyPro()
            else ...[
              _PlanTile(
                selected: _selected == AppConstants.proYearlyId,
                title: 'paywall.yearly'.tr(),
                price: billing.productById(AppConstants.proYearlyId)?.price ??
                    r'$29.99',
                badge: 'paywall.best_value'.tr(),
                onTap: () =>
                    setState(() => _selected = AppConstants.proYearlyId),
              ),
              const SizedBox(height: 12),
              _PlanTile(
                selected: _selected == AppConstants.proMonthlyId,
                title: 'paywall.monthly'.tr(),
                price: billing.productById(AppConstants.proMonthlyId)?.price ??
                    r'$4.99',
                onTap: () =>
                    setState(() => _selected = AppConstants.proMonthlyId),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _purchase,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('paywall.continue'.tr()),
              ),
              TextButton(
                onPressed: () =>
                    ref.read(subscriptionProvider.notifier).restore(),
                child: Text('paywall.restore'.tr()),
              ),
              const SizedBox(height: 8),
              Text('paywall.terms'.tr(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.selected,
    required this.title,
    required this.price,
    required this.onTap,
    this.badge,
  });

  final bool selected;
  final String title;
  final String price;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.08)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? scheme.primary : scheme.outline,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Row(
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF23A455),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(badge!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800)),
                    ),
                  ],
                ],
              ),
            ),
            Text(price,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _AlreadyPro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF23A455).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: Color(0xFF23A455)),
          const SizedBox(width: 12),
          Expanded(
            child: Text('paywall.already_pro'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
