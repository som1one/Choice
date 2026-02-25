class ApiConfig {
  // Включается через: flutter run --dart-define=USE_REMOTE_API=true
  static const bool useRemoteApi =
      bool.fromEnvironment('USE_REMOTE_API', defaultValue: true);

  // Хост бэка (IP/домен) через: --dart-define=API_HOST=77.95.203.148
  static const String host =
      String.fromEnvironment('API_HOST', defaultValue: '77.95.203.148');

  // Схема через: --dart-define=API_SCHEME=http|https
  static const String scheme =
      String.fromEnvironment('API_SCHEME', defaultValue: 'http');

  static String _serviceBaseUrl(int port) => '$scheme://$host:$port';

  // Микросервисы (порты соответствуют backend_fastapi/start_all.sh)
  static String get authBaseUrl => _serviceBaseUrl(8001);
  static String get clientBaseUrl => _serviceBaseUrl(8002);
  static String get companyBaseUrl => _serviceBaseUrl(8003);
  static String get categoryBaseUrl => _serviceBaseUrl(8004);
  static String get orderingBaseUrl => _serviceBaseUrl(8005);
  static String get chatBaseUrl => _serviceBaseUrl(8006);
  static String get reviewBaseUrl => _serviceBaseUrl(8007);
  static String get fileBaseUrl => _serviceBaseUrl(8008);

  static bool get isConfigured => useRemoteApi && host.trim().isNotEmpty;
}
