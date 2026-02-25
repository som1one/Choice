import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inquiry_model.dart';
import 'api_config.dart';
import 'auth_service.dart';
import 'remote_inquiry_service.dart';

class InquiryService {
  static const String _inquiriesKey = 'inquiries';
  static const String _currentInquiryKey = 'currentInquiry';
  static final RemoteInquiryService _remoteInquiry = RemoteInquiryService();

  // Сохранить запрос
  static Future<void> saveInquiry(InquiryModel inquiry) async {
    InquiryModel inquiryToStore = inquiry;
    final userType = await AuthService.getUserType();
    final canUseRemote = ApiConfig.isConfigured && userType != UserType.company;
    if (canUseRemote) {
      final remoteInquiry = await _remoteInquiry.createInquiry(inquiry);
      if (remoteInquiry != null) {
        inquiryToStore = remoteInquiry;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    
    // Сохранить текущий запрос
    await prefs.setString(_currentInquiryKey, jsonEncode(inquiryToStore.toJson()));
    
    // Сохранить в список всех запросов
    final inquiriesJson = prefs.getStringList(_inquiriesKey) ?? [];
    inquiriesJson.add(jsonEncode(inquiryToStore.toJson()));
    await prefs.setStringList(_inquiriesKey, inquiriesJson);
  }

  // Получить текущий запрос
  static Future<InquiryModel?> getCurrentInquiry() async {
    final prefs = await SharedPreferences.getInstance();
    final inquiryJson = prefs.getString(_currentInquiryKey);
    
    if (inquiryJson == null) return null;
    
    try {
      return InquiryModel.fromJson(jsonDecode(inquiryJson));
    } catch (e) {
      return null;
    }
  }

  // Обновить текущий запрос
  static Future<void> updateCurrentInquiry(InquiryModel inquiry) async {
    final userType = await AuthService.getUserType();
    final canUseRemote = ApiConfig.isConfigured && userType != UserType.company;
    if (canUseRemote) {
      await _remoteInquiry.updateInquiry(inquiry);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentInquiryKey, jsonEncode(inquiry.toJson()));
    
    // Обновить в списке
    final inquiriesJson = prefs.getStringList(_inquiriesKey) ?? [];
    final updatedList = inquiriesJson.map((json) {
      final inquiryData = jsonDecode(json);
      if (inquiryData['id'] == inquiry.id) {
        return jsonEncode(inquiry.toJson());
      }
      return json;
    }).toList();
    await prefs.setStringList(_inquiriesKey, updatedList);
  }

  // Получить все запросы
  static Future<List<InquiryModel>> getAllInquiries() async {
    final userType = await AuthService.getUserType();
    final canUseRemote = ApiConfig.isConfigured && userType != UserType.company;
    if (canUseRemote) {
      final remoteInquiries = await _remoteInquiry.getAllInquiries();
      if (remoteInquiries != null) {
        return remoteInquiries;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final inquiriesJson = prefs.getStringList(_inquiriesKey) ?? [];
    
    return inquiriesJson.map((json) {
      try {
        return InquiryModel.fromJson(jsonDecode(json));
      } catch (e) {
        return null;
      }
    }).whereType<InquiryModel>().toList();
  }

  // Удалить текущий запрос
  static Future<void> clearCurrentInquiry() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentInquiryKey);
  }
}
