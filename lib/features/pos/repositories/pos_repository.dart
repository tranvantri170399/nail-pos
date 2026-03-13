// lib/features/pos/repositories/pos_repository.dart

import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/staff.dart';
import '../../../core/models/service.dart';
import '../../../core/models/customer.dart';

class PosRepository {
  final Dio _dio;

  PosRepository(this._dio);

  // ── Lấy danh sách nhân viên ─────────────────────────
  Future<List<Staff>> getStaffs() async {
    final response = await _dio.get(ApiEndpoints.staffs);
    return (response.data as List)
        .map((json) => Staff.fromJson(json))
        .toList();
  }

  // ── Lấy danh sách dịch vụ ───────────────────────────
  Future<List<NailService>> getServices() async {
    final response = await _dio.get(ApiEndpoints.services);
    return (response.data as List)
        .map((json) => NailService.fromJson(json))
        .toList();
  }

  // ── Tìm khách hàng theo SĐT ─────────────────────────
  Future<Customer> findCustomerByPhone(String phone) async {
    final response = await _dio.get('${ApiEndpoints.customerByPhone}/$phone');
    return Customer.fromJson(response.data);
  }

  // ── Tạo appointment + thanh toán ────────────────────
  Future<int> createAppointment({
    required int staffId,
    int? customerId,
    required List<int> serviceIds,
    required double totalPrice,
    required int totalMinutes,
    String? note,
  }) async {
    final now = DateTime.now();
    final response = await _dio.post(
      ApiEndpoints.appointments,
      data: {
        'staff_id':       staffId,
        'customer_id':    customerId,
        'service_ids':    serviceIds,
        'scheduled_date': now.toIso8601String().split('T')[0],
        'start_time':     '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        'total_minutes':  totalMinutes,
        'total_price':    totalPrice,
        'status':         'done', // Thanh toán ngay → done
        'note':           note,
      },
    );
    return response.data['id'] as int;
  }
}
