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

class _SwipeScreenState extends State<SwipeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final CardSwiperController _swiperController = CardSwiperController();

  late final AnimationController _deleteAnimCtrl;
  late final AnimationController _keepAnimCtrl;
  late final Animation<double> _deleteScale;
  late final Animation<double> _keepScale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _deleteAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _keepAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _deleteScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _deleteAnimCtrl, curve: Curves.easeInOut));
    _keepScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _keepAnimCtrl, curve: Curves.easeInOut));

    Future.microtask(() {
      // ignore: use_build_context_synchronously
      final provider = context.read<PhotoSorterProvider>();
      if (provider.allPhotos.isEmpty) {
        provider.loadPhotos();
      } else {
        provider.resetIndex();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _swiperController.dispose();
    _deleteAnimCtrl.dispose();
    _keepAnimCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<PhotoSorterProvider>().loadPhotos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotoSorterProvider>();
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    if (!provider.isLoading && !provider.hasPermission) {
      return PermissionGateScreen(
        isPermanentlyDenied:
            provider.permissionStatus == PermissionStatus.permanentlyDenied,
      );
    }

    if (provider.isLoading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.isFinished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SummaryScreen()),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (provider.allPhotos.isEmpty) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.grid_view_outlined, color: onSurface.withValues(alpha: 0.7)),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Retour au menu',
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_library_outlined, color: onSurface.withValues(alpha: 0.24), size: 80),
              const SizedBox(height: 24),
              Text(
                'Galerie vide',
                style: TextStyle(color: onSurface, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Toutes tes photos ont déjà été triées.',
                style: TextStyle(color: onSurface.withValues(alpha: 0.54), fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.grid_view_outlined, color: onSurface.withValues(alpha: 0.7)),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Retour au menu',
        ),
        title: Text(
          '${provider.remaining} photos restantes',
          style: TextStyle(color: onSurface.withValues(alpha: 0.7), fontSize: 14),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.undo_rounded,
              color: provider.canUndo ? onSurface : onSurface.withValues(alpha: 0.24),
            ),
            onPressed: provider.canUndo ? () => _swiperController.undo() : null,
            tooltip: 'Annuler',
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: provider.toDelete.isNotEmpty ? Colors.red : onSurface.withValues(alpha: 0.24),
                ),
                onPressed: provider.toDelete.isNotEmpty
                    ? () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const SummaryScreen()),
                        )
                    : null,
                tooltip: 'Supprimer maintenant',
              ),
              if (provider.toDelete.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text(
                      '${provider.toDelete.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CardSwiper(
              controller: _swiperController,
              cardsCount: provider.allPhotos.length,
              initialIndex: 0,
              numberOfCardsDisplayed: provider.allPhotos.length.clamp(1, 3),
              backCardOffset: const Offset(0, 20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              onSwipe: (previousIndex, currentIndex, direction) {
                if (direction == CardSwiperDirection.right) {
                  provider.keepPhoto();
                  _keepAnimCtrl.forward(from: 0);
                } else if (direction == CardSwiperDirection.left) {
                  provider.deletePhoto();
                  _deleteAnimCtrl.forward(from: 0);
                }
                return true;
              },
              onUndo: (previousIndex, currentIndex, direction) {
                provider.undo();
                return true;
              },
              cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                if (index < 0 || index >= provider.allPhotos.length) {
                  return const SizedBox.shrink();
                }
                return Stack(
                  children: [
                    PhotoCard(photo: provider.allPhotos[index]),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Builder(builder: (_) {
                            final t = (percentThresholdX.abs() / 100).clamp(0.0, 1.0);
                            final alpha = t * t * t * t * 0.7;
                            return Container(
                              color: percentThresholdX > 0
                                  ? Colors.green.withValues(alpha: alpha)
                                  : Colors.red.withValues(alpha: alpha),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionButton(
                  icon: Icons.close,
                  color: Colors.red,
                  label: 'Supprimer',
                  scaleAnimation: _deleteScale,
                  onTap: () => _swiperController.swipe(CardSwiperDirection.left),
                ),
                Column(
                  children: [
                    Text(
                      '${provider.toDelete.length}',
                      style: const TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text('à supprimer', style: TextStyle(color: onSurface.withValues(alpha: 0.54), fontSize: 11)),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${provider.toKeep.length}',
                      style: const TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text('gardées', style: TextStyle(color: onSurface.withValues(alpha: 0.54), fontSize: 11)),
                  ],
                ),
                _ActionButton(
                  icon: Icons.favorite,
                  color: Colors.green,
                  label: 'Garder',
                  scaleAnimation: _keepScale,
                  onTap: () => _swiperController.swipe(CardSwiperDirection.right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final Animation<double> scaleAnimation;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          ScaleTransition(
            scale: scaleAnimation,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
