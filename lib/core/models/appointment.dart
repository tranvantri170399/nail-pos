import 'package:nail_pos/core/models/customer.dart';
import 'package:nail_pos/core/models/staff.dart';

class Appointment {
  final int id;
  final int? customerId;
  final int? staffId;
  final String scheduledDate;
  final String startTime;
  final String endTime;
  final int totalMinutes;
  final double totalPrice;
  final String status;
  final String? note;
  final String source;
  final DateTime createdAt;
  final Staff? staff;
  final Customer? customer;

  Appointment({
    required this.id,
    this.customerId,
    this.staffId,
    required this.scheduledDate,
    required this.startTime,
    required this.endTime,
    required this.totalMinutes,
    required this.totalPrice,
    required this.status,
    this.note,
    required this.source,
    required this.createdAt,
    this.staff,
    this.customer,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      customerId: json['customer_id'],
      staffId: json['staff_id'],
      scheduledDate: json['scheduled_date'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      totalMinutes: json['total_minutes'],
      totalPrice: double.parse(json['total_price'].toString()),
      status: json['status'],
      note: json['note'],
      source: json['source'],
      createdAt: DateTime.parse(json['created_at']),
      staff: json['staff'] != null ? Staff.fromJson(json['staff']) : null,
      customer: json['customer'] != null
          ? Customer.fromJson(json['customer'])
          : null,
    );
  }

  factory Appointment.create({
    required int staffId,
    int? customerId,
    required String scheduledDate,
    required String startTime,
    required String endTime,
    required int totalMinutes,
    required double totalPrice,
    required String status,
    String? note,
  }) {
    return Appointment(
      id: 0, // Will be set by database
      customerId: customerId,
      staffId: staffId,
      scheduledDate: scheduledDate,
      startTime: startTime,
      endTime: endTime,
      totalMinutes: totalMinutes,
      totalPrice: totalPrice,
      status: status,
      note: note,
      source: 'pos',
      createdAt: DateTime.now(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'staff_id': staffId,
      'scheduled_date': scheduledDate,
      'start_time': startTime,
      'end_time': endTime,
      'total_minutes': totalMinutes,
      'total_price': totalPrice,
      'status': status,
      'note': note,
      'source': source,
    };
  }

  // Getters to parse hour and minute from startTime
  int get startHour {
    final parts = startTime.split(':');
    return int.parse(parts[0]);
  }

  int get startMinute {
    final parts = startTime.split(':');
    return int.parse(parts[1]);
  }

  // Getter for service summary (for display in timeline)
  String get serviceSummary {
    // This would need to be populated from the appointment services
    // For now, return a placeholder
    return 'Dịch vụ';
  }

  // Getter for customer name (for display in timeline)
  String get customerName {
    return customer?.name ?? 'Khách lẻ';
  }

  // Getter for staff name (for display in timeline)
  String get staffName {
    return staff?.name ?? 'Không có';
  }
}
