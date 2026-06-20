import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum PromoCodeResult {
  success,
  notFound,
  expired,
  maxUsesReached,
  inactive,
  alreadyUsedByUser,
}

class PromoCodeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Valide et applique un code promo pour l'utilisateur connecté
  Future<PromoCodeResult> redeemCode(String rawCode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return PromoCodeResult.notFound;

    final code = rawCode.trim().toUpperCase();
    final codeRef = _firestore.collection('promoCodes').doc(code);
    final userRef = _firestore.collection('users').doc(user.uid);

    // ← Transaction : garantit qu'aucune course de concurrence ne permette
    // de dépasser maxUses si plusieurs personnes valident en même temps
    return _firestore.runTransaction<PromoCodeResult>((transaction) async {
      final codeSnap = await transaction.get(codeRef);

      if (!codeSnap.exists) return PromoCodeResult.notFound;

      final data = codeSnap.data()!;
      final isActive = data['isActive'] as bool? ?? false;
      final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
      final maxUses = data['maxUses'] as int? ?? -1;
      final usedCount = data['usedCount'] as int? ?? 0;
      final durationDays = data['durationDays'] as int? ?? 0;
      final usedBy = List<String>.from(data['usedBy'] ?? []);

      if (!isActive) return PromoCodeResult.inactive;
      if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
        return PromoCodeResult.expired;
      }
      if (maxUses != -1 && usedCount >= maxUses) {
        return PromoCodeResult.maxUsesReached;
      }
      if (usedBy.contains(user.uid)) {
        return PromoCodeResult.alreadyUsedByUser;
      }

      // Calcule la nouvelle date d'expiration Pro
      final userSnap = await transaction.get(userRef);
      final currentExpiresAt =
      (userSnap.data()?['proExpiresAt'] as Timestamp?)?.toDate();
      final base = (currentExpiresAt != null && currentExpiresAt.isAfter(DateTime.now()))
          ? currentExpiresAt // ← prolonge si déjà Pro et encore actif
          : DateTime.now();
      final newExpiresAt = base.add(Duration(days: durationDays));

      transaction.update(codeRef, {
        'usedCount': usedCount + 1,
        'usedBy': FieldValue.arrayUnion([user.uid]),
      });

      transaction.update(userRef, {
        'proExpiresAt': Timestamp.fromDate(newExpiresAt),
      });

      return PromoCodeResult.success;
    });
  }

  // Crée un nouveau code promo (à utiliser depuis la plateforme admin plus tard,
  // mais utile aussi pour tester depuis l'app en attendant)
  Future<void> createCode({
    required String code,
    required int durationDays,
    required int maxUses, // -1 pour illimité
    DateTime? expiresAt,
  }) async {
    await _firestore.collection('promoCodes').doc(code.toUpperCase()).set({
      'code': code.toUpperCase(),
      'durationDays': durationDays,
      'maxUses': maxUses,
      'usedCount': 0,
      'usedBy': <String>[],
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
  }
}