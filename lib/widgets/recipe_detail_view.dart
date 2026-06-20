import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const kAvailableLabels = [
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

class RecipeDetailData {
  const RecipeDetailData({
    required this.name,
    required this.cookingMinutes,
    required this.calories,
    required this.ingredients,
    required this.steps,
    required this.labels,
  });

  final String name;
  final int cookingMinutes;
  final int calories;
  final String ingredients;
  final String steps;
  final List<String> labels;

  List<String> get ingredientItems => ingredients
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  List<String> get stepItems => steps
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  int get estimatedMinutesPerStep {
    final total = stepItems.length;
    if (total == 0) return 0;
    final m = (cookingMinutes / total).round();
    return m < 1 ? 1 : m;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecipeDetailData &&
        other.name == name &&
        other.cookingMinutes == cookingMinutes &&
        other.calories == calories &&
        other.ingredients == ingredients &&
        other.steps == steps &&
        listEquals(other.labels, labels);
  }

  @override
  int get hashCode => Object.hash(
    name,
    cookingMinutes,
    calories,
    ingredients,
    steps,
    Object.hashAll(labels),
  );
}

class RecipeDetailView extends StatefulWidget {
  const RecipeDetailView({
    super.key,
    required this.recipe,
    required this.cardColor,
    required this.onBack,
    this.enableEdit = false,
    this.onSaveEdited,
    this.isSaved,
    this.onToggleSave,
  });

  final RecipeDetailData recipe;
  final Color cardColor;
  final VoidCallback onBack;

  /// If true, shows Edit / Save Changes buttons (home screen).
  final bool enableEdit;
  final ValueChanged<RecipeDetailData>? onSaveEdited;

  /// Null means no save button is shown (home screen with enableEdit).
  final bool? isSaved;
  final VoidCallback? onToggleSave;

  @override
  State<RecipeDetailView> createState() => _RecipeDetailViewState();
}

class _RecipeDetailViewState extends State<RecipeDetailView> {
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
  void didUpdateWidget(covariant RecipeDetailView oldWidget) {
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

  Future<void> _saveEditedRecipe() async {
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

    final updated = RecipeDetailData(
      name: widget.recipe.name,
      cookingMinutes: cookingMinutes,
      calories: calories,
      ingredients: ingredients,
      steps: steps,
      labels: _selectedEditLabels.toList(),
    );

    widget.onSaveEdited?.call(updated);
    setState(() => _isEditMode = false);
  }

  void _showCompletionFireworks() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'completion-fireworks',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      pageBuilder: (_, _, _) => const FireworksCelebration(),
    );
  }

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
    final stepItems = widget.recipe.stepItems;
    final ingredientItems = widget.recipe.ingredientItems;
    final totalSteps = stepItems.length;

    final totalCookingStages = totalSteps + 1;
    final currentCookingStage = _isPreparingIngredients
        ? 1
        : (_currentStepIndex + 2);
    final progress = currentCookingStage / totalCookingStages;
    final progressLabel = '${(progress * 100).round()}%';
    final canFinish =
        !_isPreparingIngredients && _currentStepIndex == totalSteps - 1;

    final accentColor = HSLColor.fromColor(widget.cardColor)
        .withLightness(
          (HSLColor.fromColor(widget.cardColor).lightness - 0.35).clamp(
            0.0,
            1.0,
          ),
        )
        .withSaturation(0.7)
        .toColor();

    final isSaved = widget.isSaved;
    final saveColor = (isSaved == true)
        ? const Color(0xFFDC2626)
        : colors.onSurfaceVariant;

    return Container(
      color: isDarkMode ? const Color(0xFF07152D) : widget.cardColor,
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
          if (_isCookingMode)
            Expanded(
              child: Padding(
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
                          color: panelColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: _isPreparingIngredients
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                      padding: const EdgeInsets.only(bottom: 8),
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
                                                color: colors.onSurfaceVariant,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                        'Estimated: ${widget.recipe.estimatedMinutesPerStep} min',
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
              ),
            )
          else
            Flexible(
              child: SingleChildScrollView(
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
                        if (_isEditMode)
                          SizedBox(
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
                        else
                          Text(
                            '${widget.recipe.cookingMinutes} min',
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
                        if (_isEditMode)
                          SizedBox(
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
                        else
                          Text(
                            '${widget.recipe.calories} cal',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _RecipeDetailSectionCard(
                      title: 'Ingredients',
                      icon: Icons.shopping_basket_outlined,
                      backgroundColor: panelColor,
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
                          : ingredientItems
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
                    _RecipeDetailSectionCard(
                      title: 'Instructions',
                      icon: Icons.format_list_numbered,
                      backgroundColor: panelColor,
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
                          : stepItems
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
                                                : widget.cardColor,
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
                    _RecipeDetailSectionCard(
                      title: 'Labels',
                      icon: Icons.sell_outlined,
                      backgroundColor: panelColor,
                      iconColor: accentColor,
                      children: _isEditMode
                          ? [
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: kAvailableLabels.map((label) {
                                  final isSelected = _selectedEditLabels
                                      .contains(label);
                                  return FilterChip(
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    backgroundColor: Colors.white,
                                    side: BorderSide(color: borderColor),
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
                                          color: panelColor,
                                          border: Border.all(
                                            color: borderColor,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
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
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
            child: _isCookingMode
                ? Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isPreparingIngredients
                              ? null
                              : _previousStep,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                            foregroundColor: colors.onSurface,
                            side: BorderSide(color: borderColor),
                            backgroundColor: panelColor,
                          ),
                          child: const Text('Previous'),
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
                : widget.enableEdit
                ? Row(
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
                            backgroundColor: panelColor,
                            foregroundColor: colors.onSurface,
                            side: BorderSide(color: borderColor),
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
                  )
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onToggleSave,
                          icon: Icon(
                            (isSaved == true)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 15,
                            color: (isSaved == true)
                                ? const Color(0xFFDC2626)
                                : saveColor,
                          ),
                          label: Text((isSaved == true) ? 'Saved' : 'Save'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                            backgroundColor: panelColor,
                            foregroundColor: saveColor,
                            side: BorderSide(
                              color: (isSaved == true)
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
                          onPressed: _openCookingMode,
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

class FireworksCelebration extends StatefulWidget {
  const FireworksCelebration({super.key});

  @override
  State<FireworksCelebration> createState() => _FireworksCelebrationState();
}

class _FireworksCelebrationState extends State<FireworksCelebration>
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

class _RecipeDetailSectionCard extends StatelessWidget {
  const _RecipeDetailSectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.backgroundColor = const Color(0xFFF8FAFC),
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
