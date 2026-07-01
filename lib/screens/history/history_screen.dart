import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/app_folder.dart';
import '../../providers/history_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/record_tile.dart';
import '../paywall/paywall_screen.dart';
import '../result/result_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(filteredHistoryProvider);
    final filter = ref.watch(historyFilterProvider);
    final folders = ref.watch(foldersProvider);
    final hasAny = ref.watch(historyProvider).isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('history.title'.tr()),
        actions: [
          if (hasAny)
            IconButton(
              tooltip: 'history.clear_all'.tr(),
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: _confirmClear,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged:
                  ref.read(historyFilterProvider.notifier).setQuery,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'history.search'.tr(),
                suffixIcon: filter.query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(historyFilterProvider.notifier)
                              .setQuery('');
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'history.all'.tr(),
                  selected: !filter.favoritesOnly &&
                      !filter.generatedOnly &&
                      filter.folderId == null,
                  onTap: () =>
                      ref.read(historyFilterProvider.notifier).reset(),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'history.favorites'.tr(),
                  icon: Icons.star_rounded,
                  selected: filter.favoritesOnly,
                  onTap: () => ref
                      .read(historyFilterProvider.notifier)
                      .toggleFavorites(),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'history.generated'.tr(),
                  icon: Icons.auto_awesome_rounded,
                  selected: filter.generatedOnly,
                  onTap: () => ref
                      .read(historyFilterProvider.notifier)
                      .toggleGenerated(),
                ),
                const SizedBox(width: 8),
                for (final f in folders) ...[
                  _FilterChip(
                    label: f.name,
                    color: Color(f.colorValue),
                    icon: Icons.folder_rounded,
                    selected: filter.folderId == f.id,
                    onTap: () => ref
                        .read(historyFilterProvider.notifier)
                        .setFolder(filter.folderId == f.id ? null : f.id),
                    onLongPress: () => _deleteFolder(f),
                  ),
                  const SizedBox(width: 8),
                ],
                _FilterChip(
                  label: 'history.new_folder'.tr(),
                  icon: Icons.add_rounded,
                  selected: false,
                  onTap: _createFolder,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: records.isEmpty
                ? EmptyState(
                    icon: Icons.inbox_rounded,
                    title: 'history.empty_title'.tr(),
                    message: 'history.empty_body'.tr(),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: records.length,
                    itemBuilder: (context, i) {
                      final r = records[i];
                      return Dismissible(
                        key: ValueKey(r.id),
                        background: _swipeBg(
                            Alignment.centerLeft,
                            Icons.star_rounded,
                            const Color(0xFFF7931A)),
                        secondaryBackground: _swipeBg(Alignment.centerRight,
                            Icons.delete_rounded, const Color(0xFFE0553D)),
                        confirmDismiss: (dir) async {
                          if (dir == DismissDirection.startToEnd) {
                            await ref
                                .read(historyProvider.notifier)
                                .toggleFavorite(r.id);
                            return false; // toggle only, keep row
                          }
                          await ref
                              .read(historyProvider.notifier)
                              .delete(r.id);
                          return true;
                        },
                        child: RecordTile(
                          record: r,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    ResultScreen(recordId: r.id)),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.more_vert_rounded),
                            onPressed: () => _rowMenu(r.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _swipeBg(Alignment align, IconData icon, Color color) => Container(
        color: color.withValues(alpha: 0.15),
        alignment: align,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Icon(icon, color: color),
      );

  // ---------------------------------------------------------------------------
  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('history.clear_all'.tr()),
        content: Text('history.clear_confirm'.tr()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('common.cancel'.tr())),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('common.delete'.tr())),
        ],
      ),
    );
    if (ok == true) await ref.read(historyProvider.notifier).clearAll();
  }

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    Color color = const Color(0xFF2F6BFF);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('history.new_folder'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration:
                    InputDecoration(hintText: 'history.folders'.tr()),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  for (final c in const [
                    Color(0xFF2F6BFF),
                    Color(0xFF00A88E),
                    Color(0xFFF7931A),
                    Color(0xFFE0553D),
                    Color(0xFF7A5CFF),
                    Color(0xFF23A455),
                  ])
                    GestureDetector(
                      onTap: () => setLocal(() => color = c),
                      child: CircleAvatar(
                        backgroundColor: c,
                        radius: 16,
                        child: color == c
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('common.cancel'.tr())),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                child: Text('common.add'.tr())),
          ],
        ),
      ),
    );
    if (name == null || name.isEmpty) return;
    final added = await ref.read(foldersProvider.notifier).addFolder(
          AppFolder(
            id: const Uuid().v4(),
            name: name,
            colorValue: color.toARGB32(),
            createdAt: DateTime.now(),
          ),
        );
    if (!added && mounted) {
      _showUpgrade('pro.folders_locked'.tr());
    }
  }

  Future<void> _deleteFolder(AppFolder folder) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(folder.name),
        content: Text('${'common.delete'.tr()}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('common.cancel'.tr())),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('common.delete'.tr())),
        ],
      ),
    );
    if (ok == true) await ref.read(foldersProvider.notifier).delete(folder.id);
  }

  void _rowMenu(String recordId) {
    final folders = ref.read(foldersProvider);
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.star_rounded),
              title: Text('common.favorite'.tr()),
              onTap: () {
                ref.read(historyProvider.notifier).toggleFavorite(recordId);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_rounded),
              title: Text('history.none'.tr()),
              onTap: () {
                ref
                    .read(historyProvider.notifier)
                    .moveToFolder(recordId, null);
                Navigator.pop(context);
              },
            ),
            for (final f in folders)
              ListTile(
                leading: Icon(Icons.folder_rounded, color: Color(f.colorValue)),
                title: Text(f.name),
                onTap: () {
                  ref
                      .read(historyProvider.notifier)
                      .moveToFolder(recordId, f.id);
                  Navigator.pop(context);
                },
              ),
            ListTile(
              leading:
                  const Icon(Icons.delete_rounded, color: Color(0xFFE0553D)),
              title: Text('common.delete'.tr()),
              onTap: () {
                ref.read(historyProvider.notifier).delete(recordId);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUpgrade(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'settings.go_pro'.tr(),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PaywallScreen()),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color,
    this.onLongPress,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = color ?? scheme.primary;
    return GestureDetector(
      onLongPress: onLongPress,
      child: FilterChip(
        avatar: icon != null
            ? Icon(icon,
                size: 16, color: selected ? Colors.white : accent)
            : null,
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: accent,
        labelStyle: TextStyle(
            color: selected ? Colors.white : null,
            fontWeight: FontWeight.w600),
        onSelected: (_) => onTap(),
      ),
    );
  }
}
