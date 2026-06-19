import 'dart:math' as math;

import 'package:flutter/material.dart';

const _kSearchCardColors = [
  Color(0xFFFFF7ED),
  Color(0xFFEFF6FF),
  Color(0xFFF0FDF4),
  Color(0xFFFFF1F2),
];

const _kSearchCategories = [
  'Breakfast',
  'Lunch',
  'Dinner',
  'Vegan',
  'Quick Meals',
  'High Protein',
  'Gluten Free',
  'Keto',
];

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

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
  bool _isCookingMode = false;
  bool _isPreparingIngredients = true;
  int _currentStepIndex = 0;
  List<bool> _preparedIngredients = const [];

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
    setState(() {
      _selectedRecipeIndex = index;
      _savedCurrentRecipe = false;
      _isCookingMode = false;
      _isPreparingIngredients = true;
      _currentStepIndex = 0;
      _preparedIngredients = List<bool>.filled(
        recipe.ingredientItems.length,
        false,
      );
    });
  }

  void _closeRecipeDetails() {
    setState(() {
      _selectedRecipeIndex = null;
      _isCookingMode = false;
      _isPreparingIngredients = true;
      _currentStepIndex = 0;
      _preparedIngredients = const [];
    });
  }

  void _toggleSave() {
    setState(() {
      _savedCurrentRecipe = !_savedCurrentRecipe;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _savedCurrentRecipe ? 'Recipe saved.' : 'Recipe removed from saved.',
        ),
      ),
    );
  }

  void _startCooking(_SearchRecipe recipe) {
    setState(() {
      _isCookingMode = true;
      _isPreparingIngredients = true;
      _currentStepIndex = 0;
      _preparedIngredients = List<bool>.filled(
        recipe.ingredientItems.length,
        false,
      );
    });
  }

  void _previousCookingStep() {
    if (_isPreparingIngredients) {
      return;
    }

    setState(() {
      if (_currentStepIndex == 0) {
        _isPreparingIngredients = true;
      } else {
        _currentStepIndex -= 1;
      }
    });
  }

  void _nextCookingStep(_SearchRecipe recipe) {
    if (_isPreparingIngredients) {
      setState(() {
        _isPreparingIngredients = false;
        _currentStepIndex = 0;
      });
      return;
    }

    if (_currentStepIndex >= recipe.stepItems.length - 1) {
      return;
    }

    setState(() {
      _currentStepIndex += 1;
    });
  }

  void _finishCooking() {
    setState(() {
      _isCookingMode = false;
    });

    _showCompletionFireworks();
  }

  void _showCompletionFireworks() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'completion-fireworks',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      pageBuilder: (_, _, _) => const _SearchFireworksCelebration(),
    );
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
      final cardColor =
          _kSearchCardColors[_selectedRecipeIndex! % _kSearchCardColors.length];
      return _SearchRecipeDetailView(
        recipe: recipe,
        cardColor: cardColor,
        isSaved: _savedCurrentRecipe,
        isCookingMode: _isCookingMode,
        isPreparingIngredients: _isPreparingIngredients,
        currentStepIndex: _currentStepIndex,
        preparedIngredients: _preparedIngredients,
        onBack: _closeRecipeDetails,
        onSave: _toggleSave,
        onStartCooking: () => _startCooking(recipe),
        onPrevious: _previousCookingStep,
        onNext: () => _nextCookingStep(recipe),
        onFinish: _finishCooking,
        onPreparedIngredientChanged: (index, value) {
          setState(() {
            _preparedIngredients[index] = value ?? false;
          });
        },
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
          children: _kSearchCategories.map((category) {
            final isSelected = _selectedCategory == category;
            return InkWell(
              onTap: () => _toggleCategory(category),
              borderRadius: BorderRadius.circular(999),
              child: Container(
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
                  ),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected
                        ? Colors.white
                        : (isDarkMode
                              ? const Color(0xFFCBD5E1)
                              : colors.onSurfaceVariant),
                  ),
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
        ...visibleRecipes.asMap().entries.map((entry) {
          final cardIndex = entry.key;
          final recipe = entry.value;
          return _SearchRecipeCard(
            recipe: recipe,
            cardColor: isDarkMode
                ? const Color(0xFF0B1B38)
                : _kSearchCardColors[cardIndex % _kSearchCardColors.length],
            onPressed: () => _openRecipeDetails(recipe),
          );
        }),
      ],
    );
  }
}

