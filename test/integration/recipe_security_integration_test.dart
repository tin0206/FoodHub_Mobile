@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:foodhub_mobile/services/api_client.dart';
import 'package:foodhub_mobile/services/api_exception.dart';
import 'package:foodhub_mobile/services/auth_service.dart';
import 'package:foodhub_mobile/services/recipe_service.dart';

import 'test_config.dart';

// RCP-08: a user must not be able to edit or delete a recipe owned by
// someone else. Verified PASSING against the real staging API on
// 2026-08-18 for recipes with a real owner (created_by set) — the server
// correctly rejects a non-owner's PATCH/DELETE.
//
// NOTE — corrected after reviewing the real `update_recipe` handler: a
// recipe with created_by = null (unowned/system-seeded, e.g. id 7401) isn't
// actually mutated when a non-owner PATCHes it. `_is_shared_catalog(recipe)`
// forks it into a brand-new private recipe owned by the caller instead
// ("copy on write" for catalog content) — the original is untouched. This
// is intentional, not a security bug; confirmed by re-fetching 7401
// afterwards (unchanged) and finding the two forked copies under the test
// user's own account (since deleted). Two real gaps worth a product/backend
// decision, not security bugs: (1) that clone branch runs unconditionally,
// even for a no-op PATCH, creating a disposable duplicate every time; (2)
// there's no link back to the original and no reuse of an already-forked
// copy, so repeated edits pile up disconnected duplicates. Not exercised
// here since the public API can't produce a created_by = null fixture to
// test against safely.
//
// Uses a throwaway recipe created (and always cleaned up) by the admin
// account, so it never touches pre-existing seeded data.
//
// Deliberately uses an in-memory TokenStorage instead of
// TestWidgetsFlutterBinding/SharedPreferences mocking — that binding fakes
// every HTTP response as a 400 with no real network call. See
// test_config.dart for details.
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

  AuthService authService() => AuthService(apiClient: api, tokenStorage: tokenStorage);
  RecipeService recipeService() => RecipeService(apiClient: api);

  Future<void> signInAs(String email, String password) =>
      authService().signIn(email: email, password: password, rememberMe: false);

  group('RCP-08: recipe ownership must be enforced by the API', () {
    int? fixtureRecipeId;

    setUp(() {
      tokenStorage = InMemoryTokenStorage();
      api = ApiClient(tokenStorage: tokenStorage);
      if (creds != null) initApiConfigForTests(creds.apiBaseUrl);
    });

    tearDown(() async {
      final id = fixtureRecipeId;
      if (id == null || creds == null) return;
      fixtureRecipeId = null;
      try {
        await signInAs(creds.adminEmail, creds.adminPassword);
        await recipeService().deleteRecipe(id);
      } catch (_) {
        // Best-effort cleanup; a failed delete here shouldn't mask the
        // actual test result.
      }
    });

    test('a non-owner cannot PATCH a recipe owned by another user', () async {
      // Admin creates a disposable fixture recipe it owns.
      await signInAs(creds!.adminEmail, creds.adminPassword);
      final admin = recipeService();
      final fixture = await admin.createRecipe(
        title: 'QA RCP-08 fixture ${DateTime.now().millisecondsSinceEpoch}',
        ingredients: fixtureIngredients,
        directions: const ['Do not edit me — automated ownership test fixture'],
      );
      fixtureRecipeId = fixture.id;

      // The normal test user (not the owner) tries to edit it.
      await signInAs(creds.userEmail, creds.userPassword);

      await expectLater(
        recipeService().updateRecipe(fixture.id, title: 'Hijacked by a non-owner'),
        throwsA(isA<ApiException>()),
      );
    }, skip: skip);

    test('a non-owner cannot DELETE a recipe owned by another user', () async {
      await signInAs(creds!.adminEmail, creds.adminPassword);
      final admin = recipeService();
      final fixture = await admin.createRecipe(
        title: 'QA RCP-08 fixture ${DateTime.now().millisecondsSinceEpoch}',
        ingredients: fixtureIngredients,
        directions: const ['Do not delete me — automated ownership test fixture'],
      );
      fixtureRecipeId = fixture.id;

      await signInAs(creds.userEmail, creds.userPassword);

      await expectLater(
        recipeService().deleteRecipe(fixture.id),
        throwsA(isA<ApiException>()),
      );
    }, skip: skip);
  });

  group('RCP-05 / RCP-06 / RCP-07: an owner can manage their own recipe', () {
    setUp(() {
      tokenStorage = InMemoryTokenStorage();
      api = ApiClient(tokenStorage: tokenStorage);
      if (creds != null) initApiConfigForTests(creds.apiBaseUrl);
    });

    test('full create → edit → delete lifecycle works end to end for the owner', () async {
      await signInAs(creds!.userEmail, creds.userPassword);
      final recipes = recipeService();

      final created = await recipes.createRecipe(
        title: 'QA RCP-05/06/07 fixture ${DateTime.now().millisecondsSinceEpoch}',
        ingredients: fixtureIngredients,
        directions: const ['Step one'],
      );

      final updated = await recipes.updateRecipe(created.id, title: 'QA fixture (edited)');
      expect(updated.title, 'QA fixture (edited)');

      await recipes.deleteRecipe(created.id);

      await expectLater(recipes.getRecipe(created.id), throwsA(isA<ApiException>()));
    }, skip: skip);
  });
}
