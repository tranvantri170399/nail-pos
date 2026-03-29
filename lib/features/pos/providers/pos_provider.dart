// lib/features/pos/providers/pos_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/staff.dart';
import '../../../core/models/service.dart';
import '../../../core/models/customer.dart';
import '../../../core/models/appointment.dart';
import '../../../core/models/transaction.dart';
import '../../../core/providers/app_data_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/pos_repository.dart';

// ════════════════════════════════════════════════════
// UI STATE PROVIDER
// ════════════════════════════════════════════════════
final staffCollapseProvider = StateProvider<bool>((ref) => false);

// ════════════════════════════════════════════════════
// POS STATE — Toàn bộ trạng thái màn hình POS
// ════════════════════════════════════════════════════

class PosState {
  // Dữ liệu từ API
  final int salonId;
  final List<Staff> staffList;
  final List<Service> serviceList;

  // Lựa chọn hiện tại
  final Staff? selectedStaff;
  final List<Service> selectedServices;
  final Customer? selectedCustomer;

  // UI state
  final bool isLoadingStaffs;
  final bool isLoadingServices;
  final bool isSearchingCustomer;
  final bool isCheckingOut;
  final String? error;
  final String? checkoutSuccess; // Mã hoá đơn sau khi thanh toán
  final String paymentMethod; // Phương thức thanh toán đang chọn
  final Transaction? lastTransaction;

  const PosState({
    this.salonId = 1,
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
    this.paymentMethod = 'cash',
    this.lastTransaction,
  });

  // ── Tính tổng tiền ──────────────────────────────────
  double get totalPrice => selectedServices.fold(0, (sum, s) => sum + s.price);

  // ── Tính tổng thời gian ─────────────────────────────
  int get totalMinutes =>
      selectedServices.fold(0, (sum, s) => sum + s.durationMinutes);

  // ── Có thể thanh toán chưa ──────────────────────────
  bool get canCheckout => selectedStaff != null && selectedServices.isNotEmpty;

  // ── CopyWith để update state ─────────────────────────
  PosState copyWith({
    int? salonId,
    List<Staff>? staffList,
    List<Service>? serviceList,
    Staff? selectedStaff,
    List<Service>? selectedServices,
    Customer? selectedCustomer,
    bool? isLoadingStaffs,
    bool? isLoadingServices,
    bool? isSearchingCustomer,
    bool? isCheckingOut,
    String? error,
    String? checkoutSuccess,
    String? paymentMethod,
    bool clearStaff = false,
    bool clearCustomer = false,
    bool clearError = false,
    bool clearCheckout = false,
    Transaction? lastTransaction,
  }) {
    return PosState(
      staffList: staffList ?? this.staffList,
      serviceList: serviceList ?? this.serviceList,
      selectedStaff: clearStaff ? null : (selectedStaff ?? this.selectedStaff),
      selectedServices: selectedServices ?? this.selectedServices,
      selectedCustomer: clearCustomer
          ? null
          : (selectedCustomer ?? this.selectedCustomer),
      isLoadingStaffs: isLoadingStaffs ?? this.isLoadingStaffs,
      isLoadingServices: isLoadingServices ?? this.isLoadingServices,
      isSearchingCustomer: isSearchingCustomer ?? this.isSearchingCustomer,
      isCheckingOut: isCheckingOut ?? this.isCheckingOut,
      error: clearError ? null : (error ?? this.error),
      checkoutSuccess: clearCheckout
          ? null
          : (checkoutSuccess ?? this.checkoutSuccess),
      paymentMethod: paymentMethod ?? this.paymentMethod,
      lastTransaction: lastTransaction ?? this.lastTransaction,
    );
  }
}

// ════════════════════════════════════════════════════
// POS NOTIFIER — Xử lý logic
// ════════════════════════════════════════════════════

class PosNotifier extends StateNotifier<PosState> {
  final PosRepository _repo;
  final Ref _ref;

  PosNotifier(this._repo, this._ref) : super(const PosState()) {
    _initSalonId(); // ← init salonId trước
    _initFromCache();
  }
  // ✅ Đúng — dùng currentUserProvider
  void _initSalonId() {
    final user = _ref.read(currentUserProvider);
    if (user != null) {
      print("salon id: ${user.salonId}");
      state = state.copyWith(salonId: user.salonId ?? 1);
    }
  }

