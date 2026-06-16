// lib/screens/app_settings_screen.dart
// UPDATED VERSION WITH FIRESTORE BACKUP/RESTORE

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database_helper.dart';
import '../services/sync_service.dart';
import '../services/app_settings_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../utils/app_translations.dart';
import 'home_screen.dart';

const _kPrimary = Color(0xFF1B8A6B);
const _kRed = Color(0xFFD32F2F);

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  final _svc = AppSettingsService.instance;
  final _syncSvc = SyncService.instance;

  bool _backingUp = false;
  bool _restoringData = false;
  bool _pinEnabled = false;
  String? _userPhoneNumber;
  DateTime? _lastBackupTime;

  @override
  void initState() {
    super.initState();
    _svc.addListener(_refresh);
    _syncSvc.addListener(_refresh);
    _loadPinState();
    _loadUserPhone();
    _loadLastBackupTime();
    _scheduleAutoBackup(); // ← زيد هاد السطر
  }

  void _scheduleAutoBackup() {
    Future.delayed(const Duration(seconds: 5), () async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final lastBackup = prefs.getInt('last_auto_backup') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final diff = now - lastBackup;
      // إذا فات أكثر من 24 ساعة
      if (diff > 24 * 60 * 60 * 1000 && _userPhoneNumber != null) {
        final success = await _syncSvc.backupAllData(_userPhoneNumber!);
        if (success) {
          await prefs.setInt('last_auto_backup', now);
          print('✅ Auto backup done');
        }
      }
    });
  }

  @override
  void dispose() {
    _svc.removeListener(_refresh);
    _syncSvc.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _loadPinState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pinEnabled = prefs.getBool('karnet_pin_enabled') ?? false;
    });
  }

  Future<void> _loadUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('user_phone');
    setState(() {
      _userPhoneNumber = phone;
    });
  }

  Future<void> _loadLastBackupTime() async {
    if (_userPhoneNumber == null) return;
    final lastTime = await _syncSvc.getLastBackupTime(_userPhoneNumber!);
    setState(() {
      _lastBackupTime = lastTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        title: Text(Tr.s('settings'),
            style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── الأمان ────────────────────────────────────────────────────────
          _sectionTitle('الأمان'),
          _card(children: [
            SwitchListTile(
              activeThumbColor: _kPrimary,
              secondary: _iconBox(Icons.lock_outline),
              title: Text(Tr.s('pin_security_title'),
                  style: TextStyle(
                      fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
              subtitle: Text(Tr.s('pin_security_subtitle'),
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
              value: _pinEnabled,
              onChanged: _onPinToggled,
            ),
          ]),

          const SizedBox(height: 16),

          // ── الإشعارات ─────────────────────────────────────────────────────
          _sectionTitle(Tr.s('notifications_label')),
          _card(children: [
            SwitchListTile(
              activeThumbColor: _kPrimary,
              secondary: _iconBox(Icons.notifications_outlined),
              title: Text(Tr.s('cheque_notif_title'),
                  style: const TextStyle(
                      fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
              subtitle: Text(Tr.s('cheque_notif_desc'),
                  style: const TextStyle(fontFamily: 'Cairo')),
              value: _svc.notificationsOn,
              onChanged: _onNotifToggled,
            ),
          ]),

          const SizedBox(height: 16),

          // ── المظهر ────────────────────────────────────────────────────────
          _sectionTitle(Tr.s('appearance')),
          _card(children: [
            _themeOption(Tr.s('light'), 'light', Icons.wb_sunny_outlined),
            _divider(),
            _themeOption(Tr.s('dark'), 'dark', Icons.nightlight_round),
            _divider(),
            _themeOption(
                Tr.s('system_auto'), 'system', Icons.phone_android_outlined),
          ]),

          const SizedBox(height: 16),

          // ── اللغة ─────────────────────────────────────────────────────────
          _sectionTitle(Tr.s('language')),
          _card(children: [
            _langOption('العربية 🇲🇦', 'ar'),
            _divider(),
            _langOption('Français 🇫🇷', 'fr'),
            _divider(),
            _langOption('English 🇬🇧', 'en'),
          ]),

          const SizedBox(height: 16),

          // ── النسخ الاحتياطي (Firestore + Local JSON) ──────────────────────
          _sectionTitle(Tr.s('backup')),
          _card(children: [
            // Cloud Backup (Firestore)
            ListTile(
              leading: _iconBox(Icons.cloud_upload_outlined),
              title: Text(Tr.s('backup_to_cloud'),
                  style: const TextStyle(
                      fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(Tr.s('backup_to_cloud_desc'),
                      style:
                          const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                  if (_lastBackupTime != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${Tr.s('last_backup')}: ${_formatDateTime(_lastBackupTime!)}',
                        style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: Colors.grey),
                      ),
                    ),
                ],
              ),
              trailing: _backingUp
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kPrimary),
                    )
                  : const Icon(Icons.chevron_left, color: Colors.grey),
              onTap: _backingUp ? null : _backupToCloud,
            ),
          ]),

          const SizedBox(height: 16),

          // ── الاستعادة من السحابة ───────────────────────────────────────────
          _sectionTitle(Tr.s('restore')),
          _card(children: [
            ListTile(
              leading: _iconBox(Icons.cloud_download_outlined),
              title: Text(Tr.s('restore_from_cloud'),
                  style: const TextStyle(
                      fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
              subtitle: Text(Tr.s('restore_from_cloud_desc'),
                  style: const TextStyle(fontFamily: 'Cairo')),
              trailing: _restoringData
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kPrimary),
                    )
                  : const Icon(Icons.chevron_left, color: Colors.grey),
              onTap: _restoringData ? null : _restoreFromCloud,
            ),
          ]),

          const SizedBox(height: 32),

          // ── حذف البيانات ──────────────────────────────────────────────────
          _card(children: [
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined,
                  color: _kRed, size: 28),
              title: Text(Tr.s('delete_all'),
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                      color: _kRed)),
              subtitle: Text(Tr.s('delete_all_desc'),
                  style: const TextStyle(fontFamily: 'Cairo')),
              onTap: _confirmDeleteAll,
            ),
          ]),

          const SizedBox(height: 24),

          // ── عن التطبيق ────────────────────────────────────────────────────
          _sectionTitle(Tr.s('about_label')),
          _card(children: [
            ListTile(
              leading: _iconBox(Icons.info_outline),
              title: Text(Tr.s('app_name'),
                  style: const TextStyle(
                      fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
              trailing: const Text('كارنيه',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
            ),
            _divider(),
            ListTile(
              leading: _iconBox(Icons.tag),
              title: Text(Tr.s('version'),
                  style: const TextStyle(
                      fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
              trailing: const Text('2.0.0',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
            ),
          ]),

          // ── تسجيل الخروج ──────────────────────────────────────────────────
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _kRed,
                side: const BorderSide(color: _kRed, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout, color: _kRed),
              label: Text(Tr.s('logout'),
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: _kRed)),
              onPressed: _confirmLogout,
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(Tr.s('logout'),
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content:
            Text(Tr.s('logout_confirm'), style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(Tr.s('cancel'),
                style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(Tr.s('logout'),
                style: TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AuthService.instance.logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  CLOUD BACKUP / RESTORE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Backup to Firestore
  Future<void> _backupToCloud() async {
    if (_userPhoneNumber == null) {
      _snack(Tr.s('error_phone_not_set'), isError: true);
      return;
    }

    setState(() => _backingUp = true);

    try {
      final success = await _syncSvc.backupAllData(_userPhoneNumber!);

      if (success) {
        _snack(Tr.s('backup_success'), isError: false);
        _loadLastBackupTime(); // Refresh the UI
      } else {
        _snack(_syncSvc.syncStatus ?? Tr.s('backup_failed'), isError: true);
      }
    } catch (e) {
      _snack('${Tr.s('error_prefix')} $e', isError: true);
    } finally {
      if (mounted) setState(() => _backingUp = false);
    }
  }

  /// Restore from Firestore
  Future<void> _restoreFromCloud() async {
    if (_userPhoneNumber == null) {
      _snack(Tr.s('error_phone_not_set'), isError: true);
      return;
    }

    // Confirm first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(Tr.s('restore_title'),
            style: const TextStyle(
                fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: Text(Tr.s('restore_confirm'),
            style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(Tr.s('cancel'),
                style: const TextStyle(fontFamily: 'Cairo')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: _kPrimary),
            child: Text(Tr.s('confirm'),
                style: const TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _restoringData = true);

    try {
      final success = await _syncSvc.restoreAllData(_userPhoneNumber!);

      if (success && (_syncSvc.syncStatus == Tr.s('restore_success'))) {
        _snack(Tr.s('restore_success'), isError: false);
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          }
        }
      } else if (success) {
        // no_backup_found — مستخدم جديد بلا داتا
        _snack(_syncSvc.syncStatus ?? Tr.s('no_cloud_data'), isError: false);
      } else {
        _snack(_syncSvc.syncStatus ?? Tr.s('restore_failed'), isError: true);
      }
    } catch (e) {
      _snack('${Tr.s('error_prefix')} $e', isError: true);
    } finally {
      if (mounted) setState(() => _restoringData = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  LOCAL JSON BACKUP (Legacy)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Export local JSON backup (existing logic)
  Future<void> _exportBackupLocal() async {
    setState(() => _backingUp = true);
    try {
      final data = await DatabaseHelper.instance.exportAllData();
      final dir = await getApplicationDocumentsDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
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

  // ═══════════════════════════════════════════════════════════════════════════
  //  PIN TOGGLE
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _onPinToggled(bool val) async {
    if (val) {
      final pinSet = await _showSetPinSheet();
      if (pinSet == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('karnet_pin_enabled', true);
        setState(() => _pinEnabled = true);
        _snack('✅ ${Tr.s('pin_enabled')}', isError: false);
      }
    } else {
      final confirm = await _confirmDisablePin();
      if (confirm == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('karnet_pin_enabled', false);
        await prefs.remove('karnet_pin');
        setState(() => _pinEnabled = false);
        _snack('🔓 ${Tr.s('pin_disabled')}', isError: false);
      }
    }
  }

  Future<bool?> _showSetPinSheet() {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SetPinSheet(),
    );
  }

  Future<bool?> _confirmDisablePin() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(Tr.s('disable_pin_title'),
            style: const TextStyle(
                fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: Text(Tr.s('disable_pin_confirm'),
            style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(Tr.s('cancel'),
                style: const TextStyle(fontFamily: 'Cairo')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: _kRed),
            child: Text(Tr.s('disable'),
                style: const TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  // ── Notifications ─────────────────────────────────────────────────────────
  Future<void> _onNotifToggled(bool val) async {
    await _svc.setNotifications(val);
    if (val) {
      await NotificationService.instance.rescheduleAllFromDb(Tr.s('currency'));
      _snack(Tr.s('notif_enabled'), isError: false);
    } else {
      await NotificationService.instance.cancelAll();
      _snack(Tr.s('notif_disabled'), isError: false);
    }
  }

  // ── Delete all ────────────────────────────────────────────────────────────
  Future<void> _confirmDeleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(Tr.s('delete_all'),
            style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                color: _kRed)),
        content: Text(Tr.s('delete_all_confirm'),
            style: const TextStyle(fontFamily: 'Cairo')),
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
      await NotificationService.instance.cancelAll();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      _snack('${Tr.s('error_prefix')} $e', isError: true);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
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

  Widget _themeOption(String label, String mode, IconData icon) {
    final isSelected = _svc.themeMode == mode;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _iconBox(icon),
      title: Text(label,
          style: const TextStyle(
              fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
      trailing: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isSelected
            ? const Icon(Icons.check_circle,
                key: ValueKey('check'), color: _kPrimary, size: 26)
            : const Icon(Icons.radio_button_unchecked,
                key: ValueKey('uncheck'), color: Colors.grey),
      ),
      onTap: () async => await _svc.setTheme(mode),
    );
  }

  Widget _langOption(String label, String code) {
    final isSelected = _svc.lang == code;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _iconBox(Icons.language_outlined),
      title: Text(label,
          style: const TextStyle(
              fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
      trailing: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isSelected
            ? const Icon(Icons.check_circle,
                key: ValueKey('check'), color: _kPrimary, size: 26)
            : const Icon(Icons.radio_button_unchecked,
                key: ValueKey('uncheck'), color: Colors.grey),
      ),
      onTap: () async {
        if (_svc.lang == code) return;
        await _svc.setLang(code);
      },
    );
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
      backgroundColor: isError ? _kRed : _kPrimary,
      duration: const Duration(seconds: 3),
    ));
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SET PIN BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════════
class _SetPinSheet extends StatefulWidget {
  const _SetPinSheet();

  @override
  State<_SetPinSheet> createState() => _SetPinSheetState();
}

class _SetPinSheetState extends State<_SetPinSheet> {
  static const _pinKey = 'karnet_pin';

  String _pin = '';
  String _confirmPin = '';
  bool _isConfirm = false;
  bool _error = false;

  String get _currentInput => _isConfirm ? _confirmPin : _pin;

  String get _title => _isConfirm ? Tr.s('confirm_pin') : Tr.s('choose_pin');
  void _onDigit(String digit) {
    if (_currentInput.length >= 4) return;
    setState(() {
      _error = false;
      if (_isConfirm) {
        _confirmPin += digit;
      } else {
        _pin += digit;
      }
    });
    if (_currentInput.length == 4) {
      Future.delayed(const Duration(milliseconds: 150), _validate);
    }
  }

  void _onDelete() {
    setState(() {
      _error = false;
      if (_isConfirm && _confirmPin.isNotEmpty) {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      } else if (!_isConfirm && _pin.isNotEmpty)
        _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _validate() async {
    if (!_isConfirm) {
      setState(() {
        _isConfirm = true;
        _error = false;
      });
    } else {
      if (_pin == _confirmPin) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_pinKey, _pin);
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() {
          _confirmPin = '';
          _error = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E2E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF1B8A6B).withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.lock_outline,
                color: Color(0xFF1B8A6B), size: 32),
          ),
          const SizedBox(height: 16),
          Text(_title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = i < _currentInput.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _error
                      ? const Color(0xFFD32F2F)
                      : filled
                          ? const Color(0xFF1B8A6B)
                          : Colors.transparent,
                  border: Border.all(
                    color: _error
                        ? const Color(0xFFD32F2F)
                        : filled
                            ? const Color(0xFF1B8A6B)
                            : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
              );
            }),
          ),
          AnimatedOpacity(
            opacity: _error ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text('الرمزان غير متطابقان',
                  style: TextStyle(
                      color: Color(0xFFD32F2F),
                      fontFamily: 'Cairo',
                      fontSize: 13)),
            ),
          ),
          const SizedBox(height: 24),
          ...[
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9']
          ].map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: row.map(_digitBtn).toList(),
                ),
              )),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _isConfirm
                  ? GestureDetector(
                      onTap: () => setState(() {
                        _isConfirm = false;
                        _confirmPin = '';
                        _error = false;
                      }),
                      child: const SizedBox(
                        width: 72,
                        height: 72,
                        child: Icon(Icons.arrow_back,
                            color: Colors.grey, size: 26),
                      ),
                    )
                  : const SizedBox(width: 72),
              _digitBtn('0'),
              GestureDetector(
                onTap: _onDelete,
                child: const SizedBox(
                  width: 72,
                  height: 72,
                  child: Icon(Icons.backspace_outlined,
                      color: Color(0xFF1B8A6B), size: 26),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _digitBtn(String digit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _onDigit(digit),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF12121A) : const Color(0xFFF5F6FA),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(digit,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                fontFamily: 'Cairo',
                color: isDark ? Colors.white : Colors.black87)),
      ),
    );
  }
}
