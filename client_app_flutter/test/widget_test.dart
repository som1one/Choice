import 'package:flutter_test/flutter_test.dart';

import 'package:client_app_flutter/main.dart';

void main() {
  testWidgets('Welcome screen and auto-navigation to login work', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Стартовый экран.
    expect(find.text('ВЫБОР'), findsOneWidget);
    expect(find.text('CHOICE'), findsOneWidget);
    expect(find.text('Приложение для выбора лучших условий'), findsOneWidget);

    // Ждем автопереход на экран входа через 2 секунды.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Вход'), findsOneWidget);
  });
}
