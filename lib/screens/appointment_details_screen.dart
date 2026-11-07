import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../services/appointment_service.dart';
import 'edit_appointment_screen.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final int appointmentId;

  const AppointmentDetailsScreen({
    super.key,
    required this.appointmentId,
  });

  @override
  State<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState
    extends State<AppointmentDetailsScreen> {
  final AppointmentService _appointmentService =
      AppointmentService.instance;

  Appointment? _appointment;

  bool _isLoading = true;
  bool _isCancelling = false;
  bool _isUpdating = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAppointment();
  }

  // Busca os detalhes reais na API.
  Future<void> _loadAppointment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appointment =
          await _appointmentService.fetchAppointmentById(
        widget.appointmentId,
      );

      if (!mounted) return;

      setState(() {
        _appointment = appointment;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Não foi possível carregar os detalhes '
            'do agendamento.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detalhes do agendamento'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detalhes do agendamento'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _loadAppointment,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_appointment == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Agendamento'),
        ),
        body: const Center(
          child: Text('Agendamento não encontrado.'),
        ),
      );
    }

    final appointment = _appointment!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalhes do agendamento',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.person_outline,
                    label: 'Cliente',
                    value: appointment.client,
                  ),

                  const Divider(height: 30),

                  _buildDetailRow(
                    icon: Icons.content_cut,
                    label: 'Serviço',
                    value: appointment.service,
                  ),

                  const Divider(height: 30),

                  _buildDetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Data',
                    value: _formatDate(appointment.date),
                  ),

                  const Divider(height: 30),

                  _buildDetailRow(
                    icon: Icons.access_time,
                    label: 'Horário',
                    value: appointment.time,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Botão de edição.
          FilledButton.icon(
            onPressed: (_isCancelling || _isUpdating)
                ? null
                : _editAppointment,
            icon: _isUpdating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.edit_outlined),
            label: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 14,
              ),
              child: Text(
                _isUpdating
                    ? 'Salvando...'
                    : 'Editar agendamento',
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Botão de cancelamento.
          OutlinedButton.icon(
            onPressed: (_isCancelling || _isUpdating)
                ? null
                : _cancelAppointment,

            icon: _isCancelling
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.cancel_outlined,
                  ),

            label: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 14,
              ),
              child: Text(
                _isCancelling
                    ? 'Cancelando...'
                    : 'Cancelar agendamento',
              ),
            ),

            style: OutlinedButton.styleFrom(
              foregroundColor:
                  Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  // Edita um agendamento e lembra a profissional de avisar a cliente.
  Future<void> _editAppointment() async {
    if (_isCancelling || _isUpdating) return;

    final appointment = _appointment;
    if (appointment == null) return;

    final updatedAppointment = await Navigator.push<Appointment>(
      context,
      MaterialPageRoute(
        builder: (context) => EditAppointmentScreen(
          appointment: appointment,
        ),
      ),
    );

    if (!mounted || updatedAppointment == null) return;

    // Não pede para avisar a cliente quando nada mudou.
    if (updatedAppointment.service == appointment.service &&
        updatedAppointment.time == appointment.time &&
        updatedAppointment.date == appointment.date) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma alteração realizada.'),
        ),
      );
      return;
    }

    setState(() => _isUpdating = true);

    bool success;
    try {
      success = await _appointmentService.updateAppointment(
        updatedAppointment,
      );
    } catch (_) {
      success = false;
    }

    if (!mounted) return;

    setState(() {
      _isUpdating = false;
      if (success) {
        _appointment = updatedAppointment;
      }
    });

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível atualizar o agendamento. '
            'Verifique os dados antes de tentar novamente.',
          ),
        ),
      );
      return;
    }

    // Exibe o lembrete APENAS após a confirmação da API.
    await _showManualNotificationReminder(
      clientName: updatedAppointment.client,
      isCancellation: false,
    );
  }

  // Cancela um agendamento na API real.
  Future<void> _cancelAppointment() async {
    if (_isCancelling || _isUpdating || _appointment == null) {
      return;
    }

    final clientName = _appointment!.client;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Cancelar agendamento?',
          ),
          content: const Text(
            'Deseja realmente cancelar este '
            'agendamento?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Não'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(dialogContext)
                        .colorScheme
                        .error,
              ),
              child: const Text(
                'Cancelar agendamento',
              ),
            ),
          ],
        );
      },
    );

    // Se o usuário desistiu, não faz nada.
    if (!mounted || confirmed != true) {
      return;
    }

    // Impede novos cliques durante a operação.
    setState(() {
      _isCancelling = true;
    });

    bool success;

    try {
      success =
          await _appointmentService.cancelAppointment(
        widget.appointmentId,
      );
    } catch (e) {
      success = false;
    }

    if (!mounted) return;

    if (!success) {
      setState(() {
        _isCancelling = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível confirmar o cancelamento. '
            'Verifique o agendamento antes de tentar novamente.',
          ),
        ),
      );

      return;
    }

    // Primeiro avisa a profissional; não envia mensagens à cliente.
    await _showManualNotificationReminder(
      clientName: clientName,
      isCancellation: true,
    );

    if (!mounted) return;

    // Mantém o retorno true para que a Agenda atualize a lista.
    Navigator.pop(context, true);
  }

  // Mostra apenas um lembrete visual. Não envia mensagens automáticas.
  Future<void> _showManualNotificationReminder({
    required String clientName,
    required bool isCancellation,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle_outline),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isCancellation
                      ? 'Agendamento cancelado!'
                      : 'Agendamento alterado!',
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCancellation
                    ? 'O agendamento de $clientName foi cancelado '
                        'com sucesso.'
                    : 'O agendamento de $clientName foi alterado '
                        'com sucesso.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Lembre-se de avisar a cliente manualmente. '
                'Nenhuma mensagem foi enviada automaticamente.',
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Entendi'),
            ),
          ],
        );
      },
    );
  }

  // Componente utilizado para exibir os detalhes.
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 25,
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Formata a data para exibição.
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
