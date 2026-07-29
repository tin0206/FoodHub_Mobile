import 'package:flutter/material.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';
import 'package:foodhub_mobile/models/favorite.dart';
import 'package:foodhub_mobile/services/api_exception.dart';
import 'package:foodhub_mobile/services/favorite_service.dart';
import 'package:foodhub_mobile/widgets/favorite_toast.dart';
import 'package:foodhub_mobile/widgets/recipe_card.dart';
import 'package:foodhub_mobile/widgets/recipe_detail_view.dart';


class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, this.onDetailModeChanged});

  final ValueChanged<bool>? onDetailModeChanged;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _favoriteService = FavoriteService();
  List<FavoriteModel> _favorites = [];
  bool _isLoading = true;
  String? _loadError;

  int? _selectedRecipeIndex;
  bool _savedCurrentRecipe = true;
  bool _isUnfavoriteDialogOpen = false;
  bool _isNoteDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    FavoriteService.changes.addListener(_onExternalChange);
  }

  void _onExternalChange() {
    // Only reload when not viewing a detail (detail manages its own state)
    if (mounted && _selectedRecipeIndex == null) _loadFavorites();
  }

  @override
  void dispose() {
    FavoriteService.changes.removeListener(_onExternalChange);
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final favorites = await _favoriteService.listFavorites();
      if (!mounted) return;
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = S.of(context).unableToLoadFavorites;
        _isLoading = false;
      });
    }
  }

  void _openRecipeDetails(int index) {
    if (index < 0 || index >= _favorites.length) return;
    widget.onDetailModeChanged?.call(true);
    setState(() {
      _selectedRecipeIndex = index;
      _savedCurrentRecipe = true;
    });
  }

  Future<void> _closeRecipeDetails() async {
    if (_selectedRecipeIndex == null) return;

    final index = _selectedRecipeIndex!;
    final favorite = _favorites[index];
    final removedName = favorite.recipe.name;

    if (!_savedCurrentRecipe) {
      try {
        await _favoriteService.deleteFavorite(favorite.id);
        if (!mounted) return;
        setState(() => _favorites.removeAt(index));
        _showRemovedToast(removedName);
      } on ApiException catch (e) {
        if (!mounted) return;
        showErrorToast(context, e.message);
        return;
      }
    }

    widget.onDetailModeChanged?.call(false);
    setState(() {
      _selectedRecipeIndex = null;
      _savedCurrentRecipe = true;
    });
  }

  Future<void> _toggleSaveInDetail() async {
    final index = _selectedRecipeIndex;
    if (index == null || index >= _favorites.length) return;

    if (_savedCurrentRecipe) {
      setState(() => _savedCurrentRecipe = false);
      return;
    }

    try {
      await _favoriteService.addFavorite(recipeId: _favorites[index].recipeId);
      if (!mounted) return;
      setState(() => _savedCurrentRecipe = true);
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorToast(context, e.message);
    }
  }

  Future<void> _onEditNote(int index) async {
    if (_isNoteDialogOpen) return;

    _isNoteDialogOpen = true;
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      _isNoteDialogOpen = false;
      return;
    }

    final current = _favorites[index];
    final cardColor = recipeCardTheme(current.recipe.id, current.recipe.labels).start;
    final updatedNote = await _showEditNoteDialog(
      initialNote: current.note ?? '',
      accentColor: cardColor,
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

    try {
      final updated = await _favoriteService.updateFavorite(
        favoriteId: current.id,
        note: updatedNote.trim().isEmpty ? '' : updatedNote.trim(),
      );
      if (!mounted) return;
      setState(() {
        _favorites[index] = updated;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorToast(context, e.message);
    }
  }

  Future<void> _onUnfavorite(int index) async {
    if (_isUnfavoriteDialogOpen) return;

    _isUnfavoriteDialogOpen = true;
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      _isUnfavoriteDialogOpen = false;
      return;
    }

    final favorite = _favorites[index];
    final recipe = favorite.recipe;
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF141414) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            S.of(context).removeFromFavorites,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
            ),
          ),
          content: Text(
            S.of(context).removeConfirm(recipe.name),
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF4B5563),
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
              child: Text(S.of(context).cancel),
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
              child: Text(S.of(context).unfavoriteLabel),
            ),
          ],
        );
      },
    );
    _isUnfavoriteDialogOpen = false;

    if (shouldRemove != true || !mounted) return;

    try {
      await _favoriteService.deleteFavorite(favorite.id);
      if (!mounted) return;
      setState(() => _favorites.removeAt(index));
      _showRemovedToast(recipe.name);
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorToast(context, e.message);
    }
  }

  void _showRemovedToast(String recipeName) {
    showFavoriteToast(context, recipeName: recipeName, saved: false);
  }

  Future<String?> _showEditNoteDialog({
    required String initialNote,
    required Color accentColor,
  }) async {
    final controller = TextEditingController(text: initialNote);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: isDarkMode ? const Color(0xFF141414) : Colors.white,
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
                  S.of(context).myNote,
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
                        ? const Color(0xFF1E1E1E)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: isDarkMode
                        ? null
                        : Border.all(color: const Color(0xFFD1D5DB)),
                  ),
                  child: TextField(
                    controller: controller,
                    minLines: 3,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: S.of(context).writeNoteHint,
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
                              ? const Color(0xFF1E1E1E)
                              : const Color(0xFFF3F4F6),
                          foregroundColor: isDarkMode
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF374151),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        child: Text(S.of(context).cancel),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.of(context).pop(controller.text),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(34),
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Text(S.of(context).saveNote),
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

  int get _savedCount => _favorites.length;

  int get _noteCount =>
      _favorites.where((r) => (r.note ?? '').trim().isNotEmpty).length;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_selectedRecipeIndex != null) {
      final favorite = _favorites[_selectedRecipeIndex!];
      final recipe = favorite.recipe;

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) { if (!didPop) _closeRecipeDetails(); },
        child: RecipeDetailView(
          recipe: recipe.toDetailData(),
          cardColor: recipeCardTheme(recipe.id, recipe.labels).start,
          onBack: _closeRecipeDetails,
          isSaved: _savedCurrentRecipe,
          onToggleSave: _toggleSaveInDetail,
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF059669)),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loadError!),
            const SizedBox(height: 8),
            FilledButton(onPressed: _loadFavorites, child: Text(S.of(context).retry)),
          ],
        ),
      );
    }

    final s = S.of(context);
    return Container(
      color: isDarkMode ? const Color(0xFF0A0A0A) : const Color(0xFFE5E7EB),
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          Row(
            children: [
              const Icon(Icons.favorite, size: 20, color: Color(0xFFE11D48)),
              const SizedBox(width: 6),
              Text(
                s.favoritesTitle,
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
            s.savedRecipesWithNotes,
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
                  label: s.savedLabel,
                  isDarkMode: isDarkMode,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  value: '$_noteCount',
                  label: s.withNotesLabel,
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_favorites.isEmpty)
            Builder(builder: (context) {
              final isDarkMode = Theme.of(context).brightness == Brightness.dark;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF141414) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDarkMode ? 0.35 : 0.06),
                      blurRadius: isDarkMode ? 10 : 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.favorite_border,
                      color: Color(0xFF9CA3AF),
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      S.of(context).noFavoritesYet,
                      style: TextStyle(
                        color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF374151),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ...List.generate(_favorites.length, (index) {
            final favorite = _favorites[index];
            final recipe = favorite.recipe;
            final isDarkMode =
                Theme.of(context).brightness == Brightness.dark;
            final noteBg = isDarkMode
                ? const Color(0xFF2F2A18)
                : const Color(0xFFFFFBEB);
            final noteBorder = isDarkMode
                ? const Color(0xFF6B5C2B)
                : const Color(0xFFF2C94C);
            final noteText = isDarkMode
                ? const Color(0xFFFDE68A)
                : const Color(0xFF92400E);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RecipeCard(
                recipe: recipe,
                onTap: () => _openRecipeDetails(index),
                onAction: () => _openRecipeDetails(index),
                footer: Column(
                  children: [
                    if ((favorite.note ?? '').isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: noteBg,
                          borderRadius: BorderRadius.circular(10),
                          border: isDarkMode ? null : Border.all(color: noteBorder),
                          boxShadow: isDarkMode
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
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
                                favorite.note!,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: noteText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _onEditNote(index),
                            icon: const Icon(
                              Icons.edit_note_outlined,
                              size: 14,
                            ),
                            label: Text(
                              favorite.note == null ? s.addNote : s.editNote,
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(32),
                              backgroundColor: isDarkMode
                                  ? const Color(0xFF1E1E1E)
                                  : const Color(0xFFF3F4F6),
                              foregroundColor: isDarkMode
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF374151),
                              side: isDarkMode
                                  ? BorderSide.none
                                  : const BorderSide(
                                      color: Color(0xFFD1D5DB),
                                    ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 34,
                          height: 32,
                          child: OutlinedButton(
                            onPressed: () => _onUnfavorite(index),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: isDarkMode
                                  ? const Color(0xFF1E1E1E)
                                  : const Color(0xFFF9FAFB),
                              side: isDarkMode
                                  ? BorderSide.none
                                  : const BorderSide(
                                      color: Color(0xFFD1D5DB),
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
        color: isDarkMode ? const Color(0xFF141414) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.35 : 0.04),
            blurRadius: isDarkMode ? 8 : 6,
            offset: const Offset(0, 2),
          ),
        ],
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

