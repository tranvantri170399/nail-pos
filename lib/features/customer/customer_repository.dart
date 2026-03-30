// lib/features/customer/customer_repository.dart
import 'package:dio/dio.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/customer.dart';

class CustomerRepository {
  final Dio _dio;
  CustomerRepository(this._dio);

  // Lấy danh sách customers theo salon
  Future<List<Customer>> getCustomers(int salonId) async {
    final response = await _dio.get(
      ApiEndpoints.customers,
      queryParameters: {'salonId': salonId},
    );
    return (response.data as List)
        .map((e) => Customer.fromJson(e))
        .toList();
  }

  // Tìm customer theo phone
  Future<Customer?> getCustomerByPhone(String phone) async {
    final response = await _dio.get(
      ApiEndpoints.customerByPhone,
      queryParameters: {'phone': phone},
    );
    if (response.data == null) return null;
    return Customer.fromJson(response.data);
  }

  // Tạo customer mới
  Future<Customer> createCustomer({
    required int salonId,
    required String name,
    required String phone,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.customers,
      data: {
        'salonId': salonId,
        'name': name,
        'phone': phone,
      },
    );
    return Customer.fromJson(response.data);
  }

  // Cập nhật customer
  Future<Customer> updateCustomer({
    required int id,
    required String name,
    required String phone,
  }) async {
    final response = await _dio.patch(
      '${ApiEndpoints.customers}/$id',
      data: {
        'name': name,
        'phone': phone,
      },
    );
    return Customer.fromJson(response.data);
  }

  // Xóa customer
  Future<void> deleteCustomer(int id) async {
    await _dio.delete('${ApiEndpoints.customers}/$id');
  }
}
