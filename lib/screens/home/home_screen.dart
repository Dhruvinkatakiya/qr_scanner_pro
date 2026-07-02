import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/history_provider.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/record_tile.dart';
import '../../widgets/section_header.dart';
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
    final shell = context.findAncestorStateOfType<RootShellState>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ─── Header ───────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.base, AppSpacing.base, AppSpacing.base, 0),
                      child: _Header(
                        greetingKey: _greetingKey(),
                        stats: stats,
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(
                          begin: -0.08,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOut,
                        ),
                  ),

                  const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.lg)),

                  // ─── Quick action cards ───────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          Expanded(
                            child: _GlassActionCard(
                              icon: Icons.qr_code_scanner_rounded,
                              title: 'home.scan_code'.tr(),
                              subtitle: 'home.scan_desc'.tr(),
                              gradientColors: [
                                const Color(0xFF3B7FF5),
                                const Color(0xFF5A9CF8),
                              ],
                              onTap: () => shell?.openScanner(),
                            ).animate().fadeIn(duration: 450.ms, delay: 80.ms).slideX(
                                  begin: -0.06,
                                  end: 0,
                                  duration: 450.ms,
                                  delay: 80.ms,
                                  curve: Curves.easeOut,
                                ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _GlassActionCard(
                              icon: Icons.qr_code_2_rounded,
                              title: 'home.create_qr'.tr(),
                              subtitle: 'home.create_desc'.tr(),
                              gradientColors: [
                                const Color(0xFF7C5CFC),
                                const Color(0xFF9B7FFF),
                              ],
                              onTap: () => shell?.goTo(1),
                            ).animate().fadeIn(duration: 450.ms, delay: 160.ms).slideX(
                                  begin: 0.06,
                                  end: 0,
                                  duration: 450.ms,
                                  delay: 160.ms,
                                  curve: Curves.easeOut,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.base)),

                  // ─── Stats strip ──────────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base),
                    sliver: SliverToBoxAdapter(
                      child: _StatsStrip(
                        month: stats.thisMonth,
                        total: stats.total,
                        favorites: stats.favorites,
                      ).animate().fadeIn(duration: 450.ms, delay: 240.ms).slideY(
                            begin: 0.06,
                            end: 0,
                            duration: 450.ms,
                            delay: 240.ms,
                            curve: Curves.easeOut,
                          ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.lg)),

                  // ─── Recent scans ─────────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base),
                    sliver: SliverToBoxAdapter(
                      child: SectionHeader(
                        title: 'home.recent'.tr(),
                        actionLabel: 'home.view_all'.tr(),
                        onAction: () => shell?.goTo(2),
                      ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                    ),
                  ),

                  const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.sm)),

                  if (recent.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                            horizontal: AppSpacing.base),
                        child: _EmptyRecent(onScan: () => shell?.openScanner()),
                      ).animate().fadeIn(duration: 500.ms, delay: 350.ms),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.base),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final r = recent[i];
                            return RecordTile(
                              record: r,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        ResultScreen(recordId: r.id)),
                              ),
                            )
                                .animate()
                                .fadeIn(
                                    duration: 400.ms,
                                    delay: Duration(milliseconds: 300 + i * 60))
                                .slideY(
                                    begin: 0.05,
                                    end: 0,
                                    duration: 400.ms,
                                    delay: Duration(
                                        milliseconds: 300 + i * 60));
                          },
                          childCount: recent.length,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(
                      child: SizedBox(height: 120)),
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

// ─── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.greetingKey, required this.stats});
  final String greetingKey;
  final HistoryStats stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greetingKey.tr(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                  children: [
                    TextSpan(text: 'home.subtitle'.tr()),
                    if (stats.total > 0)
                      TextSpan(
                        text: '  •  ${stats.total} scans total',
                        style: TextStyle(
                          color: scheme.primary.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // App logo / avatar
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.primary,
                scheme.tertiary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppShadows.md(scheme.primary),
          ),
          child: const Icon(Icons.qr_code_rounded, color: Colors.white, size: 22),
        ),
      ],
    );
  }
}

// ─── Glass Action Card ───────────────────────────────────────────────────────

