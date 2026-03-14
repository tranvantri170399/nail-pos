// lib/core/models/service.dart
class Service {
  final int id;
  final int? salonId;
  final int? categoryId;
  final String name;
  final double price;
  final int durationMinutes;
  final String? color;
  final bool isActive;

  Service({
    required this.id,
    this.salonId,
    this.categoryId,
    required this.name,
    required this.price,
    required this.durationMinutes,
    this.color,
    required this.isActive,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      salonId: json['salonId'],
      categoryId: json['categoryId'],
      name: json['name'],
      price: double.tryParse(json['price'].toString()) ?? 0,
      durationMinutes: json['durationMinutes'] ?? 0,
      color: json['color'],
      isActive: json['isActive'] ?? true,
    );
  }
}