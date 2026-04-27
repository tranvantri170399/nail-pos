// lib/core/api/api_endpoints.dart

class ApiEndpoints {
  static const String baseUrl =
      'https://nail-pos-api.onrender.com';
  // static const String baseUrl = 'http://localhost:3000';
  // ── Auth ─────────────────────────────────────────────────
  static const String ownerLogin = '/auth/owner/login';
  static const String staffLogin = '/auth/staff/login';
  static const String ownerSetPassword = '/auth/owner/set-password';
  static const String staffSetPin = '/auth/staff/set-pin';

  // ── Staffs ───────────────────────────────────────────────
  static const String staffs = '/staffs';

  // ── Customers ────────────────────────────────────────────
  static const String customers = '/customers';
  static const String customerByPhone = '/customers/phone';

  // ── Appointments ─────────────────────────────────────────
  static const String appointments = '/appointments';
  static const String appointmentByDate = '/appointments/by-date';

  // Salons
  static const String salons = '/salons';
  static String salonById(int id) => '/salons/$id';

  // Service Categories
  static const String serviceCategories = '/service-categories';
  static String serviceCategoryById(int id) => '/service-categories/$id';

  // Services
  static const String services = '/services';
  static String serviceById(int id) => '/services/$id';
  static const String servicesByCategory = '/services/by-category';

  // Appointment Services
  static const String appointmentServices = '/appointment-services';
  static String appointmentServicesByAppointment(int id) =>
      '/appointment-services/appointment/$id';
  static String appointmentServicesTotals(int id) =>
      '/appointment-services/appointment/$id/totals';
  static String appointmentServiceById(int id) => '/appointment-services/$id';

  // Transactions
  static const String transactions = '/transactions';
  static const String transactionItems = '/transaction-items';
  static const String transactionReport = '/transactions/report';
  static String transactionByAppointment(int id) =>
      '/transactions/appointment/$id';
  static String transactionRefund(int id) => '/transactions/$id/refund';

  // ── Shifts ───────────────────────────────────────────────
  static const String shifts = '/shifts';
  static const String shiftCurrent = '/shifts/current';
  static const String shiftOpen = '/shifts/open';
  static String shiftClose(int id) => '/shifts/$id/close';
  static String shiftCashMovement(int id) => '/shifts/$id/cash-movement';
}
