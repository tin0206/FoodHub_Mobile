import 'dart:async';

import 'package:flutter/material.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';
import 'package:foodhub_mobile/models/meal.dart';
import 'package:foodhub_mobile/services/api_exception.dart';
import 'package:foodhub_mobile/services/meal_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Aisle colors ────────────────────────────────────────────────────────────
// Gives every ingredient group its own accent color + icon so the list reads
// at a glance instead of one flat gray card per aisle.

class _AisleStyle {
  const _AisleStyle(this.color, this.icon);
  final Color color;
  final IconData icon;
}

const _kAisleStyles = <String, _AisleStyle>{
  'produce': _AisleStyle(Color(0xFF16A34A), Icons.eco_outlined),
  'fruit': _AisleStyle(Color(0xFF16A34A), Icons.eco_outlined),
  'vegetable': _AisleStyle(Color(0xFF16A34A), Icons.eco_outlined),
  'herb': _AisleStyle(Color(0xFF15803D), Icons.grass_outlined),
  'dairy': _AisleStyle(Color(0xFFCA8A04), Icons.egg_outlined),
  'egg': _AisleStyle(Color(0xFFCA8A04), Icons.egg_outlined),
  'meat': _AisleStyle(Color(0xFFDC2626), Icons.kebab_dining_outlined),
  'poultry': _AisleStyle(Color(0xFFDC2626), Icons.kebab_dining_outlined),
  'seafood': _AisleStyle(Color(0xFF0284C7), Icons.set_meal_outlined),
  'fish': _AisleStyle(Color(0xFF0284C7), Icons.set_meal_outlined),
  'bakery': _AisleStyle(Color(0xFFB45309), Icons.bakery_dining_outlined),
  'bread': _AisleStyle(Color(0xFFB45309), Icons.bakery_dining_outlined),
  'grain': _AisleStyle(Color(0xFFB45309), Icons.rice_bowl_outlined),
  'pasta': _AisleStyle(Color(0xFFB45309), Icons.rice_bowl_outlined),
  'pantry': _AisleStyle(Color(0xFFEA580C), Icons.kitchen_outlined),
  'spice': _AisleStyle(Color(0xFFEA580C), Icons.spa_outlined),
  'condiment': _AisleStyle(Color(0xFFEA580C), Icons.kitchen_outlined),
  'sauce': _AisleStyle(Color(0xFFEA580C), Icons.kitchen_outlined),
  'oil': _AisleStyle(Color(0xFFEA580C), Icons.kitchen_outlined),
  'canned': _AisleStyle(Color(0xFF9333EA), Icons.inventory_2_outlined),
  'frozen': _AisleStyle(Color(0xFF0891B2), Icons.ac_unit_outlined),
  'beverage': _AisleStyle(Color(0xFF7C3AED), Icons.local_cafe_outlined),
  'drink': _AisleStyle(Color(0xFF7C3AED), Icons.local_cafe_outlined),
  'snack': _AisleStyle(Color(0xFFDB2777), Icons.icecream_outlined),
  'household': _AisleStyle(Color(0xFF64748B), Icons.cleaning_services_outlined),
};

const _kAisleFallbackPalette = <_AisleStyle>[
  _AisleStyle(Color(0xFF0D9488), Icons.shopping_basket_outlined),
  _AisleStyle(Color(0xFF4F46E5), Icons.shopping_basket_outlined),
  _AisleStyle(Color(0xFFC2410C), Icons.shopping_basket_outlined),
  _AisleStyle(Color(0xFF0369A1), Icons.shopping_basket_outlined),
  _AisleStyle(Color(0xFF7C2D12), Icons.shopping_basket_outlined),
];

