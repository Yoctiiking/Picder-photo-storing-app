import 'package:flutter/material.dart';
import 'package:picder/screens/swipe_screen.dart';
import 'package:provider/provider.dart';
import '../providers/photo_sorter_provider.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotoSorterProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: provider.remaining > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white70),
                onPressed: () {
                  provider.reset(); // ← recharge depuis la galerie à jour
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const SwipeScreen()),
                  );
                },
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                provider.remaining > 0 ? 'Valider le tri ?' : 'Tri terminé !',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              // Stats
              _StatRow(
                label: 'Photos gardées',
                count: provider.toKeep.length,
                color: Colors.green,
              ),
              const SizedBox(height: 12),

              _StatRow(
                label: 'Photos supprimées',
                count: provider.toDelete.length,
                color: Colors.red,
              ),
              const SizedBox(height: 48),

              // Bouton de confirmation (suppression réelle)
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
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirmer la suppression'),
                        content: Text(
                          'Tu vas supprimer ${provider.toDelete.length} photos. '
                              'Cette action est irréversible.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Supprimer',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await provider.confirmDeletions();
                      if (context.mounted) {
                        provider.reset(); // ← recharge proprement depuis la galerie
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const SwipeScreen()),
                        );
                      }
                    }
                  },
                ),

              const SizedBox(height: 16),

              // Recommencer
              TextButton.icon(
                icon: const Icon(Icons.refresh, color: Colors.white54),
                label: const Text(
                  'Recommencer',
                  style: TextStyle(color: Colors.white54),
                ),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const SwipeScreen()),
                  );
                  provider.reset();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatRow({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
