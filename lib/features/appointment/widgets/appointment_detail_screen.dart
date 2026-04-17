// lib/features/appointment/widgets/appointment_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/appointment.dart';
import '../providers/appointment_provider.dart';

class AppointmentDetailScreen extends ConsumerStatefulWidget {
  final Appointment appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  ConsumerState<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState
    extends ConsumerState<AppointmentDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final appt = widget.appointment;
    final vnd = NumberFormat('#,###', 'vi_VN');

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151520),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Chi tiết lịch hẹn',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        actions: [
          if (appt.status != 'completed')
            IconButton(
              icon: const Icon(Icons.check_circle, color: Color(0xFF1D9E75)),
              onPressed: () => _completeAppointment(),
            ),
          IconButton(
            icon: const Icon(Icons.delete, color: Color(0xFFEF4444)),
            onPressed: () => _deleteAppointment(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            _buildStatusBadge(appt.status),
            const SizedBox(height: 20),

            // Customer info
            _buildSection('Thông tin khách hàng', [
              _buildInfoRow(
                Icons.person,
                'Tên',
                appt.customer?.name ?? 'Khách lẻ',
              ),
              _buildInfoRow(
                Icons.phone,
                'SĐT',
                appt.customer?.phone ?? 'Không có',
              ),
            ]),

            const SizedBox(height: 16),

            // Service info
            _buildSection('Dịch vụ', [
              _buildInfoRow(
                Icons.timer,
                'Thời gian',
                '${appt.totalMinutes} phút',
              ),
              _buildInfoRow(
                Icons.attach_money,
                'Giá',
                '${vnd.format(appt.totalPrice)}đ',
              ),
            ]),

            const SizedBox(height: 16),

            // Schedule info
            _buildSection('Lịch hẹn', [
              _buildInfoRow(Icons.calendar_today, 'Ngày', appt.scheduledDate),
              _buildInfoRow(
                Icons.access_time,
                'Giờ',
                '${appt.startTime} - ${appt.endTime}',
              ),
            ]),

            const SizedBox(height: 16),

            // Staff info
            _buildSection('Nhân viên', [
              _buildInfoRow(Icons.work, 'Tên', appt.staff?.name ?? 'Không có'),
            ]),

            if (appt.note != null && appt.note!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSection('Ghi chú', [
                _buildInfoRow(Icons.note, 'Nội dung', appt.note!),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final (label, color) = switch (status) {
      'pending' => ('Chờ xử lý', const Color(0xFF888899)),
      'confirmed' => ('Đã xác nhận', const Color(0xFF3B82F6)),
      'in_progress' => ('Đang thực hiện', const Color(0xFFA78BFA)),
      'completed' => ('Hoàn thành', const Color(0xFF1D9E75)),
      'cancelled' => ('Đã hủy', const Color(0xFFEF4444)),
      _ => ('Chờ xử lý', const Color(0xFF888899)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151520),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF555566),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF555566)),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF888899), fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeAppointment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A28),
        title: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Đánh dấu lịch hẹn này đã hoàn thành?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Xác nhận',
              style: TextStyle(color: Color(0xFF1D9E75)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(appointmentProvider.notifier)
          .updateStatus(
            widget.appointment.id,
            'completed',
            widget.appointment.scheduledDate,
          );

      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _deleteAppointment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A28),
        title: const Text(
          'Xác nhận xóa',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Bạn có chắc muốn xóa lịch hẹn này?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Xóa',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(appointmentProvider.notifier)
          .deleteAppointment(
            widget.appointment.id,
            widget.appointment.scheduledDate,
          );

      if (mounted) Navigator.pop(context);
    }
  }
}
