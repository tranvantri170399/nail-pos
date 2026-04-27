// lib/features/reports/repositories/reports_repository.dart
import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/transaction.dart';

class ReportsRepository {
  final Dio _dio;
  ReportsRepository(this._dio);

  // Get revenue report for a date range
  Future<Map<String, dynamic>> getRevenueReport(
    int salonId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.transactionReport,
        queryParameters: {
          'salonId': salonId,
          'startDate': _formatDate(startDate),
          'endDate': _formatDate(endDate),
        },
      );
      return response.data;
    } catch (e) {
      // Fallback: get transactions and calculate report locally
      final transactions = await getTransactionsByDateRange(
        salonId,
        startDate,
        endDate,
      );
      return _calculateReportFromTransactions(transactions);
    }
  }

  // Get daily report for a specific date
  Future<Map<String, dynamic>> getDailyReport(
    int salonId,
    DateTime date,
  ) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.transactionReport,
        queryParameters: {'salonId': salonId, 'date': _formatDate(date)},
      );
      return response.data;
    } catch (e) {
      // Fallback: get transactions and calculate report locally
      final transactions = await getTransactionsByDate(salonId, date);
      return _calculateReportFromTransactions(transactions);
    }
  }

  Future<Transaction> refundTransaction(int transactionId) async {
    final response = await _dio.patch(
      ApiEndpoints.transactionRefund(transactionId),
    );
    return Transaction.fromJson(response.data);
  }

  // Helper method to calculate report from transactions (fallback)
  Map<String, dynamic> _calculateReportFromTransactions(
    List<Transaction> transactions,
  ) {
    final totalRevenue = transactions.fold<double>(
      0,
      (sum, t) => sum + t.totalAmount,
    );
    final totalTransactions = transactions.length;
    final averageTransactionValue = totalTransactions > 0
        ? totalRevenue / totalTransactions
        : 0.0;

    // Payment method breakdown
    final paymentMethodBreakdown = <String, double>{};
    for (final transaction in transactions) {
      paymentMethodBreakdown[transaction.paymentMethod] =
          (paymentMethodBreakdown[transaction.paymentMethod] ?? 0) +
          transaction.totalAmount;
    }

    // Hourly breakdown
    final hourlyBreakdown = <Map<String, dynamic>>[];
    for (int hour = 0; hour < 24; hour++) {
      final hourTransactions = transactions.where((t) {
        if (t.paidAt == null) return false;
        return t.paidAt!.hour == hour;
      }).toList();

      final hourRevenue = hourTransactions.fold<double>(
        0,
        (sum, t) => sum + t.totalAmount,
      );

      if (hourRevenue > 0) {
        hourlyBreakdown.add({
          'hour': hour,
          'revenue': hourRevenue,
          'transactionCount': hourTransactions.length,
        });
      }
    }

    return {
      'totalRevenue': totalRevenue,
      'totalTransactions': totalTransactions,
      'averageTransactionValue': averageTransactionValue,
      'paymentMethodBreakdown': paymentMethodBreakdown,
      'hourlyBreakdown': hourlyBreakdown,
    };
  }

  // Get transactions for a specific date
  Future<List<Transaction>> getTransactionsByDate(
    int salonId,
    DateTime date,
  ) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.transactions,
        queryParameters: {'salonId': salonId, 'date': _formatDate(date)},
      );
      return (response.data as List)
          .map((e) => Transaction.fromJson(e))
          .toList();
    } catch (e) {
      // Return empty list if API fails
      return [];
    }
  }

  // Get transactions for a date range
  Future<List<Transaction>> getTransactionsByDateRange(
    int salonId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.transactions,
        queryParameters: {
          'salonId': salonId,
          'startDate': _formatDate(startDate),
          'endDate': _formatDate(endDate),
        },
      );
      return (response.data as List)
          .map((e) => Transaction.fromJson(e))
          .toList();
    } catch (e) {
      // Return empty list if API fails
      return [];
    }
  }

  // Get monthly report
  Future<Map<String, dynamic>> getMonthlyReport(
    int salonId,
    int year,
    int month,
  ) async {
    final response = await _dio.get(
      '${ApiEndpoints.transactionReport}/monthly',
      queryParameters: {'salonId': salonId, 'year': year, 'month': month},
    );
    return response.data;
  }

  // Get yearly report
  Future<Map<String, dynamic>> getYearlyReport(int salonId, int year) async {
    final response = await _dio.get(
      '${ApiEndpoints.transactionReport}/yearly',
      queryParameters: {'salonId': salonId, 'year': year},
    );
    return response.data;
  }

  // Helper method to format date for API
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
