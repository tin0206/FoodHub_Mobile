import 'package:foodhub_mobile/models/favorite.dart';
import 'package:foodhub_mobile/services/api_client.dart';

class FavoriteService {
  FavoriteService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<FavoriteModel>> listFavorites() async {
    final data = await _api.get('/favorites');
    return (data as List<dynamic>)
        .map((e) => FavoriteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FavoriteModel> addFavorite({required int recipeId, String? note}) async {
    final data = await _api.post(
      '/favorites',
      body: {
        'recipe_id': recipeId,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return FavoriteModel.fromJson(data as Map<String, dynamic>);
  }

  Future<FavoriteModel> updateFavorite({
    required int favoriteId,
    String? note,
  }) async {
    final data = await _api.patch(
      '/favorites/$favoriteId',
      body: {'note': note},
    );
    return FavoriteModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteFavorite(int favoriteId) async {
    await _api.delete('/favorites/$favoriteId');
  }
}
