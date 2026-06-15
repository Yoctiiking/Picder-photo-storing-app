import 'package:shared_preferences/shared_preferences.dart';

class SessionStats {
  final int kept;
  final int deleted;
  final int bytesFreed;

  SessionStats({required this.kept, required this.deleted, required this.bytesFreed});
}

class StatsService {
  static const _keyTotalKept = 'stats_total_kept';
  static const _keyTotalDeleted = 'stats_total_deleted';
  static const _keyTotalBytesFreed = 'stats_total_bytes_freed';
  static const _keySessions = 'stats_sessions_count';

  static const _keyLastKept = 'stats_last_kept';
  static const _keyLastDeleted = 'stats_last_deleted';
  static const _keyLastBytesFreed = 'stats_last_bytes_freed';

  // Enregistre une session terminée (appelé après confirmDeletions)
  Future<void> recordSession({
    required int kept,
    required int deleted,
    required int bytesFreed,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Totaux globaux — on additionne
    final totalKept = (prefs.getInt(_keyTotalKept) ?? 0) + kept;
    final totalDeleted = (prefs.getInt(_keyTotalDeleted) ?? 0) + deleted;
    final totalBytes = (prefs.getInt(_keyTotalBytesFreed) ?? 0) + bytesFreed;
    final sessions = (prefs.getInt(_keySessions) ?? 0) + 1;

    await prefs.setInt(_keyTotalKept, totalKept);
    await prefs.setInt(_keyTotalDeleted, totalDeleted);
    await prefs.setInt(_keyTotalBytesFreed, totalBytes);
    await prefs.setInt(_keySessions, sessions);

    // Dernière session — on remplace
    await prefs.setInt(_keyLastKept, kept);
    await prefs.setInt(_keyLastDeleted, deleted);
    await prefs.setInt(_keyLastBytesFreed, bytesFreed);
  }

  // Récupère toutes les statistiques
  Future<Map<String, int>> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'totalKept': prefs.getInt(_keyTotalKept) ?? 0,
      'totalDeleted': prefs.getInt(_keyTotalDeleted) ?? 0,
      'totalBytesFreed': prefs.getInt(_keyTotalBytesFreed) ?? 0,
      'sessions': prefs.getInt(_keySessions) ?? 0,
      'lastKept': prefs.getInt(_keyLastKept) ?? 0,
      'lastDeleted': prefs.getInt(_keyLastDeleted) ?? 0,
      'lastBytesFreed': prefs.getInt(_keyLastBytesFreed) ?? 0,
    };
  }
}