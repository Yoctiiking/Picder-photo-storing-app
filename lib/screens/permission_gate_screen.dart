import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import '../providers/photo_sorter_provider.dart';

class PermissionGateScreen extends StatelessWidget {
  final bool isPermanentlyDenied;

  const PermissionGateScreen({
    super.key,
    this.isPermanentlyDenied = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: onSurface.withValues(alpha: 0.24), width: 2),
                ),
                child: Icon(Icons.photo_library_outlined,
                    color: onSurface.withValues(alpha: 0.54), size: 48),
              ),

              const SizedBox(height: 32),

              Text(
                'Accès aux photos requis',
                style: TextStyle(color: onSurface, fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                isPermanentlyDenied
                    ? 'Tu as refusé l\'accès définitivement.\n'
                        'Va dans Réglages > Picder > Photos\n'
                        'et autorise au moins une photo.'
                    : 'Pour utiliser Picder, tu dois autoriser\n'
                        'l\'accès à au moins une photo de ta galerie.',
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.6),
                  fontSize: 16,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (isPermanentlyDenied) {
                      await PhotoManager.openSetting();
                    } else {
                      if (context.mounted) {
                        context.read<PhotoSorterProvider>().loadPhotos();
                      }
                    }
                  },
                  child: Text(
                    isPermanentlyDenied ? 'Ouvrir les réglages' : 'Autoriser l\'accès',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
