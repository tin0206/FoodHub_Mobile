import 'package:flutter/material.dart';
import 'package:foodhub_mobile/widgets/recipe_detail_view.dart';

const _kRecipeCardColors = [
  Color(0xFFFFF7ED),
  Color(0xFFEFF6FF),
  Color(0xFFF0FDF4),
  Color(0xFFFDF4FF),
  Color(0xFFFFF1F2),
  Color(0xFFFEFCE8),
];

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
    final colors = Theme.of(context).colorScheme;

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
        cardColor: _kRecipeCardColors[_selectedRecipeCardIndex! %
            _kRecipeCardColors.length],
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode
        ? const Color(0xFF0B1B38)
        : _kRecipeCardColors[cardIndex % _kRecipeCardColors.length];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF274A73) : colors.outlineVariant,
        ),
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
                    backgroundColor: isDarkMode
                        ? const Color(0xFF102647)
                        : Colors.white,
                    side: BorderSide(
                      color: isDarkMode
                          ? const Color(0xFF274A73)
                          : colors.outlineVariant,
                    ),
                    label: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode
                            ? const Color(0xFFCBD5E1)
                            : colors.onSurfaceVariant,
                      ),
                    ),
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
                  children: kAvailableLabels.map((label) {
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
