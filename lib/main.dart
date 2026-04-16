import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'services/database_helper.dart';

void main() {
  runApp(const KarnetApp());
}

// ==================== APP ====================
class KarnetApp extends StatelessWidget {
  const KarnetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Karnet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B8A6B),
          primary: const Color(0xFF1B8A6B),
        ),
        textTheme: GoogleFonts.cairoTextTheme(),
        useMaterial3: true,
      ),
      home: const ClientsScreen(),
    );
  }
}

// ==================== HELPER ====================
final _fmt = NumberFormat('#,##0.00', 'fr_MA');
String formatMontant(double m) => '${_fmt.format(m)} درهم';
String formatDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

// ==================== SCREEN CLIENTS ====================
class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  List<Client> _clients = [];
  Map<String, double> _stats = {};
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final clients = await DatabaseHelper.instance.getAllClients();
    for (var c in clients) {
      c.solde = await DatabaseHelper.instance.getSoldeClient(c.id!);
    }
    final stats = await DatabaseHelper.instance.getStatsGlobales();
    setState(() {
      _clients = clients;
      _stats = stats;
      _loading = false;
    });
  }

  List<Client> get _filtered => _clients
      .where((c) =>
          c.nom.toLowerCase().contains(_search.toLowerCase()) ||
          (c.telephone ?? '').contains(_search))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStatsCards(),
            _buildSearchBar(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B8A6B)))
                  : _filtered.isEmpty
                      ? _buildEmpty()
                      : _buildClientsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajouterClient,
        backgroundColor: const Color(0xFF1B8A6B),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('إضافة عميل', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1B8A6B),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Text(
            'كارنيه',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          const Spacer(),
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalCredit = _stats['totalCredit'] ?? 0;
    final totalRestant = _stats['totalRestant'] ?? 0;
    final totalPaye = _stats['totalPaye'] ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          _statCard('أخذت', totalCredit, const Color(0xFFE8F5E9), const Color(0xFF388E3C)),
          const SizedBox(width: 10),
          _statCard('الباقي', totalRestant, const Color(0xFFFFEBEE), const Color(0xFFD32F2F)),
          const SizedBox(width: 10),
          _statCard('أعطيت', totalPaye, const Color(0xFFE3F2FD), const Color(0xFF1976D2)),
        ],
      ),
    );
  }

  Widget _statCard(String label, double amount, Color bg, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: textColor, fontSize: 11, fontFamily: 'Cairo')),
            const SizedBox(height: 4),
            Text(
              '${_fmt.format(amount)}',
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text('درهم', style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 10, fontFamily: 'Cairo')),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Cairo'),
              decoration: InputDecoration(
                hintText: 'البحث...',
                hintStyle: const TextStyle(fontFamily: 'Cairo'),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1B8A6B)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.tune, color: Color(0xFF1B8A6B)),
          ),
        ],
      ),
    );
  }

  Widget _buildClientsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${_filtered.length} عميل',
            style: const TextStyle(color: Colors.grey, fontSize: 13, fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _clientCard(_filtered[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _clientCard(Client client) {
    return GestureDetector(
      onTap: () => _ouvrirClient(client),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatMontant(client.solde),
                  style: TextStyle(
                    color: client.solde > 0 ? const Color(0xFFD32F2F) : const Color(0xFF388E3C),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFamily: 'Cairo',
                  ),
                ),
                Text(
                  client.solde > 0 ? 'أخذت' : 'مسوى',
                  style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Cairo'),
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(client.nom, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Cairo')),
                if (client.telephone != null)
                  Text(client.telephone!, style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo')),
              ],
            ),
            const SizedBox(width: 12),
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1B8A6B).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                client.initiales,
                style: const TextStyle(
                  color: Color(0xFF1B8A6B),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('ما كاين حتى عميل', style: TextStyle(color: Colors.grey, fontSize: 16, fontFamily: 'Cairo')),
          const SizedBox(height: 8),
          const Text('ضغط على + باش تضيف عميل جديد', style: TextStyle(color: Colors.grey, fontSize: 13, fontFamily: 'Cairo')),
        ],
      ),
    );
  }

  void _ajouterClient() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddClientSheet(onSaved: _loadData),
    );
  }

  void _ouvrirClient(Client client) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClientDetailScreen(client: client)),
    ).then((_) => _loadData());
  }
}

// ==================== ADD CLIENT SHEET ====================
class AddClientSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const AddClientSheet({super.key, required this.onSaved});

  @override
  State<AddClientSheet> createState() => _AddClientSheetState();
}

