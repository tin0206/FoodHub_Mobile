import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:foodhub_mobile/config/api_config.dart';
import 'package:foodhub_mobile/models/ai.dart';
import 'package:foodhub_mobile/services/token_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class IngredientsStreamService {
  IngredientsStreamService({TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorage();

  final TokenStorage _tokenStorage;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _busyWatchdog;
  bool _awaitingResponse = false;

  bool get isConnected => _channel != null;
  bool get isBusy => _awaitingResponse;

  Future<void> connect({
    required void Function(IngredientsStreamFrame frame) onFrame,
    void Function(Object error)? onError,
    void Function()? onDone,
  }) async {
    await disconnect();

    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw StateError('Not authenticated');
    }

    final uri = Uri.parse(
      '${ApiConfig.ingredientsStreamUrl}?token=${Uri.encodeQueryComponent(token)}',
    );
    debugPrint('Ingredients WS connecting: ${uri.replace(queryParameters: {
      ...uri.queryParameters,
      'token': '***',
    })}');

    final channel = WebSocketChannel.connect(uri);
    await channel.ready.timeout(const Duration(seconds: 10));

    _channel = channel;
    _awaitingResponse = false;

    _subscription = channel.stream.listen(
      (event) {
        _clearBusy();
        try {
          final Map<String, dynamic> json;
          if (event is String) {
            json = jsonDecode(event) as Map<String, dynamic>;
          } else if (event is List<int>) {
            json = jsonDecode(utf8.decode(event)) as Map<String, dynamic>;
          } else {
            debugPrint('Ingredients WS ignored event type: ${event.runtimeType}');
            return;
          }
          final frame = IngredientsStreamFrame.fromJson(json);
          debugPrint(
            'Ingredients WS frame: '
            '${frame.ingredients.length} labels, '
            '${frame.detections.length} boxes'
            '${frame.error != null ? ', error=${frame.error}' : ''}',
          );
          onFrame(frame);
        } catch (e) {
          onError?.call(e);
        }
      },
      onError: (Object e) {
        _clearBusy();
        debugPrint('Ingredients WS stream error: $e');
        onError?.call(e);
      },
      onDone: () {
        _clearBusy();
        _channel = null;
        debugPrint('Ingredients WS closed');
        onDone?.call();
      },
      cancelOnError: false,
    );
  }

  /// Sends a JPEG frame if connected and not waiting on a prior response.
  bool sendFrame(Uint8List jpegBytes) {
    final channel = _channel;
    if (channel == null) {
      debugPrint('Ingredients WS send skipped: not connected');
      return false;
    }
    if (_awaitingResponse) {
      return false;
    }
    if (jpegBytes.isEmpty || jpegBytes.length > 1024 * 1024) {
      debugPrint('Ingredients WS send skipped: bad size ${jpegBytes.length}');
      return false;
    }

    _awaitingResponse = true;
    _busyWatchdog?.cancel();
    _busyWatchdog = Timer(const Duration(seconds: 8), () {
      if (_awaitingResponse) {
        debugPrint('Ingredients WS response timeout — unlocking sender');
        _awaitingResponse = false;
      }
    });

    try {
      channel.sink.add(jpegBytes);
      debugPrint('Ingredients WS sent frame ${jpegBytes.length} bytes');
      return true;
    } catch (e) {
      debugPrint('Ingredients WS send failed: $e');
      _clearBusy();
      return false;
    }
  }

  void _clearBusy() {
    _busyWatchdog?.cancel();
    _busyWatchdog = null;
    _awaitingResponse = false;
  }

  Future<void> disconnect() async {
    _clearBusy();
    final subscription = _subscription;
    _subscription = null;
    final channel = _channel;
    _channel = null;

    if (subscription != null) {
      try {
        await subscription.cancel();
      } catch (_) {}
    }
    if (channel == null) return;
    try {
      await channel.sink.close();
    } catch (_) {}
  }
}
