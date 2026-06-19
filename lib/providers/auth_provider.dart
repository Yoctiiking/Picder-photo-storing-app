import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isPro = false;
  bool _isLoading = true;

  User? get user => _user;
  bool get isPro => _isPro;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _authService.authStateChanges.listen((user) async {
      _user = user;
      if (user != null) {
        _isPro = await _authService.getIsPro();
      } else {
        _isPro = false;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<String?> signUp({required String email, required String password}) async {
    try {
      await _authService.signUp(email: email, password: password);
      return null; // pas d'erreur
    } on FirebaseAuthException catch (e) {
      return _mapErrorMessage(e.code);
    }
  }

  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _authService.signIn(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapErrorMessage(e.code);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  String _mapErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'invalid-email':
        return 'Adresse email invalide';
      case 'weak-password':
        return 'Le mot de passe doit contenir au moins 6 caractères';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect';
      default:
        return 'Une erreur est survenue, réessaie';
    }
  }
}