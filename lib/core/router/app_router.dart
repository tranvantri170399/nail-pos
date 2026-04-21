// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/appointment/screens/appointment_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/customer/screens/customer_form_screen.dart';
import '../../features/customer/screens/customer_list_screen.dart';
import '../../features/dashboard/screens/owner_dashboard_screen.dart';
import '../../features/pos/screens/bill_screen.dart';
import '../../features/pos/screens/pos_screen.dart';
import '../../features/reports/screens/revenue_report_screen.dart';
import '../../features/service/screens/category_form_screen.dart';
import '../../features/service/screens/service_form_screen.dart';
import '../../features/service/screens/services_list_screen.dart';
import '../../features/staff/screens/staff_form_screen.dart';
import '../../features/staff/screens/staff_list_screen.dart';

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
          return authState.user.isOwner ? AppRoutes.dashboard : AppRoutes.home;
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
        builder: (context, state) => const OwnerDashboardScreen(),
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

