import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService extends ChangeNotifier {
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  
  bool _isBannerAdLoaded = false;
  bool _isInterstitialAdLoaded = false;
  bool _isRewardedAdLoaded = false;
  String? _error;

  BannerAd? get bannerAd => _bannerAd;
  InterstitialAd? get interstitialAd => _interstitialAd;
  RewardedAd? get rewardedAd => _rewardedAd;
  
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;
  String? get error => _error;

  // Banner reklam yükle
  Future<void> loadBannerAd() async {
    try {
      _error = null;
      notifyListeners();

      _bannerAd = BannerAd(
        adUnitId: _getBannerAdUnitId(),
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _isBannerAdLoaded = true;
            notifyListeners();
          },
          onAdFailedToLoad: (ad, error) {
            _isBannerAdLoaded = false;
            _error = null; // Hata mesajı gösterme
            notifyListeners();
            ad.dispose();
          },
        ),
      );

      await _bannerAd!.load();
    } catch (e) {
      _error = null; // Hata mesajı gösterme
      notifyListeners();
    }
  }

  // Interstitial reklam yükle
  Future<void> loadInterstitialAd() async {
    try {
      _error = null;
      notifyListeners();

      await InterstitialAd.load(
        adUnitId: _getInterstitialAdUnitId(),
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isInterstitialAdLoaded = true;
            notifyListeners();
          },
          onAdFailedToLoad: (error) {
            _isInterstitialAdLoaded = false;
            _error = null; // Hata mesajı gösterme
            notifyListeners();
          },
        ),
      );
    } catch (e) {
      _error = null; // Hata mesajı gösterme
      notifyListeners();
    }
  }

  // Rewarded reklam yükle
  Future<void> loadRewardedAd() async {
    try {
      _error = null;
      notifyListeners();

      await RewardedAd.load(
        adUnitId: _getRewardedAdUnitId(),
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isRewardedAdLoaded = true;
            notifyListeners();
          },
          onAdFailedToLoad: (error) {
            _isRewardedAdLoaded = false;
            _error = null; // Hata mesajı gösterme
            notifyListeners();
          },
        ),
      );
    } catch (e) {
      _error = null; // Hata mesajı gösterme
      notifyListeners();
    }
  }

  // Interstitial reklam göster
  Future<void> showInterstitialAd() async {
    if (_interstitialAd != null && _isInterstitialAdLoaded) {
      await _interstitialAd!.show();
      _interstitialAd = null;
      _isInterstitialAdLoaded = false;
      notifyListeners();
      
      // Yeni reklam yükle
      loadInterstitialAd();
    }
  }

  // Rewarded reklam göster
  Future<void> showRewardedAd({
    required VoidCallback onRewarded,
    required VoidCallback onFailed,
  }) async {
    if (_rewardedAd != null && _isRewardedAdLoaded) {
      // Reklam başlangıç zamanını kaydet
      final adStartTime = DateTime.now();
      
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          // Reklam izleme süresini hesapla
          final adDuration = DateTime.now().difference(adStartTime).inSeconds;
          
          ad.dispose();
          _rewardedAd = null;
          _isRewardedAdLoaded = false;
          notifyListeners();
          
          // Minimum 5 saniye izlendiyse ödül ver (AdMob standardı)
          if (adDuration >= 5) {
            onRewarded();
          } else {
            onFailed(); // Yeterli süre izlenmedi
          }
          
          // Yeni reklam yükle
          loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _rewardedAd = null;
          _isRewardedAdLoaded = false;
          notifyListeners();
          
          onFailed();
          // Yeni reklam yükle
          loadRewardedAd();
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (_, reward) {
          // Bu callback artık kullanılmıyor, süre kontrolü yapıyoruz
        },
      );
    } else {
      onFailed();
    }
  }

  // Banner reklamı dispose et
  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
    notifyListeners();
  }

  // Hata mesajını temizle
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Production reklam ID'leri
  String _getBannerAdUnitId() {
    if (kIsWeb) {
      return 'ca-app-pub-6540924306014912/1702659909'; // Web production banner
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-6540924306014912/1702659909'; // Android production banner
    } else {
      return 'ca-app-pub-6540924306014912/2934735716'; // iOS production banner
    }
  }

  String _getInterstitialAdUnitId() {
    if (kIsWeb) {
      return 'ca-app-pub-6540924306014912/3586587211'; // Web production interstitial
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-6540924306014912/3586587211'; // Android production interstitial
    } else {
      return 'ca-app-pub-6540924306014912/4411468910'; // iOS production interstitial
    }
  }

  String _getRewardedAdUnitId() {
    if (kIsWeb) {
      return 'ca-app-pub-6540924306014912/4040284292'; // Web production rewarded
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-6540924306014912/4040284292'; // Android production rewarded
    } else {
      return 'ca-app-pub-6540924306014912/4040284292'; // iOS production rewarded
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }
} 