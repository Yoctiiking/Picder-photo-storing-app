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
      child: AssetEntityImage(
        photo,
        isOriginal: false,     // Utilise la miniature, pas l'original (performances)
        thumbnailSize: const ThumbnailSize(800, 800),
        fit: BoxFit.cover,     // Remplit la carte sans déformer
        errorBuilder: (context, error, stack) {
          return Container(
            color: Colors.grey[900],
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.white54, size: 60),
            ),
          );
        },
      ),
    );
  }
}