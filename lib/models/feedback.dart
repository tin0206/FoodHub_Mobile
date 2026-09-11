import 'package:foodhub_mobile/models/user.dart';

class FeedbackModel {
  const FeedbackModel({
    required this.id,
    required this.category,
    required this.message,
    this.rating,
    required this.status,
    this.adminReply,
    this.repliedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String category; // 'bug' | 'feature' | 'general' | 'complaint'
  final String message;
  final int? rating; // 1-5
  final String status; // 'open' | 'in_progress' | 'resolved'
  final String? adminReply;
  final DateTime? repliedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: (json['id'] as num).toInt(),
      category: json['category'] as String,
      message: json['message'] as String,
      rating: (json['rating'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'open',
      adminReply: json['admin_reply'] as String?,
      repliedAt: json['replied_at'] != null
          ? DateTime.parse(json['replied_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class AdminFeedbackModel extends FeedbackModel {
  const AdminFeedbackModel({
    required super.id,
    required super.category,
    required super.message,
    super.rating,
    required super.status,
    super.adminReply,
    super.repliedAt,
    required super.createdAt,
    required super.updatedAt,
    required this.user,
  });

  final UserModel user;

  factory AdminFeedbackModel.fromJson(Map<String, dynamic> json) {
    final base = FeedbackModel.fromJson(json);
    return AdminFeedbackModel(
      id: base.id,
      category: base.category,
      message: base.message,
      rating: base.rating,
      status: base.status,
      adminReply: base.adminReply,
      repliedAt: base.repliedAt,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      user: UserModel.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
    );
  }
}
