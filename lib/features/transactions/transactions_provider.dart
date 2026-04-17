// lib/features/transactions/transactions_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/transaction.dart';
import '../../core/api/api_client.dart';
import '../auth/providers/auth_provider.dart';
import 'transactions_repository.dart';

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TransactionsRepository(apiClient.dio);
});

// State cho checkout
class CheckoutState {
  final bool isLoading;
  final String? errorMessage;
  final Transaction? transaction;

  const CheckoutState({
    this.isLoading = false,
    this.errorMessage,
    this.transaction,
  });

  CheckoutState copyWith({
    bool? isLoading,
    String? errorMessage,
    Transaction? transaction,
  }) {
    return CheckoutState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      transaction: transaction ?? this.transaction,
    );
  }
}

class CheckoutNotifier extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutState();

  Future<void> checkout(CreateTransactionDto dto) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(transactionsRepositoryProvider);
      final transaction = await repo.create(dto);
      state = state.copyWith(isLoading: false, transaction: transaction);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void reset() => state = const CheckoutState();
}

final checkoutProvider = NotifierProvider<CheckoutNotifier, CheckoutState>(
  CheckoutNotifier.new,
);
