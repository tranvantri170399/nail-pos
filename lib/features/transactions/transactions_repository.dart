// lib/features/transactions/transactions_repository.dart
import 'package:dio/dio.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/transaction.dart';
import '../../core/models/transaction_item.dart';

import '../../core/models/transaction_payment.dart';

class CreateTransactionDto {
  final int? appointmentId;
  final int salonId;
  final int? customerId;
  final int? shiftId;
  
  final double subtotal;
  final String? discountType;
  final double? discountValue;
  final double? discountAmount;
  final String? discountReason;
  
  final double tipAmount;
  final double taxAmount;
  
  final String paymentMethod;
  final List<TransactionPayment>? payments;
  final String? note;
  final List<TransactionItem> items;

  CreateTransactionDto({
    this.appointmentId,
    required this.salonId,
    this.customerId,
    this.shiftId,
    required this.subtotal,
    this.discountType,
    this.discountValue,
    this.discountAmount,
    this.discountReason,
    this.tipAmount = 0,
    this.taxAmount = 0,
    required this.paymentMethod,
    this.payments,
    this.note,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'appointment_id': appointmentId,
    'salon_id': salonId,
    'customer_id': customerId,
    'shift_id': shiftId,
    'subtotal': subtotal,
    'discount_type': discountType,
    'discount_value': discountValue,
    'discount_amount': discountAmount,
    'discount_reason': discountReason,
    'tip_amount': tipAmount,
    'tax_amount': taxAmount,
    'payment_method': paymentMethod,
    if (payments != null) 'payments': payments!.map((p) => p.toJson()).toList(),
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
      queryParameters: {
        'salonId': salonId,
        ...?(date == null ? null : {'date': date}),
      },
    );
    return (response.data['data'] as List).map((e) => Transaction.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getDailyReport(int salonId, String date) async {
    final response = await _dio.get(
      ApiEndpoints.transactionReport,
      queryParameters: {'salonId': salonId, 'date': date},
    );
    return response.data;
  }
}
