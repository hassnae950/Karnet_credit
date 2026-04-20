import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database_helper.dart';
import '../utils/helpers.dart';

const _kPrimary = Color(0xFF1B8A6B);
const _kGreen   = Color(0xFF388E3C);
const _kRed     = Color(0xFFD32F2F);
const _kBlue    = Color(0xFF1976D2);

class TransactionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> tx; // transaction map from getAllTransactionsClient
  final String clientNom;
  final VoidCallback onChanged;   // called after edit or delete

  const TransactionDetailScreen({
    super.key,
    required this.tx,
    required this.clientNom,
    required this.onChanged,
  });

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late Map<String, dynamic> _tx;

  @override
  void initState() {
    super.initState();
    _tx = Map<String, dynamic>.from(widget.tx);
  }

  bool get _isCredit => _tx['type'] == 'CREDIT';
  double get _amount  => (_tx['amount'] as num).toDouble();
  double get _balance => (_tx['balance'] as num).toDouble();
  String get _dateStr => _tx['date'] as String;
  String? get _desc   => _tx['description'] as String?;
  String? get _img    => _tx['imagePath'] as String?;

  String _formatFullDate(String iso) {
    final d   = DateTime.parse(iso).toLocal();
    final now = DateTime.now();
    final h   = d.hour.toString().padLeft(2, '0');
    final m   = d.minute.toString().padLeft(2, '0');
    final today = DateTime(now.year, now.month, now.day);
    final txDay = DateTime(d.year, d.month, d.day);
    const mo = ['','يناير','فبراير','مارس','أبريل','مايو','يونيو',
                    'يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    if (txDay == today) return 'اليوم ساعة $h:$m';
    return '${d.day} ${mo[d.month]} ${d.year} ساعة $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.clientNom,
          style: const TextStyle(
              color: _kBlue, fontFamily: 'Cairo',
              fontWeight: FontWeight.bold, fontSize: 20),
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
            // Date
            Text(
              _formatFullDate(_dateStr),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  color: Colors.black87),
            ),
            const SizedBox(height: 6),

            // Type label
            Text(
              _isCredit ? 'أخذت' : 'أعطيت',
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontFamily: 'Cairo',
                  fontSize: 13),
            ),
            const SizedBox(height: 8),

            // Amount
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

            // Balance chip
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _kGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'الرصيد ${formatMontant(_balance)}',
                  style: const TextStyle(
                      color: _kGreen, fontFamily: 'Cairo', fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description / note
            if (_desc != null && _desc!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _desc!,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontFamily: 'Cairo', fontSize: 14, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Image thumbnail
            if (_img != null && _img!.isNotEmpty)
              GestureDetector(
                onTap: _showFullImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(File(_img!), fit: BoxFit.cover),
                  ),
                ),
              ),

            // "Recorded" badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'مسجلة',
                style: TextStyle(
                    color: Colors.grey, fontFamily: 'Cairo', fontSize: 13),
              ),
            ),

            const Spacer(),

            // Edit button (circle)
            Align(
              alignment: Alignment.centerLeft,
              child: Column(children: [
                GestureDetector(
                  onTap: _editTransaction,
                  child: Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: _kBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_outlined, color: _kBlue, size: 26),
                  ),
                ),
                const SizedBox(height: 4),
                const Text('تعديل',
                    style: TextStyle(
                        color: Colors.grey, fontFamily: 'Cairo', fontSize: 12)),
              ]),
            ),
            const SizedBox(height: 16),

            // Bottom buttons
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _shareTx,
                  child: const Text('نسخ',
                      style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kRed.withOpacity(0.85),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _confirmDelete,
                  child: const Text('حذف',
                      style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 16)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Edit ───────────────────────────
  void _editTransaction() {
    final ctx = context;
     showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditTxSheet(
        tx: _tx,
        onSaved: (newDesc, newAmount) async {
          await _applyEdit(newDesc, newAmount);
          Navigator.pop(ctx); // close sheet
        },
      ),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditTxSheet(
        tx: _tx,
        onSaved: (newDesc, newAmount) async {
          await _applyEdit(newDesc, newAmount);
          Navigator.pop(context); // close sheet
        },
      ),
    );
  }

  Future<void> _applyEdit(String? newDesc, double? newAmount) async {
    final type = _tx['type'] as String;
    final id   = _tx['id'] as int;
    final db   = await DatabaseHelper.instance.database;

    if (type == 'CREDIT' && newAmount != null) {
      final diff = newAmount - _amount;
      await db.update(
        'credits',
        {
          'montantTotal':    newAmount,
          'montantRestant':  (_tx['montantRestant'] as num? ?? _amount) + diff,
          if (newDesc != null) 'description': newDesc,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } else if (type == 'PAYMENT' && newAmount != null) {
      // Revert old payment then apply new
      final oldMontant = _amount;
      final creditId   = _tx['creditId'] as int;
      // Adjust credit montantRestant
      final cRows = await db.query('credits', where: 'id = ?', whereArgs: [creditId]);
      if (cRows.isNotEmpty) {
        double restant = (cRows.first['montantRestant'] as num).toDouble();
        restant += oldMontant;     // revert old
        restant -= newAmount;      // apply new
        if (restant < 0) restant = 0;
        await db.update('credits',
            {'montantRestant': restant, 'statut': restant <= 0 ? 'SOLDE' : 'EN_COURS'},
            where: 'id = ?', whereArgs: [creditId]);
      }
      await db.update(
        'paiements',
        {'montant': newAmount, if (newDesc != null) 'note': newDesc},
        where: 'id = ?',
        whereArgs: [id],
      );
    } else if (newDesc != null) {
      // Description only
      final table = type == 'CREDIT' ? 'credits' : 'paiements';
      final field = type == 'CREDIT' ? 'description' : 'note';
      await db.update(table, {field: newDesc}, where: 'id = ?', whereArgs: [id]);
    }

    // Update client solde
    final clientId = await _getClientId();
    if (clientId != null) await DatabaseHelper.instance.updateClientSolde(clientId);

    setState(() {
      if (newDesc   != null) _tx['description'] = newDesc;
      if (newAmount != null) _tx['amount']      = newAmount;
    });
    widget.onChanged();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم التعديل', style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: _kGreen));
    }
  }

  // ─────────────────────────── Delete ───────────────────────────
  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف المعاملة', textAlign: TextAlign.right,
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: const Text('واش متأكد من حذف هاد المعاملة؟', textAlign: TextAlign.right,
            style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: _kRed),
            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _deleteTransaction();
  }

  Future<void> _deleteTransaction() async {
    final type = _tx['type'] as String;
    final id   = _tx['id'] as int;
    final db   = await DatabaseHelper.instance.database;

    if (type == 'CREDIT') {
      // Delete credit (cascade deletes payments)
      await db.delete('credits', where: 'id = ?', whereArgs: [id]);
    } else {
      // Revert payment amount on credit
      final creditId = _tx['creditId'] as int;
      final cRows = await db.query('credits', where: 'id = ?', whereArgs: [creditId]);
      if (cRows.isNotEmpty) {
        double restant = (cRows.first['montantRestant'] as num).toDouble() + _amount;
        final total    = (cRows.first['montantTotal']   as num).toDouble();
        if (restant > total) restant = total;
        await db.update('credits',
            {'montantRestant': restant, 'statut': 'EN_COURS'},
            where: 'id = ?', whereArgs: [creditId]);
      }
      await db.delete('paiements', where: 'id = ?', whereArgs: [id]);
    }

    final clientId = await _getClientId();
    if (clientId != null) await DatabaseHelper.instance.updateClientSolde(clientId);

    widget.onChanged();
    if (mounted) Navigator.pop(context);
  }

  Future<int?> _getClientId() async {
    final type = _tx['type'] as String;
    final id   = _tx['id'] as int;
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

  // ─────────────────────────── Share ───────────────────────────
  void _shareTx() {
    final type    = _isCredit ? 'أخذت' : 'أعطيت';
    final text    = 'العميل: ${widget.clientNom}\n'
                  '$type: ${formatMontant(_amount)}\n'
                  'الرصيد: ${formatMontant(_balance)}\n'
                  'التاريخ: ${_formatFullDate(_dateStr)}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('تم نسخ المعلومات', style: TextStyle(fontFamily: 'Cairo')),
      backgroundColor: _kBlue,
    ));
  }

  // ─────────────────────────── Full image ───────────────────────────
  void _showFullImage() {
    if (_img == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(children: [
          InteractiveViewer(
            panEnabled: true, scaleEnabled: true,
            child: Center(child: Image.file(File(_img!), fit: BoxFit.contain)),
          ),
          Positioned(
            top: 40, right: 10,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white, size: 30)),
          ),
        ]),
      ),
    );
  }
}

