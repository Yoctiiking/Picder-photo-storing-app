import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/gallery_service.dart';

class PhotoSorterProvider extends ChangeNotifier {
  final GalleryService _galleryService = GalleryService();

  List<AssetEntity> _allPhotos = []; // Toutes les photos
  List<AssetEntity> _toKeep = []; // Décision : garder
  List<AssetEntity> _toDelete = []; // Décision : supprimer
  int _currentIndex = 0; // Photo actuellement affichée
  bool _isLoading = false;
  bool _isFinished = false;
  PermissionStatus _permissionStatus = PermissionStatus.denied;

  // Getters (lecture seule depuis l'UI)
  List<AssetEntity> get allPhotos => _allPhotos;

  List<AssetEntity> get toKeep => _toKeep;

  List<AssetEntity> get toDelete => _toDelete;

  int get currentIndex => _currentIndex;

  bool get isLoading => _isLoading;

  bool get isFinished => _isFinished;

  int get remaining => _allPhotos.length - _currentIndex;

  PermissionStatus get permissionStatus => _permissionStatus;

  // true si on peut utiliser l'app (granted OU limited avec au moins 1 photo)
  bool get hasPermission =>
      _permissionStatus == PermissionStatus.granted ||
      _permissionStatus == PermissionStatus.limited;

  // La photo actuellement affichée
  AssetEntity? get currentPhoto =>
      _currentIndex < _allPhotos.length ? _allPhotos[_currentIndex] : null;

  // Charger les photos au démarrage
  Future<void> loadPhotos() async {
    _isLoading = true;
    notifyListeners(); // Dit à l'UI "recharge-toi"

    // 1. Vérifier la permission D'ABORD
    _permissionStatus = await _galleryService.checkPermission();

    if (!hasPermission) {
      _isLoading = false;
      notifyListeners();
      return; // Stop ici — l'UI affichera le PermissionGate
    }

    // 2. Permissions: OK - Charger les photos
    _allPhotos = await _galleryService.loadPhotos();
    _isLoading = false;
    _isFinished = _allPhotos.isEmpty;
    notifyListeners();
  }

  // Swipe droite = garder
  void keepPhoto() {
    if (currentPhoto == null) return;
    _toKeep.add(currentPhoto!);
    _advance();
  }

  // Swipe gauche = supprimer
  void deletePhoto() {
    if (currentPhoto == null) return;
    _toDelete.add(currentPhoto!);
    _advance();
  }

  // Annuler la dernière action
  void undo() {
    if (_currentIndex <= 0) return;

    _currentIndex--;
    _isFinished = false;
    final lastPhoto = _allPhotos[_currentIndex];

    // Retirer des listes de décision
    _toKeep.remove(lastPhoto);
    _toDelete.remove(lastPhoto);

    notifyListeners();
  }

  // Passe à la photo suivante
  void _advance() {
    _currentIndex++;
    if (_currentIndex >= _allPhotos.length) {
      _isFinished = true;
    }
    notifyListeners();
  }

  // Confirme et exécute les suppressions
  Future<void> confirmDeletions() async {
    if (_toDelete.isEmpty) return;
    await _galleryService.deletePhotos(_toDelete);
    _toDelete.clear();
    notifyListeners();
  }

  // Recommencer du début
  void reset() {
    _allPhotos = [];
    _toKeep = [];
    _toDelete = [];
    _currentIndex = 0;
    _isFinished = false;
    notifyListeners();
    loadPhotos();
  }
}
