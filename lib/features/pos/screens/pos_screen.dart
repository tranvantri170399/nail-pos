// lib/features/pos/screens/pos_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/pos_provider.dart';
import '../../../core/models/staff.dart';
import '../../../core/models/service.dart';
import '../../../core/models/customer.dart';
import '../../auth/providers/auth_provider.dart';

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

    // Lắng nghe thanh toán thành công
    ref.listen<PosState>(posProvider, (_, next) {
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
        ref.read(posProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151520),
        elevation: 0,
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
                  color: const Color(0xFFFF6B9D20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFF6B9D40)),
                ),
                child: Text(
                  user.name,
                  style: const TextStyle(color: Color(0xFFFF6B9D), fontSize: 12),
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
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: _ServiceGrid(pos: pos),
                      ),
                      Container(height: 1, color: const Color(0xFF252535)),
                      _CustomerSearch(
                        controller: _phoneCtrl,
                        pos: pos,
                      ),
                      Container(height: 1, color: const Color(0xFF252535)),
                      _OrderSummary(pos: pos),
                    ],
                  ),
                ),
              ],
            );
          } else {
            // ── Dọc: 1 cột cuộn ────────────────────────
            return SingleChildScrollView(
              child: Column(
                children: [
                  _StaffRow(pos: pos),
                  Container(height: 1, color: const Color(0xFF252535)),
                  _ServiceGrid(pos: pos, compact: true),
                  Container(height: 1, color: const Color(0xFF252535)),
                  _CustomerSearch(controller: _phoneCtrl, pos: pos),
                  Container(height: 1, color: const Color(0xFF252535)),
                  _OrderSummary(pos: pos),
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
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
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
              ref.read(posProvider.notifier).resetOrder();
              _phoneCtrl.clear();
            },
            child: const Text('Đơn mới', style: TextStyle(color: Color(0xFFFF6B9D))),
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
          child: Text('CHỌN THỢ', style: TextStyle(
            color: const Color(0xFF555566),
            fontSize: 11,
            letterSpacing: 1.2,
          )),
        ),
        if (pos.isLoadingStaffs)
          const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B9D)))
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: pos.staffList.length,
              itemBuilder: (_, i) => _StaffCard(
                staff: pos.staffList[i],
                isSelected: pos.selectedStaff?.id == pos.staffList[i].id,
                onTap: () => ref.read(posProvider.notifier).selectStaff(pos.staffList[i]),
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
          child: Text('CHỌN THỢ', style: TextStyle(
            color: const Color(0xFF555566),
            fontSize: 11,
            letterSpacing: 1.2,
          )),
        ),
        if (pos.isLoadingStaffs)
          const Center(child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(color: Color(0xFFFF6B9D)),
          ))
        else
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: pos.staffList.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _StaffCard(
                  staff: pos.staffList[i],
                  isSelected: pos.selectedStaff?.id == pos.staffList[i].id,
                  onTap: () => ref.read(posProvider.notifier).selectStaff(pos.staffList[i]),
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
            color: isSelected ? color.withOpacity(0.2) : const Color(0xFF151520),
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
                backgroundColor: color.withOpacity(0.3),
                child: Text(
                  staff.name[0],
                  style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14),
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
          color: isSelected ? color.withOpacity(0.15) : const Color(0xFF151520),
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
              backgroundColor: color.withOpacity(0.3),
              child: Text(
                staff.name[0],
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16),
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
                      color: isSelected ? Colors.white : const Color(0xFF888899),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    staff.role,
                    style: const TextStyle(color: Color(0xFF555566), fontSize: 11),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// SERVICE GRID
// ════════════════════════════════════════════════════
class _ServiceGrid extends ConsumerWidget {
  final PosState pos;
  final bool compact;
  const _ServiceGrid({required this.pos, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('CHỌN DỊCH VỤ', style: TextStyle(
            color: const Color(0xFF555566),
            fontSize: 11,
            letterSpacing: 1.2,
          )),
        ),
        if (pos.isLoadingServices)
          const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B9D)))
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: pos.serviceList.length,
              itemBuilder: (_, i) {
                final service = pos.serviceList[i];
                final isSelected = pos.selectedServices
                    .any((s) => s.id == service.id);
                return _ServiceCard(
                  service: service,
                  isSelected: isSelected,
                  onTap: () => ref.read(posProvider.notifier).toggleService(service),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════
// SERVICE CARD
// ════════════════════════════════════════════════════
class _ServiceCard extends StatelessWidget {
  final NailService service;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _hexToColor(service.color);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : const Color(0xFF151520),
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
                      color: isSelected ? Colors.white : const Color(0xFF888899),
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
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 16),
          ],
        ),
      ),
    );
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
          Text('KHÁCH HÀNG', style: TextStyle(
            color: const Color(0xFF555566),
            fontSize: 11,
            letterSpacing: 1.2,
          )),
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
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF555566), size: 18),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      suffixIcon: pos.isSearchingCustomer
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF6B9D)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Tìm', style: TextStyle(color: Colors.white)),
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
        border: Border.all(color: const Color(0xFF4CAF5040)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF4CAF5020),
            child: Icon(Icons.person, color: Color(0xFF4CAF50), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  customer.phone,
                  style: const TextStyle(color: Color(0xFF555566), fontSize: 11),
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
// ORDER SUMMARY
// ════════════════════════════════════════════════════
class _OrderSummary extends ConsumerWidget {
  final PosState pos;
  const _OrderSummary({required this.pos});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Danh sách dịch vụ đã chọn
          if (pos.selectedServices.isNotEmpty) ...[
            ...pos.selectedServices.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Text('•  ', style: TextStyle(color: Color(0xFF555566))),
                  Expanded(child: Text(s.name, style: const TextStyle(color: Color(0xFF888899), fontSize: 13))),
                  Text('${_vnd.format(s.price)}đ', style: const TextStyle(color: Color(0xFF888899), fontSize: 13)),
                ],
              ),
            )),
            const Divider(color: Color(0xFF252535)),
          ],

          // Tổng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tổng cộng', style: TextStyle(color: Color(0xFF555566), fontSize: 12)),
                  Text(
                    '${_vnd.format(pos.totalPrice)}đ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (pos.totalMinutes > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252535),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer, color: Color(0xFF555566), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${pos.totalMinutes} phút',
                        style: const TextStyle(color: Color(0xFF555566), fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Nút thanh toán
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: pos.canCheckout && !pos.isCheckingOut
                  ? () => ref.read(posProvider.notifier).checkout()
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B9D),
                disabledBackgroundColor: const Color(0xFF252535),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: pos.isCheckingOut
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      pos.canCheckout ? '💳  Thanh toán' : 'Chọn thợ và dịch vụ',
                      style: TextStyle(
                        color: pos.canCheckout ? Colors.white : const Color(0xFF555566),
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
// HELPER
// ════════════════════════════════════════════════════
Color _hexToColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}
