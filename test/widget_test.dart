import 'package:flutter_test/flutter_test.dart';
import 'package:foodhub_mobile/main.dart';

void main() {
  testWidgets('Login screen is the default home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
  });
}
