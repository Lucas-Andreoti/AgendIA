
import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../models/business_hours.dart';
import '../models/salon_service.dart';
import '../services/appointment_service.dart';
import '../services/business_hours_service.dart';
import '../services/service_catalog_service.dart';

class EditAppointmentScreen extends StatefulWidget {
  final Appointment appointment;

  const EditAppointmentScreen({
    super.key,
    required this.appointment,
  });

  @override
  State<EditAppointmentScreen> createState() =>
      _EditAppointmentScreenState();
}

class _EditAppointmentScreenState
    extends State<EditAppointmentScreen> {
  List<SalonService> _services = [];
  List<BusinessHours> _businessHours = [];
  List<Appointment> _dayAppointments = [];
  List<String> _freeTimes = [];

  int? _selectedServiceId;
  late String _selectedTime;

  bool _isLoading = true;
  bool _isSaving = false;

  String? _loadError;

  // A geração de horários usa intervalos de 30 minutos.
  static const int _slotMinutes = 30;

  @override
  void initState() {
    super.initState();

    _selectedTime = widget.appointment.time;
    _loadData();
  }

  SalonService? get _selectedService {
    for (final service in _services) {
      if (service.id == _selectedServiceId) {
        return service;
      }
    }

    return null;
  }

  BusinessHours? get _dayHours {
    for (final hours in _businessHours) {
      // Segunda = 1 ... Domingo = 7.
      if (hours.weekday ==
          widget.appointment.date.weekday) {
        return hours;
      }
    }

    return null;
  }

  // Carrega os serviços, o expediente,
  // os horários livres e os agendamentos.
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait<Object>([
        ServiceCatalogService.instance.fetchServices(),
        BusinessHoursService.instance.fetchBusinessHours(),
        AppointmentService.instance
            .fetchFreeAppointmentTimes(
          widget.appointment.date,
        ),
        AppointmentService.instance
            .fetchAppointmentsForConflictCheck(
          widget.appointment.date,
        ),
      ]);

      if (!mounted) return;

      final services =
          (results[0] as List<SalonService>).toList()
            ..sort(
              (a, b) => a.name
                  .toLowerCase()
                  .compareTo(b.name.toLowerCase()),
            );

      int? selectedId;

      for (final service in services) {
        if (service.id == _selectedServiceId) {
          selectedId = service.id;
          break;
        }
      }

      selectedId ??= _findOriginalServiceId(
        services,
      );

      setState(() {
        _services = services;
        _businessHours = results[1] as List<BusinessHours>;
        _freeTimes = results[2] as List<String>;
        _dayAppointments =
            results[3] as List<Appointment>;

        _selectedServiceId = selectedId;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadError =
            'Não foi possível consultar os serviços, '
            'o expediente ou a disponibilidade. '
            'Tente novamente.';
      });
    }
  }

  int? _findOriginalServiceId(
    List<SalonService> services,
  ) {
    for (final service in services) {
      if (_sameServiceName(
        service.name,
        widget.appointment.service,
      )) {
        return service.id;
      }
    }

    return null;
  }

  bool _sameServiceName(String a, String b) {
    return a.trim().toLowerCase() ==
        b.trim().toLowerCase();
  }

  // Converte HH:mm e HH:mm:ss em minutos.
  int? _toMinutes(String text) {
    final parts = text.trim().split(':');

    if (parts.length < 2) {
      return null;
    }

    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);

    if (hours == null ||
        minutes == null ||
        hours < 0 ||
        hours > 23 ||
        minutes < 0 ||
        minutes > 59) {
      return null;
    }

    return hours * 60 + minutes;
  }

  // Consulta a duração de um serviço pelo nome.
  int? _durationForServiceName(String name) {
    final matches = _services
        .where(
          (service) =>
              _sameServiceName(service.name, name),
        )
        .toList();

    // Nomes ausentes ou duplicados não permitem
    // determinar a duração com segurança.
    if (matches.length != 1 ||
        matches.single.durationMinutes <= 0) {
      return null;
    }

    return matches.single.durationMinutes;
  }

  // Verifica sobreposição de intervalos.
  // O instante final não pertence ao intervalo.
  bool _overlaps(
    int startA,
    int endA,
    int startB,
    int endB,
  ) {
    return startA < endB && startB < endA;
  }

  // Retorna null quando o horário é válido.
  // Caso contrário, retorna o motivo.
  String? _invalidReason(String time) {
    final chosenService = _selectedService;

    if (chosenService == null) {
      return 'Selecione um serviço cadastrado.';
    }

    final hours = _dayHours;

    if (hours == null) {
      return 'Expediente do dia não encontrado.';
    }

    if (!hours.enabled) {
      return 'O salão está fechado nesse dia.';
    }

    final opening = _toMinutes(hours.openingTime);
    final closing = _toMinutes(hours.closingTime);
    final start = _toMinutes(time);
    final duration = chosenService.durationMinutes;

    if (opening == null ||
        closing == null ||
        start == null ||
        duration <= 0 ||
        closing <= opening) {
      return 'Dados de horário ou duração inválidos.';
    }

    final end = start + duration;

    // Não permite iniciar antes da abertura
    // ou terminar depois do fechamento.
    if (start < opening || end > closing) {
      return 'O serviço terminaria fora do expediente '
          '(${hours.openingTime}–${hours.closingTime}).';
    }

    // Verifica conflitos com outros agendamentos.
    for (final appointment in _dayAppointments) {
      // Ignora o próprio agendamento.
      if (appointment.id == widget.appointment.id) {
        continue;
      }

      if (appointment.date.year !=
              widget.appointment.date.year ||
          appointment.date.month !=
              widget.appointment.date.month ||
          appointment.date.day !=
              widget.appointment.date.day) {
        continue;
      }

      final existingStart = _toMinutes(
        appointment.time,
      );

      final existingDuration =
          _durationForServiceName(
        appointment.service,
      );

      // Se não sabemos a duração, impedimos
      // uma alteração potencialmente insegura.
      if (existingStart == null ||
          existingDuration == null) {
        return 'Há um atendimento cujo serviço '
            'não tem duração identificável no catálogo. '
            'Verifique a agenda.';
      }

      final existingEnd =
          existingStart + existingDuration;

      if (_overlaps(
        start,
        end,
        existingStart,
        existingEnd,
      )) {
        return 'Conflito com outro agendamento.';
      }
    }

    // O endpoint de horários livres pode omitir
    // o horário ocupado pelo próprio atendimento.
    //
    // Consideramos virtualmente livre somente
    // o intervalo original desse agendamento.
    final originalStart = _toMinutes(
      widget.appointment.time,
    );

    final originalDuration =
        _durationForServiceName(
      widget.appointment.service,
    );

    final originalEnd =
        (originalStart != null &&
                originalDuration != null)
            ? originalStart + originalDuration
            : null;

    final freeMinutes = _freeTimes
        .map(_toMinutes)
        .whereType<int>()
        .toSet();

    // Verifica todos os intervalos necessários
    // para completar o serviço.
    for (int instant = start;
        instant < end;
        instant += _slotMinutes) {
      if (freeMinutes.contains(instant)) {
        continue;
      }

      final isOwnOriginalSlot =
          originalStart != null &&
              originalEnd != null &&
              instant >= originalStart &&
              instant < originalEnd;

      if (!isOwnOriginalSlot) {
        return 'Não há intervalos livres suficientes '
            'para esse serviço.';
      }
    }

    return null;
  }

  // Retorna apenas horários compatíveis.
  List<String> _validTimes() {
    if (_isLoading ||
        _loadError != null ||
        _selectedService == null) {
      return [];
    }

    final candidateTimes = <String>{
      widget.appointment.time,
      ..._freeTimes,
    }.toList()
      ..sort();

    return candidateTimes
        .where(
          (time) => _invalidReason(time) == null,
        )
        .toList();
  }

  // Verifica se o usuário não alterou nada.
  bool get _unchanged {
    final service = _selectedService;

    return service != null &&
        _sameServiceName(
          service.name,
          widget.appointment.service,
        ) &&
        _selectedTime == widget.appointment.time;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // Verifica novamente a disponibilidade
  // antes de retornar o agendamento atualizado.
  Future<void> _save() async {
    if (_isSaving ||
        _isLoading ||
        _loadError != null) {
      return;
    }

    final service = _selectedService;

    if (service == null) {
      _showMessage(
        'Selecione um serviço cadastrado.',
      );
      return;
    }

    // Não faz PUT se nada foi alterado.
    if (_unchanged) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final results = await Future.wait<Object>([
        AppointmentService.instance
            .fetchFreeAppointmentTimes(
          widget.appointment.date,
        ),
        AppointmentService.instance
            .fetchAppointmentsForConflictCheck(
          widget.appointment.date,
        ),
        BusinessHoursService.instance
            .fetchBusinessHours(),
      ]);

      if (!mounted) return;

      setState(() {
        _freeTimes = results[0] as List<String>;
        _dayAppointments =
            results[1] as List<Appointment>;
        _businessHours =
            results[2] as List<BusinessHours>;
      });

      final reason = _invalidReason(
        _selectedTime,
      );

      if (reason != null) {
        _showMessage(reason);
        return;
      }

      final updatedAppointment = Appointment(
        id: widget.appointment.id,
        date: widget.appointment.date,
        time: _selectedTime,
        client: widget.appointment.client,
        service: service.name,
        status: widget.appointment.status,
      );

      if (!mounted) return;

      // O PUT e o lembrete manual continuam
      // na AppointmentDetailsScreen.
      Navigator.pop(
        context,
        updatedAppointment,
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Não foi possível confirmar a disponibilidade. '
        'Tente novamente.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedService = _selectedService;

    final validTimes = _validTimes();

    final selectedReason =
        !_isLoading &&
                _loadError == null &&
                selectedService != null
            ? _invalidReason(_selectedTime)
            : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar agendamento',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Serviço',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 12),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_loadError != null)
            Column(
              children: [
                Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'Tentar novamente',
                  ),
                ),
              ],
            )
          else ...[
            // Seleção dos serviços cadastrados.
            DropdownButtonFormField<int>(
              value: _selectedServiceId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Selecione o serviço',
                prefixIcon: Icon(
                  Icons.content_cut,
                ),
                border: OutlineInputBorder(),
              ),
              hint: const Text(
                'Escolha um serviço',
              ),

              items: _services.map((service) {
                return DropdownMenuItem<int>(
                  value: service.id,
                  child: Text(
                    service.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),

              onChanged: _isSaving
                  ? null
                  : (value) {
                      setState(() {
                        _selectedServiceId = value;
                      });
                    },
            ),

            if (selectedService == null) ...[
              const SizedBox(height: 12),

              const Text(
                'Selecione um serviço válido. '
                'O serviço atual pode ter sido '
                'removido do catálogo.',
              ),
            ] else ...[
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedService.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        selectedService.description,
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 18,
                          ),

                          const SizedBox(width: 6),

                          Text(
                            '${selectedService.durationMinutes} min',
                          ),

                          const Spacer(),

                          Text(
                            _formatPrice(
                              selectedService.price,
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Data do agendamento.
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Data do agendamento',
                prefixIcon: Icon(
                  Icons.calendar_today_outlined,
                ),
                border: OutlineInputBorder(),
              ),
              child: Text(
                _formatDate(
                  widget.appointment.date,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Expediente real configurado no banco.
            if (_dayHours != null)
              Text(
                _dayHours!.enabled
                    ? 'Expediente: '
                        '${_dayHours!.openingTime} '
                        'às ${_dayHours!.closingTime}'
                    : 'O salão não atende neste dia.',
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                ),
              )
            else
              const Text(
                'Expediente não encontrado para esta data.',
              ),

            const SizedBox(height: 24),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Horários compatíveis',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),

                IconButton(
                  tooltip: 'Atualizar disponibilidade',
                  onPressed:
                      _isSaving ? null : _loadData,
                  icon: const Icon(
                    Icons.refresh,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              'Somente horários que comportam '
              'toda a duração do serviço e não '
              'conflitam com outros atendimentos.',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 16),

            // Horários aprovados pelas verificações.
            if (validTimes.isEmpty)
              const Text(
                'Não há horários compatíveis '
                'para este serviço nesta data.',
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: validTimes.map((time) {
                  final isOriginal =
                      time == widget.appointment.time;

                  return ChoiceChip(
                    label: Text(
                      isOriginal
                          ? '$time (atual)'
                          : time,
                    ),

                    selected: _selectedTime == time,

                    onSelected: _isSaving
                        ? null
                        : (selected) {
                            if (selected) {
                              setState(() {
                                _selectedTime = time;
                              });
                            }
                          },
                  );
                }).toList(),
              ),

            const SizedBox(height: 16),

            // Horário selecionado.
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.access_time,
                ),
                title: const Text(
                  'Horário selecionado',
                ),
                trailing: Text(
                  _selectedTime,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),

            // Aviso quando o horário é incompatível.
            if (selectedReason != null &&
                !_unchanged) ...[
              const SizedBox(height: 10),

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Theme.of(context)
                        .colorScheme
                        .error,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      selectedReason,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            Text(
              'A verificação do aplicativo é '
              'preventiva. O servidor também '
              'deve validar os conflitos ao salvar.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 24),

            // Botão para salvar as alterações.
            FilledButton(
              onPressed:
                  _isSaving ? null : _save,

              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),

                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Salvar alterações',
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return 'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
