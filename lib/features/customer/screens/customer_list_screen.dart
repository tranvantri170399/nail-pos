// lib/features/customer/screens/customer_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/customer.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/pos/widgets/app_drawer.dart';
import '../customer_provider.dart';

class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final salonId = user?.salonId ?? 1;
    final customersAsync = ref.watch(customerListAsyncProvider(salonId));
    final filteredCustomers = ref.watch(filteredCustomersProvider(salonId));
    final operationState = ref.watch(customerOperationProvider);
    final searchQuery = ref.watch(customerSearchProvider);

    // Reset operation state khi success
    if (operationState.isSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(customerOperationProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thao tác thành công')),
        );
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151520),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Quản lý Khách hàng',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => context.push('/customers/form'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                ref.read(customerSearchProvider.notifier).state = value;
              },
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên hoặc SĐT...',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF1A1A28),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
          ),
          // Customer list
          Expanded(
            child: customersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Lỗi: $error',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              data: (_) {
                if (filteredCustomers.isEmpty) {
                  return _buildEmptyState(searchQuery.isNotEmpty);
                }
                return _buildCustomerList(context, ref, filteredCustomers, salonId);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isSearching) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.people_outline,
            size: 64,
            color: const Color(0xFF555566),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'Không tìm thấy khách hàng' : 'Chưa có khách hàng nào',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          if (!isSearching) ...[
            const SizedBox(height: 8),
            Text(
              'Nhấn nút + để thêm khách hàng mới',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerList(BuildContext context, WidgetRef ref, List<Customer> customers, int salonId) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        return _CustomerCard(
          customer: customer,
          onEdit: () => context.push('/customers/form', extra: customer),
          onDelete: () => _showDeleteConfirmation(context, ref, customer, salonId),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Customer customer, int salonId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A28),
        title: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
        content: Text(
          'Bạn có chắc muốn xóa khách hàng "${customer.name}"?',
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
              ref.read(customerOperationProvider.notifier).deleteCustomer(customer.id, salonId);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerCard({
    required this.customer,
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
            color: const Color(0xFF3B82F6),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          customer.name,
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
              customer.phone,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            if (customer.visitCount != null && customer.visitCount! > 0) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.history, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${customer.visitCount} lượt đến',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                  if (customer.lastVisit != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '• Lần cuối: ${_formatDate(customer.lastVisit!)}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ],
              ),
            ],
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
              icon: const Icon(Icons.delete, color: Color(0xFFEF4444), size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