_AisleStyle _styleForAisle(String aisleKey) {
  final key = aisleKey.toLowerCase();
  if (key.isEmpty || key == 'other') {
    return const _AisleStyle(Color(0xFF6B7280), Icons.shopping_basket_outlined);
  }
  for (final entry in _kAisleStyles.entries) {
    if (key.contains(entry.key)) return entry.value;
  }
  final hash = key.codeUnits.fold<int>(0, (sum, c) => sum + c);
  return _kAisleFallbackPalette[hash % _kAisleFallbackPalette.length];
}

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
  final Set<String> _collapsedAisles = {};
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
    setState(() => _checked..clear()..addAll(stored));
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

  void _clearChecked() {
    setState(() => _checked.clear());
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

  int get _totalItems =>
      _list?.groups.fold(0, (sum, g) => sum! + g.items.length) ?? 0;

  int get _checkedCount =>
      _list?.groups.fold<int>(
        0,
        (sum, g) => sum + g.items.where((it) => _checked.contains(it.key)).length,
      ) ?? 0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenBg = isDarkMode ? const Color(0xFF0A0A0A) : const Color(0xFFE5E7EB);
    final cardBg = isDarkMode ? const Color(0xFF141414) : Colors.white;
    final cardBorder = isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);
    final secondaryText = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final topPadding = MediaQuery.of(context).padding.top;
    final list = _list;
    final pending = list?.isPending == true;
    final total = _totalItems;
    final checked = _checkedCount;
    final progress = total > 0 ? checked / total : 0.0;

    final isEmpty = (list == null || list.groups.every((g) => g.items.isEmpty)) && !pending;

    return Scaffold(
      backgroundColor: screenBg,
      body: Column(
        children: [
          // ── Gradient header ────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF059669), Color(0xFF047857)],
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 12),
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
                              s.shoppingList,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (!_loading && total > 0)
                              Text(
                                '$checked / $total ${s.purchasedItems.toLowerCase()}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_checked.isNotEmpty)
                        GestureDetector(
                          onTap: _clearChecked,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.remove_done_rounded, color: Colors.white, size: 15),
                                const SizedBox(width: 5),
                                Text(
                                  s.purchasedItems,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
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
                // Progress bar
                if (!_loading && total > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            backgroundColor: Colors.white.withValues(alpha: 0.25),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────
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
                    : pending && (list?.groups.isEmpty ?? true)
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(color: Color(0xFF059669)),
                                const SizedBox(height: 16),
                                Text(
                                  s.organizingShoppingList,
                                  style: TextStyle(color: secondaryText),
                                ),
                              ],
                            ),
                          )
                        : isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.checklist_rounded, size: 56, color: secondaryText),
                                    const SizedBox(height: 12),
                                    Text(
                                      s.emptyShoppingList,
                                      style: TextStyle(color: secondaryText),
                                    ),
                                  ],
                                ),
                              )
                            : ListView(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                                children: [
                                  // ── All-done banner ─────────────────────
                                  if (total > 0 && checked == total)
                                    _AllDoneBanner(label: s.allDoneBanner),
                                  if (pending)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF059669).withValues(alpha: isDarkMode ? 0.15 : 0.08),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFF059669),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            s.organizingShoppingList,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF059669),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  for (final group in list?.groups ?? <ShoppingListGroupModel>[])
                                    _AisleSection(
                                      group: group,
                                      checked: _checked,
                                      expanded: _expanded,
                                      collapsed: _collapsedAisles.contains(group.aisleKey),
                                      isDarkMode: isDarkMode,
                                      cardBg: cardBg,
                                      cardBorder: cardBorder,
                                      secondaryText: secondaryText,
                                      onToggleCollapse: () {
                                        setState(() {
                                          if (_collapsedAisles.contains(group.aisleKey)) {
                                            _collapsedAisles.remove(group.aisleKey);
                                          } else {
                                            _collapsedAisles.add(group.aisleKey);
                                          }
                                        });
                                      },
                                      onToggleChecked: _toggleChecked,
                                      onToggleExpanded: (key) {
                                        setState(() {
                                          if (_expanded.contains(key)) {
                                            _expanded.remove(key);
                                          } else {
                                            _expanded.add(key);
                                          }
                                        });
                                      },
                                      servingsLabel: s.plannedServings,
                                    ),
                                ],
                              ),
          ),
        ],
      ),
    );
  }
}

// ── All-done banner ───────────────────────────────────────────────────────────

class _AllDoneBanner extends StatelessWidget {
  const _AllDoneBanner({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6EE7B7)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF059669),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF065F46),
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Aisle section ─────────────────────────────────────────────────────────────

class _AisleSection extends StatelessWidget {
  const _AisleSection({
    required this.group,
    required this.checked,
    required this.expanded,
    required this.collapsed,
    required this.isDarkMode,
    required this.cardBg,
    required this.cardBorder,
    required this.secondaryText,
    required this.onToggleCollapse,
    required this.onToggleChecked,
    required this.onToggleExpanded,
    required this.servingsLabel,
  });

  final ShoppingListGroupModel group;
  final Set<String> checked;
  final Set<String> expanded;
  final bool collapsed;
  final bool isDarkMode;
  final Color cardBg;
  final Color cardBorder;
  final Color secondaryText;
  final VoidCallback onToggleCollapse;
  final void Function(String key) onToggleChecked;
  final void Function(String key) onToggleExpanded;
  final String Function(double) servingsLabel;

  int get _doneCount => group.items.where((it) => checked.contains(it.key)).length;

