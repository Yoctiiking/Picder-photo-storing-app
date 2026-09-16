import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:picder/screens/swipe_screen.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../providers/auth_provider.dart';
import '../providers/photo_sorter_provider.dart';
import '../services/ads_service.dart';
import '../services/rewarded_ad_service.dart';
import '../services/settings_service.dart';
import '../utils/responsive.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final SettingsService _settingsService = SettingsService();
  final RewardedAdService _rewardedAdService = RewardedAdService();
  final AdsService _adsService = AdsService();
  bool _confirmDelete = false;

  @override
  void initState() {
    super.initState();
    _settingsService.getConfirmDelete().then((value) {
      if (mounted) setState(() => _confirmDelete = value);
    });
    if (!context.read<AuthProvider>().isPro) {
      _rewardedAdService.preload(); // ← précharge dès l'arrivée sur l'écran
    }
  }

  @override
  void dispose() {
    _rewardedAdService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotoSorterProvider>();
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final columns = Responsive.reviewGridColumns(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: provider.remaining > 0
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: onSurface.withValues(alpha: 0.7),
                ),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const SwipeScreen()),
                  );
                },
              )
            : null,
        title: Text(
          provider.remaining > 0 ? 'Valider le tri ?' : 'Tri terminé !',
          style: TextStyle(color: onSurface),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.maxSwipeWidth(context),
            ),
            child: Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      if (provider.toDelete.isNotEmpty) ...[
                        _SectionHeader(
                          label: 'À supprimer (${provider.toDelete.length})',
                          color: Colors.red,
                        ),
                        _ReviewGrid(
                          photos: provider.toDelete,
                          markedForDeletion: true,
                          columns: columns,
                          onToggle: provider.toggleDecision,
                        ),
                      ],
                      if (provider.toKeep.isNotEmpty) ...[
                        _SectionHeader(
                          label: 'Gardées (${provider.toKeep.length})',
                          color: Colors.green,
                        ),
                        _ReviewGrid(
                          photos: provider.toKeep,
                          markedForDeletion: false,
                          columns: columns,
                          onToggle: provider.toggleDecision,
                        ),
                      ],
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 16),
                      ),
                    ],
                  ),
                ),
                // ← Barre d'actions fixe : jamais besoin de scroller pour supprimer
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  child: Column(
                    children: [
                      if (provider.toDelete.isNotEmpty)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          icon: const Icon(Icons.delete_forever),
                          label: Text(
                            'Supprimer ${provider.toDelete.length} photos définitivement',
                          ),
                          onPressed: () async {
                            bool shouldDelete = true;

                            if (_confirmDelete) {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text(
                                    'Confirmer la suppression',
                                  ),
                                  content: Text(
                                    'Tu vas supprimer ${provider.toDelete.length} photos. '
                                    'Cette action est irréversible.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Annuler'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      child: const Text(
                                        'Supprimer',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              shouldDelete = confirmed == true;
                            }

                            if (shouldDelete && context.mounted) {
                              await provider.confirmDeletions();

                              // ← Lance directement la vidéo récompensée, sans demander
                              // (jamais pour les membres Pro, ni avant la fin du délai de 5 min)
                              final isPro =
                                  context.mounted &&
                                  context.read<AuthProvider>().isPro;
                              if (!isPro &&
                                  _rewardedAdService.isReady &&
                                  await _adsService.canShowDeletionAd()) {
                                await _rewardedAdService.show(
                                  onRewarded: () {},
                                );
                                await _adsService.recordDeletionAdShown();
                              }

                              if (context.mounted) {
                                provider.reload();
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const SwipeScreen(),
                                  ),
                                );
                              }
                            }
                          },
                        ),

                      const SizedBox(height: 12),

                      TextButton.icon(
                        icon: Icon(
                          Icons.refresh,
                          color: onSurface.withValues(alpha: 0.54),
                        ),
                        label: Text(
                          'Recommencer',
                          style: TextStyle(
                            color: onSurface.withValues(alpha: 0.54),
                          ),
                        ),
                        onPressed: () {
                          provider.reset();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const SwipeScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ReviewGrid extends StatelessWidget {
  final List<AssetEntity> photos;
  final bool markedForDeletion;
  final int columns;
  final ValueChanged<AssetEntity> onToggle;

  const _ReviewGrid({
    required this.photos,
    required this.markedForDeletion,
    required this.columns,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final photo = photos[index];
            return _ReviewPhotoTile(
              photo: photo,
              markedForDeletion: markedForDeletion,
              onTap: () => onToggle(photo),
            );
          },
          childCount: photos.length,
        ),
      ),
    );
  }
}

