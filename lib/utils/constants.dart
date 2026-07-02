/// App-wide constant values.
///
/// Keeping these in one place makes it easy to tweak ad units and storage keys
/// without hunting through the codebase.
class AppConstants {
  AppConstants._();

  static const String appName = 'QR Scanner Pro';

  // ---------------------------------------------------------------------------
  // Hive box names
  // ---------------------------------------------------------------------------
  static const String scanBox = 'scan_records';
  static const String folderBox = 'folders';
  static const String settingsBox = 'settings';

  // ---------------------------------------------------------------------------
  // Settings keys (stored inside [settingsBox])
  // ---------------------------------------------------------------------------
  static const String kThemeMode = 'theme_mode';
  static const String kAccentColor = 'accent_color';
  static const String kSoundEnabled = 'sound_enabled';
  static const String kHapticsEnabled = 'haptics_enabled';
  static const String kAutoOpenLinks = 'auto_open_links';
  static const String kOnboardingDone = 'onboarding_done';
  static const String kLocale = 'locale';
  static const String kVibrateOnScan = 'vibrate_on_scan';

  // ---------------------------------------------------------------------------
  // AdMob — these are Google's official TEST unit IDs. Replace before release.
  // https://developers.google.com/admob/android/test-ads
  // ---------------------------------------------------------------------------
  static const String testBannerAdUnit =
      'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialAdUnit =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testAppOpenAdUnit =
      'ca-app-pub-3940256099942544/9257395921';

  // ---------------------------------------------------------------------------
  // Links used in the Settings / About section.
  // ---------------------------------------------------------------------------
  static const String privacyPolicyUrl =
      'https://example.com/qr-scanner-pro/privacy';
  static const String supportEmail = 'support@example.com';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.example.qr_scanner_pro';
}
