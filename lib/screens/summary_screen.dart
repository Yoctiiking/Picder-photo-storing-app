import 'package:flutter/material.dart';
import 'package:picder/screens/swipe_screen.dart';
import 'package:provider/provider.dart';
import '../providers/photo_sorter_provider.dart';
import '../services/settings_service.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final SettingsService _settingsService = SettingsService();
  bool _confirmDelete = false;

  @override
  void initState() {
    super.initState();
    _settingsService.getConfirmDelete().then((value) {
      if (mounted) setState(() => _confirmDelete = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotoSorterProvider>();
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: provider.remaining > 0
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: onSurface.withValues(alpha: 0.7)),
                onPressed: () {
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
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
              const SizedBox(height: 24),
              Text(
                provider.remaining > 0 ? 'Valider le tri ?' : 'Tri terminé !',
                style: TextStyle(color: onSurface, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),

              _StatRow(label: 'Photos gardées', count: provider.toKeep.length, color: Colors.green),
              const SizedBox(height: 12),
              _StatRow(label: 'Photos supprimées', count: provider.toDelete.length, color: Colors.red),
              const SizedBox(height: 48),

              if (provider.toDelete.isNotEmpty)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  icon: const Icon(Icons.delete_forever),
                  label: Text('Supprimer ${provider.toDelete.length} photos définitivement'),
                  onPressed: () async {
                    bool shouldDelete = true;

                    if (_confirmDelete) {
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
                              child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      shouldDelete = confirmed == true;
                    }

                    if (shouldDelete && context.mounted) {
                      await provider.confirmDeletions();
                      if (context.mounted) {
                        provider.reload();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const SwipeScreen()),
                        );
                      }
                    }
                  },
                ),

              const SizedBox(height: 16),

              TextButton.icon(
                icon: Icon(Icons.refresh, color: onSurface.withValues(alpha: 0.54)),
                label: Text(
                  'Recommencer',
                  style: TextStyle(color: onSurface.withValues(alpha: 0.54)),
                ),
                onPressed: () {
                  provider.reset();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const SwipeScreen()),
                  );
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

  const _StatRow({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: onSurface.withValues(alpha: 0.7), fontSize: 16)),
        Text('$count', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
