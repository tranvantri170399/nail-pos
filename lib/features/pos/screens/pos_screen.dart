// lib/features/pos/screens/pos_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:nail_pos/features/pos/screens/services_panel.dart';
import '../../../core/models/service_category.dart';
import '../../service/services_provider.dart';
import '../providers/pos_provider.dart';
import '../widgets/app_drawer.dart';
import '../../../core/models/staff.dart';
import '../../../core/models/service.dart';
import '../../../core/models/customer.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/bottom_navigation_bar.dart';

final _vnd = NumberFormat('#,###', 'vi_VN');

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = ref.watch(posProvider);
    final user = ref.watch(currentUserProvider);
    final isStaffCollapsed = ref.watch(staffCollapseProvider);

    // Lắng nghe thanh toán thành công và chọn thợ
    ref.listen<PosState>(posProvider, (previous, next) {
      if (next.checkoutSuccess != null) {
        _showSuccessDialog(next.checkoutSuccess!);
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
        // Delay để tránh modifying provider trong build
        Future(() => ref.read(posProvider.notifier).clearError());
      }
      // Auto collapse khi có thợ được chọn (chỉ ở màn hình dọc)
      if (next.selectedStaff != null && !isStaffCollapsed) {
        // Delay để tránh modifying provider trong build
        Future(() => ref.read(staffCollapseProvider.notifier).state = true);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      drawer: const AppDrawer(),
      bottomNavigationBar: const PosBottomNavigationBar(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151520),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            // ← hamburger icon
            icon: const Icon(Icons.menu, color: Color(0xFF888899)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            const Text('💅', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              'TPOS',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 12),
            if (user != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x20FF6B9D),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x40FF6B9D)),
                ),
                child: Text(
                  user.salonName ?? "N/A",
                  style: const TextStyle(
                    color: Color(0xFFFF6B9D),
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF555566)),
            onPressed: () {
              ref.read(posProvider.notifier).resetOrder();
              _phoneCtrl.clear();
            },
            tooltip: 'Đơn mới',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF555566)),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            // ── Ngang: 2 cột ───────────────────────────
            return Row(
              children: [
                // Cột trái: Chọn thợ
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.35,
                  child: _StaffColumn(pos: pos),
                ),
                Container(width: 1, color: const Color(0xFF252535)),
                // Cột phải: Dịch vụ + Khách + Tổng tiền
                // ② Services Panel
                Expanded(
                  child: ServicesPanel(
                    salonId: pos.salonId,
                    selectedIds: pos.selectedServices.map((s) => s.id).toList(),
                    onServiceToggled: (service) {
                      ref.read(posProvider.notifier).toggleService(service);
                    },
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.35,
                  child: _OrderSummary(
                    pos: pos,
                    orientation: orientation,
                    phoneCtrl: _phoneCtrl,
                  ),
                ),
              ],
            );
          } else {
            // ── Dọc: 1 cột cuộn ────────────────────────
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // AnimatedContainer cho staff section
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: isStaffCollapsed && pos.selectedStaff != null
                        ? 70
                        : null,
                    child: isStaffCollapsed && pos.selectedStaff != null
                        ? _CollapsedStaffCard(
                            staff: pos.selectedStaff!,
                            onTap: () {
                              ref.read(staffCollapseProvider.notifier).state =
                                  false;
                            },
                          )
                        : ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.25,
                            ),
                            child: _StaffRow(pos: pos),
                          ),
                  ),
                  Container(height: 1, color: const Color(0xFF252535)),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.35,
                    ),
                    child: ServicesPanel(
                      salonId: pos.salonId,
                      selectedIds: pos.selectedServices
                          .map((s) => s.id)
                          .toList(),
                      onServiceToggled: (service) {
                        ref.read(posProvider.notifier).toggleService(service);
                      },
                    ),
                  ),
                  Container(height: 1, color: const Color(0xFF252535)),
                  _CustomerSearch(controller: _phoneCtrl, pos: pos),
                  Container(height: 1, color: const Color(0xFF252535)),
                  _OrderSummary(
                    pos: pos,
                    orientation: orientation,
                    phoneCtrl: _phoneCtrl,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  void _showSuccessDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF151520),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✅', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text(
              'Thanh toán thành công!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hoá đơn $orderId',
              style: const TextStyle(color: Color(0xFF555566), fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(AppRoutes.bill);
            },
            child: const Text(
              'In bill',
              style: TextStyle(color: Color(0xFFFF6B9D)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(posProvider.notifier).resetOrder();
              _phoneCtrl.clear();
            },
            child: const Text(
              'Đơn mới',
              style: TextStyle(color: Color(0xFFFF6B9D)),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// STAFF COLUMN (Landscape)
// ════════════════════════════════════════════════════
class _StaffColumn extends ConsumerWidget {
  final PosState pos;
  const _StaffColumn({required this.pos});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'CHỌN THỢ',
            style: TextStyle(
              color: const Color(0xFF555566),
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
        ),
        if (pos.staffList.isEmpty)
          const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6B9D)),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: pos.staffList.length,
              itemBuilder: (context, i) => _StaffCard(
                staff: pos.staffList[i],
                isSelected: pos.selectedStaff?.id == pos.staffList[i].id,
                onTap: () => ref
                    .read(posProvider.notifier)
                    .selectStaff(pos.staffList[i]),
              ),
            ),
          ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════
