import 'package:flutter/material.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final List<_FavoriteRecipe> _recipes = [
    const _FavoriteRecipe(
      name: 'Quinoa Buddha Bowl',
      duration: '25 min',
      calories: '420 cal',
      note: 'Great for meal prep! Double the tahini dressing.',
    ),
    const _FavoriteRecipe(
      name: 'Grilled Chicken & Veggies',
      duration: '35 min',
      calories: '450 cal',
      note: null,
    ),
  ];

  void _onOpenRecipe(String recipeName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Open favorite recipe: $recipeName')),
    );
  }

  Future<void> _onEditNote(int index) async {
    final current = _recipes[index];
    final updatedNote = await _showEditNoteDialog(
      initialNote: current.note ?? '',
    );
    if (!mounted || updatedNote == null) return;

    setState(() {
      _recipes[index] = current.copyWith(
        note: updatedNote.trim().isEmpty ? null : updatedNote.trim(),
      );
    });
  }

  Future<String?> _showEditNoteDialog({required String initialNote}) async {
    final controller = TextEditingController(text: initialNote);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Note',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                  ),
                  child: TextField(
                    controller: controller,
                    minLines: 3,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Write your note...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(10),
                      isDense: true,
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF374151),
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
                          backgroundColor: const Color(0xFFF3F4F6),
                          foregroundColor: const Color(0xFF374151),
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
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
    return Container(
      color: const Color(0xFFE5E7EB),
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          Row(
            children: const [
              Icon(Icons.favorite, size: 14, color: Color(0xFFE11D48)),
              SizedBox(width: 6),
              Text(
                'Favorites',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Saved recipes with your notes',
            style: TextStyle(fontSize: 10.5, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(value: '$_savedCount', label: 'Saved'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(value: '$_noteCount', label: 'With Notes'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(_recipes.length, (index) {
            final recipe = _recipes[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _FavoriteRecipeCard(
                recipe: recipe,
                onTap: () => _onOpenRecipe(recipe.name),
                onEditNote: () => _onEditNote(index),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

class _FavoriteRecipeCard extends StatelessWidget {
  const _FavoriteRecipeCard({
    required this.recipe,
    required this.onTap,
    required this.onEditNote,
  });

  final _FavoriteRecipe recipe;
  final VoidCallback onTap;
  final VoidCallback onEditNote;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipe.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${recipe.duration} - ${recipe.calories}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563)),
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
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF2C94C)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sticky_note_2_outlined,
                        size: 13,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          recipe.note!,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF92400E),
                          ),
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
                        backgroundColor: const Color(0xFFF3F4F6),
                        foregroundColor: const Color(0xFF374151),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
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
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: const Color(0xFFF9FAFB),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
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
  });

  final String name;
  final String duration;
  final String calories;
  final String? note;

  _FavoriteRecipe copyWith({
    String? name,
    String? duration,
    String? calories,
    String? note,
  }) {
    return _FavoriteRecipe(
      name: name ?? this.name,
      duration: duration ?? this.duration,
      calories: calories ?? this.calories,
      note: note,
    );
  }
}
