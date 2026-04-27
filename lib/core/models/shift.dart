// lib/core/models/shift.dart

class Shift {
  final int id;
  final int salonId;
  final int? openedBy;
  final int? closedBy;
  final DateTime openedAt;
  final DateTime? closedAt;
  final double startingCash;
  final double? expectedEndingCash;
  final double? actualEndingCash;
  final double? difference;
  final String status;
  final String? notes;

  Shift({
    required this.id,
    required this.salonId,
    this.openedBy,
    this.closedBy,
    required this.openedAt,
    this.closedAt,
    required this.startingCash,
    this.expectedEndingCash,
    this.actualEndingCash,
    this.difference,
    required this.status,
    this.notes,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      salonId: int.tryParse(json['salon_id']?.toString() ?? '') ?? 0,
      openedBy: json['opened_by'] != null ? int.tryParse(json['opened_by'].toString()) : null,
      closedBy: json['closed_by'] != null ? int.tryParse(json['closed_by'].toString()) : null,
      openedAt: DateTime.parse(json['opened_at']).toLocal(),
      closedAt: json['closed_at'] != null ? DateTime.parse(json['closed_at']).toLocal() : null,
      startingCash: double.tryParse(json['starting_cash']?.toString() ?? '') ?? 0,
      expectedEndingCash: json['expected_ending_cash'] != null ? double.tryParse(json['expected_ending_cash'].toString()) : null,
      actualEndingCash: json['actual_ending_cash'] != null ? double.tryParse(json['actual_ending_cash'].toString()) : null,
      difference: json['difference'] != null ? double.tryParse(json['difference'].toString()) : null,
      status: json['status'] ?? 'open',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'salon_id': salonId,
    'opened_by': openedBy,
    'closed_by': closedBy,
    'opened_at': openedAt.toIso8601String(),
    'closed_at': closedAt?.toIso8601String(),
    'starting_cash': startingCash,
    'expected_ending_cash': expectedEndingCash,
    'actual_ending_cash': actualEndingCash,
    'difference': difference,
    'status': status,
    'notes': notes,
  };
}
