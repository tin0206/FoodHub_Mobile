import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:foodhub_mobile/config/api_config.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';
import 'package:foodhub_mobile/models/aisle_mapping.dart';
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

  // Aisle mapping state
  AisleMappingStatus? _aisles;
  String? _aisleError;
  bool _aisleLoading = true;
  bool _aisleStarting = false;
  bool _aisleStopping = false;
  Timer? _aislePoll;

  @override
  void initState() {
    super.initState();
    _loadAisles();
    _loadRecipes();
  }

  @override
  void dispose() {
    _aislePoll?.cancel();
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

  // ── Aisle mapping ─────────────────────────────────────────────────────────

  void _syncAislePoll(AisleMappingStatus status) {
    final running = status.isRunning;
    if (running && _aislePoll == null) {
      _aislePoll = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _loadAisles(quiet: true),
      );
    } else if (!running && _aislePoll != null) {
      _aislePoll?.cancel();
      _aislePoll = null;
    }
  }

  Future<void> _loadAisles({bool quiet = false}) async {
    if (!quiet) {
      setState(() {
        _aisleLoading = true;
        _aisleError = null;
      });
    }
    try {
      final status = await _admin.aisleStatus();
      if (!mounted) return;
      final wasRunning = _aisles?.isRunning ?? false;
      setState(() {
        _aisles = status;
        _aisleLoading = false;
        _aisleError = null;
      });
      _syncAislePoll(status);
      if (quiet && wasRunning && !status.isRunning && mounted) {
        final job = status.job;
        final cancelled = job?.status == 'cancelled';
        final failed = !cancelled &&
            (job?.status == 'failed' || (job?.errorMessage ?? '').isNotEmpty);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              cancelled
                  ? S.of(context).aislesStopped
                  : failed
                      ? (job?.errorMessage ?? S.of(context).unableToMapAisles)
                      : S.of(context).aislesMapped,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aisleLoading = false;
        _aisleError = e is ApiException ? e.message : '$e';
      });
    }
  }

  Future<void> _startMap({required bool force}) async {
    if (_aisleStarting || (_aisles?.isRunning ?? false)) return;
    setState(() => _aisleStarting = true);
    try {
      final status = await _admin.mapAisles(force: force);
      if (!mounted) return;
      setState(() {
        _aisles = status;
        _aisleStarting = false;
        _aisleError = null;
      });
      _syncAislePoll(status);
    } catch (e) {
      if (!mounted) return;
      setState(() => _aisleStarting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException ? e.message : S.of(context).unableToMapAisles,
          ),
        ),
      );
    }
  }

  Future<void> _stopMap() async {
    if (_aisleStopping) return;
    setState(() => _aisleStopping = true);
    try {
      final status = await _admin.stopMapAisles();
      if (!mounted) return;
      _aislePoll?.cancel();
      _aislePoll = null;
      setState(() {
        _aisles = status;
        _aisleStopping = false;
        _aisleStarting = false;
        _aisleLoading = false;
        _aisleError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).aislesStopped)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _aisleStopping = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException ? e.message : S.of(context).unableToMapAisles,
          ),
        ),
      );
    }
  }

  Future<void> _onMapPressed() async {
    final s = S.of(context);
    final status = _aisles;
    if (status == null || status.isRunning) return;
    if (status.missing > 0) {
      await _startMap(force: false);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = widget.isDarkMode;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            s.remappingAisles,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
            ),
          ),
          content: Text(
            s.remapAislesConfirm,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: kAdminAccent),
              child: Text(s.remappingAisles),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await _startMap(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final cardBg = isDark ? const Color(0xFF141414) : Colors.white;
    final s = S.of(context);

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

                  // ── Aisle map card ─────────────────────────────────────
                  _AisleMapCard(
                    isDark: isDark,
                    cardBg: cardBg,
                    textPrimary: textPrimary,
                    textSub: textSub,
                    strings: s,
                    status: _aisles,
                    error: _aisleError,
                    loading: _aisleLoading,
                    starting: _aisleStarting,
                    stopping: _aisleStopping,
                    onMap: _onMapPressed,
                    onStop: _stopMap,
                    onRetry: _loadAisles,
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

// ── Aisle map card ────────────────────────────────────────────────────────────

class _AisleMapCard extends StatelessWidget {
  const _AisleMapCard({
    required this.isDark,
    required this.cardBg,
    required this.textPrimary,
    required this.textSub,
    required this.strings,
    required this.status,
    required this.error,
    required this.loading,
    required this.starting,
    required this.stopping,
    required this.onMap,
    required this.onStop,
    required this.onRetry,
  });

  final bool isDark;
  final Color cardBg;
  final Color textPrimary;
  final Color textSub;
  final S strings;
  final AisleMappingStatus? status;
  final String? error;
  final bool loading;
  final bool starting;
  final bool stopping;
  final VoidCallback onMap;
  final VoidCallback onStop;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final running = starting || (status?.isRunning ?? false);
    final job = status?.job;
    final missing = status?.missing ?? 0;
    final mapped = status?.mapped ?? 0;
    final total = status?.total ?? 0;
    final progressTotal = (job != null && job.total > 0) ? job.total : total;
    final progressDone = running && job != null ? job.processed : mapped;
    final fraction = progressTotal <= 0
        ? 0.0
        : (progressDone / progressTotal).clamp(0.0, 1.0);
    final buttonLabel = running
        ? strings.mappingAisles
        : (missing > 0 ? strings.mapAisles : strings.remappingAisles);

    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: kAdminAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.storefront_rounded, size: 17, color: kAdminAccent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  strings.mapAisles,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (loading && status == null)
            Text(strings.loadingAisleStatus, style: TextStyle(fontSize: 12, color: textSub)),
          if (error != null && status == null) ...[
            Text(error!, style: const TextStyle(fontSize: 12, color: Color(0xFFF43F5E))),
            TextButton(onPressed: onRetry, child: Text(strings.retry)),
          ],
          if (status != null) ...[
            Text(
              strings.aisleMappedCount(mapped, total),
              style: TextStyle(fontSize: 12, color: textSub),
            ),
            if (job != null &&
                (job.status == 'failed' || job.status == 'cancelled') &&
                (job.errorMessage ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                job.errorMessage!,
                style: const TextStyle(fontSize: 12, color: Color(0xFFF43F5E)),
              ),
            ],
            if (missing > 0) ...[
              const SizedBox(height: 2),
              Text(
                strings.aisleMissingCount(missing),
                style: TextStyle(fontSize: 12, color: textSub),
              ),
            ],
            if (running) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: job != null && job.total > 0 ? fraction : null,
                  minHeight: 6,
                  color: kAdminAccent,
                  backgroundColor: kAdminAccent.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                strings.aisleJobProgress(progressDone, progressTotal),
                style: TextStyle(fontSize: 11, color: textSub),
              ),
            ],
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: running || stopping ? null : onMap,
                  style: FilledButton.styleFrom(
                    backgroundColor: kAdminAccent,
                    disabledBackgroundColor: kAdminAccent.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(buttonLabel),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: stopping ? null : onStop,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF43F5E),
                    side: const BorderSide(color: Color(0xFFF43F5E)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(strings.stopMappingAisles),
                ),
              ),
            ],
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
