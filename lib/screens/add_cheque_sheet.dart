import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../database_helper.dart';
import '../utils/app_translations.dart';
import '../services/image_encryption_service.dart';

const _kPrimary = Color(0xFF1B8A6B);
const _kRed = Color(0xFFD32F2F);
const _kGreen = Color(0xFF388E3C);

class AddChequeSheet extends StatefulWidget {
  final int clientId;
  final VoidCallback onSaved;

  const AddChequeSheet({
    super.key,
    required this.clientId,
    required this.onSaved,
  });

  @override
  State<AddChequeSheet> createState() => _AddChequeSheetState();
}

class _AddChequeSheetState extends State<AddChequeSheet> {
  final _numeroCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  final _banqueCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  String? _imagePath;
  bool _saving = false;
  DateTime? _selectedDate;

  // ── نوع الشيك: CREDIT = أخذت / PAYMENT = أعطيت ──────────────────────────
  String _chequeType = 'CREDIT'; // default: أخذت

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _montantCtrl.dispose();
    _banqueCtrl.dispose();
    _descCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x != null) setState(() => _imagePath = x.path);
  }

  Future<void> _takePhoto() async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 85);
    if (x != null) setState(() => _imagePath = x.path);
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _dateCtrl.text = '${date.day}/${date.month}/${date.year}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final fillColor =
        isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF5F6FA);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: textColor),
                  ),
                  Text(Tr.s('add_cheque'),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: textColor)),
                ],
              ),
              const SizedBox(height: 12),

              // ── نوع الشيك: أخذت / أعطيت ──────────────────────────────
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _chequeType = 'CREDIT'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _chequeType == 'CREDIT' ? _kGreen : fillColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _chequeType == 'CREDIT'
                              ? _kGreen
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_downward,
                              color: _chequeType == 'CREDIT'
                                  ? Colors.white
                                  : Colors.grey,
                              size: 18),
                          const SizedBox(width: 6),
                          Text(Tr.s('took'),
                              style: TextStyle(
                                color: _chequeType == 'CREDIT'
                                    ? Colors.white
                                    : Colors.grey,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _chequeType = 'PAYMENT'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _chequeType == 'PAYMENT' ? _kRed : fillColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _chequeType == 'PAYMENT'
                              ? _kRed
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_upward,
                              color: _chequeType == 'PAYMENT'
                                  ? Colors.white
                                  : Colors.grey,
                              size: 18),
                          const SizedBox(width: 6),
                          Text(Tr.s('gave'),
                              style: TextStyle(
                                color: _chequeType == 'PAYMENT'
                                    ? Colors.white
                                    : Colors.grey,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // ── Cheque number ────────────────────────────────────────────
              _buildField(
                  _numeroCtrl, Tr.s('cheque_number'), fillColor, textColor),
              const SizedBox(height: 12),

              // ── Amount ───────────────────────────────────────────────────
              _buildField(
                _montantCtrl,
                Tr.s('amount'),
                fillColor,
                textColor,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                prefix: '${Tr.s('currency')}  ',
              ),
              const SizedBox(height: 12),

              // ── Bank ─────────────────────────────────────────────────────
              _buildField(_banqueCtrl, Tr.s('bank'), fillColor, textColor),
              const SizedBox(height: 12),

              // ── Note ─────────────────────────────────────────────────────
              _buildField(
                  _descCtrl, Tr.s('note_optional'), fillColor, textColor),
              const SizedBox(height: 12),

              // ── Due date ─────────────────────────────────────────────────
              TextField(
                controller: _dateCtrl,
                readOnly: true,
                onTap: _selectDate,
                textAlign: Tr.textAlignStart,
                style: TextStyle(fontFamily: 'Cairo', color: textColor),
                decoration: InputDecoration(
                  hintText: Tr.s('due_date'),
                  hintStyle: TextStyle(
                      fontFamily: 'Cairo', color: Colors.grey.shade500),
                  suffixIcon:
                      const Icon(Icons.calendar_today, color: _kPrimary),
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
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: Text(Tr.s('gallery'),
                        style: const TextStyle(fontFamily: 'Cairo')),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimary,
                        side: const BorderSide(color: _kPrimary)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(Tr.s('camera'),
                        style: const TextStyle(fontFamily: 'Cairo')),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimary,
                        side: const BorderSide(color: _kPrimary)),
                  ),
                ),
              ]),

              // ── Image preview ─────────────────────────────────────────────
              if (_imagePath != null) ...[
                const SizedBox(height: 8),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(_imagePath!),
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text('سيتم تشفيرها',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontFamily: 'Cairo')),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),

              // ── Save button ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _chequeType == 'CREDIT' ? _kGreen : _kRed,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(Tr.s('save_cheque'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'Cairo')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String hint,
    Color fill,
    Color textColor, {
    TextInputType keyboard = TextInputType.text,
    String? prefix,
  }) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboard,
        textAlign: Tr.textAlignStart,
        style: TextStyle(fontFamily: 'Cairo', color: textColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade500),
          prefixText: prefix,
          prefixStyle: const TextStyle(color: _kPrimary, fontFamily: 'Cairo'),
          filled: true,
          fillColor: fill,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      );

  Future<void> _save() async {
    if (_numeroCtrl.text.trim().isEmpty) {
      _snack(Tr.s('cheque_number_required'));
      return;
    }
    final montant = double.tryParse(_montantCtrl.text.replaceAll(',', '.'));
    if (montant == null || montant <= 0) {
      _snack(Tr.s('enter_valid_amount'));
      return;
    }
    if (_selectedDate == null) {
      _snack(Tr.s('due_date_required'));
      return;
    }

    setState(() => _saving = true);
    try {
      // ── تشفير الصورة ────────────────────────────────────────────────
      String? finalImagePath;
      if (_imagePath != null) {
        finalImagePath =
            await ImageEncryptionService.instance.encryptImage(_imagePath!);
      }

      final db = await DatabaseHelper.instance.database;

      if (_chequeType == 'PAYMENT') {
        // ── أخذت — ينشئ credit جديد ──────────────────────────────────
        final creditId = await db.insert('credits', {
          'clientId': widget.clientId,
          'montantTotal': montant,
          'montantRestant': montant,
          'dateCredit': DateTime.now().toIso8601String(),
          'description': _descCtrl.text.trim().isEmpty
              ? '${Tr.s('cheque_prefix')}${_numeroCtrl.text.trim()}'
              : _descCtrl.text.trim(),
          'imagePath': finalImagePath,
        });

        await db.insert('cheques', {
          'creditId': creditId,
          'numero': _numeroCtrl.text.trim(),
          'montant': montant,
          'dateEcheance': _selectedDate!.toIso8601String(),
          'banque':
              _banqueCtrl.text.trim().isEmpty ? null : _banqueCtrl.text.trim(),
          'imagePath': finalImagePath,
          'statut': 'EN_ATTENTE',
          'dateCreation': DateTime.now().toIso8601String(),
        });
      } else {
        // ── أعطيت — ينشئ paiement FIFO + يربط الشيك بآخر credit ──────
        await DatabaseHelper.instance.createPaiementFIFO(
          widget.clientId,
          montant,
          note: _descCtrl.text.trim().isEmpty
              ? '${Tr.s('cheque_prefix')}${_numeroCtrl.text.trim()}'
              : _descCtrl.text.trim(),
          imagePath: finalImagePath,
        );

        // ربط الشيك بآخر credit موجود
        final credits = await db.query(
          'credits',
          where: 'clientId = ?',
          whereArgs: [widget.clientId],
          orderBy: 'dateCredit DESC',
          limit: 1,
        );
        if (credits.isNotEmpty) {
          final creditId = credits.first['id'] as int;
          await db.insert('cheques', {
            'creditId': creditId,
            'numero': _numeroCtrl.text.trim(),
            'montant': montant,
            'dateEcheance': _selectedDate!.toIso8601String(),
            'banque': _banqueCtrl.text.trim().isEmpty
                ? null
                : _banqueCtrl.text.trim(),
            'imagePath': finalImagePath,
            'statut': 'EN_ATTENTE',
            'dateCreation': DateTime.now().toIso8601String(),
          });
        }
      }

      await DatabaseHelper.instance.updateClientSolde(widget.clientId);
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _snack('${Tr.s('error_prefix')} $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.red));
  }
}
