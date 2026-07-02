import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/constants.dart';

/// Wraps Google Mobile Ads. Uses Google's official **test** ad units by default
/// (see [AppConstants]); swap in real unit ids before release.
///
/// Only banner ads are served — interstitials have been removed.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  bool _initialised = false;

  /// Set false to disable all ad code paths.
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
}
