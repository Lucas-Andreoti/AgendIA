
import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../services/api_client.dart';
import 'agenda_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  Appointment? _nextAppointment;

  bool _isLoading = true;
  String? _errorMessage;

  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _loadNextAppointment();
  }

  // Consulta o próximo agendamento na API.
  Future<void> _loadNextAppointment() async {
    final requestId = ++_requestId;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiClient.instance
          .get('/next-appointment')
          .timeout(const Duration(seconds: 15));

      // Caso não exista nenhum agendamento futuro.
      if (response.statusCode == 404) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map &&
            decoded['msg'] ==
                'Nenhum agendamento futuro encontrado.') {
          if (!mounted || requestId != _requestId) {
            return;
          }

          setState(() {
            _nextAppointment = null;
            _isLoading = false;
          });

          return;
        }

        throw Exception(
          'Recurso não encontrado no servidor.',
        );
      }

      if (response.statusCode == 401) {
        throw Exception(
          'Sessão inválida ou expirada.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Erro ao consultar próximo agendamento: '
          '${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw const FormatException(
          'Formato do próximo agendamento inválido.',
        );
      }

      // Converte o JSON em um Appointment.
      final appointment = Appointment.fromJson(
        Map<String, dynamic>.from(decoded),
      );

      if (!mounted || requestId != _requestId) {
        return;
      }

      setState(() {
        _nextAppointment = appointment;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) {
        return;
      }

      setState(() {
        _isLoading = false;
        _nextAppointment = null;
        _errorMessage =
            'Não foi possível consultar o próximo '
            'agendamento. Verifique sua conexão.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Agendia',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: _buildCurrentPage(),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,

        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });

          // Atualiza quando voltar para Início.
          if (index == 0) {
            _loadNextAppointment();
          }
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),

          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Agenda',
          ),

          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Config.',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 1:
        return const AgendaScreen();

      case 2:
        return const SettingsScreen();

      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Olá!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Confira seus próximos agendamentos.',
            style: TextStyle(
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 30),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Próximo agendamento',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      IconButton(
                        tooltip: 'Atualizar',
                        onPressed: _isLoading
                            ? null
                            : _loadNextAppointment,
                        icon: const Icon(
                          Icons.refresh,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  _buildNextAppointmentContent(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Define o conteúdo do card.
  Widget _buildNextAppointmentContent() {
    // Estado de carregamento.
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Erro de conexão ou resposta inesperada.
    if (_errorMessage != null) {
      return Column(
        children: [
          const Icon(
            Icons.wifi_off_outlined,
            size: 36,
          ),

          const SizedBox(height: 12),

          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: _loadNextAppointment,
            icon: const Icon(Icons.refresh),
            label: const Text(
              'Tentar novamente',
            ),
          ),
        ],
      );
    }

    // Nenhum agendamento futuro encontrado.
    if (_nextAppointment == null) {
      return const Column(
        children: [
          Center(
            child: Icon(
              Icons.event_available_outlined,
              size: 42,
            ),
          ),

          SizedBox(height: 12),

          Center(
            child: Text(
              'Nenhum agendamento futuro encontrado.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
              ),
            ),
          ),
        ],
      );
    }

    final appointment = _nextAppointment!;

    // Exibe o próximo agendamento real.
    return Column(
      children: [
        _buildInfoRow(
          Icons.person_outline,
          'Cliente',
          appointment.client,
        ),

        const Divider(height: 25),

        _buildInfoRow(
          Icons.content_cut,
          'Serviço',
          appointment.service,
        ),

        const Divider(height: 25),

        _buildInfoRow(
          Icons.calendar_today_outlined,
          'Data',
          _formatDate(appointment.date),
        ),

        const Divider(height: 25),

        _buildInfoRow(
          Icons.access_time,
          'Horário',
          appointment.time,
        ),
      ],
    );
  }

  // Linha de informação do agendamento.
  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 24,
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

  // Formata a data para dd/MM/yyyy.
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
