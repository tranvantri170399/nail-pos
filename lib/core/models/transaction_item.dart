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

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'],
      transactionId: json['transactionId'],
      serviceId: json['serviceId'],
      staffId: json['staffId'],
      serviceName: json['serviceName'],
      price: double.tryParse(json['price'].toString()) ?? 0,
      commissionRate: double.tryParse(json['commissionRate'].toString()) ?? 0,
      commissionAmount: double.tryParse(json['commissionAmount'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'serviceId': serviceId,
    'staffId': staffId,
    'serviceName': serviceName,
    'price': price,
    'commissionRate': commissionRate,
  };
}