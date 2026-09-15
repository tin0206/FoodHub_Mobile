import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';
import 'package:foodhub_mobile/models/admin.dart';
import 'package:foodhub_mobile/screens/admin/admin_ai_requests_screen.dart';
import 'package:foodhub_mobile/screens/admin/admin_recipe_detail_screen.dart';
import 'package:foodhub_mobile/screens/admin/admin_shell_screen.dart';
import 'package:foodhub_mobile/screens/admin/admin_user_detail_screen.dart';
import 'package:foodhub_mobile/services/admin_service.dart';
import 'package:foodhub_mobile/services/api_exception.dart';
import 'package:foodhub_mobile/widgets/admin/charts.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key, required this.isDarkMode});

  final bool isDarkMode;

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final _admin = AdminService();
  AdminAnalytics? _data;
  bool _loading = true;
  String? _error;
  Map<int, String> _viTitles = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _admin.getAnalytics();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : '$e';
      });
    }
  }

  Future<void> _fetchViTitles(List<AdminTopRecipe> recipes) async {
    if (recipes.isEmpty) {
      setState(() => _viTitles = {});
      return;
    }
    final results = await Future.wait(
      recipes.map((r) async {
        try {
          final t = await _admin.getRecipe(r.id, lang: 'vi');
          return MapEntry(r.id, t.title);
        } catch (_) {
          return MapEntry(r.id, r.title);
        }
      }),
    );
    if (!mounted) return;
    setState(() => _viTitles = Map.fromEntries(results));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = LangScope.of(context);
    final recipes = _data?.topRecipes ?? [];
    if (lang == 'vi' && recipes.isNotEmpty && _viTitles.isEmpty) {
      _fetchViTitles(recipes);
    } else if (lang != 'vi' && _viTitles.isNotEmpty) {
      setState(() => _viTitles = {});
    }
  }

  // ── Date helpers ─────────────────────────────────────────────────────────────

  List<String> _lastNDays(int n) {
    final today = DateTime.now();
    return List.generate(n, (i) {
      final d = today.subtract(Duration(days: n - 1 - i));
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    });
  }

  String _shortDate(String dateStr, String lang) {
    try {
      final p = dateStr.split('-');
      final d = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
      const enM = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      const viM = [
        'Th1',
        'Th2',
        'Th3',
        'Th4',
        'Th5',
        'Th6',
        'Th7',
        'Th8',
        'Th9',
        'Th10',
        'Th11',
        'Th12',
      ];
      final m = lang == 'vi' ? viM[d.month - 1] : enM[d.month - 1];
      return '$m ${d.day}';
    } catch (_) {
      return dateStr;
    }
  }

  String _dayLabel(String dateStr, String lang) {
    try {
      final p = dateStr.split('-');
      final d = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
      const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const vi = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
      return lang == 'vi' ? vi[d.weekday - 1] : en[d.weekday - 1];
    } catch (_) {
      return dateStr;
    }
  }

  String _formatCompact(int n) {
    if (n < 1000) return '$n';
    if (n < 1000000)
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
    return '${(n / 1000000).toStringAsFixed(1)}M';
  }

  String _formatPercent(double f) => '${(f * 100).toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final lang = LangScope.of(context);
    final s = S.of(context);
    final accent = kAdminAccent;
    final textPrimary = isDark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF111827);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final surface = isDark ? const Color(0xFF141414) : Colors.white;
    final subtle = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6);
    final borderColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFE5E7EB);

    // Build signup series (last 7 days)
    final days7 = _lastNDays(7);
    final signupMap = {
      for (final e in (_data?.dailySignups ?? [])) e.date: e.count,
    };
    final signupPoints = days7.map((d) {
      final n = signupMap[d] ?? 0;
      return ChartPoint(
        label: _dayLabel(d, lang),
        value: n.toDouble(),
        tooltip: '$n',
      );
    }).toList();

    // Daily active (last 14 days)
    final days14 = _lastNDays(14);
    final daiMap = {
      for (final p in (_data?.dailyActiveUsers ?? [])) p.period: p.activeUsers,
    };
    final daiPoints = days14.map((d) {
      final n = daiMap[d] ?? 0;
      return ChartPoint(
        label: _shortDate(d, lang),
        value: n.toDouble(),
        tooltip: '$n',
      );
    }).toList();

    // Response time trend (last 14 days) — same date window as daily active users
    final rttMap = {
      for (final p in (_data?.responseTimeTrend ?? [])) p.period: p,
    };
    final rttPoints = days14.map((d) {
      final p = rttMap[d];
      final ms = p?.avgDurationMs.round() ?? 0;
      final count = p?.count ?? 0;
      return ChartPoint(
        label: _shortDate(d, lang),
        value: ms.toDouble(),
        tooltip: s.adminResponseTimeTooltip(ms, count),
      );
    }).toList();

    final adoption = _data?.mealPlanAdoption;
    final aiUsage = _data?.aiUsage ?? [];
    final maxAiTotal = aiUsage.isEmpty
        ? 1
        : aiUsage.map((u) => u.total).reduce(math.max);

    return RefreshIndicator(
      onRefresh: _load,
      color: accent,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Row(
            children: [
              Text(
                'Analytics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _loading ? null : _load,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _loading
                          ? SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: accent,
                              ),
                            )
                          : Icon(
                              Icons.refresh_rounded,
                              size: 13,
                              color: accent,
                            ),
                      const SizedBox(width: 5),
                      Text(
                        'Refresh',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_error != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF43F5E).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF43F5E).withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                _error!,
                style: const TextStyle(fontSize: 12, color: Color(0xFFF43F5E)),
              ),
            ),
          ],

          // ── Top Recipes ────────────────────────────────────────────────
          _Section(
            title: 'Top Recipes',
            subtitle: 'Last 30 days by views + favorites',
            isDark: isDark,
            surface: surface,
            borderColor: borderColor,
            loading: _loading && _data == null,
            skeletonHeight: 220,
            child: _data?.topRecipes.isEmpty ?? true
                ? _EmptyNote(isDark: isDark, text: 'No recipe activity yet')
                : Column(
                    children: (_data!.topRecipes).asMap().entries.map((e) {
                      final rank = e.key + 1;
                      final r = e.value;
                      final title = _viTitles[r.id] ?? r.title;
                      final isLast = e.key == _data!.topRecipes.length - 1;
                      return Column(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AdminRecipeDetailScreen(
                                  recipeId: r.id,
                                  isDarkMode: isDark,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 22,
                                    child: Text(
                                      '#$rank',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: rank == 1
                                            ? const Color(0xFFC98500)
                                            : textSub,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.favorite_rounded,
                                              size: 11,
                                              color: textSub,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              '${r.favoritesCount}',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                color: textSub,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Icon(
                                              Icons.remove_red_eye_outlined,
                                              size: 11,
                                              color: textSub,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              '${r.viewCount}',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                color: textSub,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 16,
                                    color: textSub,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!isLast) Divider(height: 1, color: borderColor),
                        ],
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 18),

          // ── Top Users ──────────────────────────────────────────────────
          _Section(
            title: 'Top Users',
            subtitle: 'Recipes created + favorites + chat sessions',
            isDark: isDark,
            surface: surface,
            borderColor: borderColor,
            loading: _loading && _data == null,
            skeletonHeight: 220,
            child: _data?.topUsers.isEmpty ?? true
                ? _EmptyNote(isDark: isDark, text: 'No user activity yet')
                : Column(
                    children: (_data!.topUsers).asMap().entries.map((e) {
                      final rank = e.key + 1;
                      final u = e.value;
                      final name = u.displayName;
                      final avatarColor = Color(
                        adminAvatarColorInt(name, isDark: isDark),
                      );
                      final initials = adminAvatarInitials(name);
                      final isLast = e.key == _data!.topUsers.length - 1;
                      return Column(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AdminUserDetailScreen(
                                  userId: u.id,
                                  isDarkMode: isDark,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 22,
                                    child: Text(
                                      '#$rank',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: rank == 1
                                            ? const Color(0xFFC98500)
                                            : textSub,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: avatarColor.withValues(
                                        alpha: 0.18,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      initials,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: avatarColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.menu_book_outlined,
                                              size: 10,
                                              color: textSub,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              '${u.recipesCreated}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: textSub,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.star_outline_rounded,
                                              size: 10,
                                              color: textSub,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              '${u.favoritesCount}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: textSub,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.chat_bubble_outline_rounded,
                                              size: 10,
                                              color: textSub,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              '${u.chatSessions}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: textSub,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 16,
                                    color: textSub,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!isLast) Divider(height: 1, color: borderColor),
                        ],
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 18),

          // ── Popular Labels + Dietary Distribution ───────────────────────
          _TwoColumn(
            left: _Section(
              title: 'Popular Labels',
              subtitle: 'Among favorited recipes',
              isDark: isDark,
              surface: surface,
              borderColor: borderColor,
              loading: _loading && _data == null,
              skeletonHeight: 130,
              child: _data?.popularLabels.isEmpty ?? true
                  ? _EmptyNote(isDark: isDark, text: 'No favorites yet')
                  : RankedBarChart(
                      items: [
                        for (final l in _data!.popularLabels)
                          (label: l.label, count: l.count),
                      ],
                      color: accent,
                      textSub: textSub,
                      subtle: subtle,
                    ),
            ),
            right: _Section(
              title: 'Dietary Distribution',
              subtitle: 'Across whole catalog',
              isDark: isDark,
              surface: surface,
              borderColor: borderColor,
              loading: _loading && _data == null,
              skeletonHeight: 130,
              child: _data?.dietaryDistribution.isEmpty ?? true
                  ? _EmptyNote(isDark: isDark, text: 'No dietary tags yet')
                  : RankedBarChart(
                      items: [
                        for (final l in _data!.dietaryDistribution)
                          (label: l.label, count: l.count),
                      ],
                      color: accent,
                      textSub: textSub,
                      subtle: subtle,
                    ),
            ),
          ),
          const SizedBox(height: 18),

          // ── Active Users — Daily ────────────────────────────────────────
          _SectionHeader(
            title: 'Daily Active Users — Last 14 Days',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _Card(
            isDark: isDark,
            surface: surface,
            borderColor: borderColor,
            child: _loading && _data == null
                ? _Skeleton(isDark: isDark, height: 110)
                : TrendLineChart(
                    points: daiPoints,
                    color: accent,
                    textSub: textSub,
                  ),
          ),
          const SizedBox(height: 18),

          // ── Response Time — Last 14 Days ─────────────────────────────────
          _SectionHeader(title: s.adminResponseTimeHeading, isDark: isDark),
          const SizedBox(height: 8),
          _Card(
            isDark: isDark,
            surface: surface,
            borderColor: borderColor,
            child: _loading && _data == null
                ? _Skeleton(isDark: isDark, height: 110)
                : TrendLineChart(
                    points: rttPoints,
                    color: accent,
                    textSub: textSub,
                  ),
          ),
          const SizedBox(height: 18),

          // ── New Signups ─────────────────────────────────────────────────
          _SectionHeader(title: 'New Signups — Last 7 Days', isDark: isDark),
          const SizedBox(height: 8),
          _Card(
            isDark: isDark,
            surface: surface,
            borderColor: borderColor,
            child: _loading && _data == null
                ? _Skeleton(isDark: isDark, height: 100)
                : ColumnBarChart(
                    points: signupPoints,
                    color: accent,
                    textSub: textSub,
                  ),
          ),
          const SizedBox(height: 18),

          // ── Meal Plan Adoption + AI Usage ────────────────────────────────
          IntrinsicHeight(
            child: _TwoColumn(
              stretch: true,
              left: _Section(
                title: 'Meal Plan Adoption',
                isDark: isDark,
                surface: surface,
                borderColor: borderColor,
                loading: _loading && _data == null,
                skeletonHeight: 160,
                expand: true,
                child: adoption == null
                    ? _EmptyNote(isDark: isDark, text: 'No data')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Adoption rate',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: textSub,
                                ),
                              ),
                              Text(
                                _formatPercent(adoption.adoptionRate),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _Meter(
                            fraction: adoption.adoptionRate,
                            color: accent,
                            subtle: subtle,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s.adminAdoptionRateDescription,
                            style: TextStyle(
                              fontSize: 10,
                              color: textSub,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _StatTile(
                            label: 'Total users',
                            value: _formatCompact(adoption.totalUsers),
                            subtle: subtle,
                            textPrimary: textPrimary,
                            textSub: textSub,
                          ),
                          const SizedBox(height: 6),
                          _StatTile(
                            label: 'With meal plans',
                            value: _formatCompact(adoption.usersWithMealPlans),
                            subtle: subtle,
                            textPrimary: textPrimary,
                            textSub: textSub,
                          ),
                          const SizedBox(height: 6),
                          _StatTile(
                            label: 'Total meal plans',
                            value: _formatCompact(adoption.totalMealPlans),
                            subtle: subtle,
                            textPrimary: textPrimary,
                            textSub: textSub,
                          ),
                          const SizedBox(height: 6),
                          _StatTile(
                            label: 'With suggestions',
                            value: _formatCompact(
                              adoption.usersWithSuggestions,
                            ),
                            subtle: subtle,
                            textPrimary: textPrimary,
                            textSub: textSub,
                          ),
                        ],
                      ),
              ),
              right: _Section(
                title: 'AI Feature Usage',
                isDark: isDark,
                surface: surface,
                borderColor: borderColor,
                loading: _loading && _data == null,
                skeletonHeight: 160,
                expand: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lang == 'vi' ? '30 ngày qua' : 'Last 30 days',
                      style: TextStyle(fontSize: 10.5, color: textSub),
                    ),
                    const SizedBox(height: 8),
                    if (aiUsage.isEmpty)
                      _EmptyNote(isDark: isDark, text: 'No AI requests yet')
                    else
                      ...aiUsage.map((u) {
                        final frac = u.total / maxAiTotal;
                        // fail rate status color
                        final failColor = u.failRate <= 0.05
                            ? const Color(0xFF10B981)
                            : u.failRate <= 0.2
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFEF4444);
                        return Tooltip(
                          message: s.adminAiUsageTooltip(u.total, u.failRate),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        s.adminAiRequestTypeDisplay(
                                          u.requestType,
                                        ),
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                          color: textSub,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (u.failed > 0) ...[
                                      Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: failColor.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          _formatPercent(u.failRate),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: failColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                    Text(
                                      '${u.total}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: accent,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Stack(
                                    children: [
                                      Container(height: 16, color: subtle),
                                      FractionallySizedBox(
                                        widthFactor: math.max(
                                          frac,
                                          u.total > 0 ? 0.03 : 0,
                                        ),
                                        child: Container(
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: accent,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 2),
                    InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              AdminAiRequestsScreen(isDarkMode: isDark),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.adminViewAllAiRequests,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: accent,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Layout helpers ─────────────────────────────────────────────────────────────

class _TwoColumn extends StatelessWidget {
  const _TwoColumn({
    required this.left,
    required this.right,
    this.stretch = false,
  });
  final Widget left;
  final Widget right;
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: stretch
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 10),
        Expanded(child: right),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.isDark});
  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.isDark,
    required this.surface,
    required this.borderColor,
    required this.loading,
    required this.skeletonHeight,
    required this.child,
    this.subtitle,
    this.expand = false,
  });
  final String title;
  final String? subtitle;
  final bool isDark;
  final Color surface;
  final Color borderColor;
  final bool loading;
  final double skeletonHeight;
  final Widget child;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF111827);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final card = _Card(
      isDark: isDark,
      surface: surface,
      borderColor: borderColor,
      child: loading
          ? _Skeleton(isDark: isDark, height: skeletonHeight)
          : child,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        if (subtitle != null)
          Text(subtitle!, style: TextStyle(fontSize: 10.5, color: textSub)),
        const SizedBox(height: 6),
        expand ? Expanded(child: card) : card,
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.isDark,
    required this.surface,
    required this.borderColor,
    required this.child,
  });
  final bool isDark;
  final Color surface;
  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.isDark, required this.text});
  final bool isDark;
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 12,
      color: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF),
    ),
  );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.isDark, required this.height});
  final bool isDark;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(8),
    ),
  );
}

class _Meter extends StatelessWidget {
  const _Meter({
    required this.fraction,
    required this.color,
    required this.subtle,
  });
  final double fraction;
  final Color color;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    final pct = fraction.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        children: [
          Container(height: 10, color: subtle),
          FractionallySizedBox(
            widthFactor: pct,
            child: Container(height: 10, color: color),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.subtle,
    required this.textPrimary,
    required this.textSub,
  });
  final String label;
  final String value;
  final Color subtle;
  final Color textPrimary;
  final Color textSub;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: subtle,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: textSub)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ],
    ),
  );
}
