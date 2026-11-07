
import 'dart:convert';

import '../models/login_response.dart';
import 'api_client.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  String? _token;

  String? get token => _token;

  bool get isAuthenticated => _token != null;

  // Login real na API.
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.instance
        .post(
          '/login',
          authenticated: false,
          body: {
            'email': email,
            'password': password,
          },
        )
        .timeout(
          const Duration(seconds: 15),
        );

    if (response.statusCode == 400 ||
        response.statusCode == 401) {
      return LoginResponse(
        valid: false,
        token: null,
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Erro na API: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw const FormatException(
        'Resposta de login inválida.',
      );
    }

    final valid = data['valid'] == true;
    final token = data['token'];

    if (!valid ||
        token is! String ||
        token.isEmpty) {
      return LoginResponse(
        valid: false,
        token: null,
      );
    }

    _token = token;

    ApiClient.instance.setToken(token);

    return LoginResponse(
      valid: true,
      token: token,
    );
  }

  // Cadastro real na API.
  Future<bool> createAccount({
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.instance
        .post(
          '/create/account',
          authenticated: false,
          body: {
            'email': email,
            'password': password,
          },
        )
        .timeout(
          const Duration(seconds: 15),
        );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      if (response.body.isNotEmpty) {
        try {
          final data = jsonDecode(response.body);

          if (data is Map &&
              (data['valid'] == false ||
                  data['success'] == false)) {
            return false;
          }
        } on FormatException {
          // Mantém a compatibilidade com
          // respostas de sucesso sem JSON.
        }
      }

      return true;
    }

    if (response.statusCode == 400 ||
        response.statusCode == 409 ||
        response.statusCode == 422) {
      return false;
    }

    throw Exception(
      'Erro ao criar conta: ${response.statusCode}',
    );
  }

  // Recuperação de senha ainda simulada.
  Future<void> requestPasswordReset({
    required String email,
  }) async {
    await Future.delayed(
      const Duration(milliseconds: 800),
    );

    // Futuramente:
    // POST /password-recovery
  }

  // Logout real na API.
  Future<void> logout() async {
    if (_token == null) {
      // Não existe sessão local ativa.
      ApiClient.instance.setToken(null);
      return;
    }

    final response = await ApiClient.instance
        .post('/logout')
        .timeout(
          const Duration(seconds: 15),
        );

    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao encerrar sessão: '
        '${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic> ||
        data['valid'] != true) {
      throw const FormatException(
        'O servidor não confirmou o logout.',
      );
    }

    // Limpa o token somente depois
    // da confirmação do servidor.
    _token = null;

    ApiClient.instance.setToken(null);
  }

  // Exclui a conta autenticada no servidor.
  Future<void> deleteAccount() async {
    if (_token == null) {
      throw StateError(
        'Nenhuma conta autenticada.',
      );
    }

    final response = await ApiClient.instance
        .delete('/delete/account')
        .timeout(
          const Duration(seconds: 15),
        );

    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao excluir conta: '
        '${response.statusCode}',
      );
    }

    // Verifica se a API informou falha
    // explicitamente no corpo da resposta.
    if (response.body.trim().isNotEmpty) {
      dynamic data;

      try {
        data = jsonDecode(response.body);
      } on FormatException {
        data = null;
      }

      if (data is Map &&
          (data['valid'] == false ||
              data['success'] == false)) {
        throw Exception(
          'O servidor não confirmou a exclusão.',
        );
      }
    }

    // Remove a autenticação local somente
    // depois da resposta de sucesso.
    _token = null;
    ApiClient.instance.setToken(null);
  }
  // Encerra imediatamente a sessão local.
  void clearLocalSession() {
    _token = null;
    ApiClient.instance.setToken(null);
  }

}