class _SearchRecipeDetailView extends StatelessWidget {
  const _SearchRecipeDetailView({
    required this.recipe,
    required this.cardColor,
    required this.isSaved,
    required this.isCookingMode,
    required this.isPreparingIngredients,
    required this.currentStepIndex,
    required this.preparedIngredients,
    required this.onBack,
    required this.onSave,
    required this.onStartCooking,
    required this.onPrevious,
    required this.onNext,
    required this.onFinish,
    required this.onPreparedIngredientChanged,
  });

  final _SearchRecipe recipe;
  final Color cardColor;
  final bool isSaved;
  final bool isCookingMode;
  final bool isPreparingIngredients;
  final int currentStepIndex;
  final List<bool> preparedIngredients;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onStartCooking;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onFinish;
  final void Function(int index, bool? value) onPreparedIngredientChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDarkMode ? const Color(0xFF0B1B38) : Colors.white;
    final panelColor = isDarkMode
        ? const Color(0xFF102647)
        : const Color(0xFFF8FAFC);
    final borderColor = isDarkMode
        ? const Color(0xFF274A73)
        : colors.outlineVariant;
    final accentColor = HSLColor.fromColor(cardColor)
        .withLightness(
          (HSLColor.fromColor(cardColor).lightness - 0.35).clamp(0.0, 1.0),
        )
        .withSaturation(0.7)
        .toColor();
    final saveColor = isSaved
        ? const Color(0xFFDC2626)
        : colors.onSurfaceVariant;

    final totalCookingStages = recipe.stepItems.length + 1;
    final currentStage = isPreparingIngredients ? 1 : currentStepIndex + 2;
    final progress = currentStage / totalCookingStages;
    final progressLabel = '${(progress * 100).round()}%';

