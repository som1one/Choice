import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';
import 'auth_token_store.dart';

/// Сервис для загрузки файлов на сервер
class RemoteFileService {
  /// Максимальный размер файла (2MB, как на бэкенде)
  static const int maxFileSize = 2 * 1024 * 1024; // 2MB
  
  /// Загрузить файл на сервер
  /// 
  /// [filePath] - путь к локальному файлу
  /// 
  /// Возвращает имя файла на сервере (filename) или null в случае ошибки
  Future<String?> uploadFile(String filePath) async {
    if (!ApiConfig.isConfigured) return null;
    
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('File does not exist: $filePath');
        return null;
      }

      // Проверка размера файла
      final fileSize = await file.length();
      if (fileSize > maxFileSize) {
        print('File too large: ${fileSize} bytes (max: $maxFileSize)');
        return null;
      }

      final uri = Uri.parse('${ApiConfig.fileBaseUrl}/api/objects/upload');
      final request = http.MultipartRequest('POST', uri);
      
      // Добавляем токен авторизации
      final token = await AuthTokenStore.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      // Добавляем файл
      request.files.add(
        await http.MultipartFile.fromPath('file', filePath),
      );
      
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>?;
        final filename = responseBody?['filename'] as String?;
        if (filename != null && filename.isNotEmpty) {
          return filename;
        }
        // Если filename не найден, но есть message об успехе, пробуем извлечь из другого поля
        final message = responseBody?['message'] as String?;
        if (message != null && message.contains('success')) {
          // Возможно, filename в другом формате ответа
          print('Upload successful but filename not found in response');
        }
      } else {
        // Обработка различных статусов ошибок
        String errorMessage = 'Upload failed';
        try {
          if (response.body.isNotEmpty) {
            final errorBody = jsonDecode(response.body);
            if (errorBody is Map<String, dynamic>) {
              errorMessage = errorBody['detail']?.toString() ?? 
                            errorBody['message']?.toString() ?? 
                            'Upload failed with status: ${response.statusCode}';
            } else {
              errorMessage = response.body;
            }
          } else {
            errorMessage = 'Upload failed with status: ${response.statusCode}';
          }
        } catch (e) {
          // Если не удалось распарсить JSON, используем тело ответа как есть
          errorMessage = response.body.isNotEmpty 
              ? response.body 
              : 'Upload failed with status: ${response.statusCode}';
        }
        print('Upload error: $errorMessage');
        print('Response body: ${response.body}');
        // Выбрасываем исключение с понятным сообщением
        throw Exception(errorMessage);
      }
    } on http.ClientException catch (e) {
      print('Network error uploading file: $e');
      throw Exception('Network error: ${e.message}');
    } on TimeoutException catch (e) {
      print('Timeout uploading file: $e');
      throw Exception('Upload timeout: ${e.message}');
    } on FormatException catch (e) {
      print('Invalid response format: $e');
      throw Exception('Invalid response format: ${e.message}');
    } catch (e) {
      print('Error uploading file: $e');
      // Убеждаемся, что исключение имеет строковое представление
      final errorMsg = e.toString().replaceAll('_Namespace', '').trim();
      throw Exception(errorMsg.isNotEmpty ? errorMsg : 'Unknown error occurred');
    }
    
    return null;
  }

  /// Получить URL для доступа к файлу
  static String getFileUrl(String filename) {
    return '${ApiConfig.fileBaseUrl}/api/objects/$filename';
  }
}
