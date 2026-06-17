import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/settings_service.dart';
import '../services/stats_service.dart';
import 'pro_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final StatsService _statsService = StatsService();

  bool _haptics = true;
  bool _confirmDelete = false;
  bool _includeGifs = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final haptics = await _settingsService.getHapticsEnabled();
    final confirmDelete = await _settingsService.getConfirmDelete();
    final includeGifs = await _settingsService.getIncludeGifs();
    setState(() {
      _haptics = haptics;
      _confirmDelete = confirmDelete;
      _includeGifs = includeGifs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Réglages', style: TextStyle(color: onSurface)),
      ),
      body: ListView(
        children: [
          _SectionHeader('Abonnement'),
          _SettingsTile(
            icon: Icons.workspace_premium,
            iconColor: Colors.amber,
            title: 'Picder Free',
            subtitle: 'Découvrir Picder Pro',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProScreen()),
            ),
          ),

          _SectionHeader('Apparence'),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'Thème',
            subtitle: _themeLabel(themeProvider.mode),
            onTap: _showThemePicker,
          ),

          _SectionHeader('Comportement du tri'),
          _SettingsSwitchTile(
            icon: Icons.vibration,
            title: 'Vibrations',
            subtitle: 'Retour haptique lors des swipes',
            value: _haptics,
            onChanged: (v) {
              setState(() => _haptics = v);
              _settingsService.setHapticsEnabled(v);
            },
          ),
          _SettingsSwitchTile(
            icon: Icons.warning_amber_rounded,
            title: 'Confirmation de suppression',
            subtitle: 'Demander confirmation avant suppression définitive',
            value: _confirmDelete,
            onChanged: (v) {
              setState(() => _confirmDelete = v);
              _settingsService.setConfirmDelete(v);
            },
          ),
          _SettingsSwitchTile(
            icon: Icons.gif_box_outlined,
            title: 'Inclure les GIFs',
            subtitle: 'Afficher les GIFs animés pendant le tri',
            value: _includeGifs,
            onChanged: (v) {
              setState(() => _includeGifs = v);
              _settingsService.setIncludeGifs(v);
            },
          ),

          _SectionHeader('Données et confidentialité'),
          _SettingsTile(
            icon: Icons.refresh,
            title: 'Réinitialiser les statistiques',
            onTap: _confirmResetStats,
          ),
          _SettingsTile(
            icon: Icons.photo_library_outlined,
            title: 'Permissions de la galerie',
            subtitle: 'Gérer dans les réglages système',
            onTap: () => PhotoManager.openSetting(),
          ),

          _SectionHeader('À propos'),
          const _SettingsTile(
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: '1.0.0',
          ),
          _SettingsTile(
            icon: Icons.code,
            title: 'Code source',
            subtitle: 'Voir le projet sur GitHub',
            onTap: () {
              _openUrl('https://github.com/Yoctiiking/Picder-photo-storing-app');
            },
          ),
          _SettingsTile(
            icon: Icons.star_outline,
            title: 'Évaluer Picder',
            subtitle: 'Laisser un avis sur le store',
            onTap: () {
              // TODO: ouvrir la fiche store via url_launcher
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _themeLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dark:
        return 'Sombre';
      case AppThemeMode.light:
        return 'Clair';
      case AppThemeMode.system:
        return 'Système';
    }
  }

  void _showThemePicker() {
    final themeProvider = context.read<ThemeProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((mode) {
            return ListTile(
              title: Text(_themeLabel(mode),
                  style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface)),
              trailing: themeProvider.mode == mode
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                themeProvider.setMode(mode);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir le lien')),
      );
    }
  }

  Future<void> _confirmResetStats() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réinitialiser les statistiques ?'),
        content: const Text(
            'Cette action effacera toutes tes statistiques de tri. Elle est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Réinitialiser', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _statsService.resetStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Statistiques réinitialisées')),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: onSurface.withValues(alpha: 0.38),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: iconColor ?? onSurface.withValues(alpha: 0.7)),
      title: Text(title, style: TextStyle(color: onSurface)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: TextStyle(color: onSurface.withValues(alpha: 0.38), fontSize: 12))
          : null,
      trailing: onTap != null
          ? Icon(Icons.chevron_right, color: onSurface.withValues(alpha: 0.24))
          : null,
      onTap: onTap,
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SwitchListTile(
      secondary: Icon(icon, color: onSurface.withValues(alpha: 0.7)),
      title: Text(title, style: TextStyle(color: onSurface)),
      subtitle: Text(subtitle,
          style: TextStyle(color: onSurface.withValues(alpha: 0.38), fontSize: 12)),
      value: value,
      activeThumbColor: Colors.green,
      onChanged: onChanged,
    );
  }
}
