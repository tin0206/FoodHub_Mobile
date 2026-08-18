import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:foodhub_mobile/models/ingredient.dart';
import 'package:foodhub_mobile/services/recipe_service.dart';
import 'package:foodhub_mobile/services/token_storage.dart';

/// Staging credentials for live-backend integration tests.
///
/// Loaded from (in priority order): process environment variables, then the
/// gitignored `test/integration/.env.test` file. Returns null via [load]
/// when neither source has all the required values, so tests can skip
/// gracefully on machines that don't have staging credentials configured
/// (e.g. a contributor's laptop or a CI runner without secrets).
class TestCredentials {
  const TestCredentials({
    required this.apiBaseUrl,
    required this.userEmail,
    required this.userPassword,
    required this.adminEmail,
    required this.adminPassword,
  });

  final String apiBaseUrl;
  final String userEmail;
  final String userPassword;
  final String adminEmail;
  final String adminPassword;

  static TestCredentials? _cached;
  static bool _loaded = false;

  static TestCredentials? load() {
    if (_loaded) return _cached;
    _loaded = true;

    final fileValues = _readKeyValueFile('test/integration/.env.test');
    String? pick(String key) => Platform.environment[key] ?? fileValues[key];

    final apiBaseUrl =
        Platform.environment['API_BASE_URL'] ?? _readRootApiBaseUrl();
    final userEmail = pick('TEST_USER_EMAIL');
    final userPassword = pick('TEST_USER_PASSWORD');
    final adminEmail = pick('TEST_ADMIN_EMAIL');
    final adminPassword = pick('TEST_ADMIN_PASSWORD');

    if (apiBaseUrl == null ||
        apiBaseUrl.isEmpty ||
        userEmail == null ||
        userEmail.isEmpty ||
        userPassword == null ||
        userPassword.isEmpty ||
        adminEmail == null ||
        adminEmail.isEmpty ||
        adminPassword == null ||
        adminPassword.isEmpty) {
      return null;
    }

    return _cached = TestCredentials(
      apiBaseUrl: apiBaseUrl,
      userEmail: userEmail,
      userPassword: userPassword,
      adminEmail: adminEmail,
      adminPassword: adminPassword,
    );
  }

  static Map<String, String> _readKeyValueFile(String path) {
    final file = File(path);
    if (!file.existsSync()) return const {};
    final result = <String, String>{};
    for (final rawLine in file.readAsLinesSync()) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final idx = line.indexOf('=');
      if (idx <= 0) continue;
      result[line.substring(0, idx).trim()] = line.substring(idx + 1).trim();
    }
    return result;
  }

  static String? _readRootApiBaseUrl() =>
      _readKeyValueFile('.env')['API_BASE_URL'];
}

/// Points [ApiConfig.baseUrl] (and therefore every real service under test)
/// at the staging API for the duration of this test isolate. Synchronous —
/// no asset bundle involved, so nothing needs to be declared in pubspec.yaml.
void initApiConfigForTests(String baseUrl) {
  dotenv.loadFromString(envString: 'API_BASE_URL=$baseUrl');
}

/// An in-memory stand-in for [TokenStorage] (which normally persists to
/// SharedPreferences). Using this instead means these tests never need
/// `TestWidgetsFlutterBinding`/plugin mocking — which matters here because
/// that binding installs an `HttpOverrides` that fakes every HTTP response
/// as a 400 with no real network call. Plain Dart test + this fake keeps
/// requests going out over the real network to the staging API.
///
/// Share a single instance across every service constructed in a test
/// (`ApiClient`, `AuthService`, ...) so a token saved by one is visible to
/// the others — mirroring how the real app shares one token store.
class InMemoryTokenStorage implements TokenStorage {
  String? _token;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> clearToken() async => _token = null;
}

/// The real /recipes API requires at least one ingredient item. Looks up a
/// real catalog ingredient (rather than hardcoding an id, which could go
/// stale) so fixture recipes created by the integration tests pass
/// validation.
Future<List<IngredientItemInput>> fixtureIngredientItems(
  RecipeService recipeService,
) async {
  final hits = await recipeService.searchIngredients('salt', limit: 1);
  if (hits.isEmpty) {
    throw StateError('No ingredient matched "salt" in the catalog — cannot build a fixture recipe.');
  }
  final unit = hits.first.units.isNotEmpty ? hits.first.units.first.unit : 'g';
  return [IngredientItemInput(mappedId: hits.first.id, amount: 1, unit: unit)];
}
