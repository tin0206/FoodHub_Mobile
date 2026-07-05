class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

String parseApiErrorMessage(dynamic body, {String fallback = 'Request failed'}) {
  if (body is Map) {
    final detail = body['detail'];
    if (detail is String) return detail;
    if (detail is Map) {
      final message = detail['message'];
      if (message is String) return message;
      final error = detail['error'];
      if (error is String) return error;
    }
  }
  return fallback;
}
