import 'package:flutter/material.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';
import 'package:foodhub_mobile/models/meal.dart';
import 'package:foodhub_mobile/models/recipe.dart';
import 'package:foodhub_mobile/screens/search_screen.dart';
import 'package:foodhub_mobile/screens/shopping_list_screen.dart';
import 'package:foodhub_mobile/services/api_exception.dart';
import 'package:foodhub_mobile/services/meal_service.dart';
import 'package:foodhub_mobile/widgets/recipe_image.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({
    super.key,
    this.initialSuggestions,
  });

  final MealSuggestionModel? initialSuggestions;

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final _mealService = MealService();
  MealPlanModel? _plan;
  bool _loading = true;
  String? _error;

  String get _date => localIsoDate();

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
                MealPlanItemModel(
                  id: 0,
                  recipeId: recipe.id,
                  servings: 1,
                ),
              ])
            : current,
    ];
    await _save(MealPlanModel(id: plan.id, planDate: plan.planDate, slots: slots));
  }

  Future<void> _pickFromSearch(MealSlotModel slot) async {
    final recipe = await Navigator.of(context).push<RecipeModel>(
      MaterialPageRoute(
        builder: (_) => const SearchScreen(pickMode: true),
      ),
    );
    if (recipe != null) await _addRecipe(slot, recipe);
  }

  Future<void> _pickFromSuggestions(MealSlotModel slot) async {
    final suggestions = widget.initialSuggestions;
    final recipes = [
      ...?suggestions?.breakfast,
      ...?suggestions?.lunch,
      ...?suggestions?.dinner,
    ];
    if (recipes.isEmpty) {
      await _pickFromSearch(slot);
      return;
    }
    final selected = await showModalBottomSheet<RecipeModel>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final s = S.of(ctx);
        return ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.search),
              title: Text(s.addFromSearch),
              onTap: () => Navigator.pop(ctx),
            ),
            for (final recipe in recipes)
              ListTile(
                title: Text(recipe.title),
                onTap: () => Navigator.pop(ctx, recipe),
              ),
          ],
        );
      },
    );
    if (!mounted) return;
    if (selected == null) {
      await _pickFromSearch(slot);
      return;
    }
    await _addRecipe(slot, selected);
  }

  Future<void> _addExtraSlot() async {
    final s = S.of(context);
    final controller = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
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
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.todaysMealPlan),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ShoppingListScreen(date: _date),
                ),
              );
            },
            child: Text(s.shoppingList),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExtraSlot,
        icon: const Icon(Icons.add),
        label: Text(s.addExtraMeal),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF059669)),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 8),
                      OutlinedButton(onPressed: _load, child: Text(s.retry)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                  children: [
                    for (final slot in _plan?.slots ?? [])
                      _PlanSlotCard(
                        slot: slot,
                        onAdd: () => _pickFromSuggestions(slot),
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
                          await _save(
                            MealPlanModel(
                              id: plan.id,
                              planDate: plan.planDate,
                              slots: slots,
                            ),
                          );
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
                          await _save(
                            MealPlanModel(
                              id: plan.id,
                              planDate: plan.planDate,
                              slots: slots,
                            ),
                          );
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
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _PlanSlotCard extends StatelessWidget {
  const _PlanSlotCard({
    required this.slot,
    required this.onAdd,
    required this.onRemoveItem,
    required this.onServings,
    this.onDeleteSlot,
  });

  final MealSlotModel slot;
  final VoidCallback onAdd;
  final ValueChanged<MealPlanItemModel> onRemoveItem;
  final void Function(MealPlanItemModel item, double servings) onServings;
  final VoidCallback? onDeleteSlot;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    slot.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                if (onDeleteSlot != null)
                  IconButton(
                    onPressed: onDeleteSlot,
                    icon: const Icon(Icons.delete_outline),
                  ),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(s.addDish),
                ),
              ],
            ),
            if (slot.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  s.emptyMealSlot,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              )
            else
              for (final item in slot.items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: SizedBox(
                    width: 48,
                    height: 48,
                    child: RecipeImageHeader(
                      imageUrl: item.recipe?.imageUrl,
                      recipeId: item.recipeId,
                      labels: item.recipe?.labels ?? const [],
                      height: 48,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  title: Text(item.recipe?.title ?? '#${item.recipeId}'),
                  subtitle: Row(
                    children: [
                      IconButton(
                        onPressed: item.servings > 1
                            ? () => onServings(item, item.servings - 1)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline, size: 18),
                      ),
                      Text('${item.servings.toStringAsFixed(0)} ${s.servingsSuffix}'),
                      IconButton(
                        onPressed: () => onServings(item, item.servings + 1),
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    onPressed: () => onRemoveItem(item),
                    icon: const Icon(Icons.close),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
