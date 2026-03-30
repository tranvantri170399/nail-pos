// lib/features/services/services_repository.dart
import 'package:dio/dio.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/service.dart';
import '../../core/models/service_category.dart';

class ServicesRepository {
  final Dio _dio;
  ServicesRepository(this._dio);

  // Lấy services grouped theo category
  Future<List<ServiceCategory>> getCategoriesWithServices(int salonId) async {
    final response = await _dio.get(
      ApiEndpoints.serviceCategories,
      queryParameters: {'salonId': salonId},
    );
    return (response.data as List)
        .map((e) => ServiceCategory.fromJson(e))
        .toList();
  }

  // Lấy tất cả services theo salon
  Future<List<Service>> getServicesBySalon(int salonId) async {
    final response = await _dio.get(
      ApiEndpoints.services,
      queryParameters: {'salonId': salonId},
    );
    return (response.data as List).map((e) => Service.fromJson(e)).toList();
  }

  // Tạo category mới
  Future<ServiceCategory> createCategory({
    required int salonId,
    required String name,
    required String color,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.serviceCategories,
      data: {
        'salonId': salonId,
        'name': name,
        'color': color,
        'sortOrder': 0,
        'isActive': true,
      },
    );
    return ServiceCategory.fromJson(response.data);
  }

  // Cập nhật category
  Future<ServiceCategory> updateCategory({
    required int id,
    required String name,
    required String color,
    required bool isActive,
  }) async {
    final response = await _dio.patch(
      ApiEndpoints.serviceCategoryById(id),
      data: {'name': name, 'color': color, 'isActive': isActive},
    );
    return ServiceCategory.fromJson(response.data);
  }

  // Xóa category
  Future<void> deleteCategory(int id) async {
    await _dio.delete(ApiEndpoints.serviceCategoryById(id));
  }

  // Tạo service mới
  Future<Service> createService({
    required int salonId,
    required int categoryId,
    required String name,
    required double price,
    required int durationMinutes,
    String? color,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.services,
      data: {
        'salonId': salonId,
        'categoryId': categoryId,
        'name': name,
        'price': price,
        'durationMinutes': durationMinutes,
        'color': color,
        'isActive': true,
      },
    );
    return Service.fromJson(response.data);
  }

  // Cập nhật service
  Future<Service> updateService({
    required int id,
    required String name,
    required double price,
    required int durationMinutes,
    String? color,
    required bool isActive,
  }) async {
    final response = await _dio.patch(
      ApiEndpoints.serviceById(id),
      data: {
        'name': name,
        'price': price,
        'durationMinutes': durationMinutes,
        'color': color,
        'isActive': isActive,
      },
    );
    return Service.fromJson(response.data);
  }

  // Xóa service
  Future<void> deleteService(int id) async {
    await _dio.delete(ApiEndpoints.serviceById(id));
  }
}