  @override
  Widget build(BuildContext context) {
    // Ingredients the server couldn't categorize (e.g. an unrecognized item
    // like "kaffir lime leaves") come back with an empty/`other` aisle, or
    // with only a raw key like "produce" — show a clean localized label
    // instead of a raw/blank key.
    final aisleLabel = group.aisle.isNotEmpty
        ? group.aisle
        : S.of(context).aisleGroupDisplay(group.aisleKey);
    final total = group.items.length;
    final done = _doneCount;
    final allDone = done == total && total > 0;
    final aisleStyle = _styleForAisle(group.aisleKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: allDone ? cardBorder : aisleStyle.color.withValues(alpha: isDarkMode ? 0.35 : 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Aisle header ─────────────────────────────────────────────
          InkWell(
            onTap: onToggleCollapse,
            borderRadius: collapsed
                ? BorderRadius.circular(16)
                : const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: allDone
                          ? const Color(0xFF059669).withValues(alpha: isDarkMode ? 0.25 : 0.12)
                          : aisleStyle.color.withValues(alpha: isDarkMode ? 0.22 : 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      allDone ? Icons.check_rounded : aisleStyle.icon,
                      size: 16,
                      color: allDone ? const Color(0xFF059669) : aisleStyle.color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      aisleLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: allDone
                            ? secondaryText
                            : Theme.of(context).colorScheme.onSurface,
                        decoration: allDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: done > 0
                          ? const Color(0xFF059669).withValues(alpha: isDarkMode ? 0.2 : 0.1)
                          : (isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF3F4F6)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$done/$total',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: done > 0 ? const Color(0xFF059669) : secondaryText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    collapsed ? Icons.expand_more_rounded : Icons.expand_less_rounded,
                    size: 20,
                    color: secondaryText,
                  ),
                ],
              ),
            ),
          ),

          // ── Items ─────────────────────────────────────────────────────
          if (!collapsed) ...[
            Divider(height: 1, color: cardBorder),
            for (int i = 0; i < group.items.length; i++) ...[
              _ShoppingRow(
                item: group.items[i],
                isChecked: checked.contains(group.items[i].key),
                isExpanded: expanded.contains(group.items[i].key),
                isDarkMode: isDarkMode,
                secondaryText: secondaryText,
                cardBorder: cardBorder,
                onToggleChecked: () => onToggleChecked(group.items[i].key),
                onToggleExpanded: () => onToggleExpanded(group.items[i].key),
                servingsLabel: servingsLabel,
              ),
              if (i < group.items.length - 1)
                Divider(height: 1, indent: 52, color: cardBorder),
            ],
          ],
        ],
      ),
    );
  }
}

// ── Shopping row ──────────────────────────────────────────────────────────────

class _ShoppingRow extends StatelessWidget {
  const _ShoppingRow({
    required this.item,
    required this.isChecked,
    required this.isExpanded,
    required this.isDarkMode,
    required this.secondaryText,
    required this.cardBorder,
    required this.onToggleChecked,
    required this.onToggleExpanded,
    required this.servingsLabel,
  });

  final ShoppingListItemModel item;
  final bool isChecked;
  final bool isExpanded;
  final bool isDarkMode;
  final Color secondaryText;
  final Color cardBorder;
  final VoidCallback onToggleChecked;
  final VoidCallback onToggleExpanded;
  final String Function(double) servingsLabel;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isChecked ? 0.45 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Checkbox
              SizedBox(
                width: 52,
                height: 52,
                child: Center(
                  child: GestureDetector(
                    onTap: onToggleChecked,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isChecked
                            ? const Color(0xFF059669)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isChecked
                              ? const Color(0xFF059669)
                              : (isDarkMode
                                  ? const Color(0xFF4A4A4A)
                                  : const Color(0xFFD1D5DB)),
                          width: 2,
                        ),
                      ),
                      child: isChecked
                          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
              ),
              // Label
              Expanded(
                child: GestureDetector(
                  onTap: item.sources.isEmpty ? null : onToggleExpanded,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      item.displayLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                        decoration: isChecked ? TextDecoration.lineThrough : null,
                        decorationColor: secondaryText,
                      ),
                    ),
                  ),
                ),
              ),
              // Expand button
              if (item.sources.isNotEmpty)
                GestureDetector(
                  onTap: onToggleExpanded,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: secondaryText,
                    ),
                  ),
                ),
            ],
          ),
          // Sources expand
          if (isExpanded && item.sources.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(52, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final source in item.sources)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 5, right: 8),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: secondaryText,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              [
                                if (source.recipeTitle.isNotEmpty) source.recipeTitle,
                                servingsLabel(source.servings),
                                if (source.line.isNotEmpty) source.line,
                              ].join(' · '),
                              style: TextStyle(
                                color: secondaryText,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
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
