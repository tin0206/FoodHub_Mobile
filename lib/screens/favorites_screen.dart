import 'package:flutter/material.dart';
import 'package:foodhub_mobile/widgets/recipe_detail_view.dart';

const _kFavoriteCardColors = [
  Color(0xFFFFF7ED),
  Color(0xFFEFF6FF),
  Color(0xFFF0FDF4),
  Color(0xFFFFF1F2),
];

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, this.onDetailModeChanged});

  final ValueChanged<bool>? onDetailModeChanged;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final List<_FavoriteRecipe> _recipes = [
    const _FavoriteRecipe(
      name: 'Quinoa Buddha Bowl',
      duration: 25,
      calories: 420,
      note: 'Great for meal prep! Double the tahini dressing.',
      ingredients:
          '2 cups quinoa\n1 cup chickpeas\n1/2 avocado\nTahini dressing\nMixed greens',
      instructions:
          'Cook quinoa per package.\nRoast chickpeas at 200°C for 20 min.\nAssemble bowl with greens, quinoa, chickpeas.\nTop with avocado and tahini.',
      tags: ['Vegetarian', 'Healthy'],
    ),
    const _FavoriteRecipe(
      name: 'Grilled Chicken & Veggies',
      duration: 35,
      calories: 450,
      note: null,
      ingredients:
          '2 chicken breasts\nBell pepper\nZucchini\nOlive oil\nSalt and pepper',
      instructions:
          'Season the chicken.\nGrill chicken and vegetables.\nSlice chicken.\nServe warm with veggies.',
      tags: ['High Protein', 'Keto'],
    ),
  ];

  int? _selectedRecipeIndex;
  bool _savedCurrentRecipe = true;
  bool _isUnfavoriteDialogOpen = false;
  bool _isNoteDialogOpen = false;

  void _openRecipeDetails(int index) {
    if (index < 0 || index >= _recipes.length) return;
    widget.onDetailModeChanged?.call(true);
    setState(() {
      _selectedRecipeIndex = index;
      _savedCurrentRecipe = true;
    });
  }

  void _closeRecipeDetails() {
    if (_selectedRecipeIndex == null) return;

    final index = _selectedRecipeIndex!;
    final removedName = _recipes[index].name;

    if (!_savedCurrentRecipe && index < _recipes.length) {
      _recipes.removeAt(index);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$removedName removed from favorites.')),
      );
    }

    widget.onDetailModeChanged?.call(false);
    setState(() {
      _selectedRecipeIndex = null;
      _savedCurrentRecipe = true;
    });
  }

  void _toggleSaveInDetail() {
    setState(() {
      _savedCurrentRecipe = !_savedCurrentRecipe;
    });
  }

  Future<void> _onEditNote(int index) async {
    if (_isNoteDialogOpen) return;

    _isNoteDialogOpen = true;
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      _isNoteDialogOpen = false;
      return;
    }

    final current = _recipes[index];
    final updatedNote = await _showEditNoteDialog(
      initialNote: current.note ?? '',
    );
    _isNoteDialogOpen = false;

    if (!mounted || updatedNote == null) return;

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

    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    Navigator.of(context).pop();

    setState(() {
      _recipes[index] = current.copyWith(
        note: updatedNote.trim().isEmpty ? null : updatedNote.trim(),
      );
    });
  }

  Future<void> _onUnfavorite(int index) async {
    if (_isUnfavoriteDialogOpen) return;

    _isUnfavoriteDialogOpen = true;
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      _isUnfavoriteDialogOpen = false;
      return;
    }

    final recipe = _recipes[index];
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Remove from favorites?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          content: Text(
            'Do you want to remove "${recipe.name}" from your saved recipes?',
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF4B5563),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Unfavorite'),
            ),
          ],
        );
      },
    );
    _isUnfavoriteDialogOpen = false;

    if (shouldRemove != true || !mounted) return;

    setState(() {
      _recipes.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${recipe.name} removed from favorites.')),
    );
  }

  Future<String?> _showEditNoteDialog({required String initialNote}) async {
    final controller = TextEditingController(text: initialNote);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: isDarkMode ? const Color(0xFF0B1B38) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Note',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode
                        ? const Color(0xFFF8FAFC)
                        : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF102647)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode
                          ? const Color(0xFF274A73)
                          : const Color(0xFFD1D5DB),
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    minLines: 3,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Write your note...',
                      hintStyle: TextStyle(
                        color: isDarkMode
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF6B7280),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(10),
                      isDense: true,
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF374151),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(34),
                          backgroundColor: isDarkMode
                              ? const Color(0xFF102647)
                              : const Color(0xFFF3F4F6),
                          foregroundColor: isDarkMode
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF374151),
                          side: BorderSide(
                            color: isDarkMode
                                ? const Color(0xFF274A73)
                                : const Color(0xFFD1D5DB),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.of(context).pop(controller.text),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(34),
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Save Note'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    controller.dispose();
    return result;
  }

  int get _savedCount => _recipes.length;

  int get _noteCount =>
      _recipes.where((r) => (r.note ?? '').trim().isNotEmpty).length;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_selectedRecipeIndex != null) {
      final recipe = _recipes[_selectedRecipeIndex!];
      final cardColor =
          _kFavoriteCardColors[_selectedRecipeIndex! %
              _kFavoriteCardColors.length];

      return RecipeDetailView(
        recipe: RecipeDetailData(
          name: recipe.name,
          cookingMinutes: recipe.duration,
          calories: recipe.calories,
          ingredients: recipe.ingredients,
          steps: recipe.instructions,
          labels: recipe.tags,
        ),
        cardColor: cardColor,
        onBack: _closeRecipeDetails,
        isSaved: _savedCurrentRecipe,
        onToggleSave: _toggleSaveInDetail,
      );
    }

    return Container(
      color: isDarkMode ? const Color(0xFF07152D) : const Color(0xFFE5E7EB),
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          Row(
            children: [
              const Icon(Icons.favorite, size: 20, color: Color(0xFFE11D48)),
              const SizedBox(width: 6),
              Text(
                'Favorites',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Saved recipes with your notes',
            style: TextStyle(
              fontSize: 10.5,
              color: isDarkMode
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  value: '$_savedCount',
                  label: 'Saved',
                  isDarkMode: isDarkMode,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  value: '$_noteCount',
                  label: 'With Notes',
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_recipes.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD1D5DB)),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.favorite_border,
                    color: Color(0xFF9CA3AF),
                    size: 28,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No favorites yet',
                    style: TextStyle(
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ...List.generate(_recipes.length, (index) {
            final recipe = _recipes[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _FavoriteRecipeCard(
                recipe: recipe,
                cardColor: isDarkMode
                    ? const Color(0xFF0B1B38)
                    : _kFavoriteCardColors[index % _kFavoriteCardColors.length],
                isDarkMode: isDarkMode,
                onTap: () => _openRecipeDetails(index),
                onEditNote: () => _onEditNote(index),
                onUnfavorite: () => _onUnfavorite(index),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.value,
    required this.label,
    required this.isDarkMode,
  });

  final String value;
  final String label;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0B1B38) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF274A73) : const Color(0xFFD1D5DB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: isDarkMode
                  ? const Color(0xFFF8FAFC)
                  : const Color(0xFF111827),
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDarkMode
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteRecipeCard extends StatelessWidget {
  const _FavoriteRecipeCard({
    required this.recipe,
    required this.cardColor,
    required this.isDarkMode,
    required this.onTap,
    required this.onEditNote,
    required this.onUnfavorite,
  });

  final _FavoriteRecipe recipe;
  final Color cardColor;
  final bool isDarkMode;
  final VoidCallback onTap;
  final VoidCallback onEditNote;
  final VoidCallback onUnfavorite;

  @override
  Widget build(BuildContext context) {
    final noteBg = isDarkMode
        ? const Color(0xFF2F2A18)
        : const Color(0xFFFFFBEB);
    final noteBorder = isDarkMode
        ? const Color(0xFF6B5C2B)
        : const Color(0xFFF2C94C);
    final noteText = isDarkMode
        ? const Color(0xFFFDE68A)
        : const Color(0xFF92400E);

    return Material(
      color: isDarkMode ? const Color(0xFF07152D) : cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode
                  ? const Color(0xFF274A73)
                  : const Color(0xFFD1D5DB),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipe.name,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 13,
                    color: isDarkMode
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF4B5563),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${recipe.duration} min',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDarkMode
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.local_fire_department_outlined,
                    size: 13,
                    color: isDarkMode
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF4B5563),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${recipe.calories} cal',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDarkMode
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
              if ((recipe.note ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: noteBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: noteBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sticky_note_2_outlined,
                        size: 13,
                        color: noteText,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          recipe.note!,
                          style: TextStyle(fontSize: 10.5, color: noteText),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEditNote,
                      icon: const Icon(Icons.edit_note_outlined, size: 14),
                      label: Text(
                        recipe.note == null ? 'Add Note' : 'Edit Note',
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(30),
                        backgroundColor: isDarkMode
                            ? const Color(0xFF102647)
                            : const Color(0xFFF3F4F6),
                        foregroundColor: isDarkMode
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF374151),
                        side: BorderSide(
                          color: isDarkMode
                              ? const Color(0xFF274A73)
                              : const Color(0xFFD1D5DB),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 34,
                    height: 30,
                    child: OutlinedButton(
                      onPressed: onUnfavorite,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: isDarkMode
                            ? const Color(0xFF102647)
                            : const Color(0xFFF9FAFB),
                        side: BorderSide(
                          color: isDarkMode
                              ? const Color(0xFF274A73)
                              : const Color(0xFFD1D5DB),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Color(0xFFE11D48),
                        size: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteRecipe {
  const _FavoriteRecipe({
    required this.name,
    required this.duration,
    required this.calories,
    required this.note,
    required this.ingredients,
    required this.instructions,
    required this.tags,
  });

  final String name;
  final int duration;
  final int calories;
  final String? note;
  final String ingredients;
  final String instructions;
  final List<String> tags;

  List<String> get ingredientItems => ingredients
      .split('\n')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  List<String> get stepItems => instructions
      .split('\n')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  _FavoriteRecipe copyWith({
    String? name,
    int? duration,
    int? calories,
    String? note,
    String? ingredients,
    String? instructions,
    List<String>? tags,
  }) {
    return _FavoriteRecipe(
      name: name ?? this.name,
      duration: duration ?? this.duration,
      calories: calories ?? this.calories,
      note: note,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      tags: tags ?? this.tags,
    );
  }
}
