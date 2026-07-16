import 'package:flutter/material.dart';
import 'package:foodhub_mobile/screens/admin/admin_shell_screen.dart';
import 'package:foodhub_mobile/screens/admin/admin_user_form_screen.dart';
import 'package:foodhub_mobile/screens/admin/admin_users_screen.dart';

class AdminUserDetailScreen extends StatefulWidget {
  const AdminUserDetailScreen({
    super.key,
    required this.user,
    required this.isDarkMode,
  });

  final AdminUserData user;
  final bool isDarkMode;

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _isActive = widget.user.isActive;
  }

  void _confirmToggleActive() {
    final isDark = widget.isDarkMode;
    final action = _isActive ? 'Deactivate' : 'Activate';
    showDialog<void>(
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
          _isActive
              ? '${widget.user.fullName} will lose access to the app.'
              : '${widget.user.fullName} will regain access to the app.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF6B7280))),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _isActive = !_isActive);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: _isActive
                  ? const Color(0xFFF43F5E)
                  : const Color(0xFF10B981),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final user = widget.user;
    final bg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF141414) : Colors.white;
    final textPrimary =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final textSub =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: bg,
        body: Column(
          children: [
            // ── Gradient header (compact) ────────────────────────────
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
                    // Back + Edit row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 2, 8, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                size: 18, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AdminUserFormScreen(
                                    isDarkMode: isDark, user: user),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.edit_rounded,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Avatar + info row
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
                            child: AdminAvatarCircle(
                                name: user.fullName, size: 54, fontSize: 19),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.fullName,
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
                                    _GradientStatusBadge(isActive: _isActive),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Stats column
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _CompactStat(
                                  icon: Icons.menu_book_rounded,
                                  value: '${user.recipeCount}',
                                  label: 'recipes'),
                              const SizedBox(height: 6),
                              _CompactStat(
                                  icon: Icons.favorite_rounded,
                                  value: '${user.savedCount}',
                                  label: 'saved'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // TabBar
                    TabBar(
                      labelColor: Colors.white,
                      unselectedLabelColor:
                          Colors.white.withValues(alpha: 0.5),
                      indicatorColor: Colors.white,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                      unselectedLabelStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
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
                              _TabCountBadge(count: user.savedCount),
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
                              _TabCountBadge(count: user.recipeCount),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Tab content (Expanded gives exact viewport) ───────────
            Expanded(
              child: TabBarView(
                children: [
                  _ProfileTab(
                    user: user,
                    isDark: isDark,
                    cardBg: cardBg,
                    textPrimary: textPrimary,
                    textSub: textSub,
                    isActive: _isActive,
                    onToggleActive: _confirmToggleActive,
                  ),
                  _RecipeListTab(
                    recipes: _kSavedRecipes[user.id] ?? [],
                    isDark: isDark,
                    cardBg: cardBg,
                    textPrimary: textPrimary,
                    textSub: textSub,
                    emptyMessage: 'No saved recipes yet',
                    emptyIcon: Icons.favorite_border_rounded,
                  ),
                  _RecipeListTab(
                    recipes: _kPersonalRecipes[user.id] ?? [],
                    isDark: isDark,
                    cardBg: cardBg,
                    textPrimary: textPrimary,
                    textSub: textSub,
                    emptyMessage: 'No recipes created yet',
                    emptyIcon: Icons.menu_book_outlined,
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

// ── Header helpers ────────────────────────────────────────────────────────────

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
    required this.onToggleActive,
  });

  final AdminUserData user;
  final bool isDark;
  final Color cardBg;
  final Color textPrimary;
  final Color textSub;
  final bool isActive;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(14),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Account
              _InfoCard(
                title: 'Account',
                icon: Icons.badge_rounded,
                isDark: isDark,
                cardBg: cardBg,
                textPrimary: textPrimary,
                textSub: textSub,
                rows: [
                  _InfoRow(icon: Icons.tag_rounded, label: 'User ID', value: '#${user.id}'),
                  _InfoRow(icon: Icons.alternate_email_rounded, label: 'Username', value: user.username),
                  _InfoRow(icon: Icons.mail_outline_rounded, label: 'Email', value: user.email),
                  _InfoRow(icon: Icons.person_outline_rounded, label: 'Full Name', value: user.fullName),
                  _InfoRow(icon: Icons.calendar_today_rounded, label: 'Joined', value: user.createdAt),
                ],
              ),
              const SizedBox(height: 12),
              // Nutrition Goals
              _InfoCard(
                title: 'Nutrition Goals',
                icon: Icons.local_fire_department_rounded,
                isDark: isDark,
                cardBg: cardBg,
                textPrimary: textPrimary,
                textSub: textSub,
                rows: [
                  _InfoRow(icon: Icons.cake_outlined, label: 'Age', value: user.age != null ? '${user.age} years' : '—'),
                  _InfoRow(icon: Icons.monitor_weight_outlined, label: 'Weight', value: user.weight != null ? '${user.weight} kg' : '—'),
                  _InfoRow(icon: Icons.local_fire_department_outlined, label: 'Calorie Target', value: user.calorieTarget != null ? '${user.calorieTarget} kcal/day' : '—'),
                  _InfoRow(icon: Icons.egg_outlined, label: 'Protein Target', value: user.proteinTarget != null ? '${user.proteinTarget} g/day' : '—'),
                  _InfoRow(icon: Icons.flag_outlined, label: 'Primary Goal', value: user.primaryGoal ?? '—'),
                ],
              ),
              const SizedBox(height: 12),
              // Dietary Restrictions
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
                        child: Text('None specified', style: TextStyle(fontSize: 13, color: textSub)),
                      )
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: user.dietaryRestrictions.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: kAdminAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(tag, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: kAdminAccent)),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 20),
              // Deactivate / Activate button
              OutlinedButton.icon(
                onPressed: onToggleActive,
                icon: Icon(isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded, size: 16),
                label: Text(isActive ? 'Deactivate Account' : 'Activate Account'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isActive ? const Color(0xFFF43F5E) : const Color(0xFF10B981),
                  side: BorderSide(color: isActive ? const Color(0xFFF43F5E) : const Color(0xFF10B981)),
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

// ── Tab: Recipe list ──────────────────────────────────────────────────────────

class _RecipeListTab extends StatelessWidget {
  const _RecipeListTab({
    required this.recipes,
    required this.isDark,
    required this.cardBg,
    required this.textPrimary,
    required this.textSub,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  final List<_MiniRecipe> recipes;
  final bool isDark;
  final Color cardBg;
  final Color textPrimary;
  final Color textSub;
  final String emptyMessage;
  final IconData emptyIcon;

  Widget _buildCard(_MiniRecipe r) {
    return Container(
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
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  r.color.withValues(alpha: 0.22),
                  r.color.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(Icons.restaurant_rounded, size: 18, color: r.color),
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
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.favorite_rounded,
                        size: 11,
                        color: const Color(0xFFF43F5E).withValues(alpha: 0.75)),
                    const SizedBox(width: 3),
                    Text('${r.favorites}',
                        style: TextStyle(fontSize: 11, color: textSub)),
                    const SizedBox(width: 10),
                    Icon(Icons.calendar_today_rounded, size: 11, color: textSub),
                    const SizedBox(width: 3),
                    Text(r.date,
                        style: TextStyle(fontSize: 11, color: textSub)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: r.color.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        if (recipes.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(emptyIcon,
                      size: 42, color: textSub.withValues(alpha: 0.35)),
                  const SizedBox(height: 10),
                  Text(emptyMessage,
                      style: TextStyle(fontSize: 13, color: textSub)),
                ],
              ),
            ),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.all(14),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final itemIndex = i ~/ 2;
                  if (i.isOdd) return const SizedBox(height: 8);
                  return _buildCard(recipes[itemIndex]);
                },
                childCount: recipes.length * 2 - 1,
              ),
            ),
          ),
          const SliverFillRemaining(hasScrollBody: false, child: SizedBox()),
        ],
      ],
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
            color:
                Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: isDark ? 10 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card title row
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
                          Icon(row.icon,
                              size: 14,
                              color: kAdminAccent.withValues(alpha: 0.7)),
                          const SizedBox(width: 9),
                          Text(
                            row.label,
                            style:
                                TextStyle(fontSize: 12.5, color: textSub),
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

// ── Dummy data ────────────────────────────────────────────────────────────────

class _MiniRecipe {
  const _MiniRecipe({
    required this.title,
    required this.favorites,
    required this.date,
    required this.color,
  });

  final String title;
  final int favorites;
  final String date;
  final Color color;
}

const _kSavedRecipes = <int, List<_MiniRecipe>>{
  1: [
    _MiniRecipe(title: 'Green Smoothie Bowl', favorites: 201, date: 'Mar 1, 2024', color: Color(0xFF10B981)),
    _MiniRecipe(title: 'Bánh Mì Sandwich', favorites: 176, date: 'Apr 18, 2024', color: Color(0xFFF59E0B)),
    _MiniRecipe(title: 'Avocado Toast', favorites: 133, date: 'May 2, 2024', color: Color(0xFF22C55E)),
  ],
  2: [
    _MiniRecipe(title: 'Phở Bò Hà Nội', favorites: 142, date: 'Feb 1, 2024', color: Color(0xFFF97316)),
    _MiniRecipe(title: 'Keto Egg Salad', favorites: 64, date: 'Apr 5, 2024', color: Color(0xFF8B5CF6)),
  ],
  3: [
    _MiniRecipe(title: 'Grilled Salmon', favorites: 87, date: 'Mar 20, 2024', color: Color(0xFF06B6D4)),
    _MiniRecipe(title: 'Chicken Stir Fry', favorites: 89, date: 'May 15, 2024', color: Color(0xFF3B82F6)),
    _MiniRecipe(title: 'Bún Bò Huế', favorites: 98, date: 'Feb 15, 2024', color: Color(0xFFF43F5E)),
  ],
  5: [
    _MiniRecipe(title: 'Phở Bò Hà Nội', favorites: 142, date: 'Feb 1, 2024', color: Color(0xFFF97316)),
    _MiniRecipe(title: 'Bánh Mì Sandwich', favorites: 176, date: 'Apr 18, 2024', color: Color(0xFFF59E0B)),
  ],
  8: [
    _MiniRecipe(title: 'Green Smoothie Bowl', favorites: 201, date: 'Mar 1, 2024', color: Color(0xFF10B981)),
  ],
};

const _kPersonalRecipes = <int, List<_MiniRecipe>>{
  1: [
    _MiniRecipe(title: 'Phở Bò Hà Nội', favorites: 142, date: 'Feb 1, 2024', color: Color(0xFFF97316)),
    _MiniRecipe(title: 'Chicken Stir Fry', favorites: 89, date: 'May 15, 2024', color: Color(0xFF3B82F6)),
  ],
  2: [
    _MiniRecipe(title: 'Grilled Salmon', favorites: 87, date: 'Mar 20, 2024', color: Color(0xFF06B6D4)),
  ],
  3: [
    _MiniRecipe(title: 'Bún Bò Huế', favorites: 98, date: 'Feb 15, 2024', color: Color(0xFFF43F5E)),
    _MiniRecipe(title: 'Vietnamese Spring Rolls', favorites: 54, date: 'Jun 1, 2024', color: Color(0xFF10B981)),
  ],
  5: [
    _MiniRecipe(title: 'Green Smoothie Bowl', favorites: 201, date: 'Mar 1, 2024', color: Color(0xFF10B981)),
    _MiniRecipe(title: 'Avocado Toast', favorites: 133, date: 'May 2, 2024', color: Color(0xFF22C55E)),
    _MiniRecipe(title: 'Vegan Buddha Bowl', favorites: 77, date: 'Jun 10, 2024', color: Color(0xFF8B5CF6)),
  ],
  8: [
    _MiniRecipe(title: 'Bánh Mì Sandwich', favorites: 176, date: 'Apr 18, 2024', color: Color(0xFFF59E0B)),
    _MiniRecipe(title: 'Lemongrass Chicken', favorites: 61, date: 'Jul 3, 2024', color: Color(0xFFF97316)),
  ],
};
