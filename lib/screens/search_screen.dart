import 'package:flutter/material.dart';
import 'package:foodhub_mobile/models/recipe.dart';
import 'package:foodhub_mobile/services/api_exception.dart';
import 'package:foodhub_mobile/services/favorite_service.dart';
import 'package:foodhub_mobile/services/recipe_service.dart';
import 'package:foodhub_mobile/widgets/recipe_card.dart';
import 'package:foodhub_mobile/widgets/recipe_detail_view.dart';


const _kSearchCategories = [
  ('🌅', 'Breakfast'),
  ('🥗', 'Lunch'),
  ('🍝', 'Dinner'),
  ('🌱', 'Vegan'),
  ('⚡', 'Quick Meals'),
  ('💪', 'High Protein'),
  ('🌾', 'Gluten Free'),
  ('🥑', 'Keto'),
];

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.onDetailModeChanged});

  final ValueChanged<bool>? onDetailModeChanged;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
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

  static const _dietaryCategories = {
    'Vegan',
    'Gluten Free',
    'High Protein',
    'Keto',
  };

  @override
  void initState() {
    super.initState();
    _loadRecipes();
    _loadFavoriteIds();
  }

  Future<void> _loadFavoriteIds() async {
    try {
      final favorites = await _favoriteService.listFavorites();
      if (!mounted) return;
      setState(() {
        _favoriteIdsByRecipeId = {
          for (final f in favorites) f.recipeId: f.id,
        };
      });
    } catch (_) {}
  }

  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final dietary = _selectedCategory != null &&
              _dietaryCategories.contains(_selectedCategory)
          ? _selectedCategory
          : null;
      final query = _query.isNotEmpty
          ? _query
          : (_selectedCategory != null && dietary == null
              ? _selectedCategory
              : null);

      final results = await _recipeService.searchRecipes(
        query: query,
        dietaryRestriction: dietary,
      );

      if (!mounted) return;
      setState(() {
        _recipes = results;
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
        _loadError = 'Unable to search recipes.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
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
    widget.onDetailModeChanged?.call(true);
    setState(() {
      _selectedRecipeIndex = index >= 0 ? index : 0;
      _savedCurrentRecipe = _favoriteIdsByRecipeId.containsKey(recipe.id);
    });
  }

  void _closeRecipeDetails() {
    widget.onDetailModeChanged?.call(false);
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
        }
      } else {
        final favorite = await _favoriteService.addFavorite(recipeId: recipe.id);
        setState(() {
          _favoriteIdsByRecipeId[recipe.id] = favorite.id;
          _savedCurrentRecipe = true;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  List<RecipeModel> get _filteredRecipes => _recipes;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final visibleRecipes = _filteredRecipes;

    if (_selectedRecipeIndex != null &&
        _selectedRecipeIndex! >= 0 &&
        _selectedRecipeIndex! < _recipes.length) {
      final recipe = _recipes[_selectedRecipeIndex!];
      return RecipeDetailView(
        recipe: recipe.toDetailData(),
        cardColor: recipeCardTheme(recipe.labels).start,
        onBack: _closeRecipeDetails,
        isSaved: _savedCurrentRecipe,
        onToggleSave: () => _toggleSave(),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          'Search Recipes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode
                ? const Color(0xFFE2E8F0)
                : const Color(0xFF111827),
          ),
          decoration: InputDecoration(
            hintText: 'Search recipes, ingredients...',
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
            fillColor: isDarkMode ? const Color(0xFF102647) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDarkMode
                    ? const Color(0xFF274A73)
                    : colors.outlineVariant,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDarkMode
                    ? const Color(0xFF274A73)
                    : colors.outlineVariant,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF059669)),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Popular categories',
          style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _kSearchCategories.map((entry) {
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
                      : (isDarkMode ? const Color(0xFF102647) : Colors.white),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF059669)
                        : (isDarkMode
                              ? const Color(0xFF274A73)
                              : colors.outlineVariant),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF059669).withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(
                      label,
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
              'Recent recipes',
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
            ),
            const Spacer(),
            if (_selectedCategory != null || _query.isNotEmpty)
              Text(
                '${visibleRecipes.length} result${visibleRecipes.length == 1 ? '' : 's'}',
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
                OutlinedButton(onPressed: _loadRecipes, child: const Text('Retry')),
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
