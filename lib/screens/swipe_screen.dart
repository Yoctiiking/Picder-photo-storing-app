import 'package:flutter/material.dart';
import 'package:picder/screens/permission_gate_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../providers/photo_sorter_provider.dart';
import '../services/gallery_service.dart';
import '../widgets/photo_card.dart';
import 'summary_screen.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> with WidgetsBindingObserver {
  final CardSwiperController _swiperController = CardSwiperController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Charge les photos dès que l'écran s'ouvre
    Future.microtask(() => context.read<PhotoSorterProvider>().loadPhotos());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _swiperController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-vérifie les permissions si l'utilisateur revient des réglages
      context.read<PhotoSorterProvider>().loadPhotos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotoSorterProvider>();

    // ← NOUVEAU : vérification de permission en premier
    if (!provider.isLoading && !provider.hasPermission) {
      return PermissionGateScreen(
        isPermanentlyDenied:
            provider.permissionStatus == PermissionStatus.permanentlyDenied,
      );
    }

    // Écran de chargement
    if (provider.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Écran de fin de session
    if (provider.isFinished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SummaryScreen()),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // isEmpty après
    if (provider.allPhotos.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        // ← Bouton undo en haut à gauche
        leading: IconButton(
          icon: Icon(
            Icons.undo_rounded,
            color: provider.canUndo ? Colors.white : Colors.white24,
          ),
          onPressed: provider.canUndo
              ? () {
                  _swiperController
                      .undo(); // onUndo callback appelera provider.undo()
                }
              : null,
          tooltip: 'Annuler',
        ),
        title: Text(
          '${provider.remaining} photos restantes',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: provider.toDelete.isNotEmpty
                      ? Colors.red
                      : Colors.white24,
                ),
                onPressed: provider.toDelete.isNotEmpty
                    ? () async {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const SummaryScreen(),
                          ),
                        );
                      }
                    : null,
                tooltip: 'Supprimer maintenant',
              ),
              // Badge avec le compteur
              if (provider.toDelete.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${provider.toDelete.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Zone de swipe — prend la majorité de l'espace
          Expanded(
            child: CardSwiper(
              controller: _swiperController,
              cardsCount: provider.allPhotos.length,
              initialIndex: 0,
              // ← toujours 0, le swiper gère sa propre position interne
              numberOfCardsDisplayed: provider.allPhotos.length.clamp(1, 3),
              // empilement de 1 à 3 cartes visibles
              backCardOffset: const Offset(0, 20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              onSwipe: (previousIndex, currentIndex, direction) {
                // Callback appelé après chaque swipe
                if (direction == CardSwiperDirection.right) {
                  provider.keepPhoto();
                } else if (direction == CardSwiperDirection.left) {
                  provider.deletePhoto();
                }
                return true; // true = swipe accepté
              },
              onUndo: (previousIndex, currentIndex, direction) {
                provider.undo();
                return true;
              },
              cardBuilder:
                  (context, index, percentThresholdX, percentThresholdY) {
                    // ← garde de sécurité
                    if (index < 0 || index >= provider.allPhotos.length) {
                      return const SizedBox.shrink();
                    }
                    return PhotoCard(photo: provider.allPhotos[index]);
                  },
            ),
          ),

          // Boutons d'action en bas
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Bouton supprimer
                _ActionButton(
                  icon: Icons.close,
                  color: Colors.red,
                  label: 'Supprimer',
                  onTap: () =>
                      _swiperController.swipe(CardSwiperDirection.left),
                ),
                // Compteur
                Column(
                  children: [
                    Text(
                      '${provider.toDelete.length}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'à supprimer',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${provider.toKeep.length}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'gardées',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
                // Bouton garder
                _ActionButton(
                  icon: Icons.favorite,
                  color: Colors.green,
                  label: 'Garder',
                  onTap: () =>
                      _swiperController.swipe(CardSwiperDirection.right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget bouton d'action réutilisable
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
