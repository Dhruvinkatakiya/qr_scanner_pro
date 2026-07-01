import 'package:flutter/services.dart';

/// Reads the one-shot "launch action" set by the native side when the app is
/// opened via a launcher shortcut or the home-screen widget ("scan"/"create").
class IntentService {
  const IntentService();

  static const MethodChannel _channel = MethodChannel('qr_scanner_pro/intent');

  Future<String?> getLaunchAction() async {
    try {
      return await _channel.invokeMethod<String>('getLaunchAction');
    } catch (_) {
      return null;
    }
  }
}
