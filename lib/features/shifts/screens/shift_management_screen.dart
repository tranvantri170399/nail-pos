// lib/features/shifts/screens/shift_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/shift.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/shifts_provider.dart';

final _vnd = NumberFormat('#,###', 'vi_VN');

class ShiftManagementScreen extends ConsumerWidget {
  const ShiftManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftState = ref.watch(shiftsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151520),
        title: const Text('Quản lý Ca làm việc', style: TextStyle(color: Colors.white, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: shiftState.isLoading && shiftState.currentShift == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B9D)))
          : Padding(
              padding: const EdgeInsets.all(24),
              child: shiftState.currentShift != null
                  ? _ActiveShiftView(shift: shiftState.currentShift!)
                  : _OpenShiftView(salonId: user?.salonId ?? 1),
            ),
    );
  }
}

class _OpenShiftView extends ConsumerStatefulWidget {
  final int salonId;
  const _OpenShiftView({required this.salonId});

  @override
  ConsumerState<_OpenShiftView> createState() => _OpenShiftViewState();
}

class _OpenShiftViewState extends ConsumerState<_OpenShiftView> {
  final _amountCtrl = TextEditingController(text: '0');

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF151520),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF252535)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.point_of_sale, size: 64, color: Color(0xFF888899)),
            const SizedBox(height: 24),
            const Text(
              'Bắt đầu ca mới',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nhập số tiền mặt có trong két hiện tại để mở ca',
              style: TextStyle(color: Color(0xFF888899), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: 'Tiền đầu ca (VND)',
                labelStyle: const TextStyle(color: Color(0xFF555566)),
                filled: true,
                fillColor: const Color(0xFF0D0D12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF6B9D)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
                  final success = await ref.read(shiftsProvider.notifier).openShift(widget.salonId, amount);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã mở ca thành công!'), backgroundColor: Colors.green),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B9D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('MỞ CA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveShiftView extends ConsumerWidget {
  final Shift shift;
  const _ActiveShiftView({required this.shift});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _buildStatCards(),
        const SizedBox(height: 24),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context, 
                  ref,
                  icon: Icons.add_circle_outline,
                  color: Colors.green,
                  title: 'Nạp tiền (Pay In)',
                  subtitle: 'Nạp thêm tiền lẻ vào két',
                  onTap: () => _showCashMovementDialog(context, ref, 'pay_in'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  context, 
                  ref,
                  icon: Icons.remove_circle_outline,
                  color: Colors.orange,
                  title: 'Rút tiền (Pay Out)',
                  subtitle: 'Lấy tiền ra chi tiêu/trả hàng',
                  onTap: () => _showCashMovementDialog(context, ref, 'pay_out'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  context, 
                  ref,
                  icon: Icons.lock_outline,
                  color: const Color(0xFFFF6B9D),
                  title: 'Đóng ca',
                  subtitle: 'Kết thúc ca và đếm tiền',
                  onTap: () => _showCloseShiftDialog(context, ref),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Tiền đầu ca',
            value: '${_vnd.format(shift.startingCash)} đ',
            icon: Icons.account_balance_wallet,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'Tiền mặt hiện tại (Dự kiến)',
            value: '${_vnd.format(shift.expectedEndingCash ?? shift.startingCash)} đ',
            icon: Icons.attach_money,
            highlight: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'Thời gian mở',
            value: DateFormat('HH:mm - dd/MM').format(shift.openedAt),
            icon: Icons.access_time,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, WidgetRef ref, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF151520),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF252535)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: Color(0xFF888899), fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _showCashMovementDialog(BuildContext context, WidgetRef ref, String type) {
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final isPayIn = type == 'pay_in';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151520),
        title: Text(isPayIn ? 'Nạp tiền (Pay In)' : 'Rút tiền (Pay Out)', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Số tiền (VND)', labelStyle: TextStyle(color: Color(0xFF888899))),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Lý do', labelStyle: TextStyle(color: Color(0xFF888899))),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF888899))),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount > 0) {
                await ref.read(shiftsProvider.notifier).recordCashMovement(type, amount, reasonCtrl.text);
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: isPayIn ? Colors.green : Colors.orange),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCloseShiftDialog(BuildContext context, WidgetRef ref) {
    final amountCtrl = TextEditingController(text: (shift.expectedEndingCash ?? 0).toStringAsFixed(0));
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151520),
        title: const Text('Đóng Ca', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Két dự kiến có: ${_vnd.format(shift.expectedEndingCash ?? 0)} đ', style: const TextStyle(color: Color(0xFFFF6B9D), fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Tiền mặt thực tế đếm được', labelStyle: TextStyle(color: Color(0xFF888899))),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Ghi chú (nếu có chênh lệch)', labelStyle: TextStyle(color: Color(0xFF888899))),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF888899))),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              await ref.read(shiftsProvider.notifier).closeShift(amount, noteCtrl.text);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B9D)),
            child: const Text('Đóng Ca', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const _StatCard({required this.label, required this.value, required this.icon, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151520),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: highlight ? const Color(0xFFFF6B9D) : const Color(0xFF252535), width: highlight ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: highlight ? const Color(0xFFFF6B9D) : const Color(0xFF888899), size: 20),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Color(0xFF888899), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(color: Colors.white, fontSize: highlight ? 24 : 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
