// lib/core/models/user_model.dart
class UserModel {
  final int id;
  final int? salonId;      // ← thêm
  final String name;
  final String role;
  final String type;
  final String? color;
  final String? salonName;
  final String? phone;

  const UserModel({
    required this.id,
    this.salonId,          // ← thêm
    required this.name,
    required this.role,
    required this.type,
    this.color,
    this.salonName,
    this.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:        json['id'] as int,
      salonId:   json['salonId'] as int?,   // ← thêm
      name:      json['name'] as String,
      role:      json['role'] as String,
      type:      json['type'] as String,
      color:     json['color'] as String?,
      salonName: json['salon_name'] as String?,
      phone:     json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':        id,
    'salonId':  salonId,   // ← thêm
    'name':      name,
    'role':      role,
    'type':      type,
    'color':     color,
    'salon_name': salonName,
    'phone':     phone,
  };

  bool get isOwner => type == 'owner';
  bool get isStaff => type == 'staff';
  bool get isSenior => role == 'senior';
  String get displayColor => color ?? '#FF6B9D';

  @override
  String toString() => 'UserModel(id: $id, name: $name, type: $type)';
}