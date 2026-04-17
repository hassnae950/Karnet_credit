import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';
import '../utils/helpers.dart';

class CreditDetailScreen extends StatefulWidget {
  final Credit credit;
  final String clientNom;
  const CreditDetailScreen({
    super.key,
    required this.credit,
    required this.clientNom,
  });

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
        title: Text(
          widget.clientNom,
          style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B8A6B)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildCreditInfo(),
                const SizedBox(height: 16),
                const Text(
                  'سجل الدفعات',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 8),
                if (_paiements.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'ما كاين حتى دفعة',
                        style: TextStyle(color: Colors.grey, fontFamily: 'Cairo'),
                      ),
                    ),
                  )
                else
                  ..._paiements.map((p) => _paiementCard(p)),
              ],
            ),
    );
  }

  Widget _buildCreditInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatMontant(widget.credit.montantRestant),
                    style: const TextStyle(
                      color: Color(0xFFD32F2F),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const Text(
                    'الباقي',
                    style: TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo'),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatMontant(widget.credit.montantTotal),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const Text(
                    'المجموع',
                    style: TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo'),
                  ),
                ],
              ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.arrow_upward, color: Color(0xFF388E3C), size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatDate(p.datePaiement),
                style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo'),
              ),
              if (p.note != null)
                Text(
                  p.note!,
                  style: const TextStyle(fontSize: 12, fontFamily: 'Cairo'),
                ),
            ],
          ),
          const Spacer(),
          Text(
            formatMontant(p.montant),
            style: const TextStyle(
              color: Color(0xFF388E3C),
              fontWeight: FontWeight.bold,
              fontSize: 15,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}