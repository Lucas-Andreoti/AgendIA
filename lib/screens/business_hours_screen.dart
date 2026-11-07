
import 'package:flutter/material.dart';

import '../models/business_hours.dart';
import '../services/business_hours_service.dart';

class BusinessHoursScreen extends StatefulWidget {
  const BusinessHoursScreen({super.key});

  @override
  State<BusinessHoursScreen> createState() =>
      _BusinessHoursScreenState();
}

class _BusinessHoursScreenState
    extends State<BusinessHoursScreen> {
  final BusinessHoursService _service =
      BusinessHoursService.instance;

  List<BusinessHours> _businessHours = [];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  final List<String> _weekdays = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    _loadBusinessHours();
  }

  // Busca os horários reais na API.
  Future<void> _loadBusinessHours() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final hours = await _service.fetchBusinessHours();

      if (!mounted) return;

      final sortedHours = [...hours]
        ..sort(
          (a, b) => a.weekday.compareTo(b.weekday),
        );

      // Confere se a API retornou os sete dias.
      final weekdays = sortedHours
          .map((item) => item.weekday)
          .toSet();

      if (sortedHours.length != 7 ||
          weekdays.length != 7 ||
          !weekdays.containsAll(
            [1, 2, 3, 4, 5, 6, 7],
          )) {
        throw const FormatException(
          'Configuração semanal incompleta.',
        );
      }

      setState(() {
        _businessHours = sortedHours;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadError =
            'Não foi possível carregar os horários '
            'de funcionamento.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dias e horários',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _loadError != null
              ? _buildErrorContent()
              : _buildBusinessHoursContent(),
    );
  }

  // Exibe uma mensagem quando a API não responde.
  Widget _buildErrorContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_outlined,
              size: 48,
            ),

            const SizedBox(height: 16),

            Text(
              _loadError!,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            OutlinedButton.icon(
              onPressed: _loadBusinessHours,
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Tentar novamente',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Interface principal dos horários.
  Widget _buildBusinessHoursContent() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _businessHours.length,
            itemBuilder: (context, index) {
              final hours = _businessHours[index];

              return _buildDayCard(
                index,
                hours,
              );
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            20,
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving
                  ? null
                  : _saveBusinessHours,

              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Salvar',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Card de configuração de cada dia.
  Widget _buildDayCard(
    int index,
    BusinessHours hours,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _weekdays[hours.weekday - 1],
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Switch(
                  value: hours.enabled,
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          setState(() {
                            _businessHours[index] =
                                BusinessHours(
                              id: hours.id,
                              weekday: hours.weekday,
                              enabled: value,
                              openingTime:
                                  hours.openingTime,
                              closingTime:
                                  hours.closingTime,
                            );
                          });
                        },
                ),
              ],
            ),

            if (hours.enabled) ...[
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildTimeButton(
                      label: 'Abertura',
                      time: hours.openingTime,
                      onPressed: () => _selectTime(
                        index,
                        true,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _buildTimeButton(
                      label: 'Fechamento',
                      time: hours.closingTime,
                      onPressed: () => _selectTime(
                        index,
                        false,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Botão que abre o seletor de horário.
  Widget _buildTimeButton({
    required String label,
    required String time,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: _isSaving ? null : onPressed,
      child: Column(
        children: [
          Text(label),

          const SizedBox(height: 4),

          Text(
            time,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Salva os sete dias no servidor.
  Future<void> _saveBusinessHours() async {
    if (_isSaving || _isLoading) return;

    // Valida os horários antes de enviar.
    for (final hours in _businessHours) {
      if (!hours.enabled) {
        continue;
      }

      final opening =
          _timeToMinutes(hours.openingTime);

      final closing =
          _timeToMinutes(hours.closingTime);

      if (opening >= closing) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'O horário de abertura deve ser '
              'anterior ao horário de fechamento.',
            ),
          ),
        );

        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Envia a lista completa para a API.
      await _service.updateBusinessHours(
        List<BusinessHours>.from(_businessHours),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Dias e horários salvos com sucesso.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível confirmar o salvamento. '
            'Verifique sua conexão e consulte novamente '
            'os horários antes de tentar.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Converte HH:mm em minutos.
  int _timeToMinutes(String time) {
    final parts = time.split(':');

    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    return (hour * 60) + minute;
  }

  // Permite alterar abertura ou fechamento.
  Future<void> _selectTime(
    int index,
    bool isOpeningTime,
  ) async {
    if (_isSaving) return;

    final currentTime = _businessHours[index];

    final initialParts = (isOpeningTime
            ? currentTime.openingTime
            : currentTime.closingTime)
        .split(':');

    final initialTime = TimeOfDay(
      hour: int.parse(initialParts[0]),
      minute: int.parse(initialParts[1]),
    );

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (!mounted ||
        selectedTime == null ||
        _isSaving) {
      return;
    }

    final formattedTime =
        '${selectedTime.hour.toString().padLeft(2, '0')}:'
        '${selectedTime.minute.toString().padLeft(2, '0')}';

    setState(() {
      _businessHours[index] = BusinessHours(
        id: currentTime.id,
        weekday: currentTime.weekday,
        enabled: currentTime.enabled,
        openingTime: isOpeningTime
            ? formattedTime
            : currentTime.openingTime,
        closingTime: isOpeningTime
            ? currentTime.closingTime
            : formattedTime,
      );
    });
  }
}
