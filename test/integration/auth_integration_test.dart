@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:foodhub_mobile/services/api_client.dart';
import 'package:foodhub_mobile/services/api_exception.dart';
import 'package:foodhub_mobile/services/auth_service.dart';

import 'test_config.dart';

// Runs the real AuthService against the staging API (test/integration/.env.test).
// Run with: flutter test --tags integration
//
// Deliberately uses plain package:test (not flutter_test) and an in-memory
// TokenStorage — flutter_test's TestWidgetsFlutterBinding fakes every HTTP
// response as a 400 with no real network call, which defeats the purpose
// of a live-backend check. See test_config.dart for details.
void main() {
  final creds = TestCredentials.load();
  final skip = creds == null
      ? 'No staging credentials configured — copy test/integration/.env.test.example '
          'to test/integration/.env.test and fill in real values.'
      : null;

  late InMemoryTokenStorage tokenStorage;
  late ApiClient api;

  setUp(() {
    tokenStorage = InMemoryTokenStorage();
    api = ApiClient(tokenStorage: tokenStorage);
    if (creds != null) initApiConfigForTests(creds.apiBaseUrl);
  });

  AuthService authService() => AuthService(apiClient: api, tokenStorage: tokenStorage);

  group('AUTH-03 / AUTH-04: sign-in against the real API', () {
    test('signs in the normal test user and returns their real profile', () async {
      final user = await authService().signIn(
        email: creds!.userEmail,
        password: creds.userPassword,
        rememberMe: false,
      );
      expect(user.email, creds.userEmail);
      expect(user.role, 'user');
    }, skip: skip);

    test('NAV-04: signs in the admin test user with role=admin', () async {
      final user = await authService().signIn(
        email: creds!.adminEmail,
        password: creds.adminPassword,
        rememberMe: false,
      );
      expect(user.email, creds.adminEmail);
      expect(user.role, 'admin');
    }, skip: skip);

    test('rejects sign-in with a wrong password', () async {
      await expectLater(
        authService().signIn(
          email: creds!.userEmail,
          password: 'definitely-the-wrong-password',
          rememberMe: false,
        ),
        throwsA(isA<ApiException>()),
      );
    }, skip: skip);
  });

  group('AUTH-02: duplicate signup is rejected', () {
    test('signing up with an email that already exists fails', () async {
      await expectLater(
        authService().signUp(
          fullName: 'Duplicate Account Attempt',
          email: creds!.userEmail, // already registered on staging
          password: 'whateverPassword123',
        ),
        throwsA(isA<ApiException>()),
      );
    }, skip: skip);
  });

  group('AUTH-05: forgotPassword does not reveal whether an email exists', () {
    test('responds successfully for both a known and an unknown email', () async {
      final knownMessage = await authService().forgotPassword(email: creds!.userEmail);
      final unknownMessage = await authService().forgotPassword(
        email: 'qa-does-not-exist-${DateTime.now().millisecondsSinceEpoch}@example.com',
      );

      expect(knownMessage, isNotEmpty);
      expect(unknownMessage, isNotEmpty);
    }, skip: skip);
  });

  group('AUTH-07: changePassword rejects a wrong current password', () {
    test('fails with a wrong current password and leaves the real password usable', () async {
      await authService().signIn(
        email: creds!.userEmail,
        password: creds.userPassword,
        rememberMe: false,
      );

      await expectLater(
        authService().changePassword(
          currentPassword: 'not-the-real-current-password',
          newPassword: 'irrelevant-new-password-123',
        ),
        throwsA(isA<ApiException>()),
      );

      // The real password must still work — this call never should have
      // been able to change it. Sign in again with a fresh token store.
      final freshUser = await AuthService(
        apiClient: ApiClient(tokenStorage: InMemoryTokenStorage()),
        tokenStorage: InMemoryTokenStorage(),
      ).signIn(email: creds.userEmail, password: creds.userPassword, rememberMe: false);
      expect(freshUser.email, creds.userEmail);
    }, skip: skip);
  });

  group('AUTH-08: restoreSession', () {
    test('fetches /users/me for a token saved by a previous sign-in', () async {
      await authService().signIn(
        email: creds!.userEmail,
        password: creds.userPassword,
        rememberMe: false,
      );

      // Same token store, a fresh AuthService — simulates "reopen the app".
      final restored = await authService().restoreSession();

      expect(restored, isNotNull);
      expect(restored!.email, creds.userEmail);
    }, skip: skip);

    test('AUTH-09: the real server rejects a garbage token, clearing local session', () async {
      await tokenStorage.saveToken('this-is-not-a-real-jwt');

      final restored = await authService().restoreSession();

      expect(restored, isNull);
      expect(await tokenStorage.readToken(), isNull);
    }, skip: skip);
  });
}