class _ReviewPhotoTile extends StatefulWidget {
  final AssetEntity photo;
  final bool markedForDeletion;
  final VoidCallback onTap;

  const _ReviewPhotoTile({
    required this.photo,
    required this.markedForDeletion,
    required this.onTap,
  });

  @override
  State<_ReviewPhotoTile> createState() => _ReviewPhotoTileState();
}

class _ReviewPhotoTileState extends State<_ReviewPhotoTile> {
  OverlayEntry? _previewEntry;

  // ← Maintenir une tuile l'affiche en grand par-dessus tout, pour être
  // sûr de ce qu'on a sélectionné avant de confirmer. L'aperçu reste
  // affiché même après avoir relâché, jusqu'à un tap en dehors du média.
  void _showPreview() {
    if (_previewEntry != null) return;
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => _PhotoPreviewOverlay(
        photo: widget.photo,
        markedForDeletion: widget.markedForDeletion,
        onDismiss: _hidePreview,
      ),
    );
    _previewEntry = entry;
    overlay.insert(entry);
  }

  void _hidePreview() {
    _previewEntry?.remove();
    _previewEntry = null;
  }

  @override
  void dispose() {
    _previewEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.markedForDeletion ? Colors.red : Colors.green;
    return GestureDetector(
      onTap: widget.onTap,
      onLongPressStart: (_) => _showPreview(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AssetEntityImage(
              widget.photo,
              isOriginal: false,
              thumbnailSize: const ThumbnailSize(200, 200),
              fit: BoxFit.cover,
            ),
            if (widget.photo.type == AssetType.video)
              const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            if (widget.markedForDeletion)
              Container(color: Colors.red.withValues(alpha: 0.18)),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(
                  widget.markedForDeletion ? Icons.delete : Icons.check,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ← Aperçu plein écran affiché après un appui long, jusqu'à un tap
// en dehors du média (les vidéos se lancent automatiquement)
class _PhotoPreviewOverlay extends StatelessWidget {
  final AssetEntity photo;
  final bool markedForDeletion;
  final VoidCallback onDismiss;

  const _PhotoPreviewOverlay({
    required this.photo,
    required this.markedForDeletion,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final color = markedForDeletion ? Colors.red : Colors.green;
    return Positioned.fill(
      child: GestureDetector(
        onTap: onDismiss,
        child: Container(
          color: Colors.black87,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: GestureDetector(
                // ← Absorbe le tap pour que toucher le média ne ferme pas l'aperçu
                onTap: () {},
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color, width: 3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        photo.type == AssetType.video
                            ? _VideoPreviewPlayer(photo: photo)
                            : AssetEntityImage(
                                photo,
                                isOriginal: true,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stack) => const Padding(
                                  padding: EdgeInsets.all(48),
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.white54,
                                    size: 60,
                                  ),
                                ),
                              ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              markedForDeletion ? Icons.delete : Icons.check,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ← Charge et lit la vidéo en boucle dès que l'aperçu s'ouvre
class _VideoPreviewPlayer extends StatefulWidget {
  final AssetEntity photo;

  const _VideoPreviewPlayer({required this.photo});

  @override
  State<_VideoPreviewPlayer> createState() => _VideoPreviewPlayerState();
}

class _VideoPreviewPlayerState extends State<_VideoPreviewPlayer> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final file = await widget.photo.file;
    if (file == null || !mounted) return;
    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    if (!mounted) {
      controller.dispose();
      return;
    }
    controller
      ..setLooping(true)
      ..play();
    setState(() => _controller = controller);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return Stack(
        fit: StackFit.expand,
        children: [
          AssetEntityImage(
            widget.photo,
            isOriginal: false,
            thumbnailSize: const ThumbnailSize(800, 800),
            fit: BoxFit.contain,
          ),
          Container(color: Colors.black45),
          const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ],
      );
    }
    return Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: VideoPlayer(controller),
      ),
    );
  }
}
