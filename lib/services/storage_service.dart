import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_folder.dart';
import '../models/scan_record.dart';
import '../utils/constants.dart';

/// Offline-first local persistence backed by Hive.
///
/// Records and folders are stored as JSON strings keyed by their id, which
/// avoids code-generated type adapters and keeps the schema forward-compatible.
class StorageService {
  StorageService(this._records, this._folders, this._settings);

  final Box _records;
  final Box _folders;
  final Box _settings;

  /// Opens every box the app relies on. Call once during startup.
  static Future<StorageService> init() async {
    await Hive.initFlutter();
    final records = await Hive.openBox(AppConstants.scanBox);
    final folders = await Hive.openBox(AppConstants.folderBox);
    final settings = await Hive.openBox(AppConstants.settingsBox);
    return StorageService(records, folders, settings);
  }

  // ---------------------------------------------------------------------------
  // Records
  // ---------------------------------------------------------------------------
  List<ScanRecord> getRecords() {
    final list = <ScanRecord>[];
    for (final value in _records.values) {
      try {
        list.add(ScanRecord.fromJson(
            Map<String, dynamic>.from(jsonDecode(value as String) as Map)));
      } catch (_) {
        // Skip any record that fails to deserialise rather than crash startup.
      }
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> putRecord(ScanRecord record) =>
      _records.put(record.id, jsonEncode(record.toJson()));

  Future<void> deleteRecord(String id) => _records.delete(id);

  Future<void> clearRecords() => _records.clear();

  // ---------------------------------------------------------------------------
  // Folders
  // ---------------------------------------------------------------------------
  List<AppFolder> getFolders() {
    final list = <AppFolder>[];
    for (final value in _folders.values) {
      try {
        list.add(AppFolder.fromJson(
            Map<String, dynamic>.from(jsonDecode(value as String) as Map)));
      } catch (_) {}
    }
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<void> putFolder(AppFolder folder) =>
      _folders.put(folder.id, jsonEncode(folder.toJson()));

  Future<void> deleteFolder(String id) => _folders.delete(id);

  // ---------------------------------------------------------------------------
  // Settings (small key/value store)
  // ---------------------------------------------------------------------------
  T? getSetting<T>(String key, {T? defaultValue}) =>
      _settings.get(key, defaultValue: defaultValue) as T?;

  Future<void> setSetting(String key, dynamic value) =>
      _settings.put(key, value);
}
