import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:foodhub_mobile/config/api_config.dart';
import 'package:foodhub_mobile/models/recipe.dart';
import 'package:foodhub_mobile/screens/admin/admin_recipe_detail_screen.dart';
import 'package:foodhub_mobile/screens/admin/admin_recipe_form_screen.dart';
import 'package:foodhub_mobile/screens/admin/admin_shell_screen.dart';
import 'package:foodhub_mobile/services/admin_service.dart';
import 'package:foodhub_mobile/services/api_exception.dart';

class AdminRecipesScreen extends StatefulWidget {
  const AdminRecipesScreen({super.key, required this.isDarkMode});

  final bool isDarkMode;

  @override
  State<AdminRecipesScreen> createState() => _AdminRecipesScreenState();
}

class _AdminRecipesScreenState extends State<AdminRecipesScreen> {
  static const _kPageSize = 20;

  final _admin = AdminService();
  final _searchCtrl = TextEditingController();

  // Recipe list state
  List<RecipeModel> _recipes = [];
  bool _loadingRecipes = false;
  bool _hasNext = false;
  int _page = 0;
  String _query = '';
  String? _visibilityFilter; // null = all, 'public', 'private'
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Recipes API ───────────────────────────────────────────────────────────

  Future<void> _loadRecipes({bool replace = true}) async {
    if (_loadingRecipes) return;
    setState(() => _loadingRecipes = true);
    final page = replace ? 0 : _page;
    try {
      final results = await _admin.listRecipes(
        skip: page * _kPageSize,
        limit: _kPageSize + 1,
        visibility: _visibilityFilter,
        q: _query.isNotEmpty ? _query : null,
      );
      if (!mounted) return;
      final hasNext = results.length > _kPageSize;
      final items = hasNext ? results.sublist(0, _kPageSize) : results;
      setState(() {
        _loadingRecipes = false;
        _page = page;
        _hasNext = hasNext;
        _recipes = replace ? items : [..._recipes, ...items];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingRecipes = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : '$e')),
      );
    }
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      if (_query == v.trim()) return;
      setState(() => _query = v.trim());
      _loadRecipes();
    });
  }

  void _setVisibility(String? v) {
    if (_visibilityFilter == v) return;
    setState(() => _visibilityFilter = v);
    _loadRecipes();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final cardBg = isDark ? const Color(0xFF141414) : Colors.white;

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────────────
                  Row(
                    children: [
                      Text(
                        'Recipes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: kAdminAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${_recipes.length}${_hasNext ? '+' : ''}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: kAdminAccent,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (_loadingRecipes)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: kAdminAccent),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── Search ─────────────────────────────────────────────
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      style: TextStyle(fontSize: 14, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search recipes…',
                        hintStyle: TextStyle(color: textSub, fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: textSub, size: 20),
                        filled: true,
                        fillColor: cardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: kAdminAccent),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Visibility filter ──────────────────────────────────
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _visibilityFilter == null,
                          isDark: isDark,
                          onTap: () => _setVisibility(null),
                        ),
                        _FilterChip(
                          label: 'Public',
                          selected: _visibilityFilter == 'public',
                          isDark: isDark,
                          onTap: () => _setVisibility('public'),
                          icon: Icons.visibility_rounded,
                        ),
                        _FilterChip(
                          label: 'Private',
                          selected: _visibilityFilter == 'private',
                          isDark: isDark,
                          onTap: () => _setVisibility('private'),
                          icon: Icons.visibility_off_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            // ── Recipe list ────────────────────────────────────────────
            Expanded(
              child: _loadingRecipes && _recipes.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: kAdminAccent),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadRecipes(),
                      color: kAdminAccent,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 80),
                        children: [
                          if (_recipes.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                                    blurRadius: isDark ? 10 : 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.menu_book_outlined, size: 32, color: textSub.withValues(alpha: 0.4)),
                                  const SizedBox(height: 10),
                                  Text('No recipes found',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _query.isNotEmpty ? 'Try a different search' : 'Try a different visibility filter',
                                    style: TextStyle(fontSize: 12, color: textSub),
                                  ),
                                ],
                              ),
                            )
                          else
                            Opacity(
                              opacity: _loadingRecipes ? 0.6 : 1.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                                      blurRadius: isDark ? 10 : 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: _recipes.asMap().entries.map((e) {
                                    final i = e.key;
                                    final r = e.value;
                                    final isLast = i == _recipes.length - 1;
                                    return _RecipeRow(
                                      recipe: r,
                                      isDark: isDark,
                                      textPrimary: textPrimary,
                                      textSub: textSub,
                                      showTopDivider: i > 0,
                                      isLast: isLast,
                                      onTap: () async {
                                        await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => AdminRecipeDetailScreen(
                                              recipeId: r.id,
                                              isDarkMode: isDark,
                                            ),
                                          ),
                                        );
                                        _loadRecipes();
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          if (_recipes.isNotEmpty)
                            _PaginationRow(
                              isDark: isDark,
                              loading: _loadingRecipes,
                              hasNext: _hasNext,
                              page: _page,
                              onPrev: _page > 0
                                  ? () {
                                      setState(() => _page--);
                                      _loadRecipes(replace: true);
                                    }
                                  : null,
                              onNext: () {
                                setState(() => _page++);
                                _loadRecipes(replace: true);
                              },
                            ),
                        ],
                      ),
                    ), // RefreshIndicator
            ),
          ],
        ),

        // ── Add Recipe FAB ────────────────────────────────────────────────
        Positioned(
          right: 16,
          bottom: 16,
          child: GestureDetector(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AdminRecipeFormScreen(isDarkMode: widget.isDarkMode),
                ),
              );
              _loadRecipes();
            },
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: kAdminAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kAdminAccent.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Recipe row (inside grouped card) ─────────────────────────────────────────

