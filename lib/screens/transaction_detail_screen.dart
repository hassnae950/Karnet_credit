import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database_helper.dart';
import '../utils/helpers.dart';
import '../utils/app_translations.dart';
import '../services/image_encryption_service.dart';

const _kPrimary = Color(0xFF1B8A6B);
const _kGreen   = Color(0xFF388E3C);
const _kRed     = Color(0xFFD32F2F);
const _kBlue    = Color(0xFF1976D2);

class TransactionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> tx;
  final String clientNom;
  final VoidCallback onChanged;

  const TransactionDetailScreen({
    super.key,
    required this.tx,
    required this.clientNom,
    required this.onChanged,
  });

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late Map<String, dynamic> _tx;

  @override
  void initState() {
    super.initState();
    _tx = Map<String, dynamic>.from(widget.tx);
  }

  bool    get _isCredit => _tx['type'] == 'CREDIT';
  double  get _amount   => (_tx['amount']  as num).toDouble();
  double  get _balance  => (_tx['balance'] as num).toDouble();
  String  get _dateStr  => _tx['date'] as String;
  String? get _desc     => _tx['description'] as String?;
  String? get _img      => _tx['imagePath']   as String?;

  // ── Widget عرض الصورة مع فك التشفير ──────────────────────────────────────
  Widget _buildImage(String imagePath) {
    final svc = ImageEncryptionService.instance;

    if (!File(imagePath).existsSync()) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 28),
            SizedBox(height: 4),
            Text('الصورة غير متوفرة',
                style: TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Cairo')),
          ]),
        ),
      );
    }

    if (!svc.isEncrypted(imagePath)) {
      return Image.file(File(imagePath), fit: BoxFit.cover);
    }

    return FutureBuilder<File?>(
      future: svc.decryptImageToTemp(imagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 180,
            child: Center(
              child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2),
            ),
          );
        }
        if (snapshot.data == null) {
          return Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 28),
            ),
          );
        }
        return Image.file(snapshot.data!, fit: BoxFit.cover);
      },
    );
  }

  // ── عرض الصورة كاملة مع فك التشفير ──────────────────────────────────────
  void _showFullImage() async {
    if (_img == null) return;
    final svc = ImageEncryptionService.instance;
    File? displayFile;
    bool isTempFile = false;

    if (!File(_img!).existsSync()) return;

    if (svc.isEncrypted(_img!)) {
      displayFile = await svc.decryptImageToTemp(_img!);
      isTempFile = true;
    } else {
      displayFile = File(_img!);
    }

    if (displayFile == null || !mounted) return;

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(children: [
          InteractiveViewer(
            panEnabled: true,
            scaleEnabled: true,
            child: Center(child: Image.file(displayFile!, fit: BoxFit.contain)),
          ),
          Positioned(
            top: 40,
            right: 10,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
            ),
          ),
        ]),
      ),
    );

    if (isTempFile) await svc.deleteTempFile(displayFile!.path);
  }

  @override
  Widget build(BuildContext context) {
    final isDark        = Theme.of(context).brightness == Brightness.dark;
    final textColor     = isDark ? Colors.white          : Colors.black87;
    final subTextColor  = isDark ? Colors.grey.shade400  : Colors.grey.shade600;
    final cardBg        = isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF5F6FA);
    final badgeBg       = isDark ? Colors.grey.shade800  : Colors.grey.shade200;
    final badgeTextColor= isDark ? Colors.grey.shade400  : Colors.grey;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.clientNom,
          style: const TextStyle(
              color: _kBlue,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_right, color: _kBlue, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ── Date ─────────────────────────────────────────────────────
            Text(
              Tr.formatTxDate(_dateStr),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  color: textColor),
            ),
            const SizedBox(height: 6),

            // ── Type label ───────────────────────────────────────────────
            Text(
              _isCredit ? Tr.s('took_label') : Tr.s('gave_label'),
              style: TextStyle(
                  color: subTextColor, fontFamily: 'Cairo', fontSize: 13),
            ),
            const SizedBox(height: 8),

            // ── Amount ───────────────────────────────────────────────────
            Text(
              formatMontant(_amount),
              style: TextStyle(
                color: _isCredit ? _kGreen : _kRed,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 12),

            // ── Balance chip ─────────────────────────────────────────────
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _kGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${Tr.s('balance')} ${formatMontant(_balance)}',
                  style: const TextStyle(
                      color: _kGreen, fontFamily: 'Cairo', fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Description ──────────────────────────────────────────────
            if (_desc != null && _desc!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _desc!,
                  textAlign: Tr.textAlignStart,
                  style: TextStyle(
                      fontFamily: 'Cairo', fontSize: 14, color: textColor),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Image ────────────────────────────────────────────────────
            if (_img != null && _img!.isNotEmpty)
              GestureDetector(
                onTap: _showFullImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade200),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _buildImage(_img!), // ← فك التشفير تلقائي
                  ),
                ),
              ),

            // ── "Recorded" badge ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                Tr.s('recorded'),
                style: TextStyle(
                    color: badgeTextColor,
                    fontFamily: 'Cairo',
                    fontSize: 13),
              ),
            ),

            const Spacer(),

            // ── Edit button ──────────────────────────────────────────────
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Column(children: [
                GestureDetector(
                  onTap: _editTransaction,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _kBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_outlined, color: _kBlue, size: 26),
                  ),
                ),
                const SizedBox(height: 4),
                Text(Tr.s('edit'),
                    style: TextStyle(
                        color: subTextColor,
                        fontFamily: 'Cairo',
                        fontSize: 12)),
              ]),
            ),
            const SizedBox(height: 16),

            // ── Copy / Delete buttons ────────────────────────────────────
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _shareTx,
                  child: Text(Tr.s('copy'),
                      style: const TextStyle(
                          color: Colors.white, fontFamily: 'Cairo', fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kRed.withOpacity(0.85),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _confirmDelete,
                  child: Text(Tr.s('delete'),
                      style: const TextStyle(
                          color: Colors.white, fontFamily: 'Cairo', fontSize: 16)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Edit ──────────────────────────────────────────────────────────────────
  void _editTransaction() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditTxSheet(tx: _tx, onSaved: _applyEdit),
    );
  }

  Future<void> _applyEdit(String? newDesc, double? newAmount) async {
    final type = _tx['type'] as String;
    final id   = _tx['id']   as int;
    final db   = await DatabaseHelper.instance.database;

    if (type == 'CREDIT' && newAmount != null) {
      final diff = newAmount - _amount;
      await db.update(
        'credits',
        {
          'montantTotal':   newAmount,
          'montantRestant': (_tx['montantRestant'] as num? ?? _amount) + diff,
          if (newDesc != null) 'description': newDesc,
        },
        where: 'id = ?', whereArgs: [id],
      );
    } else if (type == 'PAYMENT' && newAmount != null) {
      final creditId = _tx['creditId'] as int;
      final cRows = await db.query('credits', where: 'id = ?', whereArgs: [creditId]);
      if (cRows.isNotEmpty) {
        double restant = (cRows.first['montantRestant'] as num).toDouble();
        restant += _amount;
        restant -= newAmount;
        if (restant < 0) restant = 0;
        await db.update('credits', {'montantRestant': restant},
            where: 'id = ?', whereArgs: [creditId]);
      }
      await db.update(
        'paiements',
        {'montant': newAmount, if (newDesc != null) 'note': newDesc},
        where: 'id = ?', whereArgs: [id],
      );
    } else if (newDesc != null) {
      final table = type == 'CREDIT' ? 'credits' : 'paiements';
      final field = type == 'CREDIT' ? 'description' : 'note';
      await db.update(table, {field: newDesc}, where: 'id = ?', whereArgs: [id]);
    }

    final clientId = await _getClientId();
    if (clientId != null) {
      await DatabaseHelper.instance.updateClientSolde(clientId);
    }

    setState(() {
      if (newDesc   != null) _tx['description'] = newDesc;
      if (newAmount != null) _tx['amount']       = newAmount;
    });
    widget.onChanged();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(Tr.s('edited'),
              style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: _kGreen));
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Tr.s('delete_tx'),
            textAlign: Tr.textAlignStart,
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: Text(Tr.s('confirm_delete_tx'),
            textAlign: Tr.textAlignStart,
            style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(Tr.s('cancel'),
                  style: const TextStyle(fontFamily: 'Cairo'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: _kRed),
            child: Text(Tr.s('delete'),
                style: const TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _deleteTransaction();
  }

  Future<void> _deleteTransaction() async {
    final type     = _tx['type'] as String;
    final id       = _tx['id']   as int;
    final db       = await DatabaseHelper.instance.database;
    final clientId = await _getClientId();

    if (type == 'CREDIT') {
      await db.delete('credits', where: 'id = ?', whereArgs: [id]);
    } else {
      final creditId = _tx['creditId'] as int;
      final cRows = await db.query('credits', where: 'id = ?', whereArgs: [creditId]);
      if (cRows.isNotEmpty) {
        double restant = (cRows.first['montantRestant'] as num).toDouble() + _amount;
        final total = (cRows.first['montantTotal'] as num).toDouble();
        if (restant > total) restant = total;
        await db.update('credits', {'montantRestant': restant},
            where: 'id = ?', whereArgs: [creditId]);
      }
      await db.delete('paiements', where: 'id = ?', whereArgs: [id]);
    }

    if (clientId != null) {
      await DatabaseHelper.instance.updateClientSolde(clientId);
    }

    widget.onChanged();
    if (mounted) Navigator.pop(context);
  }

  Future<int?> _getClientId() async {
    final type = _tx['type'] as String;
    final id   = _tx['id']   as int;
    final db   = await DatabaseHelper.instance.database;
    if (type == 'CREDIT') {
      final r = await db.query('credits', where: 'id = ?', whereArgs: [id]);
      return r.isEmpty ? null : r.first['clientId'] as int;
    } else {
      final creditId = _tx['creditId'] as int;
      final r = await db.query('credits', where: 'id = ?', whereArgs: [creditId]);
      return r.isEmpty ? null : r.first['clientId'] as int;
    }
  }

  // ── Share ─────────────────────────────────────────────────────────────────
  void _shareTx() {
    final typeLabel = _isCredit ? Tr.s('took_label') : Tr.s('gave_label');
    final text =
        '${Tr.s('client')}: ${widget.clientNom}\n'
        '$typeLabel: ${formatMontant(_amount)}\n'
        '${Tr.s('balance')}: ${formatMontant(_balance)}\n'
        '${Tr.s('date_label')}: ${Tr.formatTxDate(_dateStr)}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(Tr.s('info_copied'),
          style: const TextStyle(fontFamily: 'Cairo')),
      backgroundColor: _kBlue,
    ));
  }
}

