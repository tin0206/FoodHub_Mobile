import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  static String _baseUrl = const String.fromEnvironment('API_BASE_URL');
  static const _ceph = 'https://ceph.foodhub.io.vn/foodhub-images';
  static const _publicApiOrigin = 'https://api.foodhub.io.vn';

  static String get baseUrl => _baseUrl;

  // Tests override this to point at the staging API.
  // ignore: avoid_setters_without_getters
  static set baseUrl(String url) => _baseUrl = url;

  static String get apiOrigin {
    return baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');
  }

  static String get _origin {
    final origin = apiOrigin;
    return origin.isEmpty ? _publicApiOrigin : origin;
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

    final objectKey = _objectKey(url, parsed);
    if (objectKey != null) {
      // Flutter web (Chrome / DevicePreview) uses XHR/CanvasKit and needs CORS.
      // Ceph RGW currently answers GET without ACAO and OPTIONS 403.
      if (kIsWeb) {
        return '$_origin/media/$objectKey';
      }
      return '$_ceph/$objectKey';
    }

    if (!parsed.hasScheme || url.startsWith('/')) {
      final path = url.startsWith('/') ? url : '/$url';
      return '$_origin$path';
    }
    if (parsed.scheme == 'http' || parsed.scheme == 'https') {
      return url;
    }
    return '$_origin/${url.replaceFirst(RegExp(r'^/'), '')}';
  }

  static String? _objectKey(String url, Uri parsed) {
    if (!parsed.hasScheme || url.startsWith('/')) {
      final path = url.startsWith('/') ? url : '/$url';
      if (path.startsWith('/media/')) {
        return path.substring('/media/'.length);
      }
      return null;
    }
    final path = parsed.path;
    final idx = path.indexOf('/foodhub-images/');
    if (idx >= 0) {
      return path.substring(idx + '/foodhub-images/'.length);
    }
    if (path.startsWith('/media/')) {
      return path.substring('/media/'.length);
    }
    return null;
  }
}
