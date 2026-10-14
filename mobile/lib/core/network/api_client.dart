import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient(this._auth, {http.Client? client}) : _client = client ?? http.Client();

  final FirebaseAuth _auth;
  final http.Client _client;

  Future<Map<String, String>> _headers() async {
    final user = _auth.currentUser;
    final token = await user?.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    final queryParams = query?.map((key, value) => MapEntry(key, '$value'));
    return Uri.parse(
      '${AppConfig.apiBaseUrl}$normalized',
    ).replace(queryParameters: queryParams);
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    if (response.statusCode == 401) {
      // Token expirado o inválido: cerrar sesión deja que AuthGate reaccione
      // solo (escucha authStateChangesProvider) y muestre el login, en vez
      // de dejar la ApiException cruda en pantalla.
      _auth.signOut();
    }
    String message = 'Error de red';
    try {
      final body = jsonDecode(response.body);
      message = body['error']?.toString() ?? message;
    } catch (_) {}
    throw ApiException(response.statusCode, message);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final response = await _client.get(_uri(path, query), headers: await _headers());
    return _decode(response);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final response = await _client.post(
      _uri(path),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _decode(response);
  }

  Future<dynamic> patch(String path, {Object? body}) async {
    final response = await _client.patch(
      _uri(path),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _decode(response);
  }

  Future<void> delete(String path) async {
    final response = await _client.delete(_uri(path), headers: await _headers());
    _decode(response);
  }
}
