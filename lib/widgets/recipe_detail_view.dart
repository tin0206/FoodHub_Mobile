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

  Widget _buildIngredientChecklist({
    required List<String> ingredientItems,
    required Color accentColor,
    required ColorScheme colors,
    required bool isDarkMode,
    required Color panelColor,
    required Color borderColor,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      children: [
        Text(
          'Ingredients',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Prepare the following before cooking',
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 16),
        ...ingredientItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: panelColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCookingStepCard({
    required String step,
    required int stepNumber,
    required int totalSteps,
    required Color accentColor,
    required Color borderColor,
    required ColorScheme colors,
    required bool isDarkMode,
  }) {
    final infoBg = isDarkMode ? const Color(0xFF102647) : const Color(0xFFF8FAFC);

    return Column(
      children: [
        // ── Step header strip ────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: isDarkMode ? 0.14 : 0.07),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$stepNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Step $stepNumber',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                'of $totalSteps',
                style: TextStyle(
                  color: accentColor.withValues(alpha: 0.55),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // ── Instruction — vertically centered ────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Bottom info bar ──────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: BoxDecoration(
            color: infoBg,
            border: Border(top: BorderSide(color: borderColor)),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule_rounded, size: 14, color: accentColor),
              const SizedBox(width: 5),
              Text(
                '~${widget.recipe.estimatedMinutesPerStep} min',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 1,
                height: 14,
                color: borderColor,
              ),
              const SizedBox(width: 14),
              const Text('💡', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Take your time with this step',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

    final emoji = _recipeEmoji(widget.recipe.labels);

    return Column(
      children: [
        // ── Header: gradient hero (normal) or flat (cooking) ───────
        if (_isCookingMode)
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(bottom: BorderSide(color: borderColor)),
              boxShadow: isDarkMode
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: widget.onBack,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: accentColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.recipe.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                        accentColor.withValues(alpha: 0.35),
                        accentColor.withValues(alpha: 0.12),
                      ]
                    : [accentColor, accentColor.withValues(alpha: 0.75)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: widget.onBack,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        size: 17,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.recipe.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: -0.3,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 11,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${widget.recipe.cookingMinutes} min',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.local_fire_department_outlined,
                              size: 11,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${widget.recipe.calories} cal',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (widget.recipe.labels.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            children: widget.recipe.labels
                                .map(
                                  (tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isCookingMode)
            Expanded(
              child: Column(
                children: [
                  // ── Phase header strip (gradient) ─────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDarkMode
                            ? [
                                accentColor.withValues(alpha: 0.35),
                                accentColor.withValues(alpha: 0.12),
                              ]
                            : [
                                widget.cardColor,
                                widget.cardColor.withValues(alpha: 0.7),
                              ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _isPreparingIngredients
                                    ? Icons.shopping_basket_rounded
                                    : Icons.restaurant_menu_rounded,
                                color: Colors.white,
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
                                        ? 'Prepare Ingredients'
                                        : 'Step ${_currentStepIndex + 1} of $totalSteps',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    widget.recipe.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.75),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Animated progress pills
                        Row(
                          children: List.generate(totalSteps + 1, (i) {
                            final currentStage = _isPreparingIngredients
                                ? 0
                                : _currentStepIndex + 1;
                            final isActive = i == currentStage;
                            final isDone = i < currentStage;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeInOut,
                              margin: const EdgeInsets.only(right: 5),
                              width: isActive ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isDone || isActive
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                  // ── Content card ──────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: isDarkMode
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: _isPreparingIngredients
                            ? _buildIngredientChecklist(
                                ingredientItems: ingredientItems,
                                accentColor: accentColor,
                                colors: colors,
                                isDarkMode: isDarkMode,
                                panelColor: panelColor,
                                borderColor: borderColor,
                              )
                            : _buildCookingStepCard(
                                step: stepItems[_currentStepIndex],
                                stepNumber: _currentStepIndex + 1,
                                totalSteps: totalSteps,
                                accentColor: accentColor,
                                colors: colors,
                                isDarkMode: isDarkMode,
                                borderColor: borderColor,
                              ),
                      ),
                    ),
                  ),

                  // ── Navigation ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      children: [
                        Text(
                          _isPreparingIngredients
                              ? 'Tap ingredients to check them off'
                              : 'Take your time — tap Next when ready',
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.white.withValues(alpha: 0.45)
                                : widget.cardColor.withValues(alpha: 0.65),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isPreparingIngredients
                                    ? null
                                    : _previousStep,
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  size: 15,
                                ),
                                label: const Text('Back'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  foregroundColor: isDarkMode
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF374151),
                                  side: BorderSide(color: borderColor),
                                  backgroundColor: isDarkMode
                                      ? const Color(0xFF102647)
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDarkMode
                                        ? [
                                            accentColor.withValues(alpha: 0.9),
                                            accentColor,
                                          ]
                                        : [
                                            widget.cardColor,
                                            widget.cardColor.withValues(
                                              alpha: 0.8,
                                            ),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.cardColor.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: canFinish ? _finishCooking : _nextStep,
                                  icon: Icon(
                                    canFinish
                                        ? Icons.check_circle_rounded
                                        : Icons.arrow_forward_rounded,
                                    size: 17,
                                  ),
                                  label: Text(
                                    canFinish
                                        ? 'Finish! 🎉'
                                        : (_isPreparingIngredients
                                            ? 'Start Cooking'
                                            : 'Next'),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(48),
                                    textStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isEditMode) ...[
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 14),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 70,
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
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.local_fire_department_outlined,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 70,
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
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
          if (!_isCookingMode)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: widget.enableEdit
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

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Public: used by recipe cards AND detail view to keep colors consistent.
({String emoji, Color start, Color end}) recipeCardTheme(List<String> labels) {
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

String _recipeEmoji(List<String> labels) {
  for (final l in labels) {
    if (l == 'Vegan' || l == 'Vegetarian') return '🥗';
    if (l == 'Italian' || l == 'Comfort Food') return '🍝';
    if (l == 'High Protein' || l == 'Keto') return '💪';
    if (l == 'Breakfast') return '🌅';
    if (l == 'Quick Meal') return '⚡';
    if (l == 'Healthy') return '🌿';
    if (l == 'Pescetarian') return '🐟';
    if (l == 'Meal Prep') return '📦';
  }
  return '🍽️';
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
