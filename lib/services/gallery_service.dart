import 'package:photo_manager/photo_manager.dart';

// Enum pour savoir exactement dans quel état on est
enum PermissionStatus { granted, limited, denied, permanentlyDenied }

// Représente un album avec sa miniature et son nombre de photos
class AlbumInfo {
  final AssetPathEntity path;
  final int count;
  final AssetEntity? cover;

  AlbumInfo({required this.path, required this.count, this.cover});
}

class GalleryService {
  // Vérifie juste la permission, sans charger les photos
  Future<PermissionStatus> checkPermission() async {
    final PermissionState state = await PhotoManager.requestPermissionExtend();

    if (state == PermissionState.authorized) {
      return PermissionStatus.granted;
    } else if (state == PermissionState.limited) {
      return PermissionStatus.limited;
    } else {
      // Sur iOS, on peut distinguer denied vs permanentlyDenied
      // Sur Android 13+, après 2 refus c'est permanent
      // photo_manager expose ça via hasAccess + isAuth
      return state.hasAccess
          ? PermissionStatus.limited
          : PermissionStatus.permanentlyDenied;
    }
  }

  // Demande la permission et charge toutes les photos
  Future<List<AssetEntity>> loadPhotos({
    List<String> excludeIds = const [],
  }) async {
    // 1. Demander la permission
    final PermissionState permission =
        await PhotoManager.requestPermissionExtend();

    if (!permission.isAuth) {
      // L'utilisateur a refusé — on retourne une liste vide
      return [];
    }

    // 2. Récupérer tous les albums
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image, // images seulement (pas les vidéos)
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
      ),
    );

    if (albums.isEmpty) return [];

    // 3. Prendre le premier album (= "Tous les éléments" ou "Camera Roll")
    final AssetPathEntity allPhotos = albums.first;
    final int count = await allPhotos.assetCountAsync;
    if (count == 0) return [];

    // 4. Charger les assets (les métadonnées des photos)
    // On charge par pages de 100 pour ne pas exploser la mémoire
    final List<AssetEntity> photos = await allPhotos.getAssetListRange(
      start: 0,
      end: count,
    );

    // ← Filtre les photos déjà traitées
    if (excludeIds.isEmpty) return photos;
    return photos.where((p) => !excludeIds.contains(p.id)).toList();
  }

  // Récupère tous les albums avec leur miniature
  Future<List<AlbumInfo>> getAlbums() async {
    final PermissionState permission =
    await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) return [];

    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true, // inclut l'album "Tous les éléments"
    );

    final List<AlbumInfo> result = [];
    AlbumInfo? allPhotosAlbum;

    for (final album in albums) {
      final int count = await album.assetCountAsync;
      if (count == 0) continue;

      final covers = await album.getAssetListRange(start: 0, end: 1);
      final info = AlbumInfo(
        path: album,
        count: count,
        cover: covers.isNotEmpty ? covers.first : null,
      );

      if (album.isAll) {
        allPhotosAlbum = info;
      } else {
        result.add(info);
      }
    }

    if (result.isEmpty && allPhotosAlbum != null) return [allPhotosAlbum];
    return result;
  }

  // Charge les photos d'un album précis
  Future<List<AssetEntity>> loadPhotosFromAlbum(
      AssetPathEntity album, {
        List<String> excludeIds = const [],
      }) async {
    final int count = await album.assetCountAsync;
    if (count == 0) return [];

    final photos = await album.getAssetListRange(start: 0, end: count);
    if (excludeIds.isEmpty) return photos;
    return photos.where((p) => !excludeIds.contains(p.id)).toList();
  }

  // Supprime définitivement une liste de photos
  Future<bool> deletePhotos(List<AssetEntity> photos) async {
    final List<String> ids = photos.map((p) => p.id).toList();
    try {
      final List<String> deleted = await PhotoManager.editor.deleteWithIds(ids);
      return deleted.length == ids.length;
    } catch (e) {
      return false;
    }
  }
}
