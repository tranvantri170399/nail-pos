// lib/core/models/customer.dart

class Customer {
  final int id;
  final String name;
  final String phone;
  final int? visitCount;
  final DateTime? lastVisit;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.visitCount,
    this.lastVisit,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id:         json['id'] as int,
      name:       json['name'] as String,
      phone:      json['phone'] as String,
      visitCount: json['visit_count'] as int?,
      lastVisit:  json['last_visit'] != null
          ? DateTime.tryParse(json['last_visit'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':    id,
    'name':  name,
    'phone': phone,
  };
}
