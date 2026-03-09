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

  // Проверить, авторизован ли пользователь (проверяем токен или статус входа)
  static Future<bool> isAuthenticated() async {
    // Сначала проверяем токен
    final token = await getAuthToken();
    if (token != null && token.isNotEmpty) {
      // Проверяем валидность токена (exp)
      final payload = _decodeJwtPayload(token);
      if (payload != null) {
        final exp = payload['exp'] as int?;
        if (exp != null) {
          final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          if (exp > currentTime) {
            // Токен валиден, обновляем userType из токена
            final userTypeStr = payload['user_type']?.toString();
            if (userTypeStr != null) {
              UserType? userType;
              if (userTypeStr == 'Client') userType = UserType.client;
              else if (userTypeStr == 'Company') userType = UserType.company;
              else if (userTypeStr == 'Admin') userType = UserType.admin;
              if (userType != null) {
                await setLoggedIn(true, userType: userType);
              }
            }
            return true;
          }
        } else {
          // Если нет exp, считаем токен валидным
          return true;
        }
      }
    }
    // Если токена нет или он невалиден, проверяем статус входа
    return await isLoggedIn();
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
      await AuthTokenStore.setToken(remoteToken);
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
          final token = remoteResult.token!;
          await prefs.setString(_authTokenKey, token);
          await AuthTokenStore.setToken(token);
          
          // Определяем userType из токена
          final payload = _decodeJwtPayload(token);
          UserType? userType = UserType.client; // По умолчанию клиент
          if (payload != null) {
            final userTypeStr = payload['user_type']?.toString();
            if (userTypeStr == 'Company') userType = UserType.company;
            else if (userTypeStr == 'Admin') userType = UserType.admin;
          }
          await setLoggedIn(true, userType: userType);
        } else {
          await setLoggedIn(true, userType: UserType.client);
        }
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
        throw Exception('Ошибка регистрации');
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
    
    // Сохраняем данные регистрации в настройки компании для отображения в профиле
    String addressText = '';
    if (normalizedCity != '-' && normalizedStreet != '-') {
      addressText = '$normalizedCity, $normalizedStreet';
    } else if (normalizedCity != '-') {
      addressText = normalizedCity;
    } else if (normalizedStreet != '-') {
      addressText = normalizedStreet;
    }
    
    final companySettings = jsonEncode({
      'f_Название': companyName.trim(),
      'f_Mail': email.trim().toLowerCase(),
      'f_Телефон': phoneNumber.trim(),
      if (addressText.isNotEmpty) 'f_Адрес': addressText,
    });
    await prefs.setString('company_settings', companySettings);
    
    // Сохраняем токен в двух местах
    if (remoteToken != null && remoteToken.isNotEmpty) {
      await prefs.setString(_authTokenKey, remoteToken);
      await AuthTokenStore.setToken(remoteToken);
      
      // Определяем userType из токена
      final payload = _decodeJwtPayload(remoteToken);
      UserType? userType = UserType.company; // По умолчанию компания
      if (payload != null) {
        final userTypeStr = payload['user_type']?.toString();
        if (userTypeStr == 'Client') userType = UserType.client;
        else if (userTypeStr == 'Company') userType = UserType.company;
        else if (userTypeStr == 'Admin') userType = UserType.admin;
      }
      
      // Устанавливаем статусы с правильным userType из токена
      await setRegistered(true, userType: userType);
      await setLoggedIn(true, userType: userType);
    } else {
      // Если токена нет, используем UserType.company по умолчанию
      await setRegistered(true, userType: UserType.company);
      await setLoggedIn(true, userType: UserType.company);
    }
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

  /// Универсальный метод входа, который определяет тип пользователя из токена
  static Future<UserType?> loginUniversal({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    
    // Проверяем тестовые аккаунты
    if (!kReleaseMode) {
      if (normalizedEmail == _testClientAdminEmail && password == _testClientAdminPassword) {
        await setLoggedIn(true, userType: UserType.client);
        return UserType.client;
      }
      if (normalizedEmail == _testCompanyAdminEmail && password == _testCompanyAdminPassword) {
        await setLoggedIn(true, userType: UserType.company);
        return UserType.company;
      }
    }

    // Пробуем войти через API (один запрос определяет тип пользователя)
    if (ApiConfig.isConfigured) {
      final remoteResult = await _remoteAuth.loginClient(
        email: normalizedEmail,
        password: password,
      );
      if (remoteResult != null && remoteResult.success) {
        final prefs = await SharedPreferences.getInstance();
        if (remoteResult.token != null && remoteResult.token!.isNotEmpty) {
          final token = remoteResult.token!;
          await prefs.setString(_authTokenKey, token);
          await AuthTokenStore.setToken(token);
          
          // Определяем userType из токена
          final payload = _decodeJwtPayload(token);
          UserType? userType;
          if (payload != null) {
            final userTypeStr = payload['user_type']?.toString();
            if (userTypeStr == 'Client') userType = UserType.client;
            else if (userTypeStr == 'Company') userType = UserType.company;
            else if (userTypeStr == 'Admin') userType = UserType.admin;
          }
          
          // Если тип не определен из токена, пробуем определить из локальных данных
          if (userType == null) {
            // Проверяем локальные данные клиента
            final clientRaw = prefs.getString(_clientCredentialsKey);
            if (clientRaw != null) {
              final clientData = jsonDecode(clientRaw) as Map<String, dynamic>;
              final savedEmail = (clientData['email'] as String? ?? '').toLowerCase();
              if (normalizedEmail == savedEmail) {
                userType = UserType.client;
              }
            }
            
            // Если не клиент, проверяем компанию
            if (userType == null) {
              final companyRaw = prefs.getString(_companyCredentialsKey);
              if (companyRaw != null) {
                final companyData = jsonDecode(companyRaw) as Map<String, dynamic>;
                final savedEmail = (companyData['email'] as String? ?? '').toLowerCase();
                if (normalizedEmail == savedEmail) {
                  userType = UserType.company;
                }
              }
            }
          }
          
          // Если тип все еще не определен, используем Client по умолчанию
          userType ??= UserType.client;
          await setLoggedIn(true, userType: userType);
          return userType;
        }
      }
    }

    // Fallback на локальные данные
    final prefs = await SharedPreferences.getInstance();
    
    // Проверяем клиента
    final clientRaw = prefs.getString(_clientCredentialsKey);
    if (clientRaw != null) {
      final clientData = jsonDecode(clientRaw) as Map<String, dynamic>;
      final savedEmail = (clientData['email'] as String? ?? '').toLowerCase();
      final savedPassword = clientData['password'] as String? ?? '';
      if (normalizedEmail == savedEmail && _verifyPassword(savedPassword, password)) {
        if (!savedPassword.startsWith('sha256:')) {
          clientData['password'] = _hashPassword(password);
          await prefs.setString(_clientCredentialsKey, jsonEncode(clientData));
        }
        await setLoggedIn(true, userType: UserType.client);
        return UserType.client;
      }
    }
    
    // Проверяем компанию
    final companyRaw = prefs.getString(_companyCredentialsKey);
    if (companyRaw != null) {
      final companyData = jsonDecode(companyRaw) as Map<String, dynamic>;
      final savedEmail = (companyData['email'] as String? ?? '').toLowerCase();
      final savedPassword = companyData['password'] as String? ?? '';
      if (normalizedEmail == savedEmail && _verifyPassword(savedPassword, password)) {
        if (!savedPassword.startsWith('sha256:')) {
          companyData['password'] = _hashPassword(password);
          await prefs.setString(_companyCredentialsKey, jsonEncode(companyData));
        }
        await setLoggedIn(true, userType: UserType.company);
        return UserType.company;
      }
    }
    
    return null;
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
          final token = remoteResult.token!;
          await prefs.setString(_authTokenKey, token);
          await AuthTokenStore.setToken(token);
          
          // Определяем userType из токена
          final payload = _decodeJwtPayload(token);
          UserType? userType = UserType.company; // По умолчанию компания
          if (payload != null) {
            final userTypeStr = payload['user_type']?.toString();
            if (userTypeStr == 'Client') userType = UserType.client;
            else if (userTypeStr == 'Admin') userType = UserType.admin;
          }
          await setLoggedIn(true, userType: userType);
        } else {
          await setLoggedIn(true, userType: UserType.company);
        }
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

  /// Получить ID текущего пользователя из JWT токена
  static Future<String?> getCurrentUserId() async {
    final token = await getAuthToken();
    if (token == null || token.isEmpty) return null;
    
    final payload = _decodeJwtPayload(token);
    if (payload == null) return null;
    
    // ID может быть в поле 'id' или 'user_id'
    final id = payload['id'] ?? payload['user_id'];
    return id?.toString();
  }

  // Выход из системы (очистить все данные)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isRegisteredKey);
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_userTypeKey);
    await prefs.remove(_authTokenKey);
    await prefs.remove(_adminCredentialsKey);
    await AuthTokenStore.clearToken();
  }

  /// Отправка кода для сброса пароля на email
  static Future<bool> resetPassword(String email) async {
    if (ApiConfig.isConfigured) {
      return await _remoteAuth.resetPassword(email);
    }
    return false;
  }

  /// Верификация кода для сброса пароля
  static Future<String?> verifyPasswordReset(String email, String code) async {
    if (ApiConfig.isConfigured) {
      return await _remoteAuth.verifyPasswordReset(email, code);
    }
    return null;
  }

  /// Отправка кода на телефон
  static Future<bool> loginByPhone(String phone) async {
    if (ApiConfig.isConfigured) {
      return await _remoteAuth.loginByPhone(phone);
    }
    return false;
  }

  /// Верификация кода и вход по телефону
  /// Возвращает информацию о пользователе: (success, isCompany, needsFillData)
  static Future<Map<String, dynamic>?> verifyCode({
    required String phone,
    required String code,
  }) async {
    if (!ApiConfig.isConfigured) {
      return {'success': false, 'isCompany': false, 'needsFillData': false};
    }

    final result = await _remoteAuth.verifyCode(phone: phone, code: code);
    
    if (result == null || !result.success || result.token == null) {
      return {'success': false, 'isCompany': false, 'needsFillData': false};
    }

    // Сохраняем токен
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, result.token!);
    await AuthTokenStore.setToken(result.token!);

    // Определяем тип пользователя из токена
    final payload = _decodeJwtPayload(result.token!);
    UserType? userType = UserType.client;
    bool isCompany = false;
    bool needsFillData = false;

    if (payload != null) {
      final userTypeStr = payload['user_type']?.toString();
      if (userTypeStr == 'Company') {
        userType = UserType.company;
        isCompany = true;
        // Проверяем, нужно ли заполнить данные компании
        final isDataFilled = payload['is_data_filled'] ?? false;
        needsFillData = !isDataFilled;
      } else if (userTypeStr == 'Admin') {
        userType = UserType.admin;
      }
    }

    await setLoggedIn(true, userType: userType);

    return {
      'success': true,
      'isCompany': isCompany,
      'needsFillData': needsFillData,
    };
  }

  /// Установка нового пароля после сброса
  static Future<bool> setNewPassword(String password, String resetToken) async {
    if (ApiConfig.isConfigured) {
      return await _remoteAuth.setNewPassword(password, resetToken);
    }
    return false;
  }

  /// Смена пароля для авторизованного пользователя
  static Future<bool> changePassword(String currentPassword, String newPassword) async {
    if (ApiConfig.isConfigured) {
      return await _remoteAuth.changePassword(currentPassword, newPassword);
    }
    return false;
  }
}
