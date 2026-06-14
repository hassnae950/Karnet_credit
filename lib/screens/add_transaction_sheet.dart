import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../database_helper.dart';
import '../models.dart';
import '../utils/helpers.dart';
import '../utils/app_translations.dart';

class AddTransactionSheet extends StatefulWidget {
  final List<Client> clients;
  final VoidCallback onSaved;
  
  const AddTransactionSheet({
    super.key,
    required this.clients,
    required this.onSaved,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  Client? _selectedClient;
  String _transactionType = 'CREDIT'; // 'CREDIT' or 'PAYMENT'
  String _amount = '0';
  String _displayAmount = '0';
  String _note = '';
  String? _imagePath;
  bool _isLoading = false;
  bool _isCheque = false;
  String _chequeNumber = '';
  DateTime? _chequeDate;

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

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.camera);
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                  Text(
                    Tr.s('add_transaction'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              DropdownButtonFormField<Client>(
                initialValue: _selectedClient,
                decoration: InputDecoration(
                  labelText: Tr.s('select_client'),
                  border: const OutlineInputBorder(),
                  labelStyle: const TextStyle(fontFamily: 'Cairo'),
                ),
                items: widget.clients.map((client) {
                  return DropdownMenuItem(
                    value: client,
                    child: Text(client.nom, style: const TextStyle(fontFamily: 'Cairo')),
                  );
                }).toList(),
                onChanged: (client) {
                  setState(() => _selectedClient = client);
                },
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildTypeButton(Tr.s('took_label'), 'CREDIT', 
                        const Color(0xFFD32F2F), const Color(0xFFFFEBEE)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeButton(Tr.s('gave_label'), 'PAYMENT',
                        const Color(0xFF388E3C), const Color(0xFFE8F5E9)),
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
                          Text(
                            Tr.s('currency'),
                            style: TextStyle(
                              color: _transactionType == 'CREDIT' 
                                  ? const Color(0xFFD32F2F)
                                  : const Color(0xFF388E3C),
                            ),
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
              
              CheckboxListTile(
                title: Text(Tr.s('cheque_transaction'), style: const TextStyle(fontFamily: 'Cairo')),
                value: _isCheque,
                onChanged: (val) {
                  setState(() => _isCheque = val ?? false);
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              
              if (_isCheque) ...[
                const SizedBox(height: 8),
                TextField(
                  onChanged: (val) => _chequeNumber = val,
                  decoration: InputDecoration(
                    labelText: Tr.s('cheque_number'),
                    border: const OutlineInputBorder(),
                    labelStyle: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: Text(Tr.s('due_date'), style: const TextStyle(fontFamily: 'Cairo')),
                  subtitle: _chequeDate != null
                      ? Text(formatDate(_chequeDate!), style: const TextStyle(fontFamily: 'Cairo'))
                      : Text(Tr.s('select_date'), style: const TextStyle(fontFamily: 'Cairo')),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _chequeDate = date);
                    }
                  },
                ),
              ],
              
              const SizedBox(height: 12),
              
              TextField(
                onChanged: (val) => _note = val,
                maxLines: 2,
                textAlign: Tr.isRtl ? TextAlign.right : TextAlign.left,
                style: const TextStyle(fontFamily: 'Cairo'),
                decoration: InputDecoration(
                  labelText: Tr.s('note'),
                  hintText: Tr.s('note_optional'),
                  border: const OutlineInputBorder(),
                  labelStyle: const TextStyle(fontFamily: 'Cairo'),
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: Text(Tr.s('gallery'), style: const TextStyle(fontFamily: 'Cairo')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(Tr.s('camera'), style: const TextStyle(fontFamily: 'Cairo')),
                    ),
                  ),
                ],
              ),
              _buildThumbnail(),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _transactionType == 'CREDIT'
                        ? const Color(0xFFD32F2F)
                        : const Color(0xFF388E3C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isLoading ? null : () => _save(montant),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _transactionType == 'CREDIT' ? Tr.s('register_credit') : Tr.s('register_payment'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Cairo',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String label, String type, Color color, Color bgColor) {
    final isSelected = _transactionType == type;
    return GestureDetector(
      onTap: () => setState(() => _transactionType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'Cairo',
            ),
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
    if (_selectedClient == null) {
      _showError(Tr.s('select_client_error'));
      return;
    }
    
    if (montant <= 0) {
      _showError(Tr.s('enter_valid_amount'));
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      if (_transactionType == 'CREDIT') {
        await DatabaseHelper.instance.createCredit(Credit(
          clientId: _selectedClient!.id!,
          montantTotal: montant,
          montantRestant: montant,
          dateCredit: DateTime.now(),
          description: _note.isEmpty ? null : _note,
          imagePath: _imagePath,
        ));
        
        if (_isCheque && _chequeNumber.isNotEmpty) {
          final credits = await DatabaseHelper.instance.getCreditsClient(_selectedClient!.id!);
          final lastCredit = credits.first;
          await DatabaseHelper.instance.createCheque(Cheque(
            creditId: lastCredit.id!,
            numero: _chequeNumber,
            montant: montant,
            dateEcheance: _chequeDate ?? DateTime.now(),
            dateCreation: DateTime.now(),
          ));
        }
      } else {
        final credits = await DatabaseHelper.instance.getCreditsClient(_selectedClient!.id!);
        final openCredits = credits.where((c) => !c.estSolde).toList();
        
        if (openCredits.isEmpty) {
          _showError(Tr.s('no_open_credit'));
          setState(() => _isLoading = false);
          return;
        }
        
        await DatabaseHelper.instance.createPaiement(Paiement(
          creditId: openCredits.first.id!,
          montant: montant,
          datePaiement: DateTime.now(),
          note: _note.isEmpty ? null : _note,
          imagePath: _imagePath,
        ));
      }
      
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('${Tr.s('error_prefix')} $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red),
    );
  }
}