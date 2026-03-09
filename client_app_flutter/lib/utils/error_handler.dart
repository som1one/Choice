import 'package:flutter/material.dart';
import '../services/api_exception.dart';

/// Показать ошибку API пользователю через SnackBar
void showApiError(BuildContext? context, dynamic error, {String? defaultMessage}) {
  if (context == null) return;
  
  String message = defaultMessage ?? 'Произошла ошибка';
  
  if (error is ApiException) {
    message = error.errorMessage;
  } else if (error is Exception) {
    message = error.toString();
  } else if (error is String) {
    message = error;
  }
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 4),
      backgroundColor: Colors.red,
    ),
  );
}

/// Получить сообщение об ошибке из исключения
String getErrorMessage(dynamic error, {String? defaultMessage}) {
  if (error is ApiException) {
    return error.errorMessage;
  } else if (error is Exception) {
    return error.toString();
  } else if (error is String) {
    return error;
  }
  return defaultMessage ?? 'Произошла неизвестная ошибка';
}
