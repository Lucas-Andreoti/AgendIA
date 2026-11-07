
class SalonService {
  final int id;
  final String name;
  final String description;
  final double price;
  final int durationMinutes;

  const SalonService({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
  });

  // Converte o JSON da API em um objeto SalonService.
  factory SalonService.fromJson(
    Map<String, dynamic> json,
  ) {
    return SalonService(
      id: json['serviceId'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      durationMinutes: json['durationMinutes'] as int,
    );
  }

  // Prepara o objeto para envio à API.
  Map<String, dynamic> toJson() {
    return {
      'serviceId': id,
      'name': name,
      'description': description,
      'price': price,
      'durationMinutes': durationMinutes,
    };
  }
}
