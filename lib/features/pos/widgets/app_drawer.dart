// lib/features/pos/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/providers/app_data_provider.dart';
import '../../../core/providers/theme_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  String _getCurrentRoute(BuildContext context) {
    return GoRouter.of(context).routeInformationProvider.value.uri.path;
  }

  bool _isRouteActive(String currentRoute, String itemRoute) {
    // Exact match
    if (currentRoute == itemRoute) return true;

    // Handle root route
    if (currentRoute == '/' && itemRoute == '/home') return true;

    // Handle sub-routes (for future expansion)
    if (currentRoute.startsWith('$itemRoute/') && itemRoute != '/') {
      return false;
    }

    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(salonProvider);
    final user = ref.watch(currentUserProvider);
    final currentRoute = _getCurrentRoute(context);

    return Drawer(
      backgroundColor: const Color(0xFF151520),
      width: 260,
      child: Column(
        children: [
          // ① Header — salon + user info
          _DrawerHeader(salon: salon, user: user),

          // ② Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerSection(
                  label: 'Bán hàng',
                  items: [
                    _DrawerItem(
                      icon: '💅',
                      iconBg: const Color(0xFF2D1020),
                      title: 'Màn hình POS',
                      subtitle: 'Tạo đơn hàng',
                      route: '/home',
                      isActive: _isRouteActive(currentRoute, '/home'),
                    ),
                    _DrawerItem(
                      icon: '�',
                      iconBg: const Color(0xFF10B981),
                      title: 'Dashboard',
                      subtitle: 'Tổng quan',
                      route: '/dashboard',
                      isActive: _isRouteActive(currentRoute, '/dashboard'),
                    ),
                    _DrawerItem(
                      icon: '��',
                      iconBg: const Color(0xFF0D1E2E),
                      title: 'Lịch hẹn',
                      subtitle: 'Hôm nay',
                      route: '/appointments',
                      isActive: _isRouteActive(currentRoute, '/appointments'),
                    ),
                  ],
                ),
                _DrawerSection(
                  label: 'Quản lý',
                  items: [
                    _DrawerItem(
                      icon: '👥',
                      iconBg: const Color(0xFF0A1E14),
                      title: 'Nhân viên',
                      subtitle: 'Danh sách & ca làm',
                      route: '/staffs',
                      isActive: _isRouteActive(currentRoute, '/staffs'),
                    ),
                    _DrawerItem(
                      icon: '✨',
                      iconBg: const Color(0xFF1A1A0A),
                      title: 'Dịch vụ',
                      subtitle: 'Danh mục & giá',
                      route: '/services',
                      isActive: _isRouteActive(currentRoute, '/services'),
                    ),
                    _DrawerItem(
                      icon: '👤',
                      iconBg: const Color(0xFF0D1E2E),
                      title: 'Khách hàng',
                      subtitle: 'Danh sách',
                      route: '/customers',
                      isActive: _isRouteActive(currentRoute, '/customers'),
                    ),
                  ],
                ),
                _DrawerSection(
                  label: 'Báo cáo',
                  items: [
                    _DrawerItem(
                      icon: '📊',
                      iconBg: const Color(0xFF1A0A1A),
                      title: 'Doanh thu',
                      subtitle: 'Thống kê & báo cáo',
                      route: '/revenue-report',
                      isActive: _isRouteActive(currentRoute, '/revenue-report'),
                    ),
                  ],
                ),
                _DrawerSection(
                  label: 'Hệ thống',
                  items: [
                    _DrawerItem(
                      icon: '⚙️',
                      iconBg: const Color(0xFF1A1A0A),
                      title: 'Cài đặt tiệm',
                      subtitle: 'Thông tin & giờ mở cửa',
                      route: '/settings',
                      isActive: _isRouteActive(currentRoute, '/settings'),
                    ),
                    const _ThemeToggleItem(),
                  ],
                ),
              ],
            ),
          ),

          // ③ Footer — logout
          _DrawerFooter(
            onLogout: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// DRAWER HEADER
// ════════════════════════════════════════════════════
class _DrawerHeader extends StatelessWidget {
  final dynamic salon;
  final dynamic user;
  const _DrawerHeader({this.salon, this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF252535), width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            salon?.name ?? 'Nail Studio',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            salon?.address ?? '',
            style: const TextStyle(color: Color(0xFF555566), fontSize: 11),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A28),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D3557),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    user?.name?.isNotEmpty == true ? user!.name[0] : 'U',
                    style: const TextStyle(
                      color: Color(0xFF85B7EB),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      user?.role ?? '',
                      style: const TextStyle(
                        color: Color(0xFF555566),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// DRAWER SECTION
// ════════════════════════════════════════════════════
class _DrawerSection extends StatelessWidget {
  final String label;
  final List<Widget> items;
  const _DrawerSection({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF555566),
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items,
        const Divider(color: Color(0xFF252535), height: 1, thickness: 0.5),
      ],
    );
  }
}

// ════════════════════════════════════════════════════
// DRAWER ITEM
// ════════════════════════════════════════════════════
class _DrawerItem extends StatelessWidget {
  final String icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String route;
  final bool isActive;

  const _DrawerItem({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.route,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? iconBg.withValues(alpha: 0.2) : Colors.transparent,
          border: Border(
            left: isActive
                ? BorderSide(color: iconBg, width: 3)
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 15)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isActive ? iconBg : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF555566),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive) Icon(Icons.check_circle, color: iconBg, size: 18),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// DRAWER FOOTER
// ════════════════════════════════════════════════════
class _DrawerFooter extends StatelessWidget {
  final VoidCallback onLogout;
  const _DrawerFooter({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF252535), width: 0.5)),
      ),
      child: InkWell(
        onTap: onLogout,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: const Row(
            children: [
              Icon(
                Icons.power_settings_new,
                color: Color(0xFFE24B4A),
                size: 18,
              ),
              SizedBox(width: 10),
              Text(
                'Đăng xuất',
                style: TextStyle(color: Color(0xFFE24B4A), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════
// THEME TOGGLE ITEM
// ════════════════════════════════════════════════
class _ThemeToggleItem extends ConsumerWidget {
  const _ThemeToggleItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(currentThemeProvider);

    return InkWell(
      onTap: () {
        ref.read(themeProvider.notifier).toggleTheme();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: currentTheme == AppTheme.dark
                    ? const Color(0xFFFFFFFF)
                    : const Color(0xFF1A1A0A),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(
                currentTheme == AppTheme.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
                size: 16,
                color: currentTheme == AppTheme.dark
                    ? Colors.black
                    : Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Giao diện',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    currentTheme.name,
                    style: const TextStyle(
                      color: Color(0xFF555566),
                      fontSize: 11,
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
