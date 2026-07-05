import 'package:foodhub_mobile/models/recipe.dart';

class FavoriteModel {
  const FavoriteModel({
    required this.id,
    required this.recipeId,
    required this.recipe,
    this.note,
  });

  final int id;
  final int recipeId;
  final String? note;
  final RecipeModel recipe;

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['id'] as int,
      recipeId: json['recipe_id'] as int,
      note: json['note'] as String?,
      recipe: RecipeModel.fromJson(json['recipe'] as Map<String, dynamic>),
    );
  }
}
