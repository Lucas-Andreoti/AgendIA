
class Appointment {
  final int id;
  final DateTime date;
  final String time;
  final String client;
  final String service;
  final String status;

  Appointment({
    required this.id,
    required this.date,
    required this.time,
    required this.client,
    required this.service,
    this.status = 'Pendente',
  });

  factory Appointment.fromJson(
    Map<String, dynamic> json,
  ) {
    return Appointment(
      id: json['appointmentId'] as int,
      date: DateTime.parse(json['date'] as String),
      time: json['time'] as String,
      client: json['client'] as String,
      service: json['service'] as String,
      status: json['status'] as String,
    );
  }
}