// ── Edit sheet ────────────────────────────────────────────────────────────────
class _EditTxSheet extends StatefulWidget {
  final Map<String, dynamic> tx;
  final Future<void> Function(String? desc, double? amount) onSaved;
  const _EditTxSheet({required this.tx, required this.onSaved});

  @override
  State<_EditTxSheet> createState() => _EditTxSheetState();
}

class _EditTxSheetState extends State<_EditTxSheet> {
  late TextEditingController _amountCtrl;
  late TextEditingController _descCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
        text: (widget.tx['amount'] as num).toDouble().toStringAsFixed(2));
    _descCtrl = TextEditingController(
        text: widget.tx['description'] as String? ?? '');
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final sheetBg   = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final fillColor = isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF5F6FA);
    final textColor = isDark ? Colors.white : Colors.black87;
    final isCredit  = widget.tx['type'] == 'CREDIT';

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: textColor)),
              Text(
                isCredit ? Tr.s('edit_credit') : Tr.s('edit_payment'),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: textColor),
              ),
            ]),
            const SizedBox(height: 16),

            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 20, color: textColor),
              decoration: InputDecoration(
                labelText: Tr.s('amount'),
                labelStyle: TextStyle(fontFamily: 'Cairo', color: textColor),
                prefixText: '${Tr.s('currency')}  ',
                prefixStyle: const TextStyle(color: _kPrimary, fontFamily: 'Cairo'),
                filled: true,
                fillColor: fillColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _descCtrl,
              textAlign: Tr.textAlignStart,
              maxLines: 2,
              style: TextStyle(fontFamily: 'Cairo', color: textColor),
              decoration: InputDecoration(
                labelText: isCredit ? Tr.s('description') : Tr.s('note_optional'),
                labelStyle: TextStyle(fontFamily: 'Cairo', color: textColor),
                filled: true,
                fillColor: fillColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

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
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(Tr.s('save_edit'),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16, fontFamily: 'Cairo')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(Tr.s('enter_valid_amount'),
              style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.red));
      return;
    }
    setState(() => _saving = true);
    try {
      final desc = _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();
      await widget.onSaved(desc, amount);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${Tr.s('error_prefix')} $e',
                style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}