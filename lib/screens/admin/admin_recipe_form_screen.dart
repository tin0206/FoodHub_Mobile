import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:foodhub_mobile/config/api_config.dart';
import 'package:foodhub_mobile/models/recipe.dart';
import 'package:foodhub_mobile/screens/admin/admin_recipe_detail_screen.dart';
import 'package:foodhub_mobile/screens/admin/admin_shell_screen.dart';
import 'package:foodhub_mobile/services/admin_service.dart';
import 'package:foodhub_mobile/services/api_exception.dart';
import 'package:image_picker/image_picker.dart';
import 'package:foodhub_mobile/widgets/recipe_detail_view.dart' show kAvailableLabels;

class AdminRecipeFormScreen extends StatefulWidget {
  const AdminRecipeFormScreen({
    super.key,
    required this.isDarkMode,
    this.recipe,
  });

  final bool isDarkMode;
  final RecipeModel? recipe;

  @override
  State<AdminRecipeFormScreen> createState() => _AdminRecipeFormScreenState();
}

class _AdminRecipeFormScreenState extends State<AdminRecipeFormScreen> {
  bool _isSaving = false;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _servingsCtrl;
  late final List<TextEditingController> _ingredientCtrl;
  late final List<TextEditingController> _stepCtrl;
  late final Set<String> _selectedLabels;

  String? _existingImageUrl;
  Uint8List? _pendingImageBytes;
  String _pendingImageFilename = 'recipe.jpg';

