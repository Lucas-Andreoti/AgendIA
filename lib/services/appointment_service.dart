
import 'dart:convert';

import '../models/appointment.dart';
import 'api_client.dart';

class AppointmentService {
  AppointmentService._();

  static final AppointmentService instance =
      AppointmentService._();

  // Dados temporários utilizados antes da consulta à API.
  final List<Appointment> _appointments = [
    Appointment(
      id: 1,
      date: DateTime(2026, 8, 17),
      time: '09:00',
      client: 'Maria',
      service: 'Corte de cabelo',
    ),
    Appointment(
      id: 2,
      date: DateTime(2026, 8, 17),
      time: '10:30',
      client: 'Ana',
      service: 'Escova',
    ),
    Appointment(
      id: 3,
      date: DateTime(2026, 8, 18),
      time: '14:00',
      client: 'Juliana',
      service: 'Corte + Escova',
    ),
  ];

  List<Appointment> getAppointments() =>
      List.from(_appointments);

  Future<List<Appointment>> fetchAppointments({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final appointments = await _fetchAppointmentsBetween(
      startDate: startDate,
      endDate: endDate,
    );

    // Somente a consulta principal da Agenda
    // altera o cache.
    _appointments
      ..clear()
      ..addAll(appointments);

    return List.from(_appointments);
  }

  // Consulta agendamentos de um dia para
  // verificar conflitos.
  // Não altera o cache da Agenda.
  Future<List<Appointment>>
      fetchAppointmentsForConflictCheck(
    DateTime date,
  ) {
    return _fetchAppointmentsBetween(
      startDate: DateTime(
        date.year,
        date.month,
        date.day,
      ),
      endDate: DateTime(
        date.year,
        date.month,
        date.day,
        23,
        59,
        59,
      ),
    );
  }

  Future<List<Appointment>>
      _fetchAppointmentsBetween({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final endpoint = Uri(
      path: '/get/appointments',
      queryParameters: {
        'data-inicio': _formatApiDateTime(startDate),
        'data-final': _formatApiDateTime(endDate),
      },
    ).toString();

    final response = await ApiClient.instance
        .get(endpoint)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      throw Exception(
        'Sessão inválida ou expirada.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao consultar agendamentos: '
        '${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw const FormatException(
        'Formato de agendamentos inválido.',
      );
    }

    return decoded
        .map(
          (item) => Appointment.fromJson(
            Map<String, dynamic>.from(
              item as Map,
            ),
          ),
        )
        .where(
          (appointment) =>
              appointment.status.trim().toLowerCase() !=
              'cancelado',
        )
        .toList();
  }

  Appointment? getAppointmentById(int id) {
    for (final appointment in _appointments) {
      if (appointment.id == id) {
        return appointment;
      }
    }

    return null;
  }

  Future<Appointment?> fetchAppointmentById(
    int id,
  ) async {
    // Mantém a grafia da rota existente.
    final response = await ApiClient.instance
        .get('/get/appoiment/$id')
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      throw Exception(
        'Sua sessão expirou. Faça login novamente.',
      );
    }

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao buscar agendamento: '
        '${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Formato de agendamento inválido.',
      );
    }

    return Appointment.fromJson(decoded);
  }

  Future<bool> updateAppointment(
    Appointment updatedAppointment,
  ) async {
    try {
      final response = await ApiClient.instance
          .put(
            '/update/appointment',
            body: {
              'appointmentId': updatedAppointment.id,
              'date': updatedAppointment.date
                  .toIso8601String(),
              'time': updatedAppointment.time,
              'client': updatedAppointment.client,
              'service': updatedAppointment.service,
              'status': updatedAppointment.status,
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return false;
      }

      final index = _appointments.indexWhere(
        (appointment) =>
            appointment.id == updatedAppointment.id,
      );

      if (index != -1) {
        _appointments[index] = updatedAppointment;
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelAppointment(int id) async {
    try {
      final response = await ApiClient.instance
          .delete('/delete/appointment/$id')
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200 &&
          response.statusCode != 204) {
        return false;
      }

      _appointments.removeWhere(
        (appointment) => appointment.id == id,
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  String _formatApiDateTime(DateTime date) {
    String twoDigits(int value) =>
        value.toString().padLeft(2, '0');

    return '${date.year}/'
        '${twoDigits(date.month)}/'
        '${twoDigits(date.day)} '
        '${twoDigits(date.hour)}:'
        '${twoDigits(date.minute)}:'
        '${twoDigits(date.second)}';
  }

  Future<List<String>> fetchFreeAppointmentTimes(
    DateTime date,
  ) async {
    String twoDigits(int value) =>
        value.toString().padLeft(2, '0');

    final formattedDate =
        '${date.year}/${twoDigits(date.month)}/${twoDigits(date.day)}';

    final endpoint = Uri(
      path: '/get-free-appointments',
      queryParameters: {
        'data-inicial': formattedDate,
        'data-final': formattedDate,
      },
    ).toString();

    final response = await ApiClient.instance
        .get(endpoint)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      throw Exception(
        'Sessão inválida ou expirada.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao consultar horários disponíveis: '
        '${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw const FormatException(
        'Formato de horários disponíveis inválido.',
      );
    }

    final times = <String>{};

    for (final item in decoded) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException(
          'Registro de horário inválido.',
        );
      }

      final slotDate = DateTime.parse(
        item['date'] as String,
      );

      final time = item['time'] as String;

      if (slotDate.year == date.year &&
          slotDate.month == date.month &&
          slotDate.day == date.day) {
        times.add(time);
      }
    }

    return times.toList()..sort();
  }
}
