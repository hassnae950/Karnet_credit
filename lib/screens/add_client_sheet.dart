import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';

class AddClientSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const AddClientSheet({super.key, required this.onSaved});

  @override
  State<AddClientSheet> createState() => _AddClientSheetState();
}

class _AddClientSheetState extends State<AddClientSheet> {
  final _nomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _adrCtrl = TextEditingController();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                const Text('عميل جديد',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              ],
            ),
            const SizedBox(height: 16),
            _field(_nomCtrl, 'الاسم *', Icons.person_outline),
            const SizedBox(height: 12),
            _field(_telCtrl, 'رقم الهاتف', Icons.phone_outlined, type: TextInputType.phone),
            const SizedBox(height: 12),
            _field(_adrCtrl, 'العنوان', Icons.location_on_outlined),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B8A6B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('حفظ',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Cairo')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      textAlign: TextAlign.right,
      style: const TextStyle(fontFamily: 'Cairo'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'Cairo'),
        prefixIcon: Icon(icon, color: const Color(0xFF1B8A6B)),
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Future<void> _save() async {
    if (_nomCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('الاسم مطلوب', style: TextStyle(fontFamily: 'Cairo'))));
      return;
    }
    setState(() => _saving = true);
    await DatabaseHelper.instance.createClient(Client(
      nom: _nomCtrl.text.trim(),
      telephone: _telCtrl.text.trim().isEmpty ? null : _telCtrl.text.trim(),
      adresse: _adrCtrl.text.trim().isEmpty ? null : _adrCtrl.text.trim(),
      dateCreation: DateTime.now(),
    ));
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }
}