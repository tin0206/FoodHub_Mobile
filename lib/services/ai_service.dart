import 'package:flutter/foundation.dart';
import 'package:foodhub_mobile/models/ai.dart';
import 'package:foodhub_mobile/services/api_client.dart';
import 'package:foodhub_mobile/services/api_exception.dart';

class AiService {
  AiService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  static const Duration _visionTimeout = Duration(seconds: 90);
  static const Duration _chatTimeout = Duration(seconds: 200);

  /// Increments whenever a chat message is sent/received, so any open history
  /// panel knows to refresh the session list.
  static final ValueNotifier<int> sessionChanges = ValueNotifier(0);

  /// Start companion session — returns welcome reply + stable [sessionId].
  Future<ChatResponseModel> welcome({
    String? sessionId,
    List<String> dietaryRestrictions = const [],
    String? primaryGoal,
    List<String> ingredients = const [],
  }) async {
    // ignore: avoid_print
    print('[AiService] POST /ai/chat/welcome');
    final data = await _api.post(
      '/ai/chat/welcome',
      timeout: _chatTimeout,
      body: {
        if (sessionId != null && sessionId.isNotEmpty) 'session_id': sessionId,
        'dietary_restrictions': dietaryRestrictions,
        if (primaryGoal != null && primaryGoal.isNotEmpty)
          'primary_goal': primaryGoal,
        'ingredients': ingredients,
      },
    );
    final detail = _requireCompleted(data);
    // ignore: avoid_print
    print('[AiService] welcome done job=${detail.taskId} session=${detail.sessionId}');
    return _chatFromDetail(detail, fallbackSessionId: sessionId);
  }

  Future<ChatResponseModel> chat({
    required String message,
    required String sessionId,
    List<String> dietaryRestrictions = const [],
    String? primaryGoal,
    List<String> ingredients = const [],
  }) async {
    final data = await _api.post(
      '/ai/chat',
      timeout: _chatTimeout,
      body: {
        'message': message,
        'session_id': sessionId,
        'dietary_restrictions': dietaryRestrictions,
        if (primaryGoal != null && primaryGoal.isNotEmpty)
          'primary_goal': primaryGoal,
        'ingredients': ingredients,
      },
    );
    return _chatFromDetail(
      _requireCompleted(data),
      fallbackSessionId: sessionId,
    );
  }

  Future<ChatResponseModel> selectOption({
    required String sessionId,
    required int selectedOptionIndex,
    List<String> dietaryRestrictions = const [],
    String? primaryGoal,
  }) async {
    final data = await _api.post(
      '/ai/chat',
      timeout: _chatTimeout,
      body: {
        'session_id': sessionId,
        'selected_option_index': selectedOptionIndex,
        'message': '.',
        'dietary_restrictions': dietaryRestrictions,
        if (primaryGoal != null && primaryGoal.isNotEmpty)
          'primary_goal': primaryGoal,
      },
    );
    return _chatFromDetail(
      _requireCompleted(data),
      fallbackSessionId: sessionId,
    );
  }

  Future<DishRecognitionModel> recognizeDish({
    required List<int> bytes,
    required String filename,
    String contentType = 'image/jpeg',
    String language = 'en',
  }) async {
    final data = await _api.postMultipart(
      '/ai/dish-recognition',
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
      contentType: contentType,
      fields: {'language': language},
      timeout: _visionTimeout,
    );
    final detail = _requireCompleted(data);
    final payload = Map<String, dynamic>.from(detail.outputPayload ?? {});
    payload.putIfAbsent('task_id', () => detail.taskId);
    return DishRecognitionModel.fromJson(payload);
  }

  Future<IngredientsDetectModel> detectIngredients({
    required List<int> bytes,
    required String filename,
    String contentType = 'image/jpeg',
    String language = 'en',
  }) async {
    final data = await _api.postMultipart(
      '/ai/ingredients/detect',
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
      contentType: contentType,
      fields: {'language': language},
      timeout: _visionTimeout,
    );
    final detail = _requireCompleted(data);
    final payload = Map<String, dynamic>.from(detail.outputPayload ?? {});
    payload.putIfAbsent('task_id', () => detail.taskId);
    return IngredientsDetectModel.fromJson(payload);
  }

  Future<AiRequestDetailModel> getRequest(String taskId) async {
    final data = await _api.get('/ai/requests/$taskId');
    return AiRequestDetailModel.fromJson(data as Map<String, dynamic>);
  }

  AiRequestDetailModel _requireCompleted(dynamic data) {
    final detail = AiRequestDetailModel.fromJson(data as Map<String, dynamic>);
    if (detail.status == 'failed') {
      throw ApiException(
        detail.errorMessage?.isNotEmpty == true
            ? detail.errorMessage!
            : 'AI job failed.',
      );
    }
    if (detail.status != 'completed' || detail.outputPayload == null) {
      throw ApiException('AI job completed without a result payload.');
    }
    return detail;
  }

  ChatResponseModel _chatFromDetail(
    AiRequestDetailModel detail, {
    String? fallbackSessionId,
  }) {
    final payload = Map<String, dynamic>.from(detail.outputPayload ?? {});
    payload.putIfAbsent('task_id', () => detail.taskId);
    payload.putIfAbsent(
      'session_id',
      () => detail.sessionId ?? fallbackSessionId ?? detail.taskId,
    );
    payload.putIfAbsent('phase', () => 'gather');
    return ChatResponseModel.fromJson(payload);
  }

  Future<List<ChatSessionModel>> listSessions({
    int skip = 0,
    int limit = 30,
  }) async {
    final data = await _api.get(
      '/ai/sessions',
      query: {'skip': '$skip', 'limit': '$limit'},
    );
    List<dynamic> items;
    if (data is List) {
      items = data;
    } else if (data is Map<String, dynamic>) {
      // Wrapped response: {"sessions": [...]} or {"items": [...]} etc.
      final v = data['sessions'] ?? data['items'] ?? data['data'] ?? data['results'];
      items = v is List ? v : [];
      debugPrint('[AiService] listSessions wrapped response keys=${data.keys.toList()}');
    } else {
      items = [];
    }
    return items
        .whereType<Map<String, dynamic>>()
        .map(ChatSessionModel.fromJson)
        .toList();
  }

  Future<ChatSessionDetailModel> getSession(String sessionId) async {
    final data = await _api.get('/ai/sessions/$sessionId');
    return ChatSessionDetailModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteSession(String sessionId) async {
    await _api.delete('/ai/sessions/$sessionId');
  }

  Future<ChatSessionModel> renameSession(String sessionId, String title) async {
    final data = await _api.patch(
      '/ai/sessions/$sessionId',
      body: {'title': title},
    );
    return ChatSessionModel.fromJson(data as Map<String, dynamic>);
  }
}
