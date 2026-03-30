# Hướng Dẫn Tạo Lịch Hẹn với Dịch Vụ

## Tổng Quan
Hướng dẫn này giải thích cách tạo appointment (lịch hẹn) và lưu danh sách services (dịch vụ) vào appointment trong hệ thống Nail POS.

**QUAN TRỌNG:** Backend tự động tính toán `total_price` và `total_minutes`, không cần tính thủ công.

## Các Bước Thực Hiện

### 1. Chuẩn Bị Dữ Liệu

#### a. Tạo Appointment Object
```dart
final appointment = Appointment.create(
  staffId: selectedStaff.id,
  customerId: selectedCustomer?.id, // null cho khách lẻ
  scheduledDate: '2024-03-30', // Format: YYYY-MM-DD
  startTime: '09:00', // Format: HH:mm
  endTime: '10:30', // Format: HH:mm
  totalMinutes: 0, // Backend sẽ tự động tính
  totalPrice: 0, // Backend sẽ tự động tính
  status: 'confirmed', // confirmed, completed, cancelled, no_show
  note: 'Ghi chú cho lịch hẹn', // Optional
);
```

#### b. Tạo AppointmentService List
```dart
final appointmentServices = [
  AppointmentService(
    id: 0, // Backend sẽ tạo
    appointmentId: 0, // Backend sẽ set
    serviceId: service1.id,
    price: service1.price, // Giá có thể khác giá mặc định
    durationMinutes: service1.durationMinutes,
    service: service1, // Optional cho UI
  ),
  AppointmentService(
    id: 0,
    appointmentId: 0,
    serviceId: service2.id,
    price: service2.price,
    durationMinutes: service2.durationMinutes,
    service: service2,
  ),
];
```

### 2. Tạo Appointment với Services

Sử dụng method `createAppointmentWithServices` từ AppointmentNotifier:

```dart
// Trong Widget
final appointmentNotifier = ref.read(appointmentProvider.notifier);

await appointmentNotifier.createAppointmentWithServices(
  appointment: appointment,
  services: appointmentServices,
);
```

### 3. Xử Lý Kết Quả

```dart
final operationState = ref.watch(appointmentProvider);

if (operationState.isSuccess) {
  // Tạo thành công - backend đã tự động tính totals
  Navigator.of(context).pop();
  // Refresh UI nếu cần
} else if (operationState.error != null) {
  // Xử lý lỗi
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(operationState.error!)),
  );
}
```

## Flow Hoàn Chỉnh

### 1. User Interface Flow
```
1. User chọn Staff → Staff object
2. User chọn/không chọn Customer → Customer object hoặc null
3. User chọn Services → List<Service> objects
4. User chọn Date & Time → scheduledDate, startTime, endTime
5. User nhấn "Tạo Lịch Hẹn"
6. Backend tự động tính totalMinutes và totalPrice từ services
```

### 2. Backend Flow
```
1. UI tạo Appointment.create() với dữ liệu cơ bản
2. UI tạo List<AppointmentService> từ services đã chọn
3. UI gọi createAppointmentWithServices()
4. Repository gửi POST request với:
   - Appointment data (total_price và total_minutes có thể là 0)
   - List of services trong field "appointmentServices"
5. Backend tự động tính tổng tiền và tổng thời lượng
6. Backend tạo appointment trước
7. Backend tạo appointment_services records với appointmentId
8. Backend trả về appointment object với services và totals đã tính
```

## Code Example Hoàn Chỉnh

