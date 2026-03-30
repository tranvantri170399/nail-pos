// lib/features/appointments/screens/appointment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/app_data_provider.dart';
import '../../../features/pos/widgets/app_drawer.dart';
import '../providers/appointment_provider.dart';
import '../widgets/create_appointment_dialog.dart';
import '../widgets/appointment_detail_dialog.dart';
import '../../../core/widgets/bottom_navigation_bar.dart';

class AppointmentScreen extends ConsumerStatefulWidget {
  const AppointmentScreen({super.key});

  @override
  ConsumerState<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends ConsumerState<AppointmentScreen> {
  DateTime _selectedDate = DateTime.now();
  int? _selectedStaffId;

  @override
  Widget build(BuildContext context) {
    final staffList = ref.watch(staffListProvider);
    final appointments = ref.watch(
      appointmentsByDateProvider(
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151520),
        elevation: 0,
        leading: Builder(
          builder: (ctx) {
            // Show menu button on mobile, hide on desktop
            if (MediaQuery.of(ctx).size.width <= 600) {
              return IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF888899)),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              );
            }
            // On desktop, show existing app drawer button or nothing
            return const SizedBox.shrink();
          },
        ),
        title: const Text(
          'Lịch hẹn',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _refreshAppointments(),
                  icon: const Icon(
                    Icons.refresh,
                    color: Color(0xFF888899),
                    size: 18,
                  ),
                  tooltip: 'Làm mới dữ liệu',
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B9D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => _showCreateDialog(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Tạo lịch', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // ① Left — Calendar + Staff filter (Desktop only)
          if (MediaQuery.of(context).size.width > 600)
            SizedBox(
              width: 220,
              child: _LeftPanel(
                selectedDate: _selectedDate,
                selectedStaffId: _selectedStaffId,
                staffList: staffList,
                appointments: appointments.value ?? [],
                onDateSelected: (date) => setState(() => _selectedDate = date),
                onStaffSelected: (id) => setState(() => _selectedStaffId = id),
              ),
            ),

          const VerticalDivider(width: 1, color: Color(0xFF252535)),

          // ② Right — Timeline (All screen sizes)
          Expanded(
            child: Column(
              children: [
                _TimelineHeader(date: _selectedDate),
                Expanded(
                  child: appointments.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF6B9D),
                      ),
                    ),
                    error: (e, _) => Center(
                      child: Text(
                        'Lỗi: $e',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    data: (appts) => _Timeline(
                      appointments: _selectedStaffId != null
                          ? appts
                                .where((a) => a.staffId == _selectedStaffId)
                                .toList()
                          : appts,
                    ),
                  ),
                ),
                _StatBar(appointments: appointments.value ?? []),
              ],
            ),
          ),
        ],
      ),
      drawer: MediaQuery.of(context).size.width <= 600
          ? Drawer(
              backgroundColor: const Color(0xFF151520),
              child: _LeftPanel(
                selectedDate: _selectedDate,
                selectedStaffId: _selectedStaffId,
                staffList: staffList,
                appointments: appointments.value ?? [],
                onDateSelected: (date) {
                  setState(() => _selectedDate = date);
                  Navigator.pop(context); // Close drawer after selection
                },
                onStaffSelected: (id) {
                  setState(() => _selectedStaffId = id);
                  Navigator.pop(context); // Close drawer after selection
                },
              ),
            )
          : const AppDrawer(),
      bottomNavigationBar: const AppointmentBottomNavigationBar(),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const CreateAppointmentDialog(),
    );
  }

  void _refreshAppointments() {
    // Clear all appointment cache
    ref.read(appointmentProvider.notifier).clearAllCache();

    // Force refresh current date's appointments
    final currentDate =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    ref.invalidate(appointmentsByDateProvider(currentDate));
  }
}

// ════════════════════════════════════════════════════
// LEFT PANEL — Calendar + Staff filter
// ════════════════════════════════════════════════════
class _LeftPanel extends StatelessWidget {
  final DateTime selectedDate;
  final int? selectedStaffId;
  final List<dynamic> staffList;
  final List<dynamic> appointments;
  final Function(DateTime) onDateSelected;
  final Function(int?) onStaffSelected;

