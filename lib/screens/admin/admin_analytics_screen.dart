import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';
import 'package:foodhub_mobile/models/admin.dart';
import 'package:foodhub_mobile/screens/admin/admin_recipe_detail_screen.dart';
import 'package:foodhub_mobile/screens/admin/admin_shell_screen.dart';
import 'package:foodhub_mobile/screens/admin/admin_user_detail_screen.dart';
import 'package:foodhub_mobile/services/admin_service.dart';
import 'package:foodhub_mobile/services/api_exception.dart';

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

  List<String> _lastNWeekStarts(int n) {
    final today = DateTime.now();
    final dow = today.weekday; // 1=Mon…7=Sun
    final thisMonday = today.subtract(Duration(days: dow - 1));
    final base = DateTime(thisMonday.year, thisMonday.month, thisMonday.day);
    return List.generate(n, (i) {
      final d = base.subtract(Duration(days: (n - 1 - i) * 7));
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    });
  }

  String _shortDate(String dateStr, String lang) {
    try {
      final p = dateStr.split('-');
      final d = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
      const enM = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      const viM = ['Th1','Th2','Th3','Th4','Th5','Th6','Th7','Th8','Th9','Th10','Th11','Th12'];
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
      const en = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
      const vi = ['T2','T3','T4','T5','T6','T7','CN'];
      return lang == 'vi' ? vi[d.weekday - 1] : en[d.weekday - 1];
    } catch (_) {
      return dateStr;
    }
  }

  String _formatCompact(int n) {
    if (n < 1000) return '$n';
    if (n < 1000000) return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
    return '${(n / 1000000).toStringAsFixed(1)}M';
  }

  String _formatPercent(double f) => '${(f * 100).toStringAsFixed(1)}%';

  // ── AI request type display ───────────────────────────────────────────────────

  String _aiTypeLabel(String type) {
    switch (type) {
      case 'chat': return 'Chat';
      case 'dish_recognition': return 'Dish Detect';
      case 'ingredients_detect': return 'Ingredients';
      case 'meal_suggest': return 'Meal Suggest';
      case 'shopping_list': return 'Shopping List';
      default: return type.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final lang = LangScope.of(context);
    final accent = kAdminAccent;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final surface = isDark ? const Color(0xFF141414) : Colors.white;
    final subtle = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6);
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);

    // Build signup series (last 7 days)
    final days7 = _lastNDays(7);
    final signupMap = {for (final s in (_data?.dailySignups ?? [])) s.date: s.count};
    final signupCounts = days7.map((d) => signupMap[d] ?? 0).cast<int>().toList();

    // Daily active (last 14 days)
    final days14 = _lastNDays(14);
    final daiMap = {for (final p in (_data?.dailyActiveUsers ?? [])) p.period: p.activeUsers};
    final daiCounts = days14.map((d) => daiMap[d] ?? 0).cast<int>().toList();

    // Weekly active (last 8 weeks)
    final weeks8 = _lastNWeekStarts(8);
    final wauMap = {for (final p in (_data?.weeklyActiveUsers ?? [])) p.period: p.activeUsers};
    final wauCounts = weeks8.map((d) => wauMap[d] ?? 0).cast<int>().toList();

    final adoption = _data?.mealPlanAdoption;
    final aiUsage = _data?.aiUsage ?? [];
    final maxAiTotal = aiUsage.isEmpty ? 1 : aiUsage.map((u) => u.total).reduce(math.max);

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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _loading ? null : _load,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                              child: CircularProgressIndicator(strokeWidth: 2, color: accent),
                            )
                          : Icon(Icons.refresh_rounded, size: 13, color: accent),
                      const SizedBox(width: 5),
                      Text('Refresh',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accent)),
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
                border: Border.all(color: const Color(0xFFF43F5E).withValues(alpha: 0.2)),
              ),
              child: Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFFF43F5E))),
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
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => AdminRecipeDetailScreen(recipeId: r.id, isDarkMode: isDark),
                            )),
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
                                        color: rank == 1 ? const Color(0xFFC98500) : textSub,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                            Icon(Icons.favorite_rounded, size: 11, color: textSub),
                                            const SizedBox(width: 3),
                                            Text('${r.favoritesCount}',
                                                style: TextStyle(fontSize: 10.5, color: textSub)),
                                            const SizedBox(width: 10),
                                            Icon(Icons.remove_red_eye_outlined, size: 11, color: textSub),
                                            const SizedBox(width: 3),
                                            Text('${r.viewCount}',
                                                style: TextStyle(fontSize: 10.5, color: textSub)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded, size: 16, color: textSub),
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
                      final avatarColor = Color(adminAvatarColorInt(name, isDark: isDark));
                      final initials = adminAvatarInitials(name);
                      final isLast = e.key == _data!.topUsers.length - 1;
                      return Column(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => AdminUserDetailScreen(userId: u.id, isDarkMode: isDark),
                            )),
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
                                        color: rank == 1 ? const Color(0xFFC98500) : textSub,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: avatarColor.withValues(alpha: 0.18),
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                            Icon(Icons.menu_book_outlined, size: 10, color: textSub),
                                            const SizedBox(width: 3),
                                            Text('${u.recipesCreated}',
                                                style: TextStyle(fontSize: 10, color: textSub)),
                                            const SizedBox(width: 8),
                                            Icon(Icons.star_outline_rounded, size: 10, color: textSub),
                                            const SizedBox(width: 3),
                                            Text('${u.favoritesCount}',
                                                style: TextStyle(fontSize: 10, color: textSub)),
                                            const SizedBox(width: 8),
                                            Icon(Icons.chat_bubble_outline_rounded, size: 10, color: textSub),
                                            const SizedBox(width: 3),
                                            Text('${u.chatSessions}',
                                                style: TextStyle(fontSize: 10, color: textSub)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded, size: 16, color: textSub),
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
                  : _SequentialBars(
                      items: _data!.popularLabels,
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
                  : _SequentialBars(
                      items: _data!.dietaryDistribution,
                      color: accent,
                      textSub: textSub,
                      subtle: subtle,
                    ),
            ),
          ),
          const SizedBox(height: 18),

          // ── Active Users — Daily ────────────────────────────────────────
          _SectionHeader(title: 'Daily Active Users — Last 14 Days', isDark: isDark),
          const SizedBox(height: 8),
          _Card(
            isDark: isDark,
            surface: surface,
            borderColor: borderColor,
            child: _loading && _data == null
                ? _Skeleton(isDark: isDark, height: 110)
                : _TrendLine(
                    values: daiCounts,
                    labels: days14.map((d) => _shortDate(d, lang)).toList(),
                    color: accent,
                    subtle: subtle,
                    textSub: textSub,
                  ),
          ),
          const SizedBox(height: 18),

          // ── Active Users — Weekly ───────────────────────────────────────
          _SectionHeader(title: 'Weekly Active Users — Last 8 Weeks', isDark: isDark),
          const SizedBox(height: 8),
          _Card(
            isDark: isDark,
            surface: surface,
            borderColor: borderColor,
            child: _loading && _data == null
                ? _Skeleton(isDark: isDark, height: 110)
                : _ColumnChart(
                    values: wauCounts,
                    labels: weeks8.map((d) => _shortDate(d, lang)).toList(),
                    color: accent,
                    subtle: subtle,
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
                : _ColumnChart(
                    values: signupCounts,
                    labels: days7.map((d) => _dayLabel(d, lang)).toList(),
                    color: accent,
                    subtle: subtle,
                    textSub: textSub,
                  ),
          ),
          const SizedBox(height: 18),

          // ── Meal Plan Adoption + AI Usage ────────────────────────────────
          _TwoColumn(
            left: _Section(
              title: 'Meal Plan Adoption',
              isDark: isDark,
              surface: surface,
              borderColor: borderColor,
              loading: _loading && _data == null,
              skeletonHeight: 160,
              child: adoption == null
                  ? _EmptyNote(isDark: isDark, text: 'No data')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Adoption rate',
                                style: TextStyle(fontSize: 11.5, color: textSub)),
                            Text(
                              _formatPercent(adoption.adoptionRate),
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: accent),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _Meter(fraction: adoption.adoptionRate, color: accent, subtle: subtle),
                        const SizedBox(height: 12),
                        _StatTile(
                            label: 'Total users',
                            value: _formatCompact(adoption.totalUsers),
                            subtle: subtle,
                            textPrimary: textPrimary,
                            textSub: textSub),
                        const SizedBox(height: 6),
                        _StatTile(
                            label: 'With meal plans',
                            value: _formatCompact(adoption.usersWithMealPlans),
                            subtle: subtle,
                            textPrimary: textPrimary,
                            textSub: textSub),
                        const SizedBox(height: 6),
                        _StatTile(
                            label: 'Total meal plans',
                            value: _formatCompact(adoption.totalMealPlans),
                            subtle: subtle,
                            textPrimary: textPrimary,
                            textSub: textSub),
                        const SizedBox(height: 6),
                        _StatTile(
                            label: 'With suggestions',
                            value: _formatCompact(adoption.usersWithSuggestions),
                            subtle: subtle,
                            textPrimary: textPrimary,
                            textSub: textSub),
                      ],
                    ),
            ),
            right: _Section(
              title: 'AI Feature Usage',
              subtitle: 'Last 30 days',
              isDark: isDark,
              surface: surface,
              borderColor: borderColor,
              loading: _loading && _data == null,
              skeletonHeight: 160,
              child: aiUsage.isEmpty
                  ? _EmptyNote(isDark: isDark, text: 'No AI requests yet')
                  : Column(
                      children: aiUsage.map((u) {
                        final frac = u.total / maxAiTotal;
                        // fail rate status color
                        final failColor = u.failRate <= 0.05
                            ? const Color(0xFF10B981)
                            : u.failRate <= 0.2
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFFEF4444);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _aiTypeLabel(u.requestType),
                                      style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                          color: textSub),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (u.failed > 0) ...[
                                    Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: failColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _formatPercent(u.failRate),
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: failColor),
                                      ),
                                    ),
                                  ],
                                  Text(
                                    '${u.total}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: accent),
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
                                          color: accent.withValues(alpha: 0.28),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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
  const _TwoColumn({required this.left, required this.right});
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
  });
  final String title;
  final String? subtitle;
  final bool isDark;
  final Color surface;
  final Color borderColor;
  final bool loading;
  final double skeletonHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700, color: textPrimary)),
        if (subtitle != null)
          Text(subtitle!,
              style: TextStyle(fontSize: 10.5, color: textSub)),
        const SizedBox(height: 6),
        _Card(
          isDark: isDark,
          surface: surface,
          borderColor: borderColor,
          child: loading ? _Skeleton(isDark: isDark, height: skeletonHeight) : child,
        ),
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

