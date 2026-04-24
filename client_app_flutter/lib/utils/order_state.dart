const int orderStatusActive = 1;
const int orderStatusLegacyActive = 0;
const int orderStatusFinished = 2;
const int orderStatusCanceled = 3;

int parseOrderStatus(Map<String, dynamic> order) {
  final raw = order['status'] ?? order['order_status'] ?? order['orderStatus'];
  if (raw is num) return raw.toInt();
  final parsed = int.tryParse(raw?.toString() ?? '');
  return parsed ?? orderStatusActive;
}

bool _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().trim().toLowerCase();
  return normalized == 'true' || normalized == '1';
}

bool isOrderActive(Map<String, dynamic> order) {
  final status = parseOrderStatus(order);
  return status == orderStatusActive || status == orderStatusLegacyActive;
}

bool isOrderFinished(Map<String, dynamic> order) =>
    parseOrderStatus(order) == orderStatusFinished;

bool isOrderCanceled(Map<String, dynamic> order) =>
    parseOrderStatus(order) == orderStatusCanceled;

bool isOrderEnrolled(Map<String, dynamic> order) =>
    _parseBool(order['is_enrolled'] ?? order['isEnrolled']);

bool isOrderDateConfirmed(Map<String, dynamic> order) =>
    _parseBool(order['is_date_confirmed'] ?? order['isDateConfirmed']);

bool isOrderConfirmed(Map<String, dynamic> order) {
  if (!isOrderActive(order)) return false;
  return isOrderEnrolled(order) && isOrderDateConfirmed(order);
}

bool canConfirmOrder(Map<String, dynamic> order) {
  if (!isOrderActive(order)) return false;
  return !isOrderConfirmed(order);
}

bool canFinishOrder(Map<String, dynamic> order) {
  if (!isOrderActive(order)) return false;
  return isOrderConfirmed(order);
}
