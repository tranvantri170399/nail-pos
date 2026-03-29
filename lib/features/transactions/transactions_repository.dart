// lib/features/transactions/transactions_repository.dart
import 'package:dio/dio.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/transaction.dart';
import '../../core/models/transaction_item.dart';

class CreateTransactionDto {
  final int appointmentId;
  final int salonId;
  final double subtotal;
  final double discountAmount;
  final double tipAmount;
  final double taxAmount;
  final String paymentMethod;
  final String? note;
  final List<TransactionItem> items;

  CreateTransactionDto({
    required this.appointmentId,
    required this.salonId,
    required this.subtotal,
    this.discountAmount = 0,
    this.tipAmount = 0,
    this.taxAmount = 0,
    required this.paymentMethod,
    this.note,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'appointmentId': appointmentId,
    'salonId': salonId,
    'subtotal': subtotal,
    'discountAmount': discountAmount,
    'tipAmount': tipAmount,
    'taxAmount': taxAmount,
    'paymentMethod': paymentMethod,
    'note': note,
    'items': items.map((i) => i.toJson()).toList(),
  };
}

class TransactionsRepository {
  final Dio _dio;
  TransactionsRepository(this._dio);

  Future<Transaction> create(CreateTransactionDto dto) async {
    final response = await _dio.post(
      ApiEndpoints.transactions,
      data: dto.toJson(),
    );
    return Transaction.fromJson(response.data);
  }

  Future<List<Transaction>> getBySalon(int salonId, {String? date}) async {
    final response = await _dio.get(
      ApiEndpoints.transactions,
      queryParameters: {'salonId': salonId, if (date != null) 'date': ?date},
    );
    return (response.data as List).map((e) => Transaction.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getDailyReport(int salonId, String date) async {
    final response = await _dio.get(
      ApiEndpoints.transactionReport,
      queryParameters: {'salonId': salonId, 'date': date},
    );
    return response.data;
  }
}
