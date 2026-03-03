import 'api_client.dart';
import 'api_config.dart';

class RemoteOrderingService {
  /// Создать заказ (ответ компании на заявку)
  Future<Map<String, dynamic>?> createOrder({
    required String receiverId,
    required int orderRequestId,
    int? price,
    int? deadline,
    DateTime? enrollmentDate,
    int? prepayment,
  }) async {
    final body = <String, dynamic>{
      'receiver_id': receiverId,
      'order_request_id': orderRequestId,
      if (price != null) 'price': price,
      if (deadline != null) 'deadline': deadline,
      if (enrollmentDate != null) 'enrollment_date': enrollmentDate.toIso8601String(),
      if (prepayment != null) 'prepayment': prepayment,
    };

    final json = await ApiClient.postJson(
      '/api/order/create',
      body,
      baseUrl: ApiConfig.orderingBaseUrl,
    );
    return json;
  }

  /// Изменить дату записи в заказе
  Future<Map<String, dynamic>?> changeOrderEnrollmentDate({
    required int orderId,
    required DateTime newDate,
  }) async {
    final body = <String, dynamic>{
      'order_id': orderId,
      'enrollment_date': newDate.toIso8601String(),
    };
    final json = await ApiClient.putJson(
      '/api/order/changeOrderEnrollmentDate',
      body,
      baseUrl: ApiConfig.orderingBaseUrl,
    );
    return json;
  }

  /// Подтвердить дату записи (клиент подтверждает предложенную компанией дату)
  Future<Map<String, dynamic>?> confirmEnrollmentDate(int orderId) async {
    final json = await ApiClient.putJson(
      '/api/order/confirmEnrollmentDate?order_id=$orderId',
      <String, dynamic>{},
      baseUrl: ApiConfig.orderingBaseUrl,
    );
    return json;
  }

  /// Записаться (клиент записывается на услугу)
  Future<Map<String, dynamic>?> enroll(int orderId) async {
    final json = await ApiClient.putJson(
      '/api/order/enroll?order_id=$orderId',
      <String, dynamic>{},
      baseUrl: ApiConfig.orderingBaseUrl,
    );
    return json;
  }

  /// Получить все заказы текущего пользователя
  /// Если указан orderRequestId, возвращает заказы по заявке (ответы компаний)
  Future<List<Map<String, dynamic>>?> getOrders({int? orderRequestId}) async {
    final url = orderRequestId != null
        ? '/api/order/get?order_request_id=$orderRequestId'
        : '/api/order/get';
    
    final json = await ApiClient.getJson(
      url,
      baseUrl: ApiConfig.orderingBaseUrl,
    );
    if (json == null) return null;
    if (json is List) {
      return (json as List).map((e) => e as Map<String, dynamic>).toList();
    }
    if (json is Map<String, dynamic>) {
      final orders = json['orders'] ?? json['data'];
      if (orders is List) {
        return (orders as List).map((e) => e as Map<String, dynamic>).toList();
      }
    }
    return [];
  }

  /// Завершить заказ
  Future<Map<String, dynamic>?> finish(int orderId) async {
    final json = await ApiClient.putJson(
      '/api/order/finishOrder?order_id=$orderId',
      <String, dynamic>{},
      baseUrl: ApiConfig.orderingBaseUrl,
    );
    return json;
  }

  /// Отменить запись (отмена enrollment)
  Future<Map<String, dynamic>?> cancel(int orderId) async {
    final json = await ApiClient.putJson(
      '/api/order/cancelEnrollment?order_id=$orderId',
      <String, dynamic>{},
      baseUrl: ApiConfig.orderingBaseUrl,
    );
    return json;
  }
}
