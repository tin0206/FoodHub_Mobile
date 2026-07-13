import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  /// Override at build time: `--dart-define=API_BASE_URL=http://192.168.x.x:8000/api/v1`
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'http://localhost:8000/api/v1';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://localhost:8000/api/v1';
  }

  static String get ingredientsStreamUrl {
    final httpBase = baseUrl;
    final wsBase = httpBase
        .replaceFirst(RegExp(r'^https://'), 'wss://')
        .replaceFirst(RegExp(r'^http://'), 'ws://');
    return '$wsBase/ai/ingredients/stream';
  }

  static String resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final origin = baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');
    return url.startsWith('/') ? '$origin$url' : '$origin/$url';
  }
}
