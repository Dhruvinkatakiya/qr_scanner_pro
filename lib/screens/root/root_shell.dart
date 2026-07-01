import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/intent_service.dart';
import '../generate/generate_screen.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../scan/scan_screen.dart';
import '../settings/settings_screen.dart';

/// Persistent bottom-navigation shell. The centre docked FAB opens the
/// full-screen scanner; the four tabs keep their state via [IndexedStack].
class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<RootShell> createState() => RootShellState();
}

class RootShellState extends ConsumerState<RootShell> {
  late int _index = widget.initialIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleLaunchAction());
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
    return Scaffold(
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
      floatingActionButton: FloatingActionButton.large(
        onPressed: openScanner,
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner_rounded, size: 32),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 68,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'nav.home'.tr(),
              selected: _index == 0,
              onTap: () => goTo(0),
            ),
            _NavItem(
              icon: Icons.qr_code_2_rounded,
              label: 'nav.create'.tr(),
              selected: _index == 1,
              onTap: () => goTo(1),
            ),
            const SizedBox(width: 64),
            _NavItem(
              icon: Icons.history_rounded,
              label: 'nav.history'.tr(),
              selected: _index == 2,
              onTap: () => goTo(2),
            ),
            _NavItem(
              icon: Icons.settings_rounded,
              label: 'nav.settings'.tr(),
              selected: _index == 3,
              onTap: () => goTo(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
