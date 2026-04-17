import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../database_helper.dart';
import '../models.dart';

class AddChequeSheet extends StatefulWidget {
  final int creditId;
  final VoidCallback onSaved;
  const AddChequeSheet({super.key, required this.creditId, required this.onSaved});

  @override
  State<AddChequeSheet> createState() => _AddChequeSheetState();
}

class _AddChequeSheetState extends State<AddChequeSheet> {
  final _numeroCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  final _banqueCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  String? _imagePath;
  bool _saving = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imagePath = picked.path);
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => _imagePath = picked.path);
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      _dateCtrl.text = '${date.day}/${date.month}/${date.year}';
    }
  }

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
                const Text('إضافة شيك',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _numeroCtrl,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: 'رقم الشيك *',
                hintStyle: TextStyle(fontFamily: 'Cairo'),
                filled: true,
                fillColor: Color(0xFFF5F6FA),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _montantCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: 'المبلغ *',
                hintStyle: TextStyle(fontFamily: 'Cairo'),
                prefixText: 'درهم  ',
                filled: true,
                fillColor: Color(0xFFF5F6FA),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _banqueCtrl,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: 'البنك',
                hintStyle: TextStyle(fontFamily: 'Cairo'),
                filled: true,
                fillColor: Color(0xFFF5F6FA),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dateCtrl,
              readOnly: true,
              onTap: _selectDate,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: 'تاريخ الاستحقاق *',
                hintStyle: TextStyle(fontFamily: 'Cairo'),
                suffixIcon: Icon(Icons.calendar_today),
                filled: true,
                fillColor: Color(0xFFF5F6FA),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('معرض الصور'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('كاميرا'),
                  ),
                ),
              ],
            ),
            if (_imagePath != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(_imagePath!),
                    height: 100, width: double.infinity, fit: BoxFit.cover),
              ),
            ],
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
                    : const Text('حفظ الشيك',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Cairo')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_numeroCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رقم الشيك مطلوب', style: TextStyle(fontFamily: 'Cairo'))));
      return;
    }
    final montant = double.tryParse(_montantCtrl.text.replaceAll(',', '.'));
    if (montant == null || montant <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('دخل مبلغ صحيح', style: TextStyle(fontFamily: 'Cairo'))));
      return;
    }
    if (_dateCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تاريخ الاستحقاق مطلوب', style: TextStyle(fontFamily: 'Cairo'))));
      return;
    }

    setState(() => _saving = true);
    await DatabaseHelper.instance.createCheque(Cheque(
      creditId: widget.creditId,
      numero: _numeroCtrl.text,
      montant: montant,
      dateEcheance: _parseDate(_dateCtrl.text),
      banque: _banqueCtrl.text.isEmpty ? null : _banqueCtrl.text,
      imagePath: _imagePath,
      dateCreation: DateTime.now(),
    ));
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  DateTime _parseDate(String date) {
    final parts = date.split('/');
    return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
  }
}