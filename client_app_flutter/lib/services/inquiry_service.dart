import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inquiry_model.dart';
import 'api_config.dart';
import 'auth_service.dart';
import 'remote_inquiry_service.dart';
import 'remote_client_service.dart';
import 'remote_ordering_service.dart';
import '../constants/categories.dart';

class InquiryService {
  static const String _inquiriesKey = 'inquiries';
  static const String _currentInquiryKey = 'currentInquiry';
  static final RemoteInquiryService _remoteInquiry = RemoteInquiryService();
  static final RemoteClientService _remoteClient = RemoteClientService();
  static final RemoteOrderingService _remoteOrdering = RemoteOrderingService();

  // Сохранить запрос
  static Future<void> saveInquiry(InquiryModel inquiry) async {
    InquiryModel inquiryToStore = inquiry;
    final userType = await AuthService.getUserType();
    // Заявки создают только клиенты, поэтому отправляем на сервер если API настроен
    final canUseRemote = ApiConfig.isConfigured && userType == UserType.client;
    if (canUseRemote) {
      final remoteInquiry = await _remoteInquiry.createInquiry(inquiry);
      if (remoteInquiry != null) {
        inquiryToStore = remoteInquiry;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    
    // Сохранить текущий запрос
    await prefs.setString(_currentInquiryKey, jsonEncode(inquiryToStore.toJson()));
    
    // Сохранить в список всех запросов (только для клиентов)
    if (userType == UserType.client) {
      final inquiriesJson = prefs.getStringList(_inquiriesKey) ?? [];
      inquiriesJson.add(jsonEncode(inquiryToStore.toJson()));
      await prefs.setStringList(_inquiriesKey, inquiriesJson);
    }
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
    final prefs = await SharedPreferences.getInstance();
    
    // Для компаний отправляем ответ на сервер через RemoteOrderingService
    if (ApiConfig.isConfigured && userType == UserType.company) {
      final orderRequestId = int.tryParse(inquiry.id);
      if (orderRequestId != null) {
        // Получаем заявку с сервера, чтобы узнать client_id
        final orderRequest = await _remoteClient.getOrderRequest(orderRequestId);
        if (orderRequest != null) {
          final clientId = (orderRequest['client_id'] ?? orderRequest['clientId'])?.toString();
          if (clientId != null) {
            // Парсим дату записи, если указана
            DateTime? enrollmentDate;
            if (inquiry.appointmentDate != null && inquiry.appointmentTime != null) {
              try {
                final dateParts = inquiry.appointmentDate!.split('.');
                final timeParts = inquiry.appointmentTime!.split(':');
                if (dateParts.length == 3 && timeParts.length == 2) {
                  enrollmentDate = DateTime(
                    int.parse(dateParts[2]),
                    int.parse(dateParts[1]),
                    int.parse(dateParts[0]),
                    int.parse(timeParts[0]),
                    int.parse(timeParts[1]),
                  );
                }
              } catch (_) {
                // Если не удалось распарсить дату, оставляем null
              }
            }
            
            // Парсим цену, срок и предоплату
            int? price;
            int? deadline;
            int? prepayment;
            
            if (inquiry.price != null && inquiry.price!.isNotEmpty) {
              price = int.tryParse(inquiry.price!.replaceAll(RegExp(r'[^\d]'), ''));
            }
            if (inquiry.time != null && inquiry.time!.isNotEmpty) {
              deadline = int.tryParse(inquiry.time!.replaceAll(RegExp(r'[^\d]'), ''));
            }
            
            // Отправляем заказ на сервер
            await _remoteOrdering.createOrder(
              receiverId: clientId,
              orderRequestId: orderRequestId,
              price: price,
              deadline: deadline,
              enrollmentDate: enrollmentDate,
              prepayment: prepayment,
            );
          }
        }
      }
    } else if (ApiConfig.isConfigured && userType == UserType.client) {
      // Для клиентов обновляем заявку на сервере (если нужно)
      await _remoteInquiry.updateInquiry(inquiry);
    }

    // Сохраняем локально
    await prefs.setString(_currentInquiryKey, jsonEncode(inquiry.toJson()));
    
    // Обновить в списке (только для клиентов)
    if (userType == UserType.client) {
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
  }

  // Получить все запросы
  static Future<List<InquiryModel>> getAllInquiries() async {
    final userType = await AuthService.getUserType();
    
    // Для компаний получаем заявки с сервера
    if (ApiConfig.isConfigured && userType == UserType.company) {
      final orderRequests = await _remoteClient.getOrderRequests();
      if (orderRequests != null && orderRequests.isNotEmpty) {
        return orderRequests.map((request) {
          final id = (request['id'] ?? request['orderRequestId'])?.toString() ?? '';
          final categoryId = (request['category_id'] ?? request['categoryId'] as num?)?.toInt() ?? 1;
          final description = (request['description'] as String?) ?? '';
          final clientId = (request['client_id'] ?? request['clientId'])?.toString() ?? '';
          final toKnowPrice = (request['to_know_price']?.toString() ?? 'false') == 'true';
          final toKnowDeadline = (request['to_know_deadline']?.toString() ?? 'false') == 'true';
          final toKnowEnroll = (request['to_know_enrollment_date']?.toString() ?? 'false') == 'true';
          
          // Получаем имя клиента из вложенного объекта или используем ID
          String clientName = clientId;
          if (request['client'] is Map<String, dynamic>) {
            final client = request['client'] as Map<String, dynamic>;
            clientName = (client['name'] as String?) ?? clientId;
          }
          
          return InquiryModel(
            id: id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : id,
            question: description,
            category: categoryIdToTitle(categoryId),
            clientName: clientName,
            createdAt: DateTime.now(), // TODO: получить из API если доступно
            wantsPrice: toKnowPrice,
            wantsTime: toKnowDeadline,
            wantsAppointmentTime: toKnowEnroll,
          );
        }).toList();
      }
      return [];
    }
    
    // Для клиентов получаем заявки с сервера или из локального хранилища
    if (ApiConfig.isConfigured && userType == UserType.client) {
      final remoteInquiries = await _remoteInquiry.getAllInquiries();
      if (remoteInquiries != null) {
        return remoteInquiries;
      }
    }

    // Fallback на локальное хранилище
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
