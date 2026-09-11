import 'package:foodhub_mobile/models/feedback.dart';
import 'package:foodhub_mobile/services/api_client.dart';

class FeedbackService {
  FeedbackService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  static const categories = ['bug', 'feature', 'general', 'complaint'];

  Future<List<FeedbackModel>> listMyFeedback() async {
    final data = await _api.get('/feedback');
    return (data as List)
        .map((e) => FeedbackModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<FeedbackModel> submitFeedback({
    required String category,
    required String message,
    int? rating,
  }) async {
    final data = await _api.post('/feedback', body: {
      'category': category,
      'message': message,
      if (rating != null) 'rating': rating,
    });
    return FeedbackModel.fromJson(data as Map<String, dynamic>);
  }
}
