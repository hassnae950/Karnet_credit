import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../database_helper.dart';
import '../services/app_settings_service.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: _kPrimary,
        title: const Text('الإعدادات',
            style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('المظهر'),
          _card(children: [
            _themeOption('فاتح ☀️',   'light'),
            _divider(),
            _themeOption('داكن 🌙',   'dark'),
            _divider(),
            _themeOption('تلقائي 📱', 'system'),
          ]),
          const SizedBox(height: 16),

          _sectionTitle('النسخ الاحتياطي'),
          _card(children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: _iconBox(Icons.cloud_upload_outlined),
              title: const Text('تصدير البيانات',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
              subtitle: const Text('حفظ نسخة احتياطية JSON',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey)),
              trailing: _backingUp
                  ? const SizedBox(width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                  : const Icon(Icons.chevron_left, color: Colors.grey),
              onTap: _backingUp ? null : _exportBackup,
            ),
          ]),
          const SizedBox(height: 16),

          _sectionTitle('اللغة'),
          _card(children: [
            _langOption('العربية 🇲🇦', 'ar'),
            _divider(),
            _langOption('Français 🇫🇷', 'fr'),
            _divider(),
            _langOption('English 🇬🇧',  'en'),
          ]),
          const SizedBox(height: 16),

          _sectionTitle('عن التطبيق'),
          _card(children: [
            _infoTile(Icons.info_outline,  'اسم التطبيق', 'كارنيه'),
            _divider(),
            _infoTile(Icons.tag,           'الإصدار',     '2.0.0'),
            _divider(),
            _infoTile(Icons.phone_android, 'المنصة',      'Android / iOS'),
          ]),
          const SizedBox(height: 16),

          _card(children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: _kRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.delete_forever_outlined, color: _kRed, size: 20),
              ),
              title: const Text('حذف كل البيانات',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, color: _kRed)),
              subtitle: const Text('حذف جميع العملاء والمعاملات',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey)),
              trailing: const Icon(Icons.chevron_left, color: _kRed),
              onTap: _confirmDeleteAll,
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(right: 4, bottom: 8),
    child: Text(t, style: const TextStyle(color: Colors.grey, fontFamily: 'Cairo',
        fontSize: 12, fontWeight: FontWeight.w600)),
  );

  Widget _card({required List<Widget> children}) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(children: children),
  );

  Widget _divider() => const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F0F0));

  Widget _iconBox(IconData icon) => Container(
    width: 40, height: 40,
    decoration: BoxDecoration(
        color: _kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
    child: Icon(icon, color: _kPrimary, size: 20),
  );

  Widget _themeOption(String label, String mode) {
    final selected = _svc.themeMode == mode;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: _iconBox(mode == 'light' ? Icons.wb_sunny_outlined
          : mode == 'dark' ? Icons.nightlight_outlined : Icons.phone_android_outlined),
      title: Text(label, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
      trailing: selected
          ? const Icon(Icons.check_circle, color: _kPrimary)
          : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
      onTap: () async { await _svc.setTheme(mode); setState(() {}); },
    );
  }

  Widget _langOption(String label, String code) {
    final selected = _svc.lang == code;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: _iconBox(Icons.language_outlined),
      title: Text(label, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
      trailing: selected
          ? const Icon(Icons.check_circle, color: _kPrimary)
          : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
      onTap: () async { await _svc.setLang(code); setState(() {}); },
    );
  }

  Widget _infoTile(IconData icon, String label, String value) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    leading: _iconBox(icon),
    title: Text(label, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
    trailing: Text(value, style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 13)),
  );

  Future<void> _exportBackup() async {
    setState(() => _backingUp = true);
    try {
      final data = await DatabaseHelper.instance.exportAllData();
      final dir  = await getApplicationDocumentsDirectory();
      final ts   = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/karnet_backup_$ts.json');
      await file.writeAsString(jsonEncode(data), flush: true);
      await Clipboard.setData(ClipboardData(text: file.path));
      _snack('تم حفظ النسخة ✅ — مسار الملف تم نسخه', isError: false);
    } catch (e) {
      _snack('خطأ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _backingUp = false);
    }
  }

  Future<void> _confirmDeleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف كل البيانات', textAlign: TextAlign.right,
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: _kRed)),
        content: const Text('غادي يتمحاو جميع العملاء والمعاملات بلا رجعة. متأكد 100%؟',
            textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: _kRed),
            child: const Text('حذف الكل', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await DatabaseHelper.instance.deleteAllData();
      _snack('تم حذف كل البيانات', isError: false);
    } catch (e) {
      _snack('خطأ: $e', isError: true);
    }
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
      backgroundColor: isError ? _kRed : _kPrimary,
    ));
  }
}