  const _LeftPanel({
    required this.selectedDate,
    required this.selectedStaffId,
    required this.staffList,
    required this.appointments,
    required this.onDateSelected,
    required this.onStaffSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF151520),
      child: Column(
        children: [
          // Mini calendar
          _MiniCalendar(
            selectedDate: selectedDate,
            onDateSelected: onDateSelected,
          ),

          const Divider(color: Color(0xFF252535), height: 1),

          // Staff filter
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NHÂN VIÊN',
                    style: TextStyle(
                      color: Color(0xFF555566),
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tất cả
                  _StaffChip(
                    name: 'Tất cả',
                    color: const Color(0xFFFF6B9D),
                    count: appointments.length,
                    isSelected: selectedStaffId == null,
                    onTap: () => onStaffSelected(null),
                  ),

                  // Từng staff
                  ...staffList.map((staff) {
                    final count = appointments
                        .where((a) => a.staffId == staff.id)
                        .length;
                    return _StaffChip(
                      name: staff.name,
                      color: _hexToColor(staff.color ?? '#FF6B9D'),
                      count: count,
                      isSelected: selectedStaffId == staff.id,
                      onTap: () => onStaffSelected(staff.id),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// MINI CALENDAR
// ════════════════════════════════════════════════════
class _MiniCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  const _MiniCalendar({
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<_MiniCalendar> createState() => _MiniCalendarState();
}

class _MiniCalendarState extends State<_MiniCalendar> {
  late DateTime _viewMonth;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _viewMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('vi', null);
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6B9D)),
        ),
      );
    }
    final firstDay = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Month nav
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.chevron_left,
                  color: Color(0xFF555566),
                  size: 18,
                ),
                onPressed: () => setState(
                  () => _viewMonth = DateTime(
                    _viewMonth.year,
                    _viewMonth.month - 1,
                  ),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                DateFormat('MMMM, y', 'vi').format(_viewMonth),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF555566),
                  size: 18,
                ),
                onPressed: () => setState(
                  () => _viewMonth = DateTime(
                    _viewMonth.year,
                    _viewMonth.month + 1,
                  ),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Day labels
          Row(
            children: ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7']
                .map(
                  (d) => Expanded(
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF555566),
                        fontSize: 10,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),

          // Days grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (_, i) {
              if (i < startWeekday) return const SizedBox();
              final day = i - startWeekday + 1;
              final date = DateTime(_viewMonth.year, _viewMonth.month, day);
              final isSelected =
                  date.year == widget.selectedDate.year &&
                  date.month == widget.selectedDate.month &&
                  date.day == widget.selectedDate.day;
              final isToday =
                  date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;

              return GestureDetector(
                onTap: () => widget.onDateSelected(date),
                child: Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFF6B9D)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? Colors.white
                          : isToday
                          ? const Color(0xFFFF6B9D)
                          : const Color(0xFF888899),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// TIMELINE
// ════════════════════════════════════════════════════
class _Timeline extends StatelessWidget {
  final List<dynamic> appointments;
  const _Timeline({required this.appointments});

  @override
  Widget build(BuildContext context) {
    final hours = List.generate(13, (i) => i + 8); // 8h - 20h
    final now = DateTime.now();
    final nowMinutes = (now.hour - 8) * 60 + now.minute;

    return SingleChildScrollView(
      child: SizedBox(
        height: hours.length * 60.0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time column
            SizedBox(
              width: 52,
              child: Column(
                children: hours
                    .map(
                      (h) => SizedBox(
                        height: 60,
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 4, 8, 0),
                            child: Text(
                              '$h:00',
                              style: const TextStyle(
                                color: Color(0xFF555566),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

            // Appointment column
            Expanded(
              child: Stack(
                children: [
                  // Hour lines
                  Column(
                    children: hours
                        .map(
                          (_) => Container(
                            height: 60,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Color(0xFF1A1A28),
                                  width: 0.5,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),

                  // Now line
                  if (nowMinutes >= 0 && nowMinutes <= hours.length * 60)
                    Positioned(
                      top: nowMinutes.toDouble(),
                      left: 0,
                      right: 0,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF6B9D),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1.5,
                              color: const Color(0xFFFF6B9D),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Appointment cards
                  ...appointments.map((appt) => _buildApptCard(context, appt)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApptCard(BuildContext context, dynamic appt) {
    final startMinutes = appt.startHour * 60 + appt.startMinute - 8 * 60;
    final totalMinutes = appt.totalMinutes ?? 60;
    final height = (totalMinutes < 60 ? 60 : totalMinutes).toDouble() - 4;

    final statusColor = switch (appt.status) {
      'completed' => const Color(0xFF1D9E75),
      'in_progress' => const Color(0xFFA78BFA),
      _ => const Color(0xFF555566),
    };

    return Positioned(
      top: startMinutes.toDouble(),
      left: 4,
      right: 4,
      height: height,
      child: GestureDetector(
        onTap: () => _showAppointmentDetail(context, appt),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A28),
            borderRadius: BorderRadius.circular(8),
            border: Border(left: BorderSide(color: statusColor, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appt.customerName ?? 'Khách lẻ',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${appt.serviceSummary} · ${appt.staffName}',
                style: const TextStyle(color: Color(0xFF555566), fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAppointmentDetail(BuildContext context, dynamic appt) {
    showDialog(
      context: context,
      builder: (_) => AppointmentDetailDialog(appointment: appt),
    );
  }
}

// ════════════════════════════════════════════════════
// STAT BAR
// ════════════════════════════════════════════════════
class _StatBar extends StatelessWidget {
  final List<dynamic> appointments;
  const _StatBar({required this.appointments});

  @override
  Widget build(BuildContext context) {
    final vnd = NumberFormat('#,###', 'vi_VN');
    final done = appointments.where((a) => a.status == 'completed').length;
    final doing = appointments.where((a) => a.status == 'in_progress').length;
    final revenue = appointments
        .where((a) => a.status == 'completed')
        .fold<double>(0, (sum, a) => sum + (a.totalPrice ?? 0));

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF151520),
        border: Border(top: BorderSide(color: Color(0xFF252535), width: 0.5)),
      ),
      child: Row(
        children: [
          _Stat(label: 'Lịch hẹn', value: '${appointments.length}'),
          _Stat(label: 'Hoàn thành', value: '$done'),
          _Stat(label: 'Đang làm', value: '$doing'),
          _Stat(label: 'Doanh thu', value: '${vnd.format(revenue)}đ'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: const BoxDecoration(
          border: Border(
            right: BorderSide(color: Color(0xFF252535), width: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF555566), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widgets
class _TimelineHeader extends StatelessWidget {
  final DateTime date;
  const _TimelineHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF252535), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            DateFormat('EEEE, dd/MM/yyyy', 'vi').format(date),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffChip extends StatelessWidget {
  final String name;
  final Color color;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _StaffChip({
    required this.name,
    required this.color,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF252535),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? color : const Color(0xFF888899),
                ),
              ),
            ),
            Text(
              '$count',
              style: const TextStyle(fontSize: 10, color: Color(0xFF555566)),
            ),
          ],
        ),
      ),
    );
  }
}

Color _hexToColor(String hex) {
  try {
    return Color(int.parse(hex.replaceAll('#', '0xFF')));
  } catch (_) {
    return const Color(0xFFFF6B9D);
  }
}
