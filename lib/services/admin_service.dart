import 'package:foodhub_mobile/models/aisle_mapping.dart';
import 'package:foodhub_mobile/services/api_client.dart';

class AdminService {
  AdminService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<AisleMappingStatus> aisleStatus() async {
    final data = await _api.get('/admin/recipes/aisles');
    return AisleMappingStatus.fromJson(data as Map<String, dynamic>);
  }

  Future<AisleMappingStatus> mapAisles({bool force = false, int? recipeId}) async {
    final data = await _api.post(
      '/admin/recipes/map-aisles',
      body: {
        'force': force,
        'recipe_id': ?recipeId,
      },
    );
    return AisleMappingStatus.fromJson(data as Map<String, dynamic>);
  }

  Future<AisleMappingStatus> stopMapAisles() async {
    final data = await _api.post('/admin/recipes/map-aisles/stop');
    return AisleMappingStatus.fromJson(data as Map<String, dynamic>);
  }
}
