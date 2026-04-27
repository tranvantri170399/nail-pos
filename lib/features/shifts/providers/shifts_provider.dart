// lib/features/shifts/providers/shifts_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/shift.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/shifts_repository.dart';

final shiftsRepositoryProvider = Provider<ShiftsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ShiftsRepository(apiClient.dio);
});

class ShiftsState {
  final Shift? currentShift;
  final bool isLoading;
  final String? error;

  ShiftsState({
    this.currentShift,
    this.isLoading = false,
    this.error,
  });

  ShiftsState copyWith({
    Shift? currentShift,
    bool? isLoading,
    String? error,
    bool clearShift = false,
    bool clearError = false,
  }) {
    return ShiftsState(
      currentShift: clearShift ? null : (currentShift ?? this.currentShift),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ShiftsNotifier extends StateNotifier<ShiftsState> {
  final ShiftsRepository _repo;
  final Ref _ref;

  ShiftsNotifier(this._repo, this._ref) : super(ShiftsState()) {
    _init();
  }

  void _init() {
    _ref.listen<AuthState>(authProvider, (_, next) {
      if (next is AuthAuthenticated) {
        loadCurrentShift(next.user.salonId ?? 1);
      } else {
        state = state.copyWith(clearShift: true);
      }
    });
    
    // Initial load
    final authState = _ref.read(authProvider);
    if (authState is AuthAuthenticated) {
      loadCurrentShift(authState.user.salonId ?? 1);
    }
  }

  Future<void> loadCurrentShift(int salonId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final shift = await _repo.getCurrentShift(salonId);
      state = state.copyWith(isLoading: false, currentShift: shift, clearShift: shift == null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> openShift(int salonId, double startingCash) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final shift = await _repo.openShift(salonId, startingCash);
      state = state.copyWith(isLoading: false, currentShift: shift);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> closeShift(double actualEndingCash, String? notes) async {
    if (state.currentShift == null) return false;
    
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final shift = await _repo.closeShift(state.currentShift!.id, actualEndingCash, notes);
      state = state.copyWith(isLoading: false, currentShift: shift);
      
      // Mở lại sau khi đóng để reset state, UI sẽ phản hồi
      loadCurrentShift(shift.salonId);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> recordCashMovement(String type, double amount, String? reason) async {
    if (state.currentShift == null) return false;
    
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.recordCashMovement(state.currentShift!.id, type, amount, reason);
      // Reload shift to get updated expected_ending_cash
      await loadCurrentShift(state.currentShift!.salonId);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final shiftsProvider = StateNotifierProvider<ShiftsNotifier, ShiftsState>((ref) {
  final repo = ref.watch(shiftsRepositoryProvider);
  return ShiftsNotifier(repo, ref);
});
