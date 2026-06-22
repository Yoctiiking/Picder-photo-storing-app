import 'package:cloud_functions/cloud_functions.dart';

enum PromoCodeResult {
  success,
  notFound,
  expired,
  maxUsesReached,
  inactive,
  alreadyUsedByUser,
}

class PromoCodeService {
  final FirebaseFunctions _functions =
  FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<PromoCodeResult> redeemCode(String rawCode) async {
    try {
      final callable = _functions.httpsCallable('redeemPromoCode');
      await callable.call({'code': rawCode.trim().toUpperCase()});
      return PromoCodeResult.success;
    } on FirebaseFunctionsException catch (e) {
      return _mapError(e.message ?? '');
    } catch (e) {
      return PromoCodeResult.notFound;
    }
  }

  PromoCodeResult _mapError(String message) {
    switch (message) {
      case 'notFound':
        return PromoCodeResult.notFound;
      case 'expired':
        return PromoCodeResult.expired;
      case 'maxUsesReached':
        return PromoCodeResult.maxUsesReached;
      case 'inactive':
        return PromoCodeResult.inactive;
      case 'alreadyUsed':
        return PromoCodeResult.alreadyUsedByUser;
      default:
        return PromoCodeResult.notFound;
    }
  }
}