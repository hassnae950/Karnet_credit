import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';
import '../utils/helpers.dart';
import 'client_detail_screen.dart';
import 'add_client_sheet.dart';

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
        label: const Text('إضافة عميل',
            style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
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
            width: 42,
            height: 42,
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
            width: 38,
            height: 38,
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
            Text(label,
                style: TextStyle(color: textColor, fontSize: 11, fontFamily: 'Cairo')),
            const SizedBox(height: 4),
            Text(
              formatMontant(amount),
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text('درهم',
                style: TextStyle(
                    color: textColor.withOpacity(0.7), fontSize: 10, fontFamily: 'Cairo')),
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
            width: 46,
            height: 46,
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
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
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
                Text(client.nom,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Cairo')),
                if (client.telephone != null)
                  Text(client.telephone!,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12, fontFamily: 'Cairo')),
              ],
            ),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
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
          const Text('ما كاين حتى عميل',
              style: TextStyle(color: Colors.grey, fontSize: 16, fontFamily: 'Cairo')),
          const SizedBox(height: 8),
          const Text('ضغط على + باش تضيف عميل جديد',
              style: TextStyle(color: Colors.grey, fontSize: 13, fontFamily: 'Cairo')),
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