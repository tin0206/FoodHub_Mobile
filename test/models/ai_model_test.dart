import 'package:flutter_test/flutter_test.dart';
import 'package:foodhub_mobile/models/ai.dart';
import 'package:foodhub_mobile/widgets/recs/markdown_reply.dart';

void main() {
  group('RagRecipeModel.fromJson', () {
    test('reads title and RecipeName like foodhub_web', () {
      final named = RagRecipeModel.fromJson({
        'recipe_id': 12,
        'title': 'Pho Bo',
        'ingredients': ['beef', 'noodles'],
        'directions': ['Boil broth'],
        'estimated_servings': 4,
      });
      expect(named.title, 'Pho Bo');
      expect(named.recipeId, '12');
      expect(named.ingredients, ['beef', 'noodles']);
      expect(named.estimatedServings, 4);

      final fallback = RagRecipeModel.fromJson({'RecipeName': 'Banh Mi'});
      expect(fallback.title, 'Banh Mi');
    });
  });

  group('normalizeRecipeHref', () {
    test('strips /recipes/ and leading slashes', () {
      expect(normalizeRecipeHref('12'), '12');
      expect(normalizeRecipeHref('/12'), '12');
      expect(normalizeRecipeHref('/recipes/12'), '12');
      expect(normalizeRecipeHref('/api/v1/recipes/12?lang=vi'), '12');
      expect(normalizeRecipeHref('https://example.com/recipes/12'), '');
    });
  });

  group('extractRecipeMarkdownLinks', () {
    test('keeps the markdown title and a numeric recipe id', () {
      final extracted = extractRecipeMarkdownLinks(
        'Try [Pho Bo](/recipes/12) tonight.',
      );
      expect(extracted.links, hasLength(1));
      expect(extracted.links.single.title, 'Pho Bo');
      expect(extracted.links.single.recipeId, '12');
    });
  });
}
