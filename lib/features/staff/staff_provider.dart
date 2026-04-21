// lib/features/staff/staff_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/staff.dart';
import '../../core/providers/app_data_provider.dart';
import '../../core/api/api_client.dart';
import 'staff_repository.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StaffRepository(apiClient.dio);
});

// Provider cho staff list với loading/error state
final staffListAsyncProvider = FutureProvider.family<List<Staff>, int>((ref, salonId) async {
  final repository = ref.watch(staffRepositoryProvider);
  return await repository.getStaffs(salonId);
});

// State cho staff operations
class StaffOperationState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const StaffOperationState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  StaffOperationState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return StaffOperationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class StaffOperationNotifier extends StateNotifier<StaffOperationState> {
  final StaffRepository _repository;
  final Ref _ref;

  StaffOperationNotifier(this._repository, this._ref) : super(const StaffOperationState());

  Future<void> createStaff({
    required int salonId,
    required String name,
    required String phone,
    required String role,
    required double commissionRate,
    String? color,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await _repository.createStaff(
        salonId: salonId,
        name: name,
        phone: phone,
        role: role,
        commissionRate: commissionRate,
        color: color,
      );
      // Refresh app data
      await _ref.read(appDataProvider.notifier).loadAll(salonId);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateStaff({
    required int id,
    required String name,
    required String phone,
    required String role,
    required double commissionRate,
    String? color,
    required bool isActive,
    required int salonId,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await _repository.updateStaff(
        id: id,
        name: name,
        phone: phone,
        role: role,
        commissionRate: commissionRate,
        color: color,
        isActive: isActive,
      );
      // Refresh app data
      await _ref.read(appDataProvider.notifier).loadAll(salonId);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteStaff(int id, int salonId) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await _repository.deleteStaff(id);
      // Refresh app data
      await _ref.read(appDataProvider.notifier).loadAll(salonId);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() {
    state = const StaffOperationState();
  }
}

final staffOperationProvider = StateNotifierProvider<StaffOperationNotifier, StaffOperationState>((ref) {
  final repository = ref.watch(staffRepositoryProvider);
  return StaffOperationNotifier(repository, ref);
});
