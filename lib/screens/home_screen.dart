import 'package:flutter/material.dart';

const _kRecipeCardColors = [
  Color(0xFFFFF7ED), // warm amber
  Color(0xFFEFF6FF), // soft blue
  Color(0xFFF0FDF4), // mint green
  Color(0xFFFDF4FF), // lavender
  Color(0xFFFFF1F2), // rose
  Color(0xFFFEFCE8), // lemon
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
          'Step 1: Cook quinoa.\nStep 2: Slice vegetables.\nStep 3: Assemble bowl and drizzle sauce.',
      labels: ['Vegetarian', 'Healthy'],
    ),
    const _Recipe(
      name: 'Classic Italian Pasta',
      ingredients: '200g pasta\nTomato sauce\nGarlic\nParmesan\nBasil',
      steps:
          'Step 1: Boil pasta.\nStep 2: Simmer sauce with garlic.\nStep 3: Toss and top with parmesan.',
      labels: ['Italian', 'Comfort Food'],
    ),
    const _Recipe(
      name: 'Grilled Chicken & Veggies',
      ingredients:
          '2 chicken breasts\nBell pepper\nZucchini\nOlive oil\nSalt & pepper',
      steps:
          'Step 1: Season chicken.\nStep 2: Grill chicken and veggies.\nStep 3: Slice and serve warm.',
      labels: ['High Protein', 'Keto'],
    ),
    const _Recipe(
      name: 'Fresh Garden Salad',
      ingredients: 'Lettuce\nCucumber\nCherry tomatoes\nOlive oil\nLemon juice',
      steps:
          'Step 1: Chop vegetables.\nStep 2: Mix dressing.\nStep 3: Toss together and serve.',
      labels: ['Vegan', 'Quick Meal'],
    ),
    const _Recipe(
      name: 'Overnight Oats',
      ingredients: '1/2 cup oats\n1/2 cup milk\nChia seeds\nHoney\nBerries',
      steps:
          'Step 1: Combine all ingredients.\nStep 2: Refrigerate overnight.\nStep 3: Top with berries in the morning.',
      labels: ['Meal Prep', 'Breakfast'],
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
    setState(() {
      _isAddingRecipe = false;
    });
  }

  void _onSaveRecipe(_Recipe recipe) {
    setState(() {
      _recipes.add(recipe);
      _isAddingRecipe = false;
    });
  }

  void _closeRecipeDetails() {
    setState(() {
      _selectedRecipe = null;
      _selectedRecipeCardIndex = null;
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
                    Icon(
                      Icons.menu_book_outlined,
                      color: const Color(0xFF059669),
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
                          separatorBuilder: (context, index) =>
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

  void _openRecipeDetails(_Recipe recipe, int cardIndex) {
    setState(() {
      _isAddingRecipe = false;
      _selectedRecipe = recipe;
      _selectedRecipeCardIndex = cardIndex;
    });
  }
}

class _RecipeDetailView extends StatelessWidget {
  const _RecipeDetailView({
    required this.recipe,
    required this.cardColor,
    required this.onBack,
  });

  final _Recipe recipe;
  final Color cardColor;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accentColor = HSLColor.fromColor(cardColor)
        .withLightness(
          (HSLColor.fromColor(cardColor).lightness - 0.35).clamp(0.0, 1.0),
        )
        .withSaturation(0.7)
        .toColor();

    return Column(
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
                onTap: onBack,
                borderRadius: BorderRadius.circular(999),
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
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
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
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '25 min',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Icon(
                      Icons.local_fire_department_outlined,
                      size: 14,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '420 cal',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (recipe.labels.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: recipe.labels
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: colors.outlineVariant),
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
                const SizedBox(height: 12),
                _DetailSectionCard(
                  title: 'Ingredients',
                  icon: Icons.shopping_basket_outlined,
                  backgroundColor: Colors.white,
                  iconColor: accentColor,
                  children: recipe.ingredientItems
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.circle, size: 6, color: accentColor),
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
                _DetailSectionCard(
                  title: 'Instructions',
                  icon: Icons.format_list_numbered,
                  backgroundColor: Colors.white,
                  iconColor: accentColor,
                  children: recipe.stepItems
                      .asMap()
                      .entries
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(999),
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
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Open edit recipe screen/dialog
                  },
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    foregroundColor: colors.onSurfaceVariant,
                    side: BorderSide(color: colors.outline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    // TODO: Start cooking flow
                  },
                  label: const Text('Start Cooking'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.menu_book_outlined,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No recipes yet',
              style: TextStyle(
                fontSize: 28 / 2,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your own recipes and share your culinary creations',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAddFirstRecipe,
              icon: const Icon(Icons.add),
              label: const Text('Add your first recipe'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
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
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF059669),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
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
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: colors.outlineVariant),
                      borderRadius: BorderRadius.circular(999),
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
  static const _availableLabels = [
    'Dairy Free',
    'Egg Free',
    'Gluten Free',
    'Nut Free',
    'Vegan',
    'Vegetarian',
    'Pescetarian',
  ];

  final _nameController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _stepsController = TextEditingController();
  final Set<String> _selectedLabels = {};

  @override
  void dispose() {
    _nameController.dispose();
    _ingredientsController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final ingredients = _ingredientsController.text.trim();
    final steps = _stepsController.text.trim();

    if (name.isEmpty || ingredients.isEmpty || steps.isEmpty) {
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
                  visualDensity: VisualDensity.compact,
                  splashRadius: 18,
                  onPressed: widget.onCancel,
                  icon: Icon(
                    Icons.close,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              children: [
                Text(
                  'Recipe Name *',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Grandma\'s Soup',
                    hintStyle: TextStyle(fontSize: 12),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Ingredients (one per line) *',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _ingredientsController,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: '1 cup rice\n2 tomatoes\n...',
                    hintStyle: TextStyle(fontSize: 12),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Steps *',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _stepsController,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Step 1: ...\nStep 2: ...',
                    hintStyle: TextStyle(fontSize: 12),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Dietary labels',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _availableLabels.map((label) {
                    final isSelected = _selectedLabels.contains(label);
                    return FilterChip(
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFF059669),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF059669)
                            : colors.outlineVariant,
                      ),
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
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedLabels.add(label);
                          } else {
                            _selectedLabels.remove(label);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.outlineVariant)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      foregroundColor: Colors.black,
                      textStyle: const TextStyle(fontWeight: FontWeight.w400),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Save'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      backgroundColor: const Color(0xFF9CD9C1),
                      foregroundColor: Colors.white,
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

class _Recipe {
  const _Recipe({
    required this.name,
    required this.ingredients,
    required this.steps,
    required this.labels,
  });

  final String name;
  final String ingredients;
  final String steps;
  final List<String> labels;

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
    if (ingredientItems.isEmpty) {
      return '';
    }
    if (ingredientItems.length <= 3) {
      return ingredientItems.join(', ');
    }
    return '${ingredientItems.take(3).join(', ')}, ...';
  }
}
