import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';
import 'package:foodhub_mobile/models/favorite.dart';
import 'package:foodhub_mobile/models/recipe.dart';
import 'package:foodhub_mobile/services/ai_service.dart';
import 'package:foodhub_mobile/services/api_exception.dart';
import 'package:foodhub_mobile/services/favorite_service.dart';
import 'package:foodhub_mobile/services/meal_service.dart';
import 'package:foodhub_mobile/services/recipe_service.dart';
import 'package:foodhub_mobile/widgets/favorite_toast.dart';
import 'package:foodhub_mobile/widgets/meal_slot_picker.dart';
import 'package:foodhub_mobile/widgets/recipe_card.dart';
import 'package:foodhub_mobile/widgets/recipe_detail_view.dart';
import 'package:image_picker/image_picker.dart';

/// "My Recipes" (personal) and "Favorites" (saved from the catalog), grouped
/// into one screen with two tabs since they're both "recipes I keep coming
/// back to" — personal recipes just happen to be ones I wrote myself.
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key, this.onDetailModeChanged});

  final ValueChanged<bool>? onDetailModeChanged;

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  int _tabIndex = 0; // 0 = Personal Recipes (default), 1 = Favorites

  // ── Personal recipes (moved from the home screen) ────────────────────────
  final _recipeService = RecipeService();
  final List<RecipeModel> _recipes = [];
  bool _isLoadingRecipes = true;
  String? _recipesError;
  bool _isAddingRecipe = false;
  RecipeModel? _selectedRecipe;
  int? _selectedRecipeCardIndex;

  // ── Favorites ──────────────────────────────────────────────────────────────
  final _favoriteService = FavoriteService();
  final _mealService = MealService();
  List<FavoriteModel> _favorites = [];
  bool _isLoadingFavorites = true;
  String? _favoritesError;

  int? _selectedFavoriteIndex;
  bool _savedCurrentRecipe = true;
  bool _isUnfavoriteDialogOpen = false;
  bool _isNoteDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
    _loadFavorites();
    RecipeService.changes.addListener(_onRecipesExternalChange);
    FavoriteService.changes.addListener(_onFavoritesExternalChange);
    LangScope.current.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    RecipeService.changes.removeListener(_onRecipesExternalChange);
    FavoriteService.changes.removeListener(_onFavoritesExternalChange);
    LangScope.current.removeListener(_onLanguageChanged);
    super.dispose();
  }

  /// A recipe was created/updated/deleted — possibly from another screen
  /// (e.g. editing a public recipe forks it into "my recipes"). Refetch so
  /// it shows up here too.
  void _onRecipesExternalChange() {
    if (mounted && _selectedRecipe == null) _loadRecipes();
  }

  // Recipe content is localized server-side by the `lang` query param —
  // refetch so it's not left showing the previous language after a switch.
  void _onLanguageChanged() {
    if (!mounted) return;
    if (_selectedRecipe == null) _loadRecipes();
    if (_selectedFavoriteIndex == null) _loadFavorites();
  }

  void _onFavoritesExternalChange() {
    // Only reload when not viewing a detail (detail manages its own state)
    if (mounted && _selectedFavoriteIndex == null) _loadFavorites();
  }

  // ── Personal recipes: data + actions ──────────────────────────────────────

  Future<void> _loadRecipes() async {
    setState(() {
      _isLoadingRecipes = true;
      _recipesError = null;
    });
    try {
      final mine = await _recipeService.listRecipes(mine: true);
      if (!mounted) return;
      setState(() {
        _recipes
          ..clear()
          ..addAll(mine);
        _isLoadingRecipes = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _recipesError = e.message;
        _isLoadingRecipes = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recipesError = S.of(context).unableToLoadRecipes;
        _isLoadingRecipes = false;
      });
    }
  }

  void _onAddRecipePressed() {
    setState(() {
      _isAddingRecipe = true;
      _selectedRecipe = null;
      _selectedRecipeCardIndex = null;
    });
  }

  void _onCancelAddRecipe() {
    setState(() => _isAddingRecipe = false);
  }

  void _onSaveRecipe(RecipeModel recipe) {
    setState(() {
      _recipes.insert(0, recipe);
      _isAddingRecipe = false;
    });
  }

  void _openRecipeDetails(RecipeModel recipe, int cardIndex) {
    widget.onDetailModeChanged?.call(true);
    setState(() {
      _isAddingRecipe = false;
      _selectedRecipe = recipe;
      _selectedRecipeCardIndex = cardIndex;
    });
  }

  void _closeRecipeDetails() {
    widget.onDetailModeChanged?.call(false);
    setState(() {
      _selectedRecipe = null;
      _selectedRecipeCardIndex = null;
    });
  }

  Future<void> _addRecipeToPlan(RecipeModel recipe) async {
    final s = S.of(context);
    final slotKey = await showMealSlotPicker(context, recipeName: recipe.title);
    if (slotKey == null || !mounted) return;
    try {
      await _mealService.addRecipeToSlot(slotKey: slotKey, recipeId: recipe.id);
      if (mounted) showSuccessToast(context, s.addedToPlan);
    } on ApiException catch (e) {
      if (mounted) showErrorToast(context, e.message);
    }
  }

  Future<bool> _onSaveEditedRecipe(RecipeDetailData data) async {
    final index = _selectedRecipeCardIndex;
    final current = _selectedRecipe;
    if (index == null ||
        current == null ||
        index < 0 ||
        index >= _recipes.length) {
      return false;
    }

    // Optimistic image update — show new image behind loading instead of old one.
    if (data.imageUrl != null && data.imageUrl != current.imageUrl) {
      setState(() {
        _selectedRecipe = RecipeModel(
          id: current.id,
          title: current.title,
          imageUrl: data.imageUrl,
          ingredients: current.ingredients,
          directions: current.directions,
          ner: current.ner,
          estimatedServings: current.estimatedServings,
          dietaryRestrictions: current.dietaryRestrictions,
          createdBy: current.createdBy,
          visibility: current.visibility,
          locale: current.locale,
          mappedIngredients: current.mappedIngredients,
          nutrition: current.nutrition,
        );
      });
    }

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

    try {
      var updated = await _recipeService.updateRecipe(
        current.id,
        title: data.name,
        ingredients: data.ingredientItems,
        directions: RecipeModel.splitLines(data.steps),
        dietaryRestrictions: data.labels,
        estimatedServings: data.estimatedServings,
      );
      if (data.pendingImageBytes != null &&
          data.pendingImageBytes!.isNotEmpty) {
        try {
          final imageUrl = await _recipeService.uploadRecipeImage(
            updated.id,
            data.pendingImageBytes!,
            data.pendingImageFilename,
          );
          if (imageUrl != null && imageUrl.isNotEmpty) {
            updated = updated.copyWith(imageUrl: imageUrl);
          }
        } on ApiException catch (e) {
          if (mounted) showErrorToast(context, e.message);
        }
      }
      if (!mounted) return false;
      Navigator.of(context).pop(); // dismiss loading
      final wasClone = updated.id != current.id;
      setState(() {
        if (wasClone) {
          if (index < _recipes.length && _recipes[index].id == current.id) {
            _recipes[index] = updated;
          } else {
            _recipes.insert(0, updated);
          }
        } else {
          _recipes[index] = updated;
        }
        _selectedRecipe = updated;
      });
      showRecipeToast(context, recipeName: updated.name, isNew: wasClone);
      return true;
    } on ApiException catch (e) {
      if (!mounted) return false;
      Navigator.of(context).pop(); // dismiss loading
      showErrorToast(context, e.message);
      return false;
    }
  }

  Future<void> _onDeleteRecipe() async {
    final index = _selectedRecipeCardIndex;
    final current = _selectedRecipe;
    if (current == null) return;
    final confirmed = await _confirmDeleteRecipe(current.title);
    if (confirmed != true) return;
    await _deleteRecipe(current, index);
    if (mounted) _closeRecipeDetails();
  }

  Future<void> _onQuickDeleteRecipe(int index) async {
    if (index < 0 || index >= _recipes.length) return;
    final recipe = _recipes[index];
    final confirmed = await _confirmDeleteRecipe(recipe.title);
    if (confirmed != true) return;
    await _deleteRecipe(recipe, index);
  }

  Future<bool?> _confirmDeleteRecipe(String title) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Delete recipe?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        content: Text(
          'Delete "$title" permanently?',
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRecipe(RecipeModel recipe, int? knownIndex) async {
    try {
      await _recipeService.deleteRecipe(recipe.id);
      if (!mounted) return;
      setState(() {
        if (knownIndex != null &&
            knownIndex >= 0 &&
            knownIndex < _recipes.length &&
            _recipes[knownIndex].id == recipe.id) {
          _recipes.removeAt(knownIndex);
        } else {
          _recipes.removeWhere((r) => r.id == recipe.id);
        }
      });
      showDeleteToast(context, recipeName: "Recipe ${recipe.title}");
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorToast(context, e.message);
    }
  }

  // ── Favorites: data + actions (unchanged behavior) ────────────────────────

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoadingFavorites = true;
      _favoritesError = null;
    });

    try {
      final favorites = await _favoriteService.listFavorites();
      if (!mounted) return;
      setState(() {
        _favorites = favorites;
        _isLoadingFavorites = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _favoritesError = e.message;
        _isLoadingFavorites = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _favoritesError = S.of(context).unableToLoadFavorites;
        _isLoadingFavorites = false;
      });
    }
  }

  void _openFavoriteDetails(int index) {
    if (index < 0 || index >= _favorites.length) return;
    widget.onDetailModeChanged?.call(true);
    setState(() {
      _selectedFavoriteIndex = index;
      _savedCurrentRecipe = true;
    });
  }

  Future<void> _closeFavoriteDetails() async {
    if (_selectedFavoriteIndex == null) return;

    final index = _selectedFavoriteIndex!;
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
      _selectedFavoriteIndex = null;
      _savedCurrentRecipe = true;
    });
  }

  Future<void> _toggleSaveInDetail() async {
    final index = _selectedFavoriteIndex;
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
    final cardColor = recipeCardTheme(
      current.recipe.id,
      current.recipe.labels,
    ).start;
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
              color: isDarkMode
                  ? const Color(0xFFF8FAFC)
                  : const Color(0xFF111827),
            ),
          ),
          content: Text(
            S.of(context).removeConfirm(recipe.name),
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: isDarkMode
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF4B5563),
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

  Future<bool> _saveAsPersonalRecipe(RecipeDetailData data) async {
    final s = S.of(context);
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
    try {
      var updated = await _recipeService.updateRecipe(
        data.id,
        title: data.name,
        ingredients: data.ingredientItems,
        directions: RecipeModel.splitLines(data.steps),
        dietaryRestrictions: data.labels,
        estimatedServings: data.estimatedServings,
      );
      if (data.pendingImageBytes != null &&
          data.pendingImageBytes!.isNotEmpty) {
        try {
          final imageUrl = await _recipeService.uploadRecipeImage(
            updated.id,
            data.pendingImageBytes!,
            data.pendingImageFilename,
          );
          if (imageUrl != null && imageUrl.isNotEmpty) {
            updated = updated.copyWith(imageUrl: imageUrl);
          }
        } on ApiException catch (e) {
          if (mounted) showErrorToast(context, e.message);
        }
      }
      if (!mounted) return false;
      Navigator.of(context).pop();
      showSuccessToast(context, s.savedAsPersonalRecipe);
      return true;
    } on ApiException catch (e) {
      if (!mounted) return false;
      Navigator.of(context).pop();
      showErrorToast(context, e.message);
      return false;
    }
  }

  int get _savedCount => _favorites.length;

  int get _noteCount =>
      _favorites.where((r) => (r.note ?? '').trim().isNotEmpty).length;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_selectedRecipe != null && _selectedRecipeCardIndex != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _closeRecipeDetails();
        },
        child: RecipeDetailView(
          recipe: _selectedRecipe!.toDetailData(),
          cardColor: recipeCardTheme(
            _selectedRecipe!.id,
            _selectedRecipe!.labels,
          ).start,
          onBack: _closeRecipeDetails,
          enableEdit: true,
          onSaveEdited: _onSaveEditedRecipe,
          onDelete: _onDeleteRecipe,
          onAddToPlan: () => _addRecipeToPlan(_selectedRecipe!),
        ),
      );
    }

    if (_selectedFavoriteIndex != null) {
      final favorite = _favorites[_selectedFavoriteIndex!];
      final recipe = favorite.recipe;

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _closeFavoriteDetails();
        },
        child: RecipeDetailView(
          recipe: recipe.toDetailData(),
          cardColor: recipeCardTheme(recipe.id, recipe.labels).start,
          onBack: _closeFavoriteDetails,
          isSaved: _savedCurrentRecipe,
          onToggleSave: _toggleSaveInDetail,
          onSaveEdited: _saveAsPersonalRecipe,
        ),
      );
    }

    if (_isAddingRecipe) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: _AddRecipePanel(
                onCancel: _onCancelAddRecipe,
                onSave: _onSaveRecipe,
              ),
            ),
          ],
        ),
      );
    }

    final s = S.of(context);
    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFE5E7EB),
      body: RefreshIndicator(
        color: const Color(0xFF059669),
        onRefresh: () => Future.wait([_loadRecipes(), _loadFavorites()]),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 90),
          children: [
            _CollectionTabSwitcher(
              index: _tabIndex,
              isDarkMode: isDarkMode,
              personalLabel: s.myRecipes,
              favoritesLabel: s.favoritesTitle,
              onChanged: (i) => setState(() => _tabIndex = i),
            ),
            const SizedBox(height: 12),
            if (_tabIndex == 0)
              ..._buildPersonalRecipesTab(isDarkMode, s)
            else
              ..._buildFavoritesTab(isDarkMode, s),
          ],
        ),
      ),
      floatingActionButton: _tabIndex == 0
          ? FloatingActionButton(
              onPressed: _onAddRecipePressed,
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  List<Widget> _buildPersonalRecipesTab(bool isDarkMode, S s) {
    return [
      Row(
        children: [
          const Icon(
            Icons.menu_book_rounded,
            size: 20,
            color: Color(0xFF059669),
          ),
          const SizedBox(width: 6),
          Text(
            s.myRecipes,
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
        s.personalRecipesSubtitle,
        style: TextStyle(
          fontSize: 10.5,
          color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
        ),
      ),
      const SizedBox(height: 8),
      _SummaryCard(
        value: '${_recipes.length}',
        label: s.totalRecipesLabel,
        isDarkMode: isDarkMode,
      ),
      const SizedBox(height: 8),
      if (_isLoadingRecipes)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFF059669)),
          ),
        )
      else if (_recipesError != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(child: Text(_recipesError!)),
              FilledButton(onPressed: _loadRecipes, child: Text(s.retry)),
            ],
          ),
        )
      else if (_recipes.isEmpty)
        GestureDetector(
          onTap: _onAddRecipePressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF141414) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDarkMode ? 0.35 : 0.06,
                  ),
                  blurRadius: isDarkMode ? 10 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.menu_book_outlined,
                  color: Color(0xFF9CA3AF),
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  s.noRecipesYet,
                  style: TextStyle(
                    color: isDarkMode
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF374151),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.addFirstRecipe,
                  style: const TextStyle(
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        )
      else
        ...List.generate(_recipes.length, (index) {
          final recipe = _recipes[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RecipeCard(
              recipe: recipe,
              onTap: () => _openRecipeDetails(recipe, index),
              onAction: () => _openRecipeDetails(recipe, index),
              footer: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openRecipeDetails(recipe, index),
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      label: Text(s.edit),
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
                            : const BorderSide(color: Color(0xFFD1D5DB)),
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
                    height: 32,
                    child: OutlinedButton(
                      onPressed: () => _onQuickDeleteRecipe(index),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: isDarkMode
                            ? const Color(0xFF1E1E1E)
                            : const Color(0xFFF9FAFB),
                        side: isDarkMode
                            ? BorderSide.none
                            : const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFDC2626),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
    ];
  }

  List<Widget> _buildFavoritesTab(bool isDarkMode, S s) {
    return [
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
          color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
        ),
      ),
      const SizedBox(height: 8),
      if (_isLoadingFavorites)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFF059669)),
          ),
        )
      else if (_favoritesError != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(child: Text(_favoritesError!)),
              FilledButton(onPressed: _loadFavorites, child: Text(s.retry)),
            ],
          ),
        )
      else ...[
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF141414) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDarkMode ? 0.35 : 0.06,
                  ),
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
                  s.noFavoritesYet,
                  style: TextStyle(
                    color: isDarkMode
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF374151),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(_favorites.length, (index) {
            final favorite = _favorites[index];
            final recipe = favorite.recipe;
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
                onTap: () => _openFavoriteDetails(index),
                onAction: () => _openFavoriteDetails(index),
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
                          border: isDarkMode
                              ? null
                              : Border.all(color: noteBorder),
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
                                  : const BorderSide(color: Color(0xFFD1D5DB)),
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
                                  : const BorderSide(color: Color(0xFFD1D5DB)),
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
    ];
  }
}

