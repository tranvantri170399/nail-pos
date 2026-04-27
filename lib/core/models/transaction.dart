// lib/core/models/transaction.dart
import 'transaction_item.dart';
import 'transaction_payment.dart';

class Transaction {
  final int id;
  final int? appointmentId;
  final int salonId;
  final int? shiftId;
  final int? customerId;
  
  final double subtotal;
  final double discountAmount;
  final double tipAmount;
  final double taxAmount;
  final double totalAmount;
  
  final String? discountType;
  final double discountValue;
  final String? discountReason;
  final double taxRate;

  final String paymentMethod;
  final String status;
  final String? note;
  final DateTime? paidAt;
  final List<TransactionItem> items;
  final List<TransactionPayment> payments;

  Transaction({
    required this.id,
    this.appointmentId,
    required this.salonId,
    this.shiftId,
    this.customerId,
    required this.subtotal,
    required this.discountAmount,
    required this.tipAmount,
    required this.taxAmount,
    required this.totalAmount,
    this.discountType,
    this.discountValue = 0,
    this.discountReason,
    this.taxRate = 0,
    required this.paymentMethod,
    required this.status,
    this.note,
    this.paidAt,
    this.items = const [],
    this.payments = const [],
  });

  // Constructor cho tạo transaction mới (chưa có id)
  Transaction.create({
    this.appointmentId,
    required this.salonId,
    this.shiftId,
    this.customerId,
    required this.subtotal,
    required this.discountAmount,
    required this.tipAmount,
    required this.taxAmount,
    required this.totalAmount,
    this.discountType,
    this.discountValue = 0,
    this.discountReason,
    this.taxRate = 0,
    required this.paymentMethod,
    required this.status,
    this.note,
    this.paidAt,
    this.items = const [],
    this.payments = const [],
  }) : id = 0;

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final subtotal = double.tryParse(json['subtotal']?.toString() ?? '') ?? 0;
    final discountAmount = double.tryParse(json['discountAmount']?.toString() ?? '') ?? 0;
    final tipAmount = double.tryParse(json['tipAmount']?.toString() ?? '') ?? 0;
    final taxAmount = double.tryParse(json['taxAmount']?.toString() ?? '') ?? 0;
    final backendTotal = double.tryParse(json['totalAmount']?.toString() ?? '') ?? 0;
    
    // Nếu backend bỏ qua tip khi tính total, tự tính lại
    final expectedTotal = subtotal + tipAmount + taxAmount - discountAmount;
    final totalAmount = (backendTotal > 0 && (backendTotal - expectedTotal).abs() < 1)
        ? backendTotal
        : expectedTotal;

    return Transaction(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      appointmentId: json['appointmentId'] != null ? int.tryParse(json['appointmentId'].toString()) : null,
      salonId: int.tryParse(json['salonId']?.toString() ?? '') ?? 0,
      shiftId: json['shiftId'] != null ? int.tryParse(json['shiftId'].toString()) : null,
      customerId: json['customerId'] != null ? int.tryParse(json['customerId'].toString()) : null,
      subtotal: subtotal,
      discountAmount: discountAmount,
      tipAmount: tipAmount,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      discountType: json['discountType'],
      discountValue: double.tryParse(json['discountValue']?.toString() ?? '') ?? 0,
      discountReason: json['discountReason'],
      taxRate: double.tryParse(json['taxRate']?.toString() ?? '') ?? 0,
      paymentMethod: json['paymentMethod'] ?? 'cash',
      status: json['status'] ?? 'pending',
      note: json['note'],
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt']).toLocal()
          : null,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((i) => TransactionItem.fromJson(i))
          .toList(),
      payments: (json['payments'] as List<dynamic>? ?? [])
          .map((p) => TransactionPayment.fromJson(p))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'appointment_id': appointmentId,
    'salon_id': salonId,
    'shift_id': shiftId,
    'customer_id': customerId,
    'subtotal': subtotal,
    'discount_type': discountType,
    'discount_value': discountValue,
    'discount_reason': discountReason,
    'tip_amount': tipAmount,
    'tax_amount': taxAmount, // client gửi để display, backend auto-calculate
    'payment_method': paymentMethod,
    'status': status,
    'note': note,
  };

  // Method để tạo JSON với items và payments data
  Map<String, dynamic> toJsonWithItems(List<Map<String, dynamic>> itemsData, {List<Map<String, dynamic>>? paymentsData}) =>
      {
        ...toJson(),
        'items': itemsData, // Gửi items data thô
        if (paymentsData != null) 'payments': paymentsData,
      };
}