class _RecipeRow extends StatelessWidget {
  const _RecipeRow({
    required this.recipe,
    required this.isDark,
    required this.textPrimary,
    required this.textSub,
    required this.showTopDivider,
    required this.isLast,
    required this.onTap,
  });

  final RecipeModel recipe;
  final bool isDark;
  final Color textPrimary;
  final Color textSub;
  final bool showTopDivider;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = recipe;
    final isPublic = !r.isPrivate;
    final visColor = isPublic ? const Color(0xFF10B981) : textSub;
    final visIcon = isPublic ? Icons.visibility_rounded : Icons.visibility_off_rounded;
    final locale = r.locale;

    return Column(
      children: [
        if (showTopDivider)
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
          ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.vertical(
            top: showTopDivider ? Radius.zero : const Radius.circular(16),
            bottom: isLast ? const Radius.circular(16) : Radius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                // Image or placeholder
                (() {
                  final resolved = ApiConfig.resolveImageUrl(r.imageUrl);
                  if (resolved.isEmpty) return _bookPlaceholder(isDark);
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: resolved,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => _bookPlaceholder(isDark),
                      errorWidget: (ctx, url, err) => _bookPlaceholder(isDark),
                    ),
                  );
                })(),
                const SizedBox(width: 12),
                // Title + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Visibility pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: visColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(visIcon, size: 9, color: visColor),
                                const SizedBox(width: 3),
                                Text(
                                  isPublic ? 'Public' : 'Private',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: visColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '#${r.id} · $locale',
                            style: TextStyle(fontSize: 11, color: textSub),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 18, color: textSub),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bookPlaceholder(bool isDark) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: kAdminAccent.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.menu_book_rounded, size: 22, color: kAdminAccent),
    );
  }
}

// ── Pagination row ────────────────────────────────────────────────────────────

class _PaginationRow extends StatelessWidget {
  const _PaginationRow({
    required this.isDark,
    required this.loading,
    required this.hasNext,
    required this.page,
    required this.onPrev,
    required this.onNext,
  });

  final bool isDark;
  final bool loading;
  final bool hasNext;
  final int page;
  final VoidCallback? onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (page > 0)
            OutlinedButton.icon(
              onPressed: loading ? null : onPrev,
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 13),
              label: const Text('Prev'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kAdminAccent,
                side: BorderSide(color: kAdminAccent.withValues(alpha: 0.4)),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          if (page > 0) const SizedBox(width: 8),
          Text('Page ${page + 1}', style: TextStyle(fontSize: 12, color: textSub)),
          if (hasNext) const SizedBox(width: 8),
          if (hasNext)
            OutlinedButton.icon(
              onPressed: loading ? null : onNext,
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 13),
              label: const Text('Next'),
              iconAlignment: IconAlignment.end,
              style: OutlinedButton.styleFrom(
                foregroundColor: kAdminAccent,
                side: BorderSide(color: kAdminAccent.withValues(alpha: 0.4)),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? kAdminAccent
                : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 12,
                  color: selected
                      ? Colors.white
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
