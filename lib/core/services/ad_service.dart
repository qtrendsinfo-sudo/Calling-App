import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/env_config.dart';

final adServiceProvider = Provider<AdService>((ref) {
  return AdServiceImpl();
});

abstract class AdService {
  Future<void> initialize(EnvConfig config);
  bool get isAdsEnabled;
  void setAdsEnabled(bool enabled);
  void setCallActive(bool isActive);
  BannerAd? createBannerAd({
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
  });
  Future<void> showInterstitialAd();
}

class AdServiceImpl implements AdService {
  EnvConfig? _config;
  bool _isAdsEnabled = true;
  bool _isCallActive = false;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  @override
  bool get isAdsEnabled => _isAdsEnabled && !_isCallActive;

  @override
  void setAdsEnabled(bool enabled) {
    _isAdsEnabled = enabled;
  }

  @override
  void setCallActive(bool isActive) {
    _isCallActive = isActive;
    if (isActive) {
      // Discard preloaded interstitials immediately if a call starts
      _interstitialAd?.dispose();
      _interstitialAd = null;
    }
  }

  @override
  Future<void> initialize(EnvConfig config) async {
    _config = config;
    if (kIsWeb) {
      debugPrint('[AdService] Standby mode: AdMob disabled in Web sandbox.');
      return;
    }
    try {
      await MobileAds.instance.initialize();
      _loadInterstitialAd();
    } catch (e) {
      debugPrint('AdMob Initialization warning: $e');
    }
  }

  @override
  BannerAd? createBannerAd({
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    if (kIsWeb || !isAdsEnabled || _config == null) return null;

    return BannerAd(
      adUnitId: _config!.admobBannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    )..load();
  }

  void _loadInterstitialAd() {
    if (!isAdsEnabled || _isInterstitialLoading || _config == null) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: _config!.admobInterstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  @override
  Future<void> showInterstitialAd() async {
    // STRICT RULE: Never show ads if an active call is ongoing
    if (!isAdsEnabled || _isCallActive || _interstitialAd == null) return;

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
      },
    );

    await _interstitialAd!.show();
  }
}
