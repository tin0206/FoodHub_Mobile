import 'package:foodhub_mobile/models/recipe.dart';
import 'package:foodhub_mobile/services/api_client.dart';

class RecipeSearchResult {
  const RecipeSearchResult({required this.totalCount, required this.recipes});
  final int totalCount;
  final List<RecipeModel> recipes;
}

class RecipeService {
  RecipeService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<RecipeModel>> listRecipes({
    int skip = 0,
    int limit = 50,
    bool mine = false,
  }) async {
    final data = await _api.get(
      '/recipes',
      query: {'skip': '$skip', 'limit': '$limit', if (mine) 'mine': 'true'},
      auth: mine,
    );
    return (data as List<dynamic>)
        .map((e) => RecipeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RecipeSearchResult> searchRecipes({
    String? query,
    String? dietaryRestriction,
    int skip = 0,
    int? limit = 50,
    bool mine = false,
  }) async {
    final params = <String, String>{'skip': '$skip'};
    if (limit != null) params['limit'] = '$limit';
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (dietaryRestriction != null && dietaryRestriction.isNotEmpty) {
      params['dietary_restriction'] = dietaryRestriction;
    }
    if (mine) params['mine'] = 'true';

    final data = await _api.get('/recipes/search', query: params, auth: mine);
    final map = data as Map<String, dynamic>;
    return RecipeSearchResult(
      totalCount: map['total_count'] as int,
      recipes: (map['recipes'] as List<dynamic>)
          .map((e) => RecipeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<RecipeModel> getRecipe(int id) async {
    final data = await _api.get('/recipes/$id', auth: true);
    return RecipeModel.fromJson(data as Map<String, dynamic>);
  }

  Future<RecipeModel> createRecipe({
    required String title,
    required List<String> ingredients,
    required List<String> directions,
    List<String>? dietaryRestrictions,
    int? estimatedServings,
  }) async {
    final body = RecipeModel(id: 0, title: title).toCreateJson(
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
    String? title,
    List<String>? ingredients,
    List<String>? directions,
    List<String>? dietaryRestrictions,
    int? estimatedServings,
  }) async {
    final body = RecipeModel(id: 0, title: '').toUpdateJson(
      title: title,
      ingredients: ingredients,
      directions: directions,
      dietaryRestrictions: dietaryRestrictions,
      estimatedServings: estimatedServings,
    );

    final data = await _api.patch('/recipes/$id', body: body);
    return RecipeModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<String>> getDietaryRestrictions() async {
    final data = await _api.get('/recipes/dietary-restrictions', auth: false);
    final map = data as Map<String, dynamic>;
    return (map['dietary_restrictions'] as List<dynamic>).cast<String>();
  }

  Future<void> deleteRecipe(int id) async {
    await _api.delete('/recipes/$id');
  }

  Future<String?> uploadRecipeImage(
    int id,
    List<int> bytes,
    String filename,
  ) async {
    try {
      final data = await _api.postMultipart(
        '/recipes/$id/image',
        fieldName: 'file',
        bytes: bytes,
        filename: filename,
      );
      if (data is Map<String, dynamic>) {
        return data['image_url'] as String?;
      }
    } catch (_) {}
    return null;
  }
}
