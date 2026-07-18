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

String messageForStatusCode(int statusCode, dynamic body) {
  if (statusCode == 429) {
    final detail = parseApiErrorMessage(
      body,
      fallback: 'AI queue is full. Please try again in a moment.',
    );
    return detail;
  }
  return parseApiErrorMessage(
    body,
    fallback: 'Request failed ($statusCode)',
  );
}
