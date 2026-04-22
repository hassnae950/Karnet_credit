import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database_helper.dart';
import '../models.dart';
import '../utils/helpers.dart';
import 'add_credit_sheet.dart';
import 'add_paiement_sheet.dart';
import 'transaction_detail_screen.dart';
import 'client_settings_screen.dart';
import 'package:flutter/services.dart';
import '../services/pdf_service.dart';

const kYellow = Color(0xFFFFA000); // للشيكات

class ClientDetailScreen extends StatefulWidget {
  final Client client;
  const ClientDetailScreen({super.key, required this.client});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  List<Map<String, dynamic>> _transactions = [];
  List<Cheque> _cheques = [];
  double _solde = 0;
  bool _loading = true;
  bool _showCheques = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final txs = await DatabaseHelper.instance.getAllTransactionsClient(widget.client.id!);
    final solde = await DatabaseHelper.instance.getSoldeClient(widget.client.id!);
    final credits = await DatabaseHelper.instance.getCreditsClient(widget.client.id!);

    final allCheques = <Cheque>[];
    for (final c in credits) {
      allCheques.addAll(await DatabaseHelper.instance.getChequesCredit(c.id!));
    }

    setState(() {
      _transactions = txs;
      _cheques = allCheques;
      _solde = solde;
      _loading = false;
    });
  }

  void _showFullImage(String path) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              panEnabled: true,
              scaleEnabled: true,
              child: Center(child: Image.file(File(path), fit: BoxFit.contain)),
            ),
            Positioned(
              top: 40,
              right: 10,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B8A6B),
        title: Text(
          widget.client.nom,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ClientSettingsScreen(client: widget.client)),
            ).then((_) => _loadData()),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B8A6B)))
          : RefreshIndicator(
              color: const Color(0xFF1B8A6B),
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  if (widget.client.telephone != null) _contactBar(),
                  _balanceCard(theme),
                  _actionButtons(),
                  if (_cheques.isNotEmpty) _sectionToggle(),
                  _showCheques ? _chequesList(theme) : _transactionsList(theme),
                ],
              ),
            ),
      bottomNavigationBar: _bottomBar(theme),
    );
  }

  // ── Contact Bar ──
  Widget _contactBar() => GestureDetector(
        onTap: () async {
          final tel = 'tel:${widget.client.telephone}';
          if (await canLaunchUrl(Uri.parse(tel))) {
            launchUrl(Uri.parse(tel));
          }
        },
        child: Container(
          color: const Color(0xFF1B8A6B).withOpacity(0.08),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.phone, color: Color(0xFF1B8A6B), size: 18),
              const SizedBox(width: 8),
              Text(
                widget.client.telephone!,
                style: const TextStyle(color: Color(0xFF1B8A6B), fontFamily: 'Cairo'),
              ),
            ],
          ),
        ),
      );

  // ── Balance Card ──
  Widget _balanceCard(ThemeData theme) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            const Text('الرصيد', style: TextStyle(color: Colors.grey, fontFamily: 'Cairo')),
            const SizedBox(height: 8),
            Text(
              formatMontant(_solde),
              style: TextStyle(
                color: _solde > 0 ? Colors.red : Colors.green,
                fontSize: 34,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            if (widget.client.company != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  widget.client.company!,
                  style: const TextStyle(color: Colors.grey, fontFamily: 'Cairo'),
                ),
              ),
          ],
        ),
      );

  // ── Action Buttons ──
  Widget _actionButtons() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _actionBtn(Icons.print_rounded, 'طبع', _showReport),
            _actionBtn(Icons.content_copy_rounded, 'نسخ', _shareClient),
            _actionBtn(Icons.phone_rounded, 'اتصال', _callClient),
            _actionBtn(Icons.edit_note_rounded, 'ملاحظة', _addNote),
          ],
        ),
      );

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF1B8A6B).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF1B8A6B), size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo'),
            ),
          ],
        ),
      );

  // ── Toggle between Transactions & Cheques ──
  Widget _sectionToggle() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: GestureDetector(
          onTap: () => setState(() => _showCheques = !_showCheques),
          child: Text(
            _showCheques
                ? 'الشيكات (${_cheques.length}) ← المعاملات'
                : 'المعاملات (${_transactions.length}) ← الشيكات',
            style: const TextStyle(
              color: Color(0xFF1B8A6B),
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

  // ── Transactions List ──
  Widget _transactionsList(ThemeData theme) {
    if (_transactions.isEmpty) {
      return _emptyState(Icons.receipt_long_outlined, 'ما كاين حتى معاملة', theme);
    }
    return Column(
      children: _transactions.map((tx) => _transactionItem(tx, theme)).toList(),
    );
  }

  Widget _transactionItem(Map<String, dynamic> tx, ThemeData theme) {
    final isCredit = tx['type'] == 'CREDIT';
    final amount = tx['amount'] as double;
    final balance = tx['balance'] as double;
    final date = _formatTxDate(tx['date'] as String);
    final imagePath = tx['imagePath'] as String?;
    final desc = tx['description'] as String?;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionDetailScreen(
            tx: tx,
            clientNom: widget.client.nom,
            onChanged: _loadData,
          ),
        ),
      ).then((_) => _loadData()),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Arrow Circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCredit ? const Color(0xFF1B8A6B) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCredit ? const Color(0xFF1B8A6B) : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: Icon(
                isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                color: isCredit ? Colors.white : (theme.brightness == Brightness.dark ? Colors.grey.shade300 : Colors.grey.shade700),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date, style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Cairo')),
                  if (desc != null && desc.isNotEmpty)
                    Text(
                      desc,
                      style: TextStyle(color: Colors.grey, fontSize: 13, fontFamily: 'Cairo'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (imagePath != null)
                    GestureDetector(
                      onTap: () => _showFullImage(imagePath),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(imagePath), height: 60, width: 60, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatMontant(amount),
                  style: TextStyle(
                    color: isCredit ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    fontFamily: 'Cairo',
                  ),
                ),
                Text(
                  isCredit ? 'أخذت' : 'أعطيت',
                  style: TextStyle(
                    color: isCredit ? Colors.red.withOpacity(0.7) : Colors.green.withOpacity(0.7),
                    fontSize: 12,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Cheques List ──
  Widget _chequesList(ThemeData theme) {
    if (_cheques.isEmpty) {
      return _emptyState(Icons.document_scanner_outlined, 'ما كاين حتى شيك', theme);
    }
    return Column(
      children: _cheques.map((ch) => _chequeCard(ch, theme)).toList(),
    );
  }

  Widget _chequeCard(Cheque ch, ThemeData theme) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ch.statutColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ch.statutLabel,
                    style: TextStyle(color: ch.statutColor, fontSize: 12, fontFamily: 'Cairo'),
                  ),
                ),
                const Spacer(),
                Text(
                  formatDate(ch.dateCreation),
                  style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ch.numero.isNotEmpty)
                      Text('# ${ch.numero}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    if (ch.banque != null)
                      Text(ch.banque!, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    Text(
                      'استحقاق: ${formatDate(ch.dateEcheance)}',
                      style: TextStyle(color: kYellow, fontSize: 13, fontFamily: 'Cairo'),
                    ),
                  ],
                ),
                Text(
                  formatMontant(ch.montant),
                  style: const TextStyle(
                    color: Color(0xFF1B8A6B),
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
            if (ch.statut == 'EN_ATTENTE') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _statusBtn('مرفوض', 'REFUSE', Colors.red, ch.id!),
                  const SizedBox(width: 12),
                  _statusBtn('محصّل', 'ENCAISSE', Colors.green, ch.id!),
                ],
              ),
            ],
          ],
        ),
      );

  Widget _statusBtn(String label, String statut, Color color, int id) => GestureDetector(
        onTap: () async {
          await DatabaseHelper.instance.updateChequeStatut(id, statut);
          await _loadData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontFamily: 'Cairo'),
          ),
        ),
      );

  Widget _emptyState(IconData icon, String msg, ThemeData theme) => Center(
        child: Padding(
          padding: const EdgeInsets.all(60),
          child: Column(
            children: [
              Icon(icon, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(msg, style: TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontSize: 16)),
            ],
          ),
        ),
      );

  // ── Bottom Bar ──
  Widget _bottomBar(ThemeData theme) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -3)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.12),
                  foregroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _ajouterPaiement,
                icon: const Icon(Icons.arrow_upward),
                label: const Text('أعطيت', style: TextStyle(fontFamily: 'Cairo')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B8A6B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _ajouterCredit,
                icon: const Icon(Icons.arrow_downward),
                label: const Text('أخذت', style: TextStyle(fontFamily: 'Cairo')),
              ),
            ),
          ],
        ),
      );

  // ── Actions ──
  void _ajouterCredit() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AddCreditSheet(clientId: widget.client.id!, onSaved: _loadData),
      );

  void _ajouterPaiement() {
    if (_solde <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرصيد صفر، ما كاين شي باش تخلصو', style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPaiementSheet(
        clientId: widget.client.id!,
        totalRestant: _solde,
        onSaved: _loadData,
      ),
    );
  }

  void _ajouterCheque() {
    DatabaseHelper.instance.getCreditsClient(widget.client.id!).then((credits) {
      final open = credits.where((c) => !c.estSolde).toList();
      if (open.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خلق كريدي أولاً قبل إضافة شيك', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: kYellow,
          ),
        );
        return;
      }
   
    });
  }

  String _formatTxDate(String isoDate) {
    final d = DateTime.parse(isoDate).toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDay = DateTime(d.year, d.month, d.day);

    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');

    if (txDay == today) return 'اليوم ساعة $h:$m';

    const mo = ['', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    return '${d.day} ${mo[d.month]} ساعة $h:$m';
  }











  // ── طبع PDF ──
  Future<void> _showReport() async {
    if (_transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('ما كاين حتى معاملة للطباعة', style: TextStyle(fontFamily: 'Cairo'))));
      return;
    }
    try {
      final credits = await DatabaseHelper.instance.getCreditsClient(widget.client.id!);
      final pMap = <int, List<Paiement>>{};
      for (final c in credits) {
        pMap[c.id!] = await DatabaseHelper.instance.getPaiementsCredit(c.id!);
      }
      await PdfService.instance.printClientReport(widget.client, credits, pMap);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('خطأ: $e', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.red));
    }
  }

  // ── نسخ ──
  void _shareClient() async {
    final lines = StringBuffer();
    lines.writeln('العميل: ${widget.client.nom}');
    if (widget.client.telephone != null) lines.writeln('الهاتف: ${widget.client.telephone}');
    if (widget.client.company   != null) lines.writeln('الشركة: ${widget.client.company}');
    lines.writeln('الرصيد: ${formatMontant(_solde)}');
    lines.writeln('عدد المعاملات: ${_transactions.length}');
await Clipboard.setData(ClipboardData(text: lines.toString()));
if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    content: Text('تم نسخ المعلومات ✓', style: TextStyle(fontFamily: 'Cairo')),
    backgroundColor: Color(0xFF1B8A6B),
  ));
}  }

  // ── اتصال ──
  void _callClient() async {
    if (widget.client.telephone == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('ما كاين حتى رقم هاتف', style: TextStyle(fontFamily: 'Cairo'))));
      return;
    }
    final uri = Uri.parse('tel:${widget.client.telephone}');
    if (await canLaunchUrl(uri)) {
      launchUrl(uri);
    }
  }

  // ── ملاحظة ──
  void _addNote() {
    final ctrl = TextEditingController(text: widget.client.notes ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final isDark = Theme.of(sheetCtx).brightness == Brightness.dark;
        final sheetBg   = isDark ? const Color(0xFF1E1E2E) : Colors.white;
        final fillColor = isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF5F6FA);
        final textColor = isDark ? Colors.white : Colors.black87;

        return Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
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
                      onPressed: () => Navigator.pop(sheetCtx),
                      icon: Icon(Icons.close, color: textColor)),
                  Text('ملاحظة',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: textColor)),
                ]),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  textAlign: TextAlign.right,
                  maxLines: 5,
                  autofocus: true,
                  style: TextStyle(fontFamily: 'Cairo', color: textColor),
                  decoration: InputDecoration(
                    hintText: 'أضف ملاحظة عن هذا العميل...',
                    hintStyle: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade500),
                    filled: true,
                    fillColor: fillColor,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B8A6B),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final note = ctrl.text.trim().isEmpty ? null : ctrl.text.trim();
                      widget.client.notes = note;
                      await DatabaseHelper.instance.updateClient(widget.client);
                      if (mounted) {
                        Navigator.pop(sheetCtx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('تم حفظ الملاحظة ✅',
                                style: TextStyle(fontFamily: 'Cairo')),
                            backgroundColor: Color(0xFF1B8A6B)));
                      }
                    },
                    child: const Text('حفظ',
                        style: TextStyle(color: Colors.white, fontSize: 16,
                            fontFamily: 'Cairo')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

 }