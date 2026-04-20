import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService extends ChangeNotifier {
  static final AppSettingsService instance = AppSettingsService._();
  AppSettingsService._();

  static const _themeKey      = 'app_theme';       // 'light' | 'dark' | 'system'
  static const _autoBackupKey = 'auto_backup';      // bool
  static const _langKey       = 'app_lang';         // 'ar' | 'fr' | 'en'

  String _themeMode   = 'system';
  bool   _autoBackup  = false;
  String _lang        = 'ar';

  String get themeMode  => _themeMode;
  bool   get autoBackup => _autoBackup;
  String get lang       => _lang;

  ThemeMode get flutterThemeMode {
    switch (_themeMode) {
      case 'dark':   return ThemeMode.dark;
      case 'light':  return ThemeMode.light;
      default:       return ThemeMode.system;
    }
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _themeMode  = p.getString(_themeKey)      ?? 'system';
    _autoBackup = p.getBool(_autoBackupKey)   ?? false;
    _lang       = p.getString(_langKey)       ?? 'ar';
    notifyListeners();
  }

  Future<void> setTheme(String mode) async {
    _themeMode = mode;
    final p = await SharedPreferences.getInstance();
    await p.setString(_themeKey, mode);
    notifyListeners();
  }

  Future<void> setAutoBackup(bool val) async {
    _autoBackup = val;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_autoBackupKey, val);
    notifyListeners();
  }

  Future<void> setLang(String lang) async {
    _lang = lang;
    final p = await SharedPreferences.getInstance();
    await p.setString(_langKey, lang);
    notifyListeners();
  }
}