// lib/core/models/cash_movement.dart

class CashMovement {
  final int id;
  final int shiftId;
  final int? performedBy;
  final String type; // 'pay_in', 'pay_out', 'safe_drop'
  final double amount;
  final String? reason;
  final DateTime createdAt;

  CashMovement({
    required this.id,
    required this.shiftId,
    this.performedBy,
    required this.type,
    required this.amount,
    this.reason,
    required this.createdAt,
  });

  factory CashMovement.fromJson(Map<String, dynamic> json) {
    return CashMovement(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      shiftId: int.tryParse(json['shift_id']?.toString() ?? '') ?? 0,
      performedBy: json['performed_by'] != null ? int.tryParse(json['performed_by'].toString()) : null,
      type: json['type'] ?? 'pay_in',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      reason: json['reason'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }
}
