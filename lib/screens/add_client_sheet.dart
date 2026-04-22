import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';

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
  final _nomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _adrCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _selectedType = 'CLIENT';
  int? _selectedCategoryId;
  List<Category> _categories = [];
  bool _loading = false;
  bool _isLoadingCategories = true;

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

  // جلب التصنيفات من قاعدة البيانات
  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    final cats =
        await DatabaseHelper.instance.getCategoriesByType(_selectedType);
    setState(() {
      _categories = cats;
      _isLoadingCategories = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // ← أضف هذا السطر في الأعلى
    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(
                24)), // ← هذا هو الصح        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // عنوان وزر الإغلاق
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                  Text(
                    _selectedType == 'CLIENT'
                        ? 'إضافة عميل جديد'
                        : 'إضافة مورد جديد',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // نوع الحساب (زبون/مورد)
              Row(
                children: [
                  Expanded(
                    child: _buildTypeButton('زبون', 'CLIENT'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeButton('مورد', 'SUPPLIER'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // حقل الاسم
              _buildTextField(
                controller: _nomCtrl,
                hint: 'الاسم *',
                icon: Icons.person_outline,
                isRequired: true,
              ),
              const SizedBox(height: 12),

              // حقل رقم الهاتف
              _buildTextField(
                controller: _telCtrl,
                hint: 'رقم الهاتف',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),

              // حقل الشركة
              _buildTextField(
                controller: _companyCtrl,
                hint: 'اسم الشركة (اختياري)',
                icon: Icons.business_outlined,
              ),
              const SizedBox(height: 12),

              // حقل العنوان
              _buildTextField(
                controller: _adrCtrl,
                hint: 'العنوان (اختياري)',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 12),

              // اختيار التصنيف
              _buildCategoryDropdown(),
              const SizedBox(height: 12),

              // حقل الملاحظات
              _buildTextField(
                controller: _notesCtrl,
                hint: 'ملاحظات (اختياري)',
                icon: Icons.note_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // زر الحفظ
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B8A6B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'حفظ',
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

  // زر اختيار نوع الحساب
  Widget _buildTypeButton(String label, String type) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () async {
        setState(() {
          _selectedType = type;
        });
        await _loadCategories();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B8A6B) : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B8A6B) : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      ),
    );
  }

  // حقل إدخال نصي
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textAlign: TextAlign.right,
      maxLines: maxLines,
      style: const TextStyle(fontFamily: 'Cairo'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'Cairo'),
        prefixIcon: Icon(icon, color: const Color(0xFF1B8A6B)),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2C2C2C)
            : const Color(0xFFF5F6FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // قائمة التصنيفات المنسدلة
  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.label_outline, color: Color(0xFF1B8A6B)),
          const SizedBox(width: 8),
          Expanded(
            child: _isLoadingCategories
                ? const SizedBox(
                    height: 50,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      hint: const Text(
                        'اختر التصنيف',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                      value: _selectedCategoryId,
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text(
                            'بدون تصنيف',
                            textAlign: TextAlign.right,
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                        ),
                        ..._categories.map((cat) {
                          return DropdownMenuItem<int>(
                            value: cat.id,
                            child: Text(
                              cat.name,
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // حفظ البيانات
  Future<void> _save() async {
    // التحقق من صحة البيانات
    if (_nomCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'الاسم مطلوب',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // إنشاء عميل/مورد جديد
      await DatabaseHelper.instance.createClient(
        Client(
          nom: _nomCtrl.text.trim(),
          telephone: _telCtrl.text.trim().isEmpty ? null : _telCtrl.text.trim(),
          adresse: _adrCtrl.text.trim().isEmpty ? null : _adrCtrl.text.trim(),
          company: _companyCtrl.text.trim().isEmpty
              ? null
              : _companyCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          type: _selectedType,
          categoryId: _selectedCategoryId,
          dateCreation: DateTime.now(),
        ),
      );

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ: $e',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
