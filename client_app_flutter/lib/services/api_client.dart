import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiClient {
  static const Duration _timeout = Duration(seconds: 10);

  static Uri _uri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${ApiConfig.baseUrl}$normalizedPath');
  }

  static Future<Map<String, dynamic>?> getJson(String path) async {
    if (!ApiConfig.isConfigured) return null;
    try {
      final response = await http.get(
        _uri(path),
        headers: {'Content-Type': 'application/json'},
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
  ) async {
    if (!ApiConfig.isConfigured) return null;
    try {
      final response = await http
          .post(
            _uri(path),
            headers: {'Content-Type': 'application/json'},
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
  ) async {
    if (!ApiConfig.isConfigured) return null;
    try {
      final response = await http
          .put(
            _uri(path),
            headers: {'Content-Type': 'application/json'},
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
}
