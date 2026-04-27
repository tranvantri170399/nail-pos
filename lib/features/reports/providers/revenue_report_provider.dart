// lib/features/reports/providers/revenue_report_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/transaction.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReportsRepository(apiClient.dio);
});

// Revenue Report State
class RevenueReportState {
  final bool isLoading;
  final String? errorMessage;
  final Map<String, dynamic>? dailyReport;
  final List<Transaction>? transactions;
  final DateTime? startDate;
  final DateTime? endDate;

  const RevenueReportState({
    this.isLoading = false,
    this.errorMessage,
    this.dailyReport,
    this.transactions,
    this.startDate,
    this.endDate,
  });

  RevenueReportState copyWith({
    bool? isLoading,
    String? errorMessage,
    Map<String, dynamic>? dailyReport,
    List<Transaction>? transactions,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return RevenueReportState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      dailyReport: dailyReport ?? this.dailyReport,
      transactions: transactions ?? this.transactions,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  // Getters for easy access to report data
  double get totalRevenue => dailyReport?['totalRevenue']?.toDouble() ?? 0.0;
  int get totalTransactions => dailyReport?['totalTransactions'] ?? 0;
  double get averageTransactionValue =>
      totalTransactions > 0 ? totalRevenue / totalTransactions : 0.0;
  Map<String, dynamic> get paymentMethodBreakdown =>
      dailyReport?['paymentMethodBreakdown'] ?? {};
  List<dynamic> get hourlyBreakdown => dailyReport?['hourlyBreakdown'] ?? [];
}

class RevenueReportNotifier extends Notifier<RevenueReportState> {
  @override
  RevenueReportState build() => const RevenueReportState();

  Future<void> generateReport(
    int salonId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      startDate: startDate,
      endDate: endDate,
    );

    try {
      final repo = ref.read(reportsRepositoryProvider);

      // Get daily report for the date range
      final reportData = await repo.getRevenueReport(
        salonId,
        startDate,
        endDate,
      );

      // Get transactions for the date range
      final transactions = await repo.getTransactionsByDateRange(
        salonId,
        startDate,
        endDate,
      );

      state = state.copyWith(
        isLoading: false,
        dailyReport: _enrichReport(reportData, transactions),
        transactions: transactions,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> getDailyReport(int salonId, DateTime date) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      startDate: date,
      endDate: date,
    );

    try {
      final repo = ref.read(reportsRepositoryProvider);
      final reportData = await repo.getDailyReport(salonId, date);
      final transactions = await repo.getTransactionsByDate(salonId, date);

      state = state.copyWith(
        isLoading: false,
        dailyReport: _enrichReport(reportData, transactions),
        transactions: transactions,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Bổ sung paymentMethodBreakdown và hourlyBreakdown từ transactions
  Map<String, dynamic> _enrichReport(
    Map<String, dynamic> reportData,
    List<Transaction> transactions,
  ) {
    final paymentMethodBreakdown = <String, double>{};
    for (final t in transactions) {
      paymentMethodBreakdown[t.paymentMethod] =
          (paymentMethodBreakdown[t.paymentMethod] ?? 0) + t.totalAmount;
    }

    final hourlyMap = <int, Map<String, dynamic>>{};
    for (final t in transactions) {
      if (t.paidAt == null) continue;
      final hour = t.paidAt!.toLocal().hour;
      hourlyMap[hour] ??= {'hour': hour, 'revenue': 0.0, 'transactionCount': 0};
      hourlyMap[hour]!['revenue'] =
          (hourlyMap[hour]!['revenue'] as double) + t.totalAmount;
      hourlyMap[hour]!['transactionCount'] =
          (hourlyMap[hour]!['transactionCount'] as int) + 1;
    }
    final hourlyBreakdown = hourlyMap.entries
        .map((e) => e.value)
        .toList()
      ..sort((a, b) => (a['hour'] as int).compareTo(b['hour'] as int));

    return {
      ...reportData,
      'totalRevenue': reportData['totalRevenue'] ??
          transactions.fold<double>(0, (s, t) => s + t.totalAmount),
      'totalTransactions':
          reportData['totalTransactions'] ?? transactions.length,
      'paymentMethodBreakdown': paymentMethodBreakdown,
      'hourlyBreakdown': hourlyBreakdown,
    };
  }

  void reset() => state = const RevenueReportState();
}

final revenueReportProvider =
    NotifierProvider<RevenueReportNotifier, RevenueReportState>(
      RevenueReportNotifier.new,
    );

// Provider for current date report (today's revenue)
final todayRevenueReportProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final repo = ref.read(reportsRepositoryProvider);
  final authState = ref.read(authProvider);

  if (authState is! AuthAuthenticated) {
    throw Exception('User not authenticated');
  }

  final salonId = authState.user.salonId ?? 1;
  final today = DateTime.now();
  return repo.getDailyReport(salonId, today);
});
