import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodhub_mobile/config/api_config.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';
import 'package:foodhub_mobile/models/ingredient.dart';
import 'package:foodhub_mobile/services/recipe_service.dart';
import 'package:foodhub_mobile/widgets/favorite_toast.dart';
import 'package:foodhub_mobile/widgets/recipe_image.dart';
import 'package:image_picker/image_picker.dart';

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
    required this.id,
    required this.name,
    this.imageUrl,
    required this.cookingMinutes,
    this.calories,
    this.estimatedServings,
    required this.ingredients,
    required this.steps,
    required this.labels,
    this.isPrivate = false,
    this.mappedIngredients = const [],
    this.nutrition,
  });

  final int id;
  final String name;
  final String? imageUrl;
  final int cookingMinutes;
  final int? calories;
  final int? estimatedServings;
  final String ingredients;
  final String steps;
  final List<String> labels;
  final bool isPrivate;
  final List<MappedIngredient> mappedIngredients;
  final RecipeNutrition? nutrition;

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
        other.imageUrl == imageUrl &&
        other.cookingMinutes == cookingMinutes &&
        other.calories == calories &&
        other.estimatedServings == estimatedServings &&
        other.ingredients == ingredients &&
        other.steps == steps &&
        listEquals(other.labels, labels);
  }

  @override
  int get hashCode => Object.hash(
    name,
    imageUrl,
    cookingMinutes,
    calories,
    estimatedServings,
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
    this.onDelete,
    this.isSaved,
    this.onToggleSave,
  });

  final RecipeDetailData recipe;
  final Color cardColor;
  final VoidCallback onBack;

  /// If true, shows Edit / Save Changes buttons (home screen).
  final bool enableEdit;
  final ValueChanged<RecipeDetailData>? onSaveEdited;
  final VoidCallback? onDelete;

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

  double _swipeDragStartX = 0;
  double _swipeDragStartY = 0;
  bool _swipeHandled = false;

  Uint8List? _editImageBytes;
  String _editImageFilename = 'recipe.jpg';
  final _recipeService = RecipeService();

  late List<TextEditingController> _ingredientControllers;
  late List<TextEditingController> _stepControllers;
  late TextEditingController _titleController;
  late TextEditingController _cookingMinutesController;
  late TextEditingController _servingsController;
  late Set<String> _selectedEditLabels;
  List<String> _availableLabels = [];
  bool _showMoreNutrition = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableLabels();
    _ingredientControllers = _controllersFromLines(widget.recipe.ingredientItems);
    _stepControllers = widget.recipe.stepItems
        .map((s) => TextEditingController(text: s))
        .toList();
    if (_stepControllers.isEmpty) {
      _stepControllers.add(TextEditingController());
    }
    _titleController = TextEditingController(text: widget.recipe.name);
    _cookingMinutesController = TextEditingController(
      text: widget.recipe.cookingMinutes.toString(),
    );
    _servingsController = TextEditingController(
      text: (widget.recipe.estimatedServings ?? 1).toString(),
    );
    _selectedEditLabels = widget.recipe.labels.toSet();
  }

  Future<void> _loadAvailableLabels() async {
    try {
      final options = await _recipeService.getDietaryRestrictions();
      if (mounted) setState(() => _availableLabels = options);
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant RecipeDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recipe != widget.recipe) {
      for (final c in _stepControllers) {
        c.dispose();
      }
      for (final c in _ingredientControllers) {
        c.dispose();
      }
      _ingredientControllers = _controllersFromLines(widget.recipe.ingredientItems);
      _stepControllers = widget.recipe.stepItems
          .map((s) => TextEditingController(text: s))
          .toList();
      if (_stepControllers.isEmpty) {
        _stepControllers.add(TextEditingController());
      }
      _titleController.text = widget.recipe.name;
      _cookingMinutesController.text = widget.recipe.cookingMinutes.toString();
      _servingsController.text =
          (widget.recipe.estimatedServings ?? 1).toString();
      _selectedEditLabels = widget.recipe.labels.toSet();
      _isEditMode = false;
      _isCookingMode = false;
      _isPreparingIngredients = true;
      _currentStepIndex = 0;
      _editImageBytes = null;
    }
  }

  List<TextEditingController> _controllersFromLines(List<String> lines) {
    if (lines.isEmpty) return [TextEditingController()];
    return lines.map((s) => TextEditingController(text: s)).toList();
  }

  Future<void> _pickEditImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _editImageBytes = bytes;
      _editImageFilename = file.name.isNotEmpty ? file.name : 'recipe.jpg';
    });
  }

  @override
  void dispose() {
    for (final c in _ingredientControllers) {
      c.dispose();
    }
    for (final c in _stepControllers) {
      c.dispose();
    }
    _titleController.dispose();
    _cookingMinutesController.dispose();
    _servingsController.dispose();
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

  void _closeCookingMode() {
    setState(() {
      _isCookingMode = false;
      _isPreparingIngredients = true;
      _currentStepIndex = 0;
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
    final title = _titleController.text.trim();
    final ingredients = _ingredientControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final steps = _stepControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .join('\n');
    final cookingMinutes = int.tryParse(_cookingMinutesController.text.trim());
    final servings = int.tryParse(_servingsController.text.trim());

    if (title.isEmpty ||
        ingredients.isEmpty ||
        steps.isEmpty ||
        servings == null ||
        servings <= 0) {
      showErrorToast(context, S.of(context).fillAllFields);
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: CircularProgressIndicator(color: widget.cardColor),
          ),
        ),
      ),
    );

    String? uploadedImageUrl;
    if (_editImageBytes != null) {
      uploadedImageUrl = await _recipeService.uploadRecipeImage(
        widget.recipe.id,
        _editImageBytes!,
        _editImageFilename,
      );
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }

    if (!mounted) return;
    Navigator.of(context).pop();

    final updated = RecipeDetailData(
      id: widget.recipe.id,
      name: title,
      imageUrl: uploadedImageUrl ?? widget.recipe.imageUrl,
      cookingMinutes: cookingMinutes != null && cookingMinutes > 0
          ? cookingMinutes
          : widget.recipe.cookingMinutes,
      calories: widget.recipe.calories,
      estimatedServings: servings,
      ingredients: ingredients.join('\n'),
      steps: steps,
      labels: _selectedEditLabels.toList(),
      isPrivate: widget.recipe.isPrivate,
      mappedIngredients: widget.recipe.mappedIngredients,
      nutrition: widget.recipe.nutrition,
    );

    widget.onSaveEdited?.call(updated);
    setState(() {
      _isEditMode = false;
      _editImageBytes = null;
    });
  }

  List<Widget> _buildIngredientEditList({
    required Color accentColor,
    required ColorScheme colors,
  }) {
    return [
      ..._ingredientControllers.asMap().entries.map((entry) {
        final i = entry.key;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: entry.value,
                  maxLines: 1,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(fontSize: 13, color: colors.onSurface),
                  decoration: InputDecoration(
                    hintText: S.of(context).ingredientHint(i),
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: accentColor, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 6,
                    ),
                  ),
                ),
              ),
              if (_ingredientControllers.length > 1) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => setState(() {
                    _ingredientControllers[i].dispose();
                    _ingredientControllers.removeAt(i);
                  }),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }),
      TextButton.icon(
        onPressed: () => setState(
          () => _ingredientControllers.add(TextEditingController()),
        ),
        icon: const Icon(Icons.add, size: 14),
        label: Text(S.of(context).addIngredient),
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    ];
  }

  Widget _buildNutritionBlock(ColorScheme colors, Color accentColor) {
    final nutrition = widget.recipe.nutrition!;
    final s = S.of(context);
    String fmt(double? v) => v == null ? '—' : (v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.perServingLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _macroChip('${fmt(nutrition.kcalPerServing)} ${s.calSuffix}', accentColor, colors),
            const SizedBox(width: 8),
            _macroChip('${fmt(nutrition.proteinPerServing)}g ${s.proteinShort}', accentColor, colors),
            const SizedBox(width: 8),
            _macroChip('${fmt(nutrition.carbsPerServing)}g ${s.carbsShort}', accentColor, colors),
            const SizedBox(width: 8),
            _macroChip('${fmt(nutrition.fatPerServing)}g ${s.fatShort}', accentColor, colors),
          ],
        ),
        if (nutrition.extraPerServing.isNotEmpty) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _showMoreNutrition = !_showMoreNutrition),
            child: Text(
              _showMoreNutrition ? s.hideNutrition : s.moreNutrition,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
          ),
          if (_showMoreNutrition) ...[
            const SizedBox(height: 8),
            for (final entry in nutrition.extraPerServing)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                      ),
                    ),
                    Text(
                      fmt(entry.value),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ],
    );
  }

  Widget _macroChip(String label, Color accentColor, ColorScheme colors) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStepEditList({
    required Color accentColor,
    required ColorScheme colors,
    required bool isDarkMode,
  }) {
    return [
      ..._stepControllers.asMap().entries.map((entry) {
        final i = entry.key;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDarkMode ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: entry.value,
                  maxLines: null,
                  minLines: 1,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(fontSize: 13, color: colors.onSurface),
                  decoration: InputDecoration(
                    hintText: S.of(context).stepHint(i),
                    hintStyle: TextStyle(fontSize: 13, color: colors.onSurfaceVariant.withValues(alpha: 0.5)),
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: accentColor, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                  ),
                ),
              ),
              if (_stepControllers.length > 1) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => setState(() {
                    _stepControllers[i].dispose();
                    _stepControllers.removeAt(i);
                  }),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }),
      TextButton.icon(
        onPressed: () =>
            setState(() => _stepControllers.add(TextEditingController())),
        icon: const Icon(Icons.add, size: 14),
        label: Text(S.of(context).addStep),
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    ];
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDarkMode ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.restaurant_menu_rounded,
                size: 20,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).getReady,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  Text(
                    S.of(context).ingredientsToPrepare(ingredientItems.length),
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                '${ingredientItems.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        ...ingredientItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: panelColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDarkMode ? 0.3 : 0.06,
                    ),
                    blurRadius: isDarkMode ? 6 : 8,
                    offset: const Offset(0, 2),
                  ),
                ],
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
    final infoBg = isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF8FAFC);

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
                S.of(context).stepLabel(stepNumber),
                style: TextStyle(
                  color: accentColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                S.of(context).ofTotal(totalSteps),
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
                    color: isDarkMode ? Colors.white : colors.onSurface,
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
                S.of(context).estimatedTimePerStep(widget.recipe.estimatedMinutesPerStep),
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
                  S.of(context).takeYourTimeWithStep,
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
    final surfaceColor = isDarkMode ? const Color(0xFF141414) : Colors.white;
    final panelColor = isDarkMode
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF8FAFC);
    final borderColor = isDarkMode
        ? const Color(0xFF2A2A2A)
        : colors.outlineVariant;
    final stepItems = widget.recipe.stepItems;
    final ingredientItems = widget.recipe.ingredientItems;
    final totalSteps = stepItems.length;

    final canFinish =
        !_isPreparingIngredients && _currentStepIndex == totalSteps - 1;

    final baseHsl = HSLColor.fromColor(widget.cardColor);
    final accentColor = isDarkMode
        ? baseHsl
            .withLightness((baseHsl.lightness + 0.1).clamp(0.0, 1.0))
            .withSaturation((baseHsl.saturation + 0.05).clamp(0.0, 1.0))
            .toColor()
        : baseHsl
            .withLightness((baseHsl.lightness - 0.35).clamp(0.0, 1.0))
            .withSaturation(0.7)
            .toColor();

    final isSaved = widget.isSaved;
    final saveColor = (isSaved == true)
        ? const Color(0xFFDC2626)
        : colors.onSurfaceVariant;

    final emoji = _recipeEmoji(widget.recipe.labels);
    final hasImage = widget.recipe.imageUrl != null &&
        widget.recipe.imageUrl!.isNotEmpty &&
        ApiConfig.resolveImageUrl(widget.recipe.imageUrl).isNotEmpty;

    return Listener(
      onPointerDown: (e) {
        _swipeDragStartX = e.position.dx;
        _swipeDragStartY = e.position.dy;
        _swipeHandled = false;
      },
      onPointerMove: (e) {
        if (_swipeHandled || _isCookingMode) return;
        final dx = e.position.dx - _swipeDragStartX;
        final dy = (e.position.dy - _swipeDragStartY).abs();
        // Left swipe >= 90px, dy < 50px to exclude vertical scroll
        if (dx < -90 && dy < 50) {
          _swipeHandled = true;
          if (_isEditMode) {
            setState(() => _isEditMode = false);
          } else {
            widget.onBack();
          }
        }
      },
      child: Column(
        children: [
        // ── Header: gradient hero (normal) or flat (cooking) ───────
        if (_isCookingMode)
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDarkMode ? 0.35 : 0.06),
                  blurRadius: isDarkMode ? 10 : 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: _closeCookingMode,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: isDarkMode ? Colors.white : accentColor,
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
        else if (_isEditMode)
          DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDarkMode ? 0.35 : 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 160,
                child: _editImageBytes != null
                    ? Image.memory(_editImageBytes!, fit: BoxFit.cover, width: double.infinity)
                    : hasImage
                        ? RecipeImageHeader(
                            imageUrl: widget.recipe.imageUrl,
                            recipeId: widget.recipe.id,
                            labels: widget.recipe.labels,
                            height: 160,
                            borderRadius: BorderRadius.zero,
                          )
                        : Container(
                            color: isDarkMode ? const Color(0xFF1C1C1C) : const Color(0xFFF3F4F6),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 32,
                                    color: isDarkMode ? Colors.white30 : Colors.black26),
                                const SizedBox(height: 4),
                                Text(S.of(context).addPhoto,
                                    style: TextStyle(fontSize: 12,
                                        color: isDarkMode ? Colors.white30 : Colors.black38)),
                              ],
                            ),
                          ),
              ),
              if (_editImageBytes != null || hasImage)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _pickEditImage,
                    child: ColoredBox(color: Colors.black.withValues(alpha: 0.28)),
                  ),
                ),
              Positioned(
                top: 10,
                left: 12,
                child: GestureDetector(
                  onTap: widget.onBack,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, size: 17, color: Colors.white),
                  ),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  onTap: _pickEditImage,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_camera_outlined, size: 15, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            (_editImageBytes != null || hasImage)
                                ? S.of(context).changePhoto
                                : S.of(context).addPhoto,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )),
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
                                        ? S.of(context).prepareIngredients
                                        : S.of(context).stepOf(_currentStepIndex + 1, totalSteps),
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
                        if (!_isPreparingIngredients)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              S.of(context).takeYourTime,
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white.withValues(alpha: 0.45)
                                    : widget.cardColor.withValues(alpha: 0.65),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: OutlinedButton.icon(
                                onPressed: _isPreparingIngredients
                                    ? null
                                    : _previousStep,
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  size: 15,
                                ),
                                label: Text(S.of(context).back),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  foregroundColor: isDarkMode
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF374151),
                                  side: BorderSide.none,
                                  backgroundColor: isDarkMode
                                      ? const Color(0xFF1E1E1E)
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3,
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
                                        ? S.of(context).finish
                                        : (_isPreparingIngredients
                                            ? S.of(context).startCooking
                                            : S.of(context).next),
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
              child: Stack(
                children: [
                  Positioned.fill(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!_isEditMode && hasImage)
                            Stack(
                              children: [
                                RecipeImageHeader(
                                  imageUrl: widget.recipe.imageUrl,
                                  recipeId: widget.recipe.id,
                                  labels: widget.recipe.labels,
                                  height: 200,
                                  borderRadius: BorderRadius.zero,
                                ),
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.35),
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.65),
                                        ],
                                        stops: const [0, 0.35, 1],
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 12,
                                  right: 16,
                                  bottom: 12,
                                  child: _DetailHeaderInfo(recipe: widget.recipe),
                                ),
                              ],
                            )
                          else if (!_isEditMode)
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
                                padding: const EdgeInsets.fromLTRB(56, 10, 16, 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(emoji, style: const TextStyle(fontSize: 26)),
                                    const SizedBox(width: 10),
                                    Expanded(child: _DetailHeaderInfo(recipe: widget.recipe)),
                                  ],
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                    if (_isEditMode) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: panelColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDarkMode ? 0.28 : 0.07),
                              blurRadius: isDarkMode ? 8 : 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 14, color: accentColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _titleController,
                                maxLines: 1,
                                textInputAction: TextInputAction.next,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: colors.onSurface,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: accentColor, width: 1.5),
                                  ),
                                  hintText: S.of(context).recipeTitleHint,
                                  hintStyle: TextStyle(
                                    fontSize: 14,
                                    color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: panelColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDarkMode ? 0.28 : 0.07),
                              blurRadius: isDarkMode ? 8 : 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.schedule, size: 14, color: accentColor),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 70,
                              height: 34,
                              child: TextField(
                                controller: _cookingMinutesController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: colors.onSurface),
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: accentColor, width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                  suffixText: S.of(context).minSuffix,
                                  suffixStyle: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Icon(Icons.restaurant_outlined, size: 14, color: accentColor),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 78,
                              height: 34,
                              child: TextField(
                                controller: _servingsController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: colors.onSurface),
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: accentColor, width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                  suffixText: S.of(context).servingsSuffix,
                                  suffixStyle: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    _RecipeDetailSectionCard(
                      title: S.of(context).ingredientsLabel,
                      icon: Icons.shopping_basket_outlined,
                      backgroundColor: panelColor,
                      iconColor: accentColor,
                      children: _isEditMode
                          ? _buildIngredientEditList(
                              accentColor: accentColor,
                              colors: colors,
                            )
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
                    if (!_isEditMode && widget.recipe.nutrition != null) ...[
                      const SizedBox(height: 10),
                      _RecipeDetailSectionCard(
                        title: S.of(context).nutritionLabel,
                        icon: Icons.monitor_heart_outlined,
                        backgroundColor: panelColor,
                        iconColor: accentColor,
                        children: [_buildNutritionBlock(colors, accentColor)],
                      ),
                    ],
                    const SizedBox(height: 10),
                    _RecipeDetailSectionCard(
                      title: S.of(context).instructionsLabel,
                      icon: Icons.format_list_numbered,
                      backgroundColor: panelColor,
                      iconColor: accentColor,
                      children: _isEditMode
                          ? _buildStepEditList(
                              accentColor: accentColor,
                              colors: colors,
                              isDarkMode: isDarkMode,
                            )
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
                                            color: accentColor.withValues(
                                              alpha: isDarkMode ? 0.18 : 0.1,
                                            ),
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
                    if (_isEditMode) ...[
                      const SizedBox(height: 10),
                      _RecipeDetailSectionCard(
                        title: S.of(context).labelsLabel,
                        icon: Icons.sell_outlined,
                        backgroundColor: panelColor,
                        iconColor: accentColor,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _availableLabels.map((label) {
                              final isSelected = _selectedEditLabels
                                  .contains(label);
                              return FilterChip(
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: isDarkMode
                                    ? const Color(0xFF1E1E1E)
                                    : Colors.white,
                                side: isDarkMode
                                    ? BorderSide.none
                                    : BorderSide(color: borderColor),
                                selectedColor: accentColor,
                                checkmarkColor: Colors.white,
                                selected: isSelected,
                                label: Text(
                                  S.of(context).dietaryTagDisplay(label),
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
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      if (!_isEditMode)
        Positioned(
          top: 10,
          left: 12,
          child: GestureDetector(
            onTap: widget.onBack,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: hasImage
                    ? Colors.black.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 17,
                color: Colors.white,
              ),
            ),
          ),
        ),
    ],
  ),
),
          if (!_isCookingMode)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: widget.enableEdit
                ? Row(
                    children: [
                      if (widget.onDelete != null && !_isEditMode) ...[
                        OutlinedButton(
                          onPressed: widget.onDelete,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            backgroundColor: panelColor,
                            foregroundColor: const Color(0xFFDC2626),
                            side: isDarkMode
                                ? BorderSide.none
                                : const BorderSide(color: Color(0xFFFCA5A5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(S.of(context).delete),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (_isEditMode) ...[
                        Expanded(
                          flex: 2,
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _isEditMode = false;
                                _titleController.text = widget.recipe.name;
                                _selectedEditLabels = widget.recipe.labels.toSet();
                                _editImageBytes = null;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: panelColor,
                              foregroundColor: colors.onSurface,
                              side: isDarkMode ? BorderSide.none : BorderSide(color: borderColor),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            ),
                            child: Text(S.of(context).cancel),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: FilledButton(
                            onPressed: _saveEditedRecipe,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(40),
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            ),
                            child: Text(S.of(context).saveChanges),
                          ),
                        ),
                      ] else
                        Expanded(
                          child: FilledButton(
                            onPressed: () => setState(() => _isEditMode = true),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(40),
                              backgroundColor: widget.cardColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            ),
                            child: Text(S.of(context).edit),
                          ),
                        ),
                    ],
                  )
                : OutlinedButton.icon(
                    onPressed: widget.onToggleSave,
                    icon: Icon(
                      (isSaved == true) ? Icons.favorite : Icons.favorite_border,
                      size: 15,
                      color: (isSaved == true) ? const Color(0xFFDC2626) : saveColor,
                    ),
                    label: Text((isSaved == true) ? S.of(context).saved : S.of(context).save),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      backgroundColor: panelColor,
                      foregroundColor: saveColor,
                      side: isDarkMode
                          ? BorderSide.none
                          : BorderSide(
                              color: (isSaved == true) ? const Color(0xFFFCA5A5) : borderColor,
                            ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
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
              Builder(builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Container(
                  width: 190,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 36)),
                      const SizedBox(height: 8),
                      Text(
                        S.of(context).completed,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        S.of(context).greatJobChef,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailHeaderInfo extends StatelessWidget {
  const _DetailHeaderInfo({required this.recipe});

  final RecipeDetailData recipe;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          recipe.name,
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
        if (recipe.isPrivate) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded, size: 11, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Private',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
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
              S.of(context).cookingMinutesDisplay(recipe.cookingMinutes),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 10),
            if (recipe.calories != null) ...[
              const Icon(
                Icons.local_fire_department_outlined,
                size: 11,
                color: Colors.white70,
              ),
              const SizedBox(width: 3),
              Text(
                '${recipe.calories} ${S.of(context).calSuffix}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        if (recipe.labels.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 5,
            runSpacing: 4,
            children: recipe.labels
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      S.of(context).dietaryTagDisplay(tag),
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
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

const _kCardPalette = [
  (Color(0xFF10B981), Color(0xFF059669)),
  (Color(0xFFF59E0B), Color(0xFFD97706)),
  (Color(0xFF3B82F6), Color(0xFF2563EB)),
  (Color(0xFFF97316), Color(0xFFEA580C)),
  (Color(0xFF8B5CF6), Color(0xFF7C3AED)),
  (Color(0xFF14B8A6), Color(0xFF0D9488)),
  (Color(0xFF06B6D4), Color(0xFF0891B2)),
  (Color(0xFFF43F5E), Color(0xFFE11D48)),
  (Color(0xFF6366F1), Color(0xFF4F46E5)),
  (Color(0xFFEC4899), Color(0xFFDB2777)),
];

/// Public: used by recipe cards AND detail view to keep colors consistent.
({String emoji, Color start, Color end}) recipeCardTheme(int id, List<String> labels) {
  final (start, end) = _kCardPalette[id.abs() % _kCardPalette.length];
  return (emoji: _recipeEmoji(labels), start: start, end: end);
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.07),
            blurRadius: isDarkMode ? 8 : 10,
            offset: const Offset(0, 3),
          ),
        ],
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
