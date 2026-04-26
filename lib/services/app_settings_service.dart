// lib/services/app_settings_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_translations.dart';   // ← sync Tr on lang change

/// Single source of truth for app-wide settings.
/// Extends ChangeNotifier so that any widget listening to this service
/// rebuilds automatically when a setting changes.
class AppSettingsService extends ChangeNotifier {
  static final AppSettingsService instance = AppSettingsService._();
  AppSettingsService._();

  // ── SharedPreferences keys ─────────────────────────────────────────────────
  static const _themeKey      = 'app_theme';   // 'light' | 'dark' | 'system'
  static const _autoBackupKey = 'auto_backup'; // bool
  static const _langKey       = 'app_lang';    // 'ar' | 'fr' | 'en'

  // ── State ──────────────────────────────────────────────────────────────────
  String _themeMode  = 'system';
  bool   _autoBackup = false;
  String _lang       = 'ar';

  // ── Getters ────────────────────────────────────────────────────────────────
  String get themeMode  => _themeMode;
  bool   get autoBackup => _autoBackup;
  String get lang       => _lang;

  ThemeMode get flutterThemeMode {
    switch (_themeMode) {
      case 'dark':  return ThemeMode.dark;
      case 'light': return ThemeMode.light;
      default:      return ThemeMode.system;
    }
  }

  // ── Load from disk (call once at startup, before runApp) ───────────────────
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _themeMode  = p.getString(_themeKey)    ?? 'system';
    _autoBackup = p.getBool(_autoBackupKey) ?? false;
    _lang       = p.getString(_langKey)     ?? 'ar';

    // Sync the static Tr helper so it's ready before the first frame.
    Tr.setLang(_lang);
    // No notifyListeners() here — called before the widget tree exists.
  }

  // ── Setters ────────────────────────────────────────────────────────────────

  /// Change and persist the theme mode ('light' | 'dark' | 'system').
  Future<void> setTheme(String mode) async {
    _themeMode = mode;
    final p = await SharedPreferences.getInstance();
    await p.setString(_themeKey, mode);
    notifyListeners(); // triggers MaterialApp rebuild → ThemeMode switch
  }

  /// Change and persist automatic backup preference.
  Future<void> setAutoBackup(bool val) async {
    _autoBackup = val;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_autoBackupKey, val);
    notifyListeners();
  }

  /// Change and persist the UI language ('ar' | 'fr' | 'en').
  /// Also updates the Tr static helper so all screens immediately reflect
  /// the new language on their next rebuild.
  Future<void> setLang(String lang) async {
    _lang = lang;
    Tr.setLang(lang); // ← keep static helper in sync BEFORE notifyListeners
    final p = await SharedPreferences.getInstance();
    await p.setString(_langKey, lang);
    notifyListeners(); // triggers MaterialApp rebuild → new Locale + Directionality
  }
}