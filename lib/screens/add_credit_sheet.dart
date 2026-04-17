import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../database_helper.dart';
import '../models.dart';

class AddCreditSheet extends StatefulWidget {
  final int clientId;
  final VoidCallback onSaved;
  const AddCreditSheet({super.key, required this.clientId, required this.onSaved});

  @override
  State<AddCreditSheet> createState() => _AddCreditSheetState();
}

class _AddCreditSheetState extends State<AddCreditSheet> {
  final TextEditingController _descCtrl = TextEditingController();
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

  Widget _buildThumbnail() {
    if (_imagePath == null) return const SizedBox.shrink();
    
    return GestureDetector(
      onTap: () => _showFullImage(),
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1B8A6B), width: 2),
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
                    'إضافة كريدي',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
                            style: TextStyle(color: Color(0xFF1B8A6B)),
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
              const SizedBox(height: 16),
              TextField(
                controller: _descCtrl,
                textAlign: TextAlign.right,
                maxLines: 3,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'الوصف (اختياري)\nمثال: فاتورة شهر يناير',
                  hintStyle: const TextStyle(fontFamily: 'Cairo'),
                  hintMaxLines: 2,
                  filled: true,
                  fillColor: const Color(0xFFF5F6FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('إضافة صورة', style: TextStyle(fontFamily: 'Cairo')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1B8A6B),
                  side: const BorderSide(color: Color(0xFF1B8A6B)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              _buildThumbnail(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B8A6B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _saving ? null : () => _save(montant),
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'تسجيل الكريدي',
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
    
    setState(() => _saving = true);
    
    try {
      await DatabaseHelper.instance.createCredit(
        Credit(
          clientId: widget.clientId,
          montantTotal: montant,
          montantRestant: montant,
          dateCredit: DateTime.now(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
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