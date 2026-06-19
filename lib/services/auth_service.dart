import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Flux qui notifie chaque changement de connexion/déconnexion
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // Inscription avec email/mot de passe
  Future<User?> signUp({required String email, required String password}) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      // Crée le document Firestore associé avec le statut Pro par défaut
      await _firestore.collection('users').doc(user.uid).set({
        'email': email,
        'isPro': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return user;
  }

  // Connexion avec email/mot de passe
  Future<User?> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Récupère le statut Pro de l'utilisateur connecté
  Future<bool> getIsPro() async {
    final user = currentUser;
    if (user == null) return false;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data()?['isPro'] ?? false;
  }
}