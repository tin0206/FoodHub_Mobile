import 'package:flutter_test/flutter_test.dart';
import 'package:foodhub_mobile/models/ingredient.dart';

void main() {
  group('IngredientHit.fromJson', () {
    test('parses nested units', () {
      final hit = IngredientHit.fromJson({
        'id': 5,
        'name': 'chicken breast',
        'natural_name': 'Chicken Breast',
        'units': [
          {'unit': 'g', 'grams_per_unit': 1},
          {'unit': 'piece', 'grams_per_unit': 174},
        ],
      });

      expect(hit.id, 5);
      expect(hit.units, hasLength(2));
      expect(hit.units.last.unit, 'piece');
      expect(hit.units.last.gramsPerUnit, 174);
    });

    test('defaults units to an empty list when absent', () {
      final hit = IngredientHit.fromJson({
        'id': 1,
        'name': 'salt',
        'natural_name': 'Salt',
      });
      expect(hit.units, isEmpty);
    });
  });

  group('IngredientItemInput.toJson', () {
    test('serializes to the API shape', () {
      const input = IngredientItemInput(mappedId: 3, amount: 2.5, unit: 'cup');
      expect(input.toJson(), {'mapped_id': 3, 'amount': 2.5, 'unit': 'cup'});
    });
  });

  group('RecipeNutrition', () {
    test('exposes macro getters and sorted extras', () {
      final nutrition = RecipeNutrition.fromJson({
        'per_serving': {
          RecipeNutrition.kcalKey: 250.0,
          RecipeNutrition.proteinKey: 20.0,
          'Sodium (mg)': 400.0,
          'Fiber (g)': 5.0,
        },
        'total': {RecipeNutrition.kcalKey: 1000.0},
        'ingredients': [],
      });

      expect(nutrition.kcalPerServing, 250.0);
      expect(nutrition.proteinPerServing, 20.0);
      expect(nutrition.carbsPerServing, isNull);
      expect(
        nutrition.extraPerServing.map((e) => e.key),
        ['Fiber (g)', 'Sodium (mg)'],
      );
    });

    test('ignores non-numeric nutrient values', () {
      final nutrition = RecipeNutrition.fromJson({
        'per_serving': {'Calories (kcal)': 'n/a'},
      });
      expect(nutrition.perServing, isEmpty);
    });
  });

  group('SelectedCatalogIngredient', () {
    test('fromHit falls back to a default gram unit when none exist', () {
      final hit = IngredientHit.fromJson({
        'id': 1,
        'name': 'water',
        'natural_name': 'Water',
      });
      final selected = SelectedCatalogIngredient.fromHit(hit);

      expect(selected.unit, 'g');
      expect(selected.amount, 1);
      expect(selected.units, hasLength(1));
    });

    test('fromMapped uses the mapped amount/unit when valid', () {
      final mapped = MappedIngredient.fromJson({
        'mapped_id': 9,
        'mapped_name': 'Rice',
        'amount': 3,
        'unit': 'cup',
      });
      final selected = SelectedCatalogIngredient.fromMapped(mapped);

      expect(selected.amount, 3);
      expect(selected.unit, 'cup');
      expect(selected.displayName, 'Rice');
    });

    test('fromMapped defaults to 1 gram when amount is missing or zero', () {
      final mapped = MappedIngredient.fromJson({
        'mapped_id': 9,
        'mapped_name': 'Rice',
        'amount': 0,
      });
      final selected = SelectedCatalogIngredient.fromMapped(mapped);

      expect(selected.amount, 1);
      expect(selected.unit, 'g');
    });

    test('copyWith overrides only the given fields', () {
      final hit = IngredientHit.fromJson({
        'id': 1,
        'name': 'water',
        'natural_name': 'Water',
      });
      final selected = SelectedCatalogIngredient.fromHit(hit);
      final updated = selected.copyWith(amount: 2);

      expect(updated.amount, 2);
      expect(updated.unit, selected.unit);
      expect(updated.id, selected.id);
    });
  });
}
