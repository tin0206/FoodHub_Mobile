import 'dart:async';

import 'package:flutter/material.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';
import 'package:foodhub_mobile/models/aisle_mapping.dart';
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
  String _query = '';
  String? _labelFilter;
  final _admin = AdminService();
  AisleMappingStatus? _aisles;
  String? _aisleError;
  bool _aisleLoading = true;
  bool _aisleStarting = false;
  bool _aisleStopping = false;
  Timer? _aislePoll;

  static const _allLabels = [
    'Vietnamese', 'Vegan', 'High Protein', 'Keto',
    'Breakfast', 'Quick Meal', 'Pescetarian', 'Healthy',
  ];

  @override
  void initState() {
    super.initState();
    _loadAisles();
  }

  @override
  void dispose() {
    _aislePoll?.cancel();
    super.dispose();
  }

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

  List<_RecipeData> get _filtered {
    var list = _kRecipes.toList();
    if (_labelFilter != null) {
      list = list.where((r) => r.labels.contains(_labelFilter)).toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((r) => r.title.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  void _confirmDelete(_RecipeData r) {
    final isDark = widget.isDarkMode;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Recipe?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
          ),
        ),
        content: Text(
          '"${r.title}" will be permanently removed.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final cardBg = isDark ? const Color(0xFF141414) : Colors.white;
    final list = _filtered;
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
                          '${_kRecipes.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: kAdminAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
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
                      onChanged: (v) => setState(() => _query = v.trim()),
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
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _labelFilter == null,
                          isDark: isDark,
                          onTap: () => setState(() => _labelFilter = null),
                        ),
                        ..._allLabels.map(
                          (l) => _FilterChip(
                            label: l,
                            selected: _labelFilter == l,
                            isDark: isDark,
                            onTap: () => setState(
                              () => _labelFilter = l == _labelFilter ? null : l,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text('No recipes found',
                          style: TextStyle(color: textSub)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 80),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final r = list[i];
                        return Container(
                          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: isDark ? 0.3 : 0.06),
                                blurRadius: isDark ? 10 : 8,
                                offset: const Offset(0, 3),
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
                                            color: const Color(0xFFF43F5E)
                                                .withValues(alpha: 0.7)),
                                        const SizedBox(width: 3),
                                        Text('${r.favorites}',
                                            style: TextStyle(
                                                fontSize: 11, color: textSub)),
                                        const SizedBox(width: 10),
                                        Icon(Icons.calendar_today_rounded,
                                            size: 11, color: textSub),
                                        const SizedBox(width: 3),
                                        Text(r.createdAt,
                                            style: TextStyle(
                                                fontSize: 11, color: textSub)),
                                      ],
                                    ),
                                    if (r.labels.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 5,
                                        children: r.labels.take(3).map((l) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: kAdminAccent
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              l,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: kAdminAccent,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _confirmDelete(r),
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 19,
                                  color: const Color(0xFFF43F5E)
                                      .withValues(alpha: 0.7),
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 36, minHeight: 36),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),

        // ── Add Recipe FAB ────────────────────────────────────────────
        Positioned(
          right: 16,
          bottom: 16,
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    AdminRecipeFormScreen(isDarkMode: widget.isDarkMode),
              ),
            ),
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
                child: const Icon(
                  Icons.storefront_rounded,
                  size: 17,
                  color: kAdminAccent,
                ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

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
                color:
                    Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected
                  ? Colors.white
                  : (isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF6B7280)),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _RecipeData {
  const _RecipeData({
    required this.id,
    required this.title,
    required this.labels,
    required this.favorites,
    required this.createdAt,
  });

  final int id;
  final String title;
  final List<String> labels;
  final int favorites;
  final String createdAt;
}

const _kRecipes = [
  _RecipeData(id: 1, title: 'Phở Bò Hà Nội', labels: ['Vietnamese', 'High Protein'], favorites: 142, createdAt: 'Feb 1, 2024'),
  _RecipeData(id: 2, title: 'Bún Bò Huế', labels: ['Vietnamese'], favorites: 98, createdAt: 'Feb 15, 2024'),
  _RecipeData(id: 3, title: 'Green Smoothie Bowl', labels: ['Vegan', 'Breakfast', 'Healthy'], favorites: 201, createdAt: 'Mar 1, 2024'),
  _RecipeData(id: 4, title: 'Grilled Salmon', labels: ['High Protein', 'Pescetarian'], favorites: 87, createdAt: 'Mar 20, 2024'),
  _RecipeData(id: 5, title: 'Keto Egg Salad', labels: ['Keto', 'Quick Meal'], favorites: 64, createdAt: 'Apr 5, 2024'),
  _RecipeData(id: 6, title: 'Bánh Mì Sandwich', labels: ['Vietnamese', 'Quick Meal'], favorites: 176, createdAt: 'Apr 18, 2024'),
  _RecipeData(id: 7, title: 'Avocado Toast', labels: ['Vegan', 'Breakfast'], favorites: 133, createdAt: 'May 2, 2024'),
  _RecipeData(id: 8, title: 'Chicken Stir Fry', labels: ['High Protein', 'Quick Meal'], favorites: 89, createdAt: 'May 15, 2024'),
];
