import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';


import 'package:uuid/uuid.dart';

import '../../models/app_folder.dart';
import '../../providers/history_provider.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/record_tile.dart';
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
    final scheme = Theme.of(context).colorScheme;

    // Group records by time bucket
    final grouped = _groupRecords(records);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // ─── Sliver app bar with frosted search ──────────────────────
            SliverAppBar(
              floating: true,
              snap: true,
              pinned: false,
              forceElevated: innerBoxIsScrolled,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Text('history.title'.tr()),
              actions: [
                if (hasAny)
                  IconButton(
                    tooltip: 'history.clear_all'.tr(),
                    icon: const Icon(Icons.delete_sweep_rounded),
                    onPressed: _confirmClear,
                  ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(116),
                child: Column(
                  children: [
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.base, 0, AppSpacing.base, AppSpacing.sm),
                      child: TextField(
                        controller: _searchController,
                        onChanged:
                            ref.read(historyFilterProvider.notifier).setQuery,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          hintText: 'history.search'.tr(),
                          suffixIcon: filter.query.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18),
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
                    // Filter chips
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.base),
                        children: [
                          _PillChip(
                            label: 'history.all'.tr(),
                            selected: !filter.favoritesOnly &&
                                !filter.generatedOnly &&
                                filter.folderId == null,
                            onTap: () => ref
                                .read(historyFilterProvider.notifier)
                                .reset(),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _PillChip(
                            label: 'history.favorites'.tr(),
                            icon: Icons.star_rounded,
                            selected: filter.favoritesOnly,
                            onTap: () => ref
                                .read(historyFilterProvider.notifier)
                                .toggleFavorites(),
                            accentColor: const Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _PillChip(
                            label: 'history.generated'.tr(),
                            icon: Icons.auto_awesome_rounded,
                            selected: filter.generatedOnly,
                            onTap: () => ref
                                .read(historyFilterProvider.notifier)
                                .toggleGenerated(),
                            accentColor: scheme.tertiary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          for (final f in folders) ...[
                            _PillChip(
                              label: f.name,
                              color: Color(f.colorValue),
                              icon: Icons.folder_rounded,
                              selected: filter.folderId == f.id,
                              onTap: () => ref
                                  .read(historyFilterProvider.notifier)
                                  .setFolder(filter.folderId == f.id
                                      ? null
                                      : f.id),
                              onLongPress: () => _deleteFolder(f),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          _PillChip(
                            label: 'history.new_folder'.tr(),
                            icon: Icons.add_rounded,
                            selected: false,
                            onTap: _createFolder,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ),
          ];
        },
        body: records.isEmpty
            ? EmptyState(
                icon: Icons.inbox_rounded,
                title: 'history.empty_title'.tr(),
                message: 'history.empty_body'.tr(),
              )
            : ListView.builder(
                // extendBody: bottom inset includes nav bar + gesture inset.
                padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
                    left: AppSpacing.base,
                    right: AppSpacing.base,
                    top: AppSpacing.sm),
                itemCount: grouped.length,
                itemBuilder: (context, i) {
                  final item = grouped[i];
                  if (item is _DateHeader) {
                    return Padding(
                      padding: const EdgeInsets.only(
                          top: AppSpacing.md, bottom: AppSpacing.sm),
                      child: Text(
                        item.label,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ).animate().fadeIn(duration: 300.ms);
                  }

                  final record = (item as _RecordItem).record;
                  return Dismissible(
                    key: ValueKey(record.id),
                    background: _SwipeBg(
                      alignment: Alignment.centerLeft,
                      icon: Icons.star_rounded,
                      color: const Color(0xFFF59E0B),
                      label: 'Favourite',
                    ),
                    secondaryBackground: _SwipeBg(
                      alignment: Alignment.centerRight,
                      icon: Icons.delete_rounded,
                      color: const Color(0xFFEF4444),
                      label: 'Delete',
                    ),
                    confirmDismiss: (dir) async {
                      if (dir == DismissDirection.startToEnd) {
                        await ref
                            .read(historyProvider.notifier)
                            .toggleFavorite(record.id);
                        return false;
                      }
                      await ref
                          .read(historyProvider.notifier)
                          .delete(record.id);
                      return true;
                    },
                    child: Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: RecordTile(
                        record: record,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  ResultScreen(recordId: record.id)),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert_rounded, size: 18),
                          onPressed: () => _rowMenu(record.id),
                        ),
                      ),
                    ),
                  )
                      .animate(delay: Duration(milliseconds: i * 30))
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.04, end: 0, duration: 300.ms);
                },
              ),
      ),
    );
  }

  // ─── Date grouping ──────────────────────────────────────────────────────────
  List<Object> _groupRecords(List records) {
    if (records.isEmpty) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final result = <Object>[];
    String? lastBucket;

    for (final r in records) {
      final created = (r as dynamic).createdAt as DateTime;
      final day = DateTime(created.year, created.month, created.day);

      final String bucket;
      if (!day.isBefore(today)) {
        bucket = 'Today';
      } else if (!day.isBefore(yesterday)) {
        bucket = 'Yesterday';
      } else if (!day.isBefore(weekAgo)) {
        bucket = 'This Week';
      } else {
        bucket = DateFormat('MMMM yyyy').format(created);
      }

      if (bucket != lastBucket) {
        result.add(_DateHeader(bucket));
        lastBucket = bucket;
      }
      result.add(_RecordItem(r));
    }
    return result;
  }

  // ─── Actions ────────────────────────────────────────────────────────────────
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
    Color color = const Color(0xFF3B7FF5);
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
              const SizedBox(height: AppSpacing.base),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final c in const [
                    Color(0xFF3B7FF5),
                    Color(0xFF00BFA5),
                    Color(0xFFF59E0B),
                    Color(0xFFEF4444),
                    Color(0xFF7C5CFC),
                    Color(0xFF22C55E),
                  ])
                    GestureDetector(
                      onTap: () => setLocal(() => color = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: color == c
                              ? Border.all(
                                  color: Colors.white, width: 2.5)
                              : null,
                          boxShadow:
                              color == c ? AppShadows.sm(c) : null,
                        ),
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
                onPressed: () =>
                    Navigator.pop(ctx, controller.text.trim()),
                child: Text('common.add'.tr())),
          ],
        ),
      ),
    );
    if (name == null || name.isEmpty) return;
    await ref.read(foldersProvider.notifier).addFolder(
          AppFolder(
            id: const Uuid().v4(),
            name: name,
            colorValue: color.toARGB32(),
            createdAt: DateTime.now(),
          ),
        );
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
              leading: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
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
                leading:
                    Icon(Icons.folder_rounded, color: Color(f.colorValue)),
                title: Text(f.name),
                onTap: () {
                  ref
                      .read(historyProvider.notifier)
                      .moveToFolder(recordId, f.id);
                  Navigator.pop(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_rounded,
                  color: Color(0xFFEF4444)),
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
}

