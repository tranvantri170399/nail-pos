// lib/features/service/screens/service_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/service.dart';
import '../../../core/models/service_category.dart';
import '../../../core/providers/app_data_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../services_provider.dart';

class ServiceFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? extra; // Contains 'service' and 'category' for edit mode

  const ServiceFormScreen({super.key, this.extra});

  @override
  ConsumerState<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends ConsumerState<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _durationController;
  
  int? _selectedCategoryId;
  String? _selectedColor;
  bool _isActive = true;
  bool _isEditMode = false;
  Service? _editingService;

  final List<Map<String, dynamic>> _colors = [
    {'name': 'Xanh dương', 'value': '#3B82F6'},
    {'name': 'Xanh lá', 'value': '#10B981'},
    {'name': 'Vàng', 'value': '#F59E0B'},
    {'name': 'Đỏ', 'value': '#EF4444'},
    {'name': 'Tím', 'value': '#8B5CF6'},
    {'name': 'Hồng', 'value': '#FF6B9D'},
    {'name': 'Cam', 'value': '#F97316'},
    {'name': 'Xám', 'value': '#6B7280'},
  ];

  @override
  void initState() {
    super.initState();
    
    _isEditMode = widget.extra != null && widget.extra!['service'] != null;
    
    if (_isEditMode) {
      _editingService = widget.extra!['service'] as Service;
      final category = widget.extra!['category'] as ServiceCategory?;
      
      _nameController = TextEditingController(text: _editingService!.name);
      _priceController = TextEditingController(text: _editingService!.price.toStringAsFixed(0));
      _durationController = TextEditingController(text: _editingService!.durationMinutes.toString());
      _selectedCategoryId = category?.id;
      _selectedColor = _editingService!.color;
      _isActive = _editingService!.isActive;
    } else {
      _nameController = TextEditingController();
      _priceController = TextEditingController();
      _durationController = TextEditingController(text: '30');
      _selectedColor = _colors[0]['value'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final operationState = ref.watch(serviceOperationProvider);
    final categories = ref.watch(categoriesProvider);

    if (operationState.isSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(serviceOperationProvider.notifier).reset();
        if (context.mounted) context.pop();
      });
    }

    // Set default category if not set and categories available
    if (!_isEditMode && _selectedCategoryId == null && categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151520),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _isEditMode ? 'Sửa Dịch vụ' : 'Thêm Dịch vụ',
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
                    _buildSectionTitle('Thông tin dịch vụ'),
                    _buildDropdown(
                      label: 'Danh mục',
                      value: _selectedCategoryId,
                      items: categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedCategoryId = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Tên dịch vụ',
                      hint: 'Ví dụ: Sơn gel, Massage chân...',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tên dịch vụ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _priceController,
                            label: 'Giá (VNĐ)',
                            hint: '100000',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập giá';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _durationController,
                            label: 'Thời gian (phút)',
                            hint: '30',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập thời gian';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Màu sắc hiển thị'),
                    _buildColorSelector(),
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
                        onPressed: operationState.isLoading ? null : _saveService,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _isEditMode ? 'Cập nhật' : 'Thêm dịch vụ',
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
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
          keyboardType: keyboardType,
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

  Widget _buildDropdown({
    required String label,
    required int? value,
    required List<DropdownMenuItem<int>> items,
    required ValueChanged<int?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A28),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              items: items.isEmpty
                  ? [DropdownMenuItem(value: 0, child: Text('Chưa có danh mục', style: TextStyle(color: Colors.grey[600])))]
                  : items,
              onChanged: onChanged,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A1A28),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _colors.map((color) {
        final isSelected = _selectedColor == color['value'];
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = color['value']),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Color(int.parse(color['value']!.replaceFirst('#', '0xFF'))).withOpacity(0.2)
                  : const Color(0xFF1A1A28),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? Color(int.parse(color['value']!.replaceFirst('#', '0xFF')))
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Color(int.parse(color['value']!.replaceFirst('#', '0xFF'))),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  color['name']!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _saveService() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn danh mục')),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    final salonId = user?.salonId ?? 1;
    final price = double.tryParse(_priceController.text) ?? 0;
    final duration = int.tryParse(_durationController.text) ?? 30;

    if (_isEditMode) {
      ref.read(serviceOperationProvider.notifier).updateService(
        id: _editingService!.id,
        name: _nameController.text,
        price: price,
        durationMinutes: duration,
        color: _selectedColor,
        isActive: _isActive,
        salonId: salonId,
      );
    } else {
      ref.read(serviceOperationProvider.notifier).createService(
        salonId: salonId,
        categoryId: _selectedCategoryId!,
        name: _nameController.text,
        price: price,
        durationMinutes: duration,
        color: _selectedColor,
      );
    }
  }
}
