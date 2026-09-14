import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:foodhub_mobile/config/api_config.dart';
import 'package:foodhub_mobile/models/admin.dart';
import 'package:foodhub_mobile/models/recipe.dart';
import 'package:foodhub_mobile/models/user.dart';
import 'package:foodhub_mobile/screens/admin/admin_recipe_detail_screen.dart';
import 'package:foodhub_mobile/screens/admin/admin_shell_screen.dart';
import 'package:foodhub_mobile/screens/admin/admin_user_form_screen.dart';
import 'package:foodhub_mobile/services/admin_service.dart';
import 'package:foodhub_mobile/services/api_exception.dart';

class AdminUserDetailScreen extends StatefulWidget {
  const AdminUserDetailScreen({
    super.key,
    required this.userId,
    required this.isDarkMode,
  });

  final int userId;
  final bool isDarkMode;

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  final _admin = AdminService();
  AdminUserDetail? _detail;
  bool _loading = true;
  String? _error;
  bool _toggling = false;

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
      final detail = await _admin.getUserDetail(widget.userId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
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

  void _confirmToggleActive() {
    final isDark = widget.isDarkMode;
    final user = _detail?.user;
    if (user == null || _toggling) return;
    final isActive = user.isActive;
    final action = isActive ? 'Deactivate' : 'Activate';
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$action Account?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
          ),
        ),
        content: Text(
          isActive
              ? '${user.fullName ?? user.username} will lose access to the app.'
              : '${user.fullName ?? user.username} will regain access to the app.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF6B7280),
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: isActive
                  ? const Color(0xFFF43F5E)
                  : const Color(0xFF10B981),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(action),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true || !mounted) return;
      setState(() => _toggling = true);
      try {
        final updated = await _admin.updateUser(widget.userId, {
          'is_active': !isActive,
        });
        if (!mounted) return;
        setState(() {
          _detail = AdminUserDetail(
            user: updated,
            recipesCount: _detail?.recipesCount ?? 0,
            savedCount: _detail?.savedCount ?? 0,
          );
          _toggling = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _toggling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : '$e')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final bg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF141414) : Colors.white;
    final textPrimary = isDark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF111827);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: kAdminAccent,
          ),
        ),
      );
    }

    if (_error != null || _detail == null) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error ?? 'User not found',
                style: TextStyle(color: textSub),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final detail = _detail!;
    final user = detail.user;
    final name = user.fullName ?? user.username;
    final avatarColor = Color(adminAvatarColorInt(name, isDark: isDark));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: bg,
        body: Column(
          children: [
            // ── Gradient header ───────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 2, 8, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AdminUserFormScreen(
                                    isDarkMode: isDark,
                                    user: user,
                                  ),
                                ),
                              );
                              _load();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 27,
                              backgroundColor: avatarColor.withValues(
                                alpha: 0.25,
                              ),
                              child: Text(
                                adminAvatarInitials(name),
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: avatarColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  user.email,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.68),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 7),
                                Row(
                                  children: [
                                    _GradientRoleBadge(role: user.role),
                                    const SizedBox(width: 6),
                                    _GradientStatusBadge(
                                      isActive: user.isActive,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _CompactStat(
                                icon: Icons.menu_book_rounded,
                                value: '${detail.recipesCount}',
                                label: 'recipes',
                              ),
                              const SizedBox(height: 6),
                              _CompactStat(
                                icon: Icons.favorite_rounded,
                                value: '${detail.savedCount}',
                                label: 'saved',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    TabBar(
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
                      indicatorColor: Colors.white,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      dividerColor: Colors.white.withValues(alpha: 0.15),
                      tabs: [
                        const Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_rounded, size: 14),
                              SizedBox(width: 5),
                              Text('Profile'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.favorite_rounded, size: 14),
                              const SizedBox(width: 5),
                              const Text('Saved'),
                              const SizedBox(width: 4),
                              _TabCountBadge(count: detail.savedCount),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.menu_book_rounded, size: 14),
                              const SizedBox(width: 5),
                              const Text('Recipes'),
                              const SizedBox(width: 4),
                              _TabCountBadge(count: detail.recipesCount),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Tab content ───────────────────────────────────────────
            Expanded(
              child: TabBarView(
                children: [
                  _ProfileTab(
                    user: user,
                    isDark: isDark,
                    cardBg: cardBg,
                    textPrimary: textPrimary,
                    textSub: textSub,
                    isActive: user.isActive,
                    toggling: _toggling,
                    onToggleActive: _confirmToggleActive,
                  ),
                  _LazyRecipeListTab(
                    userId: widget.userId,
                    isDark: isDark,
                    cardBg: cardBg,
                    textPrimary: textPrimary,
                    textSub: textSub,
                    emptyMessage: 'No saved recipes yet',
                    emptyIcon: Icons.favorite_border_rounded,
                    loader: (id) => AdminService().getUserFavorites(id),
                  ),
                  _LazyRecipeListTab(
                    userId: widget.userId,
                    isDark: isDark,
                    cardBg: cardBg,
                    textPrimary: textPrimary,
                    textSub: textSub,
                    emptyMessage: 'No recipes created yet',
                    emptyIcon: Icons.menu_book_outlined,
                    loader: (id) => AdminService().getUserRecipes(id),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header helpers ─────────────────────────────────────────────────────────────

class _CompactStat extends StatelessWidget {
  const _CompactStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: Colors.white.withValues(alpha: 0.6)),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

class _GradientRoleBadge extends StatelessWidget {
  const _GradientRoleBadge({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isAdmin ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.shield_rounded : Icons.person_rounded,
            size: 11,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isAdmin ? 'Admin' : 'User',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientStatusBadge extends StatelessWidget {
  const _GradientStatusBadge({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF34D399)
                  : const Color(0xFFF87171),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabCountBadge extends StatelessWidget {
  const _TabCountBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Tab: Profile ──────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.user,
    required this.isDark,
    required this.cardBg,
    required this.textPrimary,
    required this.textSub,
    required this.isActive,
    required this.toggling,
    required this.onToggleActive,
  });

  final UserModel user;
  final bool isDark;
  final Color cardBg;
  final Color textPrimary;
  final Color textSub;
  final bool isActive;
  final bool toggling;
  final VoidCallback onToggleActive;

  static String _genderLabel(String? gender) {
    switch (gender) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'other':
        return 'Other';
      default:
        return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(14),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _InfoCard(
                title: 'Account',
                icon: Icons.badge_rounded,
                isDark: isDark,
                cardBg: cardBg,
                textPrimary: textPrimary,
                textSub: textSub,
                rows: [
                  _InfoRow(
                    icon: Icons.tag_rounded,
                    label: 'User ID',
                    value: '#${user.id}',
                  ),
                  _InfoRow(
                    icon: Icons.alternate_email_rounded,
                    label: 'Username',
                    value: user.username,
                  ),
                  _InfoRow(
                    icon: Icons.mail_outline_rounded,
                    label: 'Email',
                    value: user.email,
                  ),
                  _InfoRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Full Name',
                    value: user.fullName ?? '—',
                  ),
                  _InfoRow(
                    icon: Icons.cake_outlined,
                    label: 'Age',
                    value: user.age != null ? '${user.age} years' : '—',
                  ),
                  _InfoRow(
                    icon: Icons.monitor_weight_outlined,
                    label: 'Weight',
                    value: user.weight != null ? '${user.weight} kg' : '—',
                  ),
                  _InfoRow(
                    icon: Icons.wc_rounded,
                    label: 'Gender',
                    value: _genderLabel(user.gender),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                title: 'Nutrition Goals',
                icon: Icons.local_fire_department_rounded,
                isDark: isDark,
                cardBg: cardBg,
                textPrimary: textPrimary,
                textSub: textSub,
                rows: [
                  _InfoRow(
                    icon: Icons.local_fire_department_outlined,
                    label: 'Calories (kcal/day)',
                    value: user.calorieTarget != null
                        ? '${user.calorieTarget} kcal/day'
                        : '—',
                  ),
                  _InfoRow(
                    icon: Icons.egg_outlined,
                    label: 'Protein (g/day)',
                    value: user.proteinTarget != null
                        ? '${user.proteinTarget} g/day'
                        : '—',
                  ),
                  _InfoRow(
                    icon: Icons.grain_outlined,
                    label: 'Carbs (g/day)',
                    value: user.carbTarget != null
                        ? '${user.carbTarget} g/day'
                        : '—',
                  ),
                  _InfoRow(
                    icon: Icons.water_drop_outlined,
                    label: 'Fat (g/day)',
                    value: user.fatTarget != null
                        ? '${user.fatTarget} g/day'
                        : '—',
                  ),
                  _InfoRow(
                    icon: Icons.flag_outlined,
                    label: 'Primary Goal',
                    value: user.primaryGoal ?? '—',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                title: 'Dietary Restrictions',
                icon: Icons.eco_rounded,
                isDark: isDark,
                cardBg: cardBg,
                textPrimary: textPrimary,
                textSub: textSub,
                rows: const [],
                customChild: user.dietaryRestrictions.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'None specified',
                          style: TextStyle(fontSize: 13, color: textSub),
                        ),
                      )
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: user.dietaryRestrictions.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: kAdminAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: kAdminAccent,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: toggling ? null : onToggleActive,
                icon: toggling
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFF43F5E),
                        ),
                      )
                    : Icon(
                        isActive
                            ? Icons.block_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 16,
                      ),
                label: Text(
                  isActive ? 'Deactivate Account' : 'Activate Account',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isActive
                      ? const Color(0xFFF43F5E)
                      : const Color(0xFF10B981),
                  side: BorderSide(
                    color: isActive
                        ? const Color(0xFFF43F5E)
                        : const Color(0xFF10B981),
                  ),
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ]),
          ),
        ),
        const SliverFillRemaining(hasScrollBody: false, child: SizedBox()),
      ],
    );
  }
}

// ── Tab: Lazy-loaded recipe list ──────────────────────────────────────────────

class _LazyRecipeListTab extends StatefulWidget {
  const _LazyRecipeListTab({
    required this.userId,
    required this.isDark,
    required this.cardBg,
    required this.textPrimary,
    required this.textSub,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.loader,
  });

  final int userId;
  final bool isDark;
  final Color cardBg;
  final Color textPrimary;
  final Color textSub;
  final String emptyMessage;
  final IconData emptyIcon;
  final Future<List<RecipeModel>> Function(int userId) loader;

  @override
  State<_LazyRecipeListTab> createState() => _LazyRecipeListTabState();
}

class _LazyRecipeListTabState extends State<_LazyRecipeListTab> {
  List<RecipeModel>? _recipes;
  bool _loading = false;
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
      final recipes = await widget.loader(widget.userId);
      if (!mounted) return;
      setState(() {
        _recipes = recipes;
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
    final isDark = widget.isDark;
    final cardBg = widget.cardBg;
    final textPrimary = widget.textPrimary;
    final textSub = widget.textSub;

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2.5, color: kAdminAccent),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(fontSize: 12, color: textSub)),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final recipes = _recipes ?? [];
    if (recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.emptyIcon,
              size: 42,
              color: textSub.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 10),
            Text(
              widget.emptyMessage,
              style: TextStyle(fontSize: 13, color: textSub),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: recipes.length,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final r = recipes[i];
        final resolvedUrl = ApiConfig.resolveImageUrl(r.imageUrl);
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  AdminRecipeDetailScreen(recipeId: r.id, isDarkMode: isDark),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                  blurRadius: isDark ? 10 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: resolvedUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: resolvedUrl,
                          width: 42,
                          height: 42,
                          fit: BoxFit.cover,
                          errorWidget: (ctx, err, st) =>
                              _RecipeThumbPlaceholder(recipeId: r.id),
                        )
                      : _RecipeThumbPlaceholder(recipeId: r.id),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            r.isPrivate
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 11,
                            color: textSub,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            r.isPrivate ? 'Private' : 'Public',
                            style: TextStyle(fontSize: 11, color: textSub),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '#${r.id}',
                            style: TextStyle(fontSize: 11, color: textSub),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, size: 18, color: textSub),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.cardBg,
    required this.textPrimary,
    required this.textSub,
    required this.rows,
    this.customChild,
  });

  final String title;
  final IconData icon;
  final bool isDark;
  final Color cardBg;
  final Color textPrimary;
  final Color textSub;
  final List<_InfoRow> rows;
  final Widget? customChild;

  @override
  Widget build(BuildContext context) {
    final divider = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: isDark ? 10 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: kAdminAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 14, color: kAdminAccent),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          if (rows.isNotEmpty || customChild != null) ...[
            const SizedBox(height: 12),
            if (customChild != null)
              customChild!
            else
              ...rows.asMap().entries.map((e) {
                final isLast = e.key == rows.length - 1;
                final row = e.value;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Row(
                        children: [
                          Icon(
                            row.icon,
                            size: 14,
                            color: kAdminAccent.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 9),
                          Text(
                            row.label,
                            style: TextStyle(fontSize: 12.5, color: textSub),
                          ),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              row.value,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast) Divider(height: 1, color: divider),
                  ],
                );
              }),
          ],
        ],
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

// ── Recipe thumbnail placeholder ──────────────────────────────────────────────

class _RecipeThumbPlaceholder extends StatelessWidget {
  const _RecipeThumbPlaceholder({required this.recipeId});
  final int recipeId;

  static const _colors = [
    Color(0xFF6366F1),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Color(0xFFF97316),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[recipeId % _colors.length];
    return Container(
      width: 42,
      height: 42,
      color: color.withValues(alpha: 0.12),
      child: Icon(Icons.restaurant_rounded, size: 18, color: color),
    );
  }
}
