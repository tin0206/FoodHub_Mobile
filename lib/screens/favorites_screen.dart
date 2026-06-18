import 'package:flutter/material.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  void _onOpenRecipe(String recipeName) {
    _showComingSoon('Open favorite recipe: $recipeName');
  }

  void _onEditNote(String recipeName) {
    _showComingSoon('Edit note for $recipeName');
  }

  void _onUnfavorite(String recipeName) {
    _showComingSoon('Remove $recipeName from favorites');
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature will be implemented later.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            const Icon(Icons.favorite, color: Color(0xFFE11D48)),
            const SizedBox(width: 8),
            Text(
              'Favorite Recipes',
              style: TextStyle(
                fontSize: 38 / 2,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Your saved recipes with personal notes',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          childAspectRatio: 1.45,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            _StatCard(value: '3', label: 'Total Saved'),
            _StatCard(value: '1', label: 'With Notes'),
            _StatCard(value: '1', label: 'High Protein'),
            _StatCard(value: '1', label: 'Quick Meals'),
          ],
        ),
        const SizedBox(height: 12),
        _FavoriteRecipeCard(
          recipeName: 'Quinoa Buddha Bowl',
          duration: '25 min',
          calories: '420 cal',
          tags: const ['Vegetarian', 'Healthy'],
          note: 'Great for meal prep! Double the tahini dressing.',
          onTap: () => _onOpenRecipe('Quinoa Buddha Bowl'),
          onEditNote: () => _onEditNote('Quinoa Buddha Bowl'),
          onToggleFavorite: () => _onUnfavorite('Quinoa Buddha Bowl'),
        ),
        _FavoriteRecipeCard(
          recipeName: 'Grilled Chicken & Veggies',
          duration: '35 min',
          calories: '450 cal',
          tags: const ['High Protein', 'Keto'],
          note: null,
          onTap: () => _onOpenRecipe('Grilled Chicken & Veggies'),
          onEditNote: () => _onEditNote('Grilled Chicken & Veggies'),
          onToggleFavorite: () => _onUnfavorite('Grilled Chicken & Veggies'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 42 / 2,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          Text(label, style: TextStyle(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _FavoriteRecipeCard extends StatelessWidget {
  const _FavoriteRecipeCard({
    required this.recipeName,
    required this.duration,
    required this.calories,
    required this.tags,
    required this.note,
    required this.onTap,
    required this.onEditNote,
    required this.onToggleFavorite,
  });

  final String recipeName;
  final String duration;
  final String calories;
  final List<String> tags;
  final String? note;
  final VoidCallback onTap;
  final VoidCallback onEditNote;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      recipeName,
                      style: TextStyle(
                        fontSize: 28 / 2,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onToggleFavorite,
                    icon: const Icon(Icons.favorite_border),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    duration,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.local_fire_department_outlined,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    calories,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ),
                    )
                    .toList(),
              ),
              if (note != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sticky_note_2_outlined,
                        color: Color(0xFFD97706),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          note!,
                          style: const TextStyle(color: Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEditNote,
                      icon: const Icon(Icons.edit_note),
                      label: Text(note == null ? 'Add Note' : 'Edit Note'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: onToggleFavorite,
                    icon: const Icon(Icons.favorite, color: Color(0xFFE11D48)),
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
