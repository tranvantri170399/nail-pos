// lib/features/auth/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/app_data_provider.dart';
import '../repositories/auth_repository.dart';

// ════════════════════════════════════════════════════
// 1. AUTH STATE
// ════════════════════════════════════════════════════
abstract class AuthState { const AuthState(); }

class AuthLoading        extends AuthState { const AuthLoading(); }
class AuthLoginLoading   extends AuthState { const AuthLoginLoading(); }
class AuthUnauthenticated extends AuthState { const AuthUnauthenticated(); }

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

// ════════════════════════════════════════════════════
// 2. AUTH NOTIFIER
// ════════════════════════════════════════════════════
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final Ref _ref;

  AuthNotifier(this._authRepository, this._ref) : super(const AuthLoading()) {
    _checkExistingAuth();
  }

  // Kiểm tra token khi mở app
  Future<void> _checkExistingAuth() async {
    try {
      final isLoggedIn = await _authRepository.isLoggedIn();
      if (isLoggedIn) {
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          state = AuthAuthenticated(user);
          await _ref.read(appDataProvider.notifier).loadAll(user.salonId ?? 1);
          return;
        }
      }
      state = const AuthUnauthenticated();
    } catch (_) {
      state = const AuthUnauthenticated();
    }
  }

  // Login owner
  Future<void> loginOwner({
    required String phone,
    required String password,
  }) async {
    state = const AuthLoginLoading();
    try {
      final authResponse = await _authRepository.loginOwner(phone, password);
      state = AuthAuthenticated(authResponse.user);
      await _ref.read(appDataProvider.notifier).loadAll(authResponse.user.salonId ?? 1);
    } catch (e) {
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Login staff
  Future<void> loginStaff({
    required String phone,
    required String pin,
  }) async {
    state = const AuthLoginLoading();
    try {
      final authResponse = await _authRepository.loginStaff(phone, pin);
      state = AuthAuthenticated(authResponse.user);
      await _ref.read(appDataProvider.notifier).loadAll(authResponse.user.salonId ?? 1);
    } catch (e) {
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Logout
  Future<void> logout() async {
    await _authRepository.logout();
    _ref.read(appDataProvider.notifier).clear();
    state = const AuthUnauthenticated();
  }

  void reset() => state = const AuthUnauthenticated();
}

// ════════════════════════════════════════════════════
// 3. PROVIDERS
// ════════════════════════════════════════════════════
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient.dio);
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository, ref); // ← ref được truyền vào đây
});

final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authProvider);

  if (authState is AuthAuthenticated) return authState.user;
  return null;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) is AuthAuthenticated;
});