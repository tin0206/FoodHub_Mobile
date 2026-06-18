class AuthService {
  Future<void> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    throw UnimplementedError('Implement signIn() when backend is ready.');
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    throw UnimplementedError('Implement signUp() when backend is ready.');
  }

  Future<void> forgotPassword({required String email}) async {
    throw UnimplementedError(
      'Implement forgotPassword() when backend is ready.',
    );
  }
}
