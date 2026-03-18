import 'api_client.dart';
import 'api_config.dart';

class RemoteClientService {
  /// Получить профиль клиента (текущего пользователя)
  Future<Map<String, dynamic>?> getClientProfile({bool throwOnError = false}) async {
    final json = await ApiClient.getJson(
      '/api/client/get',
      baseUrl: ApiConfig.clientBaseUrl,
      throwOnError: throwOnError,
    );
    return json;
  }

  /// Получить заявку по ID
  Future<Map<String, dynamic>?> getOrderRequest(int id) async {
    final json = await ApiClient.getJson(
      '/api/client/getRequest?request_id=$id',
      baseUrl: ApiConfig.clientBaseUrl,
    );
    return json;
  }

  /// Получить заявки (по категории или все заявки клиента)
  /// Если categoryId не указан, возвращает все заявки текущего клиента
  Future<List<Map<String, dynamic>>?> getOrderRequests({
    int? categoryId,
  }) async {
    final url = categoryId != null
        ? '/api/client/getOrderRequests?category_id=$categoryId'
        : '/api/client/getOrderRequests';

    final json = await ApiClient.getJson(url, baseUrl: ApiConfig.clientBaseUrl);

    if (json == null) return null;
    if (json is List) {
      return (json as List).map((e) => e as Map<String, dynamic>).toList();
    }
    if (json is Map<String, dynamic>) {
      final requests = json['requests'] ?? json['data'];
      if (requests is List) {
        return (requests as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }
    }
    return [];
  }

  /// Изменить данные клиента
  Future<Map<String, dynamic>?> changeUserData({
    required String name,
    required String surname,
    required String email,
    required String phoneNumber,
    required String city,
    required String street,
    bool throwOnError = false,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'surname': surname,
      'email': email,
      'phone_number': phoneNumber,
      'city': city,
      'street': street,
    };

    final json = await ApiClient.putJson(
      '/api/client/changeUserData',
      body,
      baseUrl: ApiConfig.clientBaseUrl,
      throwOnError: throwOnError,
    );
    return json;
  }

  /// Изменить иконку клиента
  Future<Map<String, dynamic>?> changeIconUri(String iconUri) async {
    // Бэкенд принимает uri как query параметр
    final json = await ApiClient.putJson(
      '/api/client/changeIconUri?uri=${Uri.encodeComponent(iconUri)}',
      <String, dynamic>{},
      baseUrl: ApiConfig.clientBaseUrl,
    );
    return json;
  }

  /// Получить клиента по GUID (для компаний)
  Future<Map<String, dynamic>?> getClientByGuid(String guid) async {
    final json = await ApiClient.getJson(
      '/api/client/getClientByGuid?guid=$guid',
      baseUrl: ApiConfig.clientBaseUrl,
    );
    return json;
  }
}
