import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../database_helper.dart';
import '../models.dart';
import '../utils/app_translations.dart';

const _kPrimary = Color(0xFF1B8A6B);

class AddCreditSheet extends StatefulWidget {
  final int clientId;
  final VoidCallback onSaved;
  const AddCreditSheet(
      {super.key, required this.clientId, required this.onSaved});

  @override
  State<AddCreditSheet> createState() => _AddCreditSheetState();
}

class _AddCreditSheetState extends State<AddCreditSheet> {
  final _montantCtrl = TextEditingController();
  final _descCtrl    = TextEditingController();
  String? _imagePath;
  bool    _saving = false;

  @override
  void dispose() {
    _montantCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource src) async {
    final x =
        await ImagePicker().pickImage(source: src, imageQuality: 85);
    if (x != null) setState(() => _imagePath = x.path);
  }

  @override
  Widget build(BuildContext context) {
    final theme     = Theme.of(context);
    final isDark    = theme.brightness == Brightness.dark;
    final fillColor = isDark
        ? const Color(0xFF2C2C2C)
        : const Color(0xFFF5F6FA);
    final textColor = theme.textTheme.bodyLarge?.color;

    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ── Header ───────────────────────────────────────────────────
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close)),
                    Text(
                      Tr.s('add_credit'),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: theme.textTheme.titleLarge?.color),
                    ),
                  ]),
              const SizedBox(height: 16),

              // ── Amount ───────────────────────────────────────────────────
              TextField(
                controller: _montantCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontFamily: 'Cairo', fontSize: 20, color: textColor),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: '${Tr.s('currency')}  ',
                  prefixStyle: const TextStyle(
                      color: _kPrimary, fontFamily: 'Cairo'),
                  filled: true,
                  fillColor: fillColor,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),

              // ── Description ──────────────────────────────────────────────
              TextField(
                controller: _descCtrl,
                textAlign: Tr.textAlignStart,
                style: TextStyle(fontFamily: 'Cairo', color: textColor),
                decoration: InputDecoration(
                  hintText: Tr.s('description'),
                  hintStyle: const TextStyle(
                      fontFamily: 'Cairo', color: Colors.grey),
                  prefixIcon:
                      const Icon(Icons.notes, color: _kPrimary),
                  filled: true,
                  fillColor: fillColor,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),

              // ── Image buttons ─────────────────────────────────────────────
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: Text(Tr.s('gallery'),
                        style: const TextStyle(fontFamily: 'Cairo')),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: textColor),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: Text(Tr.s('camera'),
                        style: const TextStyle(fontFamily: 'Cairo')),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: textColor),
                  ),
                ),
              ]),

              // ── Image preview ─────────────────────────────────────────────
              if (_imagePath != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(File(_imagePath!),
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover),
                ),
              ],
              const SizedBox(height: 24),

              // ── Save button ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const CircularProgressIndicator(
                          color: Colors.white)
                      : Text(
                          Tr.s('register_credit'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'Cairo'),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final montant = double.tryParse(
        _montantCtrl.text.replaceAll(',', '.'));
    if (montant == null || montant <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(Tr.s('enter_valid_amount'),
              style: const TextStyle(fontFamily: 'Cairo'))));
      return;
    }
    setState(() => _saving = true);
    try {
      await DatabaseHelper.instance.createCredit(Credit(
        clientId:      widget.clientId,
        montantTotal:  montant,
        montantRestant: montant,
        dateCredit:    DateTime.now(),
        description:   _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        imagePath: _imagePath,
      ));
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${Tr.s('error_prefix')} $e',
              style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}