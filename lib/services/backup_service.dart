import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/app_folder.dart';
import '../models/scan_record.dart';

/// Fully local, no-account backup & restore.
///
/// Exports the entire history + folders to a portable JSON file the user can
/// save/share anywhere (Drive, email, another device), and restores by pasting
/// that JSON back in. No servers, no Firebase, no sign-in required.
class BackupService {
  const BackupService();

  static const int schemaVersion = 1;

  Map<String, dynamic> buildPayload(
      List<ScanRecord> records, List<AppFolder> folders) {
    return {
      'app': 'qr_scanner_pro',
      'version': schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'records': records.map((r) => r.toJson()).toList(),
      'folders': folders.map((f) => f.toJson()).toList(),
    };
  }

  /// Writes a pretty-printed JSON export to a temp file and opens the share
  /// sheet. Returns the file path.
  Future<String> exportAndShare(
      List<ScanRecord> records, List<AppFolder> folders) async {
    final json =
        const JsonEncoder.withIndent('  ').convert(buildPayload(records, folders));
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/qr_scanner_pro_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(json);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'QR Scanner Pro backup',
      ),
    );
    return file.path;
  }

  /// Parses an exported JSON string into records + folders. Throws
  /// [FormatException] on malformed input.
  BackupData parse(String jsonString) {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map || decoded['app'] != 'qr_scanner_pro') {
      throw const FormatException('Not a QR Scanner Pro backup file.');
    }
    final records = (decoded['records'] as List? ?? [])
        .map((e) => ScanRecord.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final folders = (decoded['folders'] as List? ?? [])
        .map((e) => AppFolder.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return BackupData(records: records, folders: folders);
  }
}

class BackupData {
  const BackupData({required this.records, required this.folders});
  final List<ScanRecord> records;
  final List<AppFolder> folders;
}
