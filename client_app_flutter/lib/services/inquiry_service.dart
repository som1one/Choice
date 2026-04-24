import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inquiry_model.dart';
import 'api_config.dart';
import 'auth_service.dart';
import 'remote_inquiry_service.dart';
import 'remote_client_service.dart';
import 'remote_ordering_service.dart';
import 'remote_company_service.dart';
import '../constants/categories.dart';

class InquiryService {
  static const String _inquiriesKey = 'inquiries';
  static const String _currentInquiryKey = 'currentInquiry';
  static const String _localIdPrefix = 'local_';
  static final RemoteInquiryService _remoteInquiry = RemoteInquiryService();
  static final RemoteClientService _remoteClient = RemoteClientService();
  static final RemoteOrderingService _remoteOrdering = RemoteOrderingService();
  static final RemoteCompanyService _remoteCompany = RemoteCompanyService();

  static bool _isLikelyLegacyLocalId(String id) {
    final parsed = int.tryParse(id);
    if (parsed == null) return false;

    // Исторически локальные заявки создавались через millisecondsSinceEpoch.
    // Серверные ID у нас небольшие int, а timestamp выглядит как 13+ цифр.
    return parsed >= 1000000000000;
  }

  static bool _isRemoteId(String id) =>
      id.isNotEmpty &&
      !id.startsWith(_localIdPrefix) &&
      !_isLikelyLegacyLocalId(id) &&
      int.tryParse(id) != null;

  static String createLocalInquiryId() =>
      '$_localIdPrefix${DateTime.now().millisecondsSinceEpoch}';

  static Future<String> _inquiriesStorageKey() async {
    final userId = await AuthService.getCurrentUserId();
    return userId == null || userId.isEmpty
        ? _inquiriesKey
        : '${_inquiriesKey}_$userId';
  }

  static Future<String> _currentInquiryStorageKey() async {
    final userId = await AuthService.getCurrentUserId();
    return userId == null || userId.isEmpty
        ? _currentInquiryKey
        : '${_currentInquiryKey}_$userId';
  }

