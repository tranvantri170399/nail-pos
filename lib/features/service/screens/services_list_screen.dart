// lib/features/service/screens/services_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/service.dart';
import '../../../core/models/service_category.dart';
import '../../../core/providers/app_data_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/pos/widgets/app_drawer.dart';
import '../services_provider.dart';

class ServicesListScreen extends ConsumerWidget {
  const ServicesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final operationState = ref.watch(serviceOperationProvider);
    final user = ref.watch(currentUserProvider);

    // Reset operation state khi success
    if (operationState.isSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(serviceOperationProvider.notifier).reset();
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
          'Quản lý Dịch vụ',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddMenu(context),
          ),
        ],
      ),
      body: categories.isEmpty
          ? _buildEmptyState(context)
          : _buildCategoriesList(context, ref, categories, user?.salonId ?? 1),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A28),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder_outlined, color: Colors.white),
              title: const Text('Thêm Danh mục mới', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.push('/services/category-form');
              },
            ),
            ListTile(
              leading: const Icon(Icons.spa_outlined, color: Colors.white),
              title: const Text('Thêm Dịch vụ mới', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.push('/services/service-form');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.spa_outlined, size: 64, color: Color(0xFF555566)),
          const SizedBox(height: 16),
          const Text(
            'Chưa có dịch vụ nào',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhấn nút + để thêm danh mục hoặc dịch vụ mới',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList(BuildContext context, WidgetRef ref, List<ServiceCategory> categories, int salonId) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _CategoryCard(
          category: category,
          salonId: salonId,
          onEditCategory: () => context.push('/services/category-form', extra: category),
          onDeleteCategory: () => _showDeleteCategoryConfirmation(context, ref, category, salonId),
          onEditService: (service) => context.push('/services/service-form', extra: {'service': service, 'category': category}),
          onDeleteService: (service) => _showDeleteServiceConfirmation(context, ref, service, salonId),
        );
      },
    );
  }

  void _showDeleteCategoryConfirmation(BuildContext context, WidgetRef ref, ServiceCategory category, int salonId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A28),
        title: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
        content: Text(
          'Bạn có chắc muốn xóa danh mục "${category.name}"?\n\nLưu ý: Tất cả dịch vụ trong danh mục này cũng sẽ bị xóa.',
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
              ref.read(serviceOperationProvider.notifier).deleteCategory(category.id, salonId);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteServiceConfirmation(BuildContext context, WidgetRef ref, Service service, int salonId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A28),
        title: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
        content: Text(
          'Bạn có chắc muốn xóa dịch vụ "${service.name}"?',
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
              ref.read(serviceOperationProvider.notifier).deleteService(service.id, salonId);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ServiceCategory category;
  final int salonId;
  final VoidCallback onEditCategory;
  final VoidCallback onDeleteCategory;
  final Function(Service) onEditService;
  final Function(Service) onDeleteService;

  const _CategoryCard({
    required this.category,
    required this.salonId,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onEditService,
    required this.onDeleteService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A28),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getColorFromHex(category.color).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getColorFromHex(category.color),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF3B82F6), size: 18),
                  onPressed: onEditCategory,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Color(0xFFEF4444), size: 18),
                  onPressed: onDeleteCategory,
                ),
              ],
            ),
          ),
          // Services list
          if (category.services.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Chưa có dịch vụ nào trong danh mục này',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: category.services.length,
              separatorBuilder: (context, index) =>
                  Divider(color: Colors.grey[800], height: 1),
              itemBuilder: (context, index) {
                final service = category.services[index];
                return _ServiceItem(
                  service: service,
                  onEdit: () => onEditService(service),
                  onDelete: () => onDeleteService(service),
                );
              },
            ),
        ],
      ),
    );
  }

  Color _getColorFromHex(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFFFF6B9D);
    }
  }
}

class _ServiceItem extends StatelessWidget {
  final Service service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ServiceItem({
    required this.service,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${service.price.toStringAsFixed(0)}đ',
                      style: TextStyle(
                        color: const Color(0xFFFF6B9D),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${service.durationMinutes} phút',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    if (!service.isActive) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Ngừng KD',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF3B82F6), size: 18),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Color(0xFFEF4444), size: 18),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
