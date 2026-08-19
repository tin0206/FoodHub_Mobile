import 'package:flutter/material.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';
import 'package:foodhub_mobile/models/recipe.dart';
import 'package:foodhub_mobile/services/api_exception.dart';
import 'package:foodhub_mobile/services/favorite_service.dart';
import 'package:foodhub_mobile/services/recipe_service.dart';
import 'package:foodhub_mobile/widgets/favorite_toast.dart';
import 'package:foodhub_mobile/widgets/recipe_card.dart';
import 'package:foodhub_mobile/widgets/recipe_detail_view.dart';

const _kMealTypeCategories = [
  ('🌅', 'Breakfast'),
  ('🥗', 'Lunch'),
  ('🍝', 'Dinner'),
  ('⚡', 'Quick Meals'),
];

const _kDietaryEmojiMap = {
  'Alcoholic': '🍸',
  'Beverage': '🥤',
  'Dairy Free': '🥛',
  'Gluten Free': '🌾',
  'Nut Free': '🥜',
  'Pescetarian': '🐟',
  'Vegan': '🌱',
  'Vegetarian': '🥦',
};

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.onDetailModeChanged});

  final ValueChanged<bool>? onDetailModeChanged;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  double _savedScrollOffset = 0;
  final _recipeService = RecipeService();
  final _favoriteService = FavoriteService();

  List<RecipeModel> _recipes = [];
  Map<int, int> _favoriteIdsByRecipeId = {};
  bool _isLoading = false;
  String? _loadError;

  String _query = '';
  String? _selectedCategory;
  int? _selectedRecipeIndex;
  bool _savedCurrentRecipe = false;

  List<String> _dietaryOptions = [];
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDietaryRestrictions();
    _loadRecipes();
    _loadFavoriteIds();
    FavoriteService.changes.addListener(_onFavoritesChanged);
  }

  Future<void> _loadDietaryRestrictions() async {
    try {
      final options = await _recipeService.getDietaryRestrictions();
      if (!mounted) return;
      setState(() => _dietaryOptions = options);
    } catch (_) {}
  }

  void _onFavoritesChanged() {
    if (mounted) _loadFavoriteIds();
  }

  Future<void> _loadFavoriteIds() async {
    try {
      final favorites = await _favoriteService.listFavorites();
      if (!mounted) return;
      setState(() {
        _favoriteIdsByRecipeId = {for (final f in favorites) f.recipeId: f.id};
      });
    } catch (_) {}
  }

  bool get _hasFilter => _query.isNotEmpty || _selectedCategory != null;

  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
      _recipes = [];
      _totalCount = 0;
    });

    try {
      final dietary =
          _selectedCategory != null &&
              _dietaryOptions.contains(_selectedCategory)
          ? _selectedCategory
          : null;
      final query = _query.isNotEmpty
          ? _query
          : (_selectedCategory != null && dietary == null
                ? _selectedCategory
                : null);

      final result = await _recipeService.searchRecipes(
        query: query,
        dietaryRestriction: dietary,
        limit: _hasFilter ? null : 50,
      );

      if (!mounted) return;
      setState(() {
        _recipes = result.recipes;
        _totalCount = result.totalCount;
        _isLoading = false;
        _selectedRecipeIndex = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = S.of(context).unableToSearch;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    FavoriteService.changes.removeListener(_onFavoritesChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value.trim().toLowerCase());
    _loadRecipes();
  }

  void _toggleCategory(String category) {
    setState(() {
      _selectedCategory = _selectedCategory == category ? null : category;
    });
    _loadRecipes();
  }

  void _openRecipeDetails(RecipeModel recipe) {
    final index = _recipes.indexWhere((r) => r.id == recipe.id);
    if (_scrollController.hasClients) {
      _savedScrollOffset = _scrollController.offset;
    }
    widget.onDetailModeChanged?.call(true);
    setState(() {
      _selectedRecipeIndex = index >= 0 ? index : 0;
      _savedCurrentRecipe = _favoriteIdsByRecipeId.containsKey(recipe.id);
    });
  }

  void _closeRecipeDetails() {
    widget.onDetailModeChanged?.call(false);
    _scrollController.dispose();
    _scrollController = ScrollController(initialScrollOffset: _savedScrollOffset);
    setState(() {
      _selectedRecipeIndex = null;
    });
  }

  Future<void> _toggleSave() async {
    final index = _selectedRecipeIndex;
    if (index == null || index < 0 || index >= _recipes.length) return;
    final recipe = _recipes[index];

    try {
      if (_savedCurrentRecipe) {
        final favoriteId = _favoriteIdsByRecipeId[recipe.id];
        if (favoriteId != null) {
          await _favoriteService.deleteFavorite(favoriteId);
          setState(() {
            _favoriteIdsByRecipeId.remove(recipe.id);
            _savedCurrentRecipe = false;
          });
          if (mounted)
            showFavoriteToast(context, recipeName: recipe.name, saved: false);
        }
      } else {
        final favorite = await _favoriteService.addFavorite(
          recipeId: recipe.id,
        );
        setState(() {
          _favoriteIdsByRecipeId[recipe.id] = favorite.id;
          _savedCurrentRecipe = true;
        });
        if (mounted)
          showFavoriteToast(context, recipeName: recipe.name, saved: true);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorToast(context, e.message);
    }
  }

  List<RecipeModel> get _filteredRecipes => _recipes;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);
    final visibleRecipes = _filteredRecipes;

    if (_selectedRecipeIndex != null &&
        _selectedRecipeIndex! >= 0 &&
        _selectedRecipeIndex! < _recipes.length) {
      final recipe = _recipes[_selectedRecipeIndex!];
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _closeRecipeDetails();
        },
        child: RecipeDetailView(
          recipe: recipe.toDetailData(),
          cardColor: recipeCardTheme(recipe.id, recipe.labels).start,
          onBack: _closeRecipeDetails,
          isSaved: _savedCurrentRecipe,
          onToggleSave: () => _toggleSave(),
        ),
      );
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          s.searchRecipesTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.35 : 0.07),
                blurRadius: isDarkMode ? 10 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFF111827),
            ),
            decoration: InputDecoration(
              hintText: s.searchHint,
              hintStyle: TextStyle(
                color: isDarkMode
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF6B7280),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: isDarkMode
                    ? const Color(0xFF94A3B8)
                    : colors.onSurfaceVariant,
              ),
              filled: true,
              fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
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
                borderSide: const BorderSide(color: Color(0xFF059669)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          s.popularCategories,
          style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              [
                ..._kMealTypeCategories,
                ..._dietaryOptions.map(
                  (d) => (_kDietaryEmojiMap[d] ?? '🍽️', d),
                ),
              ].map((entry) {
                final (emoji, label) = entry;
                final isSelected = _selectedCategory == label;
                return InkWell(
                  onTap: () => _toggleCategory(label),
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF059669)
                          : (isDarkMode
                                ? const Color(0xFF1E1E1E)
                                : Colors.white),
                      borderRadius: BorderRadius.circular(999),
                      border: isSelected
                          ? Border.all(
                              color: const Color(0xFF059669),
                              width: 1.5,
                            )
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(
                                  0xFF059669,
                                ).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDarkMode ? 0.3 : 0.06,
                                ),
                                blurRadius: isDarkMode ? 8 : 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 5),
                        Text(
                          s.categoryDisplay(label),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDarkMode
                                      ? const Color(0xFFCBD5E1)
                                      : colors.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Text(
              s.recentRecipes,
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
            ),
            const Spacer(),
            if (_hasFilter)
              Text(
                s.resultCount(_totalCount),
                style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF059669)),
            ),
          )
        else if (_loadError != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(_loadError!, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: _loadRecipes, child: Text(s.retry)),
              ],
            ),
          )
        else
          ...visibleRecipes.map(
            (recipe) => RecipeCard(
              recipe: recipe,
              onTap: () => _openRecipeDetails(recipe),
              onAction: () => _openRecipeDetails(recipe),
              margin: const EdgeInsets.only(bottom: 10),
            ),
          ),
      ],
    );
  }
}
