import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'api_config.dart';
import 'remote_auth_service.dart';
import 'auth_token_store.dart';

enum UserType { client, company, admin }

class AuthService {
  static const String _isRegisteredKey = 'is_registered';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userTypeKey = 'user_type';
  static const String _clientCredentialsKey = 'client_credentials';
  static const String _companyCredentialsKey = 'company_credentials';
  static const String _authTokenKey = 'auth_token';
  static const String _adminCredentialsKey = 'admin_credentials';
  static const String _testClientAdminEmail = 'admin@client.test';
  static const String _testClientAdminPassword = '123456';
  static const String _testCompanyAdminEmail = 'admin@company.test';
  static const String _testCompanyAdminPassword = '123456';

  // Админ (задается при сборке через dart-define)
  static const String _adminEmail =
      String.fromEnvironment('ADMIN_EMAIL', defaultValue: 'admin@choice.local');
  static const String _adminPassword =
      String.fromEnvironment('ADMIN_PASSWORD', defaultValue: 'admin123456');
  static final RemoteAuthService _remoteAuth = RemoteAuthService();

  static String _hashPassword(String password) {
    final digest = sha256.convert(utf8.encode(password));
    return 'sha256:$digest';
  }

  static bool _verifyPassword(String savedPassword, String candidatePassword) {
    if (savedPassword.startsWith('sha256:')) {
      return savedPassword == _hashPassword(candidatePassword);
    }
    // Легаси-формат: ранее пароль мог храниться в открытом виде.
    return savedPassword == candidatePassword;
  }

