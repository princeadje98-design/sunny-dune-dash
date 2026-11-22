import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Mode automatique :
/// - build normal / test  -> pubs de TEST (sans risque)
/// - build avec --dart-define=PROD=true -> VRAIES pubs
const bool kUseTestAds = !bool.fromEnvironment('PROD');

class AdIds {
  // IDs de TEST officiels Google (Android)
  static const _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const _testRewarded = 'ca-app-pub-3940256099942544/5224354917';

  // Tes vrais IDs AdMob (App ID : ca-app-pub-8825505611074662~7640228894)
  static const _realBanner = 'ca-app-pub-8825505611074662/2196330526';
  static const _realInterstitial = 'ca-app-pub-8825505611074662/1692486383';
  static const _realRewarded = 'ca-app-pub-8825505611074662/9555945793';

  static String get banner => kUseTestAds ? _testBanner : _realBanner;
  static String get interstitial =>
      kUseTestAds ? _testInterstitial : _realInterstitial;
  static String get rewarded => kUseTestAds ? _testRewarded : _realRewarded;
}

class AdManager {
  AdManager._();
  static final AdManager instance = AdManager._();

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;

  bool get rewardedReady => _rewarded != null;

  void loadInterstitial() {
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  /// Affiche l'interstitielle si prête, puis appelle [onDone] dans tous les cas.
  void showInterstitial(VoidCallback onDone) {
    final ad = _interstitial;
    if (ad == null) {
      loadInterstitial();
      onDone();
      return;
    }
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        loadInterstitial();
        onDone();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        loadInterstitial();
        onDone();
      },
    );
    ad.show();
  }

  void loadRewarded() {
    RewardedAd.load(
      adUnitId: AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (_) => _rewarded = null,
      ),
    );
  }

  /// Vidéo récompensée : [onReward] est appelé seulement si le joueur la regarde.
  void showRewarded({required VoidCallback onReward}) {
    final ad = _rewarded;
    if (ad == null) {
      loadRewarded();
      return;
    }
    _rewarded = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        loadRewarded();
      },
    );
    ad.show(onUserEarnedReward: (_, __) => onReward());
  }
}

/// Bannière adaptative simple à placer en bas d'un écran.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});
  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _banner = BannerAd(
      adUnitId: AdIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _loaded = true),
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _banner == null) return const SizedBox(height: 50);
    return SizedBox(
      width: _banner!.size.width.toDouble(),
      height: _banner!.size.height.toDouble(),
      child: AdWidget(ad: _banner!),
    );
  }
}
