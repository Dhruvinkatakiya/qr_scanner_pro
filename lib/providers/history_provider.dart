import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_folder.dart';
import '../models/content_type.dart';
import '../models/scan_record.dart';
import '../services/storage_service.dart';
import 'service_providers.dart';

// -----------------------------------------------------------------------------
// Records
// -----------------------------------------------------------------------------
final historyProvider =
    NotifierProvider<HistoryNotifier, List<ScanRecord>>(HistoryNotifier.new);

class HistoryNotifier extends Notifier<List<ScanRecord>> {
  @override
  List<ScanRecord> build() => ref.read(storageServiceProvider).getRecords();

  StorageService get _storage => ref.read(storageServiceProvider);

  bool get _cloudEnabled =>
      ref.read(cloudSyncServiceProvider).isAvailable;

  Future<void> add(ScanRecord record) async {
    await _storage.putRecord(record);
    state = [record, ...state];
    if (_cloudEnabled) {
      unawaited(ref.read(cloudSyncServiceProvider).upsert(record));
    }
  }

  Future<void> _replace(ScanRecord updated) async {
    await _storage.putRecord(updated);
    state = [
      for (final r in state) if (r.id == updated.id) updated else r,
    ];
    if (_cloudEnabled) {
      unawaited(ref.read(cloudSyncServiceProvider).upsert(updated));
    }
  }

  ScanRecord? byId(String id) {
    for (final r in state) {
      if (r.id == id) return r;
    }
    return null;
  }

  Future<void> toggleFavorite(String id) async {
    final record = byId(id);
    if (record == null) return;
    await _replace(record.copyWith(isFavorite: !record.isFavorite));
  }

  Future<void> moveToFolder(String id, String? folderId) async {
    final record = byId(id);
    if (record == null) return;
    await _replace(record.copyWith(
        folderId: folderId, clearFolder: folderId == null));
  }

  Future<void> setNote(String id, String note) async {
    final record = byId(id);
    if (record == null) return;
    await _replace(record.copyWith(note: note));
  }

  Future<void> delete(String id) async {
    await _storage.deleteRecord(id);
    state = state.where((r) => r.id != id).toList();
    if (_cloudEnabled) {
      unawaited(ref.read(cloudSyncServiceProvider).delete(id));
    }
  }

  Future<void> clearAll() async {
    await _storage.clearRecords();
    state = [];
  }

  /// Merges imported records, skipping any id that already exists locally.
  Future<int> importAll(List<ScanRecord> incoming) async {
    final existing = {for (final r in state) r.id};
    var added = 0;
    for (final r in incoming) {
      if (existing.contains(r.id)) continue;
      await _storage.putRecord(r);
      added++;
    }
    if (added > 0) {
      state = ref.read(storageServiceProvider).getRecords();
    }
    return added;
  }

  /// Removes the folder association from every record in [folderId].
  Future<void> detachFolder(String folderId) async {
    for (final r in state.where((r) => r.folderId == folderId).toList()) {
      await _replace(r.copyWith(clearFolder: true));
    }
  }

  /// Full two-way restore from the cloud. Remote wins on conflicts by
  /// most-recent update time; local-only records are pushed up.
  Future<void> syncWithCloud() async {
    if (!_cloudEnabled) return;
    final cloud = ref.read(cloudSyncServiceProvider);
    final remote = await cloud.fetchAll();
    final byIdMap = {for (final r in state) r.id: r};
    for (final r in remote) {
      final local = byIdMap[r.id];
      if (local == null ||
          (r.updatedAt ?? r.createdAt)
              .isAfter(local.updatedAt ?? local.createdAt)) {
        byIdMap[r.id] = r;
        await _storage.putRecord(r);
      }
    }
    await cloud.pushAll(byIdMap.values.toList());
    final merged = byIdMap.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = merged;
  }
}

// -----------------------------------------------------------------------------
// Folders
// -----------------------------------------------------------------------------
final foldersProvider =
    NotifierProvider<FoldersNotifier, List<AppFolder>>(FoldersNotifier.new);

class FoldersNotifier extends Notifier<List<AppFolder>> {
  @override
  List<AppFolder> build() => ref.read(storageServiceProvider).getFolders();

  StorageService get _storage => ref.read(storageServiceProvider);

  /// All users can create unlimited folders — no paywall restriction.
  Future<bool> addFolder(AppFolder folder) async {
    await _storage.putFolder(folder);
    state = [...state, folder];
    return true;
  }

