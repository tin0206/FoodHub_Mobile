import 'package:foodhub_mobile/models/user.dart';

// ── Overview ─────────────────────────────────────────────────────────────────

class AdminActivityUser {
  const AdminActivityUser({
    required this.id,
    required this.email,
    required this.username,
    this.fullName,
  });

  final int id;
  final String email;
  final String username;
  final String? fullName;

  String get displayName => fullName ?? username;

  factory AdminActivityUser.fromJson(Map<String, dynamic> json) {
    return AdminActivityUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      fullName: json['full_name'] as String?,
    );
  }
}

class AdminActivityRecipe {
  const AdminActivityRecipe({
    required this.id,
    required this.title,
    required this.visibility,
  });

  final int id;
  final String title;
  final String visibility;

  bool get isPublic => visibility == 'public';

  factory AdminActivityRecipe.fromJson(Map<String, dynamic> json) {
    return AdminActivityRecipe(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      visibility: json['visibility'] as String? ?? 'private',
    );
  }
}

class AdminActivity {
  const AdminActivity({
    required this.type,
    required this.createdAt,
    this.user,
    this.recipe,
  });

  final String type; // 'user' | 'recipe'
  final String createdAt;
  final AdminActivityUser? user;
  final AdminActivityRecipe? recipe;

  factory AdminActivity.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'recipe';
    return AdminActivity(
      type: type,
      createdAt: json['created_at'] as String? ?? '',
      user: type == 'user' && json['user'] is Map
          ? AdminActivityUser.fromJson(Map<String, dynamic>.from(json['user'] as Map))
          : null,
      recipe: type == 'recipe' && json['recipe'] is Map
          ? AdminActivityRecipe.fromJson(Map<String, dynamic>.from(json['recipe'] as Map))
          : null,
    );
  }
}

class AdminOverview {
  const AdminOverview({
    required this.totalUsers,
    required this.totalRecipes,
    required this.recentActivities,
  });

  final int totalUsers;
  final int totalRecipes;
  final List<AdminActivity> recentActivities;

