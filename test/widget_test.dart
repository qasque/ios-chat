// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/src/app.dart';
import 'package:mobile/src/config/app_config.dart';

void main() {
  testWidgets('renders shell tabs', (WidgetTester tester) async {
    const config = AppConfig(
      flavor: AppFlavor.dev,
      chatwootBaseUrl: 'http://127.0.0.1:3000',
      inboxIdentifier: 'test',
      bridgeBaseUrl: 'http://127.0.0.1:4000',
      bridgeBotKey: 'test_bot',
    );

    await tester.pumpWidget(const SupportApp(config: config));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Bridge'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
