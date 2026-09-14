import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:picder/screens/swipe_screen.dart';
import 'package:provider/provider.dart';
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

class _ReviewPhotoTile extends StatelessWidget {
  final AssetEntity photo;
  final bool markedForDeletion;
  final VoidCallback onTap;

  const _ReviewPhotoTile({
    required this.photo,
    required this.markedForDeletion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = markedForDeletion ? Colors.red : Colors.green;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AssetEntityImage(
              photo,
              isOriginal: false,
              thumbnailSize: const ThumbnailSize(200, 200),
              fit: BoxFit.cover,
            ),
            if (markedForDeletion)
              Container(color: Colors.red.withValues(alpha: 0.18)),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(
                  markedForDeletion ? Icons.delete : Icons.check,
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
