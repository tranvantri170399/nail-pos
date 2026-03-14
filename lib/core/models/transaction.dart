// lib/core/models/transaction.dart
import 'transaction_item.dart';

class Transaction {
  final int id;
  final int appointmentId;
  final int salonId;
  final double subtotal;
  final double discountAmount;
  final double tipAmount;
  final double taxAmount;
  final double totalAmount;
  final String paymentMethod;
  final String status;
  final String? note;
  final DateTime? paidAt;
  final List<TransactionItem> items;

  Transaction({
    required this.id,
    required this.appointmentId,
    required this.salonId,
    required this.subtotal,
    required this.discountAmount,
    required this.tipAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    this.note,
    this.paidAt,
    this.items = const [],
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      appointmentId: json['appointmentId'],
      salonId: json['salonId'],
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0,
      discountAmount: double.tryParse(json['discountAmount'].toString()) ?? 0,
      tipAmount: double.tryParse(json['tipAmount'].toString()) ?? 0,
      taxAmount: double.tryParse(json['taxAmount'].toString()) ?? 0,
      totalAmount: double.tryParse(json['totalAmount'].toString()) ?? 0,
      paymentMethod: json['paymentMethod'] ?? 'cash',
      status: json['status'] ?? 'pending',
      note: json['note'],
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((i) => TransactionItem.fromJson(i))
          .toList(),
    );
  }
}