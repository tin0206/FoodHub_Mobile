import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodhub_mobile/main.dart';

void main() {
  testWidgets('Login screen is the default home screen', (
    WidgetTester tester,
  ) async {
    // No stored token, so the splash screen's restoreSession() call
    // resolves to "logged out" and it routes to LoginScreen.
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    // SplashScreen waits ~1600ms (session restore + minimum splash time)
    // before navigating away; settle past that plus its transition.
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();

    expect(find.textContaining('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
  });
}
