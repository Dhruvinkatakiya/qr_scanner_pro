import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Wraps Google Mobile Ads. Ad unit IDs are provided exclusively by the
/// remote ad config; while the config is missing or unreachable no ads are
/// requested at all.
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

  String? _bannerUnitId;
  String? _interstitialUnitId;
  String? _appOpenUnitId;

  bool _bannerEnabled = true;
  bool _interstitialEnabled = true;
  bool _appOpenEnabled = true;

  /// Prevents multiple full-screen ads from showing over each other.
  bool isShowingAd = false;

  Future<void> _fetchAdConfig() async {
    try {
      final request = await HttpClient().getUrl(Uri.parse(
          'https://script.googleusercontent.com/macros/echo?user_content_key=AUkAhnR6eITh2IYe-n3PsBQ-h8Cy3pUzJkgu1qXUkZYo_RMCABHARVVhgRvMK4xf_7dU7YALnAwlYxQ9QMvr4TKhFGjoABW2IjEcp8Jl7Iz-Wc6a3oZ4NKIFefimFRVyUe8lBJmaJCy8bvSxEnDzpm7sTeClZ0e0OjjUn0bjr1VFtPc7xn18HRhVAjO3_y7aSlpaqvnKtFv0ILpKN3diGGqQ-_v_9MIlfJ7J51EX5LckHr7mEDfwk8CvS-HROIVdwzB5yg4c2b5C4iiEQ8BO6G9j2ldAREUV9Q&lib=MH__BrZO-6yBZFmsCpXNALTBB5iDfypnN'));
      final response = await request.close();
      if (response.statusCode == 200) {
        final stringData = await response.transform(utf8.decoder).join();
        final List<dynamic> data = jsonDecode(stringData);
        for (var item in data) {
          if (item['Platform'] == 'Android' && item['App Name'] == 'QR_Scanner') {
            final type = item['Ad Type'];
            final unitId = item['Ad Unit ID'] as String?;
            final status = item['Status'];
            final isEnabled = status == 'Enable';
            if (unitId == null || unitId.isEmpty) continue;

            if (type == 'Banner') {
              _bannerUnitId = unitId;
              _bannerEnabled = isEnabled;
            } else if (type == 'Interstitial') {
              _interstitialUnitId = unitId;
              _interstitialEnabled = isEnabled;
            } else if (type == 'App open') {
              _appOpenUnitId = unitId;
              _appOpenEnabled = isEnabled;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch ad config: $e');
    }
  }

  Future<void> init() async {
    if (_initialised || !_supportedPlatform) return;
    try {
      await MobileAds.instance.initialize();
      await _fetchAdConfig();
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
  /// Builds (but does not attach) a banner. Returns null when ads are disabled.
  BannerAd? createBanner({VoidCallback? onLoaded}) {
    final unitId = _bannerUnitId;
    if (unitId == null ||
        !enabled || !_bannerEnabled || !_initialised || !_supportedPlatform) {
      return null;
    }
    return BannerAd(
      adUnitId: unitId,
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
    final unitId = _appOpenUnitId;
    if (unitId == null) return;
    if (!enabled || !_appOpenEnabled || !_initialised || !_supportedPlatform) return;
    if (_appOpenAd != null || _isAppOpenAdLoading) return;

    _isAppOpenAdLoading = true;
    AppOpenAd.load(
      adUnitId: unitId,
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
    final unitId = _interstitialUnitId;
    if (unitId == null) return;
    if (!enabled || !_interstitialEnabled || !_initialised || !_supportedPlatform) return;
    if (_interstitialAd != null || _isInterstitialAdLoading) return;

    _isInterstitialAdLoading = true;
    InterstitialAd.load(
      adUnitId: unitId,
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