class _GlassActionCard extends StatefulWidget {
  const _GlassActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  @override
  State<_GlassActionCard> createState() => _GlassActionCardState();
}

class _GlassActionCardState extends State<_GlassActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: 152,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.md(widget.gradientColors.first),
          ),
          child: Stack(
            children: [
              // Subtle inner highlight
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.4),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.xl)),
                  ),
                ),
              ),
              // Decorative blurred circle
              Positioned(
                right: -20,
                bottom: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 22),
                    ),
                    const Spacer(),
                    Text(
                      widget.title,
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.80),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stats Strip ─────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  const _StatsStrip(
      {required this.month, required this.total, required this.favorites});
  final int month;
  final int total;
  final int favorites;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B26) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.06))
            : null,
        boxShadow: isDark
            ? null
            : AppShadows.sm(Colors.black),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _StatItem(
                value: '$month',
                label: 'home.this_month'.tr(),
                icon: Icons.calendar_month_rounded,
                color: const Color(0xFF3B7FF5),
              ),
            ),
            VerticalDivider(
              width: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            Expanded(
              child: _StatItem(
                value: '$total',
                label: 'home.total'.tr(),
                icon: Icons.qr_code_rounded,
                color: const Color(0xFF00BFA5),
              ),
            ),
            VerticalDivider(
              width: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            Expanded(
              child: _StatItem(
                value: '$favorites',
                label: 'home.saved'.tr(),
                icon: Icons.star_rounded,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
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
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.base, horizontal: AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty Recent ────────────────────────────────────────────────────────────

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent({required this.onScan});
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B26) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.06))
            : null,
        boxShadow: isDark ? null : AppShadows.sm(Colors.black),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Line-art style QR code illustration
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(painter: _QrIllustrationPainter(scheme.primary)),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            'home.empty_recent'.tr(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Scan your first QR code to get started',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.base),
          FilledButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
            label: const Text('Scan Now'),
          ),
        ],
      ),
    );
  }
}

class _QrIllustrationPainter extends CustomPainter {
  const _QrIllustrationPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final s = size.width;
    final cornerSize = s * 0.32;
    final r = const Radius.circular(6);

    // Top-left corner
    final tlPath = Path()
      ..moveTo(0, cornerSize)
      ..lineTo(0, r.x)
      ..arcToPoint(Offset(r.x, 0), radius: r)
      ..lineTo(cornerSize, 0);
    canvas.drawPath(tlPath, paint);

    // Top-right corner
    final trPath = Path()
      ..moveTo(s - cornerSize, 0)
      ..lineTo(s - r.x, 0)
      ..arcToPoint(Offset(s, r.x), radius: r)
      ..lineTo(s, cornerSize);
    canvas.drawPath(trPath, paint);

    // Bottom-left corner
    final blPath = Path()
      ..moveTo(0, s - cornerSize)
      ..lineTo(0, s - r.x)
      ..arcToPoint(Offset(r.x, s), radius: r)
      ..lineTo(cornerSize, s);
    canvas.drawPath(blPath, paint);

    // Bottom-right corner
    final brPath = Path()
      ..moveTo(s - cornerSize, s)
      ..lineTo(s - r.x, s)
      ..arcToPoint(Offset(s, s - r.x), radius: r)
      ..lineTo(s, s - cornerSize);
    canvas.drawPath(brPath, paint);

    // Inner QR dots pattern
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final dotPositions = [
      Offset(s * 0.42, s * 0.28),
      Offset(s * 0.55, s * 0.28),
      Offset(s * 0.68, s * 0.28),
      Offset(s * 0.28, s * 0.42),
      Offset(s * 0.42, s * 0.42),
      Offset(s * 0.55, s * 0.42),
      Offset(s * 0.68, s * 0.42),
      Offset(s * 0.28, s * 0.55),
      Offset(s * 0.55, s * 0.55),
      Offset(s * 0.28, s * 0.68),
      Offset(s * 0.42, s * 0.68),
      Offset(s * 0.68, s * 0.68),
    ];

    for (final pos in dotPositions) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: pos, width: s * 0.09, height: s * 0.09),
          const Radius.circular(2),
        ),
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_QrIllustrationPainter oldDelegate) =>
      oldDelegate.color != color;
}
