import 'dart:io';
import '../services/pdf_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database_helper.dart';
import '../models.dart';
import '../utils/helpers.dart';
import 'add_credit_sheet.dart';
import 'transaction_detail_screen.dart';
import 'add_paiement_sheet.dart';
import 'add_cheque_sheet.dart';
import 'client_settings_screen.dart';

const kPrimary = Color(0xFF1B8A6B);
const kRed     = Color(0xFFD32F2F);
const kGreen   = Color(0xFF388E3C);
const kYellow  = Color(0xFFFFA000);
const kBg      = Color(0xFFF5F6FA);
const kRedBg   = Color(0xFFFFEBEE);
const kGreenBg = Color(0xFFE8F5E9);

class ClientDetailScreen extends StatefulWidget {
  final Client client;
  const ClientDetailScreen({super.key, required this.client});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  List<Map<String, dynamic>> _transactions = [];
  List<Cheque>  _cheques  = [];
  double        _solde    = 0;
  bool          _loading  = true;
  bool          _showCheques = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final txs    = await DatabaseHelper.instance.getAllTransactionsClient(widget.client.id!);
    final solde  = await DatabaseHelper.instance.getSoldeClient(widget.client.id!);
    final credits = await DatabaseHelper.instance.getCreditsClient(widget.client.id!);
    final allCheques = <Cheque>[];
    for (final c in credits) {
      allCheques.addAll(await DatabaseHelper.instance.getChequesCredit(c.id!));
    }
    setState(() {
      _transactions = txs;
      _cheques      = allCheques;
      _solde        = solde;
      _loading      = false;
    });
  }

  // ── Helpers ──
  String _formatTxDate(String isoDate) {
    final d   = DateTime.parse(isoDate).toLocal();
    final now = DateTime.now();
    final h   = d.hour.toString().padLeft(2, '0');
    final m   = d.minute.toString().padLeft(2, '0');
    final today = DateTime(now.year, now.month, now.day);
    final txDay = DateTime(d.year, d.month, d.day);
    if (txDay == today) return 'اليوم ساعة $h:$m';
    const mo = ['','يناير','فبراير','مارس','أبريل','مايو','يونيو',
                    'يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    return '${d.day} ${mo[d.month]} ساعة $h:$m';
  }

  void _showFullImage(String path) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(children: [
          InteractiveViewer(
            panEnabled: true, scaleEnabled: true,
            child: Center(
              child: Image.file(File(path), fit: BoxFit.contain)),
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

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kPrimary,
        title: Text(widget.client.nom,
            style: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
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
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(
              color: kPrimary,
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  // Contact info line
                  if (widget.client.telephone != null)
                    _contactBar(),

                  // Balance card
                  _balanceCard(),

                  // Action buttons
                  _actionButtons(),

                  // Cheques / transactions toggle
                  if (_cheques.isNotEmpty) _sectionToggle(),

                  // Transactions or Cheques
                  _showCheques ? _chequesList() : _transactionsList(),
                ],
              ),
            ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  // ── Contact bar ──
  Widget _contactBar() => GestureDetector(
    onTap: () async {
      final tel = 'tel:${widget.client.telephone}';
      if (await canLaunchUrl(Uri.parse(tel))) {
        launchUrl(Uri.parse(tel));
      }
    },
    child: Container(
      color: kPrimary.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.phone, color: kPrimary, size: 16),
          const SizedBox(width: 6),
          Text(
            widget.client.telephone!,
            style: const TextStyle(
                color: kPrimary, fontFamily: 'Cairo', fontSize: 13),
          ),
          const SizedBox(width: 6),
          const Text('• اضغط للاتصال',
              style: TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontSize: 11)),
        ],
      ),
    ),
  );

  // ── Balance card ──
  Widget _balanceCard() => Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0,4))],
    ),
    child: Column(children: [
      const Text('الرصيد',
          style: TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Cairo')),
      const SizedBox(height: 8),
      Text(
        formatMontant(_solde),
        style: TextStyle(
          color: _solde > 0 ? kRed : kGreen,
          fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Cairo',
        ),
      ),
      if (widget.client.company != null) ...[
        const SizedBox(height: 4),
        Text(widget.client.company!,
            style: const TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontSize: 12)),
      ],
    ]),
  );

  // ── Action buttons ──
  Widget _actionButtons() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _actionBtn(Icons.print_rounded, 'طبع', _showReport),
        _actionBtn(Icons.content_copy_rounded,     'نسخ', _shareClient),
        _actionBtn(Icons.phone_rounded,     'اتصال',  _callClient),
        _actionBtn(Icons.edit_note_rounded, 'ملاحظة', _addNote),
      ],
    ),
  );

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: kPrimary, size: 24),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(
            color: Colors.grey, fontSize: 11, fontFamily: 'Cairo')),
      ]),
    );

  // ── Section toggle (transactions / cheques) ──
  Widget _sectionToggle() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => setState(() => _showCheques = !_showCheques),
          child: Text(
            _showCheques
                ? 'الشيكات (${_cheques.length})'
                : 'معاملات (${_transactions.length})',
            style: const TextStyle(
                color: kPrimary, fontFamily: 'Cairo',
                fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _showCheques = !_showCheques),
          child: Text(
            _showCheques ? 'المعاملات' : 'الشيكات (${_cheques.length})',
            style: const TextStyle(
                color: kPrimary, fontFamily: 'Cairo', fontSize: 12),
          ),
        ),
      ],
    ),
  );

  // ── Transactions list (image 1 style) ──
  Widget _transactionsList() {
    if (_transactions.isEmpty) {
      return _emptyState(Icons.receipt_long_outlined, 'ما كاين حتى معاملة');
    }
    final label = _cheques.isEmpty ? 'معاملات (${_transactions.length})' : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(label,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 13, fontFamily: 'Cairo')),
          ),
        ...  _transactions.map(_transactionItem),
      ],
    );
  }

  Widget _transactionItem(Map<String, dynamic> tx) {
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
      child: _transactionItemContent(tx),
    );
  }

  Widget _transactionItemContent(Map<String, dynamic> tx) {
    final isCredit  = tx['type'] == 'CREDIT';
    final amount    = tx['amount'] as double;
    final balance   = tx['balance'] as double;
    final date      = _formatTxDate(tx['date'] as String);
    final imagePath = tx['imagePath'] as String?;
    final desc      = tx['description'] as String?;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0,2))],
      ),
      child: Row(
        children: [
          // ── Arrow circle ──
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isCredit ? kPrimary : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCredit ? kPrimary : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCredit ? Colors.white : Colors.black54,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // ── Date + balance + image ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Cairo',
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  'الرصيد ${formatMontant(balance)}',
                  style: const TextStyle(
                      color: Colors.grey, fontFamily: 'Cairo', fontSize: 11),
                ),
                if (desc != null && desc.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(desc,
                      style: const TextStyle(
                          color: Colors.grey, fontFamily: 'Cairo', fontSize: 11),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                if (imagePath != null && imagePath.isNotEmpty)
                  GestureDetector(
                    onTap: () => _showFullImage(imagePath),
                    child: Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 52, height: 42,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(imagePath), fit: BoxFit.cover),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Amount + label ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMontant(amount),
                style: TextStyle(
                  color: isCredit ? kRed : kGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                isCredit ? 'أخذت' : 'أعطيت',
                style: TextStyle(
                  color: isCredit ? kRed.withOpacity(0.6) : kGreen.withOpacity(0.6),
                  fontSize: 11,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Cheques list ──
  Widget _chequesList() {
    if (_cheques.isEmpty) return _emptyState(Icons.document_scanner_outlined, 'ما كاين حتى شيك');
    return Column(
      children: _cheques.map(_chequeCard).toList(),
    );
  }

  Widget _chequeCard(Cheque ch) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: ch.statutColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(ch.statutLabel,
              style: TextStyle(color: ch.statutColor, fontSize: 11, fontFamily: 'Cairo')),
        ),
        const Spacer(),
        Text(formatDate(ch.dateCreation),
            style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Cairo')),
      ]),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (ch.numero.isNotEmpty)
            Text('# ${ch.numero}',
                style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Cairo')),
          if (ch.banque != null)
            Text(ch.banque!,
                style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Cairo')),
          Text('استحقاق: ${formatDate(ch.dateEcheance)}',
              style: const TextStyle(color: kYellow, fontSize: 11, fontFamily: 'Cairo')),
        ]),
        Text(formatMontant(ch.montant),
            style: const TextStyle(
                color: kPrimary, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo')),
      ]),
      if (ch.statut == 'EN_ATTENTE') ...[
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          _statusBtn('مرفوض', 'REFUSE', kRed, ch.id!),
          const SizedBox(width: 8),
          _statusBtn('محصّل', 'ENCAISSE', kGreen, ch.id!),
        ]),
      ],
    ]),
  );

  Widget _statusBtn(String label, String statut, Color color, int id) => GestureDetector(
    onTap: () async {
      await DatabaseHelper.instance.updateChequeStatut(id, statut);
      await _loadData();
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontFamily: 'Cairo')),
    ),
  );

  Widget _emptyState(IconData icon, String msg) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(children: [
        Icon(icon, size: 72, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 16, fontFamily: 'Cairo')),
      ]),
    ),
  );

  // ── Bottom bar ──
  Widget _bottomBar() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,-2))],
    ),
    child: Row(children: [
      Expanded(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: kRedBg, elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: _ajouterPaiement,
          icon: const Icon(Icons.arrow_upward, color: kRed),
          label: const Text('أعطيت',
              style: TextStyle(color: kRed, fontFamily: 'Cairo', fontSize: 15)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: _ajouterCredit,
          icon: const Icon(Icons.arrow_downward, color: Colors.white),
          label: const Text('أخذت',
              style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 15)),
        ),
      ),
    ]),
  );

  // ── Actions ──
  void _ajouterCredit() => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => AddCreditSheet(clientId: widget.client.id!, onSaved: _loadData),
  );

  void _ajouterPaiement() {
    if (_solde <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('الرصيد صفر، ما كاين شي باش تخلصو',
              style: TextStyle(fontFamily: 'Cairo'))));
      return;
    }
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => AddPaiementSheet(
        clientId: widget.client.id!,
        totalRestant: _solde,
        onSaved: _loadData,
      ),
    );
  }

  void _ajouterCheque() {
    // Need an open credit
    DatabaseHelper.instance.getCreditsClient(widget.client.id!).then((credits) {
      final open = credits.where((c) => !c.estSolde).toList();
      if (open.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('خلق كريدي أولاً قبل إضافة شيك',
              style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: kYellow,
        ));
        return;
      }
      showModalBottomSheet(
        context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (_) => AddChequeSheet(creditId: open.first.id!, onSaved: _loadData),
      );
    });
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
      builder: (_) => Container(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
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
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
                const Text('ملاحظة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo')),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                textAlign: TextAlign.right,
                maxLines: 5,
                autofocus: true,
                style: const TextStyle(fontFamily: 'Cairo'),
                decoration: InputDecoration(
                  hintText: 'أضف ملاحظة عن هذا العميل...',
                  hintStyle: const TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF5F6FA),
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
                      Navigator.pop(context);
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
      ),
    );
  }
}


