import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService extends ChangeNotifier {
  static const bool _testMode = true; // Set to false for production
  
  // Test Ad Unit IDs (use these for development)
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testNativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';
  
  // Production Ad Unit IDs (replace with your actual AdMob IDs)
  static const String _prodBannerAdUnitId = 'ca-app-pub-YOUR_APP_ID/banner';
  static const String _prodInterstitialAdUnitId = 'ca-app-pub-YOUR_APP_ID/interstitial';
  static const String _prodRewardedAdUnitId = 'ca-app-pub-YOUR_APP_ID/rewarded';
  static const String _prodNativeAdUnitId = 'ca-app-pub-YOUR_APP_ID/native';
  
  // Current ad unit IDs
  static String get bannerAdUnitId => _testMode ? _testBannerAdUnitId : _prodBannerAdUnitId;
  static String get interstitialAdUnitId => _testMode ? _testInterstitialAdUnitId : _prodInterstitialAdUnitId;
  static String get rewardedAdUnitId => _testMode ? _testRewardedAdUnitId : _prodRewardedAdUnitId;
  static String get nativeAdUnitId => _testMode ? _testNativeAdUnitId : _prodNativeAdUnitId;
  
  // Ad instances
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  NativeAd? _nativeAd;
  
  // Ad states
  bool _isBannerAdLoaded = false;
  bool _isInterstitialAdLoaded = false;
  bool _isRewardedAdLoaded = false;
  bool _isNativeAdLoaded = false;
  
  // Getters
  BannerAd? get bannerAd => _bannerAd;
  InterstitialAd? get interstitialAd => _interstitialAd;
  RewardedAd? get rewardedAd => _rewardedAd;
  NativeAd? get nativeAd => _nativeAd;
  
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;
  bool get isNativeAdLoaded => _isNativeAdLoaded;
  
  // Initialize ads
  Future<void> initializeAds() async {
    await loadBannerAd();
    await loadInterstitialAd();
    await loadRewardedAd();
    await loadNativeAd();
  }
  
  // Banner Ad
  Future<void> loadBannerAd() async {
    _bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: bannerAdUnitId,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerAdLoaded = true;
          notifyListeners();
          if (kDebugMode) print('Banner ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          _isBannerAdLoaded = false;
          ad.dispose();
          notifyListeners();
          if (kDebugMode) print('Banner ad failed to load: $error');
        },
        onAdOpened: (ad) {
          if (kDebugMode) print('Banner ad opened');
        },
        onAdClosed: (ad) {
          if (kDebugMode) print('Banner ad closed');
        },
      ),
      request: const AdRequest(),
    );
    
    await _bannerAd!.load();
  }
  
  // Interstitial Ad
  Future<void> loadInterstitialAd() async {
    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
          notifyListeners();
          if (kDebugMode) print('Interstitial ad loaded');
          
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdLoaded = false;
          notifyListeners();
          if (kDebugMode) print('Interstitial ad failed to load: $error');
        },
      ),
    );
  }
  
  // Show Interstitial Ad
  Future<void> showInterstitialAd({VoidCallback? onAdClosed}) async {
    if (_interstitialAd != null && _isInterstitialAdLoaded) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          if (kDebugMode) print('Interstitial ad showed');
        },
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialAdLoaded = false;
          notifyListeners();
          onAdClosed?.call();
          loadInterstitialAd(); // Load next ad
          if (kDebugMode) print('Interstitial ad dismissed');
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialAdLoaded = false;
          notifyListeners();
          onAdClosed?.call();
          if (kDebugMode) print('Interstitial ad failed to show: $error');
        },
      );
      
      await _interstitialAd!.show();
    } else {
      onAdClosed?.call();
      if (kDebugMode) print('Interstitial ad not ready');
    }
  }
  
  // Rewarded Ad
  Future<void> loadRewardedAd() async {
    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          notifyListeners();
          if (kDebugMode) print('Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdLoaded = false;
          notifyListeners();
          if (kDebugMode) print('Rewarded ad failed to load: $error');
        },
      ),
    );
  }
  
  // Show Rewarded Ad
  Future<void> showRewardedAd({
    required VoidCallback onUserEarnedReward,
    VoidCallback? onAdClosed,
  }) async {
    if (_rewardedAd != null && _isRewardedAdLoaded) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          if (kDebugMode) print('Rewarded ad showed');
        },
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          _isRewardedAdLoaded = false;
          notifyListeners();
          onAdClosed?.call();
          loadRewardedAd(); // Load next ad
          if (kDebugMode) print('Rewarded ad dismissed');
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _rewardedAd = null;
          _isRewardedAdLoaded = false;
          notifyListeners();
          onAdClosed?.call();
          if (kDebugMode) print('Rewarded ad failed to show: $error');
        },
      );
      
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          onUserEarnedReward();
          if (kDebugMode) print('User earned reward: ${reward.amount} ${reward.type}');
        },
      );
    } else {
      onAdClosed?.call();
      if (kDebugMode) print('Rewarded ad not ready');
    }
  }
  
  // Native Ad
  Future<void> loadNativeAd() async {
    _nativeAd = NativeAd(
      adUnitId: nativeAdUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _isNativeAdLoaded = true;
          notifyListeners();
          if (kDebugMode) print('Native ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          _isNativeAdLoaded = false;
          ad.dispose();
          notifyListeners();
          if (kDebugMode) print('Native ad failed to load: $error');
        },
        onAdOpened: (ad) {
          if (kDebugMode) print('Native ad opened');
        },
        onAdClosed: (ad) {
          if (kDebugMode) print('Native ad closed');
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.white,
        cornerRadius: 16.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFF0057FF),
          style: NativeTemplateFontStyle.bold,
          size: 14.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black87,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black54,
          style: NativeTemplateFontStyle.normal,
          size: 14.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black54,
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
      ),
    );
    
    await _nativeAd!.load();
  }
  
  // Dispose all ads
  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _nativeAd?.dispose();
    super.dispose();
  }
  
  // Refresh banner ad
  Future<void> refreshBannerAd() async {
    _bannerAd?.dispose();
    _isBannerAdLoaded = false;
    notifyListeners();
    await loadBannerAd();
  }
  
  // Refresh native ad
  Future<void> refreshNativeAd() async {
    _nativeAd?.dispose();
    _isNativeAdLoaded = false;
    notifyListeners();
    await loadNativeAd();
  }
}