class _AddClientSheetState extends State<AddClientSheet> {
  final _nomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _adrCtrl = TextEditingController();
  bool _saving = false;

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
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                const Text('عميل جديد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              ],
            ),
            const SizedBox(height: 16),
            _field(_nomCtrl, 'الاسم *', Icons.person_outline),
            const SizedBox(height: 12),
            _field(_telCtrl, 'رقم الهاتف', Icons.phone_outlined, type: TextInputType.phone),
            const SizedBox(height: 12),
            _field(_adrCtrl, 'العنوان', Icons.location_on_outlined),
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
                    : const Text('حفظ', style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Cairo')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      textAlign: TextAlign.right,
      style: const TextStyle(fontFamily: 'Cairo'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'Cairo'),
        prefixIcon: Icon(icon, color: const Color(0xFF1B8A6B)),
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Future<void> _save() async {
    if (_nomCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الاسم مطلوب', style: TextStyle(fontFamily: 'Cairo'))));
      return;
    }
    setState(() => _saving = true);
    await DatabaseHelper.instance.createClient(Client(
      nom: _nomCtrl.text.trim(),
      telephone: _telCtrl.text.trim().isEmpty ? null : _telCtrl.text.trim(),
      adresse: _adrCtrl.text.trim().isEmpty ? null : _adrCtrl.text.trim(),
      dateCreation: DateTime.now(),
    ));
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }
}

// ==================== CLIENT DETAIL SCREEN ====================
class ClientDetailScreen extends StatefulWidget {
  final Client client;
  const ClientDetailScreen({super.key, required this.client});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  List<Credit> _credits = [];
  double _solde = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final credits = await DatabaseHelper.instance.getCreditsClient(widget.client.id!);
    final solde = await DatabaseHelper.instance.getSoldeClient(widget.client.id!);
    setState(() {
      _credits = credits;
      _solde = solde;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B8A6B),
        title: Text(widget.client.nom, style: const TextStyle(color: Colors.white, fontFamily: 'Cairo')),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSoldeCard(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B8A6B)))
                : _credits.isEmpty
                    ? _buildEmpty()
                    : _buildCreditsList(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSoldeCard() {
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
          const Text('الرصيد', style: TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Cairo')),
          const SizedBox(height: 8),
          Text(
            formatMontant(_solde),
            style: TextStyle(
              color: _solde > 0 ? const Color(0xFFD32F2F) : const Color(0xFF388E3C),
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          if (widget.client.telephone != null) ...[
            const SizedBox(height: 8),
            Text(widget.client.telephone!, style: const TextStyle(color: Colors.grey, fontFamily: 'Cairo')),
          ],
        ],
      ),
    );
  }

  Widget _buildCreditsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('معاملات (${_credits.length})', style: const TextStyle(color: Colors.grey, fontSize: 13, fontFamily: 'Cairo')),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: _credits.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _creditCard(_credits[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _creditCard(Credit credit) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CreditDetailScreen(credit: credit, clientNom: widget.client.nom)),
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
                    color: credit.estSolde ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    credit.estSolde ? 'مسوى' : 'جاري',
                    style: TextStyle(
                      color: credit.estSolde ? const Color(0xFF388E3C) : const Color(0xFFD32F2F),
                      fontSize: 11,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                const Spacer(),
                Text(formatDate(credit.dateCredit), style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(formatMontant(credit.montantRestant), style: const TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Cairo')),
                  const Text('الباقي', style: TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Cairo')),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(formatMontant(credit.montantTotal), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Cairo')),
                  const Text('المجموع', style: TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Cairo')),
                ]),
              ],
            ),
            if (credit.description != null) ...[
              const SizedBox(height: 8),
              Text(credit.description!, style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo')),
            ],
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: credit.pourcentagePaye.clamp(0.0, 1.0),
                backgroundColor: const Color(0xFFFFEBEE),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1B8A6B)),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('ما كاين حتى معاملة', style: TextStyle(color: Colors.grey, fontSize: 16, fontFamily: 'Cairo')),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFEBEE),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _ajouterPaiement,
              icon: const Icon(Icons.arrow_upward, color: Color(0xFFD32F2F)),
              label: const Text('أعطيت', style: TextStyle(color: Color(0xFFD32F2F), fontFamily: 'Cairo', fontSize: 15)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B8A6B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _ajouterCredit,
              icon: const Icon(Icons.arrow_downward, color: Colors.white),
              label: const Text('أخذت', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 15)),
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
    if (_credits.where((c) => !c.estSolde).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ما كاين حتى كريدي مفتوح', style: TextStyle(fontFamily: 'Cairo'))));
      return;
    }
    final creditOuvert = _credits.firstWhere((c) => !c.estSolde);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPaiementSheet(credit: creditOuvert, onSaved: _loadData),
    );
  }
}

// ==================== ADD CREDIT SHEET ====================
class AddCreditSheet extends StatefulWidget {
  final int clientId;
  final VoidCallback onSaved;
  const AddCreditSheet({super.key, required this.clientId, required this.onSaved});

  @override
  State<AddCreditSheet> createState() => _AddCreditSheetState();
}

