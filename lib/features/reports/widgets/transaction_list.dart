// lib/features/reports/widgets/transaction_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/transaction.dart';
import '../../../core/providers/app_data_provider.dart';

class TransactionList extends StatelessWidget {
  final List<Transaction> transactions;
  final ThemeData theme;

  const TransactionList({
    super.key,
    required this.transactions,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Show only last 10 transactions
    final displayTransactions = transactions.take(10).toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Giao dịch gần đây',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (transactions.length > 10)
                  Text(
                    'Hiển thị ${displayTransactions.length}/${transactions.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
              ],
            ),
          ),
          
          // Transaction list
          ...displayTransactions.asMap().entries.map((entry) {
            final index = entry.key;
            final transaction = entry.value;
            final isLast = index == displayTransactions.length - 1;
            
            return Column(
              children: [
                InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => TransactionDetailDialog(
                      transaction: transaction,
                      theme: theme,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Transaction info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '#${transaction.id}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(transaction.status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _getStatusLabel(transaction.status),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: _getStatusColor(transaction.status),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  transaction.paidAt != null
                                      ? '${dateFormat.format(transaction.paidAt!)} ${timeFormat.format(transaction.paidAt!)}'
                                      : 'Chưa thanh toán',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.payment,
                                  size: 12,
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getPaymentMethodLabel(transaction.paymentMethod),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                                if (transaction.items.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '${transaction.items.length} dịch vụ',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Amount
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormat.format(transaction.totalAmount),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          if (transaction.discountAmount > 0) ...[
                            const SizedBox(height: 2),
                            Text(
                              '-${currencyFormat.format(transaction.discountAmount)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.red,
                                decoration: TextDecoration.lineThrough,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    color: theme.colorScheme.outline.withOpacity(0.1),
                  ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Đã thanh toán';
      case 'pending':
        return 'Chờ thanh toán';
      case 'refunded':
        return 'Đã hoàn tiền';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'refunded':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return theme.colorScheme.primary;
    }
  }

  String _getPaymentMethodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Tiền mặt';
      case 'card':
        return 'Thẻ tín dụng';
      case 'transfer':
        return 'Chuyển khoản';
      case 'ewallet':
        return 'Ví điện tử';
      default:
        return method;
    }
  }
}

// ════════════════════════════════════════════════════
// TRANSACTION DETAIL DIALOG
// ════════════════════════════════════════════════════
class TransactionDetailDialog extends ConsumerWidget {
  final Transaction transaction;
  final ThemeData theme;

  const TransactionDetailDialog({
    super.key,
    required this.transaction,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffList = ref.watch(appDataProvider).staffList;
    final vnd = NumberFormat('#,###', 'vi_VN');
    final dateTimeFormat = DateFormat('HH:mm · dd/MM/yyyy');

    final statusColor = _statusColor(transaction.status);
    final statusLabel = _statusLabel(transaction.status);
    final paymentIcon = _paymentIcon(transaction.paymentMethod);
    final paymentLabel = _paymentLabel(transaction.paymentMethod);

    return Dialog(
      backgroundColor: const Color(0xFF1A1A28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.receipt_long, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đơn #${transaction.id}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (transaction.paidAt != null)
                              Text(
                                dateTimeFormat.format(transaction.paidAt!),
                                style: const TextStyle(
                                  color: Color(0xFF888899),
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Color(0xFF888899), size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Phương thức thanh toán ───────────────
              _InfoRow(
                icon: paymentIcon,
                label: 'Thanh toán',
                value: paymentLabel,
              ),
              if (transaction.note != null && transaction.note!.isNotEmpty)
                _InfoRow(
                  icon: Icons.note_outlined,
                  label: 'Ghi chú',
                  value: transaction.note!,
                ),
              const SizedBox(height: 16),

              // ── Danh sách dịch vụ ────────────────────
              if (transaction.items.isNotEmpty) ...[
                _SectionLabel(label: 'DỊCH VỤ (${transaction.items.length})'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: transaction.items.asMap().entries.map((e) {
                      final item = e.value;
                      final isLast = e.key == transaction.items.length - 1;
                      final staffName = item.staffId != null
                          ? staffList
                                .where((s) => s.id == item.staffId)
                                .firstOrNull
                                ?.name
                          : null;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
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
                                        ),
                                      ),
                                      if (staffName != null) ...[  
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.person_outline,
                                              size: 11,
                                              color: Color(0xFF555566),
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              staffName,
                                              style: const TextStyle(
                                                color: Color(0xFF888899),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${vnd.format(item.price)}đ',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'HH: ${(item.commissionRate * 100).toStringAsFixed(0)}%'
                                      ' · ${vnd.format(item.commissionAmount)}đ',
                                      style: const TextStyle(
                                        color: Color(0xFF555566),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (!isLast)
                            const Divider(
                              height: 1,
                              color: Color(0xFF1A1A28),
                              indent: 14,
                              endIndent: 14,
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Tổng kết ─────────────────────────────
              _SectionLabel(label: 'CHI TIẾT THANH TOÁN'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _AmountRow(
                      label: 'Tạm tính',
                      value: '${vnd.format(transaction.subtotal)}đ',
                    ),
                    if (transaction.tipAmount > 0)
                      _AmountRow(
                        label: 'Tip',
                        value: '+ ${vnd.format(transaction.tipAmount)}đ',
                        valueColor: const Color(0xFFFF6B9D),
                      ),
                    if (transaction.discountAmount > 0)
                      _AmountRow(
                        label: 'Giảm giá',
                        value: '- ${vnd.format(transaction.discountAmount)}đ',
                        valueColor: const Color(0xFF4CAF50),
                      ),
                    if (transaction.taxAmount > 0)
                      _AmountRow(
                        label: 'Thuế',
                        value: '+ ${vnd.format(transaction.taxAmount)}đ',
                      ),
                    const Divider(color: Color(0xFF252535), height: 16),
                    _AmountRow(
                      label: 'Tổng cộng',
                      value: '${vnd.format(transaction.totalAmount)}đ',
                      labelStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      valueStyle: const TextStyle(
                        color: Color(0xFFFF6B9D),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Đóng ─────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF252535),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(color: Color(0xFF888899), fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) => switch (status.toLowerCase()) {
        'paid' => Colors.green,
        'pending' => Colors.orange,
        'refunded' => Colors.red,
        _ => Colors.grey,
      };

  String _statusLabel(String status) => switch (status.toLowerCase()) {
        'paid' => 'Đã thanh toán',
        'pending' => 'Chờ thanh toán',
        'refunded' => 'Đã hoàn tiền',
        'cancelled' => 'Đã hủy',
        _ => status,
      };

  IconData _paymentIcon(String method) => switch (method.toLowerCase()) {
        'cash' => Icons.payments_outlined,
        'card' => Icons.credit_card,
        'transfer' => Icons.account_balance_outlined,
        'ewallet' => Icons.account_balance_wallet_outlined,
        _ => Icons.payment,
      };

  String _paymentLabel(String method) => switch (method.toLowerCase()) {
        'cash' => 'Tiền mặt',
        'card' => 'Thẻ tín dụng',
        'transfer' => 'Chuyển khoản',
        'ewallet' => 'Ví điện tử',
        _ => method,
      };
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF555566)),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: const TextStyle(color: Color(0xFF888899), fontSize: 12),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF555566),
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const _AmountRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: labelStyle ??
                const TextStyle(color: Color(0xFF888899), fontSize: 12),
          ),
          Text(
            value,
            style: valueStyle ??
                TextStyle(
                  color: valueColor ?? const Color(0xFF888899),
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }
}
