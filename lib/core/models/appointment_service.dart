import 'package:intl/intl.dart';
import 'package:nail_pos/core/models/service.dart';

class AppointmentService {
  final int id;
  final int appointmentId;
  final int serviceId;
  final double price;
  final int durationMinutes;
  final Service? service;

  AppointmentService({
    required this.id,
    required this.appointmentId,
    required this.serviceId,
    required this.price,
    required this.durationMinutes,
    this.service,
  });

  factory AppointmentService.fromJson(Map<String, dynamic> json) {
    return AppointmentService(
      id: json['id'] ?? 0,
      appointmentId: json['appointmentId'] ?? 0,
      serviceId: json['serviceId'] ?? 0,
      price: double.parse((json['price'] ?? 0).toString()),
      durationMinutes: json['durationMinutes'] ?? 0,
      service: json['service'] != null
          ? Service.fromJson(json['service'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceId,
      'price': price,
      'durationMinutes': durationMinutes,
    };
  }

  // Getter để lấy tên service
  String get serviceName {
    return service?.name ?? 'Dịch vụ không xác định';
  }

  // Getter để lấy giá hiển thị
  String get formattedPrice {
    final vnd = NumberFormat('#,###', 'vi_VN');
    return '${vnd.format(price)}đ';
  }

  // Getter để lấy thời lượng hiển thị
  String get formattedDuration {
    return '$durationMinutes phút';
  }
}
