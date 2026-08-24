import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:foodhub_mobile/config/api_config.dart';
import 'package:foodhub_mobile/models/admin.dart';
import 'package:foodhub_mobile/models/recipe.dart';
import 'package:foodhub_mobile/screens/admin/admin_recipe_form_screen.dart';
import 'package:foodhub_mobile/screens/admin/admin_shell_screen.dart';
import 'package:foodhub_mobile/services/admin_service.dart';
import 'package:foodhub_mobile/services/api_exception.dart';

class AdminRecipeDetailScreen extends StatefulWidget {
  const AdminRecipeDetailScreen({
    super.key,
    required this.recipeId,
    required this.isDarkMode,
  });

  final int recipeId;
  final bool isDarkMode;

  @override
  State<AdminRecipeDetailScreen> createState() => _AdminRecipeDetailScreenState();
}

class _AdminRecipeDetailScreenState extends State<AdminRecipeDetailScreen> {
  final _admin = AdminService();
  RecipeModel? _recipe;
  List<RecipeTranslation>? _translations;
  bool _loading = true;
  String? _error;
  bool _visibilityToggling = false;
  bool _deleting = false;

  // Inline translation panel
  static const _supportedLocales = ['en', 'vi'];
  String _selectedLocale = 'en';
  final _titleCtrl = TextEditingController();
  final _ingredientsCtrl = TextEditingController();
  final _directionsCtrl = TextEditingController();
  bool _saving = false;
  bool _deletingTranslation = false;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _ingredientsCtrl.dispose();
    _directionsCtrl.dispose();
    super.dispose();
  }

  void _fillControllers(String locale) {
    final recipe = _recipe;
    if (recipe == null) return;
    final existing = (_translations ?? []).where((t) => t.locale == locale).toList();
    if (existing.isNotEmpty) {
      final t = existing.first;
      _titleCtrl.text = t.title;
      _ingredientsCtrl.text = t.ingredients.join('\n');
      _directionsCtrl.text = t.directions.join('\n');
    } else {
      _titleCtrl.text = recipe.title;
      _ingredientsCtrl.text = recipe.ingredients.join('\n');
      _directionsCtrl.text = recipe.directions.join('\n');
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _admin.getRecipe(widget.recipeId),
        _admin.getTranslations(widget.recipeId),
      ]);
      if (!mounted) return;
      setState(() {
        _recipe = results[0] as RecipeModel;
        _translations = results[1] as List<RecipeTranslation>;
        _loading = false;
      });
      _fillControllers(_selectedLocale);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : '$e';
      });
    }
  }

  Future<void> _toggleVisibility() async {
    final recipe = _recipe;
    if (recipe == null || _visibilityToggling) return;
    setState(() => _visibilityToggling = true);
    try {
      final newVis = recipe.isPrivate ? 'public' : 'private';
      final updated = await _admin.setRecipeVisibility(recipe.id, newVis);
      if (!mounted) return;
      setState(() {
        _recipe = updated;
        _visibilityToggling = false;
        _notice = 'Visibility updated to ${updated.isPrivate ? 'private' : 'public'}.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _visibilityToggling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : '$e')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final isDark = widget.isDarkMode;
    final recipe = _recipe;
    if (recipe == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Recipe?',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827))),
        content: Text(
            '"${recipe.title}" and all its translations will be permanently removed.',
            style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF43F5E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await _admin.deleteRecipe(recipe.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : '$e')),
      );
    }
  }

  Future<void> _saveTranslation() async {
    final recipe = _recipe;
    if (recipe == null || _saving) return;
    setState(() => _saving = true);
    try {
      final t = RecipeTranslation(
        locale: _selectedLocale,
        title: _titleCtrl.text.trim(),
        ingredients: _ingredientsCtrl.text
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        directions: _directionsCtrl.text
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      );
      await _admin.saveTranslation(recipe.id, _selectedLocale, t);
      final translations = await _admin.getTranslations(recipe.id);
      if (!mounted) return;
      setState(() {
        _translations = translations;
        _saving = false;
        _notice = 'Translation saved.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : '$e')),
      );
    }
  }

  Future<void> _deleteTranslation() async {
    final recipe = _recipe;
    if (recipe == null || _deletingTranslation) return;
    setState(() => _deletingTranslation = true);
    try {
      await _admin.deleteTranslation(recipe.id, _selectedLocale);
      final translations = await _admin.getTranslations(recipe.id);
      if (!mounted) return;
      setState(() {
        _translations = translations;
        _deletingTranslation = false;
        _notice = 'Translation deleted.';
      });
      _fillControllers(_selectedLocale);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deletingTranslation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : '$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final bg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF141414) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final divColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6);
    final inputFill = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6);

    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(
            child: CircularProgressIndicator(strokeWidth: 2.5, color: kAdminAccent)),
      );
    }

    if (_error != null || _recipe == null) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? 'Recipe not found', style: TextStyle(color: textSub)),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final recipe = _recipe!;
    final translations = _translations ?? [];
    final isPublic = !recipe.isPrivate;
    final isCatalog = recipe.createdBy == null;
    final hasCurrentTranslation = translations.any((t) => t.locale == _selectedLocale);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
            foregroundColor: textPrimary,
            elevation: 0,
            floating: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Recipe Detail',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
            centerTitle: true,
            actions: [
              IconButton(
                icon: _deleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFFF43F5E)))
                    : const Icon(Icons.delete_outline_rounded, color: Color(0xFFF43F5E)),
                onPressed: _deleting ? null : _confirmDelete,
              ),
              IconButton(
                icon: Icon(Icons.edit_rounded, color: textPrimary),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          AdminRecipeFormScreen(isDarkMode: isDark, recipe: recipe),
                    ),
                  );
                  _load();
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: divColor),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero image ───────────────────────────────────────────
                Builder(builder: (ctx) {
                  final resolved = ApiConfig.resolveImageUrl(recipe.imageUrl);
                  if (resolved.isEmpty) return _ImagePlaceholder(isDark: isDark);
                  return SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: CachedNetworkImage(
                      imageUrl: resolved,
                      fit: BoxFit.cover,
                      placeholder: (ctx2, url) => _ImagePlaceholder(isDark: isDark),
                      errorWidget: (ctx2, url, err) => _ImagePlaceholder(isDark: isDark),
                    ),
                  );
                }),

                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Catalog notice ──────────────────────────────────
                      if (isCatalog)
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
                                  'This is a catalog recipe. Edits will create a user copy.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFF59E0B)),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // ── Success notice ──────────────────────────────────
                      if (_notice != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline_rounded,
                                  size: 14, color: Color(0xFF10B981)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_notice!,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF10B981))),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _notice = null),
                                child: const Icon(Icons.close_rounded,
                                    size: 14, color: Color(0xFF10B981)),
                              ),
                            ],
                          ),
                        ),

                      // ── Recipe header card ──────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                              blurRadius: isDark ? 12 : 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(recipe.title,
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                    letterSpacing: -0.3)),
                            const SizedBox(height: 4),
                            Text('#${recipe.id} · ${recipe.locale}',
                                style: TextStyle(fontSize: 12, color: textSub)),
                            const SizedBox(height: 14),

                            // Visibility pill + toggle
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isPublic
                                            ? const Color(0xFF10B981)
                                            : textSub)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isPublic
                                            ? Icons.visibility_rounded
                                            : Icons.visibility_off_rounded,
                                        size: 10,
                                        color: isPublic
                                            ? const Color(0xFF10B981)
                                            : textSub,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isPublic ? 'Public' : 'Private',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isPublic
                                                ? const Color(0xFF10B981)
                                                : textSub),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: _visibilityToggling
                                      ? null
                                      : _toggleVisibility,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isPublic
                                          ? const Color(0xFF10B981)
                                              .withValues(alpha: 0.1)
                                          : kAdminAccent.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: _visibilityToggling
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: kAdminAccent))
                                        : Text(
                                            isPublic
                                                ? 'Make Private'
                                                : 'Make Public',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: isPublic
                                                    ? const Color(0xFF10B981)
                                                    : kAdminAccent),
                                          ),
                                  ),
                                ),
                              ],
                            ),

                            if (recipe.dietaryRestrictions.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 6,
                                runSpacing: 5,
                                children: recipe.dietaryRestrictions.map((l) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 9, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: kAdminAccent.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(l,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: kAdminAccent)),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Ingredients ─────────────────────────────────────
                      _DetailSection(
                        title: 'Ingredients',
                        icon: Icons.shopping_basket_outlined,
                        isDark: isDark,
                        cardBg: cardBg,
                        textPrimary: textPrimary,
                        textSub: textSub,
                        child: recipe.ingredients.isEmpty
                            ? Text('None',
                                style: TextStyle(fontSize: 13, color: textSub))
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: recipe.ingredients.map((ing) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 7),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(top: 5),
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color:
                                                kAdminAccent.withValues(alpha: 0.7),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(ing,
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: textPrimary)),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                      const SizedBox(height: 10),

                      // ── Directions ──────────────────────────────────────
                      _DetailSection(
                        title: 'Instructions',
                        icon: Icons.format_list_numbered,
                        isDark: isDark,
                        cardBg: cardBg,
                        textPrimary: textPrimary,
                        textSub: textSub,
                        child: recipe.directions.isEmpty
                            ? Text('None',
                                style: TextStyle(fontSize: 13, color: textSub))
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children:
                                    recipe.directions.asMap().entries.map((e) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color:
                                                kAdminAccent.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text('${e.key + 1}',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: kAdminAccent)),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(e.value,
                                              style: TextStyle(
                                                  fontSize: 13, color: textPrimary)),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                      const SizedBox(height: 18),

                      // ── Translations (inline panel) ─────────────────────
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: kAdminAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.translate_rounded,
                                size: 15, color: kAdminAccent),
                          ),
                          const SizedBox(width: 8),
                          Text('Translations',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                              blurRadius: isDark ? 12 : 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Locale picker
                            Row(
                              children: _supportedLocales.map((loc) {
                                final hasIt =
                                    translations.any((t) => t.locale == loc);
                                final isSelected = _selectedLocale == loc;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() => _selectedLocale = loc);
                                      _fillControllers(loc);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? kAdminAccent
                                            : kAdminAccent.withValues(
                                                alpha: isDark ? 0.15 : 0.08),
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: Text(
                                        hasIt
                                            ? loc.toUpperCase()
                                            : '${loc.toUpperCase()} + new',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? Colors.white
                                              : kAdminAccent,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),
                            Divider(height: 1, color: divColor),
                            const SizedBox(height: 14),

                            // Title
                            _TransFieldInline(
                              label: 'Title',
                              controller: _titleCtrl,
                              isDark: isDark,
                              textPrimary: textPrimary,
                              textSub: textSub,
                              inputFill: inputFill,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 12),

                            // Ingredients
                            _TransFieldInline(
                              label: 'Ingredients (one per line)',
                              controller: _ingredientsCtrl,
                              isDark: isDark,
                              textPrimary: textPrimary,
                              textSub: textSub,
                              inputFill: inputFill,
                              maxLines: 6,
                            ),
                            const SizedBox(height: 12),

                            // Directions
                            _TransFieldInline(
                              label: 'Instructions (one per line)',
                              controller: _directionsCtrl,
                              isDark: isDark,
                              textPrimary: textPrimary,
                              textSub: textSub,
                              inputFill: inputFill,
                              maxLines: 8,
                            ),
                            const SizedBox(height: 16),

                            // Save + Delete
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    onPressed: _saving ? null : _saveTranslation,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: kAdminAccent,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: _saving
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white))
                                        : Text(
                                            'Save ${_selectedLocale.toUpperCase()}',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700)),
                                  ),
                                ),
                                if (hasCurrentTranslation) ...[
                                  const SizedBox(width: 10),
                                  OutlinedButton(
                                    onPressed: _deletingTranslation
                                        ? null
                                        : _deleteTranslation,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFF43F5E),
                                      side: const BorderSide(
                                          color: Color(0xFFF43F5E)),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 14),
                                    ),
                                    child: _deletingTranslation
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFFF43F5E)))
                                        : Text(
                                            'Delete ${_selectedLocale.toUpperCase()}',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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

// ── Hero image placeholder ─────────────────────────────────────────────────────

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFEEF0FF),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded,
              size: 48, color: kAdminAccent.withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          Text('No image',
              style: TextStyle(
                  fontSize: 12,
                  color: kAdminAccent.withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}

// ── Detail section card ────────────────────────────────────────────────────────

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.cardBg,
    required this.textPrimary,
    required this.textSub,
    required this.child,
  });

  final String title;
  final IconData icon;
  final bool isDark;
  final Color cardBg;
  final Color textPrimary;
  final Color textSub;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: isDark ? 10 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: kAdminAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 14, color: kAdminAccent),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Inline translation textarea ────────────────────────────────────────────────

class _TransFieldInline extends StatelessWidget {
  const _TransFieldInline({
    required this.label,
    required this.controller,
    required this.isDark,
    required this.textPrimary,
    required this.textSub,
    required this.inputFill,
    required this.maxLines,
  });

  final String label;
  final TextEditingController controller;
  final bool isDark;
  final Color textPrimary;
  final Color textSub;
  final Color inputFill;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: textSub)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(fontSize: 13, color: textPrimary),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kAdminAccent, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}
