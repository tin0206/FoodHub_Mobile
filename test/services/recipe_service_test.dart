import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:foodhub_mobile/models/ingredient.dart';
import 'package:foodhub_mobile/models/user.dart';
import 'package:foodhub_mobile/services/api_client.dart';
import 'package:foodhub_mobile/services/recipe_service.dart';
import 'package:foodhub_mobile/services/session_service.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient api;
  late RecipeService recipeService;

  setUp(() {
    api = MockApiClient();
    recipeService = RecipeService(apiClient: api);
    SessionService.instance.clear();
  });

  tearDown(() {
    SessionService.instance.clear();
  });

  group('listRecipes', () {
    test('does not add a lang query param when the user has none set', () async {
      when(
        () => api.get('/recipes', query: any(named: 'query'), auth: false),
      ).thenAnswer((_) async => <dynamic>[]);

      await recipeService.listRecipes();

      final query = verify(
        () => api.get('/recipes', query: captureAny(named: 'query'), auth: false),
      ).captured.single as Map<String, String>;
      expect(query, {'skip': '0', 'limit': '50'});
    });

    test('injects the session language when no explicit lang is given', () async {
      SessionService.instance.setUser(
        const UserModel(id: 1, email: 'a@b.com', username: 'a', language: 'vi'),
      );
      when(
        () => api.get('/recipes', query: any(named: 'query'), auth: false),
      ).thenAnswer((_) async => <dynamic>[]);

      await recipeService.listRecipes();

      final query = verify(
        () => api.get('/recipes', query: captureAny(named: 'query'), auth: false),
      ).captured.single as Map<String, String>;
      expect(query['lang'], 'vi');
    });

    test('an explicit lang argument wins over the session language', () async {
      SessionService.instance.setUser(
        const UserModel(id: 1, email: 'a@b.com', username: 'a', language: 'vi'),
      );
      when(
        () => api.get('/recipes', query: any(named: 'query'), auth: false),
      ).thenAnswer((_) async => <dynamic>[]);

      await recipeService.listRecipes(lang: 'en');

      final query = verify(
        () => api.get('/recipes', query: captureAny(named: 'query'), auth: false),
      ).captured.single as Map<String, String>;
      expect(query['lang'], 'en');
    });

    test('mine=true adds the mine flag and requests with auth', () async {
      when(
        () => api.get('/recipes', query: any(named: 'query'), auth: true),
      ).thenAnswer((_) async => <dynamic>[]);

      await recipeService.listRecipes(mine: true);

      final query = verify(
        () => api.get('/recipes', query: captureAny(named: 'query'), auth: true),
      ).captured.single as Map<String, String>;
      expect(query['mine'], 'true');
    });

    test('maps the response into RecipeModel instances', () async {
      when(
        () => api.get('/recipes', query: any(named: 'query'), auth: false),
      ).thenAnswer(
        (_) async => [
          {'id': 1, 'title': 'A'},
          {'id': 2, 'title': 'B'},
        ],
      );

      final recipes = await recipeService.listRecipes();
      expect(recipes.map((r) => r.title), ['A', 'B']);
    });
  });

  group('searchRecipes', () {
    test('parses total_count and the recipe list', () async {
      when(
        () => api.get('/recipes/search', query: any(named: 'query'), auth: false),
      ).thenAnswer(
        (_) async => {
          'total_count': 42,
          'recipes': [
            {'id': 1, 'title': 'Match'},
          ],
        },
      );

      final result = await recipeService.searchRecipes(query: 'pho');

      expect(result.totalCount, 42);
      expect(result.recipes.single.title, 'Match');

      final query = verify(
        () => api.get('/recipes/search', query: captureAny(named: 'query'), auth: false),
      ).captured.single as Map<String, String>;
      expect(query['q'], 'pho');
    });

    test('omits q and dietary_restriction when not provided', () async {
      when(
        () => api.get('/recipes/search', query: any(named: 'query'), auth: false),
      ).thenAnswer((_) async => {'total_count': 0, 'recipes': []});

      await recipeService.searchRecipes();

      final query = verify(
        () => api.get('/recipes/search', query: captureAny(named: 'query'), auth: false),
      ).captured.single as Map<String, String>;
      expect(query.containsKey('q'), isFalse);
      expect(query.containsKey('dietary_restriction'), isFalse);
    });
  });

  group('getRecipe', () {
    test('requests the recipe by id with auth', () async {
      when(
        () => api.get('/recipes/7', query: any(named: 'query'), auth: true),
      ).thenAnswer((_) async => {'id': 7, 'title': 'Detail'});

      final recipe = await recipeService.getRecipe(7);
      expect(recipe.id, 7);
    });
  });

  group('createRecipe', () {
    test('omits estimated_servings and dietary_restrictions when not given', () async {
      when(() => api.post('/recipes', body: any(named: 'body'))).thenAnswer(
        (_) async => {'id': 1, 'title': 'New'},
      );

      await recipeService.createRecipe(
        title: 'New',
        ingredientItems: const [
          IngredientItemInput(mappedId: 1, amount: 2, unit: 'g'),
        ],
        directions: const ['Step 1'],
      );

      final body = verify(
        () => api.post('/recipes', body: captureAny(named: 'body')),
      ).captured.single as Map<String, dynamic>;
      expect(body['title'], 'New');
      expect(body.containsKey('estimated_servings'), isFalse);
      expect(body.containsKey('dietary_restrictions'), isFalse);
      expect(body['ingredient_items'], [
        {'mapped_id': 1, 'amount': 2, 'unit': 'g'},
      ]);
    });

    test('includes estimated_servings and dietary_restrictions when given', () async {
      when(() => api.post('/recipes', body: any(named: 'body'))).thenAnswer(
        (_) async => {'id': 1, 'title': 'New'},
      );

      await recipeService.createRecipe(
        title: 'New',
        ingredientItems: const [],
        directions: const [],
        dietaryRestrictions: const ['vegan'],
        estimatedServings: 4,
      );

      final body = verify(
        () => api.post('/recipes', body: captureAny(named: 'body')),
      ).captured.single as Map<String, dynamic>;
      expect(body['estimated_servings'], 4);
      expect(body['dietary_restrictions'], ['vegan']);
    });
  });

  group('updateRecipe', () {
    test('only includes fields that were explicitly passed', () async {
      when(
        () => api.patch('/recipes/5', body: any(named: 'body'), query: any(named: 'query')),
      ).thenAnswer((_) async => {'id': 5, 'title': 'Updated'});

      await recipeService.updateRecipe(5, title: 'Updated');

      final body = verify(
        () => api.patch(
          '/recipes/5',
          body: captureAny(named: 'body'),
          query: any(named: 'query'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(body, {'title': 'Updated'});
    });
  });

  group('deleteRecipe', () {
    test('calls DELETE on the recipe endpoint', () async {
      when(() => api.delete('/recipes/3')).thenAnswer((_) async {});
      await recipeService.deleteRecipe(3);
      verify(() => api.delete('/recipes/3')).called(1);
    });
  });

  group('searchIngredients', () {
    test('parses the ingredients list', () async {
      when(
        () => api.get('/ingredients/search', query: any(named: 'query')),
      ).thenAnswer(
        (_) async => {
          'ingredients': [
            {'id': 1, 'name': 'egg', 'natural_name': 'Egg'},
          ],
        },
      );

      final hits = await recipeService.searchIngredients('egg');
      expect(hits.single.name, 'egg');
    });
  });

  group('getDietaryRestrictions', () {
    test('returns the restriction list without auth', () async {
      when(
        () => api.get('/recipes/dietary-restrictions', auth: false),
      ).thenAnswer(
        (_) async => {
          'dietary_restrictions': ['vegan', 'keto'],
        },
      );

      final restrictions = await recipeService.getDietaryRestrictions();
      expect(restrictions, ['vegan', 'keto']);
    });
  });

  group('uploadRecipeImage', () {
    test('returns the image_url on success', () async {
      when(
        () => api.postMultipart(
          '/recipes/1/image',
          fieldName: 'file',
          bytes: any(named: 'bytes'),
          filename: any(named: 'filename'),
        ),
      ).thenAnswer((_) async => {'image_url': 'https://x/img.jpg'});

      final url = await recipeService.uploadRecipeImage(1, [1, 2, 3], 'a.jpg');
      expect(url, 'https://x/img.jpg');
    });

    test('swallows errors and returns null instead of throwing', () async {
      when(
        () => api.postMultipart(
          '/recipes/1/image',
          fieldName: 'file',
          bytes: any(named: 'bytes'),
          filename: any(named: 'filename'),
        ),
      ).thenThrow(Exception('upload failed'));

      final url = await recipeService.uploadRecipeImage(1, [1, 2, 3], 'a.jpg');
      expect(url, isNull);
    });
  });
}