// ──────────────────────────── Edit Sheet ────────────────────────────
class _EditTxSheet extends StatefulWidget {
  final Map<String, dynamic> tx;
  final void Function(String? desc, double? amount) onSaved;
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
    _descCtrl = TextEditingController(text: widget.tx['description'] as String? ?? '');
  }

  @override
  void dispose() {
    _amountCtrl.dispose(); _descCtrl.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = widget.tx['type'] == 'CREDIT';
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
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              Text('تعديل ${isCredit ? "الكريدي" : "الدفعة"}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            ]),
            const SizedBox(height: 16),
            // Amount
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 20),
              decoration: InputDecoration(
                labelText: 'المبلغ',
                labelStyle: const TextStyle(fontFamily: 'Cairo'),
                prefixText: 'درهم  ',
                prefixStyle: const TextStyle(color: _kPrimary, fontFamily: 'Cairo'),
                filled: true, fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            // Description/note
            TextField(
              controller: _descCtrl,
              textAlign: TextAlign.right,
              maxLines: 2,
              style: const TextStyle(fontFamily: 'Cairo'),
              decoration: InputDecoration(
                labelText: isCredit ? 'الوصف' : 'ملاحظة',
                labelStyle: const TextStyle(fontFamily: 'Cairo'),
                filled: true, fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('حفظ التعديل',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Cairo')),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('دخل مبلغ صحيح', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.red));
      return;
    }
    setState(() => _saving = true);
    final desc = _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();
    widget.onSaved(desc, amount);
  }
}