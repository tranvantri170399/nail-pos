// lib/features/auth/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _showOwnerForm = false; // false = chọn loại, true = form owner
  bool _showStaffForm = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Lắng nghe state thay đổi
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next is AuthAuthenticated) {
        // Điều hướng dựa theo type
        if (next.user.isOwner) {
          context.go(AppRoutes.home);
        } else {
          context.go(AppRoutes.dashboard);
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // ── Logo ─────────────────────────────────────
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B9D), Color(0xFFc44dff)],
                  ),
                ),
                child: const Center(
                  child: Text('💅', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'TPOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                ),
              ),
              const Text(
                'Nail Salon Management',
                style: TextStyle(color: Color(0xFF555566), fontSize: 13),
              ),
              const SizedBox(height: 60),

              // ── Chọn loại đăng nhập ──────────────────────
              if (!_showOwnerForm && !_showStaffForm) ...[
                _buildTypeButton(
                  icon: '👑',
                  label: 'Đăng nhập chủ tiệm',
                  subtitle: 'Quản lý toàn bộ salon',
                  color: const Color(0xFFFFBF00),
                  onTap: () => setState(() => _showOwnerForm = true),
                ),
                const SizedBox(height: 16),
                _buildTypeButton(
                  icon: '💅',
                  label: 'Đăng nhập nhân viên',
                  subtitle: 'Xem lịch hẹn của bạn',
                  color: const Color(0xFFFF6B9D),
                  onTap: () => setState(() => _showStaffForm = true),
                ),
              ],

              // ── Form đăng nhập chủ tiệm ──────────────────
              if (_showOwnerForm)
                OwnerLoginForm(
                  onBack: () => setState(() => _showOwnerForm = false),
                ),

              // ── Form đăng nhập nhân viên ─────────────────
              if (_showStaffForm)
                StaffLoginForm(
                  onBack: () => setState(() => _showStaffForm = false),
                ),

              // ── Lỗi ─────────────────────────────────────
              if (authState is AuthError) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xffef444415),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEF444440)),
                  ),
                  child: Row(
                    children: [
                      const Text('⚠️ ', style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Text(
                          authState.message,
                          style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton({
    required String icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF151520),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF555566), fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// OWNER LOGIN FORM
// ════════════════════════════════════════════════════
class OwnerLoginForm extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  const OwnerLoginForm({super.key, required this.onBack});

  @override
  ConsumerState<OwnerLoginForm> createState() => _OwnerLoginFormState();
}

class _OwnerLoginFormState extends ConsumerState<OwnerLoginForm> {
  final _phoneCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure       = true;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _login() {
    if (_phoneCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) return;
    ref.read(authProvider.notifier).loginOwner(
      phone:    _phoneCtrl.text.trim(),
      password: _passwordCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider) is AuthLoginLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        GestureDetector(
          onTap: () {
            ref.read(authProvider.notifier).reset();
            widget.onBack();
          },
          child: const Row(
            children: [
              Icon(Icons.arrow_back_ios, color: Color(0xFF555566), size: 16),
              Text('Quay lại', style: TextStyle(color: Color(0xFF555566), fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text('👑 Chủ tiệm', style: TextStyle(color: Color(0xFFFFBF00), fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Đăng nhập để quản lý salon', style: TextStyle(color: Color(0xFF555566), fontSize: 13)),
        const SizedBox(height: 28),

        // Phone field
        _buildLabel('Số điện thoại'),
        const SizedBox(height: 6),
        _buildInput(
          controller: _phoneCtrl,
          hint: '0967890123',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),

        // Password field
        _buildLabel('Mật khẩu'),
        const SizedBox(height: 6),
        _buildInput(
          controller: _passwordCtrl,
          hint: '••••••••',
          obscure: _obscure,
          suffix: IconButton(
            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF555566), size: 18),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        const SizedBox(height: 28),

        // Login button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFBF00),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Text('Đăng nhập', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════
// STAFF LOGIN FORM
// ════════════════════════════════════════════════════
class StaffLoginForm extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  const StaffLoginForm({super.key, required this.onBack});

  @override
  ConsumerState<StaffLoginForm> createState() => _StaffLoginFormState();
}

class _StaffLoginFormState extends ConsumerState<StaffLoginForm> {
  final _phoneCtrl = TextEditingController();
  final _pinCtrl   = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _login() {
    if (_phoneCtrl.text.isEmpty || _pinCtrl.text.isEmpty) return;
    ref.read(authProvider.notifier).loginStaff(
      phone: _phoneCtrl.text.trim(),
      pin:   _pinCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider) is AuthLoginLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        GestureDetector(
          onTap: () {
            ref.read(authProvider.notifier).reset();
            widget.onBack();
          },
          child: const Row(
            children: [
              Icon(Icons.arrow_back_ios, color: Color(0xFF555566), size: 16),
              Text('Quay lại', style: TextStyle(color: Color(0xFF555566), fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text('💅 Nhân viên', style: TextStyle(color: Color(0xFFFF6B9D), fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Nhập SĐT và mã PIN của bạn', style: TextStyle(color: Color(0xFF555566), fontSize: 13)),
        const SizedBox(height: 28),

        // Phone field
        _buildLabel('Số điện thoại'),
        const SizedBox(height: 6),
        _buildInput(
          controller: _phoneCtrl,
          hint: '0901111111',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),

        // PIN field
        _buildLabel('Mã PIN (4 số)'),
        const SizedBox(height: 6),
        _buildInput(
          controller: _pinCtrl,
          hint: '••••',
          obscure: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
        ),
        const SizedBox(height: 28),

        // Login button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B9D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Đăng nhập', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════
// SHARED WIDGETS
// ════════════════════════════════════════════════════
Widget _buildLabel(String text) {
  return Text(
    text,
    style: const TextStyle(
      color: Color(0xFF555566),
      fontSize: 11,
      letterSpacing: 0.8,
    ),
  );
}

Widget _buildInput({
  required TextEditingController controller,
  required String hint,
  bool obscure = false,
  TextInputType? keyboardType,
  Widget? suffix,
  int? maxLength,
}) {
  return TextField(
    controller: controller,
    obscureText: obscure,
    keyboardType: keyboardType,
    maxLength: maxLength,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF333344)),
      counterText: '',
      filled: true,
      fillColor: const Color(0xFF151520),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF252535)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF252535)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFF6B9D)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
  );
}