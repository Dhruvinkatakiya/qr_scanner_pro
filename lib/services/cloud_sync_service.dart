import '../models/scan_record.dart';

/// Abstraction over remote backup/sync of the user's history.
///
/// The default [LocalOnlyCloudSyncService] is a no-op so the app builds and runs
/// with **no Firebase configuration**. A drop-in Firestore implementation lives
/// in `firebase_cloud_sync_service.dart.example` — add the Firebase
/// dependencies (see README) and swap it in via `cloudSyncServiceProvider`.
abstract class CloudSyncService {
  /// Whether cloud features should be surfaced at all (Firebase configured).
  bool get isAvailable;

  /// A short label for the signed-in account, or null when signed out.
  String? get accountLabel;

  /// Upgrades the (anonymous) session to a Google account. Returns true on
  /// success.
  Future<bool> signInWithGoogle();

  Future<void> signOut();

  /// Pushes a single record (create/update).
  Future<void> upsert(ScanRecord record);

  /// Removes a record remotely.
  Future<void> delete(String id);

  /// Full download used for a first sync / restore on a new device.
  Future<List<ScanRecord>> fetchAll();

  /// Pushes the entire local set (initial backup).
  Future<void> pushAll(List<ScanRecord> records);
}

/// Safe default used until Firebase is wired up. Every method is inert so
/// callers can invoke sync unconditionally.
class LocalOnlyCloudSyncService implements CloudSyncService {
  const LocalOnlyCloudSyncService();

  @override
  bool get isAvailable => false;

  @override
  String? get accountLabel => null;

  @override
  Future<bool> signInWithGoogle() async => false;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> upsert(ScanRecord record) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<ScanRecord>> fetchAll() async => const [];

  @override
  Future<void> pushAll(List<ScanRecord> records) async {}
}
