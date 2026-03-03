import 'api_client.dart';
import 'api_config.dart';

class RemoteChatService {
  /// Получить сообщения с конкретным пользователем
  Future<List<Map<String, dynamic>>?> getMessages(String receiverId) async {
    final json = await ApiClient.getJson(
      '/api/message/getMessages?receiver_id=$receiverId',
      baseUrl: ApiConfig.chatBaseUrl,
    );
    if (json == null) return null;
    
    // Если это список, возвращаем как есть
    if (json is List) {
      return (json as List).map((e) => e as Map<String, dynamic>).toList();
    }
    // Если это объект с массивом сообщений
    if (json is Map<String, dynamic>) {
      final messages = json['messages'] ?? json['data'];
      if (messages is List) {
        return (messages as List).map((e) => e as Map<String, dynamic>).toList();
      }
    }
    return [];
  }

  /// Получить чат с конкретным пользователем (включая информацию о пользователе)
  Future<Map<String, dynamic>?> getChat(String userId) async {
    final json = await ApiClient.getJson(
      '/api/message/getChat?user_id=$userId',
      baseUrl: ApiConfig.chatBaseUrl,
    );
    return json;
  }

  /// Получить все чаты текущего пользователя
  Future<List<Map<String, dynamic>>?> getChats() async {
    final json = await ApiClient.getJson(
      '/api/message/getChats',
      baseUrl: ApiConfig.chatBaseUrl,
    );
    if (json == null) return null;
    
    // Если это список, возвращаем как есть
    if (json is List) {
      return (json as List).map((e) => e as Map<String, dynamic>).toList();
    }
    // Если это объект с массивом чатов
    if (json is Map<String, dynamic>) {
      final chats = json['chats'] ?? json['data'];
      if (chats is List) {
        return (chats as List).map((e) => e as Map<String, dynamic>).toList();
      }
    }
    return [];
  }

  /// Отправить текстовое сообщение
  Future<Map<String, dynamic>?> sendMessage({
    required String text,
    required String receiverId,
  }) async {
    final body = <String, dynamic>{
      'receiver_id': receiverId,
      'text': text,
    };
    final json = await ApiClient.postJson(
      '/api/message/send',
      body,
      baseUrl: ApiConfig.chatBaseUrl,
    );
    return json;
  }

  /// Отправить изображение
  Future<Map<String, dynamic>?> sendImage({
    required String imageUri,
    required String receiverId,
  }) async {
    final body = <String, dynamic>{
      'receiver_id': receiverId,
      'uri': imageUri,
    };
    final json = await ApiClient.postJson(
      '/api/message/sendImage',
      body,
      baseUrl: ApiConfig.chatBaseUrl,
    );
    return json;
  }

  /// Отметить сообщение как прочитанное
  Future<bool> readMessage(int messageId) async {
    final json = await ApiClient.putJson(
      '/api/message/read?message_id=$messageId',
      <String, dynamic>{},
      baseUrl: ApiConfig.chatBaseUrl,
    );
    return json != null;
  }
}
