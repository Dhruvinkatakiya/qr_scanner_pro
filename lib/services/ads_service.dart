import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/constants.dart';

/// Wraps Google Mobile Ads. Uses Google's official **test** ad units by default
/// (see [AppConstants]); swap in real unit ids before release.
///
/// All entry points are safe to call even when the SDK failed to initialise or
/// the user is Pro — callers simply gate on [enabled].
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  bool _initialised = false;
  int _scansSinceInterstitial = 0;

  /// Set false for Pro users so no ad code paths run.
  bool enabled = true;

  bool get _supportedPlatform => !kIsWeb && Platform.isAndroid;

  Future<void> init() async {
    if (_initialised || !_supportedPlatform) return;
    try {
      await MobileAds.instance.initialize();
      _initialised = true;
    } catch (e) {
      debugPrint('AdMob init failed: $e');
    }
  }

  String get _bannerUnitId => AppConstants.testBannerAdUnit;
  String get _interstitialUnitId => AppConstants.testInterstitialAdUnit;

  /// Builds (but does not attach) a banner. Returns null when ads are disabled.
  BannerAd? createBanner({VoidCallback? onLoaded}) {
    if (!enabled || !_initialised || !_supportedPlatform) return null;
    return BannerAd(
      adUnitId: _bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded?.call(),
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner failed: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  /// Shows an interstitial roughly every [frequency] scans, for free users.
  void maybeShowInterstitial({int frequency = 4}) {
    if (!enabled || !_initialised) return;
    _scansSinceInterstitial++;
    if (_scansSinceInterstitial < frequency) return;
    _scansSinceInterstitial = 0;

    InterstitialAd.load(
      adUnitId: _interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, _) => ad.dispose(),
          );
          ad.show();
        },
        onAdFailedToLoad: (error) =>
            debugPrint('Interstitial failed: $error'),
      ),
    );
  }
}
