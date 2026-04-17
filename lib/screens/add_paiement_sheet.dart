import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../database_helper.dart';
import '../models.dart';
import '../utils/helpers.dart';

class AddPaiementSheet extends StatefulWidget {
  final Credit credit;
  final VoidCallback onSaved;
  const AddPaiementSheet({super.key, required this.credit, required this.onSaved});

  @override
  State<AddPaiementSheet> createState() => _AddPaiementSheetState();
}

class _AddPaiementSheetState extends State<AddPaiementSheet> {
  final TextEditingController _noteCtrl = TextEditingController();
  String _amount = '0';
  String _displayAmount = '0';
  String? _imagePath;
  bool _saving = false;

  void _addNumber(String num) {
    setState(() {
      if (_amount == '0') {
        _amount = num;
      } else {
        _amount = _amount + num;
      }
      _displayAmount = _amount;
    });
  }

  void _clear() {
    setState(() {
      _amount = '0';
      _displayAmount = '0';
    });
  }

  void _delete() {
    setState(() {
      if (_amount.length > 1) {
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = '0';
      }
      _displayAmount = _amount;
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imagePath = picked.path);
    }
  }

  void _setFullAmount() {
    setState(() {
      _amount = widget.credit.montantRestant.toString();
      _displayAmount = _amount;
    });
  }

  Widget _buildThumbnail() {
    if (_imagePath == null) return const SizedBox.shrink();
    
    return GestureDetector(
      onTap: () => _showFullImage(),
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF388E3C), width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(_imagePath!),
            height: 80,
            width: 80,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  void _showFullImage() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: InteractiveViewer(
            panEnabled: true,
            scaleEnabled: true,
            child: Image.file(
              File(_imagePath!),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double montant = double.tryParse(_amount) ?? 0;
    
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
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
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                  const Text(
                    'تسجيل دفعة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  ),
                ],
              ),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 16, bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'المبلغ المتبقي: ${formatMontant(widget.credit.montantRestant)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFFD32F2F),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'درهم',
                            style: TextStyle(color: Color(0xFF388E3C)),
                          ),
                          Text(
                            _displayAmount,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCalculatorRow(['7', '8', '9']),
                    _buildCalculatorRow(['4', '5', '6']),
                    _buildCalculatorRow(['1', '2', '3']),
                    _buildCalculatorRow(['00', '0', 'C']),
                    Row(
                      children: [
                        _buildCalcButton('⌫', onTap: _delete),
                        const SizedBox(width: 8),
                        _buildCalcButton('.', onTap: () => _addNumber('.')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              TextField(
                controller: _noteCtrl,
                textAlign: TextAlign.right,
                maxLines: 2,
                style: const TextStyle(fontFamily: 'Cairo'),
                decoration: InputDecoration(
                  hintText: 'ملاحظة (اختياري)',
                  hintStyle: const TextStyle(fontFamily: 'Cairo'),
                  filled: true,
                  fillColor: const Color(0xFFF5F6FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('إضافة صورة', style: TextStyle(fontFamily: 'Cairo')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF388E3C),
                  side: const BorderSide(color: Color(0xFF388E3C)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              
              _buildThumbnail(),
              const SizedBox(height: 8),
              
              GestureDetector(
                onTap: _setFullAmount,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF1B8A6B)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'خلص الكل',
                    style: TextStyle(color: Color(0xFF1B8A6B), fontFamily: 'Cairo'),
                  ),
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
                  onPressed: _saving ? null : () => _save(montant),
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'تأكيد الدفعة',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Cairo'),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculatorRow(List<String> buttons) {
    return Row(
      children: buttons.map((btn) => _buildCalcButton(btn, onTap: () {
        if (btn == 'C') {
          _clear();
        } else {
          _addNumber(btn);
        }
      })).toList(),
    );
  }

  Widget _buildCalcButton(String text, {VoidCallback? onTap}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save(double montant) async {
    if (montant <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('دخل مبلغ صحيح', style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }
    if (montant > widget.credit.montantRestant) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المبلغ أكبر من الباقي', style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }
    
    setState(() => _saving = true);
    
    try {
      await DatabaseHelper.instance.createPaiement(
        Paiement(
          creditId: widget.credit.id!,
          montant: montant,
          datePaiement: DateTime.now(),
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          imagePath: _imagePath,
        ),
      );
      
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}