
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'business_hours_screen.dart';
import 'login_screen.dart';
import 'services_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoggingOut = false;
  bool _isDeletingAccount = false;

  bool get _isBusy =>
      _isLoggingOut || _isDeletingAccount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Agenda',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.calendar_month,
              ),
              title: const Text(
                'Dias e horários de trabalho',
              ),
              subtitle: const Text(
                'Defina quando você está disponível '
                'para trabalhar',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: _isBusy
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const BusinessHoursScreen(),
                        ),
                      );
                    },
            ),
          ),

          const SizedBox(height: 30),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.content_cut,
              ),
              title: const Text(
                'Serviços',
              ),
              subtitle: const Text(
                'Consulte os serviços oferecidos pelo salão',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: _isBusy
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ServicesScreen(),
                        ),
                      );
                    },
            ),
          ),


          Text(
            'Conta',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 10),

          // Logout.
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.logout,
              ),
              title: Text(
                _isLoggingOut
                    ? 'Saindo da conta...'
                    : 'Sair da conta',
              ),
              subtitle: const Text(
                'Encerrar a sessão atual',
              ),
              trailing: _isLoggingOut
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.chevron_right,
                    ),
              onTap: _isBusy ? null : _logout,
            ),
          ),

          const SizedBox(height: 10),

          // Exclusão real da conta.
          Card(
            child: ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context)
                    .colorScheme
                    .error,
              ),
              title: Text(
                _isDeletingAccount
                    ? 'Excluindo conta...'
                    : 'Excluir conta',
              ),
              subtitle: const Text(
                'Excluir permanentemente sua '
                'conta e seus dados',
              ),
              trailing: _isDeletingAccount
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.chevron_right,
                    ),
              onTap: _isBusy
                  ? null
                  : _showDeleteAccountDialog,
            ),
          ),
        ],
      ),
    );
  }

  // Logout real no servidor.
  Future<void> _logout() async {
    if (_isBusy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Sair da conta?',
          ),
          content: const Text(
            'Deseja realmente encerrar '
            'a sessão atual?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await AuthService.instance.logout();

      if (!mounted) return;

      setState(() {
        _isLoggingOut = false;
      });

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível confirmar o logout '
            'no servidor. Tente novamente.',
          ),
        ),
      );
    }
  }

  // Confirma e exclui a conta na API.
  Future<void> _showDeleteAccountDialog() async {
    if (_isBusy) return;

    final confirmController =
        TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            dialogContentContext,
            setDialogState,
          ) {
            final canDelete =
                confirmController.text == 'confirmar';

            return AlertDialog(
              title: const Text(
                'Excluir conta?',
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Esta ação solicitará a exclusão '
                      'permanente da sua conta no servidor.',
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Esta ação não poderá ser desfeita.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(
                          dialogContentContext,
                        ).colorScheme.error,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Para confirmar, digite:',
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'confirmar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: confirmController,
                      decoration: const InputDecoration(
                        labelText: 'Confirmação',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setDialogState(() {});
                      },
                    ),
                  ],
                ),
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
                  onPressed: canDelete
                      ? () {
                          Navigator.pop(
                            dialogContext,
                            true,
                          );
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(
                      dialogContentContext,
                    ).colorScheme.error,
                  ),
                  child: const Text(
                    'Excluir conta',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    confirmController.dispose();

    if (!mounted ||
        confirmed != true ||
        _isBusy) {
      return;
    }

    // Inicia a exclusão no servidor.
    setState(() {
      _isDeletingAccount = true;
    });

    try {
      await AuthService.instance.deleteAccount();

      if (!mounted) return;

      setState(() {
        _isDeletingAccount = false;
      });

      // A sessão local foi limpa no AuthService.
      // Retorna para o login sem manter
      // as telas anteriores na navegação.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isDeletingAccount = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível confirmar a exclusão. '
            'Verifique o estado da conta antes '
            'de tentar novamente.',
          ),
        ),
      );
    }
  }
}
