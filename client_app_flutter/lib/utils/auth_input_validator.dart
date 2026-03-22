class AuthInputValidator {
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static bool isValidEmail(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return false;
    return _emailPattern.hasMatch(normalized);
  }
}
