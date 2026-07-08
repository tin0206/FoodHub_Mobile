import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:foodhub_mobile/config/api_config.dart';
import 'package:foodhub_mobile/widgets/recipe_detail_view.dart';

class RecipeImageHeader extends StatelessWidget {
  const RecipeImageHeader({
    super.key,
    required this.imageUrl,
    required this.labels,
    this.height = 150,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(20)),
    this.showPlaceholderEmoji = true,
  });

  final String? imageUrl;
  final List<String> labels;
  final double height;
  final BorderRadius borderRadius;
  final bool showPlaceholderEmoji;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = recipeCardTheme(labels);
    final resolvedUrl = ApiConfig.resolveImageUrl(imageUrl);

    if (resolvedUrl.isEmpty) {
      return _PlaceholderHeader(
        theme: theme,
        height: height,
        borderRadius: borderRadius,
        isDarkMode: isDarkMode,
        showEmoji: showPlaceholderEmoji,
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CachedNetworkImage(
          imageUrl: resolvedUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => _PlaceholderHeader(
            theme: theme,
            height: height,
            borderRadius: BorderRadius.zero,
            isDarkMode: isDarkMode,
            showEmoji: false,
            showShimmer: true,
          ),
          errorWidget: (context, url, error) => _PlaceholderHeader(
            theme: theme,
            height: height,
            borderRadius: BorderRadius.zero,
            isDarkMode: isDarkMode,
            showEmoji: showPlaceholderEmoji,
          ),
        ),
      ),
    );
  }
}

class _PlaceholderHeader extends StatelessWidget {
  const _PlaceholderHeader({
    required this.theme,
    required this.height,
    required this.borderRadius,
    required this.isDarkMode,
    this.showEmoji = true,
    this.showShimmer = false,
  });

  final ({String emoji, Color start, Color end}) theme;
  final double height;
  final BorderRadius borderRadius;
  final bool isDarkMode;
  final bool showEmoji;
  final bool showShimmer;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  theme.start.withValues(alpha: 0.28),
                  theme.end.withValues(alpha: 0.14),
                ]
              : [theme.start, theme.end],
        ),
        borderRadius: borderRadius,
      ),
      child: showShimmer
          ? Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            )
          : showEmoji
              ? Center(
                  child: Text(
                    theme.emoji,
                    style: const TextStyle(fontSize: 48),
                  ),
                )
              : null,
    );
  }
}
