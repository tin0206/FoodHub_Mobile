import 'package:flutter/material.dart';
import 'package:foodhub_mobile/screens/admin/admin_shell_screen.dart';
import 'package:foodhub_mobile/widgets/recipe_detail_view.dart';

class AdminRecipeFormScreen extends StatefulWidget {
  const AdminRecipeFormScreen({
    super.key,
    required this.isDarkMode,
    this.recipe,
  });

  final bool isDarkMode;
  final AdminRecipeFormData? recipe;

  @override
  State<AdminRecipeFormScreen> createState() => _AdminRecipeFormScreenState();
}

class AdminRecipeFormData {
  const AdminRecipeFormData({
    required this.id,
    required this.title,
    required this.cookingMinutes,
    required this.calories,
    required this.ingredientLines,
    required this.stepLines,
    required this.labels,
  });

  final int id;
  final String title;
  final int cookingMinutes;
  final int calories;
  final List<String> ingredientLines;
  final List<String> stepLines;
  final List<String> labels;
}

class _AdminRecipeFormScreenState extends State<AdminRecipeFormScreen> {
  bool _isSaving = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _minutesCtrl;
  late final TextEditingController _caloriesCtrl;
  late final List<TextEditingController> _ingredientCtrl;
  late final List<TextEditingController> _stepCtrl;
  late final Set<String> _selectedLabels;

