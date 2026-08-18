import 'package:foodhub_mobile/models/ingredient.dart';
import 'package:foodhub_mobile/widgets/recipe_detail_view.dart';

class RecipeModel {
  const RecipeModel({
    required this.id,
    required this.title,
    this.imageUrl,
    this.ingredients = const [],
    this.directions = const [],
    this.ner = const [],
    this.estimatedServings,
    this.dietaryRestrictions = const [],
    this.createdBy,
    this.visibility = 'private',
    this.locale = 'en',
    this.mappedIngredients = const [],
    this.nutrition,
  });

  final int id;
  final String title;
  final String? imageUrl;
  final List<String> ingredients;
  final List<String> directions;
  final List<String> ner;
  final int? estimatedServings;
  final List<String> dietaryRestrictions;
  final int? createdBy;
  final String visibility;
  final String locale;
  final List<MappedIngredient> mappedIngredients;
  final RecipeNutrition? nutrition;

  bool get isPrivate => visibility == 'private';

  String get name => title;

  List<String> get labels => dietaryRestrictions;

  int get cookingMinutes {
    final steps = directions.isEmpty ? 1 : directions.length;
    final ingredientCount = ingredients.isEmpty ? 1 : ingredients.length;
    return (8 * steps + 2 * ingredientCount).clamp(10, 120);
  }

  int? get calories {
    final kcal = nutrition?.kcalPerServing;
    if (kcal == null) return null;
    return kcal.round();
  }

  String get ingredientsText => ingredients.join('\n');

  String get stepsText => directions.join('\n');

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    final rawImageUrl = json['image_url'] as String?;
    RecipeNutrition? nutrition;
    final rawNutrition = json['nutrition'];
    if (rawNutrition is Map<String, dynamic>) {
      nutrition = RecipeNutrition.fromJson(rawNutrition);
    }
    return RecipeModel(
      id: json['id'] as int,
      title: json['title'] as String,
      imageUrl: rawImageUrl != null && rawImageUrl.isNotEmpty
          ? rawImageUrl
          : null,
      ingredients: _parseStringList(json['ingredients']),
      directions: _parseStringList(json['directions']),
      ner: _parseStringList(json['ner']),
      estimatedServings: json['estimated_servings'] as int?,
      dietaryRestrictions: _parseStringList(json['dietary_restrictions']),
      createdBy: json['created_by'] as int?,
      visibility: (json['visibility'] as String?) ?? 'private',
      locale: (json['locale'] as String?) ?? 'en',
      mappedIngredients: [
        for (final item in json['mapped_ingredients'] as List<dynamic>? ?? [])
          if (item is Map)
            MappedIngredient.fromJson(Map<String, dynamic>.from(item)),
      ],
      nutrition: nutrition,
    );
  }

  RecipeDetailData toDetailData() {
    return RecipeDetailData(
      id: id,
      name: title,
      imageUrl: imageUrl,
      cookingMinutes: cookingMinutes,
      calories: calories,
      estimatedServings: estimatedServings,
      ingredients: ingredientsText,
      steps: stepsText,
      labels: dietaryRestrictions,
      isPrivate: isPrivate,
      mappedIngredients: mappedIngredients,
      nutrition: nutrition,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return const [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String && value.isNotEmpty) return [value];
    return const [];
  }

  static List<String> splitLines(String text) {
    return text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
