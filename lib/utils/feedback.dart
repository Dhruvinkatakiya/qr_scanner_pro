import 'package:flutter/services.dart';

/// Central place for scan feedback so the sound/haptic settings are honoured
/// consistently wherever a code is detected.
class ScanFeedback {
  ScanFeedback._();

  static void onScan({required bool sound, required bool haptics}) {
    if (haptics) HapticFeedback.mediumImpact();
    if (sound) SystemSound.play(SystemSoundType.click);
  }

  static void tap({required bool haptics}) {
    if (haptics) HapticFeedback.selectionClick();
  }
}