  factory AdminOverview.fromJson(Map<String, dynamic> json) {
    final raw = json['recent_activities'];
    return AdminOverview(
      totalUsers: (json['total_users'] as num?)?.toInt() ?? 0,
      totalRecipes: (json['total_recipes'] as num?)?.toInt() ?? 0,
      recentActivities: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => AdminActivity.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

// ── Analytics ─────────────────────────────────────────────────────────────────

class AdminLabelCount {
  const AdminLabelCount({required this.label, required this.count});
  final String label;
  final int count;
  factory AdminLabelCount.fromJson(Map<String, dynamic> json) => AdminLabelCount(
        label: json['label'] as String? ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}

// Legacy alias kept for any remaining references
typedef AdminPopularLabel = AdminLabelCount;

class AdminTopRecipe {
  const AdminTopRecipe({
    required this.id,
    required this.title,
    required this.favoritesCount,
    this.viewCount = 0,
    this.score = 0,
  });
  final int id;
  final String title;
  final int favoritesCount;
  final int viewCount;
  final int score;

  factory AdminTopRecipe.fromJson(Map<String, dynamic> json) {
    // New format: {"recipe": {...}, "favorite_count": N, "view_count": N, "score": N}
    // Old format: {"id": N, "title": "...", "favorites_count": N}
    final recipe = json['recipe'] as Map<String, dynamic>?;
    if (recipe != null) {
      return AdminTopRecipe(
        id: (recipe['id'] as num?)?.toInt() ?? 0,
        title: recipe['title'] as String? ?? '',
        favoritesCount: (json['favorite_count'] as num?)?.toInt() ?? 0,
        viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
        score: (json['score'] as num?)?.toInt() ?? 0,
      );
    }
    return AdminTopRecipe(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      favoritesCount: (json['favorites_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminTopUser {
  const AdminTopUser({
    required this.id,
    required this.username,
    this.fullName,
    this.email = '',
    this.recipesCreated = 0,
    this.favoritesCount = 0,
    this.chatSessions = 0,
    this.score = 0,
  });
  final int id;
  final String username;
  final String? fullName;
  final String email;
  final int recipesCreated;
  final int favoritesCount;
  final int chatSessions;
  final int score;

  String get displayName => (fullName != null && fullName!.isNotEmpty) ? fullName! : username;

  factory AdminTopUser.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final u = user ?? json;
    return AdminTopUser(
      id: (u['id'] as num?)?.toInt() ?? 0,
      username: u['username'] as String? ?? '',
      fullName: u['full_name'] as String?,
      email: u['email'] as String? ?? '',
      recipesCreated: (json['recipes_created'] as num?)?.toInt() ?? 0,
      favoritesCount: (json['favorites_count'] as num?)?.toInt() ?? 0,
      chatSessions: (json['chat_sessions'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminAiUsage {
  const AdminAiUsage({
    required this.requestType,
    required this.total,
    required this.failed,
    required this.failRate,
  });
  final String requestType;
  final int total;
  final int failed;
  final double failRate;

  factory AdminAiUsage.fromJson(Map<String, dynamic> json) => AdminAiUsage(
        requestType: json['request_type'] as String? ?? '',
        total: (json['total'] as num?)?.toInt() ?? 0,
        failed: (json['failed'] as num?)?.toInt() ?? 0,
        failRate: (json['fail_rate'] as num?)?.toDouble() ?? 0,
      );
}

class AdminActivePoint {
  const AdminActivePoint({required this.period, required this.activeUsers});
  final String period;
  final int activeUsers;

  factory AdminActivePoint.fromJson(Map<String, dynamic> json) => AdminActivePoint(
        period: json['period'] as String? ?? '',
        activeUsers: (json['active_users'] as num?)?.toInt() ?? 0,
      );
}

class AdminMealPlanAdoption {
  const AdminMealPlanAdoption({
    required this.totalUsers,
    required this.usersWithMealPlans,
    required this.totalMealPlans,
    required this.usersWithSuggestions,
    required this.totalSuggestions,
    required this.adoptionRate,
  });
  final int totalUsers;
  final int usersWithMealPlans;
  final int totalMealPlans;
  final int usersWithSuggestions;
  final int totalSuggestions;
  final double adoptionRate;

  factory AdminMealPlanAdoption.fromJson(Map<String, dynamic> json) => AdminMealPlanAdoption(
        totalUsers: (json['total_users'] as num?)?.toInt() ?? 0,
        usersWithMealPlans: (json['users_with_meal_plans'] as num?)?.toInt() ?? 0,
        totalMealPlans: (json['total_meal_plans'] as num?)?.toInt() ?? 0,
        usersWithSuggestions: (json['users_with_suggestions'] as num?)?.toInt() ?? 0,
        totalSuggestions: (json['total_suggestions'] as num?)?.toInt() ?? 0,
        adoptionRate: (json['adoption_rate'] as num?)?.toDouble() ?? 0,
      );
}

class AdminDailySignup {
  const AdminDailySignup({required this.date, required this.count});
  final String date;
  final int count;
  factory AdminDailySignup.fromJson(Map<String, dynamic> json) => AdminDailySignup(
        date: json['date'] as String? ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}

class AdminAnalytics {
  const AdminAnalytics({
    required this.topRecipes,
    required this.popularLabels,
    required this.dailySignups,
    this.topUsers = const [],
    this.aiUsage = const [],
    this.dailyActiveUsers = const [],
    this.weeklyActiveUsers = const [],
    this.dietaryDistribution = const [],
    this.mealPlanAdoption,
  });

  final List<AdminTopRecipe> topRecipes;
  final List<AdminLabelCount> popularLabels;
  final List<AdminDailySignup> dailySignups;
  final List<AdminTopUser> topUsers;
  final List<AdminAiUsage> aiUsage;
  final List<AdminActivePoint> dailyActiveUsers;
  final List<AdminActivePoint> weeklyActiveUsers;
  final List<AdminLabelCount> dietaryDistribution;
  final AdminMealPlanAdoption? mealPlanAdoption;

  factory AdminAnalytics.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(dynamic raw, T Function(Map<String, dynamic>) f) {
      if (raw is! List) return const [];
      return raw.whereType<Map>().map((e) => f(Map<String, dynamic>.from(e))).toList();
    }

    return AdminAnalytics(
      topRecipes: parseList(json['top_recipes'], AdminTopRecipe.fromJson),
      popularLabels: parseList(json['popular_recipes'], AdminLabelCount.fromJson),
      dailySignups: parseList(json['daily_signups'], AdminDailySignup.fromJson),
      topUsers: parseList(json['top_users'], AdminTopUser.fromJson),
      aiUsage: parseList(json['ai_usage'], AdminAiUsage.fromJson),
      dailyActiveUsers: parseList(json['daily_active_users'], AdminActivePoint.fromJson),
      weeklyActiveUsers: parseList(json['weekly_active_users'], AdminActivePoint.fromJson),
      dietaryDistribution: parseList(json['dietary_restriction_distribution'], AdminLabelCount.fromJson),
      mealPlanAdoption: json['meal_plan_adoption'] is Map
          ? AdminMealPlanAdoption.fromJson(
              Map<String, dynamic>.from(json['meal_plan_adoption'] as Map))
          : null,
    );
  }
}

// ── User detail ───────────────────────────────────────────────────────────────

class AdminUserDetail {
  const AdminUserDetail({
    required this.user,
    required this.recipesCount,
    required this.savedCount,
  });

  final UserModel user;
  final int recipesCount;
  final int savedCount;

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    return AdminUserDetail(
      user: rawUser is Map
          ? UserModel.fromJson(Map<String, dynamic>.from(rawUser))
          : UserModel.fromJson(json),
      recipesCount: (json['recipes_count'] as num?)?.toInt() ?? 0,
      savedCount: (json['saved_count'] as num?)?.toInt() ?? 0,
    );
  }
}

// ── Recipe translation ────────────────────────────────────────────────────────

class RecipeTranslation {
  const RecipeTranslation({
    required this.locale,
    required this.title,
    required this.ingredients,
    required this.directions,
  });

  final String locale;
  final String title;
  final List<String> ingredients;
  final List<String> directions;

  factory RecipeTranslation.fromJson(Map<String, dynamic> json) {
    List<String> toStrList(dynamic v) {
      if (v is List) return v.map((e) => '$e').toList();
      if (v is String) return v.split('\n').where((s) => s.trim().isNotEmpty).toList();
      return const [];
    }

    return RecipeTranslation(
      locale: json['locale'] as String? ?? 'en',
      title: json['title'] as String? ?? '',
      ingredients: toStrList(json['ingredients']),
      directions: toStrList(json['directions']),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'ingredients': ingredients,
    'directions': directions,
  };
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Stable HSL color from name hash (same algorithm as web admin).
String adminAvatarColor(String name, {bool isDark = false}) {
  if (name.isEmpty) return isDark ? '#64748B' : '#9CA3AF';
  var hash = 0;
  for (final c in name.codeUnits) {
    hash = c + ((hash << 5) - hash);
  }
  final h = ((hash % 360) + 360) % 360;
  return 'hsl($h,${isDark ? 55 : 60}%,${isDark ? 55 : 45}%)';
}

int adminAvatarColorInt(String name, {bool isDark = false}) {
  if (name.isEmpty) return isDark ? 0xFF64748B : 0xFF9CA3AF;
  var hash = 0;
  for (final c in name.codeUnits) {
    hash = c + ((hash << 5) - hash);
  }
  final h = (((hash % 360) + 360) % 360) / 360.0;
  final s = isDark ? 0.55 : 0.60;
  final l = isDark ? 0.55 : 0.45;
  return _hslToInt(h, s, l);
}

int _hslToInt(double h, double s, double l) {
  final a = s * (l < 0.5 ? l : 1 - l);
  double k(double n) => (n + h * 12) % 12;
  double f(double n) => l - a * (1.0 - (-1.0 > k(n) - 3 ? -1.0 : k(n) - 3 < 1 ? k(n) - 3 : 1.0).clamp(-1.0, 1.0)).abs().clamp(0.0, 1.0);
  // Avoid .clamp usage ambiguity with int overloads, keep as double throughout
  final r = (f(0.0) * 255).round().clamp(0, 255);
  final g = (f(8.0) * 255).round().clamp(0, 255);
  final b = (f(4.0) * 255).round().clamp(0, 255);
  return 0xFF000000 | (r << 16) | (g << 8) | b;
}

String adminAvatarInitials(String name) {
  if (name.isEmpty) return '?';
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
  return name[0].toUpperCase();
}

/// Relative time string in en/vi.
String adminRelativeTime(String isoDate, String lang) {
  final isVi = lang == 'vi';
  DateTime dt;
  try {
    dt = DateTime.parse(isoDate).toLocal();
  } catch (_) {
    return isoDate;
  }
  final diff = DateTime.now().difference(dt);

  if (diff.inSeconds < 60) return isVi ? 'vừa xong' : 'just now';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return isVi ? '$m phút trước' : '${m}m ago';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return isVi ? '$h giờ trước' : '${h}h ago';
  }
  if (diff.inDays < 30) {
    final d = diff.inDays;
    return isVi ? '$d ngày trước' : '${d}d ago';
  }
  if (diff.inDays < 365) {
    final mo = (diff.inDays / 30).round();
    return isVi ? '$mo tháng trước' : '${mo}mo ago';
  }
  final y = (diff.inDays / 365).round();
  return isVi ? '$y năm trước' : '${y}y ago';
}

// Categorical color palette (8 colors) matching web admin CATEGORICAL array.
// Each entry is (lightArgb, darkArgb).
const kAdminCategorical = [
  (0xFF6366F1, 0xFF818CF8), // indigo
  (0xFFF59E0B, 0xFFFBBF24), // amber
  (0xFF10B981, 0xFF34D399), // emerald
  (0xFFEF4444, 0xFFF87171), // red
  (0xFF3B82F6, 0xFF60A5FA), // blue
  (0xFF8B5CF6, 0xFFA78BFA), // violet
  (0xFFF97316, 0xFFFB923C), // orange
  (0xFFEC4899, 0xFFF472B6), // pink
];

int categoricalColor(int index, {bool isDark = false}) {
  final (light, dark) = kAdminCategorical[index % kAdminCategorical.length];
  return isDark ? dark : light;
}

