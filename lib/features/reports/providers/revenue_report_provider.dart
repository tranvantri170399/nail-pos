// lib/features/reports/providers/revenue_report_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/transaction.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(ApiClient().dio);
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
        dailyReport: reportData,
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
        dailyReport: reportData,
        transactions: transactions,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
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
