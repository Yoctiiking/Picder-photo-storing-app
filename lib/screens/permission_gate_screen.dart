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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: const Icon(Icons.photo_library_outlined,
                    color: Colors.white54, size: 48),
              ),

              const SizedBox(height: 32),

              const Text(
                'Accès aux photos requis',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
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
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 16,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Bouton principal
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
                      // Envoie l'utilisateur dans les Réglages système
                      await PhotoManager.openSetting();
                      // Quand il revient, on re-vérifie (via AppLifecycleObserver ci-dessous)
                    } else {
                      // Tente de re-demander la permission directement
                      if (context.mounted) {
                        context.read<PhotoSorterProvider>().loadPhotos();
                      }
                    }
                  },
                  child: Text(
                    isPermanentlyDenied
                        ? 'Ouvrir les réglages'
                        : 'Autoriser l\'accès',
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