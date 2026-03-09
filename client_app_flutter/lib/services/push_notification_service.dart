import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'api_config.dart';
import 'api_client.dart';
import 'auth_token_store.dart';
import '../main.dart';
import '../screens/chat_screen.dart';
import '../services/auth_service.dart';

/// Сервис для работы с push-уведомлениями через Firebase Cloud Messaging
class PushNotificationService {
  static const String _tokenKey = 'fcm_token';
  static FirebaseMessaging? _messaging;
  static String? _currentToken;

  /// Инициализация FCM
  static Future<void> initialize() async {
    _messaging = FirebaseMessaging.instance;

    // Запрос разрешений
    NotificationSettings settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Получаем токен
      await _getToken();

      // Слушаем обновления токена
      _messaging!.onTokenRefresh.listen((newToken) {
        _currentToken = newToken;
        _saveToken(newToken);
        _sendTokenToServer(newToken);
      });

      // Обработка уведомлений в foreground
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Обработка уведомлений при нажатии (когда приложение в background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      // Проверяем, было ли приложение открыто из уведомления
      RemoteMessage? initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessage(initialMessage);
      }
    }
  }

  /// Получить текущий токен
  static Future<String?> getToken() async {
    if (_currentToken != null) return _currentToken;
    return await _getToken();
  }

  static Future<String?> _getToken() async {
    try {
      final token = await _messaging?.getToken();
      if (token != null) {
        _currentToken = token;
        await _saveToken(token);
        await _sendTokenToServer(token);
      }
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Сохранить токен локально
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Отправить токен на сервер
  static Future<void> _sendTokenToServer(String token) async {
    if (!ApiConfig.isConfigured) return;

    try {
      final authToken = await AuthTokenStore.getToken();
      if (authToken == null) return;

      await ApiClient.putJson(
        '/api/auth/updateDeviceToken?device_token=${Uri.encodeComponent(token)}',
        <String, dynamic>{},
        baseUrl: ApiConfig.authBaseUrl,
      );
    } catch (e) {
      print('Error sending device token to server: $e');
    }
  }

  /// Обработка уведомления в foreground
  static void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.messageId}');
    // TODO: Показать локальное уведомление через flutter_local_notifications
    // или обновить UI приложения
  }

  /// Обработка уведомления при нажатии (background)
  static void _handleBackgroundMessage(RemoteMessage message) {
    print('Background message opened: ${message.messageId}');
    
    // Получаем navigator key из MyApp
    final navigatorKey = MyApp.navigatorKey;
    if (navigatorKey?.currentContext == null) {
      print('Navigator context not available');
      return;
    }
    
    final context = navigatorKey!.currentContext!;
    final data = message.data;
    
    // Определяем тип уведомления и выполняем навигацию
    final type = data['type']?.toString();
    
    if (type == 'message' || type == 'chat') {
      // Навигация к чату
      final senderId = data['sender_id'] ?? data['senderId'];
      final senderName = data['sender_name'] ?? data['senderName'] ?? 'Пользователь';
      final senderIconUri = data['sender_icon_uri'] ?? data['senderIconUri'];
      
      if (senderId != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              userId: senderId.toString(),
              userName: senderName.toString(),
              userIconUri: senderIconUri?.toString(),
            ),
          ),
        );
      }
    } else if (type == 'order' || type == 'orderCreated') {
      // Навигация к деталям заказа (можно открыть список заказов)
      // TODO: Реализовать навигацию к конкретному заказу, если есть order_id
      print('Order notification: ${data['order_id']}');
    } else if (type == 'review') {
      // Навигация к отзывам
      print('Review notification');
    }
  }

  /// Удалить токен (при выходе из аккаунта)
  static Future<void> deleteToken() async {
    try {
      await _messaging?.deleteToken();
      _currentToken = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (e) {
      print('Error deleting FCM token: $e');
    }
  }
}

/// Обработчик фоновых сообщений (должен быть top-level функцией)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message received: ${message.messageId}');
  // TODO: Обработка фоновых уведомлений
}
