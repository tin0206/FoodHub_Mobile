import 'dart:async';

import 'package:flutter/material.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';
import 'package:foodhub_mobile/models/ingredient.dart';
import 'package:foodhub_mobile/services/recipe_service.dart';

class IngredientPickerRow extends StatefulWidget {
  const IngredientPickerRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.canRemove,
    required this.onRemove,
    this.accentColor = const Color(0xFF059669),
  });

  final SelectedCatalogIngredient? value;
  final ValueChanged<SelectedCatalogIngredient?> onChanged;
  final bool canRemove;
  final VoidCallback onRemove;
  final Color accentColor;

  @override
  State<IngredientPickerRow> createState() => _IngredientPickerRowState();
}

class _IngredientPickerRowState extends State<IngredientPickerRow> {
  final _recipeService = RecipeService();
  final _searchController = TextEditingController();
  final _amountController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<IngredientHit> _hits = [];
  bool _searching = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _syncFromValue();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _hits = []);
      }
    });
  }

  @override
  void didUpdateWidget(covariant IngredientPickerRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value?.id != widget.value?.id ||
        oldWidget.value?.amount != widget.value?.amount ||
        oldWidget.value?.unit != widget.value?.unit) {
      _syncFromValue();
    }
  }

  void _syncFromValue() {
    final selected = widget.value;
    if (selected == null) {
      if (_searchController.text.isNotEmpty) _searchController.clear();
      _amountController.text = '1';
      return;
    }
    _searchController.text = selected.displayName;
    final amount = selected.amount;
    _amountController.text =
        amount == amount.roundToDouble() ? '${amount.toInt()}' : '$amount';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _amountController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String raw) {
    if (widget.value != null) {
      widget.onChanged(null);
    }
    _debounce?.cancel();
    final q = raw.trim();
    if (q.length < 2) {
      setState(() {
        _hits = [];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() => _searching = true);
    try {
      final hits = await _recipeService.searchIngredients(q);
      if (!mounted || _searchController.text.trim() != q) return;
      setState(() {
        _hits = hits;
        _lastQuery = q;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hits = [];
        _searching = false;
      });
    }
  }

  void _selectHit(IngredientHit hit) {
    _focusNode.unfocus();
    setState(() => _hits = []);
    widget.onChanged(SelectedCatalogIngredient.fromHit(hit));
  }

  void _onAmountChanged(String raw) {
    final selected = widget.value;
    if (selected == null) return;
    final amount = double.tryParse(raw.replaceAll(',', '.'));
    if (amount == null || amount <= 0) return;
    widget.onChanged(selected.copyWith(amount: amount));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final s = S.of(context);
    final selected = widget.value;
    final locked = selected != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: widget.accentColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: locked
                  ? _buildSelected(context, selected, colors, s)
                  : _buildSearch(context, colors, s),
            ),
            if (widget.canRemove) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: widget.onRemove,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (!locked && (_hits.isNotEmpty || _searching))
          Padding(
            padding: const EdgeInsets.only(left: 17, top: 4),
            child: _buildHits(colors, s),
          ),
      ],
    );
  }

  Widget _buildSearch(BuildContext context, ColorScheme colors, S s) {
    return TextField(
      controller: _searchController,
      focusNode: _focusNode,
      maxLines: 1,
      textInputAction: TextInputAction.next,
      onChanged: _onQueryChanged,
      style: TextStyle(fontSize: 13, color: colors.onSurface),
      decoration: InputDecoration(
        hintText: s.searchIngredientHint,
        hintStyle: TextStyle(
          fontSize: 13,
          color: colors.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        isDense: true,
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: widget.accentColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  Widget _buildSelected(
    BuildContext context,
    SelectedCatalogIngredient selected,
    ColorScheme colors,
    S s,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            widget.onChanged(null);
            _searchController.clear();
            _focusNode.requestFocus();
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Text(
              selected.displayName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ),
        ),
        Row(
          children: [
            SizedBox(
              width: 64,
              child: TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(fontSize: 13, color: colors.onSurface),
                onChanged: _onAmountChanged,
                decoration: InputDecoration(
                  hintText: s.amountHint,
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: widget.accentColor, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                ),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selected.units.any((u) => u.unit == selected.unit)
                    ? selected.unit
                    : selected.units.first.unit,
                isDense: true,
                style: TextStyle(fontSize: 13, color: colors.onSurface),
                items: [
                  for (final unit in selected.units)
                    DropdownMenuItem(
                      value: unit.unit,
                      child: Text(unit.unit),
                    ),
                ],
                onChanged: (unit) {
                  if (unit == null) return;
                  widget.onChanged(selected.copyWith(unit: unit));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHits(ColorScheme colors, S s) {
    if (_searching && _hits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: widget.accentColor,
          ),
        ),
      );
    }
    if (_hits.isEmpty && _lastQuery.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          s.noMatchingIngredient,
          style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
        ),
      );
    }
    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _hits.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: colors.outlineVariant.withValues(alpha: 0.5),
        ),
        itemBuilder: (context, index) {
          final hit = _hits[index];
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Text(
              hit.naturalName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: hit.name != hit.naturalName
                ? Text(
                    hit.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
                  )
                : null,
            onTap: () => _selectHit(hit),
          );
        },
      ),
    );
  }
}

class IngredientPickerList extends StatelessWidget {
  const IngredientPickerList({
    super.key,
    required this.lines,
    required this.onChanged,
    this.accentColor = const Color(0xFF059669),
  });

  final List<SelectedCatalogIngredient?> lines;
  final ValueChanged<List<SelectedCatalogIngredient?>> onChanged;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: IngredientPickerRow(
              value: lines[i],
              accentColor: accentColor,
              canRemove: lines.length > 1,
              onChanged: (value) {
                final next = List<SelectedCatalogIngredient?>.from(lines);
                next[i] = value;
                onChanged(next);
              },
              onRemove: () {
                final next = List<SelectedCatalogIngredient?>.from(lines)
                  ..removeAt(i);
                onChanged(next);
              },
            ),
          ),
        TextButton.icon(
          onPressed: () => onChanged([...lines, null]),
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
    );
  }
}

List<IngredientItemInput> selectedIngredientInputs(
  List<SelectedCatalogIngredient?> lines,
) {
  return lines
      .whereType<SelectedCatalogIngredient>()
      .where((item) => item.amount > 0)
      .map((item) => item.toInput())
      .toList();
}
