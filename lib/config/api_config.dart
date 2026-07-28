class ApiConfig {
  ApiConfig._();

  /// Override at build time: `--dart-define=API_BASE_URL=http://justinakatruc-mac.tail657715.ts.net:8000/api/v1`
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return 'http://justinakatruc-mac.tail657715.ts.net:8000/api/v1';
  }

  static String get apiOrigin {
    return baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');
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

    final parsed = Uri.tryParse(url);
    if (parsed == null) return '';

    // Preferred: API-relative /media/... (same host as the app API)
    if (!parsed.hasScheme || url.startsWith('/')) {
      final path = url.startsWith('/') ? url : '/$url';
      return '$apiOrigin$path';
    }

    // Legacy absolute Ceph URLs → rewrite to API /media proxy
    final path = parsed.path;
    final mediaIdx = path.indexOf('/foodhub-images/');
    if (mediaIdx >= 0) {
      final objectKey = path.substring(mediaIdx + '/foodhub-images/'.length);
      return '$apiOrigin/media/$objectKey';
    }
    if (path.startsWith('/media/')) {
      return '$apiOrigin$path';
    }

    if (parsed.scheme == 'http' || parsed.scheme == 'https') {
      return url;
    }

    return '$apiOrigin/${url.replaceFirst(RegExp(r'^/'), '')}';
  }
}
