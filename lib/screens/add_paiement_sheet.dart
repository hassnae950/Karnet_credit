import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';
import '../utils/helpers.dart';

class AddPaiementSheet extends StatefulWidget {
  final Credit credit;
  final VoidCallback onSaved;
  const AddPaiementSheet({super.key, required this.credit, required this.onSaved});

  @override
  State<AddPaiementSheet> createState() => _AddPaiementSheetState();
}

class _AddPaiementSheetState extends State<AddPaiementSheet> {
  final _montantCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
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
                const Text('تسجيل دفعة',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              ],
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'الباقي: ${formatMontant(widget.credit.montantRestant)}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: Color(0xFFD32F2F),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo'),
              ),
            ),
            TextField(
              controller: _montantCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 18),
              decoration: InputDecoration(
                hintText: 'المبلغ المدفوع',
                hintStyle: const TextStyle(fontFamily: 'Cairo'),
                prefixText: 'درهم  ',
                prefixStyle: const TextStyle(color: Color(0xFF388E3C), fontFamily: 'Cairo'),
                filled: true,
                fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Cairo'),
              decoration: InputDecoration(
                hintText: 'ملاحظة (اختياري)',
                hintStyle: const TextStyle(fontFamily: 'Cairo'),
                filled: true,
                fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                _montantCtrl.text = widget.credit.montantRestant.toString();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF1B8A6B)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('خلص الكل',
                    style: TextStyle(color: Color(0xFF1B8A6B), fontFamily: 'Cairo')),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF388E3C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('تأكيد الدفعة',
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
    if (montant > widget.credit.montantRestant) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('المبلغ أكبر من الباقي', style: TextStyle(fontFamily: 'Cairo'))));
      return;
    }
    setState(() => _saving = true);
    await DatabaseHelper.instance.createPaiement(
      Paiement(
        creditId: widget.credit.id!,
        montant: montant,
        datePaiement: DateTime.now(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      ),
    );
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }
}