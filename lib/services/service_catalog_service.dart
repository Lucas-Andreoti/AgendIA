
import 'dart:convert';

import '../models/salon_service.dart';
import 'api_client.dart';

class ServiceCatalogService {
  ServiceCatalogService._();

  static final ServiceCatalogService instance =
      ServiceCatalogService._();

  // Consulta os serviços cadastrados no servidor.
  Future<List<SalonService>> fetchServices() async {
    final response = await ApiClient.instance
        .get('/get/services')
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      throw Exception(
        'Sessão inválida ou expirada.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao consultar serviços: '
        '${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw const FormatException(
        'Formato de serviços inválido.',
      );
    }

    final services = decoded.map((item) {
      return SalonService.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
    }).toList();

    return services;
  }
  
  Future<void> createService({
    required String name,
    required String description,
    required double price,
    required int durationMinutes,
  }) async {
    final service = SalonService(
      id: 0,
      name: name,
      description: description,
      price: price,
      durationMinutes: durationMinutes,
    );

    final response = await ApiClient.instance
        .post(
          '/create/service',
          body: service.toJson(),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      throw Exception(
        'Sessão inválida ou expirada.',
      );
    }

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
        'Erro ao cadastrar serviço: '
        '${response.statusCode}',
      );
    }
  }
  Future<void> updateService(
    SalonService service,
  ) async {
      final response = await ApiClient.instance
        .put(
          '/update/service',
          body: service.toJson(), 
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      throw Exception(
        'Sessão inválida ou expirada.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao atualizar serviço: '
        '${response.statusCode}',
      );
    }
  }
  
  Future<void> deleteService(int serviceId) async {
    final response = await ApiClient.instance
          .delete('/delete/service/$serviceId')
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      throw Exception(
        'Sessão inválida ou expirada.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao excluir serviço: '
        '${response.statusCode}',
      );
    }
  }



}
