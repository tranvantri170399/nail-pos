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
        // Add timeout to prevent infinite loading
        Future.delayed(const Duration(seconds: 5), () {
          if (!appData.hasCategories) {
            // Force trigger loadCategoriesOnly if still loading after 5 seconds
            ref.read(appDataProvider.notifier).loadCategoriesOnly(salonId);
          }
        });
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

// State cho service operations
class ServiceOperationState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const ServiceOperationState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  ServiceOperationState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return ServiceOperationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class ServiceOperationNotifier extends StateNotifier<ServiceOperationState> {
  final ServicesRepository _repository;
  final Ref _ref;

  ServiceOperationNotifier(this._repository, this._ref)
    : super(const ServiceOperationState());

  // Category operations
  Future<void> createCategory({
    required int salonId,
    required String name,
    required String color,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await _repository.createCategory(
        salonId: salonId,
        name: name,
        color: color,
      );
      await _ref.read(appDataProvider.notifier).loadAll(salonId);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateCategory({
    required int id,
    required String name,
    required String color,
    required bool isActive,
    required int salonId,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await _repository.updateCategory(
        id: id,
        name: name,
        color: color,
        isActive: isActive,
      );
      await _ref.read(appDataProvider.notifier).loadAll(salonId);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteCategory(int id, int salonId) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await _repository.deleteCategory(id);
      await _ref.read(appDataProvider.notifier).loadAll(salonId);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Service operations
  Future<void> createService({
    required int salonId,
    required int categoryId,
    required String name,
    required double price,
    required int durationMinutes,
    String? color,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await _repository.createService(
        salonId: salonId,
        categoryId: categoryId,
        name: name,
        price: price,
        durationMinutes: durationMinutes,
        color: color,
      );
      await _ref.read(appDataProvider.notifier).loadAll(salonId);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateService({
    required int id,
    required String name,
    required double price,
    required int durationMinutes,
    String? color,
    required bool isActive,
    required int salonId,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await _repository.updateService(
        id: id,
        name: name,
        price: price,
        durationMinutes: durationMinutes,
        color: color,
        isActive: isActive,
      );
      await _ref.read(appDataProvider.notifier).loadAll(salonId);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteService(int id, int salonId) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await _repository.deleteService(id);
      await _ref.read(appDataProvider.notifier).loadAll(salonId);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() {
    state = const ServiceOperationState();
  }
}

final serviceOperationProvider =
    StateNotifierProvider<ServiceOperationNotifier, ServiceOperationState>((
      ref,
    ) {
      final repository = ref.watch(servicesRepositoryProvider);
      return ServiceOperationNotifier(repository, ref);
    });
