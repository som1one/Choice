import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_config.dart';
import 'auth_token_store.dart';

/// WebSocket сервис для real-time чата
class WebSocketChatService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  final Map<String, Function(Map<String, dynamic>)> _messageHandlers = {};
  final Map<String, Function(String, String)> _statusHandlers = {};
  final Map<String, Function(Map<String, dynamic>)> _orderHandlers = {};
  
  /// URL WebSocket endpoint
  String get _wsUrl {
    final scheme = ApiConfig.scheme == 'https' ? 'wss' : 'ws';
    return '${scheme}://${ApiConfig.host}:8006/ws/chat';
  }

  /// Подключиться к WebSocket
  Future<bool> connect() async {
    if (_isConnected && _channel != null) {
      return true;
    }

    try {
      final token = await AuthTokenStore.getToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      final uri = Uri.parse('$_wsUrl?token=${Uri.encodeComponent(token)}');
      _channel = WebSocketChannel.connect(uri);
      
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      _isConnected = true;
      return true;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  /// Отключиться от WebSocket
  Future<void> disconnect() async {
    _isConnected = false;
    await _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _subscription = null;
  }

  /// Отправить сообщение через WebSocket
  Future<bool> sendMessage({
    required String text,
    required String receiverId,
  }) async {
    if (!_isConnected || _channel == null) {
      return false;
    }

    try {
      final message = {
        'type': 'sendMessage',
        'receiver_id': receiverId,
        'text': text,
      };
      _channel!.sink.add(jsonEncode(message));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Подписаться на получение новых сообщений
  void onMessage(Function(Map<String, dynamic>) handler) {
    _messageHandlers['message'] = handler;
  }

  /// Подписаться на изменение статуса пользователя
  void onUserStatusChanged(Function(String userId, String status) handler) {
    _statusHandlers['status'] = handler;
  }

  /// Подписаться на события заказов (enrollmentDateChanged, enrolled, confirmed, statusChanged)
  void onOrderEvent(Function(Map<String, dynamic>) handler) {
    _orderHandlers['order'] = handler;
  }

  /// Обработка входящих сообщений
  void _handleMessage(dynamic data) {
    try {
      final message = jsonDecode(data.toString()) as Map<String, dynamic>;
      final type = message['type'] as String?;

      if (type == 'send') {
        // Новое сообщение от бэкенда
        final messageData = message['message'] as Map<String, dynamic>?;
        if (messageData != null) {
          // Преобразуем формат бэкенда в формат, ожидаемый фронтендом
          // sender_id и receiver_id могут быть UUID (строки)
          final senderId = messageData['sender_id']?.toString() ?? 
                          messageData['senderId']?.toString();
          final receiverId = messageData['receiver_id']?.toString() ?? 
                            messageData['receiverId']?.toString();
          
          final formattedMessage = {
            'id': messageData['id'],
            'text': messageData['text'] ?? messageData['body'] ?? '',
            'sender_id': senderId,
            'receiver_id': receiverId,
            'is_read': messageData['is_read'] ?? messageData['isRead'] ?? false,
            'created_at': messageData['creation_time']?.toString() ?? 
                         messageData['created_at']?.toString() ?? 
                         messageData['createdAt']?.toString(),
            'message_type': messageData['message_type'] ?? 
                           messageData['messageType'] ?? 
                           'Text',
          };
          
          for (final handler in _messageHandlers.values) {
            handler(formattedMessage);
          }
        }
      } else if (type == 'read') {
        // Сообщение прочитано - обновляем статус существующего сообщения
        final messageData = message['message'] as Map<String, dynamic>?;
        if (messageData != null) {
          final senderId = messageData['sender_id']?.toString() ?? 
                          messageData['senderId']?.toString();
          final receiverId = messageData['receiver_id']?.toString() ?? 
                            messageData['receiverId']?.toString();
          
          final formattedMessage = {
            'id': messageData['id'],
            'text': messageData['text'] ?? messageData['body'] ?? '',
            'sender_id': senderId,
            'receiver_id': receiverId,
            'is_read': true,
            'created_at': messageData['creation_time']?.toString() ?? 
                         messageData['created_at']?.toString() ?? 
                         messageData['createdAt']?.toString(),
            'message_type': messageData['message_type'] ?? 
                           messageData['messageType'] ?? 
                           'Text',
          };
          
          for (final handler in _messageHandlers.values) {
            handler(formattedMessage);
          }
        }
      } else if (type == 'userStatusChanged') {
        // Изменение статуса пользователя
        final userId = message['user_id'] as String?;
        final status = message['status'] as String?;
        if (userId != null && status != null) {
          for (final handler in _statusHandlers.values) {
            handler(userId, status);
          }
        }
      } else if (type == 'enrollmentDateChanged') {
        // Изменена дата записи
        final orderData = message['order'] ?? message['data'] ?? message;
        for (final handler in _orderHandlers.values) {
          handler({
            'type': 'enrollmentDateChanged',
            ...orderData,
          });
        }
      } else if (type == 'enrolled') {
        // Запись подтверждена
        final orderData = message['order'] ?? message['data'] ?? message;
        for (final handler in _orderHandlers.values) {
          handler({
            'type': 'enrolled',
            ...orderData,
          });
        }
      } else if (type == 'confirmed') {
        // Дата подтверждена
        final orderData = message['order'] ?? message['data'] ?? message;
        for (final handler in _orderHandlers.values) {
          handler({
            'type': 'confirmed',
            ...orderData,
          });
        }
      } else if (type == 'statusChanged') {
        // Изменен статус заказа
        final orderData = message['order'] ?? message['data'] ?? message;
        for (final handler in _orderHandlers.values) {
          handler({
            'type': 'statusChanged',
            ...orderData,
          });
        }
      }
    } catch (e) {
      // Игнорируем некорректные сообщения
    }
  }

  /// Обработка ошибок
  void _handleError(dynamic error) {
    _isConnected = false;
    // Можно добавить логирование или уведомление об ошибке
  }

  /// Обработка отключения
  void _handleDisconnect() {
    _isConnected = false;
    // Можно попытаться переподключиться
  }

  /// Проверка подключения
  bool get isConnected => _isConnected;
}
