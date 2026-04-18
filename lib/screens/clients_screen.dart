import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';
import '../utils/helpers.dart';
import 'client_detail_screen.dart';  // هذا السطر مهم جداً
import 'add_client_sheet.dart';

class ClientsScreen extends StatefulWidget {
  final String type;
  const ClientsScreen({super.key, required this.type});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  List<Client> _clients = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final clients = await DatabaseHelper.instance.getClientsByType(widget.type);
    for (var c in clients) {
      c.solde = await DatabaseHelper.instance.getSoldeClient(c.id!);
    }
    setState(() {
      _clients = clients;
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
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
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B8A6B)))
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _clientCard(_filtered[i]),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _ajouterClient(),
        backgroundColor: const Color(0xFF1B8A6B),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: Text(
          widget.type == 'CLIENT' ? 'إضافة عميل' : 'إضافة مورد',
          style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
        ),
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
              offset: const Offset(0, 2),
            )
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
                  _getSoldeText(client.solde),
                  style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Cairo'),
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  client.nom,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Cairo'),
                ),
                if (client.telephone != null)
                  Text(
                    client.telephone!,
                    style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo'),
                  ),
                if (client.company != null)
                  Text(
                    client.company!,
                    style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Cairo'),
                  ),
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

  String _getSoldeText(double solde) {
    if (widget.type == 'CLIENT') {
      return solde > 0 ? 'عليه لك' : 'مسوى';
    } else {
      return solde > 0 ? 'لك عليه' : 'مسوى';
    }
  }

  Widget _buildEmpty() {
    final title = widget.type == 'CLIENT' ? 'عملاء' : 'موردين';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.type == 'CLIENT' ? Icons.people_outline : Icons.local_shipping_outlined,
            size: 72,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'ما كاين حتى $title',
            style: const TextStyle(color: Colors.grey, fontSize: 16, fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 8),
          Text(
            'ضغط على + باش تضيف ${widget.type == 'CLIENT' ? 'عميل' : 'مورد'} جديد',
            style: const TextStyle(color: Colors.grey, fontSize: 13, fontFamily: 'Cairo'),
          ),
        ],
      ),
    );
  }

  void _ajouterClient() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddClientSheet(
        onSaved: _loadData,
        defaultType: widget.type,
      ),
    );
  }

  void _ouvrirClient(Client client) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClientDetailScreen(client: client)),
    ).then((_) => _loadData());
  }
}