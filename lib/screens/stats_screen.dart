import 'package:flutter/material.dart';
import '../services/stats_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final StatsService _statsService = StatsService();
  Map<String, int>? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await _statsService.getStats();
    setState(() => _stats = stats);
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 Mo';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} Ko';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} Go';
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Statistiques', style: TextStyle(color: onSurface)),
      ),
      body: stats == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _HighlightCard(
                  icon: Icons.storage_rounded,
                  label: 'Espace total libéré',
                  value: _formatBytes(stats['totalBytesFreed']!),
                ),
                const SizedBox(height: 24),

                Text('Total global',
                    style: TextStyle(
                        color: onSurface.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _StatTile(icon: Icons.favorite, color: Colors.green, label: 'Photos gardées', value: '${stats['totalKept']}'),
                _StatTile(icon: Icons.delete, color: Colors.red, label: 'Photos supprimées', value: '${stats['totalDeleted']}'),
                _StatTile(icon: Icons.check_circle_outline, color: Colors.purpleAccent, label: 'Sessions de tri terminées', value: '${stats['sessions']}'),

                const SizedBox(height: 24),
                Text('Dernière session',
                    style: TextStyle(
                        color: onSurface.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _StatTile(icon: Icons.favorite, color: Colors.green, label: 'Photos gardées', value: '${stats['lastKept']}'),
                _StatTile(icon: Icons.delete, color: Colors.red, label: 'Photos supprimées', value: '${stats['lastDeleted']}'),
                _StatTile(icon: Icons.storage_rounded, color: Colors.blueAccent, label: 'Espace libéré', value: _formatBytes(stats['lastBytesFreed']!)),
              ],
            ),
    );
  }
}

// Carte mise en avant — toujours sur fond dégradé sombre, couleurs fixes
class _HighlightCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HighlightCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFe94560), Color(0xFF0f3460)],
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 40),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatTile({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: TextStyle(color: onSurface.withValues(alpha: 0.7), fontSize: 14)),
          ),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
