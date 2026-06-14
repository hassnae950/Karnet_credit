import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database_helper.dart';
import '../models.dart';
import '../utils/app_translations.dart';
import '../services/app_settings_service.dart';
import '../services/notification_service.dart';

const _kPrimary = Color(0xFF1B8A6B);
const _kRed = Color(0xFFD32F2F);

class ClientSettingsScreen extends StatefulWidget {
  final Client client;
  const ClientSettingsScreen({super.key, required this.client});

  @override
  State<ClientSettingsScreen> createState() => _ClientSettingsScreenState();
}

class _ClientSettingsScreenState extends State<ClientSettingsScreen> {
  bool _notifications = true;
  String _language = 'ar';
  String _theme = 'light';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifications = prefs.getBool('notif_${widget.client.id}') ?? true;
      _language = prefs.getString('lang_${widget.client.id}') ?? 'ar';
      _theme = prefs.getString('theme_${widget.client.id}') ?? 'light';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool('${key}_${widget.client.id}', value);
    } else if (value is String) {
      await prefs.setString('${key}_${widget.client.id}', value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${Tr.s('client_settings')} — ${widget.client.nom}',
          style: const TextStyle(
              fontFamily: 'Cairo',
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Notifications ────────────────────────────────────────────────
          _sectionTitle(Tr.s('notifications')),
          _card(children: [
            SwitchListTile(
              activeThumbColor: _kPrimary,
              title: Text(Tr.s('client_notif'),
                  style: const TextStyle(
                      fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
              subtitle: Text(Tr.s('client_notif_desc'),
                  style: const TextStyle(fontFamily: 'Cairo')),
              value: _notifications,
              onChanged: (v) async {
                setState(() => _notifications = v);
                _saveSetting('notif', v);
                await AppSettingsService.instance.setNotifications(v);
                if (v) {
                  await NotificationService.instance
                      .rescheduleAllFromDb(Tr.s('currency'));
                } else {
                  await NotificationService.instance.cancelAll();
                }
              },
            ),
          ]),
          const SizedBox(height: 16),

          // ── Language ─────────────────────────────────────────────────────
          _sectionTitle(Tr.s('language')),
          _card(children: [
            _langOption('العربية 🇲🇦', 'ar'),
            _divider(),
            _langOption('Français 🇫🇷', 'fr'),
            _divider(),
            _langOption('English 🇬🇧', 'en'),
          ]),
          const SizedBox(height: 16),

          // ── Appearance ───────────────────────────────────────────────────
          _sectionTitle(Tr.s('appearance')),
          _card(children: [
            _themeOption(Tr.s('light'), 'light', Icons.wb_sunny_outlined),
            _divider(),
            _themeOption(Tr.s('dark'), 'dark', Icons.nightlight_round),
            _divider(),
            _themeOption(
                Tr.s('system'), 'system', Icons.phone_android_outlined),
          ]),
          const SizedBox(height: 32),

          // ── Delete client ────────────────────────────────────────────────
          _card(children: [
            ListTile(
              leading: const Icon(Icons.delete_forever, color: _kRed),
              title: Text(Tr.s('delete_client'),
                  style: const TextStyle(
                      color: _kRed,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600)),
              onTap: _confirmDelete,
            ),
          ]),
        ],
      ),
    );
  }

  // ── Helper widgets ────────────────────────────────────────────────────────────

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: Text(title,
            style: const TextStyle(
                color: Colors.grey,
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      );

  Widget _card({required List<Widget> children}) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: children),
      );

  Widget _divider() => const Divider(height: 1, indent: 16, endIndent: 16);

  Widget _iconBox(IconData icon) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _kPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _kPrimary),
      );

  // ── Language tile ─────────────────────────────────────────────────────────────
  Widget _langOption(String label, String code) {
    final isSelected = _language == code;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _iconBox(Icons.language_outlined),
      title: Text(label,
          style: const TextStyle(
              fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: _kPrimary, size: 26)
          : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
      onTap: () {
        setState(() => _language = code);
        _saveSetting('lang', code);
        AppSettingsService.instance.setLang(code); // ← زيد هاد السطر
      },
    );
  }

  // ── Theme tile ────────────────────────────────────────────────────────────────
  Widget _themeOption(String label, String mode, IconData icon) {
    final isSelected = _theme == mode;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _iconBox(icon),
      title: Text(label,
          style: const TextStyle(
              fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: _kPrimary, size: 26)
          : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
      onTap: () {
        setState(() => _theme = mode);
        _saveSetting('theme', mode);
        AppSettingsService.instance.setTheme(mode); // ← زيد هاد السطر
      },
    );
  }

  // ── Delete ────────────────────────────────────────────────────────────────────
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Tr.s('confirm_delete_label'),
            style: const TextStyle(
                fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: Text(
          '${Tr.s('confirm_delete_msg')} ${widget.client.nom}؟\n${Tr.s('delete_warning')}',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(Tr.s('cancel'),
                  style: const TextStyle(fontFamily: 'Cairo'))),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteClient(widget.client.id!);
              if (mounted) {
                Navigator.pop(ctx); // close dialog
                Navigator.pop(context); // close settings screen
                Navigator.pop(context); // close client detail
              }
            },
            style: TextButton.styleFrom(foregroundColor: _kRed),
            child: Text(Tr.s('delete'),
                style: const TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}
