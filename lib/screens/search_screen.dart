import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // TODO: Implement API search and filtering logic.
  }

  void _onRecipePressed(String recipeName) {
    _showComingSoon('Open recipe details for $recipeName');
  }

  void _onToggleFavorite(String recipeName) {
    _showComingSoon('Toggle favorite for $recipeName');
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
        Text(
          'Search Recipes',
          style: TextStyle(
            fontSize: 42 / 2,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Find the perfect recipe for your next meal',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search by recipe name, ingredient...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              onPressed: () => _showComingSoon('Advanced filters'),
              icon: const Icon(Icons.filter_alt_outlined),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Showing 4 results',
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        _RecipeCard(
          name: 'Quinoa Buddha Bowl',
          duration: '25 min',
          calories: '420 cal',
          tags: const ['Vegetarian', 'Healthy'],
          onPressed: () => _onRecipePressed('Quinoa Buddha Bowl'),
          onFavorite: () => _onToggleFavorite('Quinoa Buddha Bowl'),
        ),
        _RecipeCard(
          name: 'Classic Italian Pasta',
          duration: '30 min',
          calories: '580 cal',
          tags: const ['Italian', 'Comfort Food'],
          onPressed: () => _onRecipePressed('Classic Italian Pasta'),
          onFavorite: () => _onToggleFavorite('Classic Italian Pasta'),
        ),
        _RecipeCard(
          name: 'Grilled Chicken & Veggies',
          duration: '35 min',
          calories: '450 cal',
          tags: const ['High Protein', 'Keto'],
          onPressed: () => _onRecipePressed('Grilled Chicken & Veggies'),
          onFavorite: () => _onToggleFavorite('Grilled Chicken & Veggies'),
        ),
        _RecipeCard(
          name: 'Fresh Garden Salad',
          duration: '15 min',
          calories: '280 cal',
          tags: const ['Vegan', 'Quick Meal'],
          onPressed: () => _onRecipePressed('Fresh Garden Salad'),
          onFavorite: () => _onToggleFavorite('Fresh Garden Salad'),
        ),
      ],
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.name,
    required this.duration,
    required this.calories,
    required this.tags,
    required this.onPressed,
    required this.onFavorite,
  });

  final String name;
  final String duration;
  final String calories;
  final List<String> tags;
  final VoidCallback onPressed;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 28 / 2,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onFavorite,
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
            ],
          ),
        ),
      ),
    );
  }
}
