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
    return (response.data as List)
        .map((e) => Service.fromJson(e))
        .toList();
  }
}