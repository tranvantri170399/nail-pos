// lib/core/models/service_category.dart
import 'service.dart';

class ServiceCategory {
  final int id;
  final int salonId;
  final String name;
  final String color;
  final int sortOrder;
  final bool isActive;
  final List<Service> services;

  ServiceCategory({
    required this.id,
    required this.salonId,
    required this.name,
    required this.color,
    required this.sortOrder,
    required this.isActive,
    this.services = const [],
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'],
      salonId: json['salonId'],
      name: json['name'],
      color: json['color'] ?? '#FF6B9D',
      sortOrder: json['sortOrder'] ?? 0,
      isActive: json['isActive'] ?? true,
      services: (json['services'] as List<dynamic>? ?? [])
          .map((s) => Service.fromJson(s))
          .toList(),
    );
  }
}