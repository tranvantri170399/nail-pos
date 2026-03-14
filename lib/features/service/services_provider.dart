// lib/features/services/services_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/service_category.dart';
import '../../core/providers/app_data_provider.dart';
import 'services_repository.dart';

final servicesRepositoryProvider = Provider<ServicesRepository>((ref) {
  return ServicesRepository(ApiClient().dio);
});

// Provider lấy categories + services theo salonId
final categoriesWithServicesProvider = FutureProvider.family<List<ServiceCategory>, int>(
      (ref, salonId) async {
    return ref.watch(categoriesProvider);
  },
);