// lib/features/staff/screens/staff_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/staff.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../staff_provider.dart';

class StaffFormScreen extends ConsumerStatefulWidget {
  final Staff? staff; // Null = create mode, Not null = edit mode

  const StaffFormScreen({super.key, this.staff});

  @override
  ConsumerState<StaffFormScreen> createState() => _StaffFormScreenState();
}

class _StaffFormScreenState extends ConsumerState<StaffFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _commissionController;
  
  String _selectedRole = 'junior';
  String? _selectedColor;
  bool _isActive = true;
  bool _isEditMode = false;

  final List<String> _roles = ['junior', 'senior', 'manager'];
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
    _isEditMode = widget.staff != null;
    
    _nameController = TextEditingController(text: widget.staff?.name ?? '');
    _phoneController = TextEditingController(text: widget.staff?.phone ?? '');
    _commissionController = TextEditingController(
      text: widget.staff?.commissionRate.toString() ?? '0',
    );
    
    if (_isEditMode) {
      _selectedRole = widget.staff!.role;
      _selectedColor = widget.staff!.color;
      _isActive = widget.staff!.isActive;
    } else {
      _selectedColor = _colors[0]['value'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final operationState = ref.watch(staffOperationProvider);
    final user = ref.watch(currentUserProvider);

    // Handle success
    if (operationState.isSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(staffOperationProvider.notifier).reset();
        if (context.mounted) {
          context.pop();
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151520),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _isEditMode ? 'Sửa Nhân viên' : 'Thêm Nhân viên',
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
                    _buildSectionTitle('Thông tin cơ bản'),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Họ tên',
                      hint: 'Nhập họ tên nhân viên',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập họ tên';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Số điện thoại',
                      hint: 'Nhập số điện thoại',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập số điện thoại';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Vai trò & Hoa hồng'),
                    _buildDropdown(
                      label: 'Vai trò',
                      value: _selectedRole,
                      items: _roles.map((role) {
                        final labels = {
                          'junior': 'Nhân viên',
                          'senior': 'Nhân viên chính',
                          'manager': 'Quản lý',
                        };
                        return DropdownMenuItem(
                          value: role,
                          child: Text(labels[role] ?? role),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedRole = value!);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _commissionController,
                      label: 'Tỷ lệ hoa hồng (%)',
                      hint: 'Nhập tỷ lệ hoa hồng',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tỷ lệ hoa hồng';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Màu sắc hiển thị'),
                    _buildColorSelector(),
                    if (_isEditMode) ...[
                      const SizedBox(height: 24),
                      _buildSectionTitle('Trạng thái'),
                      SwitchListTile(
                        value: _isActive,
                        onChanged: (value) {
                          setState(() => _isActive = value);
                        },
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
                        onPressed: operationState.isLoading
                            ? null
                            : () => _saveStaff(user?.salonId ?? 1),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _isEditMode ? 'Cập nhật' : 'Thêm nhân viên',
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
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
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
            child: DropdownButton<String>(
              value: value,
              items: items,
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

  void _saveStaff(int salonId) {
    if (!_formKey.currentState!.validate()) return;

    final commission = double.tryParse(_commissionController.text) ?? 0;

    if (_isEditMode) {
      ref.read(staffOperationProvider.notifier).updateStaff(
        id: widget.staff!.id,
        name: _nameController.text,
        phone: _phoneController.text,
        role: _selectedRole,
        commissionRate: commission,
        color: _selectedColor,
        isActive: _isActive,
        salonId: salonId,
      );
    } else {
      ref.read(staffOperationProvider.notifier).createStaff(
        salonId: salonId,
        name: _nameController.text,
        phone: _phoneController.text,
        role: _selectedRole,
        commissionRate: commission,
        color: _selectedColor,
      );
    }
  }
}
