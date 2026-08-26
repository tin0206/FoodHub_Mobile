import 'package:flutter/material.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';
import 'package:foodhub_mobile/models/meal.dart';
import 'package:foodhub_mobile/models/recipe.dart';
import 'package:foodhub_mobile/screens/search_screen.dart';
import 'package:foodhub_mobile/screens/shopping_list_screen.dart';
import 'package:foodhub_mobile/services/api_exception.dart';
import 'package:foodhub_mobile/services/meal_service.dart';
import 'package:foodhub_mobile/widgets/app_top_bar.dart';
import 'package:foodhub_mobile/widgets/recipe_detail_view.dart';
import 'package:foodhub_mobile/widgets/recipe_image.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final _mealService = MealService();
  MealPlanModel? _plan;
  bool _loading = true;
  String? _error;
  MealPlanItemModel? _selectedItem;

  String get _date => localIsoDate();

  void _openRecipeDetail(MealPlanItemModel item) {
    if (item.recipe == null) return;
    setState(() => _selectedItem = item);
  }

  void _closeRecipeDetail() {
    setState(() => _selectedItem = null);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plan = await _mealService.getPlan(date: _date);
      if (!mounted) return;
      setState(() {
        _plan = plan;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = S.of(context).unableToLoadMealPlan;
        _loading = false;
      });
    }
  }

  Future<void> _save(MealPlanModel plan) async {
    final updated = await _mealService.replacePlan(plan, date: _date);
    if (!mounted) return;
    setState(() => _plan = updated);
  }

  Future<void> _addRecipe(MealSlotModel slot, RecipeModel recipe) async {
    final plan = _plan;
    if (plan == null) return;
    final slots = [
      for (final current in plan.slots)
        current.slotKey == slot.slotKey
            ? current.withItems([
                ...current.items,
                MealPlanItemModel(id: 0, recipeId: recipe.id, servings: 1),
              ])
            : current,
    ];
    await _save(MealPlanModel(id: plan.id, planDate: plan.planDate, slots: slots));
  }

  Future<void> _pickFromSearch(MealSlotModel slot) async {
    final recipe = await Navigator.of(context).push<RecipeModel>(
      MaterialPageRoute(builder: (_) => const SearchScreen(pickMode: true)),
    );
    if (recipe != null) await _addRecipe(slot, recipe);
  }

  Future<void> _addExtraSlot() async {
    final s = S.of(context);
    final controller = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(s.addExtraMeal),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: s.extraMealHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(s.save),
          ),
        ],
      ),
    );
    if (label == null || label.isEmpty) return;
    final plan = await _mealService.addExtraSlot(label: label, date: _date);
    if (!mounted) return;
    setState(() => _plan = plan);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenBg = isDarkMode ? const Color(0xFF0A0A0A) : const Color(0xFFE5E7EB);
    final cardBg = isDarkMode ? const Color(0xFF141414) : Colors.white;
    final cardBorder = isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);
    final secondaryText = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final topPadding = MediaQuery.of(context).padding.top;

    if (_selectedItem != null) {
      final recipe = _selectedItem!.recipe!;
      final theme = recipeCardTheme(recipe.id, recipe.labels);
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _closeRecipeDetail();
        },
        child: Scaffold(
          body: Column(
            children: [
              AppTopBar(onOpenProfile: () {}),
              Expanded(
                child: RecipeDetailView(
                  recipe: recipe.toDetailData(),
                  cardColor: theme.start,
                  onBack: _closeRecipeDetail,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: screenBg,
      body: Column(
        children: [
          // ── Gradient header ─────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF059669), Color(0xFF047857)],
              ),
            ),
            padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.todaysMealPlan,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        _date,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ShoppingListScreen(date: _date),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          s.shoppingList,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF059669)),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: secondaryText),
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: TextStyle(color: secondaryText),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _load,
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(s.retry),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        children: [
                          for (final slot in _plan?.slots ?? [])
                            _PlanSlotCard(
                              slot: slot,
                              isDarkMode: isDarkMode,
                              cardBg: cardBg,
                              cardBorder: cardBorder,
                              secondaryText: secondaryText,
                              onAdd: () => _pickFromSearch(slot),
                              onViewDetail: _openRecipeDetail,
                              onRemoveItem: (item) async {
                                final plan = _plan!;
                                final slots = [
                                  for (final current in plan.slots)
                                    current.id == slot.id
                                        ? current.withItems(
                                            current.items
                                                .where((it) => it.id != item.id)
                                                .toList(),
                                          )
                                        : current,
                                ];
                                await _save(MealPlanModel(
                                  id: plan.id,
                                  planDate: plan.planDate,
                                  slots: slots,
                                ));
                              },
                              onServings: (item, servings) async {
                                final plan = _plan!;
                                final slots = [
                                  for (final current in plan.slots)
                                    current.id == slot.id
                                        ? current.withItems([
                                            for (final it in current.items)
                                              it.id == item.id
                                                  ? MealPlanItemModel(
                                                      id: it.id,
                                                      recipeId: it.recipeId,
                                                      servings: servings,
                                                      recipe: it.recipe,
                                                    )
                                                  : it,
                                          ])
                                        : current,
                                ];
                                await _save(MealPlanModel(
                                  id: plan.id,
                                  planDate: plan.planDate,
                                  slots: slots,
                                ));
                              },
                              onDeleteSlot: slot.isMain
                                  ? null
                                  : () async {
                                      final plan = await _mealService.deleteSlot(
                                        slotId: slot.id,
                                        date: _date,
                                      );
                                      if (!mounted) return;
                                      setState(() => _plan = plan);
                                    },
                            ),
                          const SizedBox(height: 8),
                          Text(
                            s.mealPlanHint,
                            style: TextStyle(fontSize: 12, color: secondaryText),
                          ),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExtraSlot,
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(s.addExtraMeal),
      ),
    );
  }
}

