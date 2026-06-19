import 'dart:math' as math;

import 'package:flutter/material.dart';

const _kFavoriteCardColors = [
  Color(0xFFFFF7ED),
  Color(0xFFEFF6FF),
  Color(0xFFF0FDF4),
  Color(0xFFFFF1F2),
];

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final List<_FavoriteRecipe> _recipes = [
    const _FavoriteRecipe(
      name: 'Quinoa Buddha Bowl',
      duration: 25,
      calories: 420,
      note: 'Great for meal prep! Double the tahini dressing.',
      ingredients:
          '2 cups quinoa\n1 cup chickpeas\n1/2 avocado\nTahini dressing\nMixed greens',
      instructions:
          'Cook quinoa per package.\nRoast chickpeas at 200°C for 20 min.\nAssemble bowl with greens, quinoa, chickpeas.\nTop with avocado and tahini.',
      tags: ['Vegetarian', 'Healthy'],
    ),
    const _FavoriteRecipe(
      name: 'Grilled Chicken & Veggies',
      duration: 35,
      calories: 450,
      note: null,
      ingredients:
          '2 chicken breasts\nBell pepper\nZucchini\nOlive oil\nSalt and pepper',
      instructions:
          'Season the chicken.\nGrill chicken and vegetables.\nSlice chicken.\nServe warm with veggies.',
      tags: ['High Protein', 'Keto'],
    ),
  ];

  int? _selectedRecipeIndex;
  bool _savedCurrentRecipe = true;
  bool _isCookingMode = false;
  bool _isPreparingIngredients = true;
  int _currentStepIndex = 0;
  bool _isUnfavoriteDialogOpen = false;
  bool _isNoteDialogOpen = false;

  void _openRecipeDetails(int index) {
    if (index < 0 || index >= _recipes.length) return;

    setState(() {
      _selectedRecipeIndex = index;
      _savedCurrentRecipe = true;
      _isCookingMode = false;
      _isPreparingIngredients = true;
      _currentStepIndex = 0;
    });
  }

  void _closeRecipeDetails() {
    if (_selectedRecipeIndex == null) return;

    final index = _selectedRecipeIndex!;
    final removedName = _recipes[index].name;

    if (!_savedCurrentRecipe && index < _recipes.length) {
      _recipes.removeAt(index);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$removedName removed from favorites.')),
      );
    }

    setState(() {
      _selectedRecipeIndex = null;
      _savedCurrentRecipe = true;
      _isCookingMode = false;
      _isPreparingIngredients = true;
      _currentStepIndex = 0;
    });
  }

  void _toggleSaveInDetail() {
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

  void _startCooking() {
    setState(() {
      _isCookingMode = true;
      _isPreparingIngredients = true;
      _currentStepIndex = 0;
    });
  }

  void _previousCookingStep() {
    if (_isPreparingIngredients) return;

    setState(() {
      if (_currentStepIndex == 0) {
        _isPreparingIngredients = true;
      } else {
        _currentStepIndex -= 1;
      }
    });
  }

  void _nextCookingStep(_FavoriteRecipe recipe) {
    if (_isPreparingIngredients) {
      setState(() {
        _isPreparingIngredients = false;
        _currentStepIndex = 0;
      });
      return;
    }

    if (_currentStepIndex >= recipe.stepItems.length - 1) return;

    setState(() {
      _currentStepIndex += 1;
    });
  }

  void _finishCooking() {
    setState(() {
      _isCookingMode = false;
    });

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'completion-fireworks',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      pageBuilder: (_, _, _) => const _FavoriteFireworksCelebration(),
    );
  }

  Future<void> _onEditNote(int index) async {
    if (_isNoteDialogOpen) return;

    _isNoteDialogOpen = true;
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      _isNoteDialogOpen = false;
      return;
    }

    final current = _recipes[index];
    final updatedNote = await _showEditNoteDialog(
      initialNote: current.note ?? '',
    );
    _isNoteDialogOpen = false;

    if (!mounted || updatedNote == null) return;

    setState(() {
      _recipes[index] = current.copyWith(
        note: updatedNote.trim().isEmpty ? null : updatedNote.trim(),
      );
    });
  }

  Future<void> _onUnfavorite(int index) async {
    if (_isUnfavoriteDialogOpen) return;

    _isUnfavoriteDialogOpen = true;
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      _isUnfavoriteDialogOpen = false;
      return;
    }

    final recipe = _recipes[index];
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Remove from favorites?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          content: Text(
            'Do you want to remove "${recipe.name}" from your saved recipes?',
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF4B5563),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Unfavorite'),
            ),
          ],
        );
      },
    );
    _isUnfavoriteDialogOpen = false;

    if (shouldRemove != true || !mounted) return;

    setState(() {
      _recipes.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${recipe.name} removed from favorites.')),
    );
  }

  Future<String?> _showEditNoteDialog({required String initialNote}) async {
    final controller = TextEditingController(text: initialNote);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Note',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                  ),
                  child: TextField(
                    controller: controller,
                    minLines: 3,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Write your note...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(10),
                      isDense: true,
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(34),
                          backgroundColor: const Color(0xFFF3F4F6),
                          foregroundColor: const Color(0xFF374151),
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.of(context).pop(controller.text),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(34),
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Save Note'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    controller.dispose();
    return result;
  }

  int get _savedCount => _recipes.length;

  int get _noteCount =>
      _recipes.where((r) => (r.note ?? '').trim().isNotEmpty).length;

  @override
  Widget build(BuildContext context) {
    if (_selectedRecipeIndex != null) {
      final recipe = _recipes[_selectedRecipeIndex!];
      final cardColor =
          _kFavoriteCardColors[_selectedRecipeIndex! %
              _kFavoriteCardColors.length];

      return _FavoriteRecipeDetailView(
        recipe: recipe,
        cardColor: cardColor,
        isSaved: _savedCurrentRecipe,
        isCookingMode: _isCookingMode,
        isPreparingIngredients: _isPreparingIngredients,
        currentStepIndex: _currentStepIndex,
        onBack: _closeRecipeDetails,
        onSave: _toggleSaveInDetail,
        onStartCooking: _startCooking,
        onPrevious: _previousCookingStep,
        onNext: () => _nextCookingStep(recipe),
        onFinish: _finishCooking,
      );
    }

    return Container(
      color: const Color(0xFFE5E7EB),
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          Row(
            children: const [
              Icon(Icons.favorite, size: 20, color: Color(0xFFE11D48)),
              SizedBox(width: 6),
              Text(
                'Favorites',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Saved recipes with your notes',
            style: TextStyle(fontSize: 10.5, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(value: '$_savedCount', label: 'Saved'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(value: '$_noteCount', label: 'With Notes'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_recipes.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD1D5DB)),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.favorite_border,
                    color: Color(0xFF9CA3AF),
                    size: 28,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No favorites yet',
                    style: TextStyle(
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ...List.generate(_recipes.length, (index) {
            final recipe = _recipes[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _FavoriteRecipeCard(
                recipe: recipe,
                onTap: () => _openRecipeDetails(index),
                onEditNote: () => _onEditNote(index),
                onUnfavorite: () => _onUnfavorite(index),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FavoriteRecipeDetailView extends StatelessWidget {
  const _FavoriteRecipeDetailView({
    required this.recipe,
    required this.cardColor,
    required this.isSaved,
    required this.isCookingMode,
    required this.isPreparingIngredients,
    required this.currentStepIndex,
    required this.onBack,
    required this.onSave,
    required this.onStartCooking,
    required this.onPrevious,
    required this.onNext,
    required this.onFinish,
  });

  final _FavoriteRecipe recipe;
  final Color cardColor;
  final bool isSaved;
  final bool isCookingMode;
  final bool isPreparingIngredients;
  final int currentStepIndex;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onStartCooking;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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
      color: cardColor,
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
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.outlineVariant),
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
                        _FavoriteDetailSectionCard(
                          title: 'Ingredients',
                          icon: Icons.shopping_basket_outlined,
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
                        _FavoriteDetailSectionCard(
                          title: 'Instructions',
                          icon: Icons.format_list_numbered,
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
                                          color: cardColor,
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
                        _FavoriteDetailSectionCard(
                          title: 'Labels',
                          icon: Icons.sell_outlined,
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
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: colors.outlineVariant,
                                        ),
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
                          onPressed: isPreparingIngredients ? null : onPrevious,
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
                            backgroundColor: Colors.white,
                            foregroundColor: saveColor,
                            side: BorderSide(
                              color: isSaved
                                  ? const Color(0xFFFCA5A5)
                                  : colors.outline,
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

class _FavoriteRecipeCard extends StatelessWidget {
  const _FavoriteRecipeCard({
    required this.recipe,
    required this.onTap,
    required this.onEditNote,
    required this.onUnfavorite,
  });

  final _FavoriteRecipe recipe;
  final VoidCallback onTap;
  final VoidCallback onEditNote;
  final VoidCallback onUnfavorite;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipe.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.schedule_outlined,
                    size: 13,
                    color: Color(0xFF4B5563),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${recipe.duration} min',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.local_fire_department_outlined,
                    size: 13,
                    color: Color(0xFF4B5563),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${recipe.calories} cal',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
              if ((recipe.note ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF2C94C)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sticky_note_2_outlined,
                        size: 13,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          recipe.note!,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEditNote,
                      icon: const Icon(Icons.edit_note_outlined, size: 14),
                      label: Text(
                        recipe.note == null ? 'Add Note' : 'Edit Note',
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(30),
                        backgroundColor: const Color(0xFFF3F4F6),
                        foregroundColor: const Color(0xFF374151),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 34,
                    height: 30,
                    child: OutlinedButton(
                      onPressed: onUnfavorite,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: const Color(0xFFF9FAFB),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Color(0xFFE11D48),
                        size: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteDetailSectionCard extends StatelessWidget {
  const _FavoriteDetailSectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.iconColor = const Color(0xFF059669),
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
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

class _FavoriteRecipe {
  const _FavoriteRecipe({
    required this.name,
    required this.duration,
    required this.calories,
    required this.note,
    required this.ingredients,
    required this.instructions,
    required this.tags,
  });

  final String name;
  final int duration;
  final int calories;
  final String? note;
  final String ingredients;
  final String instructions;
  final List<String> tags;

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
    if (stepItems.isEmpty) return 0;
    final minutes = (duration / stepItems.length).round();
    return minutes < 1 ? 1 : minutes;
  }

  _FavoriteRecipe copyWith({
    String? name,
    int? duration,
    int? calories,
    String? note,
    String? ingredients,
    String? instructions,
    List<String>? tags,
  }) {
    return _FavoriteRecipe(
      name: name ?? this.name,
      duration: duration ?? this.duration,
      calories: calories ?? this.calories,
      note: note,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      tags: tags ?? this.tags,
    );
  }
}

class _FavoriteFireworksCelebration extends StatefulWidget {
  const _FavoriteFireworksCelebration();

  @override
  State<_FavoriteFireworksCelebration> createState() =>
      _FavoriteFireworksCelebrationState();
}

class _FavoriteFireworksCelebrationState
    extends State<_FavoriteFireworksCelebration>
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
