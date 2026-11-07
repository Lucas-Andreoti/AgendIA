class BusinessHours {
  final int id;
  final int weekday;
  final bool enabled;
  final String openingTime;
  final String closingTime;

  BusinessHours({
    required this.id,
    required this.weekday,
    required this.enabled,
    required this.openingTime,
    required this.closingTime,
  });

  // Converte o JSON recebido da API em BusinessHours.
  factory BusinessHours.fromJson(
    Map<String, dynamic> json,
  ) {
    final weekday = json['weekday'] as int;

    return BusinessHours(
      // A API não retorna um ID separado.
      // Usamos weekday como identificador local.
      id: weekday,
      weekday: weekday,
      enabled: json['enabled'] as bool,
      openingTime: json['openingTime'] as String,
      closingTime: json['closingTime'] as String,
    );
  }

  // Converte BusinessHours para o JSON exigido pela API.
  Map<String, dynamic> toJson() {
    return {
      'weekday': weekday,
      'enabled': enabled,
      'openingTime': openingTime,
      'closingTime': closingTime,
    };
  }
}
