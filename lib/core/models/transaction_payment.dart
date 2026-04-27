// lib/core/models/transaction_payment.dart

class TransactionPayment {
  final int? id;
  final int? transactionId;
  final String paymentMethod;
  final double amount;
  final String? reference;
  final DateTime? createdAt;

  TransactionPayment({
    this.id,
    this.transactionId,
    required this.paymentMethod,
    required this.amount,
    this.reference,
    this.createdAt,
  });

  factory TransactionPayment.fromJson(Map<String, dynamic> json) {
    return TransactionPayment(
      id: int.tryParse(json['id']?.toString() ?? ''),
      transactionId: int.tryParse(json['transactionId']?.toString() ?? ''),
      paymentMethod: json['paymentMethod'] ?? 'cash',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      reference: json['reference'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'payment_method': paymentMethod,
    'amount': amount,
    'reference': reference,
  };
}
