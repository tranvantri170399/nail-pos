// lib/core/models/user_model.dart

class UserModel {
  final int id;
  final String name;
  final String role;       // owner | senior | junior
  final String type;       // owner | staff
  final String? color;     // Màu đại diện nhân viên
  final String? salonName; // Tên tiệm (chỉ có ở owner)
  final String? phone;

  const UserModel({
    required this.id,
    required this.name,
    required this.role,
    required this.type,
    this.color,
    this.salonName,
    this.phone,
  });

  // Parse từ JSON API trả về
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:         json['id'] as int,
      name:       json['name'] as String,
      role:       json['role'] as String,
      type:       json['type'] as String,
      color:      json['color'] as String?,
      salonName:  json['salon_name'] as String?,
      phone:      json['phone'] as String?,
    );
  }

  // Convert sang JSON để lưu local
  Map<String, dynamic> toJson() => {
    'id':         id,
    'name':       name,
    'role':       role,
    'type':       type,
    'color':      color,
    'salon_name': salonName,
    'phone':      phone,
  };

  // Helper getters
  bool get isOwner => type == 'owner';
  bool get isStaff => type == 'staff';
  bool get isSenior => role == 'senior';

  // Màu hiển thị (mặc định nếu null)
  String get displayColor => color ?? '#FF6B9D';

  @override
  String toString() => 'UserModel(id: $id, name: $name, type: $type)';
}