```dart
class CreateAppointmentScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<CreateAppointmentScreen> createState() => _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends ConsumerState<CreateAppointmentScreen> {
  Staff? selectedStaff;
  Customer? selectedCustomer;
  List<Service> selectedServices = [];
  DateTime selectedDate = DateTime.now();
  TimeOfDay startTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay endTime = TimeOfDay(hour: 10, minute: 30);

  Future<void> _createAppointment() async {
    // 1. Validate
    if (selectedStaff == null || selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng chọn nhân viên và dịch vụ')),
      );
      return;
    }

    // 2. Create appointment (totals sẽ được backend tính)
    final appointment = Appointment.create(
      staffId: selectedStaff!.id,
      customerId: selectedCustomer?.id,
      scheduledDate: DateFormat('yyyy-MM-dd').format(selectedDate),
      startTime: '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
      endTime: '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
      totalMinutes: 0, // Backend sẽ tự động tính
      totalPrice: 0, // Backend sẽ tự động tính
      status: 'confirmed',
    );

    // 3. Create appointment services
    final appointmentServices = selectedServices.map((service) {
      return AppointmentService(
        id: 0, // Backend sẽ tạo
        appointmentId: 0, // Backend sẽ set
        serviceId: service.id,
        price: service.price, // Giá có thể khác giá mặc định
        durationMinutes: service.durationMinutes,
        service: service, // Optional cho UI
      );
    }).toList();

    // 4. Call API
    await ref.read(appointmentProvider.notifier).createAppointmentWithServices(
      appointment: appointment,
      services: appointmentServices,
    );

    // 5. Handle result
    final operationState = ref.watch(appointmentProvider);
    if (operationState.isSuccess) {
      Navigator.of(context).pop();
    } else if (operationState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(operationState.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tạo Lịch Hẹn')),
      body: Column(
        children: [
          // UI để chọn staff, customer, services, date, time
          // ...
          
          ElevatedButton(
            onPressed: _createAppointment,
            child: Text('Tạo Lịch Hẹn'),
          ),
        ],
      ),
    );
  }
}
```

## API Endpoint Details

### POST /api/appointments
Request body:
```json
{
  "customer_id": 123,
  "staff_id": 456,
  "scheduled_date": "2024-03-30",
  "start_time": "09:00",
  "end_time": "10:30",
  "total_minutes": 0,
  "total_price": 0,
  "status": "confirmed",
  "note": "Ghi chú",
  "source": "walk_in",
  "appointmentServices": [
    {
      "serviceId": 1,
      "price": 300000,
      "durationMinutes": 60
    },
    {
      "serviceId": 2,
      "price": 200000,
      "durationMinutes": 30
    }
  ]
}
```

Response:
```json
{
  "id": 789,
  "customer_id": 123,
  "staff_id": 456,
  "scheduled_date": "2024-03-30",
  "start_time": "09:00",
  "end_time": "10:30",
  "total_minutes": 90,        // Auto-calculated by backend
  "total_price": 500000,      // Auto-calculated by backend
  "status": "confirmed",
  "source": "walk_in",
  "created_at": "2024-03-30T08:00:00Z",
  "staff": { /* Staff object */ },
  "customer": { /* Customer object */ },
  "appointmentServices": [
    {
      "id": 1001,
      "appointmentId": 789,
      "serviceId": 1,
      "price": 300000,
      "durationMinutes": 60,
      "service": { /* Service object */ }
    }
    // ... other services
  ]
}
```

## Important Notes

1. **Backend tự động tính totals**: Không cần tính `total_price` và `total_minutes` ở client
2. **Field name là "appointmentServices"**: Không phải "services" hay "appointment_services"
3. **Service ID**: Phải có `serviceId` hợp lệ từ danh sách services có sẵn
4. **Price & Duration**: Có thể khác với giá mặc định của service
5. **Error Handling**: Luôn check `operationState.error` để hiển thị thông báo lỗi
6. **Loading State**: Sử dụng `operationState.isLoading` để hiển thị loading indicator
7. **Refresh Data**: Sau khi tạo thành công, các providers sẽ tự động refresh

## Testing

```dart
// Test case: Tạo appointment với services
test('should create appointment with services', () async {
  final mockAppointment = Appointment.create(
    staffId: 1,
    scheduledDate: '2024-03-30',
    startTime: '09:00',
    endTime: '10:30',
    totalMinutes: 0, // Backend sẽ tính
    totalPrice: 0, // Backend sẽ tính
    status: 'confirmed',
  );
  
  final mockServices = [
    AppointmentService(
      id: 0,
      appointmentId: 0,
      serviceId: 1,
      price: 300000,
      durationMinutes: 60,
    ),
  ];
  
  await notifier.createAppointmentWithServices(
    appointment: mockAppointment,
    services: mockServices,
  );
  
  expect(state.isSuccess, true);
  expect(state.error, null);
});
```
