// lib/features/reports/screens/revenue_report_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/revenue_report_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/revenue_summary_card.dart';
import '../widgets/payment_method_chart.dart';
import '../widgets/hourly_revenue_chart.dart';
import '../widgets/transaction_list.dart';
import '../../pos/widgets/app_drawer.dart';
import '../../../core/widgets/bottom_navigation_bar.dart';

class RevenueReportScreen extends ConsumerStatefulWidget {
  const RevenueReportScreen({super.key});

  @override
  ConsumerState<RevenueReportScreen> createState() =>
      _RevenueReportScreenState();
}

class _RevenueReportScreenState extends ConsumerState<RevenueReportScreen> {
  DateTime? startDate;
  DateTime? endDate;
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    // Default to today's report - delay để tránh modifying provider trong build
    Future(() => _loadTodayReport());
  }

  void _loadTodayReport() {
    final today = DateTime.now();
    final authState = ref.read(authProvider);

    if (authState is! AuthAuthenticated) {
      return;
    }

    final salonId = authState.user.salonId ?? 1;

    setState(() {
      startDate = today;
      endDate = today;
    });

    ref.read(revenueReportProvider.notifier).getDailyReport(salonId, today);
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.secondary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final authState = ref.read(authProvider);

      if (authState is! AuthAuthenticated) {
        return;
      }

      final salonId = authState.user.salonId ?? 1;

      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });

      ref
          .read(revenueReportProvider.notifier)
          .generateReport(salonId, picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(revenueReportProvider);
    final theme = Theme.of(context);

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
        title: const Text('Báo cáo doanh thu'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF888899)),
            onSelected: (value) {
              switch (value) {
                case 'pos':
                  GoRouter.of(context).go('/home');
                  break;
                case 'dashboard':
                  GoRouter.of(context).go('/dashboard');
                  break;
                case 'appointments':
                  GoRouter.of(context).go('/appointments');
                  break;
                case 'staffs':
                  GoRouter.of(context).go('/staffs');
                  break;
                case 'services':
                  GoRouter.of(context).go('/services');
                  break;
                case 'customers':
                  GoRouter.of(context).go('/customers');
                  break;
                case 'settings':
                  GoRouter.of(context).go('/settings');
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'pos',
                child: Row(
                  children: [
                    Icon(Icons.point_of_sale, size: 20),
                    SizedBox(width: 8),
                    Text('Màn hình POS'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'dashboard',
                child: Row(
                  children: [
                    Icon(Icons.dashboard, size: 20),
                    SizedBox(width: 8),
                    Text('Dashboard'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'appointments',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20),
                    SizedBox(width: 8),
                    Text('Lịch hẹn'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'staffs',
                child: Row(
                  children: [
                    Icon(Icons.people, size: 20),
                    SizedBox(width: 8),
                    Text('Nhân viên'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'services',
                child: Row(
                  children: [
                    Icon(Icons.spa, size: 20),
                    SizedBox(width: 8),
                    Text('Dịch vụ'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'customers',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20),
                    SizedBox(width: 8),
                    Text('Khách hàng'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 8),
                    Text('Cài đặt'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDateRange,
            tooltip: 'Chọn khoảng thời gian',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTodayReport,
            tooltip: 'Hôm nay',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: const ReportsBottomNavigationBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          final authState = ref.read(authProvider);

          if (authState is! AuthAuthenticated ||
              startDate == null ||
              endDate == null) {
            return;
          }

          final salonId = authState.user.salonId ?? 1;

          if (startDate == endDate) {
            await ref
                .read(revenueReportProvider.notifier)
                .getDailyReport(salonId, startDate!);
          } else {
            await ref
                .read(revenueReportProvider.notifier)
                .generateReport(salonId, startDate!, endDate!);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Range Selector
              _buildDateRangeSelector(theme),
              const SizedBox(height: 24),

              // Loading State
              if (reportState.isLoading)
                const Center(child: CircularProgressIndicator())
              // Error State
              else if (reportState.errorMessage != null)
                _buildErrorCard(theme, reportState.errorMessage!)
              // Report Content
              else if (reportState.dailyReport != null)
                _buildReportContent(reportState, theme)
              // Empty State
              else
                _buildEmptyState(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector(ThemeData theme) {
    String dateText = 'Chọn khoảng thời gian';
    if (startDate != null && endDate != null) {
      if (startDate == endDate) {
        dateText = _dateFormatter.format(startDate!);
      } else {
        dateText =
            '${_dateFormatter.format(startDate!)} - ${_dateFormatter.format(endDate!)}';
      }
    }

    return GestureDetector(
      onTap: _selectDateRange,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.date_range,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                dateText,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTodayReport,
            color: theme.colorScheme.error,
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(RevenueReportState reportState, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Revenue Summary Cards
        Row(
          children: [
            Expanded(
              child: RevenueSummaryCard(
                title: 'Tổng doanh thu',
                value: reportState.totalRevenue,
                icon: Icons.attach_money,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RevenueSummaryCard(
                title: 'Số giao dịch',
                value: reportState.totalTransactions.toDouble(),
                icon: Icons.receipt,
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
        const SizedBox(height: 24),

        // Payment Method Breakdown
        if (reportState.paymentMethodBreakdown.isNotEmpty) ...[
          Text(
            'Phương thức thanh toán',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          PaymentMethodChart(
            data: reportState.paymentMethodBreakdown,
            theme: theme,
          ),
          const SizedBox(height: 24),
        ],

        // Hourly Revenue Chart
        if (reportState.hourlyBreakdown.isNotEmpty) ...[
          Text(
            'Doanh thu theo giờ',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          HourlyRevenueChart(data: reportState.hourlyBreakdown, theme: theme),
          const SizedBox(height: 24),
        ],

        // Recent Transactions
        if (reportState.transactions != null &&
            reportState.transactions!.isNotEmpty) ...[
          Text(
            'Giao dịch gần đây',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TransactionList(
            transactions: reportState.transactions!,
            theme: theme,
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có dữ liệu báo cáo',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chọn khoảng thời gian để xem báo cáo doanh thu',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.calendar_today),
            label: const Text('Chọn thời gian'),
          ),
        ],
      ),
    );
  }
}
