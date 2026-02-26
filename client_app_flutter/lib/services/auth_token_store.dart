import 'package:shared_preferences/shared_preferences.dart';

/// Хранилище токена авторизации для API.
///
/// Вынесено отдельно, чтобы `ApiClient` мог читать токен без циклических импортов
/// (AuthService -> RemoteAuthService -> ApiClient).
class AuthTokenStore {
  static const String _authTokenKey = 'auth_token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_authTokenKey);
    if (token == null || token.trim().isEmpty) return null;
    return token;
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = token.trim();
    if (normalized.isEmpty) return;
    await prefs.setString(_authTokenKey, normalized);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
  }
}

