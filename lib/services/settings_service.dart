import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { dark, light, system }

class SettingsService {
  static const _keyTheme = 'settings_theme_mode';
  static const _keyHaptics = 'settings_haptics_enabled';
  static const _keyConfirmDelete = 'settings_confirm_delete';
  static const _keyIncludeGifs = 'settings_include_gifs';

  Future<AppThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyTheme) ?? 'dark';
    return AppThemeMode.values.firstWhere(
          (e) => e.name == value,
      orElse: () => AppThemeMode.dark,
    );
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, mode.name);
  }

  Future<bool> getHapticsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHaptics) ?? true;
  }

  Future<void> setHapticsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHaptics, value);
  }

  Future<bool> getConfirmDelete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyConfirmDelete) ?? false;
  }

  Future<void> setConfirmDelete(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyConfirmDelete, value);
  }

  Future<bool> getIncludeGifs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIncludeGifs) ?? true;
  }

  Future<void> setIncludeGifs(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIncludeGifs, value);
  }
}