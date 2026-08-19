import 'package:foodhub_mobile/models/recipe.dart';

class TopFavoriteModel {
  const TopFavoriteModel({
    required this.recipeId,
    required this.recipe,
    required this.favoriteCount,
  });

  final int recipeId;
  final RecipeModel recipe;
  final int favoriteCount;

  factory TopFavoriteModel.fromJson(Map<String, dynamic> json) {
    return TopFavoriteModel(
      recipeId: json['recipe_id'] as int,
      recipe: RecipeModel.fromJson(json['recipe'] as Map<String, dynamic>),
      favoriteCount: json['favorite_count'] as int,
    );
  }
}

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
