import 'dart:math' as math;
import 'package:flutter/material.dart';

const _kRecipeCardColors = [
  Color(0xFFFFF7ED),
  Color(0xFFEFF6FF),
  Color(0xFFF0FDF4),
  Color(0xFFFDF4FF),
  Color(0xFFFFF1F2),
  Color(0xFFFEFCE8),
];

const _kAvailableLabels = [
  'Dairy Free',
  'Egg Free',
  'Gluten Free',
  'Nut Free',
  'Vegan',
  'Vegetarian',
  'Pescetarian',
  'Healthy',
  'Italian',
  'Comfort Food',
  'High Protein',
  'Keto',
  'Quick Meal',
  'Meal Prep',
  'Breakfast',
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<_Recipe> _recipes = [
    const _Recipe(
      name: 'Quinoa Buddha Bowl',
      ingredients: '1 cup quinoa\n1 avocado\n1 carrot\nSpinach\nTahini sauce',
      steps:
          'Cook quinoa.\nSlice vegetables.\nAssemble bowl and drizzle sauce.',
      labels: ['Vegetarian', 'Healthy'],
      cookingMinutes: 25,
      calories: 420,
    ),
    const _Recipe(
      name: 'Classic Italian Pasta',
      ingredients: '200g pasta\nTomato sauce\nGarlic\nParmesan\nBasil',
      steps:
          'Boil pasta.\nSimmer sauce with garlic.\nToss and top with parmesan.',
      labels: ['Italian', 'Comfort Food'],
      cookingMinutes: 30,
      calories: 550,
    ),
    const _Recipe(
      name: 'Grilled Chicken & Veggies',
      ingredients:
          '2 chicken breasts\nBell pepper\nZucchini\nOlive oil\nSalt & pepper',
      steps:
          'Season chicken.\nGrill chicken and veggies.\nSlice and serve warm.',
      labels: ['High Protein', 'Keto'],
      cookingMinutes: 35,
      calories: 600,
    ),
  ];

  bool _isAddingRecipe = false;
  _Recipe? _selectedRecipe;
  int? _selectedRecipeCardIndex;

  void _onAddRecipePressed() {
    setState(() {
      _isAddingRecipe = true;
      _selectedRecipe = null;
      _selectedRecipeCardIndex = null;
    });
  }

  void _onCancelAddRecipe() {
    setState(() => _isAddingRecipe = false);
  }

  void _onSaveRecipe(_Recipe recipe) {
    setState(() {
      _recipes.add(recipe);
      _isAddingRecipe = false;
    });
  }

  void _openRecipeDetails(_Recipe recipe, int cardIndex) {
    setState(() {
      _isAddingRecipe = false;
      _selectedRecipe = recipe;
      _selectedRecipeCardIndex = cardIndex;
    });
  }

  void _closeRecipeDetails() {
    setState(() {
      _selectedRecipe = null;
      _selectedRecipeCardIndex = null;
    });
  }

  void _onSaveEditedRecipe(_Recipe updatedRecipe) {
    final index = _selectedRecipeCardIndex;
    if (index == null || index < 0 || index >= _recipes.length) return;

    setState(() {
      _recipes[index] = updatedRecipe;
      _selectedRecipe = updatedRecipe;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (_selectedRecipe != null && _selectedRecipeCardIndex != null) {
      return _RecipeDetailView(
        recipe: _selectedRecipe!,
        cardColor:
            _kRecipeCardColors[_selectedRecipeCardIndex! %
                _kRecipeCardColors.length],
        onBack: _closeRecipeDetails,
        onSaveEditedRecipe: _onSaveEditedRecipe,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _isAddingRecipe
            ? [
                Expanded(
                  child: _AddRecipePanel(
                    onCancel: _onCancelAddRecipe,
                    onSave: _onSaveRecipe,
                  ),
                ),
              ]
            : [
                Row(
                  children: [
                    const Icon(
                      Icons.menu_book_outlined,
                      color: Color(0xFF059669),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'My Recipes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _onAddRecipePressed,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Your personal recipe collection',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: _recipes.isEmpty
                      ? _EmptyRecipesView(onAddFirstRecipe: _onAddRecipePressed)
                      : ListView.separated(
                          padding: const EdgeInsets.only(top: 15),
                          itemCount: _recipes.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final recipe = _recipes[index];
                            return _RecipeCard(
                              recipe: recipe,
                              cardIndex: index,
                              onView: () => _openRecipeDetails(recipe, index),
                            );
                          },
                        ),
                ),
              ],
      ),
    );
  }
}

class _RecipeDetailView extends StatefulWidget {
  const _RecipeDetailView({
    required this.recipe,
    required this.cardColor,
    required this.onBack,
    required this.onSaveEditedRecipe,
  });

  final _Recipe recipe;
  final Color cardColor;
  final VoidCallback onBack;
  final ValueChanged<_Recipe> onSaveEditedRecipe;

  @override
  State<_RecipeDetailView> createState() => _RecipeDetailViewState();
}

class _RecipeDetailViewState extends State<_RecipeDetailView> {
  bool _isEditMode = false;
  bool _isCookingMode = false;
  bool _isPreparingIngredients = true;
  int _currentStepIndex = 0;

  late TextEditingController _ingredientsController;
  late TextEditingController _stepsController;
  late TextEditingController _cookingMinutesController;
  late TextEditingController _caloriesController;
  late Set<String> _selectedEditLabels;

  @override
  void initState() {
    super.initState();
    _ingredientsController = TextEditingController(
      text: widget.recipe.ingredients,
    );
    _stepsController = TextEditingController(text: widget.recipe.steps);
    _cookingMinutesController = TextEditingController(
      text: widget.recipe.cookingMinutes.toString(),
    );
    _caloriesController = TextEditingController(
      text: widget.recipe.calories.toString(),
    );
    _selectedEditLabels = widget.recipe.labels.toSet();
  }

  @override
  void didUpdateWidget(covariant _RecipeDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.recipe != widget.recipe) {
      _ingredientsController.text = widget.recipe.ingredients;
      _stepsController.text = widget.recipe.steps;
      _cookingMinutesController.text = widget.recipe.cookingMinutes.toString();
      _caloriesController.text = widget.recipe.calories.toString();
      _selectedEditLabels = widget.recipe.labels.toSet();

      _isEditMode = false;
      _isCookingMode = false;
      _isPreparingIngredients = true;
      _currentStepIndex = 0;
    }
  }

  @override
  void dispose() {
    _ingredientsController.dispose();
    _stepsController.dispose();
    _cookingMinutesController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _openCookingMode() {
    if (widget.recipe.stepItems.isEmpty) return;

    setState(() {
      _isCookingMode = true;
      _isPreparingIngredients = true;
      _currentStepIndex = 0;
    });
  }

  void _previousStep() {
    if (_isPreparingIngredients) return;

    setState(() {
      if (_currentStepIndex == 0) {
        _isPreparingIngredients = true;
      } else {
        _currentStepIndex--;
      }
    });
  }

  void _nextStep() {
    if (_isPreparingIngredients) {
      setState(() {
        _isPreparingIngredients = false;
        _currentStepIndex = 0;
      });
      return;
    }

    if (_currentStepIndex >= widget.recipe.stepItems.length - 1) return;

    setState(() {
      _currentStepIndex++;
    });
  }

  void _finishCooking() {
    if (_isPreparingIngredients) return;

    setState(() {
      _isCookingMode = false;
    });

    _showCompletionFireworks();
  }

  void _saveEditedRecipe() {
    final ingredients = _ingredientsController.text.trim();
    final steps = _stepsController.text.trim();
    final cookingMinutes = int.tryParse(_cookingMinutesController.text.trim());
    final calories = int.tryParse(_caloriesController.text.trim());

    if (ingredients.isEmpty ||
        steps.isEmpty ||
        cookingMinutes == null ||
        calories == null ||
        cookingMinutes <= 0 ||
        calories <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ingredients, instructions, cooking time and calories are required.',
          ),
        ),
      );
      return;
    }

    final updatedRecipe = _Recipe(
      name: widget.recipe.name,
      ingredients: ingredients,
      steps: steps,
      labels: _selectedEditLabels.toList(),
      cookingMinutes: cookingMinutes,
      calories: calories,
    );

    widget.onSaveEditedRecipe(updatedRecipe);

    setState(() {
      _isEditMode = false;
    });

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Recipe updated'),
        content: const Text('Your changes have been saved successfully.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCompletionFireworks() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'completion-fireworks',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      pageBuilder: (_, _, _) => const _FireworksCelebration(),
    );
  }

  int _estimatedMinutesForCurrentStep() {
    final totalSteps = widget.recipe.stepItems.length;
    if (totalSteps == 0) return 0;

    final minutes = (widget.recipe.cookingMinutes / totalSteps).round();
    return minutes < 1 ? 1 : minutes;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final stepItems = widget.recipe.stepItems;
    final ingredientItems = widget.recipe.ingredientItems;
    final totalSteps = stepItems.length;

    final totalCookingStages = totalSteps + 1;
    final currentCookingStage = _isPreparingIngredients
        ? 1
        : (_currentStepIndex + 2);
    final progress = currentCookingStage / totalCookingStages;
    final progressLabel = '${(progress * 100).round()}%';

    final accentColor = HSLColor.fromColor(widget.cardColor)
        .withLightness(
          (HSLColor.fromColor(widget.cardColor).lightness - 0.35).clamp(
            0.0,
            1.0,
          ),
        )
        .withSaturation(0.7)
        .toColor();

    final canFinish =
        !_isPreparingIngredients && _currentStepIndex == totalSteps - 1;

    return Container(
      color: widget.cardColor,
      child: Column(
        children: [
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: colors.outlineVariant)),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: widget.onBack,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.arrow_back, size: 16),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.recipe.name,
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
            child: _isCookingMode
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.outlineVariant),
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
                                  _isPreparingIngredients
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
                                      _isPreparingIngredients
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
                                      widget.recipe.name,
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
                                _isPreparingIngredients
                                    ? 'Preparation'
                                    : 'Step ${_currentStepIndex + 1} of $totalSteps',
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
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.outlineVariant),
                            ),
                            child: _isPreparingIngredients
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
                                      ...ingredientItems.map(
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
                                        stepItems[_currentStepIndex],
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
                                            'Estimated: ${_estimatedMinutesForCurrentStep()} min',
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
                            _isPreparingIngredients
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
                          widget.recipe.name,
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

                            Center(
                              child: _isEditMode
                                  ? SizedBox(
                                      width: 65,
                                      height: 34,
                                      child: TextField(
                                        controller: _cookingMinutesController,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          suffixText: 'min',
                                        ),
                                      ),
                                    )
                                  : Text(
                                      '${widget.recipe.cookingMinutes} min',
                                      style: TextStyle(
                                        color: colors.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                            ),

                            const SizedBox(width: 16),

                            Icon(
                              Icons.local_fire_department_outlined,
                              size: 14,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),

                            Center(
                              child: _isEditMode
                                  ? SizedBox(
                                      width: 65,
                                      height: 34,
                                      child: TextField(
                                        controller: _caloriesController,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          suffixText: 'cal',
                                        ),
                                      ),
                                    )
                                  : Text(
                                      '${widget.recipe.calories} cal',
                                      style: TextStyle(
                                        color: colors.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _DetailSectionCard(
                          title: 'Ingredients',
                          icon: Icons.shopping_basket_outlined,
                          backgroundColor: Colors.white,
                          iconColor: accentColor,
                          children: _isEditMode
                              ? [
                                  TextField(
                                    controller: _ingredientsController,
                                    maxLines: 6,
                                    decoration: const InputDecoration(
                                      hintText: 'One ingredient per line',
                                    ),
                                  ),
                                ]
                              : widget.recipe.ingredientItems
                                    .map(
                                      (item) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
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
                                                  color:
                                                      colors.onSurfaceVariant,
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
                        _DetailSectionCard(
                          title: 'Instructions',
                          icon: Icons.format_list_numbered,
                          backgroundColor: Colors.white,
                          iconColor: accentColor,
                          children: _isEditMode
                              ? [
                                  TextField(
                                    controller: _stepsController,
                                    maxLines: 7,
                                    decoration: const InputDecoration(
                                      hintText: 'One instruction per line',
                                    ),
                                  ),
                                ]
                              : widget.recipe.stepItems
                                    .asMap()
                                    .entries
                                    .map(
                                      (entry) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 22,
                                              height: 22,
                                              decoration: BoxDecoration(
                                                color: widget.cardColor,
                                                borderRadius:
                                                    BorderRadius.circular(999),
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
                                                  color:
                                                      colors.onSurfaceVariant,
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
                        _DetailSectionCard(
                          title: 'Labels',
                          icon: Icons.sell_outlined,
                          backgroundColor: Colors.white,
                          iconColor: accentColor,
                          children: _isEditMode
                              ? [
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: _kAvailableLabels.map((label) {
                                      final isSelected = _selectedEditLabels
                                          .contains(label);

                                      return FilterChip(
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        backgroundColor: Colors.white,
                                        selectedColor: const Color(0xFF059669),
                                        checkmarkColor: Colors.white,
                                        selected: isSelected,
                                        label: Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isSelected
                                                ? Colors.white
                                                : colors.onSurfaceVariant,
                                          ),
                                        ),
                                        onSelected: (selected) {
                                          setState(() {
                                            if (selected) {
                                              _selectedEditLabels.add(label);
                                            } else {
                                              _selectedEditLabels.remove(label);
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ]
                              : [
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: widget.recipe.labels
                                        .map(
                                          (tag) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                color: colors.outlineVariant,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
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
            child: _isCookingMode
                ? Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: (_isPreparingIngredients)
                              ? null
                              : _previousStep,
                          child: const Text(
                            'Previous',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          onPressed: _isPreparingIngredients
                              ? _nextStep
                              : (_currentStepIndex < totalSteps - 1
                                    ? _nextStep
                                    : null),
                          child: const Text('Next'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          onPressed: canFinish ? _finishCooking : null,
                          child: const Text('Finish'),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _isEditMode = !_isEditMode;
                              _selectedEditLabels = widget.recipe.labels
                                  .toSet();
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: colors.onSurface,
                            side: BorderSide(color: colors.outline),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(_isEditMode ? 'Cancel' : 'Edit'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isEditMode
                              ? _saveEditedRecipe
                              : _openCookingMode,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            _isEditMode ? 'Save Changes' : 'Start Cooking',
                          ),
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

class _FireworksCelebration extends StatefulWidget {
  const _FireworksCelebration();

  @override
  State<_FireworksCelebration> createState() => _FireworksCelebrationState();
}

class _FireworksCelebrationState extends State<_FireworksCelebration>
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

class _DetailSectionCard extends StatelessWidget {
  const _DetailSectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.backgroundColor = const Color(0xFFFAFAFA),
    this.iconColor = const Color(0xFF059669),
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
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

class _EmptyRecipesView extends StatelessWidget {
  const _EmptyRecipesView({required this.onAddFirstRecipe});

  final VoidCallback onAddFirstRecipe;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Text('No recipes yet', style: TextStyle(color: colors.onSurface)),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.recipe,
    required this.cardIndex,
    required this.onView,
  });

  final _Recipe recipe;
  final int cardIndex;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kRecipeCardColors[cardIndex % _kRecipeCardColors.length],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  recipe.name,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onView,
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('View'),
              ),
            ],
          ),
          Text(
            recipe.ingredientsSummary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: recipe.labels
                .map(
                  (tag) => Chip(
                    backgroundColor: Colors.white,
                    label: Text(tag, style: const TextStyle(fontSize: 11)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _AddRecipePanel extends StatefulWidget {
  const _AddRecipePanel({required this.onCancel, required this.onSave});

  final VoidCallback onCancel;
  final ValueChanged<_Recipe> onSave;

  @override
  State<_AddRecipePanel> createState() => _AddRecipePanelState();
}

class _AddRecipePanelState extends State<_AddRecipePanel> {
  final _nameController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _stepsController = TextEditingController();
  final _cookingMinutesController = TextEditingController();
  final _caloriesController = TextEditingController();
  final Set<String> _selectedLabels = {};

  @override
  void dispose() {
    _nameController.dispose();
    _ingredientsController.dispose();
    _stepsController.dispose();
    _cookingMinutesController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final ingredients = _ingredientsController.text.trim();
    final steps = _stepsController.text.trim();
    final cookingMinutes = int.tryParse(_cookingMinutesController.text.trim());
    final calories = int.tryParse(_caloriesController.text.trim());

    if (name.isEmpty ||
        ingredients.isEmpty ||
        steps.isEmpty ||
        cookingMinutes == null ||
        calories == null ||
        cookingMinutes <= 0 ||
        calories <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    widget.onSave(
      _Recipe(
        name: name,
        ingredients: ingredients,
        steps: steps,
        labels: _selectedLabels.toList(),
        cookingMinutes: cookingMinutes,
        calories: calories,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
            child: Row(
              children: [
                Text(
                  'Add Recipe',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close, size: 16),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Recipe Name *'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cookingMinutesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cooking time *',
                          suffixText: 'min',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _caloriesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Calories *',
                          suffixText: 'cal',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _ingredientsController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Ingredients *',
                    hintText: 'One ingredient per line',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _stepsController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Steps *',
                    hintText: 'One instruction per line',
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _kAvailableLabels.map((label) {
                    final isSelected = _selectedLabels.contains(label);

                    return FilterChip(
                      selected: isSelected,
                      selectedColor: const Color(0xFF059669),
                      checkmarkColor: Colors.white,
                      label: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? Colors.white
                              : colors.onSurfaceVariant,
                        ),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          selected
                              ? _selectedLabels.add(label)
                              : _selectedLabels.remove(label);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Save'),
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

class _Recipe {
  const _Recipe({
    required this.name,
    required this.ingredients,
    required this.steps,
    required this.labels,
    required this.cookingMinutes,
    required this.calories,
  });

  final String name;
  final String ingredients;
  final String steps;
  final List<String> labels;
  final int cookingMinutes;
  final int calories;

  List<String> get ingredientItems => ingredients
      .split('\n')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  List<String> get stepItems => steps
      .split('\n')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  String get ingredientsSummary {
    if (ingredientItems.isEmpty) return '';
    if (ingredientItems.length <= 3) return ingredientItems.join(', ');
    return '${ingredientItems.take(3).join(', ')}, ...';
  }
}