// ── Tab switcher (Personal Recipes | Favorites) ───────────────────────────────

class _CollectionTabSwitcher extends StatelessWidget {
  const _CollectionTabSwitcher({
    required this.index,
    required this.isDarkMode,
    required this.personalLabel,
    required this.favoritesLabel,
    required this.onChanged,
  });

  final int index;
  final bool isDarkMode;
  final String personalLabel;
  final String favoritesLabel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF141414) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.35 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _CollectionTabOption(
              label: personalLabel,
              icon: Icons.menu_book_rounded,
              selected: index == 0,
              isDarkMode: isDarkMode,
              onTap: () => onChanged(0),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _CollectionTabOption(
              label: favoritesLabel,
              icon: Icons.favorite_rounded,
              selected: index == 1,
              isDarkMode: isDarkMode,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionTabOption extends StatelessWidget {
  const _CollectionTabOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDarkMode,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool isDarkMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF059669) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected
                  ? Colors.white
                  : (isDarkMode
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF6B7280)),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? Colors.white
                      : (isDarkMode
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF6B7280)),
                ),
              ),
            ),
          ],
        ),
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

// ── Add recipe panel (moved from the home screen) ─────────────────────────────

class _AddRecipePanel extends StatefulWidget {
  const _AddRecipePanel({required this.onCancel, required this.onSave});

