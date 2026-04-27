// lib/features/pos/screens/bill_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nail_pos/core/models/transaction_item.dart';
import 'package:nail_pos/core/services/printer_service.dart';
import '../../../core/models/transaction.dart';
import '../../../core/models/salon.dart';
import '../../../core/providers/app_data_provider.dart';
import '../../pos/providers/pos_provider.dart';

class BillScreen extends ConsumerWidget {
  const BillScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = ref.watch(posProvider);
    final salon = ref.watch(salonProvider);
    final transaction = pos.lastTransaction;

    if (transaction == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D14),
        body: const Center(
          child: Text(
            'Không tìm thấy thông tin hóa đơn',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D14),
        elevation: 0,
        title: const Text(
          'Hoá đơn',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            ref.read(posProvider.notifier).resetOrder();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Chia sẻ/Tải PDF',
            onPressed: () => _shareBill(context, ref, transaction, salon, pos),
            icon: const Icon(Icons.share, color: Color(0xFFFF6B9D), size: 18),
          ),
          TextButton.icon(
            onPressed: () => _printBill(context, ref, transaction, salon, pos),
            icon: const Icon(Icons.print, size: 16, color: Color(0xFFFF6B9D)),
            label: const Text(
              'In bill',
              style: TextStyle(color: Color(0xFFFF6B9D)),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _BillCard(transaction: transaction, salon: salon, pos: pos),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, ref),
    );
  }

  Widget _buildBottomBar(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF151520),
        border: Border(top: BorderSide(color: Color(0xFF252535), width: 0.5)),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B9D),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () {
          ref.read(posProvider.notifier).resetOrder();
          Navigator.pop(context);
        },
        child: const Text(
          'Đơn mới',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _printBill(
    BuildContext context,
    WidgetRef ref,
    Transaction transaction,
    Salon? salon,
    PosState pos,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(printerServiceProvider)
          .printBill(
            transaction: transaction,
            salon: salon,
            customerName: pos.selectedCustomer?.name,
            staffName: pos.selectedStaff?.name,
          );
    } catch (e, st) {
      debugPrint('[BillScreen] printBill error: $e');
      debugPrintStack(label: '[BillScreen] printBill stack', stackTrace: st);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Không thể mở chế độ in: $e'),
        ),
      );
    }
  }

  Future<void> _shareBill(
    BuildContext context,
    WidgetRef ref,
    Transaction transaction,
    Salon? salon,
    PosState pos,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(printerServiceProvider)
          .shareBill(
            transaction: transaction,
            salon: salon,
            customerName: pos.selectedCustomer?.name,
            staffName: pos.selectedStaff?.name,
          );
    } catch (e, st) {
      debugPrint('[BillScreen] shareBill error: $e');
      debugPrintStack(label: '[BillScreen] shareBill stack', stackTrace: st);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Không thể chia sẻ PDF: $e'),
        ),
      );
    }
  }
}

// ════════════════════════════════════════════════════
// BILL CARD
// ════════════════════════════════════════════════════
class _BillCard extends StatelessWidget {
  final Transaction transaction;
  final Salon? salon;
  final PosState pos;

  const _BillCard({
    required this.transaction,
    required this.salon,
    required this.pos,
  });

