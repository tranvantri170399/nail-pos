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

  TransactionItem({
    required this.id,
    required this.transactionId,
    this.serviceId,
    this.staffId,
    required this.serviceName,
    required this.price,
    required this.commissionRate,
    required this.commissionAmount,
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
  }) : id = 0;

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: int.tryParse(json['id'].toString()) ?? 0,
      transactionId: int.tryParse(json['transactionId'].toString()) ?? 0,
      serviceId: json['serviceId'] != null
          ? int.tryParse(json['serviceId'].toString())
          : null,
      staffId: json['staffId'] != null
          ? int.tryParse(json['staffId'].toString())
          : null,
      serviceName: json['serviceName'],
      price: double.tryParse(json['price'].toString()) ?? 0,
      commissionRate: double.tryParse(json['commissionRate'].toString()) ?? 0,
      commissionAmount:
          double.tryParse(json['commissionAmount'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'transaction_id': transactionId,
    'service_id': serviceId,
    'staff_id': staffId,
    'service_name': serviceName,
    'price': price,
    'commission_rate': commissionRate,
    // Không gửi commissionAmount - để backend tự tính
  };
}
