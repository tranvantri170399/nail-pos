// lib/features/appointments/widgets/create_appointment_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/staff.dart';
import '../../../core/models/service.dart';
import '../../../core/models/customer.dart';
import '../../../core/models/appointment.dart';
import '../../../core/models/appointment_service.dart';
import '../../../core/providers/app_data_provider.dart';
import '../providers/appointment_provider.dart';
import '../../customer/customer_provider.dart';

class CreateAppointmentDialog extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  const CreateAppointmentDialog({super.key, this.initialDate});

  @override
  ConsumerState<CreateAppointmentDialog> createState() =>
      _CreateAppointmentDialogState();
}

class _CreateAppointmentDialogState
    extends ConsumerState<CreateAppointmentDialog> {
  final _phoneCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _customerNameCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  Staff? _selectedStaff;
  Customer? _foundCustomer;
  final List<Service> _selectedServices = [];
  bool _isSearching = false;
  bool _showCreateCustomer = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) _selectedDate = widget.initialDate!;
    // Initialize end time to 1 hour after start time
    final startTotalMinutes = _startTime.hour * 60 + _startTime.minute;
    _endTime = TimeOfDay(
      hour: (startTotalMinutes + 60) ~/ 60,
      minute: (startTotalMinutes + 60) % 60,
    );
  }

  // Tổng thời gian (phút)
  int get _totalMinutes =>
      _selectedServices.fold(0, (s, e) => s + e.durationMinutes);

  // Giờ kết thúc
  TimeOfDay get _calculatedEndTime {
    final totalMins = _startTime.hour * 60 + _startTime.minute + _totalMinutes;
    return TimeOfDay(hour: totalMins ~/ 60, minute: totalMins % 60);
  }

  // Tổng tiền
  double get _totalPrice => _selectedServices.fold(0, (s, e) => s + e.price);

  @override
  Widget build(BuildContext context) {
    final staffList = ref.watch(staffListProvider);
    final categories = ref.watch(categoriesProvider);
    final vnd = NumberFormat('#,###', 'vi_VN');

    return Dialog(
      backgroundColor: const Color(0xFF151520),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ① Khách hàng
                    _buildCustomerSection(),
                    const SizedBox(height: 16),

                    // ② Ngày + Giờ
                    Row(
                      children: [
                        Expanded(flex: 3, child: _buildDateField()),
                        const SizedBox(width: 12),
                        Expanded(flex: 7, child: _buildTimeField()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ③ Chọn thợ
                    _buildLabel('Chọn thợ'),
                    const SizedBox(height: 8),
                    _buildStaffGrid(staffList),
                    const SizedBox(height: 16),

                    // ④ Dịch vụ
                    _buildLabel('Dịch vụ'),
                    const SizedBox(height: 8),
                    _buildServicesGrid(categories),
                    const SizedBox(height: 16),

                    // ⑤ Ghi chú
                    _buildLabel('Ghi chú'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _noteCtrl,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _inputDecoration('Yêu cầu đặc biệt...'),
                    ),
                  ],
                ),
              ),
            ),
            _buildFooter(vnd),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // HEADER
  // ════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF252535), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Tạo lịch hẹn',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF555566), size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // KHÁCH HÀNG
  // ════════════════════════════════════════════════════
  Widget _buildCustomerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Khách hàng'),
        const SizedBox(height: 6),
        if (!_showCreateCustomer) ...[
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Nhập SĐT để tìm khách...').copyWith(
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFF6B9D),
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(
                        Icons.person_add,
                        color: Color(0xFFFF6B9D),
                        size: 18,
                      ),
                      onPressed: () =>
                          setState(() => _showCreateCustomer = true),
                      tooltip: 'Thêm khách hàng mới',
                    ),
            ),
            onChanged: _searchCustomer,
          ),

          // Hiển thị khách tìm được
          if (_foundCustomer != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1E14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1D9E75), width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D3557),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _foundCustomer!.name[0],
                      style: const TextStyle(
                        color: Color(0xFF85B7EB),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _foundCustomer!.name,
                          style: const TextStyle(
                            color: Color(0xFF1D9E75),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${_foundCustomer!.phone} · ${_foundCustomer!.visitCount} lần ghé',
                          style: const TextStyle(
                            color: Color(0xFF555566),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _foundCustomer = null),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF555566),
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Hiển thị nút thêm khách hàng nếu không tìm thấy
          if (_phoneCtrl.text.length >= 9 &&
              _foundCustomer == null &&
              !_isSearching) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2D1020),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF6B9D), width: 0.5),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_add,
                    color: Color(0xFFFF6B9D),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Không tìm thấy khách hàng',
                      style: TextStyle(color: Color(0xFFFF6B9D), fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _showCreateCustomer = true),
                    child: const Text(
                      'Thêm mới',
                      style: TextStyle(color: Color(0xFFFF6B9D), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ] else ...[
          // Form tạo khách hàng mới
          _buildCreateCustomerForm(),
        ],
      ],
    );
  }

  // ════════════════════════════════════════════════════
  // CREATE CUSTOMER FORM
  // ════════════════════════════════════════════════════
  Widget _buildCreateCustomerForm() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFF6B9D), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_add, color: Color(0xFFFF6B9D), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Thêm khách hàng mới',
                style: TextStyle(
                  color: Color(0xFFFF6B9D),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showCreateCustomer = false;
                    _customerNameCtrl.clear();
                    _phoneCtrl.clear();
                  });
                },
                icon: const Icon(
                  Icons.close,
                  color: Color(0xFF555566),
                  size: 16,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customerNameCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Tên khách hàng *'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Số điện thoại *'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _showCreateCustomer = false;
                    _customerNameCtrl.clear();
                    _phoneCtrl.clear();
                  });
                },
                child: const Text(
                  'Huỷ',
                  style: TextStyle(color: Color(0xFF555566)),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B9D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                ),
                onPressed: _createNewCustomer,
                child: const Text('Lưu', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // NGÀY & GIỜ
  // ════════════════════════════════════════════════════
  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Ngày hẹn'),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF252535), width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF555566),
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Giờ hẹn'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _pickStartTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF252535),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Color(0xFF555566),
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _startTime.format(context),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: _pickEndTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF252535),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Color(0xFF555566),
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _endTime.format(context),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════
  // STAFF GRID
  // ════════════════════════════════════════════════════
  Widget _buildStaffGrid(List<Staff> staffList) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: staffList.length,
      itemBuilder: (_, i) {
        final staff = staffList[i];
        final isSelected = _selectedStaff?.id == staff.id;
        final color = _hexToColor(staff.color ?? '#FF6B9D');

        return GestureDetector(
          onTap: () =>
              setState(() => _selectedStaff = isSelected ? null : staff),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? color : const Color(0xFF252535),
                width: 0.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    staff.name[0],
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  staff.name,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? color : const Color(0xFF888899),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════
  // SERVICES GRID
  // ════════════════════════════════════════════════════
  Widget _buildServicesGrid(List<dynamic> categories) {
    final allServices = categories
        .expand((c) => c.services as List<Service>)
        .toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.5,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: allServices.length,
      itemBuilder: (_, i) {
        final svc = allServices[i];
        final isSelected = _selectedServices.any((s) => s.id == svc.id);
        final vnd = NumberFormat('#,###', 'vi_VN');

        return GestureDetector(
          onTap: () => setState(() {
            isSelected
                ? _selectedServices.removeWhere((s) => s.id == svc.id)
                : _selectedServices.add(svc);
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2D1020) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFF6B9D)
                    : const Color(0xFF252535),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        svc.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFFFF6B9D)
                              : const Color(0xFF888899),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${vnd.format(svc.price)}đ · ${svc.durationMinutes}p',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF555566),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected ? Icons.check_circle : Icons.add_circle_outline,
                  color: isSelected
                      ? const Color(0xFFFF6B9D)
                      : const Color(0xFF252535),
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════
  // FOOTER
  // ════════════════════════════════════════════════════
  Widget _buildFooter(NumberFormat vnd) {
    final canConfirm = _selectedStaff != null && _selectedServices.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF252535), width: 0.5)),
      ),
      child: Row(
        children: [
          // Tổng thời gian + tiền
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_totalMinutes phút',
                style: const TextStyle(color: Color(0xFF555566), fontSize: 12),
              ),
              Text(
                '${vnd.format(_totalPrice)}đ',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Buttons
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Huỷ',
              style: TextStyle(color: Color(0xFF555566)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: canConfirm
                  ? const Color(0xFFFF6B9D)
                  : const Color(0xFF252535),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            onPressed: canConfirm ? _confirm : null,
            child: const Text(
              'Đặt lịch',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // ACTIONS
  // ════════════════════════════════════════════════════
  Future<void> _searchCustomer(String phone) async {
    if (phone.length < 9) {
      setState(() => _foundCustomer = null);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final repo = ref.read(appointmentRepositoryProvider);
      final customer = await repo.findCustomerByPhone(phone);
      setState(() {
        _foundCustomer = customer;
        _isSearching = false;
      });
    } catch (_) {
      setState(() {
        _foundCustomer = null;
        _isSearching = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFFFF6B9D)),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFFFF6B9D)),
        ),
        child: child!,
      ),
    );
    if (time != null) {
      setState(() {
        _startTime = time;
        // Auto-calculate end time if it was previously calculated
        if (_endTime.hour == _calculatedEndTime.hour &&
            _endTime.minute == _calculatedEndTime.minute) {
          _endTime = _calculatedEndTime;
        }
      });
    }
  }

  Future<void> _pickEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFFFF6B9D)),
        ),
        child: child!,
      ),
    );
    if (time != null) setState(() => _endTime = time);
  }

  Future<void> _createNewCustomer() async {
    final name = _customerNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập đầy đủ thông tin'),
            backgroundColor: Color(0xFFFF6B9D),
          ),
        );
      }
      return;
    }

    try {
      final customerNotifier = ref.read(customerOperationProvider.notifier);
      final salonId = ref.read(salonProvider)?.id ?? 1;

      await customerNotifier.createCustomer(
        salonId: salonId,
        name: name,
        phone: phone,
      );

      // Search for the newly created customer
      await _searchCustomer(phone);

      setState(() {
        _showCreateCustomer = false;
        _customerNameCtrl.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm khách hàng mới'),
            backgroundColor: Color(0xFF1D9E75),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirm() async {
    final notifier = ref.read(appointmentProvider.notifier);

    // Create appointment object first (without services)
    final appointment = Appointment.create(
      staffId: _selectedStaff!.id,
      customerId: _foundCustomer?.id,
      scheduledDate:
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
      startTime:
          '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
      endTime:
          '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
      totalMinutes: _totalMinutes,
      totalPrice: _totalPrice,
      status: 'confirmed',
      note: _noteCtrl.text.trim(),
    );

    // Create appointment services from selected services
    final appointmentServices = _selectedServices.map((service) {
      return AppointmentService(
        id: 0, // Will be set by database
        appointmentId: 0, // Will be set by database
        serviceId: service.id,
        price: service.price,
        durationMinutes: service.durationMinutes,
        service: service,
      );
    }).toList();

    await notifier.createAppointmentWithServices(
      appointment,
      appointmentServices,
    );
    if (mounted) Navigator.pop(context);
  }

  // Helpers
  Widget _buildLabel(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      color: Color(0xFF555566),
      fontSize: 10,
      letterSpacing: 1.0,
    ),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF2A2A3A), fontSize: 13),
    filled: true,
    fillColor: const Color(0xFF0D0D14),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF252535), width: 0.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF252535), width: 0.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFFF6B9D), width: 1),
    ),
  );

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return const Color(0xFFFF6B9D);
    }
  }
}
