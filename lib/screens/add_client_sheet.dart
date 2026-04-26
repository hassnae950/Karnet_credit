import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';
import '../utils/app_translations.dart';

const _kPrimary = Color(0xFF1B8A6B);

class AddClientSheet extends StatefulWidget {
  final VoidCallback onSaved;
  final String defaultType; // 'CLIENT' or 'SUPPLIER'

  const AddClientSheet({
    super.key,
    required this.onSaved,
    this.defaultType = 'CLIENT',
  });

  @override
  State<AddClientSheet> createState() => _AddClientSheetState();
}

class _AddClientSheetState extends State<AddClientSheet> {
  final _nomCtrl     = TextEditingController();
  final _telCtrl     = TextEditingController();
  final _adrCtrl     = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _notesCtrl   = TextEditingController();

  String _selectedType       = 'CLIENT';
  int?   _selectedCategoryId;
  List<Category> _categories = [];
  bool   _loading            = false;
  bool   _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.defaultType;
    _loadCategories();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _telCtrl.dispose();
    _adrCtrl.dispose();
    _companyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    final cats = await DatabaseHelper.instance
        .getCategoriesByType(_selectedType);
    setState(() {
      _categories = cats;
      _isLoadingCategories = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ── Header ───────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                  Text(
                    _selectedType == 'CLIENT'
                        ? Tr.s('add_new_client')
                        : Tr.s('add_new_supplier'),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Type toggle ──────────────────────────────────────────────
              Row(children: [
                Expanded(child: _buildTypeButton(Tr.s('client'),   'CLIENT')),
                const SizedBox(width: 12),
                Expanded(child: _buildTypeButton(Tr.s('supplier'), 'SUPPLIER')),
              ]),
              const SizedBox(height: 16),

              // ── Name ─────────────────────────────────────────────────────
              _buildTextField(
                controller:   _nomCtrl,
                hint:         Tr.s('name'),
                icon:         Icons.person_outline,
                isRequired:   true,
              ),
              const SizedBox(height: 12),

              // ── Phone ─────────────────────────────────────────────────────
              _buildTextField(
                controller:   _telCtrl,
                hint:         Tr.s('phone'),
                icon:         Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),

              // ── Company ───────────────────────────────────────────────────
              _buildTextField(
                controller: _companyCtrl,
                hint:       Tr.s('company'),
                icon:       Icons.business_outlined,
              ),
              const SizedBox(height: 12),

              // ── Address ───────────────────────────────────────────────────
              _buildTextField(
                controller: _adrCtrl,
                hint:       Tr.s('address'),
                icon:       Icons.location_on_outlined,
              ),
              const SizedBox(height: 12),

              // ── Category dropdown ─────────────────────────────────────────
              _buildCategoryDropdown(isDark),
              const SizedBox(height: 12),

              // ── Notes ─────────────────────────────────────────────────────
              _buildTextField(
                controller: _notesCtrl,
                hint:       Tr.s('notes_optional'),
                icon:       Icons.note_outlined,
                maxLines:   2,
              ),
              const SizedBox(height: 24),

              // ── Save button ───────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const CircularProgressIndicator(
                          color: Colors.white)
                      : Text(
                          Tr.s('save'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'Cairo'),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Type toggle button ────────────────────────────────────────────────────────
  Widget _buildTypeButton(String label, String type) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () async {
        setState(() => _selectedType = type);
        await _loadCategories();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimary : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? _kPrimary : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Colors.grey.shade700,
              fontWeight: isSelected
                  ? FontWeight.bold
                  : FontWeight.normal,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      ),
    );
  }

  // ── Text field helper ─────────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines  = 1,
    bool isRequired = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller:   controller,
      keyboardType: keyboardType,
      textAlign:    Tr.textAlignStart,
      maxLines:     maxLines,
      style: const TextStyle(fontFamily: 'Cairo'),
      decoration: InputDecoration(
        hintText:  hint,
        hintStyle: const TextStyle(fontFamily: 'Cairo'),
        prefixIcon: Icon(icon, color: _kPrimary),
        filled:    true,
        fillColor: isDark
            ? const Color(0xFF2C2C2C)
            : const Color(0xFFF5F6FA),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }

  // ── Category dropdown ─────────────────────────────────────────────────────────
  Widget _buildCategoryDropdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2C2C2C)
            : const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Icon(Icons.label_outline, color: _kPrimary),
        const SizedBox(width: 8),
        Expanded(
          child: _isLoadingCategories
              ? const SizedBox(
                  height: 50,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    hint: Text(
                      Tr.s('choose_category'),
                      textAlign: Tr.textAlignStart,
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                    value: _selectedCategoryId,
                    items: [
                      DropdownMenuItem<int>(
                        value: null,
                        child: Text(
                          Tr.s('no_category'),
                          textAlign: Tr.textAlignStart,
                          style:
                              const TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                      ..._categories.map((cat) {
                        return DropdownMenuItem<int>(
                          value: cat.id,
                          child: Text(
                            cat.name,
                            textAlign: Tr.textAlignStart,
                            style: const TextStyle(
                                fontFamily: 'Cairo'),
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedCategoryId = value),
                  ),
                ),
        ),
      ]),
    );
  }

  // ── Save ──────────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (_nomCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(Tr.s('name_required'),
              style: const TextStyle(fontFamily: 'Cairo'))));
      return;
    }
    setState(() => _loading = true);
    try {
      await DatabaseHelper.instance.createClient(Client(
        nom:       _nomCtrl.text.trim(),
        telephone: _telCtrl.text.trim().isEmpty
            ? null
            : _telCtrl.text.trim(),
        adresse:   _adrCtrl.text.trim().isEmpty
            ? null
            : _adrCtrl.text.trim(),
        company:   _companyCtrl.text.trim().isEmpty
            ? null
            : _companyCtrl.text.trim(),
        notes:     _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
        type:          _selectedType,
        categoryId:    _selectedCategoryId,
        dateCreation:  DateTime.now(),
      ));
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${Tr.s('error_prefix')} $e',
              style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}