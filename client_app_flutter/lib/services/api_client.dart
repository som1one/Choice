import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'api_config.dart';
import 'auth_token_store.dart';
import 'api_exception.dart';
import '../utils/error_handler.dart';
import '../services/auth_service.dart';
import '../screens/welcome_screen.dart';

class ApiClient {
  static const Duration _timeout = Duration(seconds: 30);
  
  // Глобальный navigator key для показа ошибок
  static GlobalKey<NavigatorState>? navigatorKey;
  
  /// Установить navigator key для показа ошибок
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
  }
  
  /// Показать ошибку через SnackBar (если доступен context)
  static void _showError(dynamic error, {BuildContext? context}) {
    final ctx = context ?? navigatorKey?.currentContext;
    if (ctx != null) {
      showApiError(ctx, error);
    } else {
      // Если context недоступен, просто логируем ошибку
      print('API Error: $error');
    }
  }

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
    bool throwOnError = false,
  }) async {
    if (!ApiConfig.isConfigured) {
      print('API Error: API not configured (useRemoteApi: ${ApiConfig.useRemoteApi}, host: ${ApiConfig.host})');
      return null;
    }
    try {
      final uri = _uri(baseUrl, path);
      print('API Request: GET $uri');
      final response = await http.get(
        uri,
        headers: await _headers(),
      ).timeout(_timeout);
      print('API Response: ${response.statusCode} for $uri');
      
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final exception = ApiException.fromResponse(response.statusCode, response.body);
        
        // Обработка ошибки 401 (Unauthorized) - перенаправление на экран входа
        if (response.statusCode == 401) {
          await _handleUnauthorized();
          // Не показываем ошибку, так как пользователь будет перенаправлен
          return null;
        }
        
        if (throwOnError) {
          throw exception;
        }
        _showError(exception);
        return null;
      }
      
      if (response.body.isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{'data': decoded};
    } on TimeoutException catch (e) {
      print('API Timeout Error (GET): ${e.message} for $baseUrl$path');
      final exception = ApiException.timeout();
      if (throwOnError) {
        throw exception;
      }
      _showError(exception);
      return null;
    } on http.ClientException catch (e) {
      print('API Network Error (GET): ${e.message} for $baseUrl$path');
      final exception = ApiException.networkError(e.message);
      if (throwOnError) {
        throw exception;
      }
      _showError(exception);
      return null;
    } on SocketException catch (e) {
      print('API Socket Error (GET): ${e.message} for $baseUrl$path');
      final exception = ApiException.networkError('Socket error: ${e.message}');
      if (throwOnError) {
        throw exception;
      }
      _showError(exception);
      return null;
    } on FormatException catch (e) {
      print('API Format Error (GET): ${e.message} for $baseUrl$path');
      final exception = ApiException(
        statusCode: 0,
        message: 'Invalid response format',
        detail: e.message,
      );
      if (throwOnError) {
        throw exception;
      }
      _showError(exception);
      return null;
    } catch (e) {
      print('API Unknown Error (GET): $e for $baseUrl$path');
      if (e is ApiException) {
        if (throwOnError) rethrow;
        _showError(e);
        return null;
      }
      final exception = ApiException.timeout();
      if (throwOnError) {
        throw exception;
      }
      _showError(exception);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> postJson(
    String path,
    Map<String, dynamic> body,
    {required String baseUrl,
    bool throwOnError = false,}
  ) async {
    if (!ApiConfig.isConfigured) {
      print('API Error: API not configured (useRemoteApi: ${ApiConfig.useRemoteApi}, host: ${ApiConfig.host})');
      return null;
    }
    try {
      final uri = _uri(baseUrl, path);
      print('API Request: POST $uri');
      print('API Request Body: ${jsonEncode(body)}');
      final response = await http
          .post(
            uri,
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      print('API Response: ${response.statusCode} for $uri');
      
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final exception = ApiException.fromResponse(response.statusCode, response.body);
        
        // Обработка ошибки 401 (Unauthorized) - перенаправление на экран входа
        if (response.statusCode == 401) {
          await _handleUnauthorized();
          // Не показываем ошибку, так как пользователь будет перенаправлен
          return null;
        }
        
        if (throwOnError) {
          throw exception;
        }
        _showError(exception);
        return null;
      }
      
      if (response.body.isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{'data': decoded};
    } on TimeoutException catch (e) {
      print('API Timeout Error (POST): ${e.message} for $baseUrl$path');
      final exception = ApiException.timeout();
      if (throwOnError) {
        throw exception;
      }
      _showError(exception);
      return null;
    } on http.ClientException catch (e) {
      print('API Network Error (POST): ${e.message} for $baseUrl$path');
      final exception = ApiException.networkError(e.message);
      if (throwOnError) {
        throw exception;
      }
      _showError(exception);
      return null;
    } on SocketException catch (e) {
      print('API Socket Error (POST): ${e.message} for $baseUrl$path');
      final exception = ApiException.networkError('Socket error: ${e.message}');
      if (throwOnError) {
        throw exception;
      }
      _showError(exception);
      return null;
    } on FormatException catch (e) {
      print('API Format Error (POST): ${e.message} for $baseUrl$path');
      final exception = ApiException(
        statusCode: 0,
        message: 'Invalid response format',
        detail: e.message,
      );
      if (throwOnError) {
        throw exception;
      }
      _showError(exception);
      return null;
    } catch (e) {
      print('API Unknown Error (POST): $e (${e.runtimeType}) for $baseUrl$path');
      if (e is ApiException) {
        if (throwOnError) rethrow;
        _showError(e);
        return null;
      }
      final exception = ApiException.timeout();
      if (throwOnError) {
        throw exception;
      }
      _showError(exception);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> putJson(
    String path,
    Map<String, dynamic> body,
    {required String baseUrl, 
    Map<String, String>? headers,
    bool throwOnError = false,}
  ) async {
    if (!ApiConfig.isConfigured) {
      print('API Error: API not configured (useRemoteApi: ${ApiConfig.useRemoteApi}, host: ${ApiConfig.host})');
      return null;
    }
    try {
      final uri = _uri(baseUrl, path);
      print('API Request: PUT $uri');
      print('API Request Body: ${jsonEncode(body)}');
      final defaultHeaders = await _headers();
      if (headers != null) {
        defaultHeaders.addAll(headers);
      }
      final response = await http
          .put(
            uri,
            headers: defaultHeaders,
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      print('API Response: ${response.statusCode} for $uri');
      
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final exception = ApiException.fromResponse(response.statusCode, response.body);
        
        // Обработка ошибки 401 (Unauthorized) - перенаправление на экран входа
        if (response.statusCode == 401) {
          await _handleUnauthorized();
          // Не показываем ошибку, так как пользователь будет перенаправлен
          return null;
        }
        
        if (throwOnError) {
          throw exception;
        }
        _showError(exception);
        return null;
      }
      
      if (response.body.isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{'data': decoded};
    } on TimeoutException catch (e) {
      print('API Timeout Error (DELETE): ${e.message} for $baseUrl$path');
      final exception = ApiException.timeout();
      if (throwOnError) {
        throw exception;
      }
      _showError(exception);
      return null;
    } on http.ClientException catch (e) {
      print('API Network Error (DELETE): ${e.message} for $baseUrl$path');
      final exception = ApiException.networkError(e.message);
      if (throwOnError) {
        throw exception;
      }
      _showError(exception);
      return null;
    } on SocketException catch (e) {
      print('API Socket Error (DELETE): ${e.message} for $baseUrl$path');
      final exception = ApiException.networkError('Socket error: ${e.message}');
      if (throwOnError) {
        throw exception;
      }
      _showError(exception);
      return null;
    } on FormatException catch (e) {
      print('API Format Error (DELETE): ${e.message} for $baseUrl$path');
      final exception = ApiException(
        statusCode: 0,
        message: 'Invalid response format',
        detail: e.message,
      );
      if (throwOnError) {
        throw exception;
      }
      _showError(exception);
      return null;
    } catch (e) {
      print('API Unknown Error (DELETE): $e (${e.runtimeType}) for $baseUrl$path');
      if (e is ApiException) {
        if (throwOnError) rethrow;
        _showError(e);
        return null;
      }
      final exception = ApiException.timeout();
      if (throwOnError) {
        throw exception;
      }
      _showError(exception);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> deleteJson(
    String path, {
    required String baseUrl,
    bool throwOnError = false,
  }) async {
    if (!ApiConfig.isConfigured) return null;
    try {
      final response = await http
          .delete(
            _uri(baseUrl, path),
            headers: await _headers(),
          )
          .timeout(_timeout);
      
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final exception = ApiException.fromResponse(response.statusCode, response.body);
        
        // Обработка ошибки 401 (Unauthorized) - перенаправление на экран входа
        if (response.statusCode == 401) {
          await _handleUnauthorized();
          // Не показываем ошибку, так как пользователь будет перенаправлен
          return null;
        }
        
        if (throwOnError) {
          throw exception;
        }
        _showError(exception);
        return null;
      }
      
      if (response.body.isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{'data': decoded};
    } on TimeoutException catch (e) {
      print('API Timeout Error (PUT): ${e.message} for $baseUrl$path');
      final exception = ApiException.timeout();
      if (throwOnError) {
        throw exception;
      }
      _showError(exception);
      return null;
    } on http.ClientException catch (e) {
      print('API Network Error (PUT): ${e.message} for $baseUrl$path');
      final exception = ApiException.networkError(e.message);
      if (throwOnError) {
        throw exception;
      }
      _showError(exception);
      return null;
    } on SocketException catch (e) {
      print('API Socket Error (PUT): ${e.message} for $baseUrl$path');
      final exception = ApiException.networkError('Socket error: ${e.message}');
      if (throwOnError) {
        throw exception;
      }
      _showError(exception);
      return null;
    } on FormatException catch (e) {
      print('API Format Error (PUT): ${e.message} for $baseUrl$path');
      final exception = ApiException(
        statusCode: 0,
        message: 'Invalid response format',
        detail: e.message,
      );
      if (throwOnError) {
        throw exception;
      }
      _showError(exception);
      return null;
    } catch (e) {
      print('API Unknown Error (PUT): $e for $baseUrl$path');
      if (e is ApiException) {
        if (throwOnError) rethrow;
        _showError(e);
        return null;
      }
      final exception = ApiException.timeout();
      if (throwOnError) {
        throw exception;
      }
      _showError(exception);
      return null;
    }
  }

  /// Обработка ошибки 401 - очистка токена и перенаправление на экран входа
  static Future<void> _handleUnauthorized() async {
    // Очищаем токен
    await AuthTokenStore.clearToken();
    await AuthService.logout();
    
    // Перенаправляем на экран входа
    final context = navigatorKey?.currentContext;
    if (context != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }
}
