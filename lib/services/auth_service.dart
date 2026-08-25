import 'package:foodhub_mobile/models/user.dart';
import 'package:foodhub_mobile/services/api_client.dart';
import 'package:foodhub_mobile/services/session_service.dart';
import 'package:foodhub_mobile/services/token_storage.dart';

class AuthService {
  AuthService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
    SessionService? session,
  })  : _api = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage(),
        _session = session ?? SessionService.instance;

  final ApiClient _api;
  final TokenStorage _tokenStorage;
  final SessionService _session;

  Future<UserModel> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final data = await _api.post(
      '/auth/login',
      auth: false,
      body: {
        'email': email.trim(),
        'password': password,
        'remember_me': rememberMe,
      },
    );

    final token = AuthToken.fromJson(data as Map<String, dynamic>);
    await _tokenStorage.saveToken(token.accessToken);
    _session.setUser(token.user);
    return token.user;
  }

  Future<UserModel> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final data = await _api.post(
      '/auth/signup',
      auth: false,
      body: {
        'email': email.trim(),
        'password': password,
        'full_name': fullName.trim(),
      },
    );

    final token = AuthToken.fromJson(data as Map<String, dynamic>);
    await _tokenStorage.saveToken(token.accessToken);
    _session.setUser(token.user);
    return token.user;
  }

  /// [tokenType] is either 'id_token' (mobile) or 'access_token' (web).
  Future<UserModel> signInWithGoogle({
    required String token,
    required String tokenType,
  }) async {
    final endpoint = tokenType == 'access_token'
        ? '/auth/google/access_token'
        : '/auth/google/token';
    // ignore: avoid_print
    print('[AuthService] POST $endpoint  tokenType=$tokenType  tokenLen=${token.length}');
    try {
      final data = await _api.post(endpoint, auth: false, body: {tokenType: token});
      // ignore: avoid_print
      print('[AuthService] response=$data');
      final authToken = AuthToken.fromJson(data as Map<String, dynamic>);
      await _tokenStorage.saveToken(authToken.accessToken);
      _session.setUser(authToken.user);
      return authToken.user;
    } catch (e) {
      // ignore: avoid_print
      print('[AuthService] ERROR: $e');
      rethrow;
    }
  }

  /// Returns (message, resetToken). resetToken is non-null in dev (returned
  /// directly by the API until email service is wired up).
  Future<({String message, String? resetToken})> forgotPassword({
    required String email,
  }) async {
    final data = await _api.post(
      '/auth/forgot-password',
      auth: false,
      body: {'email': email.trim()},
    );
    final map = data as Map<String, dynamic>;
    return (
      message: map['message'] as String? ?? 'If the email exists, a reset link has been sent.',
      resetToken: map['reset_token'] as String?,
    );
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    await _api.post(
      '/auth/reset-password',
      auth: false,
      body: {'email': email.trim(), 'token': token, 'new_password': newPassword},
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.post(
      '/auth/change-password',
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }

  Future<UserModel?> restoreSession() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) return null;

    try {
      final userService = UserService(apiClient: _api);
      final user = await userService.getMe();
      _session.setUser(user);
      return user;
    } catch (_) {
      await _tokenStorage.clearToken();
      _session.clear();
      return null;
    }
  }

  Future<void> signOut() async {
    await _tokenStorage.clearToken();
    _session.clear();
  }
}

class UserService {
  UserService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<UserModel> getMe() async {
    final data = await _api.get('/users/me');
    return UserModel.fromJson(data as Map<String, dynamic>);
  }

  Future<UserModel> updateMe(Map<String, dynamic> body) async {
    final data = await _api.patch('/users/me', body: body);
    final user = UserModel.fromJson(data as Map<String, dynamic>);
    SessionService.instance.setUser(user);
    return user;
  }
}
