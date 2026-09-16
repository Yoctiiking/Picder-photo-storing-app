import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive.dart';
import 'auth_screen.dart';
import 'promo_code_screen.dart';

class ProScreen extends StatelessWidget {
  const ProScreen({super.key});

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    Widget content;
    if (!authProvider.isLoggedIn) {
      content = _ProMessage(
        icon: Icons.workspace_premium,
        iconColor: Colors.amber,
        title: 'Débloque Picder Pro',
        subtitle: 'Connecte-toi pour voir ton statut et activer un code promo.',
        buttonLabel: 'Se connecter',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        ),
      );
    } else if (authProvider.isPro) {
      final expiresAt = authProvider.proExpiresAt;
      content = _ProMessage(
        icon: Icons.workspace_premium,
        iconColor: Colors.amber,
        title: 'Picder Pro actif',
        subtitle: expiresAt != null
            ? 'Valide jusqu\'au ${_formatDate(expiresAt)}'
            : null,
        footnote:
            'Tu peux maintenant trier tes vidéos en plus des photos. '
            'Sync cloud et suppression des pubs arrivent bientôt pour les membres Pro.',
      );
    } else {
      content = _ProMessage(
        icon: Icons.workspace_premium_outlined,
        iconColor: onSurface.withValues(alpha: 0.4),
        title: 'Picder Free',
        subtitle: 'Active un code promo pour débloquer Picder Pro.',
        buttonLabel: 'J\'ai un code promo',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PromoCodeScreen()),
        ),
        footnote: 'L\'abonnement payant arrive bientôt.',
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Picder Pro', style: TextStyle(color: onSurface)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.maxContentWidth(context),
          ),
          child: content,
        ),
      ),
    );
  }
}

class _ProMessage extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String? buttonLabel;
  final VoidCallback? onPressed;
  final String? footnote;

  const _ProMessage({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.buttonLabel,
    this.onPressed,
    this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 72),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              color: onSurface,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.6),
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (buttonLabel != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
              onPressed: onPressed,
              child: Text(buttonLabel!),
            ),
          ],
          if (footnote != null) ...[
            const SizedBox(height: 24),
            Text(
              footnote!,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.4),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