// ── Data viz widgets ───────────────────────────────────────────────────────────

class _SequentialBars extends StatelessWidget {
  const _SequentialBars({
    required this.items,
    required this.color,
    required this.textSub,
    required this.subtle,
  });
  final List<AdminLabelCount> items;
  final Color color;
  final Color textSub;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    final maxCount = items.isEmpty ? 1 : items.map((l) => l.count).reduce(math.max);
    return Column(
      children: items.map((l) {
        final frac = maxCount == 0 ? 0.0 : l.count / maxCount;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  l.label,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w500, color: textSub),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Stack(
                    children: [
                      Container(height: 18, color: subtle),
                      FractionallySizedBox(
                        widthFactor: math.max(frac, l.count > 0 ? 0.03 : 0),
                        child: Container(
                          height: 18,
                          color: color.withValues(alpha: 0.25),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 30,
                child: Text(
                  '${l.count}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ColumnChart extends StatelessWidget {
  const _ColumnChart({
    required this.values,
    required this.labels,
    required this.color,
    required this.subtle,
    required this.textSub,
  });
  final List<int> values;
  final List<String> labels;
  final Color color;
  final Color subtle;
  final Color textSub;

  @override
  Widget build(BuildContext context) {
    final maxVal = values.isEmpty ? 0 : values.reduce(math.max);
    return Column(
      children: [
        SizedBox(
          height: 96,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: values.asMap().entries.map((e) {
              final v = e.value;
              final frac = maxVal == 0 ? 0.0 : v / maxVal;
              final displayFrac = v > 0 ? frac.clamp(0.08, 1.0) : 0.0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '$v',
                        style: TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w700, color: color),
                      ),
                      const SizedBox(height: 3),
                      Flexible(
                        child: FractionallySizedBox(
                          heightFactor: displayFrac,
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels.map((l) => Expanded(
            child: Text(
              l,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 9.5, fontWeight: FontWeight.w500, color: textSub),
            ),
          )).toList(),
        ),
      ],
    );
  }
}

class _TrendLine extends StatelessWidget {
  const _TrendLine({
    required this.values,
    required this.labels,
    required this.color,
    required this.subtle,
    required this.textSub,
  });
  final List<int> values;
  final List<String> labels;
  final Color color;
  final Color subtle;
  final Color textSub;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, box) {
        const h = 96.0;
        final w = box.maxWidth;
        final maxVal = values.isEmpty ? 1 : values.reduce(math.max);
        final n = values.length;
        if (n < 2) {
          return SizedBox(height: h + 24, child: _ColumnChart(
            values: values, labels: labels, color: color, subtle: subtle, textSub: textSub));
        }
        final stepX = w / (n - 1);
        final points = values.asMap().entries.map((e) {
          final x = e.key * stepX;
          final y = h - 4 - (e.value / maxVal) * (h - 12);
          return Offset(x, y);
        }).toList();

        // mid label index
        final midIdx = (labels.length - 1) ~/ 2;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: h,
              width: w,
              child: CustomPaint(
                painter: _TrendLinePainter(
                  points: points,
                  color: color,
                  chartH: h,
                  chartW: w,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: labels.asMap().entries.map((e) {
                final show = e.key == 0 || e.key == labels.length - 1 || e.key == midIdx;
                return Expanded(
                  child: Text(
                    show ? e.value : '',
                    textAlign: e.key == 0
                        ? TextAlign.left
                        : e.key == labels.length - 1
                            ? TextAlign.right
                            : TextAlign.center,
                    style: TextStyle(fontSize: 9, color: textSub),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  _TrendLinePainter({
    required this.points,
    required this.color,
    required this.chartH,
    required this.chartW,
  });
  final List<Offset> points;
  final Color color;
  final double chartH;
  final double chartW;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }

    // Area fill
    final area = Path.from(path)
      ..lineTo(points.last.dx, chartH)
      ..lineTo(points.first.dx, chartH)
      ..close();
    canvas.drawPath(
      area,
      Paint()..color = color.withValues(alpha: 0.10),
    );

    // Line
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    // Dots
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final radius = i == points.length - 1 ? 3.0 : 2.0;
      canvas.drawCircle(p, radius, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_TrendLinePainter old) =>
      old.points != points || old.color != color;
}

class _Meter extends StatelessWidget {
  const _Meter({required this.fraction, required this.color, required this.subtle});
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
            Text(label,
                style: TextStyle(fontSize: 11, color: textSub)),
            Text(value,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
          ],
        ),
      );
}