  static Future<void> _persistLocalInquiries(List<InquiryModel> inquiries) async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = await _inquiriesStorageKey();
    final encoded = inquiries.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(storageKey, encoded);
  }

  static List<InquiryModel> _mergeClientInquiries(
    List<InquiryModel> remote,
    List<InquiryModel> local,
  ) {
    final byId = <String, InquiryModel>{};

    for (final item in remote) {
      byId[item.id] = item;
    }

    for (final item in local) {
      if (!byId.containsKey(item.id)) {
        byId[item.id] = item;
      }
    }

    final merged = byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }

  static Future<List<InquiryModel>> _readLocalInquiries() async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = await _inquiriesStorageKey();
    final scopedInquiriesJson = prefs.getStringList(storageKey);
    final inquiriesJson = scopedInquiriesJson ?? prefs.getStringList(_inquiriesKey) ?? [];

    return inquiriesJson
        .map((json) {
          try {
            return InquiryModel.fromJson(jsonDecode(json));
          } catch (e) {
            return null;
          }
        })
        .whereType<InquiryModel>()
        .toList();
  }

  static Future<List<InquiryModel>> _syncPendingLocalInquiries(
    List<InquiryModel> localInquiries,
  ) async {
    var changed = false;
    final synced = <InquiryModel>[];

    for (final inquiry in localInquiries) {
      if (_isRemoteId(inquiry.id)) {
        synced.add(inquiry);
        continue;
      }

      try {
        final remoteInquiry = await _remoteInquiry.createInquiry(inquiry);
        if (remoteInquiry != null && _isRemoteId(remoteInquiry.id)) {
          synced.add(remoteInquiry);
          changed = true;
          continue;
        }
      } catch (_) {
        // Оставляем локальную заявку как pending и повторим позже.
      }

      synced.add(inquiry);
    }

    if (changed) {
      await _persistLocalInquiries(synced);
    }

    return synced;
  }

  static String? _extractFirstPhotoUri(dynamic rawPhotoUris) {
    if (rawPhotoUris == null) return null;

    if (rawPhotoUris is List) {
      for (final item in rawPhotoUris) {
        final value = item.toString().trim();
        if (value.isNotEmpty) {
          return value;
        }
      }
      return null;
    }

    final rawString = rawPhotoUris.toString().trim();
    if (rawString.isEmpty) return null;

    if (rawString.startsWith('[') && rawString.endsWith(']')) {
      final values = rawString
          .substring(1, rawString.length - 1)
          .split(',')
          .map((item) => item.replaceAll('"', '').trim())
          .where((item) => item.isNotEmpty);
      if (values.isNotEmpty) {
        return values.first;
      }
    }

    return rawString;
  }

  // Сохранить запрос
  static Future<void> saveInquiry(InquiryModel inquiry) async {
    InquiryModel inquiryToStore = inquiry;
    final userType = await AuthService.getUserType();
    // Заявки создают только клиенты, поэтому отправляем на сервер если API настроен
    final canUseRemote = ApiConfig.isConfigured && userType == UserType.client;
    if (canUseRemote) {
      try {
        final remoteInquiry = await _remoteInquiry.createInquiry(inquiry);
        if (remoteInquiry != null) {
          inquiryToStore = remoteInquiry;
        }
      } catch (_) {
        // Если сервер временно недоступен, сохраняем локально и повторим синхронизацию позже.
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final currentInquiryStorageKey = await _currentInquiryStorageKey();

    // Сохранить текущий запрос
    await prefs.setString(
      currentInquiryStorageKey,
      jsonEncode(inquiryToStore.toJson()),
    );

    // Сохранить в список всех запросов (только для клиентов)
    if (userType == UserType.client) {
      final existing = await _readLocalInquiries();
      final updated = [
        inquiryToStore,
        ...existing.where((item) => item.id != inquiryToStore.id),
      ];
      await _persistLocalInquiries(updated);
    }
  }

  // Получить текущий запрос
  static Future<InquiryModel?> getCurrentInquiry() async {
    final prefs = await SharedPreferences.getInstance();
    final currentInquiryStorageKey = await _currentInquiryStorageKey();
    final inquiryJson =
        prefs.getString(currentInquiryStorageKey) ?? prefs.getString(_currentInquiryKey);

    if (inquiryJson == null) return null;

    try {
      return InquiryModel.fromJson(jsonDecode(inquiryJson));
    } catch (e) {
      return null;
    }
  }

  // Установить текущий запрос без побочных действий (без отправки на сервер)
  static Future<void> setCurrentInquiry(InquiryModel inquiry) async {
    final userType = await AuthService.getUserType();
    final prefs = await SharedPreferences.getInstance();
    final currentInquiryStorageKey = await _currentInquiryStorageKey();

    await prefs.setString(currentInquiryStorageKey, jsonEncode(inquiry.toJson()));

    // Обновить в списке (только для клиентов)
    if (userType == UserType.client) {
      final inquiriesStorageKey = await _inquiriesStorageKey();
      final inquiriesJson =
          prefs.getStringList(inquiriesStorageKey) ?? prefs.getStringList(_inquiriesKey) ?? [];
      final updatedList = inquiriesJson.map((json) {
        final inquiryData = jsonDecode(json);
        if (inquiryData['id'] == inquiry.id) {
          return jsonEncode(inquiry.toJson());
        }
        return json;
      }).toList();
      await prefs.setStringList(inquiriesStorageKey, updatedList);
    }
  }

  // Обновить текущий запрос
  static Future<void> updateCurrentInquiry(InquiryModel inquiry) async {
    final userType = await AuthService.getUserType();

    // Для компаний отправляем ответ на сервер через RemoteOrderingService
    if (ApiConfig.isConfigured && userType == UserType.company) {
      final orderRequestId = int.tryParse(inquiry.id);
      if (orderRequestId == null) {
        throw StateError('Неверный идентификатор заявки');
      }

      // Получаем заявку с сервера, чтобы узнать корректный client GUID
      final orderRequest = await _remoteClient.getOrderRequest(orderRequestId);
      if (orderRequest == null) {
        throw StateError('Не удалось получить заявку клиента');
      }

      final clientId =
          (orderRequest['client_guid'] ??
                  orderRequest['clientGuid'] ??
                  orderRequest['client_id'] ??
                  orderRequest['clientId'])
              ?.toString();
      if (clientId == null || clientId.isEmpty) {
        throw StateError('Не удалось определить получателя отклика');
      }

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
      final responseText = inquiry.companyResponse?.trim();
      final specialistName = inquiry.specialistName?.trim();
      final specialistPhone = inquiry.specialistPhone?.trim();

      if (inquiry.price != null && inquiry.price!.isNotEmpty) {
        price = int.tryParse(inquiry.price!.replaceAll(RegExp(r'[^\d]'), ''));
      }
      if (inquiry.time != null && inquiry.time!.isNotEmpty) {
        deadline = int.tryParse(inquiry.time!.replaceAll(RegExp(r'[^\d]'), ''));
      }
      if (inquiry.prepayment != null && inquiry.prepayment!.isNotEmpty) {
        prepayment = int.tryParse(
          inquiry.prepayment!.replaceAll(RegExp(r'[^\d]'), ''),
        );
      }

      // Отправляем заказ на сервер
      final createdOrder = await _remoteOrdering.createOrder(
        receiverId: clientId,
        orderRequestId: orderRequestId,
        price: price,
        deadline: deadline,
        enrollmentDate: enrollmentDate,
        prepayment: prepayment,
        responseText: responseText != null && responseText.isNotEmpty
            ? responseText
            : null,
        specialistName: specialistName != null && specialistName.isNotEmpty
            ? specialistName
            : null,
        specialistPhone: specialistPhone != null && specialistPhone.isNotEmpty
            ? specialistPhone
            : null,
        throwOnError: true,
      );
      if (createdOrder == null) {
        throw StateError('Сервер не подтвердил создание отклика');
      }
    } else if (ApiConfig.isConfigured && userType == UserType.client) {
      // Для клиентов обновляем заявку на сервере (если нужно)
      await _remoteInquiry.updateInquiry(inquiry);
    }

    await setCurrentInquiry(inquiry);
  }

  // Получить все запросы
  static Future<List<InquiryModel>> getAllInquiries() async {
    final userType = await AuthService.getUserType();

    // Для компаний получаем заявки с сервера через новый endpoint
    if (ApiConfig.isConfigured && userType == UserType.company) {
      // Категории и радиус должна определять серверная сторона по профилю компании.
      final orderRequests = await _remoteCompany.getOrderRequests();

      if (orderRequests != null && orderRequests.isNotEmpty) {
        return orderRequests.map((request) {
          final id =
              (request['id'] ?? request['orderRequestId'])?.toString() ?? '';
          final categoryId =
              (request['category_id'] ?? request['categoryId'] as num?)
                  ?.toInt() ??
              1;
          final description = (request['description'] as String?) ?? '';
          final clientId =
              (request['client_guid'] ??
                      request['clientGuid'] ??
                      request['client_id'] ??
                      request['clientId'])
                  ?.toString() ??
              '';
          final toKnowPrice =
              (request['to_know_price']?.toString() ?? 'false') == 'true';
          final toKnowDeadline =
              (request['to_know_deadline']?.toString() ?? 'false') == 'true';
          final toKnowSpecialist =
              (request['to_know_specialist']?.toString() ?? 'false') == 'true';
          final toKnowEnroll =
              (request['to_know_enrollment_date']?.toString() ?? 'false') ==
              'true';
          final createdAtRaw =
              request['creation_date'] ?? request['creationDate'];
          final createdAt = createdAtRaw != null
              ? DateTime.tryParse(createdAtRaw.toString())
              : null;

          // Получаем имя клиента из вложенного объекта или используем ID
          String clientName =
              (request['client_name'] ?? request['clientName'])?.toString() ??
              clientId;
          if (request['client'] is Map<String, dynamic>) {
            final client = request['client'] as Map<String, dynamic>;
            final name = client['name']?.toString().trim() ?? '';
            final surname = client['surname']?.toString().trim() ?? '';
            final fullName = '$name $surname'.trim();
            clientName = fullName.isNotEmpty ? fullName : clientId;
          }

          return InquiryModel(
            id: id.isEmpty
                ? DateTime.now().millisecondsSinceEpoch.toString()
                : id,
            question: description,
            category: categoryIdToTitle(categoryId),
            clientName: clientName,
            createdAt: createdAt ?? DateTime.now(),
            wantsPrice: toKnowPrice,
            wantsTime: toKnowDeadline,
            wantsSpecialist: toKnowSpecialist,
            wantsAppointmentTime: toKnowEnroll,
            attachmentUrl: _extractFirstPhotoUri(
              request['photo_uris'] ?? request['photoUris'],
            ),
          );
        }).toList();
      }
      return [];
    }

    // Для клиентов получаем заявки с сервера или из локального хранилища
    final localInquiries = await _readLocalInquiries();

    if (ApiConfig.isConfigured && userType == UserType.client) {
      final syncedLocalInquiries = await _syncPendingLocalInquiries(localInquiries);
      final remoteInquiries = await _remoteInquiry.getAllInquiries();
      if (remoteInquiries != null) {
        final merged = _mergeClientInquiries(remoteInquiries, syncedLocalInquiries);
        await _persistLocalInquiries(merged);
        return merged;
      }

      return syncedLocalInquiries;
    }

    // Fallback на локальное хранилище
    return localInquiries;
  }

  // Удалить текущий запрос
  static Future<void> clearCurrentInquiry() async {
    final prefs = await SharedPreferences.getInstance();
    final currentInquiryStorageKey = await _currentInquiryStorageKey();
    await prefs.remove(currentInquiryStorageKey);
  }
}
