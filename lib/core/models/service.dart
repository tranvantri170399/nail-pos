class NailService {
  final int id;
  final String name;
  final double price;
  final int durationMinutes;
  final String color;
  final String category;

  NailService({
    required this.id,
    required this.name,
    required this.price,
    required this.durationMinutes,
    required this.color,
    required this.category,
  });

  factory NailService.fromJson(Map<String, dynamic> json) => NailService(
    id:              json['id'],
    name:            json['name'],
    price:           double.parse(json['price'].toString()),
    durationMinutes: json['duration_minutes'],
    color:           json['color'] ?? '#FF6B9D',
    category:        json['category'] ?? 'Tay',
  );
}