@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:foodhub_mobile/services/api_client.dart';
import 'package:foodhub_mobile/services/auth_service.dart';
import 'package:foodhub_mobile/services/favorite_service.dart';
import 'package:foodhub_mobile/services/recipe_service.dart';

import 'test_config.dart';

// FAV-01/02: adding and removing a favorite against the real staging API.
// Uses a throwaway recipe it creates and cleans up itself, and always
// removes the favorite it adds — never touches pre-existing favorites.
//
// Deliberately avoids TestWidgetsFlutterBinding/SharedPreferences mocking in
// favor of an in-memory TokenStorage — see test_config.dart for why.
//
// Run with: flutter test --tags integration
void main() {
  final creds = TestCredentials.load();
  final skip = creds == null
      ? 'No staging credentials configured — copy test/integration/.env.test.example '
          'to test/integration/.env.test and fill in real values.'
      : null;

  late InMemoryTokenStorage tokenStorage;
  late ApiClient api;

  Future<void> signInAsTestUser() => AuthService(apiClient: api, tokenStorage: tokenStorage)
      .signIn(email: creds!.userEmail, password: creds.userPassword, rememberMe: false);

  group('FAV-01 / FAV-02: add and remove a favorite', () {
    int? fixtureRecipeId;
    int? fixtureFavoriteId;

    setUp(() {
      tokenStorage = InMemoryTokenStorage();
      api = ApiClient(tokenStorage: tokenStorage);
      if (creds != null) initApiConfigForTests(creds.apiBaseUrl);
    });

    tearDown(() async {
      if (creds == null) return;
      await signInAsTestUser();
      if (fixtureFavoriteId != null) {
        try {
          await FavoriteService(apiClient: api).deleteFavorite(fixtureFavoriteId!);
        } catch (_) {}
        fixtureFavoriteId = null;
      }
      if (fixtureRecipeId != null) {
        try {
          await RecipeService(apiClient: api).deleteRecipe(fixtureRecipeId!);
        } catch (_) {}
        fixtureRecipeId = null;
      }
    });

    test('adding then removing a favorite round-trips cleanly', () async {
      await signInAsTestUser();

      final recipeService = RecipeService(apiClient: api);
      final recipe = await recipeService.createRecipe(
        title: 'QA FAV fixture ${DateTime.now().millisecondsSinceEpoch}',
        ingredientItems: await fixtureIngredientItems(recipeService),
        directions: const ['Fixture recipe for the favorites integration test'],
      );
      fixtureRecipeId = recipe.id;

      final favorites = FavoriteService(apiClient: api);
      final added = await favorites.addFavorite(recipeId: recipe.id, note: 'qa note');
      fixtureFavoriteId = added.id;

      final list = await favorites.listFavorites();
      expect(list.any((f) => f.id == added.id), isTrue);

      await favorites.deleteFavorite(added.id);
      fixtureFavoriteId = null;

      final listAfterRemoval = await favorites.listFavorites();
      expect(listAfterRemoval.any((f) => f.recipeId == recipe.id), isFalse);
    }, skip: skip);
  });
}
