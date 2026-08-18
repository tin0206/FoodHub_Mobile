import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:foodhub_mobile/models/user.dart';
import 'package:foodhub_mobile/services/api_client.dart';
import 'package:foodhub_mobile/services/auth_service.dart';
import 'package:foodhub_mobile/services/session_service.dart';
import 'package:foodhub_mobile/services/token_storage.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockTokenStorage extends Mock implements TokenStorage {}

class MockSessionService extends Mock implements SessionService {}

void main() {
  late MockApiClient api;
  late MockTokenStorage tokenStorage;
  late MockSessionService session;
  late AuthService authService;

  setUpAll(() {
    registerFallbackValue(
      const UserModel(id: 0, email: 'fallback@x.com', username: 'fallback'),
    );
  });

  setUp(() {
    api = MockApiClient();
    tokenStorage = MockTokenStorage();
    session = MockSessionService();
    authService = AuthService(
      apiClient: api,
      tokenStorage: tokenStorage,
      session: session,
    );

    when(() => tokenStorage.saveToken(any())).thenAnswer((_) async {});
    when(() => tokenStorage.clearToken()).thenAnswer((_) async {});
    when(() => session.setUser(any())).thenReturn(null);
    when(() => session.clear()).thenReturn(null);
  });

  group('signIn', () {
    test('saves the token and updates the session on success', () async {
      when(
        () => api.post(
          '/auth/login',
          auth: false,
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => {
          'access_token': 'tok-1',
          'token_type': 'bearer',
          'user': {'id': 1, 'email': 'a@b.com', 'username': 'a'},
        },
      );

      final user = await authService.signIn(
        email: '  a@b.com  ',
        password: 'secret',
        rememberMe: true,
      );

      expect(user.id, 1);
      verify(() => tokenStorage.saveToken('tok-1')).called(1);
      verify(() => session.setUser(any(that: isA<UserModel>()))).called(1);

      final captured = verify(
        () => api.post('/auth/login', auth: false, body: captureAny(named: 'body')),
      ).captured.single as Map<String, dynamic>;
      expect(captured['email'], 'a@b.com'); // trimmed
      expect(captured['remember_me'], isTrue);
    });

    test('propagates the error and never touches storage on failure', () async {
      when(
        () => api.post('/auth/login', auth: false, body: any(named: 'body')),
      ).thenThrow(Exception('invalid credentials'));

      expect(
        () => authService.signIn(
          email: 'a@b.com',
          password: 'wrong',
          rememberMe: false,
        ),
        throwsException,
      );

      verifyNever(() => tokenStorage.saveToken(any()));
      verifyNever(() => session.setUser(any()));
    });
  });

  group('signUp', () {
    test('trims email/name and stores the returned token', () async {
      when(
        () => api.post('/auth/signup', auth: false, body: any(named: 'body')),
      ).thenAnswer(
        (_) async => {
          'access_token': 'tok-2',
          'user': {'id': 2, 'email': 'new@b.com', 'username': 'new'},
        },
      );

      await authService.signUp(
        fullName: '  New User  ',
        email: '  new@b.com  ',
        password: 'secret',
      );

      final captured = verify(
        () => api.post('/auth/signup', auth: false, body: captureAny(named: 'body')),
      ).captured.single as Map<String, dynamic>;
      expect(captured['full_name'], 'New User');
      expect(captured['email'], 'new@b.com');
      verify(() => tokenStorage.saveToken('tok-2')).called(1);
    });
  });

  group('forgotPassword', () {
    test('returns the server message when present', () async {
      when(
        () => api.post('/auth/forgot-password', auth: false, body: any(named: 'body')),
      ).thenAnswer((_) async => {'message': 'Check your inbox'});

      final message = await authService.forgotPassword(email: 'a@b.com');
      expect(message, 'Check your inbox');
    });

    test('falls back to a generic message when the API omits it', () async {
      when(
        () => api.post('/auth/forgot-password', auth: false, body: any(named: 'body')),
      ).thenAnswer((_) async => <String, dynamic>{});

      final message = await authService.forgotPassword(email: 'a@b.com');
      expect(message, 'If the email exists, a reset link has been sent.');
    });
  });

  group('changePassword', () {
    test('sends current and new password to the API', () async {
      when(
        () => api.post('/auth/change-password', body: any(named: 'body')),
      ).thenAnswer((_) async => null);

      await authService.changePassword(
        currentPassword: 'old',
        newPassword: 'new',
      );

      final captured = verify(
        () => api.post('/auth/change-password', body: captureAny(named: 'body')),
      ).captured.single as Map<String, dynamic>;
      expect(captured['current_password'], 'old');
      expect(captured['new_password'], 'new');
    });
  });

  group('restoreSession', () {
    test('returns null without calling the API when there is no token', () async {
      when(() => tokenStorage.readToken()).thenAnswer((_) async => null);

      final user = await authService.restoreSession();

      expect(user, isNull);
      verifyNever(() => api.get(any()));
    });

    test('fetches the current user and updates the session when a token exists', () async {
      when(() => tokenStorage.readToken()).thenAnswer((_) async => 'tok-3');
      when(() => api.get('/users/me')).thenAnswer(
        (_) async => {'id': 9, 'email': 'a@b.com', 'username': 'a'},
      );

      final user = await authService.restoreSession();

      expect(user?.id, 9);
      verify(() => session.setUser(any(that: isA<UserModel>()))).called(1);
    });

    test('clears the token and session when the stored token is rejected', () async {
      when(() => tokenStorage.readToken()).thenAnswer((_) async => 'expired');
      when(() => api.get('/users/me')).thenThrow(Exception('401'));

      final user = await authService.restoreSession();

      expect(user, isNull);
      verify(() => tokenStorage.clearToken()).called(1);
      verify(() => session.clear()).called(1);
    });
  });

  group('signOut', () {
    test('clears the stored token and the session', () async {
      await authService.signOut();

      verify(() => tokenStorage.clearToken()).called(1);
      verify(() => session.clear()).called(1);
    });
  });
}
