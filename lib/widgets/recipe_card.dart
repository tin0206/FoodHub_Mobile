import 'package:flutter/material.dart';
import 'package:foodhub_mobile/models/recipe.dart';
import 'package:foodhub_mobile/widgets/recipe_detail_view.dart';
import 'package:foodhub_mobile/widgets/recipe_image.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.onAction,
    this.footer,
    this.margin,
  });

  final RecipeModel recipe;
  final VoidCallback? onTap;
  final VoidCallback? onAction;
  final Widget? footer;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final t = recipeCardTheme(recipe.labels);
    final primaryText = isDarkMode
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF111827);

    final card = Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0B1B38) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDarkMode ? Border.all(color: const Color(0xFF274A73)) : null,
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: t.start.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              RecipeImageHeader(
                imageUrl: recipe.imageUrl,
                labels: recipe.labels,
              ),
              Positioned(
                top: 10,
                right: 10,
                child: _MetaPill(
                  cookingMinutes: recipe.cookingMinutes,
                  calories: recipe.calories,
                  onImage: recipe.imageUrl != null &&
                      recipe.imageUrl!.isNotEmpty,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        recipe.name,
                        style: TextStyle(
                          color: primaryText,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: -0.3,
                          height: 1.25,
                        ),
                      ),
                    ),
                    if (onAction != null) ...[
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: onAction,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [t.start, t.end],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: t.start.withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (recipe.labels.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: recipe.labels
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? t.start.withValues(alpha: 0.15)
                                  : t.start.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: t.start.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode
                                    ? t.start.withValues(alpha: 0.9)
                                    : t.end,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ] else
                  const SizedBox(height: 2),
                if (footer != null) ...[
                  const SizedBox(height: 10),
                  footer!,
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (margin != null) {
      return Padding(
        padding: margin!,
        child: onTap != null
            ? GestureDetector(onTap: onTap, child: card)
            : card,
      );
    }

    return onTap != null ? GestureDetector(onTap: onTap, child: card) : card;
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.cookingMinutes,
    required this.calories,
    required this.onImage,
  });

  final int cookingMinutes;
  final int calories;
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: onImage
            ? Colors.black.withValues(alpha: 0.45)
            : Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 11,
            color: Colors.white.withValues(alpha: onImage ? 0.95 : 1),
          ),
          const SizedBox(width: 3),
          Text(
            '${cookingMinutes}m',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.local_fire_department_outlined,
            size: 11,
            color: Colors.white.withValues(alpha: onImage ? 0.95 : 1),
          ),
          const SizedBox(width: 3),
          Text(
            '$calories',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
