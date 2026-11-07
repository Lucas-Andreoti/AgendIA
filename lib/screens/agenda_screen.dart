
import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../services/appointment_service.dart';
import 'appointment_details_screen.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  DateTime _selectedDate = DateTime.now();

  final AppointmentService _appointmentService =
      AppointmentService.instance;

  List<Appointment> _appointments = [];

  bool _isLoading = false;
  String? _errorMessage;

  int _latestRequestId = 0;

  @override
  void initState() {
    super.initState();

    _loadAppointments();
  }

  // Consulta os agendamentos reais no servidor.
  Future<void> _loadAppointments() async {
    final requestId = ++_latestRequestId;
    final selectedDate = _selectedDate;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final startDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    final endDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      23,
      59,
      59,
    );

    try {
      final appointments =
          await _appointmentService.fetchAppointments(
        startDate: startDate,
        endDate: endDate,
      );

      if (!mounted || requestId != _latestRequestId) {
        return;
      }

      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _latestRequestId) {
        return;
      }

      setState(() {
        _isLoading = false;
        _appointments = [];
        _errorMessage =
            'Não foi possível carregar os agendamentos. '
            'Verifique sua conexão e tente novamente.';
      });
    }
  }

  // Avança ou retrocede um dia.
  void _changeDate(int days) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day + days,
      );
    });

    _loadAppointments();
  }

  // Abre o calendário para selecionar uma data.
  Future<void> _selectDate() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = selectedDate;
    });

    _loadAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateSelector(),

            const SizedBox(height: 25),

            Text(
              'Agendamentos',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 15),

            Expanded(
              child: _buildAppointmentsContent(),
            ),
          ],
        ),
      ),
    );
  }

  // Define o que aparece na lista.
  Widget _buildAppointmentsContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_outlined,
              size: 48,
            ),

            const SizedBox(height: 15),

            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            OutlinedButton.icon(
              onPressed: _loadAppointments,
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Tentar novamente',
              ),
            ),
          ],
        ),
      );
    }

    final appointmentsForSelectedDate =
        _appointments.where((appointment) {
      return appointment.date.year == _selectedDate.year &&
          appointment.date.month == _selectedDate.month &&
          appointment.date.day == _selectedDate.day;
    }).toList();

    if (appointmentsForSelectedDate.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum agendamento para este dia.',
          style: TextStyle(
            fontSize: 16,
          ),
        ),
      );
    }

    // Organiza os agendamentos por horário.
    appointmentsForSelectedDate.sort(
      (a, b) => a.time.compareTo(b.time),
    );

    return ListView.builder(
      itemCount: appointmentsForSelectedDate.length,
      itemBuilder: (context, index) {
        final appointment =
            appointmentsForSelectedDate[index];

        return _buildAppointmentCard(appointment);
      },
    );
  }

  // Seletor de datas com setinhas e calendário.
  Widget _buildDateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => _changeDate(-1),
          icon: const Icon(Icons.chevron_left),
        ),

        Expanded(
          child: InkWell(
            onTap: _selectDate,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_selectedDate.day.toString().padLeft(2, '0')}/'
                        '${_selectedDate.month.toString().padLeft(2, '0')}/'
                        '${_selectedDate.year}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(width: 6),

                      const Icon(
                        Icons.calendar_month_outlined,
                        size: 20,
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Toque para selecionar uma data',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        IconButton(
          onPressed: () => _changeDate(1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  // Card de cada agendamento.
  Widget _buildAppointmentCard(
    Appointment appointment,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final cancelled = await Navigator.push<bool>(
            context,
            MaterialPageRoute<bool>(
              builder: (context) =>
                  AppointmentDetailsScreen(
                appointmentId: appointment.id,
              ),
            ),
          );

        if (!mounted) return;

          // Busca novamente os dados reais na API.
          await _loadAppointments();

          if (!mounted) return;

          // Mostra a confirmação somente quando
          // o servidor confirmou o cancelamento.
          if (cancelled == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Agendamento cancelado com sucesso.',
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 70,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Text(
                  appointment.time,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.client,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      appointment.service,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
