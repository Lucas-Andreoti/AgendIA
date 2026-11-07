import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  String? get token => _token;

  Map<String, String> _buildHeaders({
    bool authenticated = true,
  }) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',

      if (authenticated && _token != null)
        'Authorization': 'Bearer $_token',
    };
  }

  Future<http.Response> get(
    String endpoint, {
    bool authenticated = true,
  }) {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}$endpoint',
    );

    return http.get(
      uri,
      headers: _buildHeaders(
        authenticated: authenticated,
      ),
    );
  }

  Future<http.Response> post(
    String endpoint, {
    Object? body,
    bool authenticated = true,
  }) {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}$endpoint',
    );

    return http.post(
      uri,
      headers: _buildHeaders(
        authenticated: authenticated,
      ),
      body: body == null
          ? null
          : jsonEncode(body),
    );
  }

  Future<http.Response> put(
    String endpoint, {
    Object? body,
    bool authenticated = true,
  }) {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}$endpoint',
    );

    return http.put(
      uri,
      headers: _buildHeaders(
        authenticated: authenticated,
      ),
      body: body == null
          ? null
          : jsonEncode(body),
    );
  }

  Future<http.Response> delete(
    String endpoint, {
    Object? body,
    bool authenticated = true,
  }) {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}$endpoint',
    );

    return http.delete(
      uri,
      headers: _buildHeaders(
        authenticated: authenticated,
      ),
      body: body == null
          ? null
          : jsonEncode(body),
    );
  }
}