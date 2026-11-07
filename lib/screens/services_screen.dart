
import 'package:flutter/material.dart';

import '../models/salon_service.dart';
import '../services/service_catalog_service.dart';
import 'create_service_screen.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() =>
      _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final ServiceCatalogService _service =
      ServiceCatalogService.instance;

  List<SalonService> _services = [];

  bool _isLoading = true;
  String? _errorMessage;

  // Identifica o serviço que está sendo excluído.
  int? _deletingServiceId;

  // Impede outras operações durante carregamento
  // ou exclusão.
  bool get _isBusy =>
      _isLoading || _deletingServiceId != null;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  // Consulta os serviços reais na API.
  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final services = await _service.fetchServices();

      if (!mounted) return;

      setState(() {
        _services = services;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Não foi possível carregar os serviços. '
            'Verifique sua conexão e tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Serviços',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Adicionar serviço.
          IconButton(
            tooltip: 'Adicionar serviço',
            onPressed: _isBusy
                ? null
                : _createService,
            icon: const Icon(Icons.add),
          ),

          // Atualizar lista.
          IconButton(
            tooltip: 'Atualizar serviços',
            onPressed: _isBusy
                ? null
                : _loadServices,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  // Define o conteúdo exibido na tela.
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
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
                _errorMessage!,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: _loadServices,
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

    if (_services.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.content_cut,
              size: 48,
            ),

            const SizedBox(height: 16),

            const Text(
              'Nenhum serviço cadastrado.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 20),

            OutlinedButton.icon(
              onPressed: _isBusy
                  ? null
                  : _loadServices,
              icon: const Icon(Icons.refresh),
              label: const Text('Atualizar'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _deletingServiceId != null
          ? () async {}
          : _loadServices,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _services.length,
        itemBuilder: (context, index) {
          final service = _services[index];

          return _buildServiceCard(service);
        },
      ),
    );
  }

  // Card com os dados de um serviço.
  Widget _buildServiceCard(SalonService service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.content_cut,
                  size: 24,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    service.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Editar serviço.
                IconButton(
                  tooltip: 'Editar serviço',
                  onPressed: _isBusy
                      ? null
                      : () => _editService(service),
                  icon: const Icon(
                    Icons.edit_outlined,
                  ),
                ),

                // Excluir serviço.
                IconButton(
                  tooltip: 'Excluir serviço',
                  onPressed: _isBusy
                      ? null
                      : () => _deleteService(service),

                  icon: _deletingServiceId == service.id
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          Icons.delete_outline,
                          color: Theme.of(context)
                              .colorScheme
                              .error,
                        ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              service.description,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 16),

            const Divider(),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 20,
                    ),

                    const SizedBox(width: 6),

                    Text(
                      '${service.durationMinutes} min',
                      style: const TextStyle(
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),

                Text(
                  _formatPrice(service.price),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Formata o preço em reais.
  String _formatPrice(double price) {
    final formatted = price
        .toStringAsFixed(2)
        .replaceAll('.', ',');

    return 'R\$ $formatted';
  }

  // Abre a tela de cadastro.
  Future<void> _createService() async {
    if (_isBusy) return;

    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const CreateServiceScreen(),
      ),
    );

    if (!mounted) return;

    if (created == true) {
      await _loadServices();

      if (!mounted) return;

      if (_errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Serviço cadastrado com sucesso.',
            ),
          ),
        );
      }
    }
  }

  // Abre a tela de edição.
  Future<void> _editService(
    SalonService service,
  ) async {
    if (_isBusy) return;

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateServiceScreen(
          service: service,
        ),
      ),
    );

    if (!mounted) return;

    if (updated == true) {
      await _loadServices();

      if (!mounted) return;

      if (_errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Serviço atualizado com sucesso.',
            ),
          ),
        );
      }
    }
  }

  // Exclui um serviço pela API.
  Future<void> _deleteService(
    SalonService service,
  ) async {
    if (_isBusy) return;

    // Solicita confirmação.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Excluir serviço?',
          ),

          content: Text(
            'Deseja realmente excluir o serviço '
            '"${service.name}"?\n\n'
            'Essa ação poderá ser permanente.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancelar',
              ),
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
                'Excluir serviço',
              ),
            ),
          ],
        );
      },
    );

    // Não exclui se o usuário desistiu.
    if (!mounted || confirmed != true || _isBusy) {
      return;
    }

    // Bloqueia outras ações durante a exclusão.
    setState(() {
      _deletingServiceId = service.id;
    });

    try {
      // Envia DELETE /delete/service/{id}.
      await _service.deleteService(service.id);

      if (!mounted) return;

      // Consulta os dados reais após a exclusão.
      await _loadServices();

      if (!mounted) return;

      // A API aceitou a exclusão, mas a consulta falhou.
      if (_errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'A exclusão foi aceita pelo servidor, '
              'mas não foi possível atualizar a lista.',
            ),
          ),
        );

        return;
      }

      // Verifica se o serviço ainda existe na API.
      final stillExists = _services.any(
        (item) => item.id == service.id,
      );

      if (stillExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'O servidor respondeu com sucesso, '
              'mas o serviço ainda aparece na lista. '
              'Verifique o resultado antes de tentar novamente.',
            ),
          ),
        );

        return;
      }

      // Somente confirma após verificar a lista.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Serviço excluído com sucesso.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível confirmar a exclusão. '
            'Atualize a lista antes de tentar novamente.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingServiceId = null;
        });
      }
    }
  }
}
