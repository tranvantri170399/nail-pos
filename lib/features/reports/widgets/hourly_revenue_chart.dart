// lib/features/reports/widgets/hourly_revenue_chart.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HourlyRevenueChart extends StatelessWidget {
  final List<dynamic> data;
  final ThemeData theme;

  const HourlyRevenueChart({
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
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Text(
            'Không có dữ liệu theo giờ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    // Find max value for scaling
    final maxValue = data.fold<double>(0, (max, item) {
      final revenue = (item['revenue'] as num?)?.toDouble() ?? 0.0;
      return revenue > max ? revenue : max;
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Chart header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Giờ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              Text(
                'Doanh thu',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Hourly bars
          SizedBox(
            height: 200,
            child: Row(
              children: data.map((item) {
                final hour = item['hour'] as int? ?? 0;
                final revenue = (item['revenue'] as num?)?.toDouble() ?? 0.0;
                final transactionCount = item['transactionCount'] as int? ?? 0;
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Revenue amount on top of bar
                        if (revenue > 0)
                          Text(
                            currencyFormat.format(revenue),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        
                        // Bar
                        Container(
                          height: maxValue > 0 ? (revenue / maxValue) * 150 : 0,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        
                        // Hour label
                        Text(
                          '${hour.toString().padLeft(2, '0')}h',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                          ),
                        ),
                        
                        // Transaction count
                        if (transactionCount > 0)
                          Text(
                            '$transactionCount',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 9,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                'Số giao dịch được hiển thị trên mỗi cột',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
