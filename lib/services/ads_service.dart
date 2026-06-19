import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class AdsService {
  // IDs de TEST officiels Google — à remplacer par tes vrais IDs AdMob
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/9214589741';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    throw UnsupportedError('Plateforme non supportée');
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    throw UnsupportedError('Plateforme non supportée');
  }

  static const _keyBannerHiddenUntil = 'ads_banner_hidden_until';
  static const Duration bannerHideDuration = Duration(hours: 1);

  // Enregistre l'heure jusqu'à laquelle la bannière doit rester cachée
  Future<void> hideBannerTemporarily() async {
    final prefs = await SharedPreferences.getInstance();
    final until = DateTime.now().add(bannerHideDuration);
    await prefs.setInt(_keyBannerHiddenUntil, until.millisecondsSinceEpoch);
  }

  // Vérifie si la bannière doit être cachée actuellement
  Future<bool> isBannerHidden() async {
    final prefs = await SharedPreferences.getInstance();
    final until = prefs.getInt(_keyBannerHiddenUntil);
    if (until == null) return false;
    return DateTime.now().millisecondsSinceEpoch < until;
  }
}