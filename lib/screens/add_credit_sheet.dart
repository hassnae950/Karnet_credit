import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';


class AddCreditSheet extends StatefulWidget {
  final int clientId;
  final VoidCallback onSaved;
  const AddCreditSheet({super.key, required this.clientId, required this.onSaved});

  @override
  State<AddCreditSheet> createState() => _AddCreditSheetState();
}

class _AddCreditSheetState extends State<AddCreditSheet> {
  final _montantCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
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
                const Text('إضافة كريدي',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _montantCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 18),
              decoration: InputDecoration(
                hintText: 'المبلغ (درهم)',
                hintStyle: const TextStyle(fontFamily: 'Cairo'),
                prefixText: 'درهم  ',
                prefixStyle: const TextStyle(color: Color(0xFF1B8A6B), fontFamily: 'Cairo'),
                filled: true,
                fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Cairo'),
              decoration: InputDecoration(
                hintText: 'الوصف (اختياري)',
                hintStyle: const TextStyle(fontFamily: 'Cairo'),
                filled: true,
                fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
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
                    : const Text('تسجيل الكريدي',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Cairo')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final montant = double.tryParse(_montantCtrl.text.replaceAll(',', '.'));
    if (montant == null || montant <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('دخل مبلغ صحيح', style: TextStyle(fontFamily: 'Cairo'))));
      return;
    }
    setState(() => _saving = true);
    await DatabaseHelper.instance.createCredit(
      Credit(
        clientId: widget.clientId,
        montantTotal: montant,
        montantRestant: montant,
        dateCredit: DateTime.now(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      ),
    );
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }
}