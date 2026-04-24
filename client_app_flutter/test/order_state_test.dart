import 'package:flutter_test/flutter_test.dart';
import 'package:client_app_flutter/utils/order_state.dart';

void main() {
  group('order_state helpers', () {
    test('parses status from int and string', () {
      expect(parseOrderStatus({'status': 2}), orderStatusFinished);
      expect(parseOrderStatus({'status': '3'}), orderStatusCanceled);
      expect(parseOrderStatus({'status': null}), orderStatusActive);
      expect(parseOrderStatus({}), orderStatusActive);
    });

    test('parses enrollment and confirmation flags in snake/camel formats', () {
      expect(
        isOrderConfirmed({
          'status': 1,
          'is_enrolled': true,
          'is_date_confirmed': true,
        }),
        isTrue,
      );

      expect(
        isOrderConfirmed({
          'status': '1',
          'isEnrolled': 1,
          'isDateConfirmed': 'true',
        }),
        isTrue,
      );
    });

    test('confirmed requires active status', () {
      final finished = {
        'status': 2,
        'is_enrolled': true,
        'is_date_confirmed': true,
      };
      final canceled = {
        'status': 3,
        'is_enrolled': true,
        'is_date_confirmed': true,
      };

      expect(isOrderConfirmed(finished), isFalse);
      expect(isOrderConfirmed(canceled), isFalse);
      expect(canFinishOrder(finished), isFalse);
      expect(canConfirmOrder(canceled), isFalse);
    });
  });
}
