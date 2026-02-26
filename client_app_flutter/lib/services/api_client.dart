import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_token_store.dart';

class ApiClient {
  static const Duration _timeout = Duration(seconds: 10);

  static Uri _uri(String baseUrl, String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await AuthTokenStore.getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<Map<String, dynamic>?> getJson(
    String path, {
    required String baseUrl,
  }) async {
    if (!ApiConfig.isConfigured) return null;
    try {
      final response = await http.get(
        _uri(baseUrl, path),
        headers: await _headers(),
      ).timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      if (response.body.isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{'data': decoded};
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> postJson(
    String path,
    Map<String, dynamic> body,
    {required String baseUrl,}
  ) async {
    if (!ApiConfig.isConfigured) return null;
    try {
      final response = await http
          .post(
            _uri(baseUrl, path),
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      if (response.body.isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{'data': decoded};
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> putJson(
    String path,
    Map<String, dynamic> body,
    {required String baseUrl,}
  ) async {
    if (!ApiConfig.isConfigured) return null;
    try {
      final response = await http
          .put(
            _uri(baseUrl, path),
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      if (response.body.isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{'data': decoded};
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> deleteJson(
    String path, {
    required String baseUrl,
  }) async {
    if (!ApiConfig.isConfigured) return null;
    try {
      final response = await http
          .delete(
            _uri(baseUrl, path),
            headers: await _headers(),
          )
          .timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      if (response.body.isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{'data': decoded};
    } catch (_) {
      return null;
    }
  }
}
