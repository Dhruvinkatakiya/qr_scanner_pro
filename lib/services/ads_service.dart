import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/constants.dart';

/// Wraps Google Mobile Ads. Uses Google's official **test** ad units by default
/// (see [AppConstants]); swap in real unit ids before release.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  bool _initialised = false;
  
  /// Set false to disable all ad code paths.
  bool enabled = true;

  bool get _supportedPlatform => !kIsWeb && Platform.isAndroid;

  // ---------------------------------------------------------------------------
  // Cached Ads
  // ---------------------------------------------------------------------------
  AppOpenAd? _appOpenAd;
  bool _isAppOpenAdLoading = false;
  
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoading = false;

  /// Prevents multiple full-screen ads from showing over each other.
  bool isShowingAd = false;

  Future<void> init() async {
    if (_initialised || !_supportedPlatform) return;
    try {
      await MobileAds.instance.initialize();
      _initialised = true;
      
      // Pre-load full-screen ads in the background
      loadAppOpenAd();
      loadInterstitialAd();
    } catch (e) {
      debugPrint('AdMob init failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Banner Ads
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // App Open Ads
  // ---------------------------------------------------------------------------
  void loadAppOpenAd() {
    if (!enabled || !_initialised || !_supportedPlatform) return;
    if (_appOpenAd != null || _isAppOpenAdLoading) return;
    
    _isAppOpenAdLoading = true;
    AppOpenAd.load(
      adUnitId: AppConstants.testAppOpenAdUnit,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isAppOpenAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('AppOpenAd failed to load: $error');
          _isAppOpenAdLoading = false;
        },
      ),
    );
  }

  void showAppOpenAd() {
    if (!enabled || _appOpenAd == null || isShowingAd) {
      loadAppOpenAd();
      return;
    }
    
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => isShowingAd = true,
      onAdFailedToShowFullScreenContent: (ad, error) {
        isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
      onAdDismissedFullScreenContent: (ad) {
        isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
    );
    
    _appOpenAd!.show();
  }

  // ---------------------------------------------------------------------------
  // Interstitial Ads
  // ---------------------------------------------------------------------------
  void loadInterstitialAd() {
    if (!enabled || !_initialised || !_supportedPlatform) return;
    if (_interstitialAd != null || _isInterstitialAdLoading) return;
    
    _isInterstitialAdLoading = true;
    InterstitialAd.load(
      adUnitId: AppConstants.testInterstitialAdUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          _isInterstitialAdLoading = false;
        },
      ),
    );
  }

  /// Shows the interstitial ad if ready, then executes [onDismissed].
  /// If no ad is ready, [onDismissed] is executed immediately.
  void showInterstitialAd({required VoidCallback onDismissed}) {
    if (!enabled || _interstitialAd == null || isShowingAd) {
      onDismissed();
      loadInterstitialAd();
      return;
    }
    
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => isShowingAd = true,
      onAdFailedToShowFullScreenContent: (ad, error) {
        isShowingAd = false;
        ad.dispose();
        _interstitialAd = null;
        onDismissed();
        loadInterstitialAd();
      },
      onAdDismissedFullScreenContent: (ad) {
        isShowingAd = false;
        ad.dispose();
        _interstitialAd = null;
        onDismissed();
        loadInterstitialAd();
      },
    );
    
    _interstitialAd!.show();
  }
}
