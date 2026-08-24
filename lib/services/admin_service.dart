import 'package:foodhub_mobile/models/admin.dart';
import 'package:foodhub_mobile/models/aisle_mapping.dart';
import 'package:foodhub_mobile/models/recipe.dart';
import 'package:foodhub_mobile/models/user.dart';
import 'package:foodhub_mobile/services/api_client.dart';

class AdminService {
  AdminService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  // ── Aisle mapping ─────────────────────────────────────────────────────────

  Future<AisleMappingStatus> aisleStatus() async {
    final data = await _api.get('/admin/recipes/aisles');
    return AisleMappingStatus.fromJson(data as Map<String, dynamic>);
  }

  Future<AisleMappingStatus> mapAisles({bool force = false, int? recipeId}) async {
    final body = <String, dynamic>{'force': force};
    if (recipeId != null) body['recipe_id'] = recipeId;
    final data = await _api.post('/admin/recipes/map-aisles', body: body);
    return AisleMappingStatus.fromJson(data as Map<String, dynamic>);
  }

  Future<AisleMappingStatus> stopMapAisles() async {
    final data = await _api.post('/admin/recipes/map-aisles/stop');
    return AisleMappingStatus.fromJson(data as Map<String, dynamic>);
  }

  // ── Overview ──────────────────────────────────────────────────────────────

  Future<AdminOverview> getOverview() async {
    final data = await _api.get('/admin/overview');
    return AdminOverview.fromJson(data as Map<String, dynamic>);
  }

  // ── Analytics ─────────────────────────────────────────────────────────────

  Future<AdminAnalytics> getAnalytics() async {
    final data = await _api.get('/admin/analytics');
    return AdminAnalytics.fromJson(data as Map<String, dynamic>);
  }

  // ── Recipes ───────────────────────────────────────────────────────────────

  Future<List<RecipeModel>> listRecipes({
    int skip = 0,
    int limit = 21,
    String? visibility,
    String? q,
    String? lang,
  }) async {
    final query = <String, String>{
      'skip': '$skip',
      'limit': '$limit',
      if (visibility != null && visibility.isNotEmpty) 'visibility': visibility,
      if (q != null && q.isNotEmpty) 'q': q,
      if (lang != null && lang.isNotEmpty) 'lang': lang,
    };
    final data = await _api.get('/admin/recipes', query: query);
    final list = data as List? ?? [];
    return list
        .whereType<Map>()
        .map((e) => RecipeModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<RecipeModel> getRecipe(int id, {String? lang}) async {
    final query = lang != null ? {'lang': lang} : null;
    final data = await _api.get('/recipes/$id', query: query);
    return RecipeModel.fromJson(data as Map<String, dynamic>);
  }

  Future<RecipeModel> createRecipe({
    required String title,
    required List<String> ingredients,
    required List<String> directions,
    List<String>? dietaryRestrictions,
    int? estimatedServings,
    String? imageUrl,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'ingredients': ingredients,
      'directions': directions,
      if (dietaryRestrictions != null) 'dietary_restrictions': dietaryRestrictions,
      if (estimatedServings != null) 'estimated_servings': estimatedServings,
      if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
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
    String? imageUrl,
  }) async {
    final body = <String, dynamic>{
      if (title != null) 'title': title,
      if (ingredients != null) 'ingredients': ingredients,
      if (directions != null) 'directions': directions,
      if (dietaryRestrictions != null) 'dietary_restrictions': dietaryRestrictions,
      if (estimatedServings != null) 'estimated_servings': estimatedServings,
      if (imageUrl != null) 'image_url': imageUrl,
    };
    final data = await _api.patch('/recipes/$id', body: body);
    return RecipeModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteRecipe(int id) async {
    await _api.delete('/recipes/$id');
  }

  Future<RecipeModel> setRecipeVisibility(int id, String visibility) async {
    final data = await _api.patch(
      '/admin/recipes/$id/visibility',
      body: {'visibility': visibility},
    );
    return RecipeModel.fromJson(data as Map<String, dynamic>);
  }

  // ── Translations ──────────────────────────────────────────────────────────

  Future<List<RecipeTranslation>> getTranslations(int recipeId) async {
    final data = await _api.get('/admin/recipes/$recipeId/translations');
    final list = data as List? ?? [];
    return list
        .whereType<Map>()
        .map((e) => RecipeTranslation.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<RecipeTranslation> saveTranslation(
    int recipeId,
    String locale,
    RecipeTranslation translation,
  ) async {
    final data = await _api.put(
      '/admin/recipes/$recipeId/translations/$locale',
      body: translation.toJson(),
    );
    return RecipeTranslation.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteTranslation(int recipeId, String locale) async {
    await _api.delete('/admin/recipes/$recipeId/translations/$locale');
  }

  // ── Users ─────────────────────────────────────────────────────────────────

  Future<List<UserModel>> listUsers({
    int skip = 0,
    int limit = 21,
    String? q,
    String? role,
    bool? active,
  }) async {
    final query = <String, String>{
      'skip': '$skip',
      'limit': '$limit',
      if (q != null && q.isNotEmpty) 'q': q,
      if (role != null && role.isNotEmpty) 'role': role,
      if (active != null) 'active': '$active',
    };
    final data = await _api.get('/admin/users', query: query);
    final list = data as List? ?? [];
    return list
        .whereType<Map>()
        .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<AdminUserDetail> getUserDetail(int id) async {
    final data = await _api.get('/admin/users/$id');
    return AdminUserDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<List<RecipeModel>> getUserRecipes(int userId) async {
    final data = await _api.get('/admin/users/$userId/recipes');
    final list = data as List? ?? [];
    return list
        .whereType<Map>()
        .map((e) => RecipeModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<RecipeModel>> getUserFavorites(int userId) async {
    final data = await _api.get('/admin/users/$userId/favorites');
    final list = data as List? ?? [];
    return list
        .whereType<Map>()
        .map((e) => RecipeModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<UserModel> updateUser(int id, Map<String, dynamic> fields) async {
    final data = await _api.patch('/admin/users/$id', body: fields);
    return UserModel.fromJson(data as Map<String, dynamic>);
  }

  Future<UserModel> createUser(Map<String, dynamic> fields) async {
    final data = await _api.post('/admin/users', body: fields);
    return UserModel.fromJson(data as Map<String, dynamic>);
  }
}
