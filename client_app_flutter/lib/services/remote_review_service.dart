import 'api_client.dart';
import 'api_config.dart';
import 'api_exception.dart';
import 'remote_ordering_service.dart';
import 'auth_service.dart';

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

  /// Проверить возможность оставить отзыв
  /// guid - это GUID компании (для клиентов) или клиента (для компаний)
  Future<bool> canSendReview(String guid) async {
    if (!ApiConfig.isConfigured) return false;
    
    try {
      final userType = await AuthService.getUserType();
      final currentUserId = await AuthService.getCurrentUserId();
      
      if (currentUserId == null) return false;
      
      final orderingService = RemoteOrderingService();
      
      // Для клиентов: проверяем возможность оставить отзыв компании
      if (userType == UserType.client) {
        return await orderingService.canAddReview(
          clientId: currentUserId,
          companyId: guid,
          reviewerId: currentUserId,
          reserve: false,
        );
      }
      // Для компаний: проверяем возможность оставить отзыв клиенту
      else if (userType == UserType.company) {
        return await orderingService.canAddReview(
          clientId: guid,
          companyId: currentUserId,
          reviewerId: currentUserId,
          reserve: false,
        );
      }
      
      return false;
    } catch (e) {
      // Если проверка не удалась, возвращаем false (безопаснее)
      return false;
    }
  }

  /// Отправить отзыв
  /// Перед отправкой проверяет возможность оставить отзыв
  /// 
  /// [throwOnError] - если true, выбрасывает ApiException при ошибке
  /// Если false (по умолчанию), возвращает null при ошибке
  Future<Map<String, dynamic>?> sendReview({
    required String guid,
    required int grade,
    String? text,
    List<String>? photoUris,
    bool throwOnError = false,
  }) async {
    // Проверяем возможность оставить отзыв
    final canReview = await canSendReview(guid);
    if (!canReview) {
      if (throwOnError) {
        throw ApiException(
          statusCode: 400,
          message: 'Cannot leave review',
          detail: 'Невозможно оставить отзыв: нет завершенного заказа или отзыв уже оставлен',
        );
      }
      // Возвращаем ошибку в формате, похожем на ответ API
      return {
        'error': 'Cannot leave review: no finished order found or review already added',
        'success': false,
      };
    }
    
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
      throwOnError: throwOnError,
    );
    return json;
  }
}
