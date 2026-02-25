import '../models/inquiry_model.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'user_profile_service.dart';
import '../constants/categories.dart';

class RemoteInquiryService {
  Future<InquiryModel?> createInquiry(InquiryModel inquiry) async {
    final profile = await UserProfileService.getProfile();
    final radius = profile?.searchRadiusKm ?? 20;

    final body = <String, dynamic>{
      'category_id': categoryTitleToId(inquiry.category),
      'description': inquiry.question,
      'search_radius': radius,
      'to_know_price': inquiry.wantsPrice,
      // closest mapping from UI checkboxes to backend flags
      'to_know_deadline': inquiry.wantsTime,
      'to_know_enrollment_date': inquiry.wantsAppointmentTime,
      'photo_uris': inquiry.attachmentUrl == null ? <String>[] : <String>[inquiry.attachmentUrl!],
    };

    final json = await ApiClient.postJson(
      '/api/client/sendOrderRequest',
      body,
      baseUrl: ApiConfig.clientBaseUrl,
    );
    if (json == null) return null;

    // Бэк возвращает OrderRequestResponse без createdAt — заполним "сейчас"
    final id = (json['id'] ?? json['data']?['id'])?.toString();
    if (id == null || id.isEmpty) return inquiry;

    return inquiry.copyWith(id: id, createdAt: DateTime.now());
  }

  Future<bool?> updateInquiry(InquiryModel inquiry) async {
    // В текущей модели приложения обновление заявки в бэке не используется.
    // (на бэке это /api/client/changeOrderRequest).
    return null;
  }

  Future<List<InquiryModel>?> getAllInquiries() async {
    final json = await ApiClient.getJson(
      '/api/client/getClientRequests',
      baseUrl: ApiConfig.clientBaseUrl,
    );
    if (json == null) return null;
    try {
      final raw = json is List ? json : (json['data'] ?? json['items'] ?? json['requests']);
      if (raw is! List) return <InquiryModel>[];

      final mapped = <InquiryModel>[];
      for (final item in raw) {
        if (item is! Map<String, dynamic>) continue;
        final id = (item['id'])?.toString() ?? '';
        final categoryId = (item['category_id'] as num?)?.toInt() ?? (item['categoryId'] as num?)?.toInt() ?? 1;
        final desc = (item['description'] as String?) ?? '';
        final toKnowPrice = (item['to_know_price']?.toString() ?? 'false') == 'true';
        final toKnowDeadline = (item['to_know_deadline']?.toString() ?? 'false') == 'true';
        final toKnowEnroll = (item['to_know_enrollment_date']?.toString() ?? 'false') == 'true';

        mapped.add(
          InquiryModel(
            id: id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : id,
            question: desc,
            category: categoryIdToTitle(categoryId),
            clientName: '',
            createdAt: DateTime.now(),
            wantsPrice: toKnowPrice,
            wantsTime: toKnowDeadline,
            wantsAppointmentTime: toKnowEnroll,
          ),
        );
      }

      return mapped;
    } catch (_) {
      return null;
    }
  }
}