class _AddCreditSheetState extends State<AddCreditSheet> {
  final _montantCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                const Text('إضافة كريدي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _montantCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 18),
              decoration: InputDecoration(
                hintText: 'المبلغ (درهم)',
                hintStyle: const TextStyle(fontFamily: 'Cairo'),
                prefixText: 'درهم  ',
                prefixStyle: const TextStyle(color: Color(0xFF1B8A6B), fontFamily: 'Cairo'),
                filled: true,
                fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Cairo'),
              decoration: InputDecoration(
                hintText: 'الوصف (اختياري)',
                hintStyle: const TextStyle(fontFamily: 'Cairo'),
                filled: true,
                fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
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
                    : const Text('تسجيل الكريدي', style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Cairo')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final montant = double.tryParse(_montantCtrl.text.replaceAll(',', '.'));
    if (montant == null || montant <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('دخل مبلغ صحيح', style: TextStyle(fontFamily: 'Cairo'))));
      return;
    }
    setState(() => _saving = true);
    await DatabaseHelper.instance.createCredit(Credit(
      clientId: widget.clientId,
      montantTotal: montant,
      montantRestant: montant,
      dateCredit: DateTime.now(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
    ));
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }
}

// ==================== ADD PAIEMENT SHEET ====================
class AddPaiementSheet extends StatefulWidget {
  final Credit credit;
  final VoidCallback onSaved;
  const AddPaiementSheet({super.key, required this.credit, required this.onSaved});

  @override
  State<AddPaiementSheet> createState() => _AddPaiementSheetState();
}

class _AddPaiementSheetState extends State<AddPaiementSheet> {
  final _montantCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                const Text('تسجيل دفعة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              ],
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(12)),
              child: Text(
                'الباقي: ${formatMontant(widget.credit.montantRestant)}',
                textAlign: TextAlign.right,
                style: const TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
              ),
            ),
            TextField(
              controller: _montantCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 18),
              decoration: InputDecoration(
                hintText: 'المبلغ المدفوع',
                hintStyle: const TextStyle(fontFamily: 'Cairo'),
                prefixText: 'درهم  ',
                prefixStyle: const TextStyle(color: Color(0xFF388E3C), fontFamily: 'Cairo'),
                filled: true,
                fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Cairo'),
              decoration: InputDecoration(
                hintText: 'ملاحظة (اختياري)',
                hintStyle: const TextStyle(fontFamily: 'Cairo'),
                filled: true,
                fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                _montantCtrl.text = widget.credit.montantRestant.toString();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF1B8A6B)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('خلص الكل', style: TextStyle(color: Color(0xFF1B8A6B), fontFamily: 'Cairo')),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF388E3C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('تأكيد الدفعة', style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Cairo')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final montant = double.tryParse(_montantCtrl.text.replaceAll(',', '.'));
    if (montant == null || montant <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('دخل مبلغ صحيح', style: TextStyle(fontFamily: 'Cairo'))));
      return;
    }
    if (montant > widget.credit.montantRestant) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('المبلغ أكبر من الباقي', style: TextStyle(fontFamily: 'Cairo'))));
      return;
    }
    setState(() => _saving = true);
    await DatabaseHelper.instance.createPaiement(Paiement(
      creditId: widget.credit.id!,
      montant: montant,
      datePaiement: DateTime.now(),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    ));
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }
}

// ==================== CREDIT DETAIL SCREEN ====================
class CreditDetailScreen extends StatefulWidget {
  final Credit credit;
  final String clientNom;
  const CreditDetailScreen({super.key, required this.credit, required this.clientNom});

  @override
  State<CreditDetailScreen> createState() => _CreditDetailScreenState();
}

class _CreditDetailScreenState extends State<CreditDetailScreen> {
  List<Paiement> _paiements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final paiements = await DatabaseHelper.instance.getPaiementsCredit(widget.credit.id!);
    setState(() {
      _paiements = paiements;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B8A6B),
        title: Text(widget.clientNom, style: const TextStyle(color: Colors.white, fontFamily: 'Cairo')),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B8A6B)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildCreditInfo(),
                const SizedBox(height: 16),
                const Text('سجل الدفعات', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo')),
                const SizedBox(height: 8),
                if (_paiements.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('ما كاين حتى دفعة', style: TextStyle(color: Colors.grey, fontFamily: 'Cairo')),
                  ))
                else
                  ..._paiements.map((p) => _paiementCard(p)),
              ],
            ),
    );
  }

  Widget _buildCreditInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(formatMontant(widget.credit.montantRestant), style: const TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Cairo')),
                const Text('الباقي', style: TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo')),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(formatMontant(widget.credit.montantTotal), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Cairo')),
                const Text('المجموع', style: TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo')),
              ]),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: widget.credit.pourcentagePaye.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFFFEBEE),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1B8A6B)),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(widget.credit.pourcentagePaye * 100).toStringAsFixed(0)}% مدفوع',
            style: const TextStyle(color: Color(0xFF1B8A6B), fontFamily: 'Cairo'),
          ),
        ],
      ),
    );
  }

  Widget _paiementCard(Paiement p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const Icon(Icons.arrow_upward, color: Color(0xFF388E3C), size: 20),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(formatDate(p.datePaiement), style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo')),
            if (p.note != null) Text(p.note!, style: const TextStyle(fontSize: 12, fontFamily: 'Cairo')),
          ]),
          const Spacer(),
          Text(formatMontant(p.montant), style: const TextStyle(color: Color(0xFF388E3C), fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Cairo')),
        ],
      ),
    );
  }
}