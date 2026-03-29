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
final categoriesWithServicesProvider =
    Provider.family<AsyncValue<List<ServiceCategory>>, int>((ref, salonId) {
      final appData = ref.watch(appDataProvider);

      if (appData.hasCategories) {
        return AsyncValue.data(appData.categories);
      } else if (appData.isLoading) {
        return const AsyncValue.loading();
      } else if (appData.error != null) {
        return AsyncValue.error(appData.error!, StackTrace.current);
      } else {
        // Trigger load categories riêng nếu chưa có
        Future.microtask(
          () => ref.read(appDataProvider.notifier).loadCategoriesOnly(salonId),
        );
        return const AsyncValue.loading();
      }
    });
