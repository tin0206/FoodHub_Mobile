class ApiConfig {
  ApiConfig._();

  static String _baseUrl = const String.fromEnvironment('API_BASE_URL');

  static String get baseUrl => _baseUrl;

  // Tests override this to point at the staging API.
  // ignore: avoid_setters_without_getters
  static set baseUrl(String url) => _baseUrl = url;

  static String get apiOrigin {
    return baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');
  }

  static String get ingredientsStreamUrl {
    final wsBase = baseUrl
        .replaceFirst(RegExp(r'^https://'), 'wss://')
        .replaceFirst(RegExp(r'^http://'), 'ws://');
    return '$wsBase/ai/ingredients/stream';
  }

  static String resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';

    final parsed = Uri.tryParse(url);
    if (parsed == null) return '';

    if (!parsed.hasScheme || url.startsWith('/')) {
      final path = url.startsWith('/') ? url : '/$url';
      return '$apiOrigin$path';
    }

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
