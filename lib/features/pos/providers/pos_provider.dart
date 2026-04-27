// lib/features/pos/providers/pos_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/staff.dart';
import '../../../core/models/service.dart';
import '../../../core/models/customer.dart';
import '../../../core/models/appointment.dart';
import '../../../core/models/transaction.dart';
import '../../../core/api/api_client.dart';
import '../../../core/providers/app_data_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shifts/providers/shifts_provider.dart';
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

  // Tip / Discount / Tax / Cash
  final double tipAmount;
  final String discountType; // 'fixed' | 'percentage'
  final double discountValue; // Amount or Percentage value
  final double discountAmount; // Calculated amount
  final String? discountReason;
  final double taxRate; // VD: 0.08 = 8%
  final double cashReceived;

  // UI state
  final bool isLoadingStaffs;
  final bool isLoadingServices;
  final bool isSearchingCustomer;
  final bool isCheckingOut;
  final String? error;
  final String? checkoutSuccess; // Mã hoá đơn sau khi thanh toán
  final String paymentMethod; // (Legacy) Phương thức thanh toán đang chọn
  final List<Map<String, dynamic>> splitPayments; // [{'method': 'cash', 'amount': 100}, ...]
  final Transaction? lastTransaction;

  const PosState({
    this.salonId = 1,
    this.staffList = const [],
    this.serviceList = const [],
    this.selectedStaff,
    this.selectedServices = const [],
    this.selectedCustomer,
    this.tipAmount = 0,
    this.discountType = 'fixed',
    this.discountValue = 0,
    this.discountAmount = 0,
    this.discountReason,
    this.taxRate = 0,
    this.cashReceived = 0,
    this.isLoadingStaffs = false,
    this.isLoadingServices = false,
    this.isSearchingCustomer = false,
    this.isCheckingOut = false,
    this.error,
    this.checkoutSuccess,
    this.paymentMethod = 'cash',
    this.splitPayments = const [],
    this.lastTransaction,
  });

  // ── Tạm tính (tổng dịch vụ) ──────────────────────────
  double get subtotal => selectedServices.fold(0, (sum, s) => sum + s.price);

  // ── Thuế tính trên subtotal ──────────────────────────
  double get taxAmount => (subtotal * taxRate).roundToDouble();

  // ── Tổng sau tip/tax/discount ────────────────────────
  double get grandTotal => subtotal + tipAmount + taxAmount - discountAmount;

  // ── Tiền thừa trả lại ───────────────────────────────
  double get changeDue =>
      cashReceived > 0 ? cashReceived - grandTotal : 0;

  // ── Alias để tương thích ─────────────────────────────
  double get totalPrice => subtotal;

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
    double? tipAmount,
    String? discountType,
    double? discountValue,
    double? discountAmount,
    String? discountReason,
    double? taxRate,
    double? cashReceived,
    bool? isLoadingStaffs,
    bool? isLoadingServices,
    bool? isSearchingCustomer,
    bool? isCheckingOut,
    String? error,
    String? checkoutSuccess,
    String? paymentMethod,
    List<Map<String, dynamic>>? splitPayments,
    bool clearStaff = false,
    bool clearCustomer = false,
    bool clearError = false,
    bool clearCheckout = false,
    Transaction? lastTransaction,
  }) {
    return PosState(
      salonId: salonId ?? this.salonId,
      staffList: staffList ?? this.staffList,
      serviceList: serviceList ?? this.serviceList,
      selectedStaff: clearStaff ? null : (selectedStaff ?? this.selectedStaff),
      selectedServices: selectedServices ?? this.selectedServices,
      selectedCustomer: clearCustomer
          ? null
          : (selectedCustomer ?? this.selectedCustomer),
      tipAmount: tipAmount ?? this.tipAmount,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      discountAmount: discountAmount ?? this.discountAmount,
      discountReason: discountReason ?? this.discountReason,
      taxRate: taxRate ?? this.taxRate,
      cashReceived: cashReceived ?? this.cashReceived,
      isLoadingStaffs: isLoadingStaffs ?? this.isLoadingStaffs,
      isLoadingServices: isLoadingServices ?? this.isLoadingServices,
      isSearchingCustomer: isSearchingCustomer ?? this.isSearchingCustomer,
      isCheckingOut: isCheckingOut ?? this.isCheckingOut,
      error: clearError ? null : (error ?? this.error),
      checkoutSuccess: clearCheckout
          ? null
          : (checkoutSuccess ?? this.checkoutSuccess),
      paymentMethod: paymentMethod ?? this.paymentMethod,
      splitPayments: splitPayments ?? this.splitPayments,
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
    _listenAppData();
  }

  void _initSalonId() {
    final user = _ref.read(currentUserProvider);
    if (user != null) {
      state = state.copyWith(salonId: user.salonId ?? 1);
    }
  }

  void _listenAppData() {
    _ref.listen<AppDataState>(appDataProvider, (_, next) {
      if (next.salon != null || next.hasStaff || next.hasCategories) {
        state = state.copyWith(
          salonId: next.salon?.id ?? state.salonId,
          staffList: next.staffList,
          serviceList: next.allServices,
        );
      }
    });
  }

  // Load staffs + services khi mở màn hình
  void _initFromCache() async {
    final appData = _ref.read(appDataProvider);

    // Copy data từ cache nếu có
    if (appData.hasStaff) {
      state = state.copyWith(staffList: appData.staffList);
    }
    if (appData.hasCategories) {
      state = state.copyWith(serviceList: appData.allServices);
    }

    // Trigger load data nếu chưa được load - ưu tiên cho services
    if (!appData.isLoading && (!appData.hasStaff || !appData.hasCategories)) {
      final user = _ref.read(currentUserProvider);
      if (user != null) {
        // Defer the loading to avoid modifying other providers during initialization
        Future.microtask(() {
          _ref.read(appDataProvider.notifier).loadAll(user.salonId ?? 1);
        });
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
      splitPayments: const [],
      tipAmount: 0,
      discountType: 'fixed',
      discountValue: 0,
      discountAmount: 0,
      discountReason: null,
      taxRate: 0,
      cashReceived: 0,
    );
  }

  // ── Đặt tip ──────────────────────────────────────────
  void setTip(double amount) {
    state = state.copyWith(tipAmount: amount < 0 ? 0 : amount);
  }

  // ── Đặt tiền nhận ─────────────────────────────────────
  void setCashReceived(double amount) {
    state = state.copyWith(cashReceived: amount < 0 ? 0 : amount);
  }

  // ── Đặt tax rate ──────────────────────────────────────
  void setTaxRate(double rate) {
    state = state.copyWith(taxRate: rate < 0 ? 0 : rate);
  }

  // ── Đặt giảm giá ─────────────────────────────────────
  void setDiscount({required String type, required double value, String? reason}) {
    final max = state.subtotal + state.tipAmount;
    double amount = 0;
    if (type == 'percentage') {
      amount = (state.subtotal * value / 100).roundToDouble();
    } else {
      amount = value;
    }
    
    state = state.copyWith(
      discountType: type,
      discountValue: value,
      discountReason: reason,
      discountAmount: amount < 0 ? 0 : (amount > max ? max : amount),
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

  // ── Split Payments ──────────────────────────────────
  void addSplitPayment(String method, double amount) {
    final current = List<Map<String, dynamic>>.from(state.splitPayments);
    current.add({'method': method, 'amount': amount});
    state = state.copyWith(splitPayments: current);
  }
  
  void clearSplitPayments() {
    state = state.copyWith(splitPayments: const []);
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
        final commissionRate = state.selectedStaff!.commissionRate;

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
        shiftId: _ref.read(shiftsProvider).currentShift?.id,
        customerId: state.selectedCustomer?.id,
        subtotal: state.subtotal,
        discountType: state.discountType,
        discountValue: state.discountValue,
        discountReason: state.discountReason,
        discountAmount: state.discountAmount,
        tipAmount: state.tipAmount,
        taxAmount: state.taxAmount,
        taxRate: state.taxRate,
        totalAmount: state.grandTotal,
        paymentMethod: state.splitPayments.isNotEmpty ? 'split' : state.paymentMethod, // ← Dùng phương thức đã chọn
        status: 'paid',
        note: note,
        paidAt: now,
      );

      Transaction createdTransaction = await _repo.createTransaction(
        transaction,
        itemsData: itemsData,
        paymentsData: state.splitPayments.isNotEmpty ? state.splitPayments : [
          {'method': state.paymentMethod, 'amount': state.grandTotal}
        ],
      );
      state = state.copyWith(
        isCheckingOut: false,
        checkoutSuccess: '#${createdTransaction.id}',
        lastTransaction: createdTransaction,
      );
    } catch (e) {
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
