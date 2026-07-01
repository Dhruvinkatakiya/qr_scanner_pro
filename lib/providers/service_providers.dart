import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ads_service.dart';
import '../services/backup_service.dart';
import '../services/billing_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/permission_service.dart';
import '../services/qr_parser_service.dart';
import '../services/scanner_service.dart';
import '../services/storage_service.dart';

/// Overridden in `main()` with the already-initialised instance.
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('storageServiceProvider must be overridden');
});

final qrParserServiceProvider =
    Provider<QrParserService>((ref) => QrParserService());

final scannerServiceProvider =
    Provider<ScannerService>((ref) => const ScannerService());

final permissionServiceProvider =
    Provider<PermissionService>((ref) => const PermissionService());

/// Defaults to the no-op local implementation. To enable Firebase-backed sync,
/// override this with a `FirebaseCloudSyncService` (see README) after adding the
/// Firebase dependencies.
final cloudSyncServiceProvider =
    Provider<CloudSyncService>((ref) => const LocalOnlyCloudSyncService());

final billingServiceProvider = Provider<BillingService>((ref) {
  final service = BillingService();
  ref.onDispose(service.dispose);
  return service;
});

final adsServiceProvider = Provider<AdsService>((ref) => AdsService.instance);

final backupServiceProvider =
    Provider<BackupService>((ref) => const BackupService());
