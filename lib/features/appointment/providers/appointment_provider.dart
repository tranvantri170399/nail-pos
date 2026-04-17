// lib/features/appointment/providers/appointment_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/appointment.dart';
import '../../../core/models/appointment_service.dart';
import '../../../core/api/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/appointment_repository.dart';

// Repository provider
final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AppointmentRepository(apiClient.dio);
});

// Provider lấy appointments theo ngày
final appointmentsByDateProvider =
    FutureProvider.family<List<Appointment>, String>((ref, date) async {
      final repo = ref.read(appointmentRepositoryProvider);
      return repo.getByDate(date);
    });

// Provider lấy tất cả appointments
final allAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final repo = ref.read(appointmentRepositoryProvider);
  return repo.getAll();
});

// State cho appointment operations
class AppointmentOperationState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const AppointmentOperationState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  AppointmentOperationState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return AppointmentOperationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class AppointmentNotifier extends StateNotifier<AppointmentOperationState> {
  final AppointmentRepository _repository;
  final Ref _ref;

  AppointmentNotifier(this._repository, this._ref)
    : super(const AppointmentOperationState());

  Future<void> createAppointment(Appointment appointment) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      await _repository.createAppointment(appointment);

      // Refresh appointments list
      _ref.invalidate(appointmentsByDateProvider(appointment.scheduledDate));
      _ref.invalidate(allAppointmentsProvider);

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Không thể tạo lịch hẹn: ${e.toString()}',
      );
    }
  }

  Future<void> createAppointmentWithServices(
    Appointment appointment,
    List<AppointmentService> services,
  ) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      await _repository.createAppointmentWithServices(
        appointment: appointment,
        services: services,
      );

      // Refresh appointments list
      _ref.invalidate(appointmentsByDateProvider(appointment.scheduledDate));
      _ref.invalidate(allAppointmentsProvider);

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Không thể tạo lịch hẹn: ${e.toString()}',
      );
    }
  }

  Future<void> updateStatus(
    int appointmentId,
    String status,
    String date,
  ) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      await _repository.updateStatus(appointmentId, status);
      _ref.invalidate(appointmentsByDateProvider(date));
      _ref.invalidate(allAppointmentsProvider);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Không thể cập nhật: ${e.toString()}',
      );
    }
  }

  Future<void> deleteAppointment(int appointmentId, String date) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      await _repository.deleteAppointment(appointmentId);
      _ref.invalidate(appointmentsByDateProvider(date));
      _ref.invalidate(allAppointmentsProvider);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Không thể xóa: ${e.toString()}',
      );
    }
  }

  Future<List<AppointmentService>> getAppointmentServices(
    int appointmentId,
  ) async {
    try {
      return await _repository.getAppointmentServices(appointmentId);
    } catch (e) {
      state = state.copyWith(error: 'Không thể tải dịch vụ: ${e.toString()}');
      return [];
    }
  }

  Future<Appointment> getAppointmentById(int id) async {
    try {
      return await _repository.getById(id);
    } catch (e) {
      state = state.copyWith(error: 'Không thể tải lịch hẹn: ${e.toString()}');
      rethrow;
    }
  }

  void reset() {
    state = const AppointmentOperationState();
  }

  void clearAllCache() {
    // Clear all appointment providers
    _ref.invalidate(allAppointmentsProvider);
    // Note: appointmentsByDateProvider will be invalidated when used with specific date
  }
}

// Provider cho appointment operations
final appointmentProvider =
    StateNotifierProvider<AppointmentNotifier, AppointmentOperationState>((
      ref,
    ) {
      final repository = ref.watch(appointmentRepositoryProvider);
      return AppointmentNotifier(repository, ref);
    });
