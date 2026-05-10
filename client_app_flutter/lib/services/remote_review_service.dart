import 'api_client.dart';
import 'api_config.dart';
import 'api_exception.dart';
import 'auth_service.dart';
import 'remote_ordering_service.dart';

class RemoteReviewService {
  List<Map<String, dynamic>> _readMapList(Object? value) {
    if (value is! List) {
      return [];
    }
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<Map<String, dynamic>>?> getReviews(String guid) async {
    final Object? json = await ApiClient.getJson(
      '/api/review/get?guid=$guid',
      baseUrl: ApiConfig.reviewBaseUrl,
    );
    if (json == null) return null;
    if (json is List) {
      return _readMapList(json);
    }
    if (json is Map<String, dynamic>) {
      final reviews = json['reviews'] ?? json['data'];
      return _readMapList(reviews);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>?> getClientReviews(String clientGuid) async {
    final Object? json = await ApiClient.getJson(
      '/api/review/getClientReviews?client_guid=$clientGuid',
      baseUrl: ApiConfig.reviewBaseUrl,
    );
    if (json == null) return null;
    if (json is List) {
      return _readMapList(json);
    }
    if (json is Map<String, dynamic>) {
      final reviews = json['reviews'] ?? json['data'];
      return _readMapList(reviews);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getReviewPhrases({
    int? grade,
    bool activeOnly = true,
  }) async {
    final query = <String>[
      if (grade != null) 'grade=$grade',
      'is_active=$activeOnly',
    ].join('&');
    final Object? json = await ApiClient.getJson(
      '/api/rating-criteria/${query.isEmpty ? '' : '?$query'}',
      baseUrl: ApiConfig.companyBaseUrl,
    );
    if (json == null) return [];
    if (json is List) {
      return _readMapList(json);
    }
    if (json is Map<String, dynamic>) {
      final data = json['data'];
      return _readMapList(data);
    }
    return [];
  }

  Future<bool> canSendReview(String guid) async {
    if (!ApiConfig.isConfigured) return false;

    try {
      final userType = await AuthService.getUserType();
      final currentUserId = await AuthService.getCurrentUserId();
      if (currentUserId == null) return false;

      final orderingService = RemoteOrderingService();
      if (userType == UserType.client) {
        return await orderingService.canAddReview(
          clientId: currentUserId,
          companyId: guid,
          reviewerId: currentUserId,
          reserve: false,
        );
      }
      if (userType == UserType.company) {
        return await orderingService.canAddReview(
          clientId: guid,
          companyId: currentUserId,
          reviewerId: currentUserId,
          reserve: false,
        );
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasOwnReview(String guid) async {
    try {
      final currentUserId = await AuthService.getCurrentUserId();
      final userType = await AuthService.getUserType();
      if (currentUserId == null || userType == null) {
        return false;
      }

      final reviews = userType == UserType.company
          ? await getClientReviews(guid)
          : await getReviews(guid);
      if (reviews == null) {
        return false;
      }

      for (final review in reviews) {
        final senderId = (review['sender_id'] ?? review['senderId'])
            ?.toString()
            .trim();
        if (senderId == currentUserId) {
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> sendReview({
    required String guid,
    required int grade,
    int? criterionId,
    String? text,
    List<String>? photoUris,
    bool throwOnError = false,
  }) async {
    final canReview = await canSendReview(guid);
    if (!canReview) {
      if (throwOnError) {
        throw ApiException(
          statusCode: 400,
          message: 'Cannot leave review',
          detail:
              'Невозможно оставить отзыв: нет завершенного заказа или отзыв уже оставлен',
        );
      }
      return {
        'error':
            'Cannot leave review: no finished order found or review already added',
        'success': false,
      };
    }

    final body = <String, dynamic>{
      'guid': guid,
      'grade': grade,
      if (criterionId != null) 'criterion_id': criterionId,
      if (text != null) 'text': text,
      if (photoUris != null) 'photo_uris': photoUris,
    };

    return ApiClient.postJson(
      '/api/review/send',
      body,
      baseUrl: ApiConfig.reviewBaseUrl,
      throwOnError: throwOnError,
    );
  }
}
