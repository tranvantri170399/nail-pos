// lib/core/models/transaction_item.dart
class TransactionItem {
  final int id;
  final int transactionId;
  final int? serviceId;
  final int? staffId;
  final String serviceName;
  final double price;
  final double commissionRate;
  final double commissionAmount;
  
  // New Core POS Fields
  final String? discountType;
  final double discountValue;
  final double discountAmount;
  final String? discountReason;
  final double tipAmount;

  TransactionItem({
    required this.id,
    required this.transactionId,
    this.serviceId,
    this.staffId,
    required this.serviceName,
    required this.price,
    required this.commissionRate,
    required this.commissionAmount,
    this.discountType,
    this.discountValue = 0,
    this.discountAmount = 0,
    this.discountReason,
    this.tipAmount = 0,
  });

  // Constructor cho tạo transaction item mới (chưa có id)
  TransactionItem.create({
    required this.transactionId,
    this.serviceId,
    this.staffId,
    required this.serviceName,
    required this.price,
    required this.commissionRate,
    required this.commissionAmount,
    this.discountType,
    this.discountValue = 0,
    this.discountAmount = 0,
    this.discountReason,
    this.tipAmount = 0,
  }) : id = 0;

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      transactionId: int.tryParse(json['transactionId']?.toString() ?? '') ?? 0,
      serviceId: json['serviceId'] != null
          ? int.tryParse(json['serviceId'].toString())
          : null,
      staffId: json['staffId'] != null
          ? int.tryParse(json['staffId'].toString())
          : null,
      serviceName: json['serviceName'],
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0,
      commissionRate: double.tryParse(json['commissionRate']?.toString() ?? '') ?? 0,
      commissionAmount: double.tryParse(json['commissionAmount']?.toString() ?? '') ?? 0,
      discountType: json['discountType'],
      discountValue: double.tryParse(json['discountValue']?.toString() ?? '') ?? 0,
      discountAmount: double.tryParse(json['discountAmount']?.toString() ?? '') ?? 0,
      discountReason: json['discountReason'],
      tipAmount: double.tryParse(json['tipAmount']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'transaction_id': transactionId,
    'service_id': serviceId,
    'staff_id': staffId,
    'service_name': serviceName,
    'price': price,
    'commission_rate': commissionRate,
    'discount_type': discountType,
    'discount_value': discountValue,
    'discount_reason': discountReason,
    'tip_amount': tipAmount,
    // Không gửi commissionAmount, discountAmount - để backend tự tính
  };
}
