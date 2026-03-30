// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/appointment/screens/appointment_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/customer/screens/customer_form_screen.dart';
import '../../features/customer/screens/customer_list_screen.dart';
import '../../features/pos/screens/bill_screen.dart';
import '../../features/pos/screens/pos_screen.dart';
import '../../features/reports/screens/revenue_report_screen.dart';
import '../../features/service/screens/category_form_screen.dart';
import '../../features/service/screens/service_form_screen.dart';
import '../../features/service/screens/services_list_screen.dart';
import '../../features/staff/screens/staff_form_screen.dart';
import '../../features/staff/screens/staff_list_screen.dart';
import '../widgets/bottom_navigation_bar.dart';

// ════════════════════════════════════════════════════
// ROUTES
// ════════════════════════════════════════════════════
class AppRoutes {
  static const login = '/login';
  static const home = '/home'; // Staff: appointment screen
  static const dashboard = '/dashboard'; // Owner: dashboard screen
  static const appointments = '/appointments';
  static const bill = '/bill'; // Bill screen
  static const revenueReport = '/revenue-report'; // Revenue report screen

  // Staff routes
  static const staffs = '/staffs';
  static const staffForm = '/staffs/form';

  // Service routes
  static const services = '/services';
  static const serviceCategoryForm = '/services/category-form';
  static const serviceForm = '/services/service-form';

  // Customer routes
  static const customers = '/customers';
  static const customerForm = '/customers/form';
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
      GoRoute(
        path: AppRoutes.revenueReport,
        builder: (context, state) => const RevenueReportScreen(),
      ),
      // Appointment routes
      GoRoute(
        path: AppRoutes.appointments,
        builder: (context, state) => const AppointmentScreen(),
      ),
      // Staff routes
      GoRoute(
        path: AppRoutes.staffs,
        builder: (context, state) => const StaffListScreen(),
      ),
      GoRoute(
        path: AppRoutes.staffForm,
        builder: (context, state) =>
            StaffFormScreen(staff: state.extra as dynamic),
      ),
      // Service routes
      GoRoute(
        path: AppRoutes.services,
        builder: (context, state) => const ServicesListScreen(),
      ),
      GoRoute(
        path: AppRoutes.serviceCategoryForm,
        builder: (context, state) =>
            CategoryFormScreen(category: state.extra as dynamic),
      ),
      GoRoute(
        path: AppRoutes.serviceForm,
        builder: (context, state) =>
            ServiceFormScreen(extra: state.extra as Map<String, dynamic>?),
      ),
      // Customer routes
      GoRoute(
        path: AppRoutes.customers,
        builder: (context, state) => const CustomerListScreen(),
      ),
      GoRoute(
        path: AppRoutes.customerForm,
        builder: (context, state) =>
            CustomerFormScreen(customer: state.extra as dynamic),
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
      bottomNavigationBar: const DashboardBottomNavigationBar(),
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

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.go(AppRoutes.revenueReport),
                      icon: const Icon(Icons.bar_chart),
                      label: const Text('Báo cáo doanh thu'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.go(AppRoutes.home),
                      icon: const Icon(Icons.point_of_sale),
                      label: const Text('Màn hình POS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => ref.read(authProvider.notifier).logout(),
                      icon: const Icon(Icons.logout),
                      label: const Text('Đăng xuất'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
