import 'package:flutter/material.dart';
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
  final List<_SearchRecipe> _recipes = const [
    _SearchRecipe(
      name: 'Quinoa Buddha Bowl',
      duration: 25,
      calories: 420,
      ingredients:
          '2 cups quinoa\n1 cup chickpeas\n1/2 avocado\nTahini dressing\nMixed greens',
      instructions:
          'Cook quinoa per package.\nRoast chickpeas at 200°C for 20 min.\nAssemble bowl with greens, quinoa, chickpeas.\nTop with avocado and tahini.',
      tags: ['Vegetarian', 'Healthy'],
      categories: ['Lunch', 'Vegan', 'Quick Meals'],
    ),
    _SearchRecipe(
      name: 'Classic Italian Pasta',
      duration: 30,
      calories: 580,
      ingredients: '200g pasta\nTomato sauce\nGarlic\nParmesan\nFresh basil',
      instructions:
          'Boil pasta until al dente.\nSimmer sauce with garlic.\nToss pasta with sauce.\nTop with parmesan and basil.',
      tags: ['Italian'],
      categories: ['Dinner'],
    ),
    _SearchRecipe(
      name: 'Grilled Chicken & Veggies',
      duration: 35,
      calories: 450,
      ingredients:
          '2 chicken breasts\nBell pepper\nZucchini\nOlive oil\nSalt and pepper',
      instructions:
          'Season the chicken.\nGrill chicken and vegetables.\nSlice chicken.\nServe warm with veggies.',
      tags: ['High Protein'],
      categories: ['Lunch', 'High Protein', 'Keto'],
    ),
    _SearchRecipe(
      name: 'Fresh Garden Salad',
      duration: 15,
      calories: 280,
      ingredients: 'Lettuce\nCucumber\nCherry tomatoes\nOlive oil\nLemon juice',
      instructions:
          'Wash vegetables.\nChop all ingredients.\nMix dressing.\nToss and serve.',
      tags: ['Vegan'],
      categories: ['Lunch', 'Quick Meals', 'Gluten Free'],
    ),
  ];

  String _query = '';
  String? _selectedCategory;
  int? _selectedRecipeIndex;
  bool _savedCurrentRecipe = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _query = value.trim().toLowerCase();
      _selectedRecipeIndex = null;
    });
  }

  void _toggleCategory(String category) {
    setState(() {
      _selectedCategory = _selectedCategory == category ? null : category;
      _selectedRecipeIndex = null;
    });
  }

  void _openRecipeDetails(_SearchRecipe recipe) {
    final index = _recipes.indexOf(recipe);
    widget.onDetailModeChanged?.call(true);
    setState(() {
      _selectedRecipeIndex = index;
      _savedCurrentRecipe = false;
    });
  }

  void _closeRecipeDetails() {
    widget.onDetailModeChanged?.call(false);
    setState(() {
      _selectedRecipeIndex = null;
    });
  }

  void _toggleSave() {
    setState(() {
      _savedCurrentRecipe = !_savedCurrentRecipe;
    });
  }

  List<_SearchRecipe> get _filteredRecipes {
    return _recipes.where((recipe) {
      final matchesQuery =
          _query.isEmpty ||
          recipe.name.toLowerCase().contains(_query) ||
          recipe.ingredients.toLowerCase().contains(_query);
      final matchesCategory =
          _selectedCategory == null ||
          recipe.categories.contains(_selectedCategory);
      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final visibleRecipes = _filteredRecipes;

    if (_selectedRecipeIndex != null) {
      final recipe = _recipes[_selectedRecipeIndex!];
      return RecipeDetailView(
        recipe: RecipeDetailData(
          name: recipe.name,
          cookingMinutes: recipe.duration,
          calories: recipe.calories,
          ingredients: recipe.ingredients,
          steps: recipe.instructions,
          labels: recipe.tags,
        ),
        cardColor: recipeCardTheme(recipe.tags).start,
        onBack: _closeRecipeDetails,
        isSaved: _savedCurrentRecipe,
        onToggleSave: _toggleSave,
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
        ...visibleRecipes.map((recipe) => _SearchRecipeCard(
          recipe: recipe,
          onPressed: () => _openRecipeDetails(recipe),
        )),
      ],
    );
  }
}

class _SearchRecipeCard extends StatelessWidget {
  const _SearchRecipeCard({
    required this.recipe,
    required this.onPressed,
  });

  final _SearchRecipe recipe;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final t = recipeCardTheme(recipe.tags);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF0B1B38) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isDarkMode ? Border.all(color: const Color(0xFF274A73)) : null,
          boxShadow: isDarkMode
              ? []
              : [
                  BoxShadow(
                    color: t.start.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [t.start.withValues(alpha: 0.28), t.end.withValues(alpha: 0.14)]
                      : [t.start, t.end],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.emoji, style: const TextStyle(fontSize: 30)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${recipe.duration}m',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.local_fire_department_outlined,
                              size: 11,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${recipe.calories}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    recipe.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: recipe.tags.isEmpty
                        ? const SizedBox.shrink()
                        : Wrap(
                            spacing: 5,
                            runSpacing: 5,
                            children: recipe.tags
                                .map(
                                  (tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? t.start.withValues(alpha: 0.15)
                                          : t.start.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: t.start.withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Text(
                                      tag,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                        color: isDarkMode
                                            ? t.start.withValues(alpha: 0.9)
                                            : t.end,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [t.start, t.end],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: t.start.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
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

class _SearchRecipe {
  const _SearchRecipe({
    required this.name,
    required this.duration,
    required this.calories,
    required this.ingredients,
    required this.instructions,
    required this.tags,
    required this.categories,
  });

  final String name;
  final int duration;
  final int calories;
  final String ingredients;
  final String instructions;
  final List<String> tags;
  final List<String> categories;

  List<String> get ingredientItems => ingredients
      .split('\n')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}
