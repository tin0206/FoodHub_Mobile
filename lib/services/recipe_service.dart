import 'package:foodhub_mobile/models/ingredient.dart';
import 'package:foodhub_mobile/models/recipe.dart';
import 'package:foodhub_mobile/services/api_client.dart';
import 'package:foodhub_mobile/services/session_service.dart';

class RecipeSearchResult {
  const RecipeSearchResult({required this.totalCount, required this.recipes});
  final int totalCount;
  final List<RecipeModel> recipes;
}

class RecipeService {
  RecipeService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  String? get _lang {
    final language = SessionService.instance.currentUser?.language;
    if (language == null || language.isEmpty) return null;
    return language;
  }

  Map<String, String> _withLang(Map<String, String> query) {
    if (!query.containsKey('lang')) {
      final lang = _lang;
      if (lang != null) query['lang'] = lang;
    }
    return query;
  }

  Future<List<RecipeModel>> listRecipes({
    int skip = 0,
    int limit = 50,
    bool mine = false,
    String? lang,
  }) async {
    final data = await _api.get(
      '/recipes',
      query: _withLang({
        'skip': '$skip',
        'limit': '$limit',
        if (mine) 'mine': 'true',
        if (lang != null && lang.isNotEmpty) 'lang': lang,
      }),
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
    String? lang,
  }) async {
    final params = _withLang({'skip': '$skip'});
    if (limit != null) params['limit'] = '$limit';
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (dietaryRestriction != null && dietaryRestriction.isNotEmpty) {
      params['dietary_restriction'] = dietaryRestriction;
    }
    if (mine) params['mine'] = 'true';
    if (lang != null && lang.isNotEmpty) params['lang'] = lang;

    final data = await _api.get('/recipes/search', query: params, auth: mine);
    final map = data as Map<String, dynamic>;
    return RecipeSearchResult(
      totalCount: map['total_count'] as int,
      recipes: (map['recipes'] as List<dynamic>)
          .map((e) => RecipeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<RecipeModel> getRecipe(int id, {String? lang}) async {
    final data = await _api.get(
      '/recipes/$id',
      query: _withLang({
        if (lang != null && lang.isNotEmpty) 'lang': lang,
      }),
      auth: true,
    );
    return RecipeModel.fromJson(data as Map<String, dynamic>);
  }

  Future<RecipeModel> createRecipe({
    required String title,
    required List<String> ingredients,
    required List<String> directions,
    List<String>? dietaryRestrictions,
    int? estimatedServings,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'ingredients': ingredients,
      'directions': directions,
      if (dietaryRestrictions != null && dietaryRestrictions.isNotEmpty)
        'dietary_restrictions': dietaryRestrictions,
      if (estimatedServings != null) 'estimated_servings': estimatedServings,
    };

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
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (ingredients != null) body['ingredients'] = ingredients;
    if (directions != null) body['directions'] = directions;
    if (dietaryRestrictions != null) {
      body['dietary_restrictions'] = dietaryRestrictions;
    }
    if (estimatedServings != null) {
      body['estimated_servings'] = estimatedServings;
    }

    final data = await _api.patch(
      '/recipes/$id',
      body: body,
      query: _withLang({}),
    );
    return RecipeModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<IngredientHit>> searchIngredients(String query, {int limit = 8}) async {
    final data = await _api.get(
      '/ingredients/search',
      query: {
        'q': query,
        'limit': '$limit',
      },
    );
    final map = data as Map<String, dynamic>;
    return (map['ingredients'] as List<dynamic>? ?? [])
        .map((e) => IngredientHit.fromJson(e as Map<String, dynamic>))
        .toList();
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
