import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile_model.dart';

class UserProfileService {
  static const String _profileKey = 'user_profile';

  // Сохранить профиль пользователя
  static Future<void> saveProfile(UserProfileModel profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  // Получить профиль пользователя
  static Future<UserProfileModel?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_profileKey);
    
    if (profileJson == null) return null;
    
    try {
      return UserProfileModel.fromJson(jsonDecode(profileJson));
    } catch (e) {
      return null;
    }
  }

  // Очистить профиль
  static Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
  }
}
