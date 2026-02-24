import '../models/inquiry_model.dart';
import 'api_client.dart';

class RemoteInquiryService {
  Future<InquiryModel?> createInquiry(InquiryModel inquiry) async {
    final json = await ApiClient.postJson('/inquiries', inquiry.toJson());
    if (json == null) return null;
    try {
      return InquiryModel.fromJson(json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : json);
    } catch (_) {
      return inquiry;
    }
  }

  Future<bool?> updateInquiry(InquiryModel inquiry) async {
    final json = await ApiClient.putJson('/inquiries/${inquiry.id}', inquiry.toJson());
    if (json == null) return null;
    return (json['success'] as bool?) ?? true;
  }

  Future<List<InquiryModel>?> getAllInquiries() async {
    final json = await ApiClient.getJson('/inquiries');
    if (json == null) return null;
    try {
      final raw = json['data'] ?? json['items'] ?? json['inquiries'];
      if (raw is! List) return <InquiryModel>[];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(InquiryModel.fromJson)
          .toList();
    } catch (_) {
      return null;
    }
  }
}
