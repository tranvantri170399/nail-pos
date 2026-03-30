// lib/core/providers/app_data_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/salon.dart';
import '../../core/models/staff.dart';
import '../../core/models/service.dart';
import '../../core/models/service_category.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'package:dio/dio.dart';

// ════════════════════════════════════════════════════
// APP DATA STATE — Lưu toàn bộ data của tiệm
// ════════════════════════════════════════════════════
class AppDataState {
  final Salon? salon;
  final List<Staff> staffList;
  final List<ServiceCategory> categories; // kèm services bên trong
  final bool isLoading;
  final String? error;

  const AppDataState({
    this.salon,
    this.staffList = const [],
    this.categories = const [],
    this.isLoading = false,
    this.error,
  });

  bool get isReady => salon != null && !isLoading;
  bool get hasStaff => staffList.isNotEmpty;
  bool get hasCategories => categories.isNotEmpty;

  // Get all services from all categories
  List<Service> get allServices {
    return categories.expand((category) => category.services).toList();
  }

  AppDataState copyWith({
    Salon? salon,
    List<Staff>? staffList,
    List<ServiceCategory>? categories,
    bool? isLoading,
    String? error,
  }) {
    return AppDataState(
      salon: salon ?? this.salon,
      staffList: staffList ?? this.staffList,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ════════════════════════════════════════════════════
// APP DATA NOTIFIER
// ════════════════════════════════════════════════════
class AppDataNotifier extends StateNotifier<AppDataState> {
  final Dio _dio;
  bool _isCategoriesLoading = false;

  AppDataNotifier(this._dio) : super(const AppDataState());

  Future<void> loadAll(int salonId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Load song song tất cả
      final results = await Future.wait([
        _loadSalon(salonId),
        _loadStaffs(salonId),
        _loadCategories(salonId),
      ]);

      state = state.copyWith(
        salon: results[0] as Salon,
        staffList: results[1] as List<Staff>,
        categories: results[2] as List<ServiceCategory>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Không tải được dữ liệu: $e',
      );
    }
  }

  // Load riêng categories cho services
  Future<void> loadCategoriesOnly(int salonId) async {
    if (state.hasCategories || _isCategoriesLoading)
      return; // Đã có rồi hoặc đang load

    _isCategoriesLoading = true;
    try {
      final categories = await _loadCategories(salonId);
      // Chỉ update nếu loadAll chưa hoàn thành
      if (!state.isLoading) {
        state = state.copyWith(categories: categories);
      }
    } catch (e) {
      // Không update error, chỉ log
      print('Failed to load categories: $e');
    } finally {
      _isCategoriesLoading = false;
    }
  }

  Future<Salon> _loadSalon(int salonId) async {
    final res = await _dio.get('/salons/$salonId');
    print("***_loadSalon***" + res.toString());
    return Salon.fromJson(res.data);
  }

  Future<List<Staff>> _loadStaffs(int salonId) async {
    final res = await _dio.get(
      '/staffs',
      queryParameters: {'salonId': salonId},
    );
    print("***_loadStaffs***" + res.toString());
    return (res.data as List).map((e) => Staff.fromJson(e)).toList();
  }

  Future<List<ServiceCategory>> _loadCategories(int salonId) async {
    final res = await _dio.get(
      '/service-categories',
      queryParameters: {'salonId': salonId},
    );
    print("***_loadCategories***" + res.toString());
    return (res.data as List).map((e) => ServiceCategory.fromJson(e)).toList();
  }

  void clear() {
    state = const AppDataState();
    _isCategoriesLoading = false;
  }
}

final appDataProvider = StateNotifierProvider<AppDataNotifier, AppDataState>((
  ref,
) {
  final dio = ref.watch(apiClientProvider).dio;
  return AppDataNotifier(dio);
});

// Convenience providers — dùng trực tiếp trong UI
final salonProvider = Provider<Salon?>(
  (ref) => ref.watch(appDataProvider).salon,
);
final staffListProvider = Provider<List<Staff>>(
  (ref) => ref.watch(appDataProvider).staffList,
);
final categoriesProvider = Provider<List<ServiceCategory>>(
  (ref) => ref.watch(appDataProvider).categories,
);
final appDataReadyProvider = Provider<bool>(
  (ref) => ref.watch(appDataProvider).isReady,
);
