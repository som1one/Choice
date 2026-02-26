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
}
