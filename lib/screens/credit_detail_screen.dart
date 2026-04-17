import 'dart:io';
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
          // إضافة الوصف إذا كان موجوداً
          if (widget.credit.description != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.credit.description!,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Cairo',
                  color: Colors.black87,
                ),
              ),
            ),
          ],
          // إضافة صورة الكريدي إذا كانت موجودة
          _buildImageThumbnail(widget.credit.imagePath),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
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
          // عرض الصورة المصغرة للدفعة إذا كانت موجودة
          _buildImageThumbnail(p.imagePath),
        ],
      ),
    );
  }

  // دالة لعرض الصورة المصغرة
  Widget _buildImageThumbnail(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return const SizedBox.shrink();
    
    return GestureDetector(
      onTap: () => _showFullImage(imagePath),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF1B8A6B), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Image.file(
            File(imagePath),
            height: 60,
            width: 60,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  // دالة لعرض الصورة بحجم كامل مع خاصية التكبير والتصغير
  void _showFullImage(String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: Stack(
            children: [
              InteractiveViewer(
                panEnabled: true,
                scaleEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                  ),
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
            ],
          ),
        ),
      ),
    );
  }
}