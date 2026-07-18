import 'package:flutter/material.dart';
import 'package:foodhub_mobile/screens/admin/admin_recipe_form_screen.dart';
import 'package:foodhub_mobile/screens/admin/admin_shell_screen.dart';

class AdminRecipesScreen extends StatefulWidget {
  const AdminRecipesScreen({super.key, required this.isDarkMode});

  final bool isDarkMode;

  @override
  State<AdminRecipesScreen> createState() => _AdminRecipesScreenState();
}

class _AdminRecipesScreenState extends State<AdminRecipesScreen> {
  String _query = '';
  String? _labelFilter;

  static const _allLabels = [
    'Vietnamese', 'Vegan', 'High Protein', 'Keto',
    'Breakfast', 'Quick Meal', 'Pescetarian', 'Healthy',
  ];

  List<_RecipeData> get _filtered {
    var list = _kRecipes.toList();
    if (_labelFilter != null) {
      list = list.where((r) => r.labels.contains(_labelFilter)).toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((r) => r.title.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  void _confirmDelete(_RecipeData r) {
    final isDark = widget.isDarkMode;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Recipe?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
          ),
        ),
        content: Text(
          '"${r.title}" will be permanently removed.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final cardBg = isDark ? const Color(0xFF141414) : Colors.white;
    final list = _filtered;

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Recipes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: kAdminAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${_kRecipes.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: kAdminAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v.trim()),
                      style: TextStyle(fontSize: 14, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search recipes…',
                        hintStyle: TextStyle(color: textSub, fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: textSub, size: 20),
                        filled: true,
                        fillColor: cardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: kAdminAccent),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _labelFilter == null,
                          isDark: isDark,
                          onTap: () => setState(() => _labelFilter = null),
                        ),
                        ..._allLabels.map(
                          (l) => _FilterChip(
                            label: l,
                            selected: _labelFilter == l,
                            isDark: isDark,
                            onTap: () => setState(
                              () => _labelFilter = l == _labelFilter ? null : l,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text('No recipes found',
                          style: TextStyle(color: textSub)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 80),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final r = list[i];
                        return Container(
                          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: isDark ? 0.3 : 0.06),
                                blurRadius: isDark ? 10 : 8,
                                offset: const Offset(0, 3),
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
                                      r.title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.favorite_rounded,
                                            size: 11,
                                            color: const Color(0xFFF43F5E)
                                                .withValues(alpha: 0.7)),
                                        const SizedBox(width: 3),
                                        Text('${r.favorites}',
                                            style: TextStyle(
                                                fontSize: 11, color: textSub)),
                                        const SizedBox(width: 10),
                                        Icon(Icons.calendar_today_rounded,
                                            size: 11, color: textSub),
                                        const SizedBox(width: 3),
                                        Text(r.createdAt,
                                            style: TextStyle(
                                                fontSize: 11, color: textSub)),
                                      ],
                                    ),
                                    if (r.labels.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 5,
                                        children: r.labels.take(3).map((l) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: kAdminAccent
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              l,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: kAdminAccent,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _confirmDelete(r),
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 19,
                                  color: const Color(0xFFF43F5E)
                                      .withValues(alpha: 0.7),
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 36, minHeight: 36),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),

        // ── Add Recipe FAB ────────────────────────────────────────────
        Positioned(
          right: 16,
          bottom: 16,
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    AdminRecipeFormScreen(isDarkMode: widget.isDarkMode),
              ),
            ),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: kAdminAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kAdminAccent.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? kAdminAccent
                : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected
                  ? Colors.white
                  : (isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF6B7280)),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _RecipeData {
  const _RecipeData({
    required this.id,
    required this.title,
    required this.labels,
    required this.favorites,
    required this.createdAt,
  });

  final int id;
  final String title;
  final List<String> labels;
  final int favorites;
  final String createdAt;
}

const _kRecipes = [
  _RecipeData(id: 1, title: 'Phở Bò Hà Nội', labels: ['Vietnamese', 'High Protein'], favorites: 142, createdAt: 'Feb 1, 2024'),
  _RecipeData(id: 2, title: 'Bún Bò Huế', labels: ['Vietnamese'], favorites: 98, createdAt: 'Feb 15, 2024'),
  _RecipeData(id: 3, title: 'Green Smoothie Bowl', labels: ['Vegan', 'Breakfast', 'Healthy'], favorites: 201, createdAt: 'Mar 1, 2024'),
  _RecipeData(id: 4, title: 'Grilled Salmon', labels: ['High Protein', 'Pescetarian'], favorites: 87, createdAt: 'Mar 20, 2024'),
  _RecipeData(id: 5, title: 'Keto Egg Salad', labels: ['Keto', 'Quick Meal'], favorites: 64, createdAt: 'Apr 5, 2024'),
  _RecipeData(id: 6, title: 'Bánh Mì Sandwich', labels: ['Vietnamese', 'Quick Meal'], favorites: 176, createdAt: 'Apr 18, 2024'),
  _RecipeData(id: 7, title: 'Avocado Toast', labels: ['Vegan', 'Breakfast'], favorites: 133, createdAt: 'May 2, 2024'),
  _RecipeData(id: 8, title: 'Chicken Stir Fry', labels: ['High Protein', 'Quick Meal'], favorites: 89, createdAt: 'May 15, 2024'),
];