  // Load staffs + services khi mở màn hình
  void _initFromCache() {
    final appData = _ref.read(appDataProvider); // ← đọc từ cache

    if (appData.hasStaff) {
      // Staff đã có → dùng luôn
      state = state.copyWith(
        salonId: appData.salon?.id ?? 1,
        staffList: appData.staffList,
      );
    }

    // Luôn lắng nghe thay đổi
    _ref.listen(appDataProvider, (_, next) {
      if (next.hasStaff && state.staffList.isEmpty) {
        state = state.copyWith(
          salonId: next.salon?.id ?? 1,
          staffList: next.staffList,
        );
      }
    });

    // Trigger load data nếu chưa được load - ưu tiên cho services
    if (!appData.isLoading && (!appData.hasStaff || !appData.hasCategories)) {
      final user = _ref.read(currentUserProvider);
      if (user != null) {
        _ref.read(appDataProvider.notifier).loadAll(user.salonId ?? 1);
      }
    }
  }

  // Reset sau khi thanh toán — giữ salonId
  void resetOrder() {
    state = PosState(
      salonId: state.salonId, // ← giữ salonId
      staffList: state.staffList,
      serviceList: state.serviceList,
      paymentMethod: 'cash', // Reset về mặc định
    );
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
  void toggleService(Service service) {
    final current = List<Service>.from(state.selectedServices);
    final index = current.indexWhere((s) => s.id == service.id);
    if (index >= 0) {
      current.removeAt(index); // Bỏ chọn
    } else {
      current.add(service); // Thêm vào
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
        selectedCustomer: customer,
        isSearchingCustomer: false,
      );
    } catch (e) {
      // Khách mới — chưa có trong hệ thống
      state = state.copyWith(isSearchingCustomer: false, clearCustomer: true);
    }
  }

  // ── Xoá khách hàng đã chọn ──────────────────────────
  void clearCustomer() {
    state = state.copyWith(clearCustomer: true);
  }

  // ── Chọn phương thức thanh toán ───────────────────────
  void selectPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  // ── Thanh toán ───────────────────────────────────────
  Future<void> checkout({String? note}) async {
    if (!state.canCheckout) return;
    state = state.copyWith(isCheckingOut: true, clearError: true);
    try {
      final now = DateTime.now();

      // 1. Tạo appointment object
      final appointment = Appointment.create(
        staffId: state.selectedStaff!.id,
        customerId: state.selectedCustomer?.id,
        scheduledDate: now.toIso8601String().split('T')[0],
        startTime:
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        endTime:
            '${(now.hour + (now.minute + state.totalMinutes) ~/ 60).toString().padLeft(2, '0')}:${((now.minute + state.totalMinutes) % 60).toString().padLeft(2, '0')}',
        totalMinutes: state.totalMinutes,
        totalPrice: state.totalPrice,
        status: 'done', // Thanh toán ngay
        note: note,
      );

      final appointmentId = await _repo.createAppointment(appointment);

      // 2. Chuẩn bị transaction items data trước
      final List<Map<String, dynamic>> itemsData = [];
      for (int i = 0; i < state.selectedServices.length; i++) {
        final service = state.selectedServices[i];
        final commissionRate = 10.0; // TODO: Lấy từ DB

        itemsData.add({
          'service_id': service.id,
          'staff_id': state.selectedStaff!.id,
          'service_name': service.name,
          'price': service.price.toDouble(),
          'commission_rate': commissionRate,
        });
      }

      // 3. Tạo transaction object
      final transaction = Transaction.create(
        appointmentId: appointmentId,
        salonId: state.salonId,
        subtotal: state.totalPrice,
        discountAmount: 0,
        tipAmount: 0,
        taxAmount: 0,
        totalAmount: state.totalPrice, // Backend sẽ tính lại
        paymentMethod: state.paymentMethod, // ← Dùng phương thức đã chọn
        status: 'completed', // Backend sẽ override
        note: note,
        paidAt: now,
      );

      // Debug: Print appointmentId
      print('Creating transaction with appointmentId: $appointmentId');

      // Print data being sent
      final dataToSend = transaction.toJsonWithItems(itemsData);
      print('Transaction data being sent: $dataToSend');

      Transaction createdTransaction = await _repo.createTransaction(
        transaction,
        itemsData: itemsData,
      );
      print('Transaction created: ${createdTransaction.toString()}');
      state = state.copyWith(
        isCheckingOut: false,
        checkoutSuccess: '#${createdTransaction.id}',
        lastTransaction: createdTransaction,
      );
    } catch (e) {
      print(e);
      state = state.copyWith(
        isCheckingOut: false,
        error: 'Thanh toán thất bại: $e',
      );
    }
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
  return PosNotifier(repo, ref);
});

// Convenience providers
final selectedServicesProvider = Provider<List<Service>>((ref) {
  return ref.watch(posProvider).selectedServices;
});

final totalPriceProvider = Provider<double>((ref) {
  return ref.watch(posProvider).totalPrice;
});