  @override
  Widget build(BuildContext context) {
    final vnd = NumberFormat('#,###', 'vi_VN');

    return Container(
      width: 360,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF151520),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF252535), width: 0.5),
      ),
      child: Column(
        children: [
          // ① Salon header
          _buildSalonHeader(),
          const _Dashed(),

          // ② Bill meta
          _buildBillMeta(),
          const SizedBox(height: 16),

          // ③ Khách hàng
          if (pos.selectedCustomer != null) ...[
            _buildCustomer(),
            const SizedBox(height: 16),
          ],

          // ④ Dịch vụ
          _buildSectionTitle('Dịch vụ'),
          ...transaction.items.map((item) => _buildServiceRow(item, vnd)),
          const _Dashed(),

          // ⑤ Tổng tiền
          _buildSummary(vnd),
          const SizedBox(height: 12),

          // ⑥ Payment badge
          _buildPaymentBadge(),
          const _Dashed(),

          // ⑦ Footer
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildSalonHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Text(
            salon?.name ?? 'Nail Studio',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            salon?.address ?? '',
            style: const TextStyle(color: Color(0xFF555566), fontSize: 12),
            textAlign: TextAlign.center,
          ),
          Text(
            salon?.phone ?? '',
            style: const TextStyle(color: Color(0xFF555566), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBillMeta() {
    final dateStr = DateFormat(
      'dd/MM/yyyy · HH:mm',
    ).format(transaction.paidAt ?? DateTime.now());
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMetaCol(
          'Hoá đơn',
          '#${transaction.id.toString().padLeft(6, '0')}',
        ),
        _buildMetaCol('Thời gian', dateStr, right: true),
      ],
    );
  }

  Widget _buildMetaCol(String label, String value, {bool right = false}) {
    return Column(
      crossAxisAlignment: right
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF555566), fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomer() {
    final customer = pos.selectedCustomer!;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF1D3557),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            customer.name.isNotEmpty ? customer.name[0] : 'K',
            style: const TextStyle(
              color: Color(0xFF85B7EB),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customer.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${customer.phone} · Lần thứ ${customer.visitCount}',
              style: const TextStyle(color: Color(0xFF555566), fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF555566),
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRow(TransactionItem item, NumberFormat vnd) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.serviceName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Thợ: ${pos.selectedStaff?.name ?? ""}',
                  style: const TextStyle(
                    color: Color(0xFF555566),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${vnd.format(item.price)}đ',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(NumberFormat vnd) {
    return Column(
      children: [
        _buildSummaryRow('Tạm tính', '${vnd.format(transaction.subtotal)}đ'),
        if (transaction.tipAmount > 0)
          _buildSummaryRow('Tip', '+ ${vnd.format(transaction.tipAmount)}đ'),
        if (transaction.taxAmount > 0)
          _buildSummaryRow(
            'Thuế',
            '+ ${vnd.format(transaction.taxAmount)}đ',
            orange: true,
          ),
        if (transaction.discountAmount > 0)
          _buildSummaryRow(
            'Giảm giá',
            '- ${vnd.format(transaction.discountAmount)}đ',
            green: true,
          ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tổng cộng',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${vnd.format(transaction.totalAmount)}đ',
              style: const TextStyle(
                color: Color(0xFFFF6B9D),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (transaction.payments.length > 1) ...[
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF252535)),
          const SizedBox(height: 8),
          const Row(
            children: [
              Text(
                'CHI TIẾT THANH TOÁN',
                style: TextStyle(color: Color(0xFF555566), fontSize: 10, letterSpacing: 1.2),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...transaction.payments.map((p) => _buildSummaryRow(
            switch(p.paymentMethod) {
              'cash' => 'Tiền mặt',
              'card' => 'Thẻ',
              'transfer' => 'Chuyển khoản',
              _ => p.paymentMethod,
            },
            '${vnd.format(p.amount)}đ',
          )),
        ],
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool green = false,
    bool orange = false,
  }) {
    final Color valueColor = green
        ? const Color(0xFF1D9E75)
        : orange
            ? const Color(0xFFFFB347)
            : const Color(0xFF888899);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
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

  Widget _buildPaymentBadge() {
    String method = '';
    if (transaction.payments.length > 1) {
      method = 'Nhiều phương thức';
    } else {
      method = switch (transaction.paymentMethod) {
        'cash' => 'Tiền mặt',
        'card' => 'Thẻ',
        'transfer' => 'Chuyển khoản',
        _ => transaction.paymentMethod,
      };
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF0A2E1E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1D9E75),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  method,
                  style: const TextStyle(
                    color: Color(0xFF1D9E75),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'Đã thanh toán',
            style: TextStyle(color: Color(0xFF555566), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: const [
          Text(
            'Cảm ơn quý khách đã sử dụng dịch vụ!',
            style: TextStyle(color: Color(0xFF555566), fontSize: 12),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            'Hẹn gặp lại lần sau ✦',
            style: TextStyle(color: Color(0xFF555566), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// Dashed divider
class _Dashed extends StatelessWidget {
  const _Dashed();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dashWidth = 6.0;
          final dashSpace = 4.0;
          final count = (constraints.maxWidth / (dashWidth + dashSpace))
              .floor();
          return Row(
            children: List.generate(
              count,
              (_) => Container(
                width: dashWidth,
                height: 0.5,
                color: const Color(0xFF252535),
                margin: EdgeInsets.only(right: dashSpace),
              ),
            ),
          );
        },
      ),
    );
  }
}
