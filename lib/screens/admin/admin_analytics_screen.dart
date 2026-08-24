import 'package:flutter/material.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';
import 'package:foodhub_mobile/models/admin.dart';
import 'package:foodhub_mobile/screens/admin/admin_recipe_detail_screen.dart';
import 'package:foodhub_mobile/screens/admin/admin_shell_screen.dart';
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

  // Vietnamese translations for top-recipe titles (fetched when lang == 'vi')
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

  // When lang == 'vi', fetch each top-recipe's Vietnamese translation in parallel.
  Future<void> _fetchViTitles(List<AdminTopRecipe> recipes) async {
    if (recipes.isEmpty) {
      setState(() => _viTitles = {});
      return;
    }
    final results = await Future.wait(
      recipes.map((r) async {
        try {
          final translated = await _admin.getRecipe(r.id, lang: 'vi');
          return MapEntry(r.id, translated.title);
        } catch (_) {
          return MapEntry(r.id, r.title);
        }
      }),
    );
    if (!mounted) return;
    setState(() => _viTitles = Map.fromEntries(results));
  }

  List<String> _last7Days() {
    final today = DateTime.now();
    return List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    });
  }

  String _dayLabel(String date, String lang) {
    try {
      final parts = date.split('-');
      final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      const enDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const viDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
      return lang == 'vi' ? viDays[dt.weekday - 1] : enDays[dt.weekday - 1];
    } catch (_) {
      return date;
    }
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

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final lang = LangScope.of(context);
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

    final days = _last7Days();
    final signupMap = {for (final s in (_data?.dailySignups ?? [])) s.date: s.count};
    final signupCounts = days.map((d) => signupMap[d] ?? 0).toList().cast<int>();
    final dayLabels = days.map((d) => _dayLabel(d, lang)).toList();
    final maxLabelCount = (_data?.popularLabels.isNotEmpty ?? false)
        ? _data!.popularLabels.first.count
        : 1;

    return RefreshIndicator(
      onRefresh: _load,
      color: kAdminAccent,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // ── Header ────────────────────────────────────────────────────
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
                    color: kAdminAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _loading
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, color: kAdminAccent),
                            )
                          : const Icon(Icons.refresh_rounded, size: 13, color: kAdminAccent),
                      const SizedBox(width: 5),
                      const Text('Refresh',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kAdminAccent)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_error != null)
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

          // ── Top Recipes (tappable list) ────────────────────────────────
          _SectionHeader(title: 'Most Favorited Recipes', isDark: isDark),
          const SizedBox(height: 8),
          _AnalyticsCard(
            isDark: isDark,
            child: _loading && _data == null
                ? _Skeleton(isDark: isDark, height: 120)
                : (_data?.topRecipes.isEmpty ?? true)
                    ? Text('No data yet', style: TextStyle(fontSize: 12, color: textSub))
                    : Column(
                        children: (_data?.topRecipes ?? []).asMap().entries.map((e) {
                          final rank = e.key + 1;
                          final r = e.value;
                          final title = _viTitles[r.id] ?? r.title;
                          final isLast = e.key == (_data!.topRecipes.length - 1);
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
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 26,
                                        child: Text(
                                          '#$rank',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: rank == 1 ? const Color(0xFFC98500) : textSub,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.chevron_right_rounded, size: 18, color: textSub),
                                    ],
                                  ),
                                ),
                              ),
                              if (!isLast)
                                Divider(
                                  height: 1,
                                  color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
                                ),
                            ],
                          );
                        }).toList(),
                      ),
          ),
          const SizedBox(height: 18),

          // ── Popular Labels ─────────────────────────────────────────────
          _SectionHeader(title: 'Popular Dietary Labels', isDark: isDark),
          const SizedBox(height: 8),
          _AnalyticsCard(
            isDark: isDark,
            child: _loading && _data == null
                ? _Skeleton(isDark: isDark, height: 120)
                : (_data?.popularLabels.isEmpty ?? true)
                    ? Text('No data yet', style: TextStyle(fontSize: 12, color: textSub))
                    : Column(
                        children: _data!.popularLabels.asMap().entries.map((e) {
                          final l = e.value;
                          final frac = l.count / maxLabelCount;
                          final color = Color(categoricalColor(e.key, isDark: isDark));
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 90,
                                  child: Text(
                                    l.label,
                                    style: TextStyle(
                                        fontSize: 11.5, fontWeight: FontWeight.w500, color: textSub),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (_, box) => Stack(
                                      children: [
                                        Container(
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        ),
                                        Container(
                                          height: 20,
                                          width: box.maxWidth * frac,
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.18),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    '${l.count}',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
          ),
          const SizedBox(height: 18),

          // ── Weekly Signups ─────────────────────────────────────────────
          _SectionHeader(title: 'New Users — Last 7 Days', isDark: isDark),
          const SizedBox(height: 8),
          _AnalyticsCard(
            isDark: isDark,
            child: _loading && _data == null
                ? _Skeleton(isDark: isDark, height: 100)
                : Column(
                    children: [
                      _BarChart(data: signupCounts, isDark: isDark, color: kAdminAccent),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: dayLabels
                            .map((d) => Text(d,
                                style: TextStyle(
                                    fontSize: 10, color: textSub, fontWeight: FontWeight.w500)))
                            .toList(),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
        ],
      ), // ListView
    ); // RefreshIndicator
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.isDark});

  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: isDark ? 12 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.data, required this.isDark, required this.color});

  final List<int> data;
  final bool isDark;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxVal = data.isEmpty ? 0 : data.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 96,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: data.map((v) {
          final frac = maxVal == 0 ? 0.0 : v / maxVal;
          final displayFrac = v > 0 ? frac.clamp(0.08, 1.0) : 0.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$v',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color),
                  ),
                  const SizedBox(height: 3),
                  Flexible(
                    child: FractionallySizedBox(
                      heightFactor: displayFrac,
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.isDark, required this.height});
  final bool isDark;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
