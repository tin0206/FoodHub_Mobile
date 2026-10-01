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
    this.heightCm,
    this.cookingSkill,
    this.mealsPerDay = 3,
    this.gender,
    this.language,
    this.theme = 'light',
    this.calorieTarget,
    this.proteinTarget,
    this.carbTarget,
    this.fatTarget,
    this.dietaryRestrictions = const [],
    this.excludedIngredients = const [],
    this.favoriteFoods = const [],
    this.dislikedIngredients = const [],
    this.primaryGoal,
    this.hasPassword = true,
    this.googleId,
  });

  final int id;
  final String email;
  final String username;
  final String? fullName;
  final String role;
  final bool isActive;
  final bool hasPassword;
  final String? googleId;

  /// True khi user chỉ có Google, chưa set password.
  bool get isGoogleOnly => googleId != null && !hasPassword;
  final int? age;
  final double? weight;
  final double? heightCm;
  final String? cookingSkill;
  final int mealsPerDay;
  final String? gender;
  final String? language;
  final String theme;
  final int? calorieTarget;
  final int? proteinTarget;
  final int? carbTarget;
  final int? fatTarget;
  final List<String> dietaryRestrictions;
  final List<String> excludedIngredients;
  final List<String> favoriteFoods;
  final List<String> dislikedIngredients;
  final String? primaryGoal;

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).toList();
  }

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
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      cookingSkill: json['cooking_skill'] as String?,
      mealsPerDay: json['meals_per_day'] as int? ?? 3,
      gender: json['gender'] as String?,
      language: json['language'] as String?,
      theme: json['theme'] as String? ?? 'light',
      calorieTarget: json['calorie_target'] as int?,
      proteinTarget: json['protein_target'] as int?,
      carbTarget: json['carb_target'] as int?,
      fatTarget: json['fat_target'] as int?,
      dietaryRestrictions: _stringList(json['dietary_restrictions']),
      excludedIngredients: _stringList(json['excluded_ingredients']),
      favoriteFoods: _stringList(json['favorite_foods']),
      dislikedIngredients: _stringList(json['disliked_ingredients']),
      primaryGoal: json['primary_goal'] as String?,
      hasPassword: json['has_password'] as bool? ?? true,
      googleId: json['google_id'] as String?,
    );
  }

  Map<String, dynamic> toProfileUpdateJson({
    String? fullName,
    int? age,
    double? weight,
    double? heightCm,
    String? cookingSkill,
    int? mealsPerDay,
    String? gender,
    int? calorieTarget,
    int? proteinTarget,
    int? carbTarget,
    int? fatTarget,
    List<String>? dietaryRestrictions,
    List<String>? excludedIngredients,
    List<String>? favoriteFoods,
    List<String>? dislikedIngredients,
    String? primaryGoal,
    String? language,
    String? theme,
  }) {
    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;
    if (age != null) data['age'] = age;
    if (weight != null) data['weight'] = weight;
    if (heightCm != null) data['height_cm'] = heightCm;
    if (cookingSkill != null) data['cooking_skill'] = cookingSkill;
    if (mealsPerDay != null) data['meals_per_day'] = mealsPerDay;
    if (gender != null) data['gender'] = gender.isEmpty ? null : gender;
    if (calorieTarget != null) data['calorie_target'] = calorieTarget;
    if (proteinTarget != null) data['protein_target'] = proteinTarget;
    if (carbTarget != null) data['carb_target'] = carbTarget;
    if (fatTarget != null) data['fat_target'] = fatTarget;
    if (dietaryRestrictions != null) {
      data['dietary_restrictions'] = dietaryRestrictions;
    }
    if (excludedIngredients != null) {
      data['excluded_ingredients'] = excludedIngredients;
    }
    if (favoriteFoods != null) data['favorite_foods'] = favoriteFoods;
    if (dislikedIngredients != null) {
      data['disliked_ingredients'] = dislikedIngredients;
    }
    if (primaryGoal != null) data['primary_goal'] = primaryGoal;
    if (language != null) data['language'] = language;
    if (theme != null) data['theme'] = theme;
    return data;
  }

  UserModel copyWith({
    String? fullName,
    int? age,
    double? weight,
    double? heightCm,
    String? cookingSkill,
    int? mealsPerDay,
    String? gender,
    int? calorieTarget,
    int? proteinTarget,
    int? carbTarget,
    int? fatTarget,
    List<String>? dietaryRestrictions,
    List<String>? excludedIngredients,
    List<String>? favoriteFoods,
    List<String>? dislikedIngredients,
    String? primaryGoal,
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
      heightCm: heightCm ?? this.heightCm,
      cookingSkill: cookingSkill ?? this.cookingSkill,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      gender: gender ?? this.gender,
      calorieTarget: calorieTarget ?? this.calorieTarget,
      proteinTarget: proteinTarget ?? this.proteinTarget,
      carbTarget: carbTarget ?? this.carbTarget,
      fatTarget: fatTarget ?? this.fatTarget,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      excludedIngredients: excludedIngredients ?? this.excludedIngredients,
      favoriteFoods: favoriteFoods ?? this.favoriteFoods,
      dislikedIngredients: dislikedIngredients ?? this.dislikedIngredients,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      hasPassword: hasPassword,
      googleId: googleId,
      role: role,
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
