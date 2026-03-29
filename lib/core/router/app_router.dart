// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/pos/screens/pos_screen.dart';
import '../../features/pos/screens/bill_screen.dart';

// ════════════════════════════════════════════════════
// ROUTES
// ════════════════════════════════════════════════════
class AppRoutes {
  static const login = '/login';
  static const home = '/home'; // Staff: appointment screen
  static const dashboard = '/dashboard'; // Owner: dashboard screen
  static const appointment = '/appointment';
  static const bill = '/bill'; // Bill screen
}

// ════════════════════════════════════════════════════
// ROUTER PROVIDER
// ════════════════════════════════════════════════════
final routerProvider = Provider<GoRouter>((ref) {
  final authStateNotifier = ValueNotifier<AuthState>(const AuthLoading());

  ref.listen<AuthState>(authProvider, (_, next) {
    authStateNotifier.value = next;
  });

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: authStateNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoginPage = state.matchedLocation == AppRoutes.login;

      if (authState is AuthLoading) return null;
      if (authState is AuthUnauthenticated || authState is AuthError) {
        return isLoginPage ? null : AppRoutes.login;
      }
      if (authState is AuthLoginLoading) return null;
      if (authState is AuthAuthenticated) {
        if (isLoginPage) {
          return authState.user.isOwner ? AppRoutes.home : AppRoutes.dashboard;
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const PosScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const OwnerDashboardPlaceholder(),
      ),
      GoRoute(
        path: AppRoutes.bill,
        builder: (context, state) => const BillScreen(),
      ),
    ],
  );
});

// ════════════════════════════════════════════════════
// PLACEHOLDER — Owner Dashboard (làm sau)
// ════════════════════════════════════════════════════
class OwnerDashboardPlaceholder extends ConsumerWidget {
  const OwnerDashboardPlaceholder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👑', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text(
              'Chào ${user?.name ?? "chủ tiệm"}!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              user?.salonName ?? '',
              style: const TextStyle(color: Color(0xFF555566)),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
              ),
              child: const Text('Đăng xuất'),
            ),
          ],
        ),
      ),
    );
  }
}
