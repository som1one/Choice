import 'api_client.dart';
import 'api_config.dart';

class RemoteReviewService {
  /// Получить отзывы пользователя
  Future<List<Map<String, dynamic>>?> getReviews(String guid) async {
    final json = await ApiClient.getJson(
      '/api/review/get?guid=$guid',
      baseUrl: ApiConfig.reviewBaseUrl,
    );
    if (json == null) return null;
    if (json is List) {
      return (json as List).map((e) => e as Map<String, dynamic>).toList();
    }
    if (json is Map<String, dynamic>) {
      final reviews = json['reviews'] ?? json['data'];
      if (reviews is List) {
        return (reviews as List).map((e) => e as Map<String, dynamic>).toList();
      }
    }
    return [];
  }

  /// Получить отзывы о клиенте от компаний (для компаний)
  Future<List<Map<String, dynamic>>?> getClientReviews(String clientGuid) async {
    final json = await ApiClient.getJson(
      '/api/review/getClientReviews?client_guid=$clientGuid',
      baseUrl: ApiConfig.reviewBaseUrl,
    );
    if (json == null) return null;
    if (json is List) {
      return (json as List).map((e) => e as Map<String, dynamic>).toList();
    }
    if (json is Map<String, dynamic>) {
      final reviews = json['reviews'] ?? json['data'];
      if (reviews is List) {
        return (reviews as List).map((e) => e as Map<String, dynamic>).toList();
      }
    }
    return [];
  }

  /// Отправить отзыв
  Future<Map<String, dynamic>?> sendReview({
    required String guid,
    required int grade,
    String? text,
    List<String>? photoUris,
  }) async {
    final body = <String, dynamic>{
      'guid': guid,
      'grade': grade,
      if (text != null) 'text': text,
      if (photoUris != null) 'photo_uris': photoUris,
    };

    final json = await ApiClient.postJson(
      '/api/review/send',
      body,
      baseUrl: ApiConfig.reviewBaseUrl,
    );
    return json;
  }
}
