import 'package:nail_pos/core/models/staff.dart';

class Appointment {
  final int id;
  final int? staffId;
  final int? customerId;
  final String scheduledDate;
  final String startTime;
  final String endTime;
  final int totalMinutes;
  final double totalPrice;
  final String status;
  final String? note;
  final Staff? staff;

  Appointment({
    required this.id,
    this.staffId,
    this.customerId,
    required this.scheduledDate,
    required this.startTime,
    required this.endTime,
    required this.totalMinutes,
    required this.totalPrice,
    required this.status,
    this.note,
    this.staff,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id:            json['id'],
    staffId:       json['staff_id'],
    customerId:    json['customer_id'],
    scheduledDate: json['scheduled_date'],
    startTime:     json['start_time'],
    endTime:       json['end_time'],
    totalMinutes:  json['total_minutes'],
    totalPrice:    double.parse(json['total_price'].toString()),
    status:        json['status'] ?? 'confirmed',
    note:          json['note'],
    staff:         json['staff'] != null ? Staff.fromJson(json['staff']) : null,
  );
}