// ─── Grouped list models ──────────────────────────────────────────────────────

class _DateHeader {
  const _DateHeader(this.label);
  final String label;
}

class _RecordItem {
  const _RecordItem(this.record);
  final dynamic record;
}

// ─── Swipe background ─────────────────────────────────────────────────────────

class _SwipeBg extends StatelessWidget {
  const _SwipeBg({
    required this.alignment,
    required this.icon,
    required this.color,
    required this.label,
  });

  final Alignment alignment;
  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pill filter chip ─────────────────────────────────────────────────────────

class _PillChip extends StatefulWidget {
  const _PillChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color,
    this.accentColor,
    this.onLongPress,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;
  final Color? accentColor;
  final VoidCallback? onLongPress;

  @override
  State<_PillChip> createState() => _PillChipState();
}

class _PillChipState extends State<_PillChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.color ?? widget.accentColor ?? scheme.primary;

    return GestureDetector(
      onLongPress: widget.onLongPress,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 6),
          decoration: BoxDecoration(
            color: widget.selected
                ? accent.withValues(alpha: 0.15)
                : isDark
                    ? const Color(0xFF161B26)
                    : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: widget.selected
                  ? accent.withValues(alpha: 0.5)
                  : isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08),
              width: widget.selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 14,
                  color: widget.selected ? accent : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight:
                      widget.selected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.selected ? accent : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
