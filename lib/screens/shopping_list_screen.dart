import 'dart:async';

import 'package:flutter/material.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';
import 'package:foodhub_mobile/models/meal.dart';
import 'package:foodhub_mobile/services/api_exception.dart';
import 'package:foodhub_mobile/services/meal_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key, this.date});

  final String? date;

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  static const _checkedPrefix = 'shopping_checked_';

  final _mealService = MealService();
  ShoppingListModel? _list;
  bool _loading = true;
  String? _error;
  final Set<String> _checked = {};
  final Set<String> _expanded = {};
  Timer? _poll;

  String get _date => widget.date ?? localIsoDate();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _loadChecked() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('$_checkedPrefix$_date') ?? const [];
    if (!mounted) return;
    setState(() {
      _checked
        ..clear()
        ..addAll(stored);
    });
  }

  Future<void> _saveChecked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('$_checkedPrefix$_date', _checked.toList());
  }

  bool _pruneChecked(ShoppingListModel list) {
    if (list.isPending) return false;
    final known = {
      for (final group in list.groups)
        for (final item in group.items) item.key,
    };
    if (known.isEmpty) return false;
    final before = _checked.length;
    _checked.removeWhere((key) => !known.contains(key));
    return _checked.length != before;
  }

  void _toggleChecked(String key) {
    setState(() {
      if (_checked.contains(key)) {
        _checked.remove(key);
      } else {
        _checked.add(key);
        _expanded.remove(key);
      }
    });
    _saveChecked();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      await _loadChecked();
      final list = await _mealService.getShoppingList(date: _date);
      if (!mounted) return;
      var pruned = false;
      setState(() {
        _list = list;
        _loading = false;
        _error = null;
        pruned = _pruneChecked(list);
      });
      if (pruned) _saveChecked();
      _syncPoll(list);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
      _poll?.cancel();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = S.of(context).unableToLoadShoppingList;
        _loading = false;
      });
      _poll?.cancel();
    }
  }

  void _syncPoll(ShoppingListModel list) {
    _poll?.cancel();
    if (!list.isPending) return;
    _poll = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final next = await _mealService.getShoppingList(date: _date);
        if (!mounted) return;
        var pruned = false;
        setState(() {
          _list = next;
          pruned = _pruneChecked(next);
        });
        if (pruned) _saveChecked();
        if (!next.isPending) _poll?.cancel();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = Theme.of(context).colorScheme;
    final list = _list;
    final pending = list?.isPending == true;

    final uncheckedGroups = <ShoppingListGroupModel>[];
    final purchased = <ShoppingListItemModel>[];
    for (final group in list?.groups ?? const <ShoppingListGroupModel>[]) {
      final openItems = [
        for (final item in group.items)
          if (!_checked.contains(item.key)) item,
      ];
      for (final item in group.items) {
        if (_checked.contains(item.key)) purchased.add(item);
      }
      if (openItems.isNotEmpty) {
        uncheckedGroups.add(
          ShoppingListGroupModel(
            aisleKey: group.aisleKey,
            aisle: group.aisle,
            items: openItems,
          ),
        );
      }
    }
    purchased.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final isEmpty = (list == null || list.groups.every((g) => g.items.isEmpty)) &&
        !pending;

    return Scaffold(
      appBar: AppBar(title: Text(s.shoppingList)),
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
                      OutlinedButton(onPressed: _load, child: Text(s.retry)),
                    ],
                  ),
                )
              : pending && (list?.groups.isEmpty ?? true)
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFF059669),
                          ),
                          const SizedBox(height: 16),
                          Text(s.organizingShoppingList),
                        ],
                      ),
                    )
                  : isEmpty
                      ? Center(child: Text(s.emptyShoppingList))
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                          children: [
                            if (pending)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF059669),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(s.organizingShoppingList),
                                  ],
                                ),
                              ),
                            for (final group in uncheckedGroups) ...[
                              Padding(
                                padding: const EdgeInsets.only(top: 8, bottom: 4),
                                child: Text(
                                  group.aisle.isNotEmpty
                                      ? group.aisle
                                      : group.aisleKey,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: colors.primary,
                                  ),
                                ),
                              ),
                              for (final item in group.items)
                                _ShoppingRow(
                                  item: item,
                                  checked: false,
                                  expanded: _expanded.contains(item.key),
                                  onToggleChecked: () => _toggleChecked(item.key),
                                  onToggleExpanded: () {
                                    setState(() {
                                      if (_expanded.contains(item.key)) {
                                        _expanded.remove(item.key);
                                      } else {
                                        _expanded.add(item.key);
                                      }
                                    });
                                  },
                                  servingsLabel: s.plannedServings,
                                ),
                            ],
                            if (purchased.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                s.purchasedItems,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: colors.outline,
                                ),
                              ),
                              for (final item in purchased)
                                _ShoppingRow(
                                  item: item,
                                  checked: true,
                                  expanded: _expanded.contains(item.key),
                                  onToggleChecked: () => _toggleChecked(item.key),
                                  onToggleExpanded: () {
                                    setState(() {
                                      if (_expanded.contains(item.key)) {
                                        _expanded.remove(item.key);
                                      } else {
                                        _expanded.add(item.key);
                                      }
                                    });
                                  },
                                  servingsLabel: s.plannedServings,
                                ),
                            ],
                          ],
                        ),
    );
  }
}

class _ShoppingRow extends StatelessWidget {
  const _ShoppingRow({
    required this.item,
    required this.checked,
    required this.expanded,
    required this.onToggleChecked,
    required this.onToggleExpanded,
    required this.servingsLabel,
  });

  final ShoppingListItemModel item;
  final bool checked;
  final bool expanded;
  final VoidCallback onToggleChecked;
  final VoidCallback onToggleExpanded;
  final String Function(double) servingsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dim = checked ? 0.45 : 1.0;
    return Opacity(
      opacity: dim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: checked,
                activeColor: const Color(0xFF059669),
                onChanged: (_) => onToggleChecked(),
              ),
              Expanded(
                child: InkWell(
                  onTap: onToggleExpanded,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      item.displayLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        decoration:
                            checked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: onToggleExpanded,
                icon: Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: colors.outline,
                ),
              ),
            ],
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.only(left: 52, right: 8, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final source in item.sources)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        [
                          if (source.recipeTitle.isNotEmpty) source.recipeTitle,
                          servingsLabel(source.servings),
                          if (source.line.isNotEmpty) source.line,
                        ].join(' · '),
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          height: 1.3,
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