// STAFF ROW (Portrait)
// ════════════════════════════════════════════════════
class _StaffRow extends ConsumerWidget {
  final PosState pos;
  const _StaffRow({required this.pos});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'CHỌN THỢ',
            style: TextStyle(
              color: const Color(0xFF555566),
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
        ),
        if (pos.staffList.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: Color(0xFFFF6B9D)),
            ),
          )
        else
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: pos.staffList.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _StaffCard(
                  staff: pos.staffList[i],
                  isSelected: pos.selectedStaff?.id == pos.staffList[i].id,
                  onTap: () => ref
                      .read(posProvider.notifier)
                      .selectStaff(pos.staffList[i]),
                  compact: true,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════
// STAFF CARD
// ════════════════════════════════════════════════════
class _StaffCard extends StatelessWidget {
  final Staff staff;
  final bool isSelected;
  final VoidCallback onTap;
  final bool compact;

  const _StaffCard({
    required this.staff,
    required this.isSelected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _hexToColor(staff.color!);

    if (compact) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 70,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.2)
                : const Color(0xFF151520),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : const Color(0xFF252535),
              width: isSelected ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withValues(alpha: 0.3),
                child: Text(
                  staff.name[0],
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                staff.name.split(' ').last,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF555566),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : const Color(0xFF151520),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF252535),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.3),
              child: Text(
                staff.name[0],
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff.name,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF888899),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    staff.role,
                    style: const TextStyle(
                      color: Color(0xFF555566),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// SERVICE GRID
// ════════════════════════════════════════════════════
class _ServiceGrid extends ConsumerStatefulWidget {
  final PosState pos;
  const _ServiceGrid({required this.pos});

  @override
  ConsumerState<_ServiceGrid> createState() => _ServiceGridState();
}

class _ServiceGridState extends ConsumerState<_ServiceGrid> {
  int? _selectedCategoryId; // null = tất cả
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(
      categoriesWithServicesProvider(widget.pos.salonId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'CHỌN DỊCH VỤ',
            style: TextStyle(
              color: const Color(0xFF555566),
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
        ),

        // Search bar
        _buildSearchBar(),

        // Category tabs + Grid
        categoriesAsync.when(
          loading: () => const Expanded(
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B9D)),
            ),
          ),
          error: (err, _) => Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFFF6B9D),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    err.toString(),
                    style: const TextStyle(
                      color: Color(0xFF555566),
                      fontSize: 12,
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.refresh(
                      categoriesWithServicesProvider(widget.pos.salonId),
                    ),
                    child: const Text(
                      'Thử lại',
                      style: TextStyle(color: Color(0xFFFF6B9D)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (categories) => Expanded(
            child: Column(
              children: [
                _buildCategoryTabs(categories),
                const SizedBox(height: 8),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Tìm dịch vụ...',
          hintStyle: const TextStyle(color: Color(0xFF555566), fontSize: 13),
          prefixIcon: const Icon(
            Icons.search,
            size: 16,
            color: Color(0xFF555566),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                    size: 14,
                    color: Color(0xFF555566),
                  ),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          filled: true,
          fillColor: const Color(0xFF151520),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF252535)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF252535), width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFFF6B9D), width: 1),
          ),
        ),
      ),
    );
  }

  // ② Category tabs
  Widget _buildCategoryTabs(List<ServiceCategory> categories) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildTab(
              label: 'Tất cả',
              color: const Color(0xFFFF6B9D),
              isSelected: _selectedCategoryId == null,
              onTap: () => setState(() => _selectedCategoryId = null),
            );
          }
          final cat = categories[index - 1];
          final color = _hexToColor(cat.color);
          return _buildTab(
            label: cat.name,
            color: color,
            isSelected: _selectedCategoryId == cat.id,
            onTap: () => setState(() => _selectedCategoryId = cat.id),
          );
        },
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : const Color(0xFF151520),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF252535),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? color : const Color(0xFF555566),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ③ Service grid grouped theo category
  Widget _buildServiceGrid(List<ServiceCategory> categories) {
    final filtered = categories
        .where(
          (cat) => _selectedCategoryId == null || cat.id == _selectedCategoryId,
        )
        .map((cat) {
          final services = cat.services
              .where(
                (s) =>
                    s.name.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();
          return MapEntry(cat, services);
        })
        .where((e) => e.value.isNotEmpty)
        .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'Không tìm thấy dịch vụ',
          style: TextStyle(color: const Color(0xFF555566), fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final cat = filtered[index].key;
        final services = filtered[index].value;
        final catColor = _hexToColor(cat.color);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: catColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat.name.toUpperCase(),
                    style: TextStyle(
                      color: catColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${services.length}',
                    style: const TextStyle(
                      color: Color(0xFF555566),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            // Grid services
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: services.length,
              itemBuilder: (context, i) {
                final service = services[i];
                final isSelected = widget.pos.selectedServices.any(
                  (s) => s.id == service.id,
                );
                return _ServiceCard(
                  service: service,
                  isSelected: isSelected,
                  onTap: () =>
                      ref.read(posProvider.notifier).toggleService(service),
                );
              },
            ),

            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════
// SERVICE CARD — giữ style cũ, thêm fallback color
// ════════════════════════════════════════════════════
class _ServiceCard extends StatelessWidget {
  final Service service;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Fallback nếu color null
    final color = service.color != null
        ? _hexToColor(service.color!)
        : const Color(0xFFFF6B9D);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : const Color(0xFF151520),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF252535),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    service.name,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF888899),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${_vnd.format(service.price)}đ · ${service.durationMinutes}p',
                    style: TextStyle(
                      color: isSelected ? color : const Color(0xFF555566),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}

// Helper — dùng chung trong file
Color _hexToColor(String hex) {
  try {
    return Color(int.parse(hex.replaceAll('#', '0xFF')));
  } catch (_) {
    return const Color(0xFFFF6B9D);
  }
}

// ════════════════════════════════════════════════════
// CUSTOMER SEARCH
// ════════════════════════════════════════════════════
class _CustomerSearch extends ConsumerWidget {
  final TextEditingController controller;
  final PosState pos;

  const _CustomerSearch({required this.controller, required this.pos});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KHÁCH HÀNG',
            style: TextStyle(
              color: const Color(0xFF555566),
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // Nếu đã tìm thấy khách
          if (pos.selectedCustomer != null)
            _CustomerCard(
              customer: pos.selectedCustomer!,
              onClear: () {
                ref.read(posProvider.notifier).clearCustomer();
                controller.clear();
              },
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Nhập SĐT để tìm khách...',
                      hintStyle: const TextStyle(color: Color(0xFF333344)),
                      filled: true,
                      fillColor: const Color(0xFF151520),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF555566),
                        size: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF252535)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF252535)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFFF6B9D)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      suffixIcon: pos.isSearchingCustomer
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFFF6B9D),
                                ),
                              ),
                            )
                          : null,
                    ),
                    onSubmitted: (phone) =>
                        ref.read(posProvider.notifier).searchCustomer(phone),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => ref
                      .read(posProvider.notifier)
                      .searchCustomer(controller.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF252535),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Tìm',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onClear;

  const _CustomerCard({required this.customer, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF151520),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x404CAF50)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0x204CAF50),
            child: Icon(Icons.person, color: Color(0xFF4CAF50), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  customer.phone,
                  style: const TextStyle(
                    color: Color(0xFF555566),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close, color: Color(0xFF555566), size: 18),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// COLLAPSED STAFF CARD (Portrait mode)
// ════════════════════════════════════════════════════
class _CollapsedStaffCard extends StatelessWidget {
  final Staff staff;
  final VoidCallback onTap;

  const _CollapsedStaffCard({required this.staff, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _hexToColor(staff.color!);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withValues(alpha: 0.3),
              child: Text(
                staff.name[0],
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    staff.role,
                    style: const TextStyle(
                      color: Color(0xFF555566),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_up, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// SUMMARY LINE (breakdown row)
// ════════════════════════════════════════════════════
class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryLine({
    required this.label,
    required this.value,
    this.valueColor = const Color(0xFF888899),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF555566), fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(color: valueColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// ORDER SUMMARY
// ════════════════════════════════════════════════════
class _OrderSummary extends ConsumerWidget {
  final PosState pos;
  final Orientation orientation;
  final TextEditingController phoneCtrl;
  const _OrderSummary({
    required this.pos,
    required this.orientation,
    required this.phoneCtrl,
  });

  // ── Dialog chọn phương thức thanh toán ─────────────────────
  void _showPaymentMethodDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn phương thức thanh toán'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.money),
              title: const Text('Tiền mặt'),
              onTap: () {
                ref.read(posProvider.notifier).selectPaymentMethod('cash');
                Navigator.of(context).pop();
                ref.read(posProvider.notifier).checkout();
              },
            ),
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('Thẻ ngân hàng'),
              onTap: () {
                ref.read(posProvider.notifier).selectPaymentMethod('card');
                Navigator.of(context).pop();
                ref.read(posProvider.notifier).checkout();
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Chuyển khoản QR'),
              onTap: () {
                ref.read(posProvider.notifier).selectPaymentMethod('transfer');
                Navigator.of(context).pop();
                ref.read(posProvider.notifier).checkout();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper methods ───────────────────────────────────────
  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'transfer':
        return Icons.qr_code_scanner;
      default:
        return Icons.money;
    }
  }

  String _getPaymentText(String method) {
    switch (method) {
      case 'cash':
        return 'Tiền mặt';
      case 'card':
        return 'Thẻ ngân hàng';
      case 'transfer':
        return 'Chuyển khoản QR';
      default:
        return 'Tiền mặt';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = ref.watch(posProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (orientation == Orientation.landscape) ...[
            _CustomerSearch(controller: phoneCtrl, pos: pos),
          ],
          // Danh sách dịch vụ đã chọn
          if (orientation == Orientation.landscape)
            Expanded(
              child: Column(
                children: [
                  if (pos.selectedServices.isNotEmpty) ...[
                    ...pos.selectedServices.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 4, top: 5),
                        child: Row(
                          children: [
                            const Text(
                              '•  ',
                              style: TextStyle(color: Color(0xFF555566)),
                            ),
                            Expanded(
                              child: Text(
                                s.name,
                                style: const TextStyle(
                                  color: Color(0xFF888899),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Text(
                              '${_vnd.format(s.price)}đ',
                              style: const TextStyle(
                                color: Color(0xFF888899),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(color: Color(0xFF252535)),
                  ],
                ],
              ),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (pos.selectedServices.isNotEmpty) ...[
                  ...pos.selectedServices.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 4, top: 5),
                      child: Row(
                        children: [
                          const Text(
                            '•  ',
                            style: TextStyle(color: Color(0xFF555566)),
                          ),
                          Expanded(
                            child: Text(
                              s.name,
                              style: const TextStyle(
                                color: Color(0xFF888899),
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            '${_vnd.format(s.price)}đ',
                            style: const TextStyle(
                              color: Color(0xFF888899),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(color: Color(0xFF252535)),
                ],
              ],
            ),

          // Tip & Giảm giá (chỉ hiện khi có dịch vụ)
          if (pos.selectedServices.isNotEmpty) ...[
            const _TipDiscountSection(),
            const SizedBox(height: 10),
          ],

          // Breakdown chi tiết (hiện khi có điều chỉnh)
          if (pos.tipAmount > 0 || pos.discountAmount > 0 || pos.taxRate > 0) ...[
            _SummaryLine(
              label: 'Tạm tính',
              value: '${_vnd.format(pos.subtotal)}đ',
            ),
            if (pos.tipAmount > 0)
              _SummaryLine(
                label: 'Tip',
                value: '+ ${_vnd.format(pos.tipAmount)}đ',
              ),
            if (pos.taxAmount > 0)
              _SummaryLine(
                label: 'Thuế (${(pos.taxRate * 100).toStringAsFixed(0)}%)',
                value: '+ ${_vnd.format(pos.taxAmount)}đ',
                valueColor: const Color(0xFFFFB347),
              ),
            if (pos.discountAmount > 0)
              _SummaryLine(
                label: 'Giảm giá',
                value: '- ${_vnd.format(pos.discountAmount)}đ',
                valueColor: const Color(0xFF4CAF50),
              ),
            const Divider(color: Color(0xFF252535), height: 12),
          ],

          // Tổng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tổng cộng',
                    style: TextStyle(color: Color(0xFF555566), fontSize: 12),
                  ),
                  Text(
                    '${_vnd.format(pos.grandTotal)}đ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _getPaymentIcon(pos.paymentMethod),
                        size: 16,
                        color: const Color(0xFF555566),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getPaymentText(pos.paymentMethod),
                        style: const TextStyle(
                          color: Color(0xFF555566),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (pos.totalMinutes > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252535),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.timer,
                        color: Color(0xFF555566),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${pos.totalMinutes} phút',
                        style: const TextStyle(
                          color: Color(0xFF555566),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          // Tiền nhận / Tiền thừa (chỉ khi chọn tiền mặt)
          if (pos.paymentMethod == 'cash' && pos.selectedServices.isNotEmpty) ...[            const _CashSection(),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          // Nút thanh toán
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: pos.canCheckout && !pos.isCheckingOut
                  ? () => _showPaymentMethodDialog(context, ref)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B9D),
                disabledBackgroundColor: const Color(0xFF252535),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: pos.isCheckingOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      pos.canCheckout
                          ? '💳  Thanh toán'
                          : 'Chọn thợ và dịch vụ',
                      style: TextStyle(
                        color: pos.canCheckout
                            ? Colors.white
                            : const Color(0xFF555566),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// TIP & DISCOUNT SECTION
// ════════════════════════════════════════════════════
class _TipDiscountSection extends ConsumerStatefulWidget {
  const _TipDiscountSection();

  @override
  ConsumerState<_TipDiscountSection> createState() =>
      _TipDiscountSectionState();
}

class _TipDiscountSectionState extends ConsumerState<_TipDiscountSection> {
  final _discountCtrl = TextEditingController();

  static const _quickTips = [0.0, 20000.0, 50000.0, 100000.0];

  @override
  void dispose() {
    _discountCtrl.dispose();
    super.dispose();
  }

  void _showCustomTipDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Nhập tip',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Số tiền...',
            hintStyle: TextStyle(color: Color(0xFF555566)),
            suffixText: 'đ',
            suffixStyle: TextStyle(color: Color(0xFF888899)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Color(0xFF888899)),
            ),
          ),
          TextButton(
            onPressed: () {
              final v =
                  double.tryParse(ctrl.text.replaceAll(',', '')) ?? 0;
              ref.read(posProvider.notifier).setTip(v);
              Navigator.pop(context);
            },
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFFFF6B9D)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pos = ref.watch(posProvider);
    final notifier = ref.read(posProvider.notifier);
    final isCustomTip =
        pos.tipAmount > 0 && !_quickTips.contains(pos.tipAmount);

    ref.listen<PosState>(posProvider, (prev, next) {
      if (next.discountAmount == 0 && (prev?.discountAmount ?? 0) != 0) {
        _discountCtrl.clear();
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── TIP ─────────────────────────────────────────
        Row(
          children: [
            const SizedBox(
              width: 44,
              child: Text(
                'TIP',
                style: TextStyle(
                  color: Color(0xFF555566),
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            _TipChip(
              label: 'Không',
              selected: pos.tipAmount == 0,
              onTap: () => notifier.setTip(0),
            ),
            _TipChip(
              label: '20k',
              selected: pos.tipAmount == 20000,
              onTap: () => notifier.setTip(20000),
            ),
            _TipChip(
              label: '50k',
              selected: pos.tipAmount == 50000,
              onTap: () => notifier.setTip(50000),
            ),
            _TipChip(
              label: '100k',
              selected: pos.tipAmount == 100000,
              onTap: () => notifier.setTip(100000),
            ),
            _TipChip(
              label: isCustomTip
                  ? '${(pos.tipAmount ~/ 1000).toInt()}k✎'
                  : 'Khác',
              selected: isCustomTip,
              onTap: () => _showCustomTipDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // ── THUẾ ─────────────────────────────────────────
        Row(
          children: [
            const SizedBox(
              width: 44,
              child: Text(
                'THUẾ',
                style: TextStyle(
                  color: Color(0xFF555566),
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            _TipChip(
              label: '0%',
              selected: pos.taxRate == 0,
              onTap: () => notifier.setTaxRate(0),
            ),
            _TipChip(
              label: '5%',
              selected: pos.taxRate == 0.05,
              onTap: () => notifier.setTaxRate(0.05),
            ),
            _TipChip(
              label: '8%',
              selected: pos.taxRate == 0.08,
              onTap: () => notifier.setTaxRate(0.08),
            ),
            _TipChip(
              label: '10%',
              selected: pos.taxRate == 0.10,
              onTap: () => notifier.setTaxRate(0.10),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // ── GIẢM GIÁ ────────────────────────────────
        Row(
          children: [
            const SizedBox(
              width: 44,
              child: Text(
                'GIẢM',
                style: TextStyle(
                  color: Color(0xFF555566),
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 32,
                child: TextField(
                  controller: _discountCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: const TextStyle(
                      color: Color(0xFF333344),
                      fontSize: 13,
                    ),
                    suffixText: 'đ',
                    suffixStyle: const TextStyle(
                      color: Color(0xFF555566),
                      fontSize: 13,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF151520),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF252535)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF252535)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFFFF6B9D)),
                    ),
                  ),
                  onChanged: (val) {
                    final v =
                        double.tryParse(val.replaceAll(',', '')) ?? 0;
                    notifier.setDiscount(v);
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════
// CASH RECEIVED SECTION
// ════════════════════════════════════════════════════
class _CashSection extends ConsumerStatefulWidget {
  const _CashSection();

  @override
  ConsumerState<_CashSection> createState() => _CashSectionState();
}

class _CashSectionState extends ConsumerState<_CashSection> {
  final _cashCtrl = TextEditingController();

  @override
  void dispose() {
    _cashCtrl.dispose();
    super.dispose();
  }

  List<double> _quickAmounts(double total) {
    final result = <double>[total];
    final r50 = (total / 50000).ceil() * 50000.0;
    if (r50 > total) result.add(r50);
    for (final a in [200000.0, 500000.0, 1000000.0, 2000000.0]) {
      if (a > total && !result.contains(a)) result.add(a);
      if (result.length >= 4) break;
    }
    return result.take(4).toList();
  }

  String _chipLabel(double amt, double total) {
    if (amt == total) return 'Đúng tiền';
    if (amt >= 1000000) return '${(amt / 1000000).toStringAsFixed(amt % 1000000 == 0 ? 0 : 1)}tr';
    return '${(amt ~/ 1000).toInt()}k';
  }

  @override
  Widget build(BuildContext context) {
    final pos = ref.watch(posProvider);
    final notifier = ref.read(posProvider.notifier);
    final total = pos.grandTotal;
    final received = pos.cashReceived;
    final change = received > 0 ? received - total : null;
    final isShort = change != null && change < 0;

    ref.listen<PosState>(posProvider, (prev, next) {
      if (next.cashReceived == 0 && (prev?.cashReceived ?? 0) != 0) {
        _cashCtrl.clear();
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Color(0xFF252535), height: 16),
        // ── Quick chips ─────────────────────────────────────
        Row(
          children: [
            const SizedBox(
              width: 44,
              child: Text(
                'NHẬN',
                style: TextStyle(
                  color: Color(0xFF555566),
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ..._quickAmounts(total).map(
              (amt) => _TipChip(
                label: _chipLabel(amt, total),
                selected: received == amt,
                onTap: () {
                  notifier.setCashReceived(amt);
                  _cashCtrl.text = amt == total
                      ? ''
                      : _vnd.format(amt).replaceAll(',', '.');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // ── Custom input ────────────────────────────────────
        Row(
          children: [
            const SizedBox(width: 44),
            Expanded(
              child: SizedBox(
                height: 32,
                child: TextField(
                  controller: _cashCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: 'Nhập số tiền...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF333344),
                      fontSize: 13,
                    ),
                    suffixText: 'đ',
                    suffixStyle: const TextStyle(
                      color: Color(0xFF555566),
                      fontSize: 13,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF151520),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isShort
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF252535),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isShort
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF252535),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFFFF6B9D)),
                    ),
                  ),
                  onChanged: (val) {
                    final v =
                        double.tryParse(val.replaceAll(',', '').replaceAll('.', '')) ?? 0;
                    notifier.setCashReceived(v);
                  },
                ),
              ),
            ),
          ],
        ),
        // ── Change due / insufficient ───────────────────────────
        if (change != null) ...[          const SizedBox(height: 6),
          Row(
            children: [
              const SizedBox(width: 44),
              Icon(
                isShort ? Icons.warning_amber_rounded : Icons.check_circle,
                size: 14,
                color: isShort
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF4CAF50),
              ),
              const SizedBox(width: 4),
              Text(
                isShort
                    ? 'Thiếu: ${_vnd.format(change.abs())}đ'
                    : 'Tiền thừa: ${_vnd.format(change)}đ',
                style: TextStyle(
                  color: isShort
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF4CAF50),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════
// TIP CHIP
// ════════════════════════════════════════════════════
class _TipChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TipChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFF6B9D).withValues(alpha: 0.15)
              : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF6B9D)
                : const Color(0xFF252535),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? const Color(0xFFFF6B9D)
                : const Color(0xFF888899),
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
