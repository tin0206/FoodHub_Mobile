import 'package:flutter/material.dart';
import 'package:foodhub_mobile/models/ai.dart';
import 'package:foodhub_mobile/widgets/recs/markdown_reply.dart';

class RecipeSuggestionList extends StatelessWidget {
  const RecipeSuggestionList({
    super.key,
    required this.recipes,
    required this.isDarkMode,
    this.onOpenRecipe,
  });

  final List<RagRecipeModel> recipes;
  final bool isDarkMode;
  final void Function(RagRecipeModel recipe)? onOpenRecipe;

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) return const SizedBox.shrink();

    // When parent already renders markdown CTAs, keep a compact secondary list
    // only if we still want expandable ingredient previews.
    final titleColor =
        isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF111827);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(
              Icons.restaurant_menu_rounded,
              size: 15,
              color: Color(0xFF059669),
            ),
            const SizedBox(width: 6),
            Text(
              'Suggested recipes',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...recipes.map(
          (recipe) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RecipeSuggestionCard(
              recipe: recipe,
              isDarkMode: isDarkMode,
              onOpenDetails: onOpenRecipe == null
                  ? null
                  : () => onOpenRecipe!(recipe),
            ),
          ),
        ),
      ],
    );
  }
}

class RecipeSuggestionCard extends StatefulWidget {
  const RecipeSuggestionCard({
    super.key,
    required this.recipe,
    required this.isDarkMode,
    this.onOpenDetails,
  });

  final RagRecipeModel recipe;
  final bool isDarkMode;
  final VoidCallback? onOpenDetails;

  @override
  State<RecipeSuggestionCard> createState() => _RecipeSuggestionCardState();
}

class _RecipeSuggestionCardState extends State<RecipeSuggestionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final isDark = widget.isDarkMode;
    final bg = isDark ? const Color(0xFF141414) : const Color(0xFFF0FDF4);
    final border = const Color(0xFF059669).withValues(alpha: 0.28);
    final primary =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final secondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.onOpenDetails != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: RecipeDetailCtaButton(
                title: recipe.title,
                isDarkMode: isDark,
                onPressed: widget.onOpenDetails!,
              ),
            ),
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.onOpenDetails == null)
                          Text(
                            recipe.title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          ),
                        if (recipe.estimatedServings != null) ...[
                          if (widget.onOpenDetails == null)
                            const SizedBox(height: 2),
                          Text(
                            'Serves ${recipe.estimatedServings}'
                            '${_expanded ? '' : ' · tap for preview'}',
                            style: TextStyle(fontSize: 11, color: secondary),
                          ),
                        ] else if (widget.onOpenDetails == null)
                          Text(
                            'Tap for preview',
                            style: TextStyle(fontSize: 11, color: secondary),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: secondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (recipe.ingredients.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Wrap(
                spacing: 5,
                runSpacing: 5,
                children: recipe.ingredients.take(8).map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E1E1E)
                          : Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFF059669).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(fontSize: 10.5, color: primary),
                    ),
                  );
                }).toList(),
              ),
            ),
          if (_expanded) ...[
            if (recipe.directions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Steps',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...recipe.directions.asMap().entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${e.key + 1}.',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF059669),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                e.value,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            if (recipe.dietaryRestrictions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: recipe.dietaryRestrictions
                      .map(
                        (d) => Chip(
                          label: Text(d, style: const TextStyle(fontSize: 10)),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: isDark
                              ? const Color(0xFF1E1E1E)
                              : const Color(0xFFECFDF5),
                          side: BorderSide(
                            color: const Color(0xFF059669)
                                .withValues(alpha: 0.3),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
