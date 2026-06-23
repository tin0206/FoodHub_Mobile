import 'package:flutter/material.dart';
import 'package:foodhub_mobile/widgets/recipe_detail_view.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onDetailModeChanged});

  final ValueChanged<bool>? onDetailModeChanged;

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

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning 🌅';
    if (h < 17) return 'Good afternoon ☀️';
    return 'Good evening 🌙';
  }

  void _openRecipeDetails(_Recipe recipe, int cardIndex) {
    widget.onDetailModeChanged?.call(true);
    setState(() {
      _isAddingRecipe = false;
      _selectedRecipe = recipe;
      _selectedRecipeCardIndex = cardIndex;
    });
  }

  void _closeRecipeDetails() {
    widget.onDetailModeChanged?.call(false);
    setState(() {
      _selectedRecipe = null;
      _selectedRecipeCardIndex = null;
    });
  }

  void _onSaveEditedRecipe(RecipeDetailData data) {
    final index = _selectedRecipeCardIndex;
    if (index == null || index < 0 || index >= _recipes.length) return;

    final updated = _Recipe(
      name: data.name,
      ingredients: data.ingredients,
      steps: data.steps,
      labels: data.labels,
      cookingMinutes: data.cookingMinutes,
      calories: data.calories,
    );

    setState(() {
      _recipes[index] = updated;
      _selectedRecipe = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedRecipe != null && _selectedRecipeCardIndex != null) {
      return RecipeDetailView(
        recipe: RecipeDetailData(
          name: _selectedRecipe!.name,
          cookingMinutes: _selectedRecipe!.cookingMinutes,
          calories: _selectedRecipe!.calories,
          ingredients: _selectedRecipe!.ingredients,
          steps: _selectedRecipe!.steps,
          labels: _selectedRecipe!.labels,
        ),
        cardColor: recipeCardTheme(_selectedRecipe!.labels).start,
        onBack: _closeRecipeDetails,
        enableEdit: true,
        onSaveEdited: _onSaveEditedRecipe,
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
                // ── Greeting hero ─────────────────────────────────────
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
                              _greeting,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'My Recipes',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${_recipes.length} recipe${_recipes.length == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: _onAddRecipePressed,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _recipes.isEmpty
                      ? _EmptyRecipesView(onAddFirstRecipe: _onAddRecipePressed)
                      : ListView.separated(
                          padding: EdgeInsets.zero,
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

class _EmptyRecipesView extends StatelessWidget {
  const _EmptyRecipesView({required this.onAddFirstRecipe});

  final VoidCallback onAddFirstRecipe;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.menu_book_outlined,
              color: isDarkMode
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF6B7280),
              size: 34,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No recipes yet',
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add your own recipes and share your culinary creations',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDarkMode
                  ? const Color(0xFF94A3B8)
                  : colors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onAddFirstRecipe,
            icon: const Icon(Icons.add),
            label: const Text('Add your first recipe'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Maps recipe labels to a visual theme (emoji + gradient colors)
({String emoji, Color start, Color end}) _recipeTheme(List<String> labels) {
  for (final l in labels) {
    if (l == 'Vegan' || l == 'Vegetarian') {
      return (emoji: '🥗', start: const Color(0xFF10B981), end: const Color(0xFF059669));
    }
    if (l == 'Italian' || l == 'Comfort Food') {
      return (emoji: '🍝', start: const Color(0xFFF59E0B), end: const Color(0xFFD97706));
    }
    if (l == 'High Protein' || l == 'Keto') {
      return (emoji: '💪', start: const Color(0xFF3B82F6), end: const Color(0xFF1D4ED8));
    }
    if (l == 'Breakfast') {
      return (emoji: '🌅', start: const Color(0xFFF97316), end: const Color(0xFFEA580C));
    }
    if (l == 'Quick Meal') {
      return (emoji: '⚡', start: const Color(0xFF8B5CF6), end: const Color(0xFF7C3AED));
    }
    if (l == 'Healthy') {
      return (emoji: '🌿', start: const Color(0xFF22C55E), end: const Color(0xFF16A34A));
    }
    if (l == 'Pescetarian') {
      return (emoji: '🐟', start: const Color(0xFF06B6D4), end: const Color(0xFF0891B2));
    }
    if (l == 'Meal Prep') {
      return (emoji: '📦', start: const Color(0xFFF43F5E), end: const Color(0xFFE11D48));
    }
  }
  return (emoji: '🍽️', start: const Color(0xFF10B981), end: const Color(0xFF059669));
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final t = _recipeTheme(recipe.labels);

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Gradient header ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                        t.start.withValues(alpha: 0.28),
                        t.end.withValues(alpha: 0.14),
                      ]
                    : [t.start, t.end],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
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
                            '${recipe.cookingMinutes}m',
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

          // ── Tags + action ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: recipe.labels.isEmpty
                      ? const SizedBox.shrink()
                      : Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: recipe.labels
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
                GestureDetector(
                  onTap: onView,
                  child: Container(
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
                ),
              ],
            ),
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
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ingredientsController.dispose();
    _stepsController.dispose();
    _cookingMinutesController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;

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

    setState(() => _isSaving = true);

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

    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    Navigator.of(context).pop();

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

  Widget _darkField({
    required TextEditingController controller,
    required String label,
    required Color fillColor,
    required Color textColor,
    required Color labelColor,
    required Color borderColor,
    String? hint,
    String? suffix,
    int? maxLines,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines ?? 1,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 13, color: textColor),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        filled: true,
        fillColor: fillColor,
        labelStyle: TextStyle(color: labelColor),
        hintStyle: TextStyle(color: labelColor, fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF059669)),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? const Color(0xFF0B1B38) : Colors.white;
    final borderColor =
        isDarkMode ? const Color(0xFF274A73) : colors.outlineVariant;
    final fieldFill =
        isDarkMode ? const Color(0xFF102647) : const Color(0xFFF9FAFB);
    final textColor =
        isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF111827);
    final labelColor =
        isDarkMode ? const Color(0xFF94A3B8) : colors.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
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
                  icon: Icon(Icons.close, size: 16, color: colors.onSurface),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              children: [
                _darkField(
                  controller: _nameController,
                  label: 'Recipe Name *',
                  fillColor: fieldFill,
                  textColor: textColor,
                  labelColor: labelColor,
                  borderColor: borderColor,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _darkField(
                        controller: _cookingMinutesController,
                        label: 'Cooking time *',
                        suffix: 'min',
                        keyboardType: TextInputType.number,
                        fillColor: fieldFill,
                        textColor: textColor,
                        labelColor: labelColor,
                        borderColor: borderColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _darkField(
                        controller: _caloriesController,
                        label: 'Calories *',
                        suffix: 'cal',
                        keyboardType: TextInputType.number,
                        fillColor: fieldFill,
                        textColor: textColor,
                        labelColor: labelColor,
                        borderColor: borderColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _darkField(
                  controller: _ingredientsController,
                  label: 'Ingredients *',
                  hint: 'One ingredient per line',
                  maxLines: 4,
                  fillColor: fieldFill,
                  textColor: textColor,
                  labelColor: labelColor,
                  borderColor: borderColor,
                ),
                const SizedBox(height: 10),
                _darkField(
                  controller: _stepsController,
                  label: 'Steps *',
                  hint: 'One instruction per line',
                  maxLines: 4,
                  fillColor: fieldFill,
                  textColor: textColor,
                  labelColor: labelColor,
                  borderColor: borderColor,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: kAvailableLabels.map((label) {
                    final isSelected = _selectedLabels.contains(label);
                    return FilterChip(
                      selected: isSelected,
                      selectedColor: const Color(0xFF059669),
                      checkmarkColor: Colors.white,
                      backgroundColor:
                          isDarkMode ? const Color(0xFF102647) : Colors.white,
                      side: BorderSide(color: borderColor),
                      label: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? Colors.white : labelColor,
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
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.onSurface,
                      side: BorderSide(color: borderColor),
                      backgroundColor: isDarkMode
                          ? const Color(0xFF102647)
                          : null,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                    ),
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
