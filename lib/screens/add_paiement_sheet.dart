import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../database_helper.dart';
import '../utils/helpers.dart';
import '../utils/app_translations.dart';

const _kPrimary = Color(0xFF1B8A6B);
const _kGreen   = Color(0xFF388E3C);
const _kRed     = Color(0xFFD32F2F);

class AddPaiementSheet extends StatefulWidget {
  final int    clientId;
  final double totalRestant;
  final VoidCallback onSaved;

  const AddPaiementSheet({
    super.key,
    required this.clientId,
    required this.totalRestant,
    required this.onSaved,
  });

  @override
  State<AddPaiementSheet> createState() => _AddPaiementSheetState();
}

class _AddPaiementSheetState extends State<AddPaiementSheet> {
  final _noteCtrl = TextEditingController();
  String  _amount    = '0';
  String? _imagePath;
  bool    _saving    = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── Numpad logic ─────────────────────────────────────────────────────────────
  void _onKey(String k) {
    setState(() {
      if (k == 'C')  { _amount = '0'; return; }
      if (k == '⌫') {
        _amount = _amount.length > 1
            ? _amount.substring(0, _amount.length - 1)
            : '0';
        return;
      }
      if (k == '.' && _amount.contains('.')) return;
      _amount = (_amount == '0' && k != '.') ? k : _amount + k;
    });
  }

  void _setFull() => setState(
      () => _amount = widget.totalRestant.toStringAsFixed(2));

  Future<void> _pickImage(ImageSource src) async {
    final x = await ImagePicker()
        .pickImage(source: src, imageQuality: 85);
    if (x != null) setState(() => _imagePath = x.path);
  }

  void _showFullImage() {
    if (_imagePath == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image.file(File(_imagePath!), fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final sheetBg   = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final fillColor = isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF5F6FA);
    final textColor = isDark ? Colors.white : Colors.black87;
    final montant   = double.tryParse(_amount) ?? 0;

    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: textColor)),
              Text(Tr.s('add_payment'),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      color: textColor)),
            ]),

            // ── Remaining balance banner ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? _kRed.withOpacity(0.15)
                    : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${Tr.s('remaining_amount')} ${formatMontant(widget.totalRestant)}',
                textAlign: Tr.textAlignStart,
                style: const TextStyle(
                    color: _kRed,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo'),
              ),
            ),

            // ── Amount display ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(Tr.s('currency'),
                      style: const TextStyle(
                          color: _kGreen,
                          fontFamily: 'Cairo',
                          fontSize: 16)),
                  Text(_amount,
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: textColor)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Calculator pad ───────────────────────────────────────────
            _calcPad(
                isDark: isDark,
                fillColor: fillColor,
                textColor: textColor),
            const SizedBox(height: 12),

            // ── Note field ───────────────────────────────────────────────
            TextField(
              controller: _noteCtrl,
              textAlign: Tr.textAlignStart,
              maxLines: 2,
              style:
                  TextStyle(fontFamily: 'Cairo', color: textColor),
              decoration: InputDecoration(
                hintText: Tr.s('note_optional'),
                hintStyle: TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.grey.shade500),
                filled: true,
                fillColor: fillColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),

            // ── Image buttons ────────────────────────────────────────────
            Row(children: [
              Expanded(
                  child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: Text(Tr.s('gallery'),
                    style: const TextStyle(fontFamily: 'Cairo')),
                style: OutlinedButton.styleFrom(
                    foregroundColor: _kGreen,
                    side: const BorderSide(color: _kGreen)),
              )),
              const SizedBox(width: 8),
              Expanded(
                  child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: Text(Tr.s('camera'),
                    style: const TextStyle(fontFamily: 'Cairo')),
                style: OutlinedButton.styleFrom(
                    foregroundColor: _kGreen,
                    side: const BorderSide(color: _kGreen)),
              )),
            ]),

            // ── Image preview ────────────────────────────────────────────
            if (_imagePath != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showFullImage,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(File(_imagePath!),
                      height: 80, width: 80, fit: BoxFit.cover),
                ),
              ),
            ],

            const SizedBox(height: 8),

            // ── Pay all shortcut ─────────────────────────────────────────
            GestureDetector(
              onTap: _setFull,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: _kPrimary),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(Tr.s('pay_all'),
                    style: const TextStyle(
                        color: _kPrimary, fontFamily: 'Cairo')),
              ),
            ),
            const SizedBox(height: 16),

            // ── Confirm button ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _saving ? null : () => _save(montant),
                child: _saving
                    ? const CircularProgressIndicator(
                        color: Colors.white)
                    : Text(Tr.s('confirm_payment'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Cairo')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Calculator grid ──────────────────────────────────────────────────────────
  Widget _calcPad({
    required bool isDark,
    required Color fillColor,
    required Color textColor,
  }) {
    final rows = [
      ['7', '8', '9'],
      ['4', '5', '6'],
      ['1', '2', '3'],
      ['00', '0', 'C'],
      ['⌫', '.', ''],
    ];
    final borderColor =
        isDark ? Colors.grey.shade700 : Colors.grey.shade200;

    return Column(
      children: rows.map((row) {
        return Row(
          children: row.map((k) {
            if (k.isEmpty) return const Expanded(child: SizedBox());
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: GestureDetector(
                  onTap: () => _onKey(k),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: k == 'C'
                          ? (isDark
                              ? _kRed.withOpacity(0.2)
                              : const Color(0xFFFFEBEE))
                          : k == '⌫'
                              ? fillColor
                              : (isDark
                                  ? const Color(0xFF2C2C3E)
                                  : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Center(
                      child: Text(k,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: k == 'C' ? _kRed : textColor,
                          )),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  // ── Save ─────────────────────────────────────────────────────────────────────
  Future<void> _save(double montant) async {
    if (montant <= 0) {
      _snack(Tr.s('enter_valid_amount'), isError: true);
      return;
    }
    if (montant > widget.totalRestant + 0.01) {
      _snack(
          '${Tr.s('amount_exceeds')} (${formatMontant(widget.totalRestant)})',
          isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await DatabaseHelper.instance.createPaiementFIFO(
        widget.clientId,
        montant,
        note: _noteCtrl.text.trim().isEmpty
            ? null
            : _noteCtrl.text.trim(),
        imagePath: _imagePath,
      );
      _snack('${Tr.s('payment_saved_amount')} ${formatMontant(montant)}',
          isError: false);
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _snack('${Tr.s('error_prefix')} $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
      backgroundColor: isError ? _kRed : _kGreen,
    ));
  }
}