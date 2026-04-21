import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/bottom_navigation_bar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../pos/widgets/app_drawer.dart';
import '../../reports/providers/revenue_report_provider.dart';
import '../../reports/widgets/revenue_summary_card.dart';
import '../../reports/widgets/transaction_list.dart';

class OwnerDashboardScreen extends ConsumerStatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  ConsumerState<OwnerDashboardScreen> createState() =>
      _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends ConsumerState<OwnerDashboardScreen> {
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    Future(_loadToday);
  }

  void _loadToday() {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final today = DateTime.now();
    final salonId = authState.user.salonId ?? 1;
    ref.read(revenueReportProvider.notifier).getDailyReport(salonId, today);
  }

  void _loadLast7Days() {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 6));
    final salonId = authState.user.salonId ?? 1;
    ref
        .read(revenueReportProvider.notifier)
        .generateReport(salonId, startDate, endDate);
  }

  void _loadThisMonth() {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = now;
    final salonId = authState.user.salonId ?? 1;
    ref
        .read(revenueReportProvider.notifier)
        .generateReport(salonId, startDate, endDate);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reportState = ref.watch(revenueReportProvider);
    final authState = ref.watch(authProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = authState.user;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF888899)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Owner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadToday,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: const PosBottomNavigationBar(),
      body: RefreshIndicator(
        onRefresh: () async => _loadToday(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xin chào, ${user.name}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.salonName ?? 'Salon',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    if (reportState.startDate != null && reportState.endDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          reportState.startDate == reportState.endDate
                              ? 'Dữ liệu: ${_dateFormatter.format(reportState.startDate!)}'
                              : 'Dữ liệu: ${_dateFormatter.format(reportState.startDate!)} - ${_dateFormatter.format(reportState.endDate!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loadToday,
                      child: const Text('Hôm nay'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loadLast7Days,
                      child: const Text('7 ngày'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loadThisMonth,
                      child: const Text('Tháng này'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (reportState.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (reportState.errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    reportState.errorMessage!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: RevenueSummaryCard(
                        title: 'Doanh thu',
                        value: reportState.totalRevenue,
                        icon: Icons.payments_outlined,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RevenueSummaryCard(
                        title: 'Giao dịch',
                        value: reportState.totalTransactions.toDouble(),
                        icon: Icons.receipt_long,
                        color: theme.colorScheme.secondary,
                        isCurrency: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                RevenueSummaryCard(
                  title: 'Giá trị trung bình',
                  value: reportState.averageTransactionValue,
                  icon: Icons.trending_up,
                  color: theme.colorScheme.tertiary,
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Truy cập nhanh',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickActionChip(
                    icon: Icons.point_of_sale,
                    label: 'POS',
                    onTap: () => context.go(AppRoutes.home),
                  ),
                  _QuickActionChip(
                    icon: Icons.bar_chart,
                    label: 'Báo cáo',
                    onTap: () => context.go(AppRoutes.revenueReport),
                  ),
                  _QuickActionChip(
                    icon: Icons.people,
                    label: 'Nhân viên',
                    onTap: () => context.go(AppRoutes.staffs),
                  ),
                  _QuickActionChip(
                    icon: Icons.spa,
                    label: 'Dịch vụ',
                    onTap: () => context.go(AppRoutes.services),
                  ),
                  _QuickActionChip(
                    icon: Icons.person,
                    label: 'Khách hàng',
                    onTap: () => context.go(AppRoutes.customers),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (reportState.transactions != null &&
                  reportState.transactions!.isNotEmpty) ...[
                Text(
                  'Giao dịch gần đây',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                TransactionList(
                  transactions: reportState.transactions!,
                  theme: theme,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onTap,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
