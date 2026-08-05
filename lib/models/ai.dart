import 'dart:convert';
import 'dart:typed_data';

enum AiCaptureMode { ingredients, dish }

sealed class AiCaptureResult {
  const AiCaptureResult();
}

class AiCaptureIngredientsResult extends AiCaptureResult {
  const AiCaptureIngredientsResult(this.ingredients);

  final List<String> ingredients;
}

class AiCaptureDishResult extends AiCaptureResult {
  const AiCaptureDishResult(this.dish);

  final DishRecognitionModel dish;
}

class ChatMessageModel {
  const ChatMessageModel({required this.role, required this.content});

  final String role;
  final String content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class RagRecipeModel {
  const RagRecipeModel({
    required this.title,
    this.recipeId,
    this.ingredients = const [],
    this.directions = const [],
    this.dietaryRestrictions = const [],
    this.estimatedServings,
    this.locale = 'en',
  });

  final String title;
  /// Qdrant / RAG recipe id (string). May match FoodHub DB id when numeric.
  final String? recipeId;
  final List<String> ingredients;
  final List<String> directions;
  final List<String> dietaryRestrictions;
  final int? estimatedServings;
  final String locale;

  int? get recipeIdAsInt {
    final raw = recipeId?.trim();
    if (raw == null || raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  factory RagRecipeModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['recipe_id'] ?? json['id'];
    return RagRecipeModel(
      title: json['title'] as String? ??
          json['RecipeName'] as String? ??
          'Untitled recipe',
      recipeId: rawId?.toString(),
      ingredients: _list(json['ingredients']),
      directions: _list(json['directions']),
      dietaryRestrictions: _list(json['dietary_restrictions']),
      estimatedServings: json['estimated_servings'] as int?,
      locale: (json['locale'] as String?) ?? 'en',
    );
  }

  static List<String> _list(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }
}

class ChatResponseModel {
  const ChatResponseModel({
    required this.taskId,
    required this.reply,
    this.phase = 'gather',
    this.sessionId,
    this.recipes = const [],
    this.knownInfo = const {},
  });

  final String taskId;
  final String reply;
  final String phase;
  final String? sessionId;
  final List<RagRecipeModel> recipes;
  final Map<String, dynamic> knownInfo;

  factory ChatResponseModel.fromJson(Map<String, dynamic> json) {
    return ChatResponseModel(
      taskId: json['task_id'] as String? ?? '',
      reply: json['reply'] as String? ?? '',
      phase: json['phase'] as String? ?? 'gather',
      sessionId: json['session_id'] as String?,
      recipes: (json['recipes'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(RagRecipeModel.fromJson)
              .toList() ??
          const [],
      knownInfo: json['known_info'] is Map<String, dynamic>
          ? json['known_info'] as Map<String, dynamic>
          : const {},
    );
  }
}

class DishRecognitionModel {
  const DishRecognitionModel({
    required this.taskId,
    required this.dishName,
    this.results = const [],
    this.suggestedRecipes = const [],
    this.imageUrl = '',
  });

  final String taskId;
  final String dishName;
  final List<DishResultModel> results;
  final List<String> suggestedRecipes;
  final String imageUrl;

  factory DishRecognitionModel.fromJson(Map<String, dynamic> json) {
    return DishRecognitionModel(
      taskId: json['task_id'] as String,
      dishName: json['dish_name'] as String? ?? '',
      results: (json['results'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(DishResultModel.fromJson)
              .toList() ??
          const [],
      suggestedRecipes: (json['suggested_recipes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      imageUrl: json['image_url'] as String? ?? '',
    );
  }
}

class DishResultModel {
  const DishResultModel({
    required this.rank,
    required this.dishName,
    required this.confidence,
  });

  final int rank;
  final String dishName;
  final double confidence;

  factory DishResultModel.fromJson(Map<String, dynamic> json) {
    return DishResultModel(
      rank: json['rank'] as int? ?? 0,
      dishName: json['dish_name'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    );
  }
}

class IngredientsDetectModel {
  const IngredientsDetectModel({
    required this.taskId,
    this.ingredients = const [],
    this.imageUrl = '',
    this.detections = const [],
    this.annotatedImageUrl = '',
    this.annotatedImageBytes,
  });

  final String taskId;
  final List<String> ingredients;
  final String imageUrl;
  final List<DetectionItemModel> detections;
  /// Server-uploaded annotated JPEG (`/media/...`); preferred over base64.
  final String annotatedImageUrl;
  final Uint8List? annotatedImageBytes;

  factory IngredientsDetectModel.fromJson(Map<String, dynamic> json) {
    Uint8List? annotated;
    final b64 = json['annotated_image_base64'] as String?;
    if (b64 != null && b64.isNotEmpty) {
      try {
        annotated = base64Decode(b64);
      } catch (_) {
        annotated = null;
      }
    }

    return IngredientsDetectModel(
      taskId: json['task_id'] as String,
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      imageUrl: json['image_url'] as String? ?? '',
      detections: (json['detections'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(DetectionItemModel.fromJson)
              .toList() ??
          const [],
      annotatedImageUrl: json['annotated_image_url'] as String? ?? '',
      annotatedImageBytes: annotated,
    );
  }
}

class DetectionItemModel {
  const DetectionItemModel({
    required this.label,
    required this.confidence,
    required this.bbox,
  });

  final String label;
  final double confidence;

  /// Normalized [x1, y1, x2, y2] in 0..1.
  final List<double> bbox;

  factory DetectionItemModel.fromJson(Map<String, dynamic> json) {
    final rawBbox = json['bbox'];
    final bbox = rawBbox is List
        ? rawBbox.map((e) => (e as num).toDouble()).toList()
        : const <double>[0, 0, 0, 0];
    return DetectionItemModel(
      label: json['label'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      bbox: bbox.length == 4 ? bbox : const [0, 0, 0, 0],
    );
  }
}

class AiJobAcceptedModel {
  const AiJobAcceptedModel({
    required this.taskId,
    required this.status,
    required this.requestType,
    this.imageUrl,
    this.sessionId,
  });

  final String taskId;
  final String status;
  final String requestType;
  final String? imageUrl;
  final String? sessionId;

  factory AiJobAcceptedModel.fromJson(Map<String, dynamic> json) {
    return AiJobAcceptedModel(
      taskId: json['task_id'] as String,
      status: json['status'] as String? ?? 'pending',
      requestType: json['request_type'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      sessionId: json['session_id'] as String?,
    );
  }
}

class AiRequestDetailModel {
  const AiRequestDetailModel({
    required this.taskId,
    required this.requestType,
    required this.status,
    this.inputPayload,
    this.outputPayload,
    this.errorMessage,
    this.durationMs,
  });

  final String taskId;
  final String requestType;
  final String status;
  final Map<String, dynamic>? inputPayload;
  final Map<String, dynamic>? outputPayload;
  final String? errorMessage;
  final int? durationMs;

  bool get isTerminal => status == 'completed' || status == 'failed';

  factory AiRequestDetailModel.fromJson(Map<String, dynamic> json) {
    return AiRequestDetailModel(
      taskId: json['task_id'] as String,
      requestType: json['request_type'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      inputPayload: json['input_payload'] is Map<String, dynamic>
          ? json['input_payload'] as Map<String, dynamic>
          : null,
      outputPayload: json['output_payload'] is Map<String, dynamic>
          ? json['output_payload'] as Map<String, dynamic>
          : null,
      errorMessage: json['error_message'] as String?,
      durationMs: json['duration_ms'] as int?,
    );
  }
}

class IngredientsStreamFrame {
  const IngredientsStreamFrame({
    this.ingredients = const [],
    this.detections = const [],
    this.error,
  });

  final List<String> ingredients;
  final List<DetectionItemModel> detections;
  final String? error;

  factory IngredientsStreamFrame.fromJson(Map<String, dynamic> json) {
    return IngredientsStreamFrame(
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      detections: (json['detections'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(DetectionItemModel.fromJson)
              .toList() ??
          const [],
      error: json['error'] as String?,
    );
  }
}
