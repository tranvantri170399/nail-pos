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

  // Constructor cho tạo transaction mới (chưa có id)
  Transaction.create({
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
  }) : id = 0;

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: int.tryParse(json['id'].toString()) ?? 0,
      appointmentId: int.tryParse(json['appointmentId'].toString()) ?? 0,
      salonId: int.tryParse(json['salonId'].toString()) ?? 0,
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

  Map<String, dynamic> toJson() => {
    'appointment_id': appointmentId,
    'salon_id': salonId,
    'subtotal': subtotal,
    'discount_amount': discountAmount,
    'tip_amount': tipAmount,
    'tax_amount': taxAmount,
    // Không gửi total_amount - để backend tự tính
    'payment_method': paymentMethod,
    'status': status, // Backend sẽ override thành 'paid'
    'note': note,
    'paid_at': paidAt?.toIso8601String(), // Backend sẽ set new Date()
  };

  // Method để tạo JSON với items data
  Map<String, dynamic> toJsonWithItems(List<Map<String, dynamic>> itemsData) =>
      {
        'appointment_id': appointmentId,
        'salon_id': salonId,
        'subtotal': subtotal,
        'discount_amount': discountAmount,
        'tip_amount': tipAmount,
        'tax_amount': taxAmount,
        'payment_method': paymentMethod,
        'status': status, // Backend sẽ override thành 'paid'
        'note': note,
        'paid_at': paidAt?.toIso8601String(), // Backend sẽ set new Date()
        'items': itemsData, // Gửi items data thô
      };
}
