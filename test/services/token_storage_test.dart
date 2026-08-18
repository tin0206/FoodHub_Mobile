import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodhub_mobile/services/token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TokenStorage storage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = TokenStorage();
  });

  test('readToken returns null when nothing was saved', () async {
    expect(await storage.readToken(), isNull);
  });

  test('saveToken persists the value so readToken can return it', () async {
    await storage.saveToken('abc123');
    expect(await storage.readToken(), 'abc123');
  });

  test('saveToken overwrites a previously saved token', () async {
    await storage.saveToken('first');
    await storage.saveToken('second');
    expect(await storage.readToken(), 'second');
  });

  test('clearToken removes the saved token', () async {
    await storage.saveToken('abc123');
    await storage.clearToken();
    expect(await storage.readToken(), isNull);
  });
}
