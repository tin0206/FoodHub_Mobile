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
    final t = recipeCardTheme(recipe.id, recipe.labels);
    final primaryText = isDarkMode
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF111827);

    final card = Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF141414) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.45)
                : t.start.withValues(alpha: 0.18),
            blurRadius: isDarkMode ? 14 : 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RecipeImageHeader(
            imageUrl: recipe.imageUrl,
            recipeId: recipe.id,
            labels: recipe.labels,
            height: 120,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
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
                const SizedBox(height: 5),
                _StatsRow(recipe: recipe, isDarkMode: isDarkMode),
                if (recipe.labels.isNotEmpty) ...[
                  const SizedBox(height: 5),
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
                              boxShadow: [
                                BoxShadow(
                                  color: t.start.withValues(alpha: isDarkMode ? 0.12 : 0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.recipe, required this.isDarkMode});

  final RecipeModel recipe;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final divColor =
        isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final iconColor =
        isDarkMode ? const Color(0xFF64748B) : const Color(0xFF9CA3AF);

    Widget dot() => Container(
          width: 1,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 7),
          color: divColor,
        );

    return Row(
      children: [
        Icon(Icons.schedule_rounded, size: 12, color: iconColor),
        const SizedBox(width: 3),
        Text(
          '${recipe.cookingMinutes} min',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        dot(),
        Icon(
          Icons.local_fire_department_outlined,
          size: 12,
          color: const Color(0xFFEF4444).withValues(alpha: 0.8),
        ),
        const SizedBox(width: 3),
        Text(
          '${recipe.calories} kcal',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

