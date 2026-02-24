class ApiConfig {
  // Включается через: flutter run --dart-define=USE_REMOTE_API=true
  static const bool useRemoteApi =
      bool.fromEnvironment('USE_REMOTE_API', defaultValue: false);

  // Базовый URL через: --dart-define=API_BASE_URL=https://api.example.com
  static const String baseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static bool get isConfigured => useRemoteApi && baseUrl.trim().isNotEmpty;
}