  final VoidCallback onCancel;
  final ValueChanged<RecipeModel> onSave;

  @override
  State<_AddRecipePanel> createState() => _AddRecipePanelState();
}

class _AddRecipePanelState extends State<_AddRecipePanel> {
  final _recipeService = RecipeService();
  final _aiService = AiService();
  final _nameController = TextEditingController();
  final _cookingMinutesController = TextEditingController();
  final _servingsController = TextEditingController();
  final List<TextEditingController> _ingredientControllers = [
    TextEditingController(),
  ];
  final List<TextEditingController> _stepControllers = [
    TextEditingController(),
  ];
  final Set<String> _selectedLabels = {};
  List<String> _availableLabels = [];
  bool _isSaving = false;
  bool _isDetectingDish = false;
  Uint8List? _imageBytes;
  String _imageFilename = 'recipe.jpg';

  @override
  void initState() {
    super.initState();
    _loadDietaryLabels();
  }

  Future<void> _loadDietaryLabels() async {
    try {
      final options = await _recipeService.getDietaryRestrictions();
      if (mounted) setState(() => _availableLabels = options);
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    final filename = file.name.isNotEmpty ? file.name : 'recipe.jpg';
    setState(() {
      _imageBytes = bytes;
      _imageFilename = filename;
    });
    unawaited(_detectDishName(bytes, filename));
  }

  Future<void> _detectDishName(Uint8List bytes, String filename) async {
    if (!mounted) return;
    setState(() => _isDetectingDish = true);
    try {
      final result = await _aiService.recognizeDish(
        bytes: bytes,
        filename: filename,
        language: LangScope.current.value,
      );
      if (!mounted) return;
      // Fill title only if field is still empty
      if (_nameController.text.trim().isEmpty) {
        final name = result.results.isNotEmpty
            ? result.results.first.dishName
            : result.dishName;
        if (name.isNotEmpty) _nameController.text = name;
      }
    } catch (_) {
      // Silently ignore detection errors
    } finally {
      if (mounted) setState(() => _isDetectingDish = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _ingredientControllers) {
      c.dispose();
    }
    for (final c in _stepControllers) {
      c.dispose();
    }
    _cookingMinutesController.dispose();
    _servingsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    final ingredients = _ingredientControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final steps = _stepControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .join('\n');
    final servings = int.tryParse(_servingsController.text.trim());

    if (name.isEmpty || ingredients.isEmpty || steps.isEmpty) {
      showErrorToast(context, S.of(context).fillAllFields);
      return;
    }

    setState(() => _isSaving = true);

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

    try {
      final created = await _recipeService.createRecipe(
        title: name,
        ingredients: ingredients,
        directions: RecipeModel.splitLines(steps),
        dietaryRestrictions: _selectedLabels.toList(),
        estimatedServings: servings != null && servings > 0 ? servings : null,
      );

      String? imageUrl;
      if (_imageBytes != null) {
        try {
          imageUrl = await _recipeService.uploadRecipeImage(
            created.id,
            _imageBytes!,
            _imageFilename,
          );
        } on ApiException catch (e) {
          if (mounted) showErrorToast(context, e.message);
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      showRecipeToast(context, recipeName: name, isNew: true);
      final finalRecipe = imageUrl != null && imageUrl.isNotEmpty
          ? created.copyWith(imageUrl: imageUrl)
          : created;
      widget.onSave(finalRecipe);
    } on ApiException catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      showErrorToast(context, e.message);
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      showErrorToast(context, S.of(context).unableToSaveRecipe);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);
    final cardBg = isDarkMode ? const Color(0xFF141414) : Colors.white;
    final panelColor = isDarkMode
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF0F2F5);
    final dividerColor = isDarkMode
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFE2E4E8);
    final hintColor = isDarkMode
        ? const Color(0xFF64748B)
        : const Color(0xFF9CA3AF);
    final textColor = isDarkMode
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF111827);
    const accentColor = Color(0xFF059669);

    InputDecoration inlineFieldDecoration({String? hint, String? suffix}) =>
        InputDecoration(
          hintText: hint,
          suffixText: suffix,
          hintStyle: TextStyle(color: hintColor, fontSize: 13),
          isDense: true,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: accentColor, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 6,
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.45 : 0.08),
            blurRadius: isDarkMode ? 20 : 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add_circle_outline,
                    size: 16,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  s.newRecipeTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onCancel,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFF3F4F6),
                    minimumSize: const Size(32, 32),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: dividerColor),

          // ── Body ────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo picker
                  GestureDetector(
                    onTap: _pickImage,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _imageBytes != null
                          ? Stack(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 140,
                                  child: Image.memory(
                                    _imageBytes!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned.fill(
                                  child: ColoredBox(
                                    color: Colors.black.withValues(alpha: 0.25),
                                  ),
                                ),
                                const Positioned.fill(
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.photo_camera_outlined,
                                          size: 15,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Change Photo',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Container(
                              width: double.infinity,
                              height: 100,
                              color: panelColor,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 28,
                                    color: isDarkMode
                                        ? const Color(0xFF64748B)
                                        : const Color(0xFF9CA3AF),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    S.of(context).addPhoto,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDarkMode
                                          ? const Color(0xFF64748B)
                                          : const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Recipe name
                  _AddSectionCard(
                    isDarkMode: isDarkMode,
                    panelColor: panelColor,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                              letterSpacing: -0.3,
                            ),
                            decoration: InputDecoration(
                              hintText: _isDetectingDish
                                  ? (LangScope.current.value == 'vi'
                                      ? 'Đang nhận diện món ăn…'
                                      : 'Detecting dish name…')
                                  : s.recipeNameHint,
                              hintStyle: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: hintColor,
                                letterSpacing: -0.3,
                              ),
                              isDense: true,
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            ),
                          ),
                        ),
                        if (_isDetectingDish)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: hintColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Time
                  _AddSectionCard(
                    isDarkMode: isDarkMode,
                    panelColor: panelColor,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: accentColor,
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 56,
                          child: TextField(
                            controller: _cookingMinutesController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(fontSize: 13, color: textColor),
                            decoration: inlineFieldDecoration(hint: '0'),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          s.minSuffix,
                          style: TextStyle(fontSize: 12, color: hintColor),
                        ),
                        const SizedBox(width: 20),
                        const Icon(
                          Icons.restaurant_outlined,
                          size: 16,
                          color: accentColor,
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 56,
                          child: TextField(
                            controller: _servingsController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(fontSize: 13, color: textColor),
                            decoration: inlineFieldDecoration(hint: ''),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          s.servingsSuffix,
                          style: TextStyle(fontSize: 12, color: hintColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Ingredients
                  _AddSectionCard(
                    isDarkMode: isDarkMode,
                    panelColor: panelColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.shopping_basket_outlined,
                              size: 15,
                              color: accentColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              s.ingredientsLabel,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._ingredientControllers.asMap().entries.map((entry) {
                          final i = entry.key;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: accentColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: entry.value,
                                    maxLines: 1,
                                    textInputAction: TextInputAction.next,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: textColor,
                                    ),
                                    decoration: inlineFieldDecoration(
                                      hint: s.ingredientHint(i),
                                    ),
                                  ),
                                ),
                                if (_ingredientControllers.length > 1) ...[
                                  const SizedBox(width: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _ingredientControllers[i].dispose();
                                        _ingredientControllers.removeAt(i);
                                      }),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 16,
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                        TextButton.icon(
                          onPressed: () => setState(
                            () => _ingredientControllers.add(
                              TextEditingController(),
                            ),
                          ),
                          icon: const Icon(Icons.add, size: 14),
                          label: Text(s.addIngredient),
                          style: TextButton.styleFrom(
                            foregroundColor: accentColor,
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Steps
                  _AddSectionCard(
                    isDarkMode: isDarkMode,
                    panelColor: panelColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.format_list_numbered,
                              size: 15,
                              color: accentColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              s.instructionsLabel,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._stepControllers.asMap().entries.map((entry) {
                          final i = entry.key;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(
                                      alpha: isDarkMode ? 0.18 : 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: accentColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: entry.value,
                                    maxLines: null,
                                    minLines: 1,
                                    textInputAction: TextInputAction.next,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: textColor,
                                    ),
                                    decoration: inlineFieldDecoration(
                                      hint: s.stepHint(i),
                                    ),
                                  ),
                                ),
                                if (_stepControllers.length > 1) ...[
                                  const SizedBox(width: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _stepControllers[i].dispose();
                                        _stepControllers.removeAt(i);
                                      }),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 16,
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                        TextButton.icon(
                          onPressed: () => setState(
                            () => _stepControllers.add(TextEditingController()),
                          ),
                          icon: const Icon(Icons.add, size: 14),
                          label: Text(s.addStep),
                          style: TextButton.styleFrom(
                            foregroundColor: accentColor,
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Labels
                  _AddSectionCard(
                    isDarkMode: isDarkMode,
                    panelColor: panelColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.sell_outlined,
                              size: 15,
                              color: accentColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              s.labelsLabel,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _availableLabels.map((label) {
                            final isSelected = _selectedLabels.contains(label);
                            return FilterChip(
                              selected: isSelected,
                              selectedColor: accentColor,
                              checkmarkColor: Colors.white,
                              backgroundColor: isDarkMode
                                  ? const Color(0xFF2A2A2A)
                                  : const Color(0xFFE4E6EA),
                              side: BorderSide.none,
                              label: Text(
                                s.dietaryTagDisplay(label),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isSelected
                                      ? Colors.white
                                      : colors.onSurfaceVariant,
                                ),
                              ),
                              onSelected: (selected) => setState(() {
                                selected
                                    ? _selectedLabels.add(label)
                                    : _selectedLabels.remove(label);
                              }),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Actions ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      foregroundColor: colors.onSurface,
                      side: BorderSide.none,
                      backgroundColor: isDarkMode
                          ? const Color(0xFF1E1E1E)
                          : const Color(0xFFF3F4F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      s.cancel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      s.saveRecipe,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddSectionCard extends StatelessWidget {
  const _AddSectionCard({
    required this.isDarkMode,
    required this.panelColor,
    required this.child,
  });

  final bool isDarkMode;
  final Color panelColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.28 : 0.06),
            blurRadius: isDarkMode ? 8 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
