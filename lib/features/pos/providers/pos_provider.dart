// lib/features/pos/providers/pos_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/staff.dart';
import '../../../core/models/service.dart';
import '../../../core/models/customer.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/pos_repository.dart';
import '../../../core/api/api_client.dart';

// ════════════════════════════════════════════════════
// POS STATE — Toàn bộ trạng thái màn hình POS
// ════════════════════════════════════════════════════

class PosState {
  // Dữ liệu từ API
  final List<Staff> staffList;
  final List<NailService> serviceList;

  // Lựa chọn hiện tại
  final Staff? selectedStaff;
  final List<NailService> selectedServices;
  final Customer? selectedCustomer;

  // UI state
  final bool isLoadingStaffs;
  final bool isLoadingServices;
  final bool isSearchingCustomer;
  final bool isCheckingOut;
  final String? error;
  final String? checkoutSuccess; // Mã hoá đơn sau khi thanh toán

  const PosState({
    this.staffList = const [],
    this.serviceList = const [],
    this.selectedStaff,
    this.selectedServices = const [],
    this.selectedCustomer,
    this.isLoadingStaffs = false,
    this.isLoadingServices = false,
    this.isSearchingCustomer = false,
    this.isCheckingOut = false,
    this.error,
    this.checkoutSuccess,
  });

  // ── Tính tổng tiền ──────────────────────────────────
  double get totalPrice =>
      selectedServices.fold(0, (sum, s) => sum + s.price);

  // ── Tính tổng thời gian ─────────────────────────────
  int get totalMinutes =>
      selectedServices.fold(0, (sum, s) => sum + s.durationMinutes);

  // ── Có thể thanh toán chưa ──────────────────────────
  bool get canCheckout =>
      selectedStaff != null && selectedServices.isNotEmpty;

  // ── CopyWith để update state ─────────────────────────
  PosState copyWith({
    List<Staff>? staffList,
    List<NailService>? serviceList,
    Staff? selectedStaff,
    List<NailService>? selectedServices,
    Customer? selectedCustomer,
    bool? isLoadingStaffs,
    bool? isLoadingServices,
    bool? isSearchingCustomer,
    bool? isCheckingOut,
    String? error,
    String? checkoutSuccess,
    bool clearStaff = false,
    bool clearCustomer = false,
    bool clearError = false,
    bool clearCheckout = false,
  }) {
    return PosState(
      staffList:           staffList ?? this.staffList,
      serviceList:         serviceList ?? this.serviceList,
      selectedStaff:       clearStaff ? null : (selectedStaff ?? this.selectedStaff),
      selectedServices:    selectedServices ?? this.selectedServices,
      selectedCustomer:    clearCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
      isLoadingStaffs:     isLoadingStaffs ?? this.isLoadingStaffs,
      isLoadingServices:   isLoadingServices ?? this.isLoadingServices,
      isSearchingCustomer: isSearchingCustomer ?? this.isSearchingCustomer,
      isCheckingOut:       isCheckingOut ?? this.isCheckingOut,
      error:               clearError ? null : (error ?? this.error),
      checkoutSuccess:     clearCheckout ? null : (checkoutSuccess ?? this.checkoutSuccess),
    );
  }
}

// ════════════════════════════════════════════════════
// POS NOTIFIER — Xử lý logic
// ════════════════════════════════════════════════════

class PosNotifier extends StateNotifier<PosState> {
  final PosRepository _repo;

  PosNotifier(this._repo) : super(const PosState()) {
    loadInitialData();
  }

  // ── Load staffs + services khi mở màn hình ──────────
  Future<void> loadInitialData() async {
    state = state.copyWith(isLoadingStaffs: true, isLoadingServices: true);
    try {
      final results = await Future.wait([
        _repo.getStaffs(),
        _repo.getServices(),
      ]);
      state = state.copyWith(
        staffList:         results[0] as List<Staff>,
        serviceList:       results[1] as List<NailService>,
        isLoadingStaffs:   false,
        isLoadingServices: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingStaffs:   false,
        isLoadingServices: false,
        error:             'Không tải được dữ liệu: $e',
      );
    }
  }

  // ── Chọn thợ ────────────────────────────────────────
  void selectStaff(Staff staff) {
    // Toggle: bấm lại thì bỏ chọn
    if (state.selectedStaff?.id == staff.id) {
      state = state.copyWith(clearStaff: true);
    } else {
      state = state.copyWith(selectedStaff: staff);
    }
  }

  // ── Chọn / bỏ chọn dịch vụ ──────────────────────────
  void toggleService(NailService service) {
    final current = List<NailService>.from(state.selectedServices);
    final index = current.indexWhere((s) => s.id == service.id);
    if (index >= 0) {
      current.removeAt(index); // Bỏ chọn
    } else {
      current.add(service);    // Thêm vào
    }
    state = state.copyWith(selectedServices: current);
  }

  // ── Tìm khách hàng theo SĐT ─────────────────────────
  Future<void> searchCustomer(String phone) async {
    if (phone.length < 9) return;
    state = state.copyWith(isSearchingCustomer: true, clearError: true);
    try {
      final customer = await _repo.findCustomerByPhone(phone);
      state = state.copyWith(
        selectedCustomer:    customer,
        isSearchingCustomer: false,
      );
    } catch (e) {
      // Khách mới — chưa có trong hệ thống
      state = state.copyWith(
        isSearchingCustomer: false,
        clearCustomer:       true,
      );
    }
  }

  // ── Xoá khách hàng đã chọn ──────────────────────────
  void clearCustomer() {
    state = state.copyWith(clearCustomer: true);
  }

  // ── Thanh toán ───────────────────────────────────────
  Future<void> checkout({String? note}) async {
    if (!state.canCheckout) return;
    state = state.copyWith(isCheckingOut: true, clearError: true);
    try {
      final appointmentId = await _repo.createAppointment(
        staffId:    state.selectedStaff!.id,
        customerId: state.selectedCustomer?.id,
        serviceIds: state.selectedServices.map((s) => s.id).toList(),
        totalPrice: state.totalPrice,
        totalMinutes: state.totalMinutes,
        note:       note,
      );
      state = state.copyWith(
        isCheckingOut:   false,
        checkoutSuccess: '#$appointmentId',
      );
    } catch (e) {
      state = state.copyWith(
        isCheckingOut: false,
        error:         'Thanh toán thất bại: $e',
      );
    }
  }

  // ── Reset sau khi thanh toán xong ───────────────────
  void resetOrder() {
    state = PosState(
      staffList:   state.staffList,   // Giữ lại data đã load
      serviceList: state.serviceList,
    );
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ════════════════════════════════════════════════════
// PROVIDERS
// ════════════════════════════════════════════════════

final posRepositoryProvider = Provider<PosRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PosRepository(apiClient.dio);
});

final posProvider = StateNotifierProvider<PosNotifier, PosState>((ref) {
  final repo = ref.watch(posRepositoryProvider);
  return PosNotifier(repo);
});

// Convenience providers
final selectedServicesProvider = Provider<List<NailService>>((ref) {
  return ref.watch(posProvider).selectedServices;
});

final totalPriceProvider = Provider<double>((ref) {
  return ref.watch(posProvider).totalPrice;
});
