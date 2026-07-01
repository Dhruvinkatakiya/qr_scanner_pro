import 'package:permission_handler/permission_handler.dart';

/// Thin wrapper over `permission_handler` with a result type the UI can switch
/// on to show rationale dialogs or route the user to app settings.
enum PermissionOutcome { granted, denied, permanentlyDenied, restricted }

class PermissionService {
  const PermissionService();

  Future<PermissionOutcome> requestCamera() => _request(Permission.camera);

  /// Photo library access for "scan from gallery". On Android 13+ this maps to
  /// READ_MEDIA_IMAGES; older versions fall back to storage.
  Future<PermissionOutcome> requestPhotos() async {
    final photos = await _request(Permission.photos);
    if (photos == PermissionOutcome.granted) return photos;
    // Fallback for Android < 13 where `photos` is not the right permission.
    return _request(Permission.storage);
  }

  Future<bool> get hasCamera async => Permission.camera.isGranted;

  Future<PermissionOutcome> _request(Permission permission) async {
    final status = await permission.request();
    if (status.isGranted || status.isLimited) return PermissionOutcome.granted;
    if (status.isPermanentlyDenied) return PermissionOutcome.permanentlyDenied;
    if (status.isRestricted) return PermissionOutcome.restricted;
    return PermissionOutcome.denied;
  }

  Future<void> openSettings() => openAppSettings();
}