  bool get _isEditing => widget.recipe != null;

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    _nameCtrl = TextEditingController(text: r?.title ?? '');
    _minutesCtrl = TextEditingController(
        text: r != null ? '${r.cookingMinutes}' : '');
    _caloriesCtrl = TextEditingController(
        text: r != null ? '${r.calories}' : '');
    _ingredientCtrl = r != null && r.ingredientLines.isNotEmpty
        ? r.ingredientLines
            .map((s) => TextEditingController(text: s))
            .toList()
        : [TextEditingController()];
    _stepCtrl = r != null && r.stepLines.isNotEmpty
        ? r.stepLines
            .map((s) => TextEditingController(text: s))
            .toList()
        : [TextEditingController()];
    _selectedLabels = r != null ? Set.from(r.labels) : {};
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _minutesCtrl.dispose();
    _caloriesCtrl.dispose();
    for (final c in _ingredientCtrl) {
      c.dispose();
    }
    for (final c in _stepCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final name = _nameCtrl.text.trim();
    final ingredients = _ingredientCtrl
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final steps = _stepCtrl
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final minutes = int.tryParse(_minutesCtrl.text.trim());
    final calories = int.tryParse(_caloriesCtrl.text.trim());

    if (name.isEmpty ||
        ingredients.isEmpty ||
        steps.isEmpty ||
        minutes == null ||
        calories == null ||
        minutes <= 0 ||
        calories <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final panelColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final dividerColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);
    final hintColor = isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF);
    final textColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF111827);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final surfaceVariant = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

    InputDecoration inlineFieldDec({String? hint, String? suffix}) =>
        InputDecoration(
          hintText: hint,
          suffixText: suffix,
          hintStyle: TextStyle(color: hintColor, fontSize: 13),
          isDense: true,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: kAdminAccent, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
        );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditing ? 'Edit Recipe' : 'New Recipe',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: dividerColor),
        ),
      ),
      body: Column(
        children: [
          // ── Scrollable body ────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe name
                  _AdminSectionCard(
                    isDark: isDark,
                    panelColor: panelColor,
                    child: TextField(
                      controller: _nameCtrl,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        letterSpacing: -0.3,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Recipe name…',
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
                  _AdminSectionCard(
                    isDark: isDark,
                    panelColor: panelColor,
                    child: Row(
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 16, color: kAdminAccent),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 56,
                          child: TextField(
                            controller: _minutesCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(fontSize: 13, color: textColor),
                            decoration: inlineFieldDec(hint: '0'),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('min',
                            style: TextStyle(fontSize: 12, color: hintColor)),
                        const SizedBox(width: 20),
                        const Icon(Icons.local_fire_department_outlined,
                            size: 16, color: kAdminAccent),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 56,
                          child: TextField(
                            controller: _caloriesCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(fontSize: 13, color: textColor),
                            decoration: inlineFieldDec(hint: '0'),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('cal',
                            style: TextStyle(fontSize: 12, color: hintColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Ingredients
                  _AdminSectionCard(
                    isDark: isDark,
                    panelColor: panelColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shopping_basket_outlined,
                                size: 15, color: kAdminAccent),
                            const SizedBox(width: 6),
                            Text(
                              'Ingredients',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: textColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._ingredientCtrl.asMap().entries.map((entry) {
                          final i = entry.key;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: kAdminAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: entry.value,
                                    maxLines: 1,
                                    textInputAction: TextInputAction.next,
                                    style: TextStyle(
                                        fontSize: 13, color: textColor),
                                    decoration:
                                        inlineFieldDec(hint: 'Ingredient ${i + 1}'),
                                  ),
                                ),
                                if (_ingredientCtrl.length > 1) ...[
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => setState(() {
                                      _ingredientCtrl[i].dispose();
                                      _ingredientCtrl.removeAt(i);
                                    }),
                                    child: Icon(Icons.close_rounded,
                                        size: 16, color: surfaceVariant),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                        TextButton.icon(
                          onPressed: () => setState(
                              () => _ingredientCtrl.add(TextEditingController())),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Add ingredient'),
                          style: TextButton.styleFrom(
                            foregroundColor: kAdminAccent,
                            textStyle: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Steps
                  _AdminSectionCard(
                    isDark: isDark,
                    panelColor: panelColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.format_list_numbered,
                                size: 15, color: kAdminAccent),
                            const SizedBox(width: 6),
                            Text(
                              'Instructions',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: textColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._stepCtrl.asMap().entries.map((entry) {
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
                                    color: kAdminAccent.withValues(
                                        alpha: isDark ? 0.18 : 0.1),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: kAdminAccent,
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
                                    style: TextStyle(
                                        fontSize: 13, color: textColor),
                                    decoration:
                                        inlineFieldDec(hint: 'Step ${i + 1}…'),
                                  ),
                                ),
                                if (_stepCtrl.length > 1) ...[
                                  const SizedBox(width: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _stepCtrl[i].dispose();
                                        _stepCtrl.removeAt(i);
                                      }),
                                      child: Icon(Icons.close_rounded,
                                          size: 16, color: surfaceVariant),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                        TextButton.icon(
                          onPressed: () => setState(
                              () => _stepCtrl.add(TextEditingController())),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Add step'),
                          style: TextButton.styleFrom(
                            foregroundColor: kAdminAccent,
                            textStyle: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Labels
                  _AdminSectionCard(
                    isDark: isDark,
                    panelColor: panelColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.sell_outlined,
                                size: 15, color: kAdminAccent),
                            const SizedBox(width: 6),
                            Text(
                              'Labels',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: textColor),
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
                              selectedColor: kAdminAccent,
                              checkmarkColor: Colors.white,
                              backgroundColor: isDark
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.white,
                              side: BorderSide.none,
                              label: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isSelected ? Colors.white : textSub,
                                ),
                              ),
                              onSelected: (v) => setState(() => v
                                  ? _selectedLabels.add(label)
                                  : _selectedLabels.remove(label)),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // ── Bottom action bar ──────────────────────────────────────────
          Container(
            color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      foregroundColor: textColor,
                      side: BorderSide.none,
                      backgroundColor:
                          isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      backgroundColor: kAdminAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _isEditing ? 'Save Changes' : 'Save Recipe',
                            style: const TextStyle(fontWeight: FontWeight.w700),
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

// ── Section card (mirrors _AddSectionCard from home_screen) ──────────────────

class _AdminSectionCard extends StatelessWidget {
  const _AdminSectionCard({
    required this.isDark,
    required this.panelColor,
    required this.child,
  });

  final bool isDark;
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
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
            blurRadius: isDark ? 8 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
