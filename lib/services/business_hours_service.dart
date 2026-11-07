import 'dart:convert';

import '../models/business_hours.dart';
import 'api_client.dart';

class BusinessHoursService {
  BusinessHoursService._();

  static final BusinessHoursService instance =
      BusinessHoursService._();

  // Dados temporários para manter compatibilidade
  // com a tela existente até integrarmos o carregamento.
  final List<BusinessHours> _businessHours = [
    BusinessHours(
      id: 1,
      weekday: 1,
      enabled: false,
      openingTime: '08:00',
      closingTime: '17:00',
    ),
    BusinessHours(
      id: 2,
      weekday: 2,
      enabled: true,
      openingTime: '08:00',
      closingTime: '17:00',
    ),
    BusinessHours(
      id: 3,
      weekday: 3,
      enabled: true,
      openingTime: '08:00',
      closingTime: '17:00',
    ),
    BusinessHours(
      id: 4,
      weekday: 4,
      enabled: true,
      openingTime: '08:00',
      closingTime: '17:00',
    ),
    BusinessHours(
      id: 5,
      weekday: 5,
      enabled: true,
      openingTime: '08:00',
      closingTime: '17:00',
    ),
    BusinessHours(
      id: 6,
      weekday: 6,
      enabled: true,
      openingTime: '08:00',
      closingTime: '12:00',
    ),
    BusinessHours(
      id: 7,
      weekday: 7,
      enabled: false,
      openingTime: '08:00',
      closingTime: '17:00',
    ),
  ];

  // Retorna os horários armazenados em memória.
  List<BusinessHours> getBusinessHours() {
    return List.from(_businessHours);
  }

  // Consulta os horários reais no servidor.
  Future<List<BusinessHours>> fetchBusinessHours() async {
    final response = await ApiClient.instance
        .get('/get/business-hours')
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      throw Exception(
        'Sessão inválida ou expirada.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao consultar horários de funcionamento: '
        '${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw const FormatException(
        'Formato de horários de funcionamento inválido.',
      );
    }

    final businessHours = decoded.map((item) {
      return BusinessHours.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
    }).toList();

    businessHours.sort(
      (a, b) => a.weekday.compareTo(b.weekday),
    );

    // Atualiza a lista somente após uma consulta válida.
    _businessHours
      ..clear()
      ..addAll(businessHours);

    return List.from(_businessHours);
  }

  // Envia as configurações semanais para a API.
  Future<void> updateBusinessHours(
    List<BusinessHours> businessHours,
  ) async {
    // Evita enviar uma configuração semanal incompleta.
    final weekdays = businessHours
        .map((hours) => hours.weekday)
        .toSet();

    if (businessHours.length != 7 ||
        weekdays.length != 7 ||
        !weekdays.containsAll(
          [1, 2, 3, 4, 5, 6, 7],
        )) {
      throw ArgumentError(
        'É necessário informar os sete dias da semana.',
      );
    }

    final payload = businessHours
        .map((hours) => hours.toJson())
        .toList();

    final response = await ApiClient.instance
        .put(
          '/update/business-hours',
          body: payload,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      throw Exception(
        'Sessão inválida ou expirada.',
      );
    }

    if (response.statusCode != 200 &&
        response.statusCode != 204) {
      throw Exception(
        'Erro ao salvar horários de funcionamento: '
        '${response.statusCode}',
      );
    }

    // Atualiza a memória somente após
    // a confirmação do servidor.
    _businessHours
      ..clear()
      ..addAll(businessHours);
  }
}