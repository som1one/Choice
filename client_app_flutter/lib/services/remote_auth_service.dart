import 'api_client.dart';
import 'api_config.dart';

class RemoteAuthResult {
  final bool success;
  final String? token;

  const RemoteAuthResult({required this.success, this.token});
}

class RemoteAuthService {
  Future<RemoteAuthResult?> registerClient({
    required String fullName,
    required String email,
    required String password,
    required String city,
    String street = '-',
    String phoneNumber = '0000000000',
  }) async {
    final json = await ApiClient.postJson('/api/auth/register', {
      'name': fullName,
      'email': email,
      'password': password,
      'street': street,
      'city': city,
      'phone_number': phoneNumber,
      'type': 'Client',
    }, baseUrl: ApiConfig.authBaseUrl);
    if (json == null) return null;
    return RemoteAuthResult(
      success: (json['success'] as bool?) ?? true,
      token: (json['access_token'] as String?) ??
          (json['token'] as String?) ??
          (json['accessToken'] as String?),
    );
  }

  Future<RemoteAuthResult?> loginClient({
    required String email,
    required String password,
  }) async {
    final json = await ApiClient.postJson('/api/auth/login', {
      'email': email,
      'password': password,
    }, baseUrl: ApiConfig.authBaseUrl);
    if (json == null) return null;
    return RemoteAuthResult(
      success: (json['success'] as bool?) ?? true,
      token: (json['access_token'] as String?) ??
          (json['token'] as String?) ??
          (json['accessToken'] as String?),
    );
  }

  Future<RemoteAuthResult?> registerCompany({
    required String companyName,
    required String email,
    required String password,
    String street = '-',
    String city = '-',
    String phoneNumber = '0000000000',
  }) async {
    final json = await ApiClient.postJson('/api/auth/register', {
      'name': companyName,
      'email': email,
      'password': password,
      'street': street,
      'city': city,
      'phone_number': phoneNumber,
      'type': 'Company',
    }, baseUrl: ApiConfig.authBaseUrl);
    if (json == null) return null;
    return RemoteAuthResult(
      success: (json['success'] as bool?) ?? true,
      token: (json['access_token'] as String?) ??
          (json['token'] as String?) ??
          (json['accessToken'] as String?),
    );
  }

  Future<RemoteAuthResult?> loginCompany({
    required String email,
    required String password,
  }) async {
    final json = await ApiClient.postJson('/api/auth/login', {
      'email': email,
      'password': password,
    }, baseUrl: ApiConfig.authBaseUrl);
    if (json == null) return null;
    return RemoteAuthResult(
      success: (json['success'] as bool?) ?? true,
      token: (json['access_token'] as String?) ??
          (json['token'] as String?) ??
          (json['accessToken'] as String?),
    );
  }

  /// Отправка кода для сброса пароля на email
  Future<bool> resetPassword(String email) async {
    final json = await ApiClient.postJson('/api/auth/resetPassword', {
      'email': email,
    }, baseUrl: ApiConfig.authBaseUrl);
    return json != null;
  }

  /// Верификация кода для сброса пароля
  Future<String?> verifyPasswordReset(String email, String code) async {
    final json = await ApiClient.postJson('/api/auth/verifyPasswordReset', {
      'email': email,
      'code': code,
    }, baseUrl: ApiConfig.authBaseUrl);
    if (json == null) return null;
    return json['reset_token'] as String?;
  }

  /// Установка нового пароля после сброса
  Future<bool> setNewPassword(String password, String resetToken) async {
    final json = await ApiClient.putJson(
      '/api/auth/setNewPassword',
      {'password': password},
      baseUrl: ApiConfig.authBaseUrl,
      headers: {'Authorization': 'Bearer $resetToken'},
    );
    return json != null;
  }

  /// Смена пароля для авторизованного пользователя
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    final json = await ApiClient.putJson(
      '/api/auth/changePassword',
      {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
      baseUrl: ApiConfig.authBaseUrl,
    );
    return json != null;
  }
}
