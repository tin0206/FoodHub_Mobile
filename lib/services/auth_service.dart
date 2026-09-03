import 'package:foodhub_mobile/models/user.dart';
import 'package:foodhub_mobile/services/api_client.dart';
import 'package:foodhub_mobile/services/session_service.dart';
import 'package:foodhub_mobile/services/token_storage.dart';

typedef OtpDispatch = ({String message, String? otp});

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

  Future<UserModel> _persist(dynamic data) async {
    final token = AuthToken.fromJson(data as Map<String, dynamic>);
    await _tokenStorage.saveToken(token.accessToken);
    _session.setUser(token.user);
    return token.user;
  }

  OtpDispatch _otpDispatch(dynamic data, String fallback) {
    final map = data as Map<String, dynamic>;
    return (
      message: map['message'] as String? ?? fallback,
      otp: map['otp'] as String?,
    );
  }

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
    return _persist(data);
  }

  Future<OtpDispatch> signUp({
    required String fullName,
    required String email,
    required String password,
    String language = 'en',
  }) async {
    final data = await _api.post(
      '/auth/signup',
      auth: false,
      body: {
        'email': email.trim(),
        'password': password,
        'full_name': fullName.trim(),
        'language': language,
      },
    );
    return _otpDispatch(
      data,
      'If this email can be used, a verification code has been sent.',
    );
  }

  Future<OtpDispatch> resendSignupOtp({required String email}) async {
    final data = await _api.post(
      '/auth/signup/resend-otp',
      auth: false,
      body: {'email': email.trim()},
    );
    return _otpDispatch(
      data,
      'If a signup is pending, a new verification code has been sent.',
    );
  }

  Future<String?> resendSignupOtpBestEffort(String email) async {
    try {
      return (await resendSignupOtp(email: email)).otp;
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> verifySignupOtp({
    required String email,
    required String otp,
  }) async {
    final data = await _api.post(
      '/auth/signup/verify-otp',
      auth: false,
      body: {
        'email': email.trim(),
        'otp': otp.trim(),
      },
    );
    return _persist(data);
  }

  /// [tokenType] is either 'id_token' (mobile) or 'access_token' (web).
  Future<UserModel> signInWithGoogle({
    required String token,
    required String tokenType,
  }) async {
    final endpoint = tokenType == 'access_token'
        ? '/auth/google/access_token'
        : '/auth/google/token';
    final data = await _api.post(endpoint, auth: false, body: {tokenType: token});
    return _persist(data);
  }

  Future<OtpDispatch> forgotPassword({required String email}) async {
    final data = await _api.post(
      '/auth/forgot-password',
      auth: false,
      body: {'email': email.trim()},
    );
    return _otpDispatch(
      data,
      'If the email exists, a reset code has been sent.',
    );
  }

  Future<void> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    await _api.post(
      '/auth/verify-reset-otp',
      auth: false,
      body: {
        'email': email.trim(),
        'otp': otp.trim(),
      },
    );
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _api.post(
      '/auth/reset-password',
      auth: false,
      body: {
        'email': email.trim(),
        'otp': otp.trim(),
        'new_password': newPassword,
      },
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
