import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/appointment.dart';
import '../../../core/models/appointment_service.dart';
import '../providers/appointment_provider.dart';

class AppointmentDetailDialog extends ConsumerStatefulWidget {
  final Appointment appointment;

  const AppointmentDetailDialog({super.key, required this.appointment});

  @override
  ConsumerState<AppointmentDetailDialog> createState() =>
      _AppointmentDetailDialogState();
}

class _AppointmentDetailDialogState
    extends ConsumerState<AppointmentDetailDialog> {
  String? _selectedStatus;
  List<AppointmentService>? _services;
  bool _isLoadingServices = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.appointment.status;
    _loadServicesIfNeeded();
  }

  Future<void> _loadServicesIfNeeded() async {
    if (widget.appointment.services != null &&
        widget.appointment.services!.isNotEmpty) {
      _services = widget.appointment.services;
      return;
    }

    setState(() {
      _isLoadingServices = true;
    });

    try {
      final services = await ref
          .read(appointmentProvider.notifier)
          .getAppointmentServices(widget.appointment.id);

      if (mounted) {
        setState(() {
          _services = services;
          _isLoadingServices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingServices = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vnd = NumberFormat('#,###', 'vi_VN');
    final operationState = ref.watch(appointmentProvider);

    return Dialog(
      backgroundColor: const Color(0xFF1A1A28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    color: _getStatusColor(),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Chi tiết lịch hẹn #${widget.appointment.id}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Color(0xFF888899)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Info sections
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column
                Expanded(
                  child: _buildInfoSection([
                    _InfoItem(
                      label: 'Khách hàng',
                      value: widget.appointment.customerName,
                      icon: Icons.person,
                    ),
                    _InfoItem(
                      label: 'Nhân viên',
                      value: widget.appointment.staffName,
                      icon: Icons.person_outline,
                    ),
                    _InfoItem(
                      label: 'Ngày hẹn',
                      value: DateFormat('dd/MM/yyyy', 'vi').format(
                        DateTime.parse(widget.appointment.scheduledDate),
                      ),
                      icon: Icons.calendar_today,
                    ),
                    _InfoItem(
                      label: 'Thời gian',
                      value:
                          '${widget.appointment.startTime} - ${widget.appointment.endTime}',
                      icon: Icons.access_time,
                    ),
                  ]),
                ),
                const SizedBox(width: 20),
                // Right column
                Expanded(
                  child: _buildInfoSection([
                    _InfoItem(
                      label: 'Thời lượng',
                      value: '${widget.appointment.totalMinutes} phút',
                      icon: Icons.hourglass_empty,
                    ),
                    _InfoItem(
                      label: 'Tổng tiền',
                      value: '${vnd.format(widget.appointment.totalPrice)}đ',
                      icon: Icons.attach_money,
                    ),
                    _InfoItem(
                      label: 'Nguồn',
                      value: widget.appointment.source.toUpperCase(),
                      icon: Icons.source,
                    ),
                    if (widget.appointment.note != null &&
                        widget.appointment.note!.isNotEmpty)
                      _InfoItem(
                        label: 'Ghi chú',
                        value: widget.appointment.note!,
                        icon: Icons.note,
                        maxLines: 3,
                      ),
                  ]),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Services section
            if (_isLoadingServices)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFFF6B9D),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Đang tải dịch vụ...',
                      style: TextStyle(color: Color(0xFF888899), fontSize: 14),
                    ),
                  ],
                ),
              )
            else if (_services != null && _services!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dịch vụ',
                      style: TextStyle(
                        color: Color(0xFF888899),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._services!.map((service) => _buildServiceItem(service)),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Không có dịch vụ',
                  style: TextStyle(color: Color(0xFF888899), fontSize: 14),
                ),
              ),

            const SizedBox(height: 24),

            // Status section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trạng thái',
                    style: TextStyle(
                      color: Color(0xFF888899),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatusChip('pending', 'Chờ xử lý'),
                      _buildStatusChip('confirmed', 'Đã xác nhận'),
                      _buildStatusChip('in_progress', 'Đang làm'),
                      _buildStatusChip('completed', 'Hoàn thành'),
                      _buildStatusChip('cancelled', 'Đã hủy'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B9D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: operationState.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save, size: 16),
                    label: Text(
                      operationState.isLoading ? 'Đang lưu...' : 'Cập nhật',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteAppointment(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE74C3C),
                      side: const BorderSide(color: Color(0xFFE74C3C)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Xóa', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ),

            // Error message
            if (operationState.error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE74C3C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFE74C3C).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Color(0xFFE74C3C), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        operationState.error!,
                        style: const TextStyle(
                          color: Color(0xFFE74C3C),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(List<_InfoItem> items) {
    return Column(children: items.map((item) => _buildInfoItem(item)).toList());
  }

  Widget _buildInfoItem(_InfoItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: const Color(0xFF888899), size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    color: Color(0xFF888899),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: item.maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(AppointmentService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A28),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.serviceName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service.formattedDuration,
                  style: const TextStyle(
                    color: Color(0xFF888899),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            service.formattedPrice,
            style: const TextStyle(
              color: Color(0xFFFF6B9D),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, String label) {
    final isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? _getStatusColorForStatus(status)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _getStatusColorForStatus(status), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : _getStatusColorForStatus(status),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() => _getStatusColorForStatus(widget.appointment.status);

  Color _getStatusColorForStatus(String status) {
    return switch (status) {
      'completed' => const Color(0xFF1D9E75),
      'in_progress' => const Color(0xFFA78BFA),
      'confirmed' => const Color(0xFF3B82F6),
      'cancelled' => const Color(0xFFEF4444),
      _ => const Color(0xFF888899), // pending
    };
  }

  IconData _getStatusIcon() {
    return switch (widget.appointment.status) {
      'completed' => Icons.check_circle,
      'in_progress' => Icons.play_circle,
      'confirmed' => Icons.event_available,
      'cancelled' => Icons.cancel,
      _ => Icons.schedule, // pending
    };
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == null ||
        _selectedStatus == widget.appointment.status) {
      return;
    }

    await ref
        .read(appointmentProvider.notifier)
        .updateStatus(
          widget.appointment.id,
          _selectedStatus!,
          widget.appointment.scheduledDate,
        );

    if (mounted && !ref.read(appointmentProvider).isLoading) {
      if (ref.read(appointmentProvider).isSuccess) {
        Navigator.of(context).pop();
      }
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
          style: TextStyle(color: Color(0xFF888899)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Color(0xFF888899)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Xóa',
              style: TextStyle(color: Color(0xFFE74C3C)),
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

      if (mounted && !ref.read(appointmentProvider).isLoading) {
        if (ref.read(appointmentProvider).isSuccess) {
          Navigator.of(context).pop();
        }
      }
    }
  }
}

class _InfoItem {
  final String label;
  final String value;
  final IconData icon;
  final int maxLines;

  _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
    this.maxLines = 1,
  });
}