  bool get _isEditing => widget.recipe != null;
  bool get _isCatalog => widget.recipe?.createdBy == null && _isEditing;
  bool get _hasImage =>
      _pendingImageBytes != null ||
      (_existingImageUrl != null && _existingImageUrl!.isNotEmpty);

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    _titleCtrl = TextEditingController(text: r?.title ?? '');
    _servingsCtrl = TextEditingController(
        text: r?.estimatedServings != null ? '${r!.estimatedServings}' : '');
    _ingredientCtrl = r != null && r.ingredients.isNotEmpty
        ? r.ingredients.map((s) => TextEditingController(text: s)).toList()
        : [TextEditingController()];
    _stepCtrl = r != null && r.directions.isNotEmpty
        ? r.directions.map((s) => TextEditingController(text: s)).toList()
        : [TextEditingController()];
    _selectedLabels = r != null ? Set.from(r.dietaryRestrictions) : {};
    _existingImageUrl = r?.imageUrl;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _servingsCtrl.dispose();
    for (final c in _ingredientCtrl) {
      c.dispose();
    }
    for (final c in _stepCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _pendingImageBytes = bytes;
      _pendingImageFilename = file.name.isNotEmpty ? file.name : 'recipe.jpg';
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final title = _titleCtrl.text.trim();
    final ingredients = _ingredientCtrl
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final steps = _stepCtrl
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final servings = int.tryParse(_servingsCtrl.text.trim());

    if (title.isEmpty || ingredients.isEmpty || steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Title, ingredients, and instructions are required.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final admin = AdminService();
      final RecipeModel saved;
      if (_isEditing) {
        saved = await admin.updateRecipe(
          widget.recipe!.id,
          title: title,
          ingredients: ingredients,
          directions: steps,
          dietaryRestrictions: _selectedLabels.toList(),
          estimatedServings: servings,
        );
      } else {
        saved = await admin.createRecipe(
          title: title,
          ingredients: ingredients,
          directions: steps,
          dietaryRestrictions: _selectedLabels.toList(),
          estimatedServings: servings,
        );
      }

      if (_pendingImageBytes != null && _pendingImageBytes!.isNotEmpty) {
        try {
          await admin.uploadRecipeImage(
            saved.id,
            _pendingImageBytes!,
            _pendingImageFilename,
          );
        } on ApiException catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Image upload failed: ${e.message}')),
            );
          }
        }
      }

      if (!mounted) return;

      // Catalog clone: backend returned a new recipe with a different id
      if (_isEditing && saved.id != widget.recipe!.id) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AdminRecipeDetailScreen(
              recipeId: saved.id,
              isDarkMode: widget.isDarkMode,
            ),
          ),
        );
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : '$e')),
      );
    }
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

    InputDecoration inlineFieldDec({String? hint, String? suffix}) => InputDecoration(
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
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: dividerColor),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Catalog notice ──────────────────────────────────────
                  if (_isCatalog)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 14, color: Color(0xFFF59E0B)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Saving this catalog recipe will create a new copy linked to you.',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFF59E0B)),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Image ───────────────────────────────────────────────
                  _AdminSectionCard(
                    isDark: isDark,
                    panelColor: panelColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.image_outlined,
                                size: 15, color: kAdminAccent),
                            const SizedBox(width: 6),
                            Text('Image',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: textColor)),
                            const Spacer(),
                            GestureDetector(
                              onTap: _pickImage,
                              child: Text(
                                _hasImage ? 'Change Photo' : 'Add Photo',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: kAdminAccent),
                              ),
                            ),
                          ],
                        ),
                        if (_hasImage) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _pendingImageBytes != null
                                ? Image.memory(
                                    _pendingImageBytes!,
                                    height: 140,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : CachedNetworkImage(
                                    imageUrl: ApiConfig.resolveImageUrl(_existingImageUrl),
                                    height: 140,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (c, u) => Container(
                                      height: 140,
                                      color: isDark
                                          ? const Color(0xFF1A1A2E)
                                          : const Color(0xFFEEF0FF),
                                    ),
                                    errorWidget: (c, u, e) => Container(
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF1A1A2E)
                                            : const Color(0xFFEEF0FF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.broken_image_outlined,
                                            color: kAdminAccent),
                                      ),
                                    ),
                                  ),
                          ),
                        ] else ...[
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              height: 90,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E1E1E)
                                    : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: kAdminAccent.withValues(alpha: 0.3),
                                    width: 1.5,
                                    style: BorderStyle.solid),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined,
                                        size: 28, color: kAdminAccent),
                                    SizedBox(height: 6),
                                    Text('Tap to add image',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: kAdminAccent)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Title ───────────────────────────────────────────────
                  _AdminSectionCard(
                    isDark: isDark,
                    panelColor: panelColor,
                    child: TextField(
                      controller: _titleCtrl,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: -0.3),
                      decoration: InputDecoration(
                        hintText: 'Recipe title…',
                        hintStyle: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: hintColor,
                            letterSpacing: -0.3),
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

                  // ── Servings ────────────────────────────────────────────
                  _AdminSectionCard(
                    isDark: isDark,
                    panelColor: panelColor,
                    child: Row(
                      children: [
                        const Icon(Icons.people_outline_rounded,
                            size: 16, color: kAdminAccent),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 56,
                          child: TextField(
                            controller: _servingsCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(fontSize: 13, color: textColor),
                            decoration: inlineFieldDec(hint: '0'),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('servings',
                            style: TextStyle(fontSize: 12, color: hintColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Ingredients ─────────────────────────────────────────
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
                            Text('Ingredients',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: textColor)),
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
                                      color: kAdminAccent, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: entry.value,
                                    maxLines: 1,
                                    textInputAction: TextInputAction.next,
                                    style: TextStyle(fontSize: 13, color: textColor),
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
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Instructions ────────────────────────────────────────
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
                            Text('Instructions',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: textColor)),
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
                                  child: Text('${i + 1}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: kAdminAccent)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: entry.value,
                                    maxLines: null,
                                    minLines: 1,
                                    textInputAction: TextInputAction.next,
                                    style: TextStyle(fontSize: 13, color: textColor),
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
                          onPressed: () =>
                              setState(() => _stepCtrl.add(TextEditingController())),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Add step'),
                          style: TextButton.styleFrom(
                            foregroundColor: kAdminAccent,
                            textStyle: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Labels ──────────────────────────────────────────────
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
                            Text('Labels',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: textColor)),
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
                                    color: isSelected ? Colors.white : textSub),
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

          // ── Bottom action bar ────────────────────────────────────────────
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
                      backgroundColor: isDark
                          ? const Color(0xFF1E1E1E)
                          : const Color(0xFFF3F4F6),
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
                                strokeWidth: 2, color: Colors.white))
                        : Text(
                            _isEditing ? 'Save Changes' : 'Save Recipe',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700),
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

// ── Section card ───────────────────────────────────────────────────────────────

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
