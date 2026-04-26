// lib/screens/app_settings_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../database_helper.dart';
import '../services/app_settings_service.dart';
import '../utils/app_translations.dart';

const _kPrimary = Color(0xFF1B8A6B);
const _kRed     = Color(0xFFD32F2F);

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  final _svc = AppSettingsService.instance;
  bool _backingUp = false;

  @override
  void initState() {
    super.initState();
    // Rebuild this screen whenever the service changes (e.g. after lang switch).
    _svc.addListener(_refresh);
  }

  @override
  void dispose() {
    _svc.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        title: Text(
          Tr.s('settings'),
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Appearance ───────────────────────────────────────────────────────
          _sectionTitle(Tr.s('appearance')),
          _card(children: [
            _themeOption(Tr.s('light'),      'light',  Icons.wb_sunny_outlined),
            _divider(),
            _themeOption(Tr.s('dark'),       'dark',   Icons.nightlight_round),
            _divider(),
            _themeOption(Tr.s('system_auto'),'system', Icons.phone_android_outlined),
          ]),

          const SizedBox(height: 16),

          // ── Language ─────────────────────────────────────────────────────────
          _sectionTitle(Tr.s('language')),
          _card(children: [
            _langOption('العربية 🇲🇦', 'ar'),
            _divider(),
            _langOption('Français 🇫🇷', 'fr'),
            _divider(),
            _langOption('English 🇬🇧',  'en'),
          ]),

          const SizedBox(height: 16),

          // ── Backup ───────────────────────────────────────────────────────────
          _sectionTitle(Tr.s('backup')),
          _card(children: [
            ListTile(
              leading: _iconBox(Icons.cloud_upload_outlined),
              title: Text(
                Tr.s('export_data'),
                style: const TextStyle(
                    fontFamily: 'Cairo', fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                Tr.s('export_desc'),
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              trailing: _backingUp
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kPrimary),
                    )
                  : const Icon(Icons.chevron_left, color: Colors.grey),
              onTap: _backingUp ? null : _exportBackup,
            ),
          ]),

          const SizedBox(height: 32),

          // ── Danger zone ───────────────────────────────────────────────────────
          _card(children: [
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined,
                  color: _kRed, size: 28),
              title: Text(
                Tr.s('delete_all'),
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                    color: _kRed),
              ),
              subtitle: Text(
                Tr.s('delete_all_desc'),
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              onTap: _confirmDeleteAll,
            ),
          ]),

          const SizedBox(height: 24),

          // ── About ─────────────────────────────────────────────────────────────
          _sectionTitle(Tr.s('about')),
          _card(children: [
            ListTile(
              leading: _iconBox(Icons.info_outline),
              title: Text(
                Tr.s('app_name'),
                style: const TextStyle(
                    fontFamily: 'Cairo', fontWeight: FontWeight.w600),
              ),
              trailing: const Text(
                'كارنيه',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
              ),
            ),
            _divider(),
            ListTile(
              leading: _iconBox(Icons.tag),
              title: Text(
                Tr.s('version'),
                style: const TextStyle(
                    fontFamily: 'Cairo', fontWeight: FontWeight.w600),
              ),
              trailing: const Text(
                '1.0.0',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
              ),
            ),
          ]),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Helper widgets ─────────────────────────────────────────────────────────

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _card({required List<Widget> children}) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: children),
      );

  Widget _divider() =>
      const Divider(height: 1, indent: 16, endIndent: 16);

  Widget _iconBox(IconData icon) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _kPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _kPrimary),
      );

  // ── Theme option tile ──────────────────────────────────────────────────────
  Widget _themeOption(String label, String mode, IconData icon) {
    final isSelected = _svc.themeMode == mode;
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _iconBox(icon),
      title: Text(
        label,
        style: const TextStyle(
            fontFamily: 'Cairo', fontWeight: FontWeight.w600),
      ),
      trailing: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isSelected
            ? const Icon(Icons.check_circle,
                key: ValueKey('check'), color: _kPrimary, size: 26)
            : const Icon(Icons.radio_button_unchecked,
                key: ValueKey('uncheck'), color: Colors.grey),
      ),
      onTap: () async {
        await _svc.setTheme(mode);
        // setState is called by the listener registered in initState.
      },
    );
  }

  // ── Language option tile ───────────────────────────────────────────────────
  /// Switching the language does three things atomically:
  ///   1. Persists to SharedPreferences (inside setLang)
  ///   2. Calls Tr.setLang() so all static string lookups update (inside setLang)
  ///   3. notifyListeners() → KarnetApp rebuilds → MaterialApp gets new
  ///      `locale` and the `builder` wraps everything in the correct Directionality.
  Widget _langOption(String label, String code) {
    final isSelected = _svc.lang == code;
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _iconBox(Icons.language_outlined),
      title: Text(
        label,
        style: const TextStyle(
            fontFamily: 'Cairo', fontWeight: FontWeight.w600),
      ),
      trailing: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isSelected
            ? const Icon(Icons.check_circle,
                key: ValueKey('check'), color: _kPrimary, size: 26)
            : const Icon(Icons.radio_button_unchecked,
                key: ValueKey('uncheck'), color: Colors.grey),
      ),
      onTap: () async {
        if (_svc.lang == code) return; // already selected
        await _svc.setLang(code); // persist + sync Tr + notify
        // The listener in initState calls setState, so no setState needed here.
      },
    );
  }

  // ── Backup ─────────────────────────────────────────────────────────────────
  Future<void> _exportBackup() async {
    setState(() => _backingUp = true);
    try {
      final data = await DatabaseHelper.instance.exportAllData();
      final dir  = await getApplicationDocumentsDirectory();
      final ts   = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/karnet_backup_$ts.json');
      await file.writeAsString(jsonEncode(data), flush: true);
      await Clipboard.setData(ClipboardData(text: file.path));
      _snack(Tr.s('backup_saved'), isError: false);
    } catch (e) {
      _snack('${Tr.s('error_prefix')} $e', isError: true);
    } finally {
      if (mounted) setState(() => _backingUp = false);
    }
  }

  // ── Delete all ─────────────────────────────────────────────────────────────
  Future<void> _confirmDeleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          Tr.s('delete_all'),
          style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: _kRed),
        ),
        content: Text(
          Tr.s('delete_all_confirm'),
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(Tr.s('cancel'),
                style: const TextStyle(fontFamily: 'Cairo')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: _kRed),
            child: Text(Tr.s('delete_all_btn'),
                style: const TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await DatabaseHelper.instance.deleteAllData();
      _snack(Tr.s('data_deleted'), isError: false);
    } catch (e) {
      _snack('${Tr.s('error_prefix')} $e', isError: true);
    }
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
      backgroundColor: isError ? _kRed : _kPrimary,
    ));
  }
}