// ── Slot card ─────────────────────────────────────────────────────────────────

class _PlanSlotCard extends StatelessWidget {
  const _PlanSlotCard({
    required this.slot,
    required this.isDarkMode,
    required this.cardBg,
    required this.cardBorder,
    required this.secondaryText,
    required this.onAdd,
    required this.onRemoveItem,
    required this.onServings,
    required this.onViewDetail,
    this.onDeleteSlot,
  });

  final MealSlotModel slot;
  final bool isDarkMode;
  final Color cardBg;
  final Color cardBorder;
  final Color secondaryText;
  final VoidCallback onAdd;
  final ValueChanged<MealPlanItemModel> onRemoveItem;
  final void Function(MealPlanItemModel item, double servings) onServings;
  final ValueChanged<MealPlanItemModel> onViewDetail;
  final VoidCallback? onDeleteSlot;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Slot header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: isDarkMode ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    size: 17,
                    color: Color(0xFF059669),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    slot.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                if (onDeleteSlot != null)
                  IconButton(
                    onPressed: onDeleteSlot,
                    icon: Icon(Icons.delete_outline, size: 20, color: secondaryText),
                    visualDensity: VisualDensity.compact,
                  ),
                TextButton.icon(
                  onPressed: onAdd,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF059669),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(s.addDish, style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // ── Divider ───────────────────────────────────────────────────
          Divider(height: 1, color: cardBorder),

          // ── Items ──────────────────────────────────────────────────────
          if (slot.items.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline, size: 18, color: secondaryText),
                  const SizedBox(width: 8),
                  Text(
                    s.emptyMealSlot,
                    style: TextStyle(color: secondaryText, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (final item in slot.items)
                    _MealItem(
                      item: item,
                      isDarkMode: isDarkMode,
                      secondaryText: secondaryText,
                      cardBorder: cardBorder,
                      onRemove: () => onRemoveItem(item),
                      onDecrease: item.servings > 1
                          ? () => onServings(item, item.servings - 1)
                          : null,
                      onIncrease: () => onServings(item, item.servings + 1),
                      onViewDetail: item.recipe != null
                          ? () => onViewDetail(item)
                          : null,
                      servingsSuffix: s.servingsSuffix,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MealItem extends StatelessWidget {
  const _MealItem({
    required this.item,
    required this.isDarkMode,
    required this.secondaryText,
    required this.cardBorder,
    required this.onRemove,
    required this.onIncrease,
    required this.servingsSuffix,
    this.onDecrease,
    this.onViewDetail,
  });

  final MealPlanItemModel item;
  final bool isDarkMode;
  final Color secondaryText;
  final Color cardBorder;
  final VoidCallback onRemove;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback? onViewDetail;
  final String servingsSuffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: onViewDetail,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: RecipeImageHeader(
                      imageUrl: item.recipe?.imageUrl,
                      recipeId: item.recipeId,
                      labels: item.recipe?.labels ?? const [],
                      height: 52,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: onViewDetail,
                      child: Text(
                        item.recipe?.title ?? '#${item.recipeId}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _ServingButton(
                          icon: Icons.remove_rounded,
                          onTap: onDecrease,
                          secondaryText: secondaryText,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '${item.servings.toStringAsFixed(0)} $servingsSuffix',
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        _ServingButton(
                          icon: Icons.add_rounded,
                          onTap: onIncrease,
                          secondaryText: secondaryText,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: Icon(Icons.close_rounded, size: 18, color: secondaryText),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        Divider(height: 1, indent: 78, color: cardBorder),
      ],
    );
  }
}

class _ServingButton extends StatelessWidget {
  const _ServingButton({
    required this.icon,
    required this.secondaryText,
    this.onTap,
  });

  final IconData icon;
  final Color secondaryText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFF059669).withValues(alpha: 0.12)
              : secondaryText.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 14,
          color: enabled ? const Color(0xFF059669) : secondaryText.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
