// lib/core/api/api_endpoints.dart

class ApiEndpoints {
  static const String baseUrl =
      'https://nail-pos-api-production.up.railway.app';

  // ── Auth ─────────────────────────────────────────────────
  static const String ownerLogin      = '/auth/owner/login';
  static const String staffLogin      = '/auth/staff/login';
  static const String ownerSetPassword = '/auth/owner/set-password';
  static const String staffSetPin     = '/auth/staff/set-pin';

  // ── Staffs ───────────────────────────────────────────────
  static const String staffs          = '/staffs';

  // ── Services ─────────────────────────────────────────────
  static const String services        = '/services';

  // ── Customers ────────────────────────────────────────────
  static const String customers       = '/customers';
  static const String customerByPhone = '/customers/phone';

  // ── Appointments ─────────────────────────────────────────
  static const String appointments     = '/appointments';
  static const String appointmentByDate = '/appointments/by-date';
}