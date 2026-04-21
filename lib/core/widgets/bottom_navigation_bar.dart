// lib/core/widgets/bottom_navigation_bar.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum NavItem {
  pos('POS', Icons.point_of_sale, '/home'),
  appointments('Lịch hẹn', Icons.calendar_today, '/appointments'),
  reports('Báo cáo', Icons.bar_chart, '/revenue-report'),
  staff('Nhân viên', Icons.people, '/staffs'),
  services('Dịch vụ', Icons.spa, '/services');

  const NavItem(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}

class AppBottomNavigationBar extends StatelessWidget {
  final NavItem activeItem;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? backgroundColor;

  const AppBottomNavigationBar({
    super.key,
    required this.activeItem,
    this.activeColor,
    this.inactiveColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColorFinal = activeColor ?? theme.colorScheme.primary;
    final inactiveColorFinal =
        inactiveColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final backgroundColorFinal = backgroundColor ?? theme.colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColorFinal,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: NavItem.values.map((item) {
              return _buildNavItem(
                context,
                item: item,
                isActive: item == activeItem,
                activeColor: activeColorFinal,
                inactiveColor: inactiveColorFinal,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required NavItem item,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final color = isActive ? activeColor : inactiveColor;

    return InkWell(
      onTap: () => GoRouter.of(context).go(item.route),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper methods cho các màn hình cụ thể
class PosBottomNavigationBar extends StatelessWidget {
  const PosBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppBottomNavigationBar(
      activeItem: NavItem.pos,
      activeColor: Color(0xFFFF6B9D),
      inactiveColor: Color(0xFF888899),
      backgroundColor: Color(0xFF151520),
    );
  }
}

class AppointmentBottomNavigationBar extends StatelessWidget {
  const AppointmentBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppBottomNavigationBar(
      activeItem: NavItem.appointments,
      activeColor: Color(0xFF3B82F6),
      inactiveColor: Color(0xFF888899),
      backgroundColor: Color(0xFF151520),
    );
  }
}

class ReportsBottomNavigationBar extends StatelessWidget {
  const ReportsBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBottomNavigationBar(
      activeItem: NavItem.reports,
      activeColor: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }
}
