import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

const _kGoogleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

class GoogleAuthService {
  static GoogleSignIn get _googleSignIn => GoogleSignIn(
        // Web dùng clientId, mobile dùng serverClientId
        clientId: kIsWeb ? _kGoogleWebClientId : null,
        serverClientId: kIsWeb ? null : _kGoogleWebClientId,
      );

    /// Mở Google Sign-In flow.
  /// Trả về record (token, type) để gửi lên backend, hoặc null nếu user hủy.
  /// Web  → accessToken + type='access_token' → POST /auth/google/access_token
  /// Mobile → idToken   + type='id_token'     → POST /auth/google/token
  static Future<({String token, String type})?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;
      final auth = await account.authentication;
      if (kIsWeb) {
        if (auth.accessToken == null) return null;
        return (token: auth.accessToken!, type: 'access_token');
      } else {
        if (auth.idToken == null) return null;
        return (token: auth.idToken!, type: 'id_token');
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('[Google] ERROR: $e\n$st');
      rethrow;
    }
  }

  static Future<void> signOut() => _googleSignIn.signOut();
}
