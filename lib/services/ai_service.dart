import 'package:foodhub_mobile/models/ai.dart';
import 'package:foodhub_mobile/services/api_client.dart';
import 'package:foodhub_mobile/services/api_exception.dart';

class AiService {
  AiService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  static const Duration _pollInterval = Duration(seconds: 1);
  static const Duration _visionTimeout = Duration(seconds: 90);
  static const Duration _chatTimeout = Duration(seconds: 200);

  /// Start companion session — returns welcome reply + stable [sessionId].
  Future<ChatResponseModel> welcome({
    String? sessionId,
    List<String> dietaryRestrictions = const [],
    String? primaryGoal,
    List<String> ingredients = const [],
  }) async {
    // ignore: avoid_print
    print('[AiService] POST /ai/chat/welcome');
    final accepted = await _api.post(
      '/ai/chat/welcome',
      body: {
        if (sessionId != null && sessionId.isNotEmpty) 'session_id': sessionId,
        'dietary_restrictions': dietaryRestrictions,
        if (primaryGoal != null && primaryGoal.isNotEmpty)
          'primary_goal': primaryGoal,
        'ingredients': ingredients,
      },
    );
    final job = AiJobAcceptedModel.fromJson(accepted as Map<String, dynamic>);
    // ignore: avoid_print
    print('[AiService] welcome accepted job=${job.taskId} session=${job.sessionId}');
    final detail = await _waitForResult(job.taskId, timeout: _chatTimeout);
    final payload = Map<String, dynamic>.from(detail.outputPayload ?? {});
    payload.putIfAbsent('task_id', () => detail.taskId);
    payload.putIfAbsent(
      'session_id',
      () => job.sessionId ?? sessionId ?? detail.taskId,
    );
    payload.putIfAbsent('phase', () => 'gather');
    return ChatResponseModel.fromJson(payload);
  }

  Future<ChatResponseModel> chat({
    required String message,
    required String sessionId,
    List<ChatMessageModel> conversationHistory = const [],
    List<String> dietaryRestrictions = const [],
    String? primaryGoal,
    List<String> ingredients = const [],
  }) async {
    final accepted = await _api.post(
      '/ai/chat',
      body: {
        'message': message,
        'session_id': sessionId,
        'conversation_history':
            conversationHistory.map((m) => m.toJson()).toList(),
        'dietary_restrictions': dietaryRestrictions,
        if (primaryGoal != null && primaryGoal.isNotEmpty)
          'primary_goal': primaryGoal,
        'ingredients': ingredients,
      },
    );
    final job = AiJobAcceptedModel.fromJson(accepted as Map<String, dynamic>);
    final detail = await _waitForResult(job.taskId, timeout: _chatTimeout);
    final payload = Map<String, dynamic>.from(detail.outputPayload ?? {});
    payload.putIfAbsent('task_id', () => detail.taskId);
    payload.putIfAbsent(
      'session_id',
      () => job.sessionId ?? sessionId,
    );
    return ChatResponseModel.fromJson(payload);
  }

  Future<DishRecognitionModel> recognizeDish({
    required List<int> bytes,
    required String filename,
    String contentType = 'image/jpeg',
  }) async {
    final accepted = await _api.postMultipart(
      '/ai/dish-recognition',
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
    final job = AiJobAcceptedModel.fromJson(accepted as Map<String, dynamic>);
    final detail = await _waitForResult(job.taskId, timeout: _visionTimeout);
    final payload = Map<String, dynamic>.from(detail.outputPayload ?? {});
    payload.putIfAbsent('task_id', () => detail.taskId);
    if ((payload['image_url'] == null ||
            (payload['image_url'] as String).isEmpty) &&
        job.imageUrl != null) {
      payload['image_url'] = job.imageUrl;
    }
    return DishRecognitionModel.fromJson(payload);
  }

  Future<IngredientsDetectModel> detectIngredients({
    required List<int> bytes,
    required String filename,
    String contentType = 'image/jpeg',
    String language = 'en',
  }) async {
    final accepted = await _api.postMultipart(
      '/ai/ingredients/detect',
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
      contentType: contentType,
      fields: {'language': language},
    );
    final job = AiJobAcceptedModel.fromJson(accepted as Map<String, dynamic>);
    final detail = await _waitForResult(job.taskId, timeout: _visionTimeout);
    final payload = Map<String, dynamic>.from(detail.outputPayload ?? {});
    payload.putIfAbsent('task_id', () => detail.taskId);
    if ((payload['image_url'] == null ||
            (payload['image_url'] as String).isEmpty) &&
        job.imageUrl != null) {
      payload['image_url'] = job.imageUrl;
    }
    return IngredientsDetectModel.fromJson(payload);
  }

  Future<AiRequestDetailModel> getRequest(String taskId) async {
    final data = await _api.get('/ai/requests/$taskId');
    return AiRequestDetailModel.fromJson(data as Map<String, dynamic>);
  }

  Future<AiRequestDetailModel> _waitForResult(
    String taskId, {
    required Duration timeout,
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final detail = await getRequest(taskId);
      if (detail.status == 'completed') {
        if (detail.outputPayload == null) {
          throw ApiException('AI job completed without a result payload.');
        }
        return detail;
      }
      if (detail.status == 'failed') {
        throw ApiException(
          detail.errorMessage?.isNotEmpty == true
              ? detail.errorMessage!
              : 'AI job failed.',
        );
      }
      await Future<void>.delayed(_pollInterval);
    }
    throw ApiException(
      'AI job timed out after ${timeout.inSeconds}s. Please try again.',
    );
  }
}
