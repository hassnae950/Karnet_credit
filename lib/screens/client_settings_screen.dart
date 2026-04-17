import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database_helper.dart';
import '../models.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text('إعدادات ${widget.client.nom}',
            style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: const Color(0xFF1B8A6B),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('إشعارات', style: TextStyle(fontFamily: 'Cairo')),
            subtitle: const Text('تنبيه عند قرب استحقاق شيك',
                style: TextStyle(fontFamily: 'Cairo')),
            value: _notifications,
            onChanged: (v) {
              setState(() => _notifications = v);
              _saveSetting('notif', v);
            },
          ),
          ListTile(
            title: const Text('اللغة', style: TextStyle(fontFamily: 'Cairo')),
            trailing: DropdownButton<String>(
              value: _language,
              items: const [
                DropdownMenuItem(value: 'ar', child: Text('العربية')),
                DropdownMenuItem(value: 'fr', child: Text('Français')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _language = v);
                  _saveSetting('lang', v);
                }
              },
            ),
          ),
          ListTile(
            title: const Text('المظهر', style: TextStyle(fontFamily: 'Cairo')),
            trailing: DropdownButton<String>(
              value: _theme,
              items: const [
                DropdownMenuItem(value: 'light', child: Text('فاتح')),
                DropdownMenuItem(value: 'dark', child: Text('داكن')),
                DropdownMenuItem(value: 'system', child: Text('النظام')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _theme = v);
                  _saveSetting('theme', v);
                }
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('حذف العميل',
                style: TextStyle(color: Colors.red, fontFamily: 'Cairo')),
            onTap: () => _confirmDelete(),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Cairo')),
        content: Text('هل أنت متأكد من حذف ${widget.client.nom}؟',
            style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteClient(widget.client.id!);
              if (mounted) {
                Navigator.pop(ctx);
                Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}