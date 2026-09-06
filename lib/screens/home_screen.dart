import 'dart:async';

import 'package:flutter/material.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';
import 'package:foodhub_mobile/models/favorite.dart';
import 'package:foodhub_mobile/models/meal.dart';
import 'package:foodhub_mobile/models/recipe.dart';
import 'package:foodhub_mobile/screens/meal_plan_screen.dart';
import 'package:foodhub_mobile/services/api_exception.dart';
import 'package:foodhub_mobile/services/favorite_service.dart';
import 'package:foodhub_mobile/services/meal_service.dart';
import 'package:foodhub_mobile/services/recipe_service.dart';
import 'package:foodhub_mobile/widgets/favorite_toast.dart';
import 'package:foodhub_mobile/widgets/meal_slot_picker.dart';
import 'package:foodhub_mobile/widgets/recipe_detail_view.dart';
import 'package:foodhub_mobile/widgets/recipe_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onDetailModeChanged});

  final ValueChanged<bool>? onDetailModeChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _recipeService = RecipeService();
  final _favoriteService = FavoriteService();
  final _mealService = MealService();
  List<TopFavoriteModel> _topFavorites = [];
  bool _isTopLoading = true;

  RecipeModel? _selectedTopRecipe;

  final Map<int, int> _recipeToFavoriteId = {};
  bool _favoritesLoaded = false;

  MealSuggestionModel? _suggestions;
  bool _isSuggestionsLoading = true;
  String? _suggestionsError;
  MealPlanModel? _mealPlan;

  @override
  void initState() {
    super.initState();
    _loadTopFavorites();
    _loadSuggestions();
    _loadMealPlan();
    LangScope.current.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    LangScope.current.removeListener(_onLanguageChanged);
    super.dispose();
  }

  // Recipe content is localized server-side by the `lang` query param —
  // refetch so it's not left showing the previous language after a switch.
  void _onLanguageChanged() {
    if (!mounted) return;
    _loadTopFavorites();
    _loadSuggestions();
  }

  Future<void> _loadTopFavorites() async {
    setState(() => _isTopLoading = true);
    try {
      final tops = await _favoriteService.getTopFavorites();
      if (!mounted) return;
      setState(() {
        _topFavorites = tops;
        _isTopLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isTopLoading = false);
    }
  }

  Future<void> _loadMealPlan() async {
    try {
      final plan = await _mealService.getPlan();
      if (!mounted) return;
      setState(() => _mealPlan = plan);
    } catch (_) {}
  }

  Future<void> _loadSuggestions({bool refresh = false}) async {
    setState(() {
      _isSuggestionsLoading = true;
      _suggestionsError = null;
    });
    try {
      final data = refresh
          ? await _mealService.refreshTodaySuggestions()
          : await _mealService.getTodaySuggestions();
      if (!mounted) return;
      setState(() {
        _suggestions = data;
        _isSuggestionsLoading = false;
        _suggestionsError = data.isFailed
            ? (data.errorMessage ?? S.of(context).suggestionsFailed)
            : null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSuggestionsLoading = false;
        _suggestionsError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSuggestionsLoading = false;
        _suggestionsError = S.of(context).suggestionsFailed;
      });
    }
  }

  Future<void> _openMealPlan() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MealPlanScreen(),
      ),
    );
    if (mounted) _loadMealPlan();
  }

  Future<void> _addRecipeToPlan(RecipeModel recipe) async {
    final s = S.of(context);
    final slotKey = await showMealSlotPicker(context, recipeName: recipe.title);
    if (slotKey == null || !mounted) return;
    try {
      final plan = await _mealService.addRecipeToSlot(
        slotKey: slotKey,
        recipeId: recipe.id,
      );
      if (!mounted) return;
      setState(() => _mealPlan = plan);
      showSuccessToast(context, s.addedToPlan);
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorToast(context, e.message);
    }
  }

  Widget _suggestionSection({
    required String title,
    required List<RecipeModel> recipes,
    required bool isDarkMode,
    required Color panelColor,
  }) {
    final s = S.of(context);
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title),
        if (_isSuggestionsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF059669)),
            ),
          )
        else if (_suggestionsError != null || _suggestions?.isFailed == true)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(child: Text(_suggestionsError ?? s.suggestionsFailed)),
                TextButton(onPressed: () => _loadSuggestions(refresh: true), child: Text(s.retry)),
              ],
            ),
          )
        else if (recipes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              _suggestions?.isPending == true
                  ? s.suggestionsPending
                  : s.noRecipesYet,
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
            ),
          )
        else
          _HorizontalScrollRow(
            height: 190,
            isDarkMode: isDarkMode,
            builder: (ctrl) => ListView.separated(
              controller: ctrl,
              scrollDirection: Axis.horizontal,
              itemCount: recipes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return _PersonalRecipeCard(
                  recipe: recipe,
                  isDarkMode: isDarkMode,
                  panelColor: panelColor,
                  onTap: () {
                    widget.onDetailModeChanged?.call(true);
                    setState(() => _selectedTopRecipe = recipe);
                    unawaited(_loadFavorites());
                  },
                  onAdd: () => _addRecipeToPlan(recipe),
                );
              },
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  Future<void> _loadFavorites() async {
    if (_favoritesLoaded) return;
    try {
      final favs = await _favoriteService.listFavorites();
      if (!mounted) return;
      setState(() {
        _favoritesLoaded = true;
        _recipeToFavoriteId.clear();
        for (final f in favs) {
          _recipeToFavoriteId[f.recipeId] = f.id;
        }
      });
    } catch (_) {}
  }

  Future<void> _toggleSaveRecipe(int recipeId) async {
    try {
      if (_recipeToFavoriteId.containsKey(recipeId)) {
        await _favoriteService.deleteFavorite(_recipeToFavoriteId[recipeId]!);
        if (!mounted) return;
        setState(() => _recipeToFavoriteId.remove(recipeId));
      } else {
        final fav = await _favoriteService.addFavorite(recipeId: recipeId);
        if (!mounted) return;
        setState(() => _recipeToFavoriteId[recipeId] = fav.id);
      }
    } catch (_) {}
  }

  String _greeting(BuildContext context) {
    final s = S.of(context);
    final h = DateTime.now().hour;
    if (h < 12) return s.goodMorning;
    if (h < 17) return s.goodAfternoon;
    return s.goodEvening;
  }

  Future<bool> _saveAsPersonalRecipe(RecipeDetailData data) async {
    final s = S.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: CircularProgressIndicator(color: Color(0xFF059669)),
          ),
        ),
      ),
    );
    try {
      var updated = await _recipeService.updateRecipe(
        data.id,
        title: data.name,
        ingredients: data.ingredientItems,
        directions: RecipeModel.splitLines(data.steps),
        dietaryRestrictions: data.labels,
        estimatedServings: data.estimatedServings,
      );
      if (data.pendingImageBytes != null && data.pendingImageBytes!.isNotEmpty) {
        try {
          final imageUrl = await _recipeService.uploadRecipeImage(
            updated.id,
            data.pendingImageBytes!,
            data.pendingImageFilename,
          );
          if (imageUrl != null && imageUrl.isNotEmpty) {
            updated = updated.copyWith(imageUrl: imageUrl);
          }
        } on ApiException catch (e) {
          if (mounted) showErrorToast(context, e.message);
        }
      }
      if (!mounted) return false;
      Navigator.of(context).pop();
      showSuccessToast(context, s.savedAsPersonalRecipe);
      return true;
    } on ApiException catch (e) {
      if (!mounted) return false;
      Navigator.of(context).pop();
      showErrorToast(context, e.message);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedTopRecipe != null) {
      final topRecipe = _selectedTopRecipe!;
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            widget.onDetailModeChanged?.call(false);
            setState(() => _selectedTopRecipe = null);
          }
        },
        child: RecipeDetailView(
          recipe: topRecipe.toDetailData(),
          cardColor: recipeCardTheme(topRecipe.id, topRecipe.labels).start,
          onBack: () {
            widget.onDetailModeChanged?.call(false);
            setState(() => _selectedTopRecipe = null);
          },
          isSaved: _favoritesLoaded
              ? _recipeToFavoriteId.containsKey(topRecipe.id)
              : null,
          onToggleSave: _favoritesLoaded
              ? () => unawaited(_toggleSaveRecipe(topRecipe.id))
              : null,
          onAddToPlan: () => _addRecipeToPlan(topRecipe),
          onSaveEdited: _saveAsPersonalRecipe,
        ),
      );
    }

    final colors = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);
    final panelColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return RefreshIndicator(
      color: const Color(0xFF059669),
      onRefresh: () async {
        await Future.wait([
          _loadTopFavorites(),
          _loadSuggestions(),
          _loadMealPlan(),
        ]);
      },
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            // ── Greeting hero ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withValues(alpha: 0.3),
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
                          _greeting(context),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.homeGreetingTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Section: Today's meal plan ────────────────────────────────
            _SectionHeader(title: s.todaysMealPlan),
            InkWell(
              onTap: _openMealPlan,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: panelColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: Color(0xFF059669)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s.mealPlanPreview(_mealPlan?.dishCount ?? 0),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      s.openMealPlan,
                      style: const TextStyle(
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            _SectionHeader(
              title: s.recommendedRecipes,
              trailing: IconButton(
                tooltip: s.refreshSuggestions,
                onPressed: () => _loadSuggestions(refresh: true),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
            _suggestionSection(
              title: s.breakfast,
              recipes: _suggestions?.breakfast ?? const [],
              isDarkMode: isDarkMode,
              panelColor: panelColor,
            ),
            _suggestionSection(
              title: s.lunch,
              recipes: _suggestions?.lunch ?? const [],
              isDarkMode: isDarkMode,
              panelColor: panelColor,
            ),
            _suggestionSection(
              title: s.dinner,
              recipes: _suggestions?.dinner ?? const [],
              isDarkMode: isDarkMode,
              panelColor: panelColor,
            ),

            const SizedBox(height: 8),

            // ── Section: Top Recipes ───────────────────────────────────────
            _SectionHeader(title: s.topRecipes),
            if (_isTopLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF059669)),
                ),
              )
            else if (_topFavorites.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    s.noTopRecipesYet,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              _HorizontalScrollRow(
                height: 180,
                isDarkMode: isDarkMode,
                builder: (ctrl) => ListView.separated(
                  controller: ctrl,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: _topFavorites.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final top = _topFavorites[index];
                    return _TopRecipeCard(
                      rank: index + 1,
                      topFavorite: top,
                      isDarkMode: isDarkMode,
                      panelColor: panelColor,
                      onTap: () {
                        widget.onDetailModeChanged?.call(true);
                        setState(() => _selectedTopRecipe = top.recipe);
                        unawaited(_loadFavorites());
                      },
                      onAdd: () => _addRecipeToPlan(top.recipe),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Horizontal scroll row with fade + arrow hint ─────────────────────────────

class _HorizontalScrollRow extends StatefulWidget {
  const _HorizontalScrollRow({
    required this.height,
    required this.isDarkMode,
    required this.builder,
  });

  final double height;
  final bool isDarkMode;
  final Widget Function(ScrollController) builder;

  @override
  State<_HorizontalScrollRow> createState() => _HorizontalScrollRowState();
}

class _HorizontalScrollRowState extends State<_HorizontalScrollRow> {
  final _ctrl = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDarkMode
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFF3F4F6);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SizedBox(height: widget.height, child: widget.builder(_ctrl)),
      ),
    );
  }
}

// ── Reusable section header ──────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: colors.onSurface,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

// ── Personal recipe card (compact, horizontal scroll) ────────────────────────

class _PersonalRecipeCard extends StatelessWidget {
  const _PersonalRecipeCard({
    required this.recipe,
    required this.isDarkMode,
    required this.panelColor,
    required this.onTap,
    this.onAdd,
  });

  final RecipeModel recipe;
  final bool isDarkMode;
  final Color panelColor;
  final VoidCallback onTap;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                RecipeImageHeader(
                  imageUrl: recipe.imageUrl,
                  recipeId: recipe.id,
                  labels: recipe.labels,
                  height: 100,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                if (onAdd != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: const Color(0xFF059669),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onAdd,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.add, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _PersonalRecipeStats(recipe: recipe),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalRecipeStats extends StatelessWidget {
  const _PersonalRecipeStats({required this.recipe});

  final RecipeModel recipe;

  @override
  Widget build(BuildContext context) {
    final subColor = Theme.of(context).colorScheme.onSurfaceVariant;
    const ts = TextStyle(fontSize: 10, fontWeight: FontWeight.w500);

    final timeText = Text('${recipe.cookingMinutes} ${S.of(context).minSuffix}',
        style: ts.copyWith(color: subColor));

    Widget divider() => Container(
          width: 1, height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          color: subColor.withValues(alpha: 0.35),
        );

    if (recipe.calories != null && recipe.calories! > 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 10, color: subColor),
          const SizedBox(width: 2),
          Flexible(child: timeText),
          divider(),
          Icon(Icons.local_fire_department_outlined,
              size: 10, color: const Color(0xFFEF4444).withValues(alpha: 0.8)),
          const SizedBox(width: 2),
          Flexible(
            child: Text('${recipe.calories} cal',
                overflow: TextOverflow.ellipsis,
                style: ts.copyWith(color: subColor)),
          ),
        ],
      );
    }

    if (recipe.estimatedServings != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 10, color: subColor),
          const SizedBox(width: 2),
          Flexible(child: timeText),
          divider(),
          Icon(Icons.people_outline_rounded, size: 10, color: subColor),
          const SizedBox(width: 2),
          Flexible(
            child: Text('Serves ${recipe.estimatedServings}',
                overflow: TextOverflow.ellipsis,
                style: ts.copyWith(color: subColor)),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule_rounded, size: 10, color: subColor),
        const SizedBox(width: 2),
        Flexible(child: timeText),
      ],
    );
  }
}

// ── Top recipe card (ranked, horizontal scroll) ───────────────────────────────

class _TopRecipeCard extends StatelessWidget {
  const _TopRecipeCard({
    required this.rank,
    required this.topFavorite,
    required this.isDarkMode,
    required this.panelColor,
    required this.onTap,
    this.onAdd,
  });

  final int rank;
  final TopFavoriteModel topFavorite;
  final bool isDarkMode;
  final Color panelColor;
  final VoidCallback onTap;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final recipe = topFavorite.recipe;
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                RecipeImageHeader(
                  imageUrl: recipe.imageUrl,
                  recipeId: recipe.id,
                  labels: recipe.labels,
                  height: 90,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: rank == 1
                          ? const Color(0xFFF59E0B)
                          : rank == 2
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFFCD7F32),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#$rank',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (onAdd != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: const Color(0xFF059669),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onAdd,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.add, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        size: 11,
                        color: Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        S.of(context).favoriteCount(topFavorite.favoriteCount),
                        style: TextStyle(
                          fontSize: 10,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
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

