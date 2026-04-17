import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';
import '../utils/helpers.dart';
import 'add_credit_sheet.dart';
import 'add_paiement_sheet.dart';
import 'add_cheque_sheet.dart';
import 'credit_detail_screen.dart';
import 'client_settings_screen.dart';

const kPrimary = Color(0xFF1B8A6B);
const kRed = Color(0xFFD32F2F);
const kGreen = Color(0xFF388E3C);
const kYellow = Color(0xFFFFA000);
const kBg = Color(0xFFF5F6FA);
const kRedBg = Color(0xFFFFEBEE);
const kGreenBg = Color(0xFFE8F5E9);

class ClientDetailScreen extends StatefulWidget {
  final Client client;
  const ClientDetailScreen({super.key, required this.client});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Credit> _credits = [];
  List<Cheque> _cheques = [];
  double _solde = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final credits = await DatabaseHelper.instance.getCreditsClient(widget.client.id!);
    final solde = await DatabaseHelper.instance.getSoldeClient(widget.client.id!);
    final allCheques = <Cheque>[];
    for (final c in credits) {
      allCheques.addAll(await DatabaseHelper.instance.getChequesCredit(c.id!));
    }
    setState(() {
      _credits = credits;
      _cheques = allCheques;
      _solde = solde;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kPrimary,
        title: Text(widget.client.nom,
            style: const TextStyle(color: Colors.white, fontFamily: 'Cairo')),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ClientSettingsScreen(client: widget.client)),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: 'الكريديات (${_credits.length})'),
            Tab(text: 'الشيكات (${_cheques.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          _soldeCard(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: kPrimary))
                : TabBarView(
                    controller: _tab,
                    children: [
                      _creditsTab(),
                      _chequesTab(),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _soldeCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          const Text('الرصيد',
              style: TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Cairo')),
          const SizedBox(height: 8),
          Text(
            formatMontant(_solde),
            style: TextStyle(
              color: _solde > 0 ? kRed : kGreen,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          if (widget.client.telephone != null) ...[
            const SizedBox(height: 6),
            Text(widget.client.telephone!,
                style: const TextStyle(color: Colors.grey, fontFamily: 'Cairo')),
          ],
        ],
      ),
    );
  }

  Widget _creditsTab() {
    if (_credits.isEmpty) {
      return _emptyState(Icons.receipt_long_outlined, 'ما كاين حتى معاملة');
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        itemCount: _credits.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _creditCard(_credits[i]),
      ),
    );
  }

  Widget _creditCard(Credit c) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreditDetailScreen(
            credit: c,
            clientNom: widget.client.nom,
          ),
        ),
      ).then((_) => _loadData()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
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
                    color: c.estSolde ? kGreenBg : kRedBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    c.estSolde ? 'مسوى' : 'جاري',
                    style: TextStyle(
                      color: c.estSolde ? kGreen : kRed,
                      fontSize: 11,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  formatDate(c.dateCredit),
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
                    Text(
                      formatMontant(c.montantRestant),
                      style: const TextStyle(
                          color: kRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          fontFamily: 'Cairo'),
                    ),
                    const Text('الباقي',
                        style: TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Cairo')),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatMontant(c.montantTotal),
                      style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          fontFamily: 'Cairo'),
                    ),
                    const Text('المجموع',
                        style: TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Cairo')),
                  ],
                ),
              ],
            ),
            if (c.description != null) ...[
              const SizedBox(height: 8),
              Text(c.description!,
                  style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo')),
            ],
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: c.pourcentagePaye.clamp(0.0, 1.0),
                backgroundColor: kRedBg,
                valueColor: const AlwaysStoppedAnimation<Color>(kPrimary),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chequesTab() {
    if (_cheques.isEmpty) {
      return _emptyStateWithButton(
        Icons.document_scanner_outlined,
        'ما كاين حتى شيك',
        'إضافة شيك',
        () => _ajouterCheque(),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: _ajouterCheque,
              icon: const Icon(Icons.add),
              label: const Text('إضافة شيك'),
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _cheques.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _chequeCard(_cheques[i]),
          ),
        ),
      ],
    );
  }

  Widget _chequeCard(Cheque ch) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  style: TextStyle(
                      color: ch.statutColor, fontSize: 11, fontFamily: 'Cairo'),
                ),
              ),
              const Spacer(),
              Text(
                formatDate(ch.dateCreation),
                style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Cairo'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ch.numero.isNotEmpty)
                    Text('# ${ch.numero}',
                        style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Cairo')),
                  if (ch.banque != null)
                    Text(ch.banque!,
                        style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Cairo')),
                  Text(
                    'استحقاق: ${formatDate(ch.dateEcheance)}',
                    style: const TextStyle(color: kYellow, fontSize: 11, fontFamily: 'Cairo'),
                  ),
                ],
              ),
              Text(
                formatMontant(ch.montant),
                style: const TextStyle(
                    color: kPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Cairo'),
              ),
            ],
          ),
          if (ch.statut == 'EN_ATTENTE') ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _statusBtn('مرفوض', 'REFUSE', kRed, ch.id!),
                const SizedBox(width: 8),
                _statusBtn('محصّل', 'ENCAISSE', kGreen, ch.id!),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBtn(String label, String statut, Color color, int id) {
    return GestureDetector(
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
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 12, fontFamily: 'Cairo'),
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(msg,
              style: const TextStyle(color: Colors.grey, fontSize: 16, fontFamily: 'Cairo')),
        ],
      ),
    );
  }

  Widget _emptyStateWithButton(IconData icon, String msg, String btnText, VoidCallback onPressed) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(msg,
              style: const TextStyle(color: Colors.grey, fontSize: 16, fontFamily: 'Cairo')),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.add),
            label: Text(btnText),
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kRedBg,
                elevation: 0,
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
        ],
      ),
    );
  }

  void _ajouterCredit() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCreditSheet(clientId: widget.client.id!, onSaved: _loadData),
    );
  }

  void _ajouterPaiement() {
    final open = _credits.where((c) => !c.estSolde).toList();
    if (open.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('ما كاين حتى كريدي مفتوح',
              style: TextStyle(fontFamily: 'Cairo'))));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPaiementSheet(credit: open.first, onSaved: _loadData),
    );
  }

  void _ajouterCheque() {
    final open = _credits.where((c) => !c.estSolde).toList();
    if (open.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('لا يمكن إضافة شيك بدون كريدي مفتوح',
              style: TextStyle(fontFamily: 'Cairo'))));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddChequeSheet(creditId: open.first.id!, onSaved: _loadData),
    );
  }
}