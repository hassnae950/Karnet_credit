import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database_helper.dart';
import '../models.dart';
import '../utils/helpers.dart';
import '../utils/app_translations.dart';
import '../services/pdf_service.dart';
import '../services/image_encryption_service.dart';
import 'add_credit_sheet.dart';
import 'add_paiement_sheet.dart';
import 'add_cheque_sheet.dart';
import 'transaction_detail_screen.dart';
import 'client_settings_screen.dart';

const kYellow = Color(0xFFFFA000);
const _kPrimary = Color(0xFF1B8A6B);
const _kGreen = Color(0xFF388E3C);
const _kRed = Color(0xFFD32F2F);

class ClientDetailScreen extends StatefulWidget {
  final Client client;
  const ClientDetailScreen({super.key, required this.client});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _transactions = [];
  List<Cheque> _cheques = [];
  List<Credit> _credits = [];
  double _solde = 0;
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    setState(() => _loading = true);
    final txs = await DatabaseHelper.instance
        .getAllTransactionsClient(widget.client.id!);
    final solde =
        await DatabaseHelper.instance.getSoldeClient(widget.client.id!);
    final credits =
        await DatabaseHelper.instance.getCreditsClient(widget.client.id!);
    final allCheques = <Cheque>[];
    for (final c in credits) {
      allCheques.addAll(await DatabaseHelper.instance.getChequesCredit(c.id!));
    }
    setState(() {
      _transactions = txs;
      _cheques = allCheques;
      _credits = credits;
      _solde = solde;
      _loading = false;
    });
  }

  // ── عرض الصورة مع فك التشفير ─────────────────────────────────────────────────
  void _showFullImage(String path) async {
    final svc = ImageEncryptionService.instance;
    File? displayFile;
    bool isTempFile = false;

    if (svc.isEncrypted(path)) {
      displayFile = await svc.decryptImageToTemp(path);
      isTempFile = true;
    } else {
      displayFile = File(path);
    }

    if (displayFile == null || !mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(children: [
          InteractiveViewer(
            panEnabled: true,
            scaleEnabled: true,
            child: Center(
              child: Image.file(displayFile!, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: 40,
            right: 10,
            child: IconButton(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
            ),
          ),
          // شارة مشفرة
          if (isTempFile)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text('صورة مشفرة — AES-256',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'Cairo')),
                    ],
                  ),
                ),
              ),
            ),
        ]),
      ),
    );

    // امسح الملف المؤقت بعد الإغلاق
    if (isTempFile && displayFile != null) {
      await svc.deleteTempFile(displayFile!.path);
    }
  }

  Widget _chequeImage(String imagePath) {
    final svc = ImageEncryptionService.instance;

    // ✅ شيك أولاً إذا الملف موجود
    if (!File(imagePath).existsSync()) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_not_supported_outlined,
                  color: Colors.grey, size: 28),
              SizedBox(height: 4),
              Text('الصورة غير متوفرة',
                  style: TextStyle(
                      color: Colors.grey, fontSize: 11, fontFamily: 'Cairo')),
            ],
          ),
        ),
      );
    }

    if (!svc.isEncrypted(imagePath)) {
      return Image.file(
        File(imagePath),
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    return FutureBuilder<File?>(
      future: svc.decryptImageToTemp(imagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 120,
            child: Center(
              child:
                  CircularProgressIndicator(color: _kPrimary, strokeWidth: 2),
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
              child: Icon(Icons.broken_image, color: Colors.grey),
            ),
          );
        }
        return Stack(
          children: [
            Image.file(
              snapshot.data!,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, color: Colors.white, size: 10),
                    SizedBox(width: 3),
                    Text('مشفرة',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontFamily: 'Cairo')),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        title: Text(widget.client.nom,
            style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ClientSettingsScreen(client: widget.client)),
            ).then((_) => loadData()),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle:
              const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: '${Tr.s('cheques')} (${_cheques.length})'),
            Tab(text: '${Tr.s('transactions')} (${_transactions.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : Column(children: [
              if (widget.client.telephone != null) _contactBar(),
              _balanceCard(theme),
              _actionButtons(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _chequeTabContent(theme),
                    _transactionsTabContent(theme),
                  ],
                ),
              ),
            ]),
      bottomNavigationBar: _bottomBar(theme),
    );
  }

  Widget _contactBar() => GestureDetector(
        onTap: () async {
          final uri = Uri.parse('tel:${widget.client.telephone}');
          if (await canLaunchUrl(uri)) launchUrl(uri);
        },
        child: Container(
          color: _kPrimary.withOpacity(0.08),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.phone, color: _kPrimary, size: 18),
            const SizedBox(width: 8),
            Text(widget.client.telephone!,
                style: const TextStyle(color: _kPrimary, fontFamily: 'Cairo')),
          ]),
        ),
      );

  Widget _balanceCard(ThemeData theme) => Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(children: [
          Text(Tr.s('balance'),
              style: const TextStyle(color: Colors.grey, fontFamily: 'Cairo')),
          const SizedBox(height: 8),
          Text(
            formatMontant(_solde),
            style: TextStyle(
              color: _solde > 0 ? _kRed : _kGreen,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          if (widget.client.telephone != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(widget.client.telephone!,
                  style: const TextStyle(
                      color: Colors.grey, fontFamily: 'Cairo', fontSize: 13)),
            ),
          if (widget.client.company != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(widget.client.company!,
                  style:
                      const TextStyle(color: Colors.grey, fontFamily: 'Cairo')),
            ),
        ]),
      );

  Widget _actionButtons() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _actionBtn(Icons.print_rounded, Tr.s('print'), _showReport),
            _actionBtn(Icons.content_copy_rounded, Tr.s('copy'), _shareClient),
            _actionBtn(Icons.phone_rounded, Tr.s('call'), _callClient),
            _actionBtn(Icons.edit_note_rounded, Tr.s('note'), _addNote),
          ],
        ),
      );

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Column(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _kPrimary, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 12, fontFamily: 'Cairo')),
        ]),
      );

  Widget _chequeTabContent(ThemeData theme) => RefreshIndicator(
        onRefresh: loadData,
        color: _kPrimary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            GestureDetector(
              onTap: _ajouterCheque,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    Text(Tr.s('add_cheque_label'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_cheques.isEmpty)
              _emptyState(
                  Icons.document_scanner_outlined, Tr.s('no_cheques'), theme)
            else
              ..._cheques.map((ch) => _chequeCard(ch, theme)),
          ],
        ),
      );

  Widget _transactionsTabContent(ThemeData theme) => RefreshIndicator(
        onRefresh: loadData,
        color: const Color.fromARGB(255, 0, 0, 0),
        child: _transactions.isEmpty
            ? ListView(children: [
                _emptyState(
                    Icons.receipt_long_outlined, Tr.s('no_transactions'), theme)
              ])
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: _transactions.length,
                itemBuilder: (_, i) =>
                    _transactionItem(_transactions[i], theme),
              ),
      );

  Widget _transactionItem(Map<String, dynamic> tx, ThemeData theme) {
    final isCredit = tx['type'] == 'CREDIT';
    final amount = tx['amount'] as double;
    final date = Tr.formatTxDate(tx['date'] as String);
    final imagePath = tx['imagePath'] as String?;
    final desc = tx['description'] as String?;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionDetailScreen(
            tx: tx,
            clientNom: widget.client.nom,
            onChanged: loadData,
          ),
        ),
      ).then((_) => loadData()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCredit
                  ? Colors.transparent
                  : _kGreen, // أعطيت فارغة، أخذت مملوءة
              shape: BoxShape.circle,
              border: Border.all(
                color: isCredit ? _kRed : _kGreen,
                width: 2,
              ),
            ),
            child: Icon(
              isCredit ? Icons.arrow_upward : Icons.arrow_downward,
              color: isCredit ? _kRed : Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(date,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontFamily: 'Cairo')),
              if (desc != null && desc.isNotEmpty)
                Text(desc,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 13, fontFamily: 'Cairo'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              if (imagePath != null)
                GestureDetector(
                  onTap: () => _showFullImage(imagePath),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _chequeImage(imagePath),
                    ),
                  ),
                ),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              formatMontant(amount),
              style: TextStyle(
                color: isCredit ? _kRed : _kGreen, // أعطيت أحمر، أخذت أخضر
                fontWeight: FontWeight.bold,
                fontSize: 17,
                fontFamily: 'Cairo',
              ),
            ),
            Text(
              isCredit ? Tr.s('gave') : Tr.s('took'),
              style: TextStyle(
                color: isCredit
                    ? _kRed.withOpacity(0.7)
                    : _kGreen.withOpacity(0.7),
                fontSize: 12,
                fontFamily: 'Cairo',
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _chequeCard(Cheque ch, ThemeData theme) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: ch.statutColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(ch.statutLabel,
                  style: TextStyle(
                      color: ch.statutColor,
                      fontSize: 12,
                      fontFamily: 'Cairo')),
            ),
            const Spacer(),
            Text(formatDate(ch.dateCreation),
                style: const TextStyle(
                    color: Colors.grey, fontSize: 12, fontFamily: 'Cairo')),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (ch.numero.isNotEmpty)
                Text('# ${ch.numero}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              if (ch.banque != null)
                Text(ch.banque!,
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              Text(
                '${Tr.s('due_label')} ${formatDate(ch.dateEcheance)}',
                style: const TextStyle(
                    color: kYellow, fontSize: 13, fontFamily: 'Cairo'),
              ),
            ]),
            Text(formatMontant(ch.montant),
                style: const TextStyle(
                    color: _kPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    fontFamily: 'Cairo')),
          ]),
          // ✅ صورة الشيك مع فك التشفير
          if (ch.imagePath != null && ch.imagePath!.isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _showFullImage(ch.imagePath!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _chequeImage(ch.imagePath!),
              ),
            ),
          ],
          if (ch.statut == 'EN_ATTENTE') ...[
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              _statusBtn(Tr.s('rejected'), 'REFUSE', Colors.red, ch.id!),
              const SizedBox(width: 12),
              _statusBtn(Tr.s('collected'), 'ENCAISSE', Colors.green, ch.id!),
            ]),
          ],
        ]),
      );

  Widget _statusBtn(String label, String statut, Color color, int id) =>
      GestureDetector(
        onTap: () async {
          await DatabaseHelper.instance.updateChequeStatut(id, statut);
          await loadData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo')),
        ),
      );

  Widget _emptyState(IconData icon, String msg, ThemeData theme) => Center(
        child: Padding(
          padding: const EdgeInsets.all(60),
          child: Column(children: [
            Icon(icon, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(msg,
                style: const TextStyle(
                    color: Colors.grey, fontFamily: 'Cairo', fontSize: 16)),
          ]),
        ),
      );

  Widget _bottomBar(ThemeData theme) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, -3))
          ],
        ),
        child: Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                // ✅ أعطيت = أحمر فاتح
                backgroundColor: _kGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _ajouterPaiement,
              icon: const Icon(Icons.arrow_upward),
              label: Text(Tr.s('took'),
                  style: const TextStyle(fontFamily: 'Cairo')),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                // ✅ أخذت = أخضر مملوء
                backgroundColor: _kRed.withOpacity(0.2),
                foregroundColor: _kRed,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _ajouterCredit,
              icon: const Icon(Icons.arrow_downward),
              label: Text(Tr.s('gave'),
                  style: const TextStyle(fontFamily: 'Cairo')),
            ),
          ),
        ]),
      );
  void _ajouterCredit() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            AddCreditSheet(clientId: widget.client.id!, onSaved: loadData),
      );

  void _ajouterPaiement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPaiementSheet(
        clientId: widget.client.id!,
        totalRestant: _solde,
        onSaved: loadData,
      ),
    );
  }

  void _ajouterCheque() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            AddChequeSheet(clientId: widget.client.id!, onSaved: loadData),
      );

  Future<void> _showReport() async {
    if (_transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(Tr.s('no_transactions_print'),
              style: const TextStyle(fontFamily: 'Cairo'))));
      return;
    }
    try {
      final credits =
          await DatabaseHelper.instance.getCreditsClient(widget.client.id!);
      final pMap = <int, List<Paiement>>{};
      for (final c in credits) {
        pMap[c.id!] = await DatabaseHelper.instance.getPaiementsCredit(c.id!);
      }
      await PdfService.instance.printClientReport(widget.client, credits, pMap);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${Tr.s('error_prefix')} $e',
              style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.red));
    }
  }

  void _shareClient() async {
    final lines = StringBuffer();
    lines.writeln('${Tr.s('client')}: ${widget.client.nom}');
    if (widget.client.telephone != null) {
      lines.writeln('${Tr.s('phone')}: ${widget.client.telephone}');
    }
    if (widget.client.company != null) {
      lines.writeln('${Tr.s('company')}: ${widget.client.company}');
    }
    lines.writeln('${Tr.s('balance')}: ${formatMontant(_solde)}');
    await Clipboard.setData(ClipboardData(text: lines.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(Tr.s('info_copied'),
            style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: _kPrimary,
      ));
    }
  }

  void _callClient() async {
    if (widget.client.telephone == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(Tr.s('no_phone'),
              style: const TextStyle(fontFamily: 'Cairo'))));
      return;
    }
    final uri = Uri.parse('tel:${widget.client.telephone}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('لا يمكن فتح تطبيق الهاتف',
                style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.red));
      }
    }
  }

  void _addNote() {
    final ctrl = TextEditingController(text: widget.client.notes ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final isDark = Theme.of(sheetCtx).brightness == Brightness.dark;
        final sheetBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
        final fillColor =
            isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF5F6FA);
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
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          icon: Icon(Icons.close, color: textColor)),
                      Text(Tr.s('note'),
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                              color: textColor)),
                    ]),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  textAlign: Tr.textAlignStart,
                  maxLines: 5,
                  autofocus: true,
                  style: TextStyle(fontFamily: 'Cairo', color: textColor),
                  decoration: InputDecoration(
                    hintText: Tr.s('note_placeholder'),
                    hintStyle: TextStyle(
                        fontFamily: 'Cairo', color: Colors.grey.shade500),
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
                      backgroundColor: _kPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final note =
                          ctrl.text.trim().isEmpty ? null : ctrl.text.trim();
                      widget.client.notes = note;
                      await DatabaseHelper.instance.updateClient(widget.client);
                      if (mounted) {
                        Navigator.pop(sheetCtx);
                        await loadData();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(Tr.s('note_saved'),
                                style: const TextStyle(fontFamily: 'Cairo')),
                            backgroundColor: _kPrimary));
                      }
                    },
                    child: Text(Tr.s('save'),
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
      },
    );
  }
}
