import 'package:flutter/foundation.dart';
import 'package:foodhub_mobile/models/favorite.dart';
import 'package:foodhub_mobile/services/api_client.dart';
import 'package:foodhub_mobile/services/session_service.dart';

class FavoriteService {
  FavoriteService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  /// Increments whenever a favorite is added or removed.
  /// Screens can listen to this to sync their local state.
  static final ValueNotifier<int> changes = ValueNotifier(0);

  Future<List<FavoriteModel>> listFavorites({String? lang}) async {
    final language =
        lang ?? SessionService.instance.currentUser?.language;
    final data = await _api.get(
      '/favorites',
      query: {
        if (language != null && language.isNotEmpty) 'lang': language,
      },
    );
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
    final result = FavoriteModel.fromJson(data as Map<String, dynamic>);
    changes.value++;
    return result;
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
    changes.value++;
  }

  Future<List<TopFavoriteModel>> getTopFavorites({String? lang}) async {
    final language = lang ?? SessionService.instance.currentUser?.language;
    final data = await _api.get(
      '/favorites/top-favorites',
      query: {
        if (language != null && language.isNotEmpty) 'lang': language,
      },
    );
    return (data as List<dynamic>)
        .map((e) => TopFavoriteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