  static Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final normalized = base64Url.normalize(parts[1]);
      final bytes = base64Url.decode(normalized);
      final jsonStr = utf8.decode(bytes);
      final decoded = jsonDecode(jsonStr);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  // Сохранить статус регистрации
  static Future<void> setRegistered(bool value, {UserType? userType}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isRegisteredKey, value);
    if (userType != null) {
      await prefs.setString(_userTypeKey, userType.toString());
    }
  }

  // Получить статус регистрации
  static Future<bool> isRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isRegisteredKey) ?? false;
  }

  // Сохранить статус входа
  static Future<void> setLoggedIn(bool value, {UserType? userType}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, value);
    if (userType != null) {
      await prefs.setString(_userTypeKey, userType.toString());
    }
  }

  // Получить статус входа
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Получить тип пользователя
  static Future<UserType?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    final userTypeString = prefs.getString(_userTypeKey);
    if (userTypeString == null) return null;
    return UserType.values.firstWhere(
      (e) => e.toString() == userTypeString,
      orElse: () => UserType.client,
    );
  }

  // Проверить, является ли пользователь компанией
  static Future<bool> isCompany() async {
    final userType = await getUserType();
    return userType == UserType.company;
  }

  static Future<bool> isAdmin() async {
    final userType = await getUserType();
    return userType == UserType.admin;
  }

  // Проверить, авторизован ли пользователь (зарегистрирован или вошел)
  static Future<bool> isAuthenticated() async {
    final registered = await isRegistered();
    final loggedIn = await isLoggedIn();
    return registered || loggedIn;
  }

  static Future<void> registerClient({
    required String fullName,
    required String email,
    required String password,
    required String city,
    required String street,
    required String phoneNumber,
  }) async {
    String? remoteToken;
    if (ApiConfig.isConfigured) {
      final remoteResult = await _remoteAuth.registerClient(
        fullName: fullName,
        email: email,
        password: password,
        city: city,
        street: street,
        phoneNumber: phoneNumber,
      );
      if (remoteResult != null && !remoteResult.success) {
        return;
      }
      remoteToken = remoteResult?.token;
    }

    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'fullName': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'password': _hashPassword(password),
      'city': city,
      'street': street.trim(),
      'phoneNumber': phoneNumber.trim(),
    });
    await prefs.setString(_clientCredentialsKey, payload);
    if (remoteToken != null && remoteToken.isNotEmpty) {
      await prefs.setString(_authTokenKey, remoteToken);
    }
    await setRegistered(true, userType: UserType.client);
    await setLoggedIn(true, userType: UserType.client);
  }

  static Future<bool> loginClient({
    required String loginOrEmail,
    required String password,
  }) async {
    // Встроенный тестовый аккаунт клиента-админа
    if (!kReleaseMode &&
        loginOrEmail.trim().toLowerCase() == _testClientAdminEmail &&
        password == _testClientAdminPassword) {
      await setLoggedIn(true, userType: UserType.client);
      return true;
    }

    if (ApiConfig.isConfigured) {
      final remoteResult = await _remoteAuth.loginClient(
        email: loginOrEmail.trim().toLowerCase(),
        password: password,
      );
      if (remoteResult != null) {
        if (!remoteResult.success) return false;
        final prefs = await SharedPreferences.getInstance();
        if (remoteResult.token != null && remoteResult.token!.isNotEmpty) {
          await prefs.setString(_authTokenKey, remoteResult.token!);
        }
        await setLoggedIn(true, userType: UserType.client);
        return true;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_clientCredentialsKey);
    if (raw == null) return false;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final savedEmail = (data['email'] as String? ?? '').toLowerCase();
    final savedPassword = data['password'] as String? ?? '';
    final candidate = loginOrEmail.trim().toLowerCase();
    final ok = candidate == savedEmail && _verifyPassword(savedPassword, password);
    if (ok) {
      if (!savedPassword.startsWith('sha256:')) {
        data['password'] = _hashPassword(password);
        await prefs.setString(_clientCredentialsKey, jsonEncode(data));
      }
      await setLoggedIn(true, userType: UserType.client);
    }
    return ok;
  }

  static Map<String, String> getClientAdminTestCredentials() {
    return {
      'email': _testClientAdminEmail,
      'password': _testClientAdminPassword,
    };
  }

  static Map<String, String> getCompanyAdminTestCredentials() {
    return {
      'email': _testCompanyAdminEmail,
      'password': _testCompanyAdminPassword,
    };
  }

  static Future<void> registerCompany({
    required String companyName,
    required String email,
    required String password,
    required String phoneNumber,
    String? companyType,
    String? inn,
    String? city,
    String? street,
  }) async {
    final normalizedInn = (inn ?? '').trim();
    final normalizedCity = (city ?? '-').trim().isEmpty ? '-' : (city ?? '-').trim();
    final normalizedStreet = (street ?? '-').trim().isEmpty ? '-' : (street ?? '-').trim();

    String? remoteToken;
    if (ApiConfig.isConfigured) {
      final remoteResult = await _remoteAuth.registerCompany(
        companyName: companyName,
        email: email,
        password: password,
        city: normalizedCity,
        street: normalizedStreet,
        phoneNumber: phoneNumber,
      );
      if (remoteResult != null && !remoteResult.success) {
        return;
      }
      remoteToken = remoteResult?.token;
    }

    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'companyName': companyName.trim(),
      'inn': normalizedInn,
      'email': email.trim().toLowerCase(),
      'password': _hashPassword(password),
      'city': normalizedCity,
      'street': normalizedStreet,
      'phoneNumber': phoneNumber.trim(),
      if (companyType != null && companyType.trim().isNotEmpty) 'companyType': companyType.trim(),
    });
    await prefs.setString(_companyCredentialsKey, payload);
    if (remoteToken != null && remoteToken.isNotEmpty) {
      await prefs.setString(_authTokenKey, remoteToken);
    }
    await setRegistered(true, userType: UserType.company);
  }

  static Future<bool> loginAdmin({
    required String email,
    required String password,
  }) async {
    final candidate = email.trim().toLowerCase();

    // Сначала пробуем реальный бек-логин (нужен токен с user_type=Admin)
    if (ApiConfig.isConfigured) {
      final remote = await _remoteAuth.loginClient( // тот же /api/auth/login
        email: candidate,
        password: password,
      );
      if (remote != null && remote.success && (remote.token ?? '').isNotEmpty) {
        final token = remote.token!;
        final payload = _decodeJwtPayload(token);
        final userType = payload?['user_type']?.toString();
        if (userType == 'Admin') {
          await AuthTokenStore.setToken(token);
          await setLoggedIn(true, userType: UserType.admin);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_adminCredentialsKey, jsonEncode({'email': candidate}));
          return true;
        }
      }
    }

    // Локальный фолбэк (для dev/offline)
    final ok = candidate == _adminEmail.trim().toLowerCase() && password == _adminPassword;
    if (!ok) return false;
    await setLoggedIn(true, userType: UserType.admin);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminCredentialsKey, jsonEncode({'email': candidate}));
    return true;
  }

  static Map<String, String> getAdminCredentialsHint() {
    return {
      'email': _adminEmail,
      'password': _adminPassword,
    };
  }

  static Future<bool> loginCompany({
    required String email,
    required String password,
  }) async {
    // Встроенный тестовый аккаунт компании-админа (только debug/profile)
    if (!kReleaseMode &&
        email.trim().toLowerCase() == _testCompanyAdminEmail &&
        password == _testCompanyAdminPassword) {
      await setLoggedIn(true, userType: UserType.company);
      return true;
    }

    if (ApiConfig.isConfigured) {
      final remoteResult = await _remoteAuth.loginCompany(
        email: email,
        password: password,
      );
      if (remoteResult != null) {
        if (!remoteResult.success) return false;
        final prefs = await SharedPreferences.getInstance();
        if (remoteResult.token != null && remoteResult.token!.isNotEmpty) {
          await prefs.setString(_authTokenKey, remoteResult.token!);
        }
        await setLoggedIn(true, userType: UserType.company);
        return true;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_companyCredentialsKey);
    if (raw == null) return false;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final savedEmail = (data['email'] as String? ?? '').toLowerCase();
    final savedPassword = data['password'] as String? ?? '';
    final ok = email.trim().toLowerCase() == savedEmail &&
        _verifyPassword(savedPassword, password);
    if (ok) {
      if (!savedPassword.startsWith('sha256:')) {
        data['password'] = _hashPassword(password);
        await prefs.setString(_companyCredentialsKey, jsonEncode(data));
      }
      await setLoggedIn(true, userType: UserType.company);
    }
    return ok;
  }

  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTokenKey);
  }

  // Выход из системы (очистить все данные)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isRegisteredKey);
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_userTypeKey);
    await prefs.remove(_authTokenKey);
    await prefs.remove(_adminCredentialsKey);
  }
}
