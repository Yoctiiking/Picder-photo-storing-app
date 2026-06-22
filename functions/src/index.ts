/* eslint-disable eol-last */
/* eslint-disable object-curly-spacing */
/* eslint-disable operator-linebreak */
/* eslint-disable max-len */
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();

export const redeemPromoCode = functions.https.onCall(async (request) => {
  // 1. Vérifie que l'utilisateur est connecté
  if (!request.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Tu dois être connecté pour utiliser un code promo."
    );
  }

  const uid = request.auth.uid;
  const rawCode = request.data.code;

  if (!rawCode || typeof rawCode !== "string") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Code invalide."
    );
  }

  const code = rawCode.trim().toUpperCase();
  const codeRef = db.collection("promoCodes").doc(code);
  const userRef = db.collection("users").doc(uid);

  // 2. Transaction — même logique qu'avant, mais côté serveur maintenant
  return db.runTransaction(async (transaction) => {
    const codeSnap = await transaction.get(codeRef);

    if (!codeSnap.exists) {
      throw new functions.https.HttpsError("not-found", "notFound");
    }

    const data = codeSnap.data()!;
    const isActive = data.isActive as boolean ?? false;
    const expiresAt = data.expiresAt?.toDate() as Date | undefined;
    const maxUses = data.maxUses as number ?? -1;
    const usedCount = data.usedCount as number ?? 0;
    const durationDays = data.durationDays as number ?? 0;
    const usedBy = (data.usedBy as string[]) ?? [];

    if (!isActive) {
      throw new functions.https.HttpsError("failed-precondition", "inactive");
    }
    if (expiresAt && expiresAt < new Date()) {
      throw new functions.https.HttpsError("failed-precondition", "expired");
    }
    if (maxUses !== -1 && usedCount >= maxUses) {
      throw new functions.https.HttpsError("resource-exhausted", "maxUsesReached");
    }
    if (usedBy.includes(uid)) {
      throw new functions.https.HttpsError("already-exists", "alreadyUsed");
    }

    // 3. Calcule la nouvelle date d'expiration Pro
    const userSnap = await transaction.get(userRef);
    const currentExpiresAt = userSnap.data()?.proExpiresAt?.toDate() as Date | undefined;
    const base =
      currentExpiresAt && currentExpiresAt > new Date()
        ? currentExpiresAt
        : new Date();
    const newExpiresAt = new Date(base);
    newExpiresAt.setDate(newExpiresAt.getDate() + durationDays);

    // 4. Met à jour Firestore
    transaction.update(codeRef, {
      usedCount: usedCount + 1,
      usedBy: admin.firestore.FieldValue.arrayUnion(uid),
    });

    transaction.update(userRef, {
      proExpiresAt: admin.firestore.Timestamp.fromDate(newExpiresAt),
    });

    return { success: true };
  });
});