    return Container(
      color: isDarkMode ? const Color(0xFF07152D) : cardColor,
      child: Column(
        children: [
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: onBack,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.arrow_back, size: 16),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    recipe.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isCookingMode
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isPreparingIngredients
                                      ? Icons.shopping_basket_outlined
                                      : Icons.restaurant_menu,
                                  color: accentColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isPreparingIngredients
                                          ? 'Prepare ingredients'
                                          : 'Cooking step',
                                      style: TextStyle(
                                        color: colors.onSurface,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      recipe.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: colors.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Text(
                                isPreparingIngredients
                                    ? 'Preparation'
                                    : 'Step ${currentStepIndex + 1} of ${recipe.stepItems.length}',
                                style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                progressLabel,
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: colors.surfaceContainerHighest,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF059669),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: panelColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: isPreparingIngredients
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ingredients',
                                        style: TextStyle(
                                          color: colors.onSurface,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      ...recipe.ingredientItems.map(
                                        (item) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.check_circle_outline,
                                                size: 16,
                                                color: accentColor,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  item,
                                                  style: TextStyle(
                                                    color:
                                                        colors.onSurfaceVariant,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        recipe.stepItems[currentStepIndex],
                                        style: TextStyle(
                                          color: colors.onSurface,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.schedule,
                                            size: 14,
                                            color: colors.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Estimated: ${recipe.estimatedMinutesForStep(currentStepIndex)} min',
                                            style: TextStyle(
                                              color: colors.onSurfaceVariant,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                          ),
                          const Spacer(),
                          Text(
                            isPreparingIngredients
                                ? 'Review your ingredients, then tap Next to start cooking.'
                                : 'Follow this step, then tap Next when you are ready.',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.name,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${recipe.duration} min',
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.local_fire_department_outlined,
                              size: 14,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${recipe.calories} cal',
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _SearchDetailSectionCard(
                          title: 'Ingredients',
                          icon: Icons.shopping_basket_outlined,
                          isDarkMode: isDarkMode,
                          iconColor: accentColor,
                          children: recipe.ingredientItems
                              .map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        size: 6,
                                        color: accentColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item,
                                          style: TextStyle(
                                            color: colors.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 10),
                        _SearchDetailSectionCard(
                          title: 'Instructions',
                          icon: Icons.format_list_numbered,
                          isDarkMode: isDarkMode,
                          iconColor: accentColor,
                          children: recipe.stepItems
                              .asMap()
                              .entries
                              .map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: isDarkMode
                                              ? const Color(0xFF274A73)
                                              : cardColor,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${entry.key + 1}',
                                          style: TextStyle(
                                            color: accentColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          entry.value,
                                          style: TextStyle(
                                            color: colors.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 10),
                        _SearchDetailSectionCard(
                          title: 'Labels',
                          icon: Icons.sell_outlined,
                          isDarkMode: isDarkMode,
                          iconColor: accentColor,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: recipe.tags
                                  .map(
                                    (tag) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: panelColor,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: Text(
                                        tag,
                                        style: TextStyle(
                                          color: colors.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: isCookingMode
                ? Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: (isPreparingIngredients)
                              ? null
                              : onPrevious,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                            foregroundColor: colors.onSurfaceVariant,
                            side: BorderSide(color: colors.outline),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: const Text('Previous'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: isPreparingIngredients
                              ? onNext
                              : (currentStepIndex < recipe.stepItems.length - 1
                                    ? onNext
                                    : null),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: const Text('Next'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed:
                              !isPreparingIngredients &&
                                  currentStepIndex ==
                                      recipe.stepItems.length - 1
                              ? onFinish
                              : null,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: const Text('Finish'),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onSave,
                          icon: Icon(
                            isSaved ? Icons.favorite : Icons.favorite_border,
                            size: 15,
                            color: isSaved
                                ? const Color(0xFFDC2626)
                                : saveColor,
                          ),
                          label: Text(isSaved ? 'Saved' : 'Save'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                            backgroundColor: panelColor,
                            foregroundColor: saveColor,
                            side: BorderSide(
                              color: isSaved
                                  ? const Color(0xFFFCA5A5)
                                  : borderColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: onStartCooking,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: const Text('Start Cooking'),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchDetailSectionCard extends StatelessWidget {
  const _SearchDetailSectionCard({
    required this.title,
    required this.icon,
    required this.children,
    required this.isDarkMode,
    this.iconColor = const Color(0xFF059669),
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Color iconColor;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF07152D) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _SearchRecipeCard extends StatelessWidget {
  const _SearchRecipeCard({
    required this.recipe,
    required this.cardColor,
    required this.onPressed,
  });

  final _SearchRecipe recipe;
  final Color cardColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF07152D) : cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF274A73) : colors.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 13,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.duration} min',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.local_fire_department_outlined,
                          size: 13,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.calories} cal',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: recipe.tags
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? const Color(0xFF102647)
                                    : const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: isDarkMode
                                      ? const Color(0xFF274A73)
                                      : colors.outlineVariant,
                                ),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: isDarkMode
                                      ? const Color(0xFFCBD5E1)
                                      : colors.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.outline),
            ],
          ),
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

  List<String> get stepItems => instructions
      .split('\n')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  int estimatedMinutesForStep(int stepIndex) {
    if (stepItems.isEmpty) {
      return 0;
    }
    final minutes = (duration / stepItems.length).round();
    return minutes < 1 ? 1 : minutes;
  }
}

class _SearchFireworksCelebration extends StatefulWidget {
  const _SearchFireworksCelebration();

  @override
  State<_SearchFireworksCelebration> createState() =>
      _SearchFireworksCelebrationState();
}

class _SearchFireworksCelebrationState
    extends State<_SearchFireworksCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    Future<void>.delayed(const Duration(milliseconds: 1900), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final particles = List<int>.generate(14, (index) => index);

    return SafeArea(
      child: Center(
        child: SizedBox(
          width: 260,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ...particles.map((index) {
                final angle = (index * 2 * math.pi) / particles.length;
                final distance = 78 + (index.isEven ? 18 : 0);

                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final t = _controller.value;
                    final dx = math.cos(angle) * distance * t;
                    final dy = math.sin(angle) * distance * t;

                    return Transform.translate(
                      offset: Offset(dx, dy),
                      child: Opacity(
                        opacity: (1 - t).clamp(0.0, 1.0),
                        child: Text(
                          index.isEven ? '🎆' : '✨',
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    );
                  },
                );
              }),
              Container(
                width: 190,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🎉', style: TextStyle(fontSize: 30)),
                    SizedBox(height: 6),
                    Text(
                      'Completed!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text('Great job chef', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
