import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:foodhub_mobile/services/ingredients_stream_service.dart';
import 'package:foodhub_mobile/services/token_storage.dart';

class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late MockTokenStorage tokenStorage;
  late IngredientsStreamService service;

  setUp(() {
    tokenStorage = MockTokenStorage();
    service = IngredientsStreamService(tokenStorage: tokenStorage);
  });

  test('starts disconnected and idle', () {
    expect(service.isConnected, isFalse);
    expect(service.isBusy, isFalse);
  });

  group('connect', () {
    test('throws StateError when there is no stored token', () async {
      when(() => tokenStorage.readToken()).thenAnswer((_) async => null);

      expect(
        () => service.connect(onFrame: (_) {}),
        throwsA(isA<StateError>()),
      );
    });

    test('throws StateError when the stored token is empty', () async {
      when(() => tokenStorage.readToken()).thenAnswer((_) async => '');

      expect(
        () => service.connect(onFrame: (_) {}),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('sendFrame', () {
    test('returns false when not connected, regardless of payload', () {
      expect(service.sendFrame(Uint8List(0)), isFalse);
      expect(service.sendFrame(Uint8List.fromList([1, 2, 3])), isFalse);
      expect(service.sendFrame(Uint8List(2 * 1024 * 1024)), isFalse);
    });
  });

  test('disconnect is a no-op when never connected', () async {
    await service.disconnect();
    expect(service.isConnected, isFalse);
  });
}
