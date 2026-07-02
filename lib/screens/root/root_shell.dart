import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/intent_service.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../generate/generate_screen.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../scan/scan_screen.dart';
import '../settings/settings_screen.dart';

/// Persistent bottom-navigation shell. The centre FAB opens the full-screen
/// scanner; the four tabs keep their state via [IndexedStack].
class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<RootShell> createState() => RootShellState();
}

class RootShellState extends ConsumerState<RootShell>
    with TickerProviderStateMixin {
  late int _index = widget.initialIndex;
  late final AnimationController _fabPulseController;
  bool _fabPressed = false;

  @override
  void initState() {
    super.initState();
    _fabPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) => _handleLaunchAction());
  }

  @override
  void dispose() {
    _fabPulseController.dispose();
    super.dispose();
  }

  /// Honour a launcher-shortcut / widget deep link ("scan" or "create").
  Future<void> _handleLaunchAction() async {
    final action = await const IntentService().getLaunchAction();
    if (!mounted) return;
    if (action == 'scan') {
      openScanner();
    } else if (action == 'create') {
      goTo(1);
    }
  }

  void goTo(int index) => setState(() => _index = index);

  void openScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // ─── Screen content ──────────────────────────────────────────────
          IndexedStack(
            index: _index,
            children: const [
              HomeScreen(),
              GenerateScreen(),
              HistoryScreen(),
              SettingsScreen(),
            ],
          ),

          // ─── Floating pill nav bar ───────────────────────────────────────
          Positioned(
            bottom: bottomPadding + AppSpacing.base,
            left: AppSpacing.base,
            right: AppSpacing.base,
            child: _FloatingNavBar(
              selectedIndex: _index,
              isDark: isDark,
              fabPulseController: _fabPulseController,
              fabPressed: _fabPressed,
              onTabSelected: goTo,
              onFabPressed: () {
                setState(() => _fabPressed = true);
                Future.delayed(const Duration(milliseconds: 120), () {
                  if (mounted) setState(() => _fabPressed = false);
                  openScanner();
                });
              },
              scheme: scheme,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Floating Nav Bar ─────────────────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.selectedIndex,
    required this.isDark,
    required this.fabPulseController,
    required this.fabPressed,
    required this.onTabSelected,
    required this.onFabPressed,
    required this.scheme,
  });

  final int selectedIndex;
  final bool isDark;
  final AnimationController fabPulseController;
  final bool fabPressed;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onFabPressed;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF161B26).withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            boxShadow: AppShadows.lg(Colors.black),
          ),
          child: Row(
            children: [
              // Home
              _NavPill(
                icon: Icons.home_rounded,
                label: 'nav.home'.tr(),
                selected: selectedIndex == 0,
                onTap: () => onTabSelected(0),
                scheme: scheme,
              ),
              // Create
              _NavPill(
                icon: Icons.qr_code_2_rounded,
                label: 'nav.create'.tr(),
                selected: selectedIndex == 1,
                onTap: () => onTabSelected(1),
                scheme: scheme,
              ),
              // Centre scan FAB
              Expanded(
                child: Center(
                  child: _ScanFab(
                    controller: fabPulseController,
                    pressed: fabPressed,
                    onPressed: onFabPressed,
                    scheme: scheme,
                  ),
                ),
              ),
              // History
              _NavPill(
                icon: Icons.history_rounded,
                label: 'nav.history'.tr(),
                selected: selectedIndex == 2,
                onTap: () => onTabSelected(2),
                scheme: scheme,
              ),
              // Settings
              _NavPill(
                icon: Icons.settings_rounded,
                label: 'nav.settings'.tr(),
                selected: selectedIndex == 3,
                onTap: () => onTabSelected(3),
                scheme: scheme,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(
          begin: 0.15,
          end: 0,
          duration: 500.ms,
          delay: 100.ms,
          curve: Curves.easeOut,
        );
  }
}

// ─── Nav Pill Item ────────────────────────────────────────────────────────────

class _NavPill extends StatefulWidget {
  const _NavPill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.scheme,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  State<_NavPill> createState() => _NavPillState();
}

class _NavPillState extends State<_NavPill> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.90 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.selected
                      ? widget.scheme.primary.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: AnimatedScale(
                  scale: widget.selected ? 1.0 : 0.9,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    widget.icon,
                    size: 22,
                    color: widget.selected
                        ? widget.scheme.primary
                        : widget.scheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight:
                      widget.selected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.selected
                      ? widget.scheme.primary
                      : widget.scheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Scan FAB ─────────────────────────────────────────────────────────────────

class _ScanFab extends StatelessWidget {
  const _ScanFab({
    required this.controller,
    required this.pressed,
    required this.onPressed,
    required this.scheme,
  });

  final AnimationController controller;
  final bool pressed;
  final VoidCallback onPressed;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final pulse = controller.value;
          return AnimatedScale(
            scale: pressed ? 0.88 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing glow ring
                AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: 60 + pulse * 12,
                  height: 60 + pulse * 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withValues(
                        alpha: 0.15 - pulse * 0.10),
                  ),
                ),
                // Main FAB button
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        scheme.primary,
                        Color.lerp(scheme.primary, scheme.tertiary, 0.6)!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: AppShadows.glow(scheme.primary),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
