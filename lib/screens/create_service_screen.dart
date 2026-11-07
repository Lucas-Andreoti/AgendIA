
import 'package:flutter/material.dart';

import '../models/salon_service.dart';
import '../services/service_catalog_service.dart';

class CreateServiceScreen extends StatefulWidget {
  // Quando service for null, cria um novo serviço.
  // Quando receber um serviço, permite editá-lo.
  final SalonService? service;

  const CreateServiceScreen({
    super.key,
    this.service,
  });

  @override
  State<CreateServiceScreen> createState() =>
      _CreateServiceScreenState();
}

class _CreateServiceScreenState
    extends State<CreateServiceScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();

  bool _isSaving = false;

  bool get _isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();

    // Se for edição, preenche os campos.
    final service = widget.service;

    if (service != null) {
      _nameController.text = service.name;
      _descriptionController.text = service.description;

      _priceController.text = service.price
          .toStringAsFixed(2)
          .replaceAll('.', ',');

      _durationController.text =
          service.durationMinutes.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  double? _parsePrice(String value) {
    return double.tryParse(
      value.trim().replaceAll(',', '.'),
    );
  }

  Future<void> _saveService() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final price = _parsePrice(
      _priceController.text,
    )!;

    final duration = int.parse(
      _durationController.text.trim(),
    );

    setState(() {
      _isSaving = true;
    });

    try {
      if (_isEditing) {
        // Atualiza um serviço já existente.
        final updatedService = SalonService(
          id: widget.service!.id,
          name: _nameController.text.trim(),
          description:
              _descriptionController.text.trim(),
          price: price,
          durationMinutes: duration,
        );

        await ServiceCatalogService.instance
            .updateService(updatedService);
      } else {
        // Cadastra um novo serviço.
        await ServiceCatalogService.instance
            .createService(
          name: _nameController.text.trim(),
          description:
              _descriptionController.text.trim(),
          price: price,
          durationMinutes: duration,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Não foi possível confirmar a edição. '
                  'Consulte a lista antes de tentar novamente.'
                : 'Não foi possível confirmar o cadastro. '
                  'Consulte a lista antes de tentar novamente.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'Editar serviço'
              : 'Novo serviço',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Form(
        key: _formKey,

        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              _isEditing
                  ? 'Editar serviço'
                  : 'Cadastrar serviço',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 8),

            Text(
              _isEditing
                  ? 'Altere as informações do serviço.'
                  : 'Preencha as informações do serviço '
                    'oferecido pelo salão.',
            ),

            const SizedBox(height: 25),

            // Nome.
            TextFormField(
              controller: _nameController,
              enabled: !_isSaving,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Nome do serviço',
                hintText: 'Ex.: Hidratação capilar',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Informe o nome do serviço.';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            // Descrição.
            TextFormField(
              controller: _descriptionController,
              enabled: !_isSaving,
              maxLines: 3,
              maxLength: 255,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                hintText: 'Descreva o procedimento',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Informe uma descrição.';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            // Preço.
            TextFormField(
              controller: _priceController,
              enabled: !_isSaving,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Preço',
                prefixText: 'R\$ ',
                hintText: '80,00',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Informe o preço.';
                }

                final price = _parsePrice(value);

                if (price == null ||
                    !price.isFinite ||
                    price < 0 ||
                    price > 99999999.99) {
                  return 'Informe um preço válido.';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            // Duração.
            TextFormField(
              controller: _durationController,
              enabled: !_isSaving,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duração (minutos)',
                hintText: '45',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final duration = int.tryParse(
                  value?.trim() ?? '',
                );

                if (duration == null || duration <= 0) {
                  return 'Informe uma duração válida.';
                }

                return null;
              },
            ),

            const SizedBox(height: 30),

            // Salvar cadastro ou edição.
            FilledButton.icon(
              onPressed: _isSaving
                  ? null
                  : _saveService,

              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_outlined),

              label: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                child: Text(
                  _isSaving
                      ? 'Salvando...'
                      : _isEditing
                          ? 'Salvar alterações'
                          : 'Salvar serviço',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
