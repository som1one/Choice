import 'dart:convert';

/// Исключение для ошибок API
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? detail;
  final Map<String, dynamic>? rawResponse;

  ApiException({
    required this.statusCode,
    required this.message,
    this.detail,
    this.rawResponse,
  });

  /// Получить детальное сообщение об ошибке
  String get errorMessage {
    if (detail != null && detail!.isNotEmpty) {
      // Переводим стандартные сообщения об ошибках на русский
      String detailText = detail!;
      if (statusCode == 401) {
        if (detailText.toLowerCase().contains('invalid authentication') ||
            detailText.toLowerCase().contains('not authenticated') ||
            detailText.toLowerCase().contains('unauthorized')) {
          return 'Сессия истекла. Пожалуйста, войдите снова';
        }
      }
      return detailText;
    }
    // Переводим стандартные сообщения об ошибках на русский
    if (statusCode == 401) {
      return 'Сессия истекла. Пожалуйста, войдите снова';
    }
    return message;
  }

  @override
  String toString() {
    return 'ApiException(statusCode: $statusCode, message: $message, detail: $detail)';
  }

  /// Создать ApiException из HTTP ответа
  static ApiException fromResponse(int statusCode, String responseBody) {
    String message = 'HTTP $statusCode';
    String? detail;

    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        // FastAPI возвращает ошибки в формате {"detail": "..."}
        detail = decoded['detail']?.toString();
        
        // Также проверяем другие возможные поля
        if (detail == null) {
          detail = decoded['message']?.toString();
        }
        if (detail == null) {
          detail = decoded['error']?.toString();
        }

        return ApiException(
          statusCode: statusCode,
          message: message,
          detail: detail,
          rawResponse: decoded,
        );
      }
    } catch (_) {
      // Если не удалось распарсить JSON, используем тело ответа как детали
      if (responseBody.isNotEmpty) {
        detail = responseBody;
      }
    }

    return ApiException(
      statusCode: statusCode,
      message: message,
      detail: detail,
    );
  }

  /// Создать ApiException для сетевых ошибок
  static ApiException networkError(String message) {
    String detail = message;
    // Переводим стандартные сообщения об ошибках на русский
    if (message.toLowerCase().contains('failed to fetch') ||
        message.toLowerCase().contains('connection refused') ||
        message.toLowerCase().contains('network is unreachable')) {
      detail = 'Не удалось подключиться к серверу. Проверьте подключение к интернету и убедитесь, что сервер запущен';
    } else if (message.toLowerCase().contains('socketexception')) {
      detail = 'Ошибка подключения к серверу. Сервер может быть недоступен';
    }
    
    return ApiException(
      statusCode: 0,
      message: 'Ошибка сети',
      detail: detail,
    );
  }

  /// Создать ApiException для таймаута
  static ApiException timeout() {
    return ApiException(
      statusCode: 0,
      message: 'Request timeout',
      detail: 'Запрос превысил время ожидания',
    );
  }
}
