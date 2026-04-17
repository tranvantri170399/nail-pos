// lib/features/customer/customer_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/customer.dart';
import 'customer_repository.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CustomerRepository(apiClient.dio);
});

// Provider cho customer list
final customerListAsyncProvider = FutureProvider.family<List<Customer>, int>((
  ref,
  salonId,
) async {
  final repository = ref.watch(customerRepositoryProvider);
  return await repository.getCustomers(salonId);
});

// State cho customer operations
class CustomerOperationState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const CustomerOperationState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  CustomerOperationState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return CustomerOperationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class CustomerOperationNotifier extends StateNotifier<CustomerOperationState> {
  final CustomerRepository _repository;
  final Ref _ref;

  CustomerOperationNotifier(this._repository, this._ref)
    : super(const CustomerOperationState());

  Future<void> createCustomer({
    required int salonId,
    required String name,
    required String phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await _repository.createCustomer(
        salonId: salonId,
        name: name,
        phone: phone,
      );
      // Invalidate customer list provider
      _ref.invalidate(customerListAsyncProvider(salonId));
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateCustomer({
    required int id,
    required String name,
    required String phone,
    required int salonId,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await _repository.updateCustomer(id: id, name: name, phone: phone);
      // Invalidate customer list provider
      _ref.invalidate(customerListAsyncProvider(salonId));
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteCustomer(int id, int salonId) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await _repository.deleteCustomer(id);
      // Invalidate customer list provider
      _ref.invalidate(customerListAsyncProvider(salonId));
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() {
    state = const CustomerOperationState();
  }
}

final customerOperationProvider =
    StateNotifierProvider<CustomerOperationNotifier, CustomerOperationState>((
      ref,
    ) {
      final repository = ref.watch(customerRepositoryProvider);
      return CustomerOperationNotifier(repository, ref);
    });

// Search provider
final customerSearchProvider = StateProvider<String>((ref) => '');

final filteredCustomersProvider = Provider.family<List<Customer>, int>((
  ref,
  salonId,
) {
  final searchQuery = ref.watch(customerSearchProvider).toLowerCase();
  final customersAsync = ref.watch(customerListAsyncProvider(salonId));

  return customersAsync.when(
    data: (customers) {
      if (searchQuery.isEmpty) return customers;
      return customers.where((c) {
        return c.name.toLowerCase().contains(searchQuery) ||
            c.phone.toLowerCase().contains(searchQuery);
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
