// lib/features/staff/screens/staff_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/staff.dart';
import '../../../core/providers/app_data_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/pos/widgets/app_drawer.dart';
import '../staff_provider.dart';

class StaffListScreen extends ConsumerWidget {
  const StaffListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffList = ref.watch(staffListProvider);
    final operationState = ref.watch(staffOperationProvider);

    // Reset operation state khi success
    if (operationState.isSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(staffOperationProvider.notifier).reset();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Thao tác thành công')));
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151520),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Quản lý Nhân viên',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => context.push('/staffs/form'),
          ),
        ],
      ),
      body: staffList.isEmpty
          ? _buildEmptyState(context)
          : _buildStaffList(context, ref, staffList),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 64, color: Color(0xFF555566)),
          const SizedBox(height: 16),
          const Text(
            'Chưa có nhân viên nào',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhấn nút + để thêm nhân viên mới',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffList(
    BuildContext context,
    WidgetRef ref,
    List<Staff> staffList,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: staffList.length,
      itemBuilder: (context, index) {
        final staff = staffList[index];
        return _StaffCard(
          staff: staff,
          onEdit: () => context.push('/staffs/form', extra: staff),
          onDelete: () => _showDeleteConfirmation(context, ref, staff),
        );
      },
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    Staff staff,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A28),
        title: const Text(
          'Xác nhận xóa',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Bạn có chắc muốn xóa nhân viên "${staff.name}"?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final salonId = ref.read(currentUserProvider)?.salonId ?? 1;
              ref
                  .read(staffOperationProvider.notifier)
                  .deleteStaff(staff.id, salonId);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final Staff staff;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StaffCard({
    required this.staff,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A28),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getColorFromHex(staff.color),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          staff.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              staff.phone,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                _buildRoleBadge(staff.role),
                const SizedBox(width: 8),
                Text(
                  'HH: ${staff.commissionRate.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 8),
                if (!staff.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Ngừng hoạt động',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF3B82F6), size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(
                Icons.delete,
                color: Color(0xFFEF4444),
                size: 20,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorFromHex(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return const Color(0xFF3B82F6);
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF3B82F6);
    }
  }

  Widget _buildRoleBadge(String role) {
    final roleColors = {
      'owner': const Color(0xFFFF6B9D),
      'manager': const Color(0xFF10B981),
      'senior': const Color(0xFF3B82F6),
      'junior': const Color(0xFFF59E0B),
    };
    final roleLabels = {
      'owner': 'Chủ tiệm',
      'manager': 'Quản lý',
      'senior': 'Nhân viên chính',
      'junior': 'Nhân viên',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: roleColors[role] ?? const Color(0xFF6B7280),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        roleLabels[role] ?? role,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }
}
