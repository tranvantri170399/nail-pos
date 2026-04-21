// lib/features/pos/repositories/pos_repository.dart

import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/staff.dart';
import '../../../core/models/service.dart';
import '../../../core/models/customer.dart';
import '../../../core/models/appointment.dart';
import '../../../core/models/transaction.dart';
import '../../../core/models/transaction_item.dart';

class PosRepository {
  final Dio _dio;

  PosRepository(this._dio);

  // ── Lấy danh sách nhân viên ─────────────────────────
  Future<List<Staff>> getStaffs(int salonId) async {
    final response = await _dio.get(
      ApiEndpoints.staffs,
      queryParameters: {'salonId': salonId}, // ← thêm dòng này
    );
    return (response.data as List).map((json) => Staff.fromJson(json)).toList();
  }

  // ── Lấy danh sách dịch vụ ───────────────────────────
  Future<List<Service>> getServices(int salonId) async {
    final response = await _dio.get(
      ApiEndpoints.services,
      queryParameters: {'salonId': salonId},
    );
    return (response.data as List)
        .map((json) => Service.fromJson(json))
        .toList();
  }

  // ── Tìm khách hàng theo SĐT ─────────────────────────
  Future<Customer> findCustomerByPhone(String phone) async {
    final response = await _dio.get('${ApiEndpoints.customerByPhone}/$phone');
    return Customer.fromJson(response.data);
  }

  // ── Tạo appointment + thanh toán ────────────────────
  Future<int> createAppointment(Appointment appointment) async {
    final response = await _dio.post(
      ApiEndpoints.appointments,
      data: appointment.toJson(),
    );
    return response.data['id'] as int;
  }

  // ── Tạo transaction sau khi appointment thành công ───────
  Future<Transaction> createTransaction(
    Transaction transaction, {
    List<Map<String, dynamic>>? itemsData,
  }) async {
    final data = itemsData != null
        ? transaction.toJsonWithItems(itemsData)
        : transaction.toJson();

    final response = await _dio.post(ApiEndpoints.transactions, data: data);
    return Transaction.fromJson(
      response.data,
    ); // ← trả về Transaction thay vì id
  }

  // ── Tạo transaction items cho mỗi dịch vụ ─────────────────
  Future<void> createTransactionItem(TransactionItem item) async {
    await _dio.post(ApiEndpoints.transactionItems, data: item.toJson());
  }

  // ── Tạo nhiều transaction items cùng lúc ───────────────────
  Future<void> createTransactionItems(List<TransactionItem> items) async {
    for (final item in items) {
      await createTransactionItem(item);
    }
  }
}
