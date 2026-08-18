import 'package:flutter_test/flutter_test.dart';
import 'package:foodhub_mobile/models/recipe.dart';

void main() {
  group('RecipeModel.fromJson', () {
    test('parses a full payload', () {
      final recipe = RecipeModel.fromJson({
        'id': 1,
        'title': 'Pho Bo',
        'image_url': 'https://example.com/pho.jpg',
        'ingredients': ['beef', 'rice noodles', 'onion'],
        'directions': ['Boil broth', 'Cook noodles', 'Assemble bowl'],
        'ner': ['beef', 'noodles'],
        'estimated_servings': 4,
        'dietary_restrictions': ['gluten-free'],
        'created_by': 7,
        'visibility': 'public',
        'locale': 'vi',
        'mapped_ingredients': [
          {'mapped_id': 1, 'mapped_name': 'Beef', 'total_grams': 500},
        ],
        'nutrition': {
          'per_serving': {'Calories (kcal)': 320.0, 'Protein (g)': 25.0},
          'total': {'Calories (kcal)': 1280.0},
          'ingredients': [],
        },
      });

      expect(recipe.id, 1);
      expect(recipe.title, 'Pho Bo');
      expect(recipe.name, 'Pho Bo');
      expect(recipe.imageUrl, 'https://example.com/pho.jpg');
      expect(recipe.ingredients, ['beef', 'rice noodles', 'onion']);
      expect(recipe.directions, hasLength(3));
      expect(recipe.dietaryRestrictions, ['gluten-free']);
      expect(recipe.labels, recipe.dietaryRestrictions);
      expect(recipe.isPrivate, isFalse);
      expect(recipe.locale, 'vi');
      expect(recipe.mappedIngredients, hasLength(1));
      expect(recipe.calories, 320);
    });

    test('applies defaults for missing optional fields', () {
      final recipe = RecipeModel.fromJson({'id': 2, 'title': 'Mystery dish'});

      expect(recipe.imageUrl, isNull);
      expect(recipe.ingredients, isEmpty);
      expect(recipe.directions, isEmpty);
      expect(recipe.estimatedServings, isNull);
      expect(recipe.visibility, 'private');
      expect(recipe.isPrivate, isTrue);
      expect(recipe.locale, 'en');
      expect(recipe.nutrition, isNull);
      expect(recipe.calories, isNull);
    });

    test('treats an empty image_url string as absent', () {
      final recipe = RecipeModel.fromJson({
        'id': 3,
        'title': 'No image',
        'image_url': '',
      });

      expect(recipe.imageUrl, isNull);
    });

    test('accepts a single ingredient string instead of a list', () {
      final recipe = RecipeModel.fromJson({
        'id': 4,
        'title': 'Single ingredient',
        'ingredients': 'salt',
      });

      expect(recipe.ingredients, ['salt']);
    });
  });

  group('RecipeModel computed getters', () {
    test('cookingMinutes falls back to 20 when there are no directions', () {
      const recipe = RecipeModel(id: 1, title: 'Empty', directions: []);
      expect(recipe.cookingMinutes, 20);
    });

    test('cookingMinutes scales with step count and clamps to [15, 120]', () {
      const short = RecipeModel(id: 1, title: 'Short', directions: ['a', 'b']);
      expect(short.cookingMinutes, 15); // 2 * 5 = 10, clamped up to 15

      const long = RecipeModel(
        id: 2,
        title: 'Long',
        directions: [
          'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
          'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 'x', 'y', 'z', 'aa', 'ab', 'ac', 'ad', 'ae',
        ],
      );
      expect(long.cookingMinutes, 120); // 26 * 5 = 130, clamped down to 120
    });

    test('ingredientsText and stepsText join with newlines', () {
      const recipe = RecipeModel(
        id: 1,
        title: 'Joined',
        ingredients: ['egg', 'flour'],
        directions: ['Mix', 'Bake'],
      );
      expect(recipe.ingredientsText, 'egg\nflour');
      expect(recipe.stepsText, 'Mix\nBake');
    });

    test('splitLines trims and drops empty lines', () {
      final lines = RecipeModel.splitLines('  egg \n\n flour \n');
      expect(lines, ['egg', 'flour']);
    });
  });
}
