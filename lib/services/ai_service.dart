import 'package:foodhub_mobile/models/ai.dart';
import 'package:foodhub_mobile/services/api_client.dart';

class AiService {
  AiService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<ChatResponseModel> chat({
    required String message,
    List<ChatMessageModel> conversationHistory = const [],
    List<String> dietaryRestrictions = const [],
    String? primaryGoal,
    List<String> ingredients = const [],
  }) async {
    final data = await _api.post(
      '/ai/chat',
      body: {
        'message': message,
        'conversation_history':
            conversationHistory.map((m) => m.toJson()).toList(),
        'dietary_restrictions': dietaryRestrictions,
        if (primaryGoal != null && primaryGoal.isNotEmpty)
          'primary_goal': primaryGoal,
        'ingredients': ingredients,
      },
    );
    return ChatResponseModel.fromJson(data as Map<String, dynamic>);
  }

  Future<DishRecognitionModel> recognizeDish({
    required List<int> bytes,
    required String filename,
    String contentType = 'image/jpeg',
  }) async {
    final data = await _api.postMultipart(
      '/ai/dish-recognition',
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
    return DishRecognitionModel.fromJson(data as Map<String, dynamic>);
  }

  Future<IngredientsDetectModel> detectIngredients({
    required List<int> bytes,
    required String filename,
    String contentType = 'image/jpeg',
  }) async {
    final data = await _api.postMultipart(
      '/ai/ingredients/detect',
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
    return IngredientsDetectModel.fromJson(data as Map<String, dynamic>);
  }
}
