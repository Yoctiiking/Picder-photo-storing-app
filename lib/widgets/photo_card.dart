import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class PhotoCard extends StatelessWidget {
  final AssetEntity photo;

  const PhotoCard({super.key, required this.photo});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: FutureBuilder<String?>(
        future: photo.mimeTypeAsync,
        builder: (context, snapshot) {
          final isGif = snapshot.data == 'image/gif';

          if (!isGif) {
            // Comportement normal pour les photos
            return AssetEntityImage(
              photo,
              isOriginal: false,
              thumbnailSize: const ThumbnailSize(800, 800),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => _errorWidget(),
            );
          }

          // ← GIF : fond flouté + GIF net par-dessus
          return Stack(
            fit: StackFit.expand,
            children: [
              // Fond flouté
              AssetEntityImage(
                photo,
                isOriginal: true,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(color: Colors.grey[900]),
              ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(color: Colors.black.withValues(alpha: 0.3)),
              ),
              // GIF net au premier plan
              AssetEntityImage(
                photo,
                isOriginal: true,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) => _errorWidget(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _errorWidget() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.white54, size: 60),
      ),
    );
  }
}