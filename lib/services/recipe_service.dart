import 'package:foodhub_mobile/models/recipe.dart';
import 'package:foodhub_mobile/services/api_client.dart';

class RecipeService {
  RecipeService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<RecipeModel>> listRecipes({int skip = 0, int limit = 50}) async {
    final data = await _api.get(
      '/recipes',
      query: {'skip': '$skip', 'limit': '$limit'},
      auth: false,
    );
    return (data as List<dynamic>)
        .map((e) => RecipeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RecipeModel>> searchRecipes({
    String? query,
    String? dietaryRestriction,
    int skip = 0,
    int limit = 50,
  }) async {
    final params = <String, String>{
      'skip': '$skip',
      'limit': '$limit',
    };
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (dietaryRestriction != null && dietaryRestriction.isNotEmpty) {
      params['dietary_restriction'] = dietaryRestriction;
    }

    final data = await _api.get('/recipes/search', query: params, auth: false);
    return (data as List<dynamic>)
        .map((e) => RecipeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RecipeModel> getRecipe(int id) async {
    final data = await _api.get('/recipes/$id', auth: false);
    return RecipeModel.fromJson(data as Map<String, dynamic>);
  }

  Future<RecipeModel> createRecipe({
    required String title,
    required List<String> ingredients,
    required List<String> directions,
    List<String>? dietaryRestrictions,
    int? estimatedServings,
  }) async {
    final body = RecipeModel(
      id: 0,
      title: title,
    ).toCreateJson(
      title: title,
      ingredients: ingredients,
      directions: directions,
      dietaryRestrictions: dietaryRestrictions,
      estimatedServings: estimatedServings,
    );

    final data = await _api.post('/recipes', body: body);
    return RecipeModel.fromJson(data as Map<String, dynamic>);
  }

  Future<RecipeModel> updateRecipe(
    int id, {
    List<String>? ingredients,
    List<String>? directions,
    List<String>? dietaryRestrictions,
    int? estimatedServings,
  }) async {
    final body = RecipeModel(id: 0, title: '').toUpdateJson(
      ingredients: ingredients,
      directions: directions,
      dietaryRestrictions: dietaryRestrictions,
      estimatedServings: estimatedServings,
    );

    final data = await _api.patch('/recipes/$id', body: body);
    return RecipeModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteRecipe(int id) async {
    await _api.delete('/recipes/$id');
  }
}
