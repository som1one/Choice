import 'api_client.dart';

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
  }) async {
    final json = await ApiClient.postJson('/auth/client/register', {
      'fullName': fullName,
      'email': email,
      'password': password,
      'city': city,
    });
    if (json == null) return null;
    return RemoteAuthResult(
      success: (json['success'] as bool?) ?? true,
      token: (json['token'] as String?) ?? (json['accessToken'] as String?),
    );
  }

  Future<RemoteAuthResult?> loginClient({
    required String email,
    required String password,
  }) async {
    final json = await ApiClient.postJson('/auth/client/login', {
      'email': email,
      'password': password,
    });
    if (json == null) return null;
    return RemoteAuthResult(
      success: (json['success'] as bool?) ?? true,
      token: (json['token'] as String?) ?? (json['accessToken'] as String?),
    );
  }

  Future<RemoteAuthResult?> registerCompany({
    required String companyName,
    required String inn,
    required String email,
    required String password,
  }) async {
    final json = await ApiClient.postJson('/auth/company/register', {
      'companyName': companyName,
      'inn': inn,
      'email': email,
      'password': password,
    });
    if (json == null) return null;
    return RemoteAuthResult(
      success: (json['success'] as bool?) ?? true,
      token: (json['token'] as String?) ?? (json['accessToken'] as String?),
    );
  }

  Future<RemoteAuthResult?> loginCompany({
    required String email,
    required String password,
  }) async {
    final json = await ApiClient.postJson('/auth/company/login', {
      'email': email,
      'password': password,
    });
    if (json == null) return null;
    return RemoteAuthResult(
      success: (json['success'] as bool?) ?? true,
      token: (json['token'] as String?) ?? (json['accessToken'] as String?),
    );
  }
}
