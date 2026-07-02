import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/ads_service.dart';
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
    with TickerProviderStateMixin, WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleLaunchAction());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fabPulseController.dispose();
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AdsService.instance.showAppOpenAd();
    }
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
      extendBody: true, // Allows body to scroll behind the BottomAppBar
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          GenerateScreen(),
          HistoryScreen(),
          SettingsScreen(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _ScanFab(
        controller: _fabPulseController,
        pressed: _fabPressed,
        onPressed: () {
          setState(() => _fabPressed = true);
          Future.delayed(const Duration(milliseconds: 120), () {
            if (mounted) setState(() => _fabPressed = false);
            AdsService.instance.showInterstitialAd(
              onDismissed: openScanner,
            );
          });
        },
        scheme: scheme,
      ),
      bottomNavigationBar: _StandardNavBar(
        selectedIndex: _index,
        onTabSelected: goTo,
        scheme: scheme,
      ),
    );
  }
}

// ─── Standard Bottom App Bar ──────────────────────────────────────────────────

class _StandardNavBar extends StatelessWidget {
  const _StandardNavBar({
    required this.selectedIndex,
    required this.onTabSelected,
    required this.scheme,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BottomAppBar(
      color: isDark ? const Color(0xFF161B26) : Colors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      height: 70,
      padding: EdgeInsets.zero,
      elevation: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Left side
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavIcon(
                  icon: Icons.home_rounded,
                  label: 'nav.home'.tr(),
                  selected: selectedIndex == 0,
                  onTap: () => onTabSelected(0),
                  scheme: scheme,
                ),
                _NavIcon(
                  icon: Icons.qr_code_2_rounded,
                  label: 'nav.create'.tr(),
                  selected: selectedIndex == 1,
                  onTap: () => onTabSelected(1),
                  scheme: scheme,
                ),
              ],
            ),
          ),
          
          // FAB Space
          const SizedBox(width: 48),
          
          // Right side
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavIcon(
                  icon: Icons.history_rounded,
                  label: 'nav.history'.tr(),
                  selected: selectedIndex == 2,
                  onTap: () => onTabSelected(2),
                  scheme: scheme,
                ),
                _NavIcon(
                  icon: Icons.settings_rounded,
                  label: 'nav.settings'.tr(),
                  selected: selectedIndex == 3,
                  onTap: () => onTabSelected(3),
                  scheme: scheme,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(
          begin: 0.2,
          end: 0,
          duration: 400.ms,
          delay: 100.ms,
          curve: Curves.easeOut,
        );
  }
}

// ─── Nav Icon Item ────────────────────────────────────────────────────────────

class _NavIcon extends StatefulWidget {
  const _NavIcon({
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
  State<_NavIcon> createState() => _NavIconState();
}

class _NavIconState extends State<_NavIcon> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: SizedBox(
          width: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
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
                    size: 24,
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
                child: Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis),
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
                      colors: const [
                        Color(0xFF0055FF), // Deep blue from logo
                        Color(0xFF00E5FF), // Cyan laser from logo
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: AppShadows.glow(const Color(0xFF0055FF)),
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
