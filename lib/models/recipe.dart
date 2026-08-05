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

  bool get isPrivate => visibility == 'private';

  String get name => title;

  List<String> get labels => dietaryRestrictions;

  int get cookingMinutes {
    if (directions.isEmpty) return 20;
    return (directions.length * 5).clamp(15, 120);
  }

  int get calories {
    final servings = estimatedServings ?? 2;
    return servings * 200;
  }

  String get ingredientsText => ingredients.join('\n');

  String get stepsText => directions.join('\n');

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    final rawImageUrl = json['image_url'] as String?;
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
    );
  }

  Map<String, dynamic> toCreateJson({
    required String title,
    required List<String> ingredients,
    required List<String> directions,
    List<String>? dietaryRestrictions,
    int? estimatedServings,
  }) {
    return {
      'title': title,
      'ingredients': ingredients,
      'directions': directions,
      if (dietaryRestrictions != null && dietaryRestrictions.isNotEmpty)
        'dietary_restrictions': dietaryRestrictions,
      if (estimatedServings != null) 'estimated_servings': estimatedServings,
    };
  }

  Map<String, dynamic> toUpdateJson({
    String? title,
    List<String>? ingredients,
    List<String>? directions,
    List<String>? dietaryRestrictions,
    int? estimatedServings,
  }) {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (ingredients != null) data['ingredients'] = ingredients;
    if (directions != null) data['directions'] = directions;
    if (dietaryRestrictions != null) {
      data['dietary_restrictions'] = dietaryRestrictions;
    }
    if (estimatedServings != null) {
      data['estimated_servings'] = estimatedServings;
    }
    return data;
  }

  RecipeDetailData toDetailData() {
    return RecipeDetailData(
      id: id,
      name: title,
      imageUrl: imageUrl,
      cookingMinutes: cookingMinutes,
      calories: calories,
      ingredients: ingredientsText,
      steps: stepsText,
      labels: dietaryRestrictions,
      isPrivate: isPrivate,
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
