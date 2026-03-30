// lib/features/staff/staff_repository.dart
import 'package:dio/dio.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/staff.dart';

class StaffRepository {
  final Dio _dio;
  StaffRepository(this._dio);

  // Lấy danh sách staff theo salon
  Future<List<Staff>> getStaffs(int salonId) async {
    final response = await _dio.get(
      ApiEndpoints.staffs,
      queryParameters: {'salonId': salonId},
    );
    return (response.data as List)
        .map((e) => Staff.fromJson(e))
        .toList();
  }

  // Tạo staff mới
  Future<Staff> createStaff({
    required int salonId,
    required String name,
    required String phone,
    required String role,
    required double commissionRate,
    String? color,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.staffs,
      data: {
        'salonId': salonId,
        'name': name,
        'phone': phone,
        'role': role,
        'commissionRate': commissionRate,
        'color': color,
        'isActive': true,
      },
    );
    return Staff.fromJson(response.data);
  }

  // Cập nhật staff
  Future<Staff> updateStaff({
    required int id,
    required String name,
    required String phone,
    required String role,
    required double commissionRate,
    String? color,
    required bool isActive,
  }) async {
    final response = await _dio.patch(
      '${ApiEndpoints.staffs}/$id',
      data: {
        'name': name,
        'phone': phone,
        'role': role,
        'commissionRate': commissionRate,
        'color': color,
        'isActive': isActive,
      },
    );
    return Staff.fromJson(response.data);
  }

  // Xóa staff
  Future<void> deleteStaff(int id) async {
    await _dio.delete('${ApiEndpoints.staffs}/$id');
  }
}
