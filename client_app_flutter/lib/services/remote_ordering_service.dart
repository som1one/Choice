import 'api_client.dart';
import 'api_config.dart';

class RemoteOrderingService {
  int? _extractOrderId(Map<String, dynamic> order) {
    final rawId = order['id'] ?? order['orderId'];
    if (rawId is num) return rawId.toInt();
    return int.tryParse(rawId?.toString() ?? '');
  }

  /// Create an order response from a company for a client inquiry.
  Future<Map<String, dynamic>?> createOrder({
    required String receiverId,
    required int orderRequestId,
    int? price,
    int? deadline,
    DateTime? enrollmentDate,
    int? prepayment,
    String? responseText,
    String? specialistName,
    String? specialistPhone,
    bool throwOnError = false,
  }) async {
    final body = <String, dynamic>{
      'receiver_id': receiverId,
      'order_request_id': orderRequestId,
      if (price != null) 'price': price,
      if (deadline != null) 'deadline': deadline,
      if (enrollmentDate != null)
        'enrollment_date': enrollmentDate.toIso8601String(),
      if (prepayment != null) 'prepayment': prepayment,
      if (responseText != null) 'response_text': responseText,
      if (specialistName != null) 'specialist_name': specialistName,
      if (specialistPhone != null) 'specialist_phone': specialistPhone,
    };

    return await ApiClient.postJson(
      '/api/order/create',
      body,
      baseUrl: ApiConfig.orderingBaseUrl,
      throwOnError: throwOnError,
    );
  }

  /// Change the proposed enrollment date.
  Future<Map<String, dynamic>?> changeOrderEnrollmentDate({
    required int orderId,
    required DateTime newDate,
  }) async {
    final body = <String, dynamic>{
      'order_id': orderId,
      'enrollment_date': newDate.toIso8601String(),
    };
    return await ApiClient.putJson(
      '/api/order/changeOrderEnrollmentDate',
      body,
      baseUrl: ApiConfig.orderingBaseUrl,
    );
  }

  /// Confirm the enrollment date proposed by the company.
  Future<Map<String, dynamic>?> confirmEnrollmentDate(int orderId) async {
    return await ApiClient.putJson(
      '/api/order/confirmEnrollmentDate?order_id=$orderId',
      <String, dynamic>{},
      baseUrl: ApiConfig.orderingBaseUrl,
    );
  }

  /// Legacy alias used by some screens for client confirmation.
  Future<Map<String, dynamic>?> enroll(int orderId) async {
    return await ApiClient.putJson(
      '/api/order/enroll?order_id=$orderId',
      <String, dynamic>{},
      baseUrl: ApiConfig.orderingBaseUrl,
    );
  }

  /// Get all orders for the current user, or all responses for one request.
  Future<List<Map<String, dynamic>>?> getOrders({int? orderRequestId}) async {
    final url = orderRequestId != null
        ? '/api/order/get?order_request_id=$orderRequestId'
        : '/api/order/get';

    try {
      final json = await ApiClient.getJson(
        url,
        baseUrl: ApiConfig.orderingBaseUrl,
      );

      if (json == null) {
        print(
          'Warning: getOrders returned null for orderRequestId=$orderRequestId',
        );
        return [];
      }

      if (json is List) {
        return (json as List).cast<Map<String, dynamic>>();
      }

      if (json is Map<String, dynamic>) {
        final orders = json['orders'] ?? json['data'] ?? json['result'];
        if (orders is List) {
          return orders.map((e) => e as Map<String, dynamic>).toList();
        }
        print(
          'Warning: getOrders response is object but no orders list found: $json',
        );
      }

      print(
        'Warning: Unexpected response format in getOrders: ${json.runtimeType}',
      );
      return [];
    } catch (e) {
      print('Error in getOrders: $e');
      return [];
    }
  }

  /// Fetch a single order by id by reusing the list endpoints the backend exposes today.
  Future<Map<String, dynamic>?> getOrderById(
    int orderId, {
    int? orderRequestId,
  }) async {
    final scopedOrders = await getOrders(orderRequestId: orderRequestId);
    if (scopedOrders != null) {
      for (final order in scopedOrders) {
        if (_extractOrderId(order) == orderId) {
          return order;
        }
      }
    }

    final allOrders = await getOrders();
    if (allOrders != null) {
      for (final order in allOrders) {
        if (_extractOrderId(order) == orderId) {
          return order;
        }
      }
    }

    return null;
  }

  /// Finish an order.
  Future<Map<String, dynamic>?> finish(int orderId) async {
    return await ApiClient.putJson(
      '/api/order/finishOrder?order_id=$orderId',
      <String, dynamic>{},
      baseUrl: ApiConfig.orderingBaseUrl,
    );
  }

  /// Cancel an enrollment and mark the order as canceled.
  Future<Map<String, dynamic>?> cancel(int orderId) async {
    return await ApiClient.putJson(
      '/api/order/cancelEnrollment?order_id=$orderId',
      <String, dynamic>{},
      baseUrl: ApiConfig.orderingBaseUrl,
    );
  }

  /// Check whether the current user can add a review.
  Future<bool> canAddReview({
    required String clientId,
    required String companyId,
    String? reviewerId,
    bool reserve = false,
  }) async {
    final reviewerQuery = reviewerId != null
        ? '&reviewer_id=${Uri.encodeComponent(reviewerId)}'
        : '';
    final json = await ApiClient.putJson(
      '/api/order/addReview?client_id=$clientId&company_id=$companyId&reserve=$reserve$reviewerQuery',
      <String, dynamic>{},
      baseUrl: ApiConfig.orderingBaseUrl,
    );
    if (json == null) return false;
    return json['success'] == true;
  }
}
