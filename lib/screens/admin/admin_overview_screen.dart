import 'package:flutter/material.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';
import 'package:foodhub_mobile/models/admin.dart';
import 'package:foodhub_mobile/models/user.dart';
import 'package:foodhub_mobile/screens/admin/admin_recipe_detail_screen.dart';
import 'package:foodhub_mobile/screens/admin/admin_shell_screen.dart';
import 'package:foodhub_mobile/services/admin_service.dart';
import 'package:foodhub_mobile/services/api_exception.dart';

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({
    super.key,
    required this.user,
    required this.isDarkMode,
  });

  final UserModel user;
  final bool isDarkMode;

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  final _admin = AdminService();
  AdminOverview? _data;
  bool _loading = true;
  String? _error;

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
      final data = await _admin.getOverview();
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

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final lang = LangScope.of(context);
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final cardBg = isDark ? const Color(0xFF141414) : Colors.white;

    return RefreshIndicator(
      onRefresh: _load,
      color: kAdminAccent,
      child: ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // ── Greeting ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kAdminAccent, Color(0xFF4F46E5)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: kAdminAccent.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.user.fullName ?? widget.user.username,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Administrator',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Stats header ──────────────────────────────────────────────
        Row(
          children: [
            Text(
              'Overview',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _loading ? null : _load,
              child: AnimatedRotation(
                turns: _loading ? 1 : 0,
                duration: const Duration(milliseconds: 600),
                child: Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: _loading ? textSub.withValues(alpha: 0.4) : kAdminAccent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_error != null)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF43F5E).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF43F5E).withValues(alpha: 0.2)),
            ),
            child: Text(
              _error!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFF43F5E)),
            ),
          ),

        // ── Stat tiles ────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _loading && _data == null
                  ? _SkeletonTile(isDark: isDark)
                  : _StatTile(
                      icon: Icons.people_rounded,
                      label: 'Total Users',
                      value: _data != null ? '${_data!.totalUsers}' : '—',
                      color: const Color(0xFF6366F1),
                      isDark: isDark,
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _loading && _data == null
                  ? _SkeletonTile(isDark: isDark)
                  : _StatTile(
                      icon: Icons.menu_book_rounded,
                      label: 'Total Recipes',
                      value: _data != null ? '${_data!.totalRecipes}' : '—',
                      color: const Color(0xFF10B981),
                      isDark: isDark,
                    ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // ── Recent activity ───────────────────────────────────────────
        Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 10),

        if (_loading && _data == null)
          ...List.generate(
            4,
            (_) => _SkeletonActivity(isDark: isDark, cardBg: cardBg),
          )
        else if (_data != null && _data!.recentActivities.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'No recent activity',
              style: TextStyle(fontSize: 13, color: textSub),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                  blurRadius: isDark ? 12 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: (_data?.recentActivities ?? []).asMap().entries.map((e) {
                final index = e.key;
                final activity = e.value;
                final isLast = index == (_data!.recentActivities.length - 1);
                final isUser = activity.type == 'user';

                final color = isUser
                    ? const Color(0xFF6366F1)
                    : (activity.recipe?.isPublic ?? false
                        ? const Color(0xFF10B981)
                        : textSub);
                final icon = isUser
                    ? Icons.person_add_rounded
                    : (activity.recipe?.isPublic ?? false
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded);

                final title = isUser
                    ? (activity.user?.displayName ?? 'New user')
                    : (activity.recipe?.title ?? 'Recipe');
                final subtitle = isUser
                    ? 'New user joined · ${adminRelativeTime(activity.createdAt, lang)}'
                    : '${activity.recipe?.isPublic == true ? 'Public' : 'Private'} recipe · ${adminRelativeTime(activity.createdAt, lang)}';

                final rowContent = Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 16, color: color),
                    ),
                    const SizedBox(width: 10),
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
                          const SizedBox(height: 1),
                          Text(
                            subtitle,
                            style: TextStyle(fontSize: 11, color: textSub),
                          ),
                        ],
                      ),
                    ),
                    if (!isUser)
                      Icon(Icons.chevron_right_rounded, size: 18, color: textSub),
                  ],
                );

                return Column(
                  children: [
                    if (isUser)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        child: rowContent,
                      )
                    else
                      InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AdminRecipeDetailScreen(
                              recipeId: activity.recipe!.id,
                              isDarkMode: isDark,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          child: rowContent,
                        ),
                      ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        indent: 58,
                        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 14),
      ],
    ), // ListView
    ); // RefreshIndicator
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final shimmer = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6);
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: shimmer,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

class _SkeletonActivity extends StatelessWidget {
  const _SkeletonActivity({required this.isDark, required this.cardBg});
  final bool isDark;
  final Color cardBg;

  @override
  Widget build(BuildContext context) {
    final shimmer = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: shimmer, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 12, width: 140, decoration: BoxDecoration(color: shimmer, borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 5),
                Container(height: 10, width: 90, decoration: BoxDecoration(color: shimmer, borderRadius: BorderRadius.circular(6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
