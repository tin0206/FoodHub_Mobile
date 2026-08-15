class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.fullName,
    this.role = 'user',
    this.isActive = true,
    this.age,
    this.weight,
    this.language,
    this.theme = 'light',
    this.calorieTarget,
    this.proteinTarget,
    this.dietaryRestrictions = const [],
    this.primaryGoal,
    this.notifyRecommendations = true,
    this.notifyNewFeatures = true,
    this.notifyWeeklySummary = true,
  });

  final int id;
  final String email;
  final String username;
  final String? fullName;
  final String role;
  final bool isActive;
  final int? age;
  final double? weight;
  final String? language;
  final String theme;
  final int? calorieTarget;
  final int? proteinTarget;
  final List<String> dietaryRestrictions;
  final String? primaryGoal;
  final bool notifyRecommendations;
  final bool notifyNewFeatures;
  final bool notifyWeeklySummary;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String?,
      role: json['role'] as String? ?? 'user',
      isActive: json['is_active'] as bool? ?? true,
      age: json['age'] as int?,
      weight: (json['weight'] as num?)?.toDouble(),
      language: json['language'] as String?,
      theme: json['theme'] as String? ?? 'light',
      calorieTarget: json['calorie_target'] as int?,
      proteinTarget: json['protein_target'] as int?,
      dietaryRestrictions:
          (json['dietary_restrictions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      primaryGoal: json['primary_goal'] as String?,
      notifyRecommendations: json['notify_recommendations'] as bool? ?? true,
      notifyNewFeatures: json['notify_new_features'] as bool? ?? true,
      notifyWeeklySummary: json['notify_weekly_summary'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toProfileUpdateJson({
    String? fullName,
    int? age,
    double? weight,
    int? calorieTarget,
    int? proteinTarget,
    List<String>? dietaryRestrictions,
    String? primaryGoal,
    bool? notifyRecommendations,
    bool? notifyNewFeatures,
    bool? notifyWeeklySummary,
    String? language,
    String? theme,
  }) {
    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;
    if (age != null) data['age'] = age;
    if (weight != null) data['weight'] = weight;
    if (calorieTarget != null) data['calorie_target'] = calorieTarget;
    if (proteinTarget != null) data['protein_target'] = proteinTarget;
    if (dietaryRestrictions != null) {
      data['dietary_restrictions'] = dietaryRestrictions;
    }
    if (primaryGoal != null) data['primary_goal'] = primaryGoal;
    if (notifyRecommendations != null) {
      data['notify_recommendations'] = notifyRecommendations;
    }
    if (notifyNewFeatures != null) {
      data['notify_new_features'] = notifyNewFeatures;
    }
    if (notifyWeeklySummary != null) {
      data['notify_weekly_summary'] = notifyWeeklySummary;
    }
    if (language != null) {
      data['language'] = language;
    }
    if (theme != null) {
      data['theme'] = theme;
    }
    return data;
  }

  UserModel copyWith({
    String? fullName,
    int? age,
    double? weight,
    int? calorieTarget,
    int? proteinTarget,
    List<String>? dietaryRestrictions,
    String? primaryGoal,
    bool? notifyRecommendations,
    bool? notifyNewFeatures,
    bool? notifyWeeklySummary,
    String? language,
    String? theme,
  }) {
    return UserModel(
      id: id,
      email: email,
      username: username,
      fullName: fullName ?? this.fullName,
      isActive: isActive,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      calorieTarget: calorieTarget ?? this.calorieTarget,
      proteinTarget: proteinTarget ?? this.proteinTarget,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      notifyRecommendations:
          notifyRecommendations ?? this.notifyRecommendations,
      notifyNewFeatures: notifyNewFeatures ?? this.notifyNewFeatures,
      notifyWeeklySummary: notifyWeeklySummary ?? this.notifyWeeklySummary,
    );
  }
}

class AuthToken {
  const AuthToken({
    required this.accessToken,
    required this.user,
    this.tokenType = 'bearer',
  });

  final String accessToken;
  final String tokenType;
  final UserModel user;

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
