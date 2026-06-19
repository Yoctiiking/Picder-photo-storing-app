import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ads_service.dart';

class RewardedAdService {
  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  // Précharge une pub récompensée (à appeler en amont pour réduire le délai)
  void preload() {
    if (_rewardedAd != null || _isLoading) return;
    _isLoading = true;

    RewardedAd.load(
      adUnitId: AdsService.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _rewardedAd = null;
        },
      ),
    );
  }

  bool get isReady => _rewardedAd != null;

  // Affiche la pub et appelle onRewarded() seulement si l'utilisateur l'a regardée en entier
  Future<void> show({required VoidCallback onRewarded}) async {
    if (_rewardedAd == null) {
      preload(); // tente de précharger pour la prochaine fois
      return;
    }

    final ad = _rewardedAd!;
    _rewardedAd = null; // une pub ne peut être montrée qu'une fois

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preload(); // recharge une nouvelle pub pour la prochaine fois
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        preload();
      },
    );

    await ad.show(
      onUserEarnedReward: (ad, reward) {
        onRewarded(); // ← appelé uniquement si la vidéo a été vue jusqu'au bout
      },
    );
  }

  void dispose() {
    _rewardedAd?.dispose();
  }
}

typedef VoidCallback = void Function();