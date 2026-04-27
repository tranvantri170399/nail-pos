// lib/features/shifts/repositories/shifts_repository.dart

import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/shift.dart';
import '../../../core/models/cash_movement.dart';

class ShiftsRepository {
  final Dio _dio;
  
  ShiftsRepository(this._dio);

  Future<Shift?> getCurrentShift(int salonId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.shiftCurrent,
        queryParameters: {'salonId': salonId},
      );
      if (response.data == null || response.data == '') return null;
      return Shift.fromJson(response.data);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        return null; // No active shift
      }
      rethrow;
    }
  }

  Future<Shift> openShift(int salonId, double startingCash) async {
    final response = await _dio.post(
      ApiEndpoints.shiftOpen,
      data: {
        'salonId': salonId,
        'starting_cash': startingCash,
      },
    );
    return Shift.fromJson(response.data);
  }

  Future<Shift> closeShift(int shiftId, double actualEndingCash, String? notes) async {
    final response = await _dio.post(
      ApiEndpoints.shiftClose(shiftId),
      data: {
        'actual_ending_cash': actualEndingCash,
        'notes': notes,
      },
    );
    return Shift.fromJson(response.data);
  }

  Future<CashMovement> recordCashMovement(int shiftId, String type, double amount, String? reason) async {
    final response = await _dio.post(
      ApiEndpoints.shiftCashMovement(shiftId),
      data: {
        'type': type,
        'amount': amount,
        'reason': reason,
      },
    );
    return CashMovement.fromJson(response.data);
  }
}
