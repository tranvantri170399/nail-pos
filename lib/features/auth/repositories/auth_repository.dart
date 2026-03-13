// lib/features/auth/repositories/auth_repository.dart

import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/auth_response.dart';
import '../../../core/models/user_model.dart';
import '../../../core/utils/token_storage.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  // ── Login nhân viên (phone + PIN) ───────────────────────
  Future<AuthResponse> loginStaff(String phone, String pin) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.staffLogin,
        data: {'phone': phone, 'pin': pin},
      );
      final authResponse = AuthResponse.fromJson(response.data);
      await TokenStorage.saveAuth(authResponse.accessToken, authResponse.user);
      return authResponse;
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Đăng nhập thất bại';
      throw Exception(message);
    }
  }

  // ── Login chủ tiệm (phone + password) ──────────────────
  Future<AuthResponse> loginOwner(String phone, String password) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.ownerLogin,
        data: {'phone': phone, 'password': password},
      );
      final authResponse = AuthResponse.fromJson(response.data);
      await TokenStorage.saveAuth(authResponse.accessToken, authResponse.user);
      return authResponse;
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Đăng nhập thất bại';
      throw Exception(message);
    }
  }

  // ── Logout ──────────────────────────────────────────────
  Future<void> logout() async {
    await TokenStorage.clear();
  }

  // ── Kiểm tra đã login chưa ──────────────────────────────
  Future<bool> isLoggedIn() async {
    final token = await TokenStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  // ── Lấy user đang login ─────────────────────────────────
  Future<UserModel?> getCurrentUser() async {
    return await TokenStorage.getUser();
  }
}