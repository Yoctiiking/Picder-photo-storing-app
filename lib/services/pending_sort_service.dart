import 'package:shared_preferences/shared_preferences.dart';

// Persiste, par album, les décisions de tri PAS ENCORE confirmées
// (avant l'appui sur "Supprimer définitivement") — pour ne rien perdre
// si l'app est tuée ou si l'utilisateur retourne au menu en plein tri.
class PendingSortService {
  String _keepKeyFor(String albumId) => 'pending_keep_ids_$albumId';
  String _deleteKeyFor(String albumId) => 'pending_delete_ids_$albumId';

  Future<List<String>> getPendingKeepIds(String albumId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keepKeyFor(albumId)) ?? const [];
  }

  Future<List<String>> getPendingDeleteIds(String albumId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_deleteKeyFor(albumId)) ?? const [];
  }

  Future<void> savePending(
    String albumId, {
    required List<String> keepIds,
    required List<String> deleteIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keepKeyFor(albumId), keepIds);
    await prefs.setStringList(_deleteKeyFor(albumId), deleteIds);
  }

  Future<void> clearPending(String albumId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keepKeyFor(albumId));
    await prefs.remove(_deleteKeyFor(albumId));
  }
}
