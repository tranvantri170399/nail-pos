// lib/core/models/staff.dart
class Staff {
  final int id;
  final String name;
  final String phone;
  final String? color;
  final String role;
  final double commissionRate;
  final bool isActive;

  Staff({
    required this.id,
    required this.name,
    required this.phone,
    this.color,
    required this.role,
    required this.commissionRate,
    required this.isActive,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      color: json['color'],
      role: json['role'] ?? 'junior',
      commissionRate: double.tryParse(json['commission_rate'].toString()) ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }
}