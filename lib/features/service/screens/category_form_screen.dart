// lib/features/service/screens/category_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/service_category.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../services_provider.dart';

class CategoryFormScreen extends ConsumerStatefulWidget {
  final ServiceCategory? category; // Null = create mode

  const CategoryFormScreen({super.key, this.category});

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  
  bool _isActive = true;
  bool _isEditMode = false;
  String _selectedColor = '#FF6B9D';

  final List<Map<String, dynamic>> _colors = [
    {'name': 'Hồng', 'value': '#FF6B9D'},
    {'name': 'Xanh dương', 'value': '#3B82F6'},
    {'name': 'Xanh lá', 'value': '#10B981'},
    {'name': 'Vàng', 'value': '#F59E0B'},
    {'name': 'Đỏ', 'value': '#EF4444'},
    {'name': 'Tím', 'value': '#8B5CF6'},
    {'name': 'Cam', 'value': '#F97316'},
    {'name': 'Xám', 'value': '#6B7280'},
    {'name': 'Xanh cyan', 'value': '#06B6D4'},
    {'name': 'Hồng đậm', 'value': '#EC4899'},
  ];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.category != null;
    
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    
    if (_isEditMode) {
      _selectedColor = widget.category!.color;
      _isActive = widget.category!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final operationState = ref.watch(serviceOperationProvider);

    if (operationState.isSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(serviceOperationProvider.notifier).reset();
        if (context.mounted) context.pop();
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151520),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _isEditMode ? 'Sửa Danh mục' : 'Thêm Danh mục',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: operationState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (operationState.error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFEF4444)),
                        ),
                        child: Text(
                          operationState.error!,
                          style: const TextStyle(color: Color(0xFFEF4444)),
                        ),
                      ),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Tên danh mục',
                      hint: 'Ví dụ: Làm móng tay, Massage...',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tên danh mục';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Chọn màu sắc',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildColorGrid(),
                    if (_isEditMode) ...[
                      const SizedBox(height: 24),
                      SwitchListTile(
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                        title: const Text(
                          'Đang hoạt động',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        activeColor: const Color(0xFF10B981),
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: operationState.isLoading ? null : _saveCategory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _isEditMode ? 'Cập nhật' : 'Thêm danh mục',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
            filled: true,
            fillColor: const Color(0xFF1A1A28),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildColorGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _colors.map((color) {
        final isSelected = _selectedColor == color['value'];
        final colorValue = Color(int.parse(color['value']!.replaceFirst('#', '0xFF')));
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = color['value']!),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: colorValue,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }

  void _saveCategory() {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    final salonId = user?.salonId ?? 1;

    if (_isEditMode) {
      ref.read(serviceOperationProvider.notifier).updateCategory(
        id: widget.category!.id,
        name: _nameController.text,
        color: _selectedColor,
        isActive: _isActive,
        salonId: salonId,
      );
    } else {
      ref.read(serviceOperationProvider.notifier).createCategory(
        salonId: salonId,
        name: _nameController.text,
        color: _selectedColor,
      );
    }
  }
}
