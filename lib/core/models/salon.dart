// lib/core/models/salon.dart
class Salon {
  final int id;
  final int ownerId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? logoUrl;
  final String openingTime;
  final String closingTime;
  final List<String> workingDays;
  final String currency;
  final double taxRate;
  final bool tipEnabled;
  final double defaultTip;
  final int slotDuration;
  final bool isActive;

  Salon({
    required this.id,
    required this.ownerId,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.logoUrl,
    required this.openingTime,
    required this.closingTime,
    required this.workingDays,
    required this.currency,
    required this.taxRate,
    required this.tipEnabled,
    required this.defaultTip,
    required this.slotDuration,
    required this.isActive,
  });

  factory Salon.fromJson(Map<String, dynamic> json) {
    return Salon(
      id: json['id'],
      ownerId: json['ownerId'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      city: json['city'],
      logoUrl: json['logoUrl'],
      openingTime: json['openingTime'] ?? '09:00',
      closingTime: json['closingTime'] ?? '20:00',
      workingDays: List<String>.from(json['workingDays'] ?? []),
      currency: json['currency'] ?? 'VND',
      taxRate: double.tryParse(json['taxRate'].toString()) ?? 0,
      tipEnabled: json['tipEnabled'] ?? true,
      defaultTip: double.tryParse(json['defaultTip'].toString()) ?? 0,
      slotDuration: json['slotDuration'] ?? 15,
      isActive: json['isActive'] ?? true,
    );
  }
}