import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/history_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/record_tile.dart';
import '../../widgets/section_header.dart';
import '../paywall/paywall_screen.dart';
import '../result/result_screen.dart';
import '../root/root_shell.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greetingKey() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'home.good_morning';
    if (hour < 18) return 'home.good_afternoon';
    return 'home.good_evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final recent = ref.watch(historyProvider).take(4).toList();
    final isPro = ref.watch(subscriptionProvider.select((s) => s.isPro));
    final shell = context.findAncestorStateOfType<RootShellState>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_greetingKey().tr(),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 2),
                            Text('home.subtitle'.tr(),
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                          ],
                        ),
                      ),
                      if (!isPro)
                        IconButton.filledTonal(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const PaywallScreen()),
                          ),
                          icon: const Icon(Icons.workspace_premium_rounded,
                              color: Color(0xFFF7931A)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickTile(
                          icon: Icons.qr_code_scanner_rounded,
                          title: 'home.scan_code'.tr(),
                          subtitle: 'home.scan_desc'.tr(),
                          gradient: const [Color(0xFF2F6BFF), Color(0xFF5B8CFF)],
                          onTap: () => shell?.openScanner(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickTile(
                          icon: Icons.qr_code_2_rounded,
                          title: 'home.create_qr'.tr(),
                          subtitle: 'home.create_desc'.tr(),
                          gradient: const [Color(0xFF7A5CFF), Color(0xFF9C82FF)],
                          onTap: () => shell?.goTo(1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _StatsRow(
                    month: stats.thisMonth,
                    total: stats.total,
                    favorites: stats.favorites,
                  ),
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'home.recent'.tr(),
                    actionLabel: 'home.view_all'.tr(),
                    onAction: () => shell?.goTo(2),
                  ),
                  const SizedBox(height: 8),
                  if (recent.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: EmptyState(
                        icon: Icons.qr_code_scanner_rounded,
                        title: 'home.empty_recent'.tr(),
                      ),
                    )
                  else
                    Card(
                      child: Column(
                        children: [
                          for (final r in recent)
                            RecordTile(
                              record: r,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        ResultScreen(recordId: r.id)),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 34),
            const Spacer(),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow(
      {required this.month, required this.total, required this.favorites});
  final int month;
  final int total;
  final int favorites;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _StatCard(
                value: '$month',
                label: 'home.this_month'.tr(),
                icon: Icons.calendar_month_rounded,
                color: const Color(0xFF2F6BFF))),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard(
                value: '$total',
                label: 'home.total'.tr(),
                icon: Icons.qr_code_rounded,
                color: const Color(0xFF00A88E))),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard(
                value: '$favorites',
                label: 'home.saved'.tr(),
                icon: Icons.star_rounded,
                color: const Color(0xFFF7931A))),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
