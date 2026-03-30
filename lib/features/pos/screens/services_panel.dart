// lib/features/pos/widgets/services_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/service.dart';
import '../../../core/models/service_category.dart';
import '../../service/services_provider.dart';
import '../../../core/providers/app_data_provider.dart';

class ServicesPanel extends ConsumerStatefulWidget {
  final List<int> selectedIds;
  final Function(Service) onServiceToggled;
  final int salonId;

  const ServicesPanel({
    super.key,
    required this.selectedIds,
    required this.onServiceToggled,
    required this.salonId,
  });

  @override
  ConsumerState<ServicesPanel> createState() => _ServicesPanelState();
}

class _ServicesPanelState extends ConsumerState<ServicesPanel> {
  String _searchQuery = '';
  int? _selectedCategoryId; // null = tất cả

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(
      categoriesWithServicesProvider(widget.salonId),
    );
    final appData = ref.watch(appDataProvider);

    return Column(
      children: [
        _buildSearchBar(),
        categoriesAsync.when(
          loading: () {
            // Show cached data if available while loading
            if (appData.hasCategories) {
              return Expanded(
                child: Column(
                  children: [
                    _buildCategoryTabs(appData.categories),
                    const Divider(height: 1),
                    Expanded(child: _buildServiceGrid(appData.categories)),
                  ],
                ),
              );
            }
            return const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFFF6B9D)),
              ),
            );
          },
          error: (err, _) {
            // Fallback to cached data on error
            if (appData.hasCategories) {
              return Expanded(
                child: Column(
                  children: [
                    _buildCategoryTabs(appData.categories),
                    const Divider(height: 1),
                    Expanded(child: _buildServiceGrid(appData.categories)),
                  ],
                ),
              );
            }
            return Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 40,
                      color: Color(0xFFFF6B9D),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lỗi: $err',
                      style: const TextStyle(color: Color(0xFFFF6B9D)),
                    ),
                    TextButton(
                      onPressed: () => ref.refresh(
                        categoriesWithServicesProvider(widget.salonId),
                      ),
                      child: const Text(
                        'Thử lại',
                        style: TextStyle(color: Color(0xFFFF6B9D)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          data: (categories) => Expanded(
            child: Column(
              children: [
                _buildCategoryTabs(categories),
                const Divider(height: 1),
                Expanded(child: _buildServiceGrid(categories)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ① Search bar
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Tìm dịch vụ...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade400),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1D9E75)),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }

  // ② Category tabs
  Widget _buildCategoryTabs(List<ServiceCategory> categories) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length + 1, // +1 cho "Tất cả"
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildCategoryTab(
              label: 'Tất cả',
              color: const Color(0xFF1D9E75),
              isSelected: _selectedCategoryId == null,
              onTap: () => setState(() => _selectedCategoryId = null),
            );
          }
          final cat = categories[index - 1];
          return _buildCategoryTab(
            label: cat.name,
            color: _parseColor(cat.color),
            isSelected: _selectedCategoryId == cat.id,
            onTap: () => setState(() => _selectedCategoryId = cat.id),
          );
        },
      ),
    );
  }

  Widget _buildCategoryTab({
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ③ Service grid grouped theo category
  Widget _buildServiceGrid(List<ServiceCategory> categories) {
    // Filter theo search + category
    final filtered = categories
        .where(
          (cat) => _selectedCategoryId == null || cat.id == _selectedCategoryId,
        )
        .map((cat) {
          final filteredServices = cat.services
              .where(
                (s) =>
                    s.name.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();
          return MapEntry(cat, filteredServices);
        })
        .where((entry) => entry.value.isNotEmpty)
        .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              'Không tìm thấy dịch vụ',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final cat = filtered[index].key;
        final services = filtered[index].value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _parseColor(cat.color),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${services.length})',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),

            // Services grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: services.length,
              itemBuilder: (context, i) =>
                  _buildServiceCard(services[i], cat.color),
            ),

            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  // ④ Service card
  Widget _buildServiceCard(Service service, String categoryColor) {
    final isSelected = widget.selectedIds.contains(service.id);
    final color = service.color != null
        ? _parseColor(service.color!)
        : _parseColor(categoryColor);

    return GestureDetector(
      onTap: () => widget.onServiceToggled(service),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Tên + check icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    service.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, size: 14, color: color),
              ],
            ),

            // Duration + Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${service.durationMinutes} phút',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatPrice(service.price),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? color : const Color(0xFF1D9E75),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helpers
  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF1D9E75);
    }
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}k';
    }
    return '\$${price.toStringAsFixed(0)}';
  }
}
