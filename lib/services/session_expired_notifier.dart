import 'package:flutter/material.dart';
import 'package:foodhub_mobile/screens/login_screen.dart';
import 'package:foodhub_mobile/services/session_service.dart';
import 'package:foodhub_mobile/services/token_storage.dart';

/// Fired by [ApiClient] whenever an *authenticated* request comes back 401
/// (expired or invalid token) while the user is actively using the app.
///
/// `ApiClient` is a plain Dart class with no `BuildContext`, so it can't
/// navigate on its own — it goes through this singleton instead, which is
/// wired to the app's root [Navigator] once at startup (see `main.dart`).
class SessionExpiredNotifier {
  SessionExpiredNotifier._();
  static final instance = SessionExpiredNotifier._();

  GlobalKey<NavigatorState>? navigatorKey;

  Future<void> handle() async {
    // SessionService.clear() is synchronous, so the first caller flips
    // isLoggedIn to false before any `await` runs — any other requests
    // that 401 in the same burst see isLoggedIn == false and bail out here,
    // so a burst of parallel failing calls triggers only one redirect.
    if (!SessionService.instance.isLoggedIn) return;
    SessionService.instance.clear();
    await TokenStorage().clearToken();

    final navigator = navigatorKey?.currentState;
    navigator?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(sessionExpired: true),
      ),
      (route) => false,
    );
  }
}
