// lib/features/reports/widgets/payment_method_chart.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentMethodChart extends StatelessWidget {
  final Map<String, dynamic> data;
  final ThemeData theme;

  const PaymentMethodChart({
    super.key,
    required this.data,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
        child: Center(
          child: Text(
            'Không có dữ liệu',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      );
    }

    // Calculate total for percentage
    final total = data.values.fold<double>(0, (sum, value) => sum + (value as num).toDouble());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Simple bar chart visualization
          ...data.entries.map((entry) {
            final amount = (entry.value as num).toDouble();
            final percentage = total > 0 ? (amount / total) * 100 : 0.0;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getPaymentMethodLabel(entry.key),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: theme.colorScheme.outline.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getPaymentMethodColor(entry.key),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        currencyFormat.format(amount),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
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

  Color _getPaymentMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Colors.green;
      case 'card':
        return Colors.blue;
      case 'transfer':
        return Colors.purple;
      case 'ewallet':
        return Colors.orange;
      default:
        return theme.colorScheme.primary;
    }
  }
}
