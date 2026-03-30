// lib/features/appointment/repositories/appointment_repository.dart
import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/appointment.dart';
import '../../../core/models/appointment_service.dart';
import '../../../core/models/customer.dart';

class AppointmentRepository {
  final Dio _dio;
  AppointmentRepository(this._dio);

  // Lấy appointments theo ngày
  Future<List<Appointment>> getByDate(String date) async {
    final response = await _dio.get(
      '${ApiEndpoints.appointments}/by-date',
      queryParameters: {'date': date},
    );
    return (response.data as List).map((e) => Appointment.fromJson(e)).toList();
  }

  // Lấy tất cả appointments
  Future<List<Appointment>> getAll() async {
    final response = await _dio.get(ApiEndpoints.appointments);
    return (response.data as List).map((e) => Appointment.fromJson(e)).toList();
  }

  // Tìm customer theo phone
  Future<Customer?> findCustomerByPhone(String phone) async {
    try {
      final response = await _dio.get('${ApiEndpoints.customerByPhone}/$phone');
      if (response.data == null) return null;
      return Customer.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  // Tạo appointment mới
  Future<Appointment> createAppointment(Appointment appointment) async {
    final response = await _dio.post(
      ApiEndpoints.appointments,
      data: appointment.toJson(),
    );
    return Appointment.fromJson(response.data);
  }

  // Cập nhật status
  Future<Appointment> updateStatus(int id, String status) async {
    final response = await _dio.patch(
      '${ApiEndpoints.appointments}/$id/status',
      data: {'status': status},
    );
    return Appointment.fromJson(response.data);
  }

  // Xóa appointment
  Future<void> deleteAppointment(int id) async {
    await _dio.delete('${ApiEndpoints.appointments}/$id');
  }

  // Lấy appointment theo ID
  Future<Appointment> getById(int id) async {
    final response = await _dio.get('${ApiEndpoints.appointments}/$id');
    return Appointment.fromJson(response.data);
  }

  // Lấy appointment services theo appointment id
  Future<List<AppointmentService>> getAppointmentServices(
    int appointmentId,
  ) async {
    final response = await _dio.get(
      '${ApiEndpoints.appointments}/$appointmentId/services',
    );
    return (response.data as List)
        .map((e) => AppointmentService.fromJson(e))
        .toList();
  }

  // Tạo appointment với services
  Future<Appointment> createAppointmentWithServices({
    required Appointment appointment,
    required List<AppointmentService> services,
  }) async {
    final data = {
      ...appointment.toJson(),
      'appointmentServices': services.map((s) => s.toJson()).toList(),
    };

    final response = await _dio.post(ApiEndpoints.appointments, data: data);
    return Appointment.fromJson(response.data);
  }
}
