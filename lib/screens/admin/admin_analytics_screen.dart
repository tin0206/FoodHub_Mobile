import 'package:flutter/material.dart';
import 'package:foodhub_mobile/screens/admin/admin_shell_screen.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key, required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode;
    final textPrimary =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final textSub =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // ── Top Recipes ───────────────────────────────────────────────
        _SectionHeader(title: 'Most Favorited Recipes', isDark: isDark),
        const SizedBox(height: 10),
        _AnalyticsCard(
          isDark: isDark,
          child: Column(
            children: _kTopRecipes.asMap().entries.map((e) {
              final rank = e.key + 1;
              final r = e.value;
              final maxFav = _kTopRecipes.first.favorites;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text(
                        '#$rank',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: rank == 1
                              ? const Color(0xFFF59E0B)
                              : textSub,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          LayoutBuilder(
                            builder: (_, box) {
                              final frac = r.favorites / maxFav;
                              return Stack(
                                children: [
                                  Container(
                                    height: 5,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1E1E1E)
                                          : const Color(0xFFF3F4F6),
                                      borderRadius:
                                          BorderRadius.circular(99),
                                    ),
                                  ),
                                  Container(
                                    height: 5,
                                    width: box.maxWidth * frac,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          kAdminAccent,
                                          kAdminAccent
                                              .withValues(alpha: 0.6),
                                        ],
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(99),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          size: 11,
                          color: const Color(0xFFF43F5E)
                              .withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${r.favorites}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 18),

        // ── Popular Labels ────────────────────────────────────────────
        _SectionHeader(title: 'Popular Dietary Labels', isDark: isDark),
        const SizedBox(height: 10),
        _AnalyticsCard(
          isDark: isDark,
          child: Column(
            children: _kLabelStats.map((l) {
              final maxCount = _kLabelStats.first.count;
              final frac = l.count / maxCount;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        l.label,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: textSub,
                        ),
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (_, box) => Stack(
                          children: [
                            Container(
                              height: 20,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E1E1E)
                                    : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            Container(
                              height: 20,
                              width: box.maxWidth * frac,
                              decoration: BoxDecoration(
                                color: l.color.withValues(alpha: 0.18),
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
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: l.color,
                        ),
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
        const SizedBox(height: 10),
        _AnalyticsCard(
          isDark: isDark,
          child: Column(
            children: [
              _BarChart(
                data: _kWeeklySignups,
                isDark: isDark,
                color: kAdminAccent,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _kWeekDays
                    .map(
                      (d) => Text(
                        d,
                        style: TextStyle(
                          fontSize: 10,
                          color: textSub,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ── AI Usage ──────────────────────────────────────────────────
        _SectionHeader(title: 'AI Scan Activity — Last 7 Days', isDark: isDark),
        const SizedBox(height: 10),
        _AnalyticsCard(
          isDark: isDark,
          child: Column(
            children: [
              _BarChart(
                data: _kAiScans,
                isDark: isDark,
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _kWeekDays
                    .map(
                      (d) => Text(
                        d,
                        style: TextStyle(
                          fontSize: 10,
                          color: textSub,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
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
  const _BarChart({
    required this.data,
    required this.isDark,
    required this.color,
  });

  final List<int> data;
  final bool isDark;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: data.map((v) {
          final frac = maxVal == 0 ? 0.0 : v / maxVal;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$v',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Flexible(
                    child: FractionallySizedBox(
                      heightFactor: frac < 0.08 ? 0.08 : frac,
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              color.withValues(alpha: 0.5),
                              color,
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5),
                          ),
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

// ── Dummy data ────────────────────────────────────────────────────────────────

class _TopRecipe {
  const _TopRecipe({required this.title, required this.favorites});
  final String title;
  final int favorites;
}

class _LabelStat {
  const _LabelStat({
    required this.label,
    required this.count,
    required this.color,
  });
  final String label;
  final int count;
  final Color color;
}

const _kTopRecipes = [
  _TopRecipe(title: 'Green Smoothie Bowl', favorites: 201),
  _TopRecipe(title: 'Bánh Mì Sandwich', favorites: 176),
  _TopRecipe(title: 'Phở Bò Hà Nội', favorites: 142),
  _TopRecipe(title: 'Avocado Toast', favorites: 133),
  _TopRecipe(title: 'Bún Bò Huế', favorites: 98),
];

const _kLabelStats = [
  _LabelStat(label: 'Vietnamese', count: 312, color: Color(0xFF6366F1)),
  _LabelStat(label: 'Vegan', count: 278, color: Color(0xFF10B981)),
  _LabelStat(label: 'High Protein', count: 241, color: Color(0xFF3B82F6)),
  _LabelStat(label: 'Quick Meal', count: 198, color: Color(0xFFF59E0B)),
  _LabelStat(label: 'Breakfast', count: 156, color: Color(0xFFF97316)),
  _LabelStat(label: 'Keto', count: 112, color: Color(0xFF8B5CF6)),
];

const _kWeeklySignups = [3, 7, 5, 12, 8, 15, 10];
const _kAiScans = [18, 24, 31, 19, 42, 38, 27];
const _kWeekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
