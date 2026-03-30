// lib/features/appointment/repositories/appointment_repository.dart
import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/appointment.dart';
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
      final response = await _dio.get(
        ApiEndpoints.customerByPhone,
        queryParameters: {'phone': phone},
      );
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
}
