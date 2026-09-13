import 'package:shared_preferences/shared_preferences.dart';

// Persiste, par album, les IDs des photos qu'on a décidé de garder —
// pour ne plus les remontrer d'une session à l'autre.
class KeptPhotosService {
  String _keyFor(String albumId) => 'kept_photo_ids_$albumId';

  Future<Set<String>> getKeptIds(String albumId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_keyFor(albumId)) ?? const []).toSet();
  }

  // Ajoute de nouveaux IDs gardés à ceux déjà persistés pour cet album.
  Future<void> addKeptIds(String albumId, Set<String> newIds) async {
    if (newIds.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_keyFor(albumId)) ?? const [];
    final merged = {...existing, ...newIds};
    await prefs.setStringList(_keyFor(albumId), merged.toList());
  }

  // Oublie les photos gardées de cet album — elles repasseront dans le tri.
  Future<void> clearKeptIds(String albumId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(albumId));
  }
}
