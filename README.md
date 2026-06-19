# Picder 📸

> **Swipe · Sort · Clean**

Picder est une application mobile Flutter (Android / iOS) qui réinvente le tri de galerie photo grâce au geste de swipe : **swipe à droite pour garder**, **swipe à gauche pour supprimer**.

---

## Fonctionnalités

### Tri par swipe
- Pile de cartes interactives pour chaque album
- Swipe droite = garder · Swipe gauche = supprimer
- Annulation de la dernière décision (undo)
- Compteurs en temps réel (gardées / à supprimer)
- Badge rouge sur le bouton de suppression rapide
- Accès au résumé à tout moment, sans attendre la fin de l'album
- État "galerie vide" quand toutes les photos ont déjà été triées

### Retours visuels & animations
- Overlay coloré progressif (vert / rouge) selon l'amplitude du geste
- Boutons d'action animés (ScaleTransition) lors de chaque décision
- Support natif des GIFs animés avec fond flouté (BackdropFilter)

### Organisation par albums
- Grille d'albums avec miniature de couverture et compteur de photos
- Carte Picder Pro intégrée dans la grille
- Exclusion automatique des photos déjà conservées lors d'une session précédente
- Accès aux statistiques et réglages depuis la barre d'actions

### Réglages
- Thème sombre / clair / système (persisté)
- Vibrations haptiques lors des swipes
- Confirmation avant suppression définitive
- Inclusion ou exclusion des GIFs dans le tri
- Réinitialisation des statistiques
- Accès direct aux permissions galerie

### Statistiques
- Espace total libéré depuis le premier usage
- Totaux cumulés : photos gardées, supprimées, nombre de sessions
- Données de la dernière session

### Gestion des permissions
- Demande conforme aux exigences Android et iOS
- Écran bloquant dédié tant que l'autorisation n'est pas accordée
- Re-vérification automatique au retour dans l'app (cycle de vie observé)
- Support du mode "photos limitées" sur iOS

### Monétisation
- Bannière publicitaire AdMob adaptative (version gratuite)
- Bouton ✕ sur la bannière : regarde une pub récompensée pour masquer la bannière 1 heure
- Écran Picder Pro (en cours)

---

## Stack technique

| Domaine | Outil |
|---|---|
| Framework | Flutter (Dart), Material 3, thème sombre/clair/système |
| Gestion d'état | Provider — `PhotoSorterProvider` + `ThemeProvider` |
| Galerie native | `photo_manager` |
| Affichage des médias | `photo_manager_image_provider` |
| Interactions de swipe | `flutter_card_swiper` |
| Persistance locale | `shared_preferences` |
| Monétisation | `google_mobile_ads` (bannières + pub récompensée) |
| Liens externes | `url_launcher` |
| Identité visuelle | `flutter_launcher_icons`, `flutter_native_splash` |

---

## Architecture

```
lib/
├── main.dart
├── providers/
│   ├── photo_sorter_provider.dart   # Décisions de tri, album, permissions
│   └── theme_provider.dart          # Thème sombre / clair / système
├── screens/
│   ├── home_screen.dart             # Grille d'albums
│   ├── swipe_screen.dart            # Tri par swipe
│   ├── summary_screen.dart          # Résumé et confirmation
│   ├── stats_screen.dart            # Statistiques
│   ├── settings_screen.dart         # Réglages
│   ├── pro_screen.dart              # Picder Pro
│   └── permission_gate_screen.dart  # Blocage si permission refusée
├── services/
│   ├── gallery_service.dart         # Lecture albums, suppression fichiers
│   ├── stats_service.dart           # Statistiques persistantes
│   ├── settings_service.dart        # Préférences utilisateur
│   ├── ads_service.dart             # Gestion bannières AdMob
│   └── rewarded_ad_service.dart     # Publicité récompensée
└── widgets/
    ├── photo_card.dart              # Carte photo (avec support GIF)
    └── banner_ad_widget.dart        # Bannière pub avec bouton fermeture
```

---

## Modèle produit

| Version | Contenu |
|---|---|
| **Picder** (gratuit) | Tri illimité, tous les réglages, statistiques, bannières AdMob avec fermeture via pub récompensée |
| **Picder Pro** (premium) | Sans publicité, tri des vidéos, synchronisation cloud — *en cours* |

---

## Roadmap

- [x] Tri par swipe (garder / supprimer)
- [x] Organisation par albums
- [x] Support des GIFs animés
- [x] Gestion des permissions Android & iOS
- [x] Identité visuelle (logo, icône, splash screen)
- [x] Statistiques de tri persistantes
- [x] Écran de réglages complet
- [x] Monétisation via AdMob (bannière + pub récompensée)
- [ ] Détection automatique de doublons
- [ ] Suggestions intelligentes basées sur la qualité des images
- [ ] Annulation multiple en cascade
- [ ] Picder Pro (sans pub, tri vidéos, sync cloud)
- [ ] Publication App Store & Google Play

---

## Lancer le projet

```bash
# Cloner le dépôt
git clone https://github.com/Yoctiiking/Picder-photo-storing-app.git
cd Picder-photo-storing-app

# Installer les dépendances
flutter pub get

# Lancer sur un appareil connecté
flutter run
```

> ⚠️ Les IDs AdMob dans `ads_service.dart` sont des IDs de **test** Google. Remplace-les par tes vrais IDs avant de publier.
