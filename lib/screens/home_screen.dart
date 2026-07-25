import 'package:flutter/material.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';
import 'package:foodhub_mobile/models/recipe.dart';
import 'package:foodhub_mobile/services/api_exception.dart';
import 'package:foodhub_mobile/services/recipe_service.dart';
import 'package:foodhub_mobile/services/session_service.dart';
import 'package:foodhub_mobile/widgets/favorite_toast.dart';
import 'package:foodhub_mobile/widgets/recipe_card.dart';
import 'package:foodhub_mobile/widgets/recipe_detail_view.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onDetailModeChanged});

  final ValueChanged<bool>? onDetailModeChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _recipeService = RecipeService();
  final List<RecipeModel> _recipes = [];
  bool _isLoading = true;
  String? _loadError;

  bool _isAddingRecipe = false;
  RecipeModel? _selectedRecipe;
  int? _selectedRecipeCardIndex;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final userId = SessionService.instance.currentUser?.id;
      final all = await _recipeService.listRecipes();
      if (!mounted) return;
      setState(() {
        _recipes
          ..clear()
          ..addAll(
            userId == null
                ? all
                : all.where((r) => r.createdBy == userId),
          );
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = S.of(context).unableToLoadRecipes;
        _isLoading = false;
      });
    }
  }

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

  void _onSaveRecipe(RecipeModel recipe) {
    setState(() {
      _recipes.add(recipe);
      _isAddingRecipe = false;
    });
  }

  void _openRecipeDetails(RecipeModel recipe, int cardIndex) {
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

  String _greeting(BuildContext context) {
    final s = S.of(context);
    final h = DateTime.now().hour;
    if (h < 12) return s.goodMorning;
    if (h < 17) return s.goodAfternoon;
    return s.goodEvening;
  }

  Future<void> _onSaveEditedRecipe(RecipeDetailData data) async {
    final index = _selectedRecipeCardIndex;
    final current = _selectedRecipe;
    if (index == null ||
        current == null ||
        index < 0 ||
        index >= _recipes.length) {
      return;
    }

    try {
      final updated = await _recipeService.updateRecipe(
        current.id,
        ingredients: RecipeModel.splitLines(data.ingredients),
        directions: RecipeModel.splitLines(data.steps),
        dietaryRestrictions: data.labels,
      );
      if (!mounted) return;
      setState(() {
        _recipes[index] = updated;
        _selectedRecipe = updated;
      });
      showRecipeToast(context, recipeName: updated.name, isNew: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorToast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedRecipe != null && _selectedRecipeCardIndex != null) {
      return RecipeDetailView(
        recipe: _selectedRecipe!.toDetailData(),
        cardColor: recipeCardTheme(_selectedRecipe!.id, _selectedRecipe!.labels).start,
        onBack: _closeRecipeDetails,
        enableEdit: true,
        onSaveEdited: (data) => _onSaveEditedRecipe(data),
      );
    }

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF059669)),
        ),
      );
    }

    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_loadError!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loadRecipes, child: Text(S.of(context).retry)),
          ],
        ),
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
                              _greeting(context),
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              S.of(context).myRecipes,
                              style: const TextStyle(
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
                                S.of(context).recipeCount(_recipes.length),
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
                            return RecipeCard(
                              recipe: recipe,
                              onAction: () => _openRecipeDetails(recipe, index),
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
    final s = S.of(context);

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
            s.noRecipesYet,
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s.noRecipesDesc,
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
            label: Text(s.addFirstRecipe),
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

class _AddRecipePanel extends StatefulWidget {
  const _AddRecipePanel({required this.onCancel, required this.onSave});

  final VoidCallback onCancel;
  final ValueChanged<RecipeModel> onSave;

  @override
  State<_AddRecipePanel> createState() => _AddRecipePanelState();
}

class _AddRecipePanelState extends State<_AddRecipePanel> {
  final _recipeService = RecipeService();
  final _nameController = TextEditingController();
  final _cookingMinutesController = TextEditingController();
  final _caloriesController = TextEditingController();
  final List<TextEditingController> _ingredientControllers = [
    TextEditingController(),
  ];
  final List<TextEditingController> _stepControllers = [
    TextEditingController(),
  ];
  final Set<String> _selectedLabels = {};
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _ingredientControllers) {
      c.dispose();
    }
    for (final c in _stepControllers) {
      c.dispose();
    }
    _cookingMinutesController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    final ingredients = _ingredientControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .join('\n');
    final steps = _stepControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .join('\n');
    final cookingMinutes = int.tryParse(_cookingMinutesController.text.trim());
    final calories = int.tryParse(_caloriesController.text.trim());

    if (name.isEmpty ||
        ingredients.isEmpty ||
        steps.isEmpty ||
        cookingMinutes == null ||
        calories == null ||
        cookingMinutes <= 0 ||
        calories <= 0) {
      showErrorToast(context, S.of(context).fillAllFields);
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

    try {
      final created = await _recipeService.createRecipe(
        title: name,
        ingredients: RecipeModel.splitLines(ingredients),
        directions: RecipeModel.splitLines(steps),
        dietaryRestrictions: _selectedLabels.toList(),
        estimatedServings: (calories / 200).round().clamp(1, 12),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      showRecipeToast(context, recipeName: name, isNew: true);
      widget.onSave(created);
    } on ApiException catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      showErrorToast(context, e.message);
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      showErrorToast(context, S.of(context).unableToSaveRecipe);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);
    final cardBg = isDarkMode ? const Color(0xFF141414) : Colors.white;
    final panelColor = isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF8FAFC);
    final dividerColor = isDarkMode ? const Color(0xFF2A2A2A) : colors.outlineVariant;
    final hintColor = isDarkMode ? const Color(0xFF64748B) : const Color(0xFF9CA3AF);
    final textColor = isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF111827);
    const accentColor = Color(0xFF059669);

    InputDecoration inlineFieldDecoration({String? hint, String? suffix}) =>
        InputDecoration(
          hintText: hint,
          suffixText: suffix,
          hintStyle: TextStyle(color: hintColor, fontSize: 13),
          isDense: true,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: accentColor, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
        );

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.45 : 0.08),
            blurRadius: isDarkMode ? 20 : 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_circle_outline, size: 16, color: accentColor),
                ),
                const SizedBox(width: 10),
                Text(
                  s.newRecipeTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onCancel,
                  icon: Icon(Icons.close_rounded, size: 18, color: colors.onSurfaceVariant),
                  style: IconButton.styleFrom(
                    backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF3F4F6),
                    minimumSize: const Size(32, 32),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: dividerColor),

          // ── Body ────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe name
                  _AddSectionCard(
                    isDarkMode: isDarkMode,
                    panelColor: panelColor,
                    child: TextField(
                      controller: _nameController,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        letterSpacing: -0.3,
                      ),
                      decoration: InputDecoration(
                        hintText: s.recipeNameHint,
                        hintStyle: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: hintColor,
                          letterSpacing: -0.3,
                        ),
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Time + Calories
                  _AddSectionCard(
                    isDarkMode: isDarkMode,
                    panelColor: panelColor,
                    child: Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 16, color: accentColor),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 56,
                          child: TextField(
                            controller: _cookingMinutesController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(fontSize: 13, color: textColor),
                            decoration: inlineFieldDecoration(hint: '0'),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(s.minSuffix, style: TextStyle(fontSize: 12, color: hintColor)),
                        const SizedBox(width: 20),
                        const Icon(Icons.local_fire_department_outlined, size: 16, color: accentColor),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 56,
                          child: TextField(
                            controller: _caloriesController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(fontSize: 13, color: textColor),
                            decoration: inlineFieldDecoration(hint: '0'),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(s.calSuffix, style: TextStyle(fontSize: 12, color: hintColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Ingredients
                  _AddSectionCard(
                    isDarkMode: isDarkMode,
                    panelColor: panelColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shopping_basket_outlined, size: 15, color: accentColor),
                            const SizedBox(width: 6),
                            Text(
                              s.ingredientsLabel,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._ingredientControllers.asMap().entries.map((entry) {
                          final i = entry.key;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: entry.value,
                                    maxLines: 1,
                                    textInputAction: TextInputAction.next,
                                    style: TextStyle(fontSize: 13, color: textColor),
                                    decoration: inlineFieldDecoration(hint: s.ingredientHint(i)),
                                  ),
                                ),
                                if (_ingredientControllers.length > 1) ...[
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => setState(() {
                                      _ingredientControllers[i].dispose();
                                      _ingredientControllers.removeAt(i);
                                    }),
                                    child: Icon(Icons.close_rounded, size: 16, color: colors.onSurfaceVariant),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                        TextButton.icon(
                          onPressed: () => setState(() => _ingredientControllers.add(TextEditingController())),
                          icon: const Icon(Icons.add, size: 14),
                          label: Text(s.addIngredient),
                          style: TextButton.styleFrom(
                            foregroundColor: accentColor,
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Steps
                  _AddSectionCard(
                    isDarkMode: isDarkMode,
                    panelColor: panelColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.format_list_numbered, size: 15, color: accentColor),
                            const SizedBox(width: 6),
                            Text(
                              s.instructionsLabel,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
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
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: accentColor,
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
                                    style: TextStyle(fontSize: 13, color: textColor),
                                    decoration: inlineFieldDecoration(hint: s.stepHint(i)),
                                  ),
                                ),
                                if (_stepControllers.length > 1) ...[
                                  const SizedBox(width: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _stepControllers[i].dispose();
                                        _stepControllers.removeAt(i);
                                      }),
                                      child: Icon(Icons.close_rounded, size: 16, color: colors.onSurfaceVariant),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                        TextButton.icon(
                          onPressed: () => setState(() => _stepControllers.add(TextEditingController())),
                          icon: const Icon(Icons.add, size: 14),
                          label: Text(s.addStep),
                          style: TextButton.styleFrom(
                            foregroundColor: accentColor,
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Labels
                  _AddSectionCard(
                    isDarkMode: isDarkMode,
                    panelColor: panelColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.sell_outlined, size: 15, color: accentColor),
                            const SizedBox(width: 6),
                            Text(
                              s.labelsLabel,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: kAvailableLabels.map((label) {
                            final isSelected = _selectedLabels.contains(label);
                            return FilterChip(
                              selected: isSelected,
                              selectedColor: accentColor,
                              checkmarkColor: Colors.white,
                              backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                              side: BorderSide.none,
                              label: Text(
                                s.dietaryTagDisplay(label),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isSelected ? Colors.white : colors.onSurfaceVariant,
                                ),
                              ),
                              onSelected: (selected) => setState(() {
                                selected ? _selectedLabels.add(label) : _selectedLabels.remove(label);
                              }),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Actions ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      foregroundColor: colors.onSurface,
                      side: BorderSide.none,
                      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(s.cancel, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(s.saveRecipe, style: const TextStyle(fontWeight: FontWeight.w700)),
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

class _AddSectionCard extends StatelessWidget {
  const _AddSectionCard({
    required this.isDarkMode,
    required this.panelColor,
    required this.child,
  });

  final bool isDarkMode;
  final Color panelColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.28 : 0.06),
            blurRadius: isDarkMode ? 8 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
