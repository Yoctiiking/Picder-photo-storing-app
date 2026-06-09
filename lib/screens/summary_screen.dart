import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/photo_sorter_provider.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotoSorterProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
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
              const Text(
                'Tri terminé !',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              // Stats
              _StatRow(
                label: 'Photos à supprimer',
                count: provider.toDelete.length,
                color: Colors.red,
              ),
              const SizedBox(height: 48),

              _StatRow(
                label: 'Photos gardées',
                count: provider.toKeep.length,
                color: Colors.green,
              ),
              const SizedBox(height: 12),

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
                    // Dialogue de confirmation avant suppression définitive
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
                            child: const Text(
                              'Supprimer',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await provider.confirmDeletions();
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
                    MaterialPageRoute(builder: (_) => const SummaryScreen()),
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