  Future<void> rename(String id, String name) async {
    final folder = state.firstWhere((f) => f.id == id);
    final updated = folder.copyWith(name: name);
    await _storage.putFolder(updated);
    state = [for (final f in state) if (f.id == id) updated else f];
  }

  Future<void> delete(String id) async {
    await _storage.deleteFolder(id);
    state = state.where((f) => f.id != id).toList();
    await ref.read(historyProvider.notifier).detachFolder(id);
  }

  AppFolder? byId(String? id) {
    if (id == null) return null;
    for (final f in state) {
      if (f.id == id) return f;
    }
    return null;
  }

  /// Merges imported folders, skipping ids that already exist.
  Future<void> importAll(List<AppFolder> incoming) async {
    final existing = {for (final f in state) f.id};
    final toAdd = incoming.where((f) => !existing.contains(f.id)).toList();
    if (toAdd.isEmpty) return;
    for (final f in toAdd) {
      await _storage.putFolder(f);
    }
    state = [...state, ...toAdd];
  }
}

// -----------------------------------------------------------------------------
// Filtering / search
// -----------------------------------------------------------------------------
class HistoryFilter {
  const HistoryFilter({
    this.query = '',
    this.type,
    this.folderId,
    this.favoritesOnly = false,
    this.generatedOnly = false,
  });

  final String query;
  final ContentType? type;
  final String? folderId;
  final bool favoritesOnly;
  final bool generatedOnly;

  HistoryFilter copyWith({
    String? query,
    ContentType? type,
    bool clearType = false,
    String? folderId,
    bool clearFolder = false,
    bool? favoritesOnly,
    bool? generatedOnly,
  }) {
    return HistoryFilter(
      query: query ?? this.query,
      type: clearType ? null : (type ?? this.type),
      folderId: clearFolder ? null : (folderId ?? this.folderId),
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      generatedOnly: generatedOnly ?? this.generatedOnly,
    );
  }

  bool get isActive =>
      query.isNotEmpty ||
      type != null ||
      folderId != null ||
      favoritesOnly ||
      generatedOnly;
}

final historyFilterProvider =
    NotifierProvider<HistoryFilterNotifier, HistoryFilter>(
        HistoryFilterNotifier.new);

class HistoryFilterNotifier extends Notifier<HistoryFilter> {
  @override
  HistoryFilter build() => const HistoryFilter();

  void setQuery(String q) => state = state.copyWith(query: q);
  void setType(ContentType? t) =>
      state = state.copyWith(type: t, clearType: t == null);
  void setFolder(String? f) =>
      state = state.copyWith(folderId: f, clearFolder: f == null);
  void toggleFavorites() =>
      state = state.copyWith(favoritesOnly: !state.favoritesOnly);
  void toggleGenerated() =>
      state = state.copyWith(generatedOnly: !state.generatedOnly);
  void reset() => state = const HistoryFilter();
}

/// The history list after the active [HistoryFilter] is applied.
final filteredHistoryProvider = Provider<List<ScanRecord>>((ref) {
  final records = ref.watch(historyProvider);
  final f = ref.watch(historyFilterProvider);
  final query = f.query.toLowerCase();
  return records.where((r) {
    if (f.favoritesOnly && !r.isFavorite) return false;
    if (f.generatedOnly && !r.isGenerated) return false;
    if (f.type != null && r.contentType != f.type) return false;
    if (f.folderId != null && r.folderId != f.folderId) return false;
    if (query.isNotEmpty && !r.content.toLowerCase().contains(query)) {
      return false;
    }
    return true;
  }).toList();
});

// -----------------------------------------------------------------------------
// Dashboard stats
// -----------------------------------------------------------------------------
class HistoryStats {
  const HistoryStats({
    required this.total,
    required this.thisMonth,
    required this.favorites,
    required this.generated,
  });

  final int total;
  final int thisMonth;
  final int favorites;
  final int generated;
}

final statsProvider = Provider<HistoryStats>((ref) {
  final records = ref.watch(historyProvider);
  final now = DateTime.now();
  var month = 0, favorites = 0, generated = 0;
  for (final r in records) {
    if (r.createdAt.year == now.year && r.createdAt.month == now.month) {
      month++;
    }
    if (r.isFavorite) favorites++;
    if (r.isGenerated) generated++;
  }
  return HistoryStats(
    total: records.length,
    thisMonth: month,
    favorites: favorites,
    generated: generated,
  );
});
