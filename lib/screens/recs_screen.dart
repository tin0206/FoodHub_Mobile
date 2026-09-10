import 'dart:async';

import 'package:flutter/material.dart';
import 'package:foodhub_mobile/config/api_config.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';
import 'package:foodhub_mobile/models/ai.dart';
import 'package:foodhub_mobile/models/recipe.dart';
import 'package:foodhub_mobile/services/ai_service.dart';
import 'package:foodhub_mobile/services/api_exception.dart';
import 'package:foodhub_mobile/services/favorite_service.dart';
import 'package:foodhub_mobile/services/recipe_service.dart';
import 'package:foodhub_mobile/widgets/ai_capture_overlay.dart';
import 'package:foodhub_mobile/widgets/favorite_toast.dart';
import 'package:foodhub_mobile/widgets/recipe_detail_view.dart';
import 'package:foodhub_mobile/widgets/recs/markdown_reply.dart';

bool isDetailRecipeMarkdown(String text) {
  final hasIngredients = RegExp(
    r'(?:^#{1,4}[^\n]*(?:ingredient|nguy[eê]n\s*li[eê]u)|\*\*[^*\n]*(?:ingredient|nguy[eê]n\s*li[eê]u)[^*\n]*\*\*)',
    caseSensitive: false,
    multiLine: true,
  ).hasMatch(text);
  final hasSteps = RegExp(
    r'(?:^#{1,4}[^\n]*(?:(?:cooking\s+)?steps?|instructions?|directions?|c[aá]ch\s+l[aà]m)|\*\*[^*\n]*(?:(?:cooking\s+)?steps?|instructions?|directions?|c[aá]ch\s+l[aà]m)[^*\n]*\*\*)',
    caseSensitive: false,
    multiLine: true,
  ).hasMatch(text);
  return hasIngredients && hasSteps;
}

class RecsScreen extends StatefulWidget {
  const RecsScreen({
    super.key,
    this.dietaryRestrictions = const {},
    this.primaryGoal = '',
    this.onDetailModeChanged,
  });

  final Set<String> dietaryRestrictions;
  final String primaryGoal;
  final ValueChanged<bool>? onDetailModeChanged;

  @override
  State<RecsScreen> createState() => _RecsScreenState();
}

class _RecsScreenState extends State<RecsScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiService _aiService = AiService();
  final RecipeService _recipeService = RecipeService();
  final List<ChatMessageModel> _conversationHistory = [];

  /// Compose-only detection lines (edited as free text; not separate chat bubbles).
  String? _composeDishText;
  String? _composeIngredientsText;
  bool _isSending = false;
  bool _isBootstrapping = true;
  String? _sessionId;
  RecipeDetailData? _selectedRecipeDetail;
  bool _openingRecipe = false;
  int _recipeCacheEpoch = 0;
  final Map<int, RecipeDetailData> _recipeCache = {};
  final Map<int, Future<RecipeDetailData?>> _recipeFetches = {};

  bool _welcomeStarted = false;

  final List<_ChatMessage> _messages = [];

  final FavoriteService _favoriteService = FavoriteService();
  final Map<int, int> _recipeToFavoriteId = {};
  bool _favoritesLoaded = false;
  final Set<int> _savingRecipeMessages = {};

  @override
  void initState() {
    super.initState();
    // Defer past initState — setState/network must not run synchronously here.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _welcomeStarted) return;
      _welcomeStarted = true;
      _bootstrapWelcome();
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _bootstrapWelcome() async {
    if (mounted) {
      setState(() {
        _isBootstrapping = true;
        _messages.clear();
        _conversationHistory.clear();
        _selectedRecipeDetail = null;
        _recipeCacheEpoch++;
        _recipeCache.clear();
        _recipeFetches.clear();
      });
    }
    widget.onDetailModeChanged?.call(false);

    final sessionId =
        'fh-${DateTime.now().millisecondsSinceEpoch}-${UniqueKey().hashCode.abs()}';
    debugPrint('[Recs] Calling POST /ai/chat/welcome session=$sessionId');
    try {
      final response = await _aiService.welcome(
        sessionId: sessionId,
        dietaryRestrictions: widget.dietaryRestrictions.toList(),
        primaryGoal: widget.primaryGoal,
      );
      if (!mounted) return;
      debugPrint(
        '[Recs] Welcome ok phase=${response.phase} '
        'session=${response.sessionId ?? sessionId}',
      );
      setState(() {
        _sessionId = response.sessionId ?? sessionId;
        _messages.add(
          _ChatMessage(
            text: response.reply.isNotEmpty
                ? response.reply
                : "Hello! I'm your culinary companion. Tell me what you'd like to cook.",
            isUser: false,
            recipes: response.recipes,
            options: response.options,
          ),
        );
        if (response.reply.isNotEmpty) {
          _conversationHistory.add(
            ChatMessageModel(role: 'assistant', content: response.reply),
          );
        }
        _isBootstrapping = false;
      });
      _scrollToBottom();
      _prefetchRecipes(response.reply, response.recipes);
    } catch (e, st) {
      debugPrint('[Recs] Welcome FAILED: $e\n$st');
      if (!mounted) return;
      setState(() {
        _sessionId = sessionId;
        _messages.add(
          _ChatMessage(text: S.of(context).unableToReachAi, isUser: false),
        );
        _isBootstrapping = false;
      });
    }
  }

  List<String> _dishNamesFrom(DishRecognitionModel dish) {
    if (dish.results.isNotEmpty) {
      return dish.results
          .take(5)
          .map((r) => r.dishName)
          .where((name) => name.isNotEmpty)
          .toList();
    }
    if (dish.dishName.isNotEmpty) return [dish.dishName];
    return dish.suggestedRecipes.take(5).toList();
  }

  /// Prefer top match for the initial compose line.
  void _setDishComposeFrom(DishRecognitionModel dish, BuildContext ctx) {
    final names = _dishNamesFrom(dish);
    if (names.isEmpty) {
      _composeDishText = null;
      return;
    }
    _composeDishText = S.of(ctx).dishDetectedName(names.first);
  }

  List<String> _ingredientsForApi() {
    final text = _composeIngredientsText?.trim();
    if (text == null || text.isEmpty) return const [];
    var values = text;
    const prefix = 'Ingredients detected:';
    if (values.toLowerCase().startsWith(prefix.toLowerCase())) {
      values = values.substring(prefix.length);
    }
    return values
        .split(RegExp(r'[,;\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Single prompt from dish → ingredients → user query (only non-empty parts).
  String _buildMergedPrompt(String userQuery) {
    final parts = <String>[];
    final dishText = _composeDishText?.trim();
    final ingredientsText = _composeIngredientsText?.trim();
    if (dishText != null && dishText.isNotEmpty) parts.add(dishText);
    if (ingredientsText != null && ingredientsText.isNotEmpty) {
      parts.add(ingredientsText);
    }
    final trimmed = userQuery.trim();
    if (trimmed.isNotEmpty) parts.add(trimmed);
    return parts.join('\n');
  }

  void _clearComposeDetections() {
    _composeIngredientsText = null;
    _composeDishText = null;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _resetChat() async {
    if (_isSending || _isBootstrapping) return;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final s = S.of(ctx);
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF141414) : Colors.white,
          title: Text(
            s.resetChatTitle,
            style: TextStyle(
              color: isDarkMode
                  ? const Color(0xFFF8FAFC)
                  : const Color(0xFF111827),
            ),
          ),
          content: Text(
            s.resetChatDesc,
            style: TextStyle(
              color: isDarkMode
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF6B7280),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
              ),
              child: Text(s.resetLabel),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    _welcomeStarted = true;
    _clearComposeDetections();
    _promptController.clear();
    await _bootstrapWelcome();
  }

  List<int> _recipeIdsFrom(String markdown, List<RagRecipeModel> recipes) {
    final links = mergeRecipeCtas(
      fromMarkdown: extractRecipeMarkdownLinks(markdown).links,
      recipes: recipes,
    );
    final ids = <int>{};
    for (final link in links) {
      final id = int.tryParse(normalizeRecipeHref(link.recipeId));
      if (id != null) ids.add(id);
    }
    return ids.toList();
  }

  Future<RecipeDetailData?> _recipeById(int id) {
    final cached = _recipeCache[id];
    if (cached != null) return Future.value(cached);

    return _recipeFetches.putIfAbsent(id, () async {
      final epoch = _recipeCacheEpoch;
      try {
        final detail = (await _recipeService.getRecipe(id)).toDetailData();
        if (epoch == _recipeCacheEpoch) _recipeCache[id] = detail;
        return detail;
      } catch (_) {
        return null;
      } finally {
        if (epoch == _recipeCacheEpoch) _recipeFetches.remove(id);
      }
    });
  }

  /// Build a lightweight detail view from RAG data already in the message list,
  /// avoiding a network round-trip when the AI already sent the recipe payload.
  RecipeDetailData? _detailFromRagRecipe(int id) {
    for (final msg in _messages) {
      if (msg.isUser || msg.recipes.isEmpty) continue;
      for (final r in msg.recipes) {
        final rid = int.tryParse(r.recipeId ?? '');
        if (rid == id) {
          final detail = RecipeDetailData(
            id: id,
            name: r.title,
            imageUrl: ApiConfig.resolveImageUrl(r.imageUrl).isNotEmpty
                ? ApiConfig.resolveImageUrl(r.imageUrl)
                : null,
            cookingMinutes: 0,
            estimatedServings: r.estimatedServings,
            ingredients: r.ingredients.join('\n'),
            steps: r.directions.join('\n'),
            labels: r.dietaryRestrictions,
          );
          _recipeCache[id] = detail;
          return detail;
        }
      }
    }
    return null;
  }

  Future<String?> _resolveRecipeImageUrl(String recipeId) async {
    final id = int.tryParse(recipeId);
    if (id == null) return null;
    // Try RAG data first (already in memory)
    final fromRag = _detailFromRagRecipe(id);
    if (fromRag?.imageUrl != null) return fromRag!.imageUrl;
    final detail = await _recipeById(id);
    return detail?.imageUrl;
  }

  void _prefetchRecipes(String markdown, List<RagRecipeModel> recipes) {
    for (final id in _recipeIdsFrom(markdown, recipes)) {
      // Seed cache from RAG payload; only fetch if missing
      if (!_recipeCache.containsKey(id)) {
        _detailFromRagRecipe(id);
      }
      if (!_recipeCache.containsKey(id)) {
        unawaited(_recipeById(id));
      }
    }
  }

  Future<void> _openRecipeFromChat(RecipeLinkRef link) async {
    if (_openingRecipe) return;
    final id = int.tryParse(normalizeRecipeHref(link.recipeId));
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).unableToOpenRecipe(link.title)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 1. Memory cache
    final cached = _recipeCache[id];
    if (cached != null) {
      widget.onDetailModeChanged?.call(true);
      setState(() => _selectedRecipeDetail = cached);
      unawaited(_loadFavorites());
      return;
    }

    // 2. RAG payload already in message list — no network call needed
    final fromRag = _detailFromRagRecipe(id);
    if (fromRag != null) {
      widget.onDetailModeChanged?.call(true);
      setState(() => _selectedRecipeDetail = fromRag);
      unawaited(_loadFavorites());
      // Fetch full detail in background to enrich cache (cooking time, nutrition…)
      unawaited(_recipeById(id));
      return;
    }

    // 3. Full API fetch
    setState(() => _openingRecipe = true);
    final detail = await _recipeById(id);
    if (!mounted) return;
    setState(() => _openingRecipe = false);

    if (detail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).unableToOpenRecipe(link.title)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    widget.onDetailModeChanged?.call(true);
    setState(() => _selectedRecipeDetail = detail);
    unawaited(_loadFavorites());
  }

  void _closeRecipeDetails() {
    widget.onDetailModeChanged?.call(false);
    setState(() => _selectedRecipeDetail = null);
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

  Future<void> _loadFavorites() async {
    if (_favoritesLoaded) return;
    try {
      final favs = await _favoriteService.listFavorites();
      if (!mounted) return;
      setState(() {
        _favoritesLoaded = true;
        _recipeToFavoriteId.clear();
        for (final f in favs) {
          _recipeToFavoriteId[f.recipeId] = f.id;
        }
      });
    } catch (_) {}
  }

  Future<void> _toggleSave(int recipeId) async {
    try {
      if (_recipeToFavoriteId.containsKey(recipeId)) {
        final favId = _recipeToFavoriteId[recipeId]!;
        await _favoriteService.deleteFavorite(favId);
        if (!mounted) return;
        setState(() => _recipeToFavoriteId.remove(recipeId));
      } else {
        final fav = await _favoriteService.addFavorite(recipeId: recipeId);
        if (!mounted) return;
        setState(() => _recipeToFavoriteId[recipeId] = fav.id);
      }
    } catch (_) {}
  }

  Future<void> _onPromptSubmitted() async {
    if (_isSending || _isBootstrapping) return;

    final userQuery = _promptController.text.trim();
    final merged = _buildMergedPrompt(userQuery);
    if (merged.isEmpty) return;

    final sessionId = _sessionId;
    if (sessionId == null || sessionId.isEmpty) {
      await _bootstrapWelcome();
      if (_sessionId == null) return;
    }

    final ingredients = _ingredientsForApi();

    setState(() {
      _messages.add(_ChatMessage(text: merged, isUser: true));
      _isSending = true;
      _clearComposeDetections();
      _promptController.clear();
    });
    _scrollToBottom();

    await _sendToAi(merged, ingredients);
  }

  Future<void> _sendToAi(String merged, List<String> ingredients) async {
    final dietary = widget.dietaryRestrictions.toList();

    try {
      final response = await _aiService.chat(
        message: merged,
        sessionId: _sessionId!,
        dietaryRestrictions: dietary,
        primaryGoal: widget.primaryGoal,
        ingredients: ingredients,
      );

      _conversationHistory
        ..add(ChatMessageModel(role: 'user', content: merged))
        ..add(ChatMessageModel(role: 'assistant', content: response.reply));

      if (!mounted) return;
      setState(() {
        if (response.sessionId != null && response.sessionId!.isNotEmpty) {
          _sessionId = response.sessionId;
        }
        _messages.add(
          _ChatMessage(
            text: response.reply,
            isUser: false,
            recipes: response.recipes,
            options: response.options,
          ),
        );
        _isSending = false;
      });
      _scrollToBottom();
      _prefetchRecipes(response.reply, response.recipes);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(text: e.message, isUser: false));
        _isSending = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(text: S.of(context).unableToReachAi, isUser: false),
        );
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendDishDetection() async {
    if (_isSending || _isBootstrapping) return;
    final text = _composeDishText?.trim();
    if (text == null || text.isEmpty) return;
    if (_sessionId == null || _sessionId!.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isSending = true;
      _composeDishText = null;
    });
    _scrollToBottom();
    await _sendToAi(text, []);
  }

  Future<void> _sendIngredientsDetection() async {
    if (_isSending || _isBootstrapping) return;
    final text = _composeIngredientsText?.trim();
    if (text == null || text.isEmpty) return;
    if (_sessionId == null || _sessionId!.isEmpty) return;
    final ingredients = _ingredientsForApi();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isSending = true;
      _composeIngredientsText = null;
    });
    _scrollToBottom();
    await _sendToAi(text, ingredients);
  }


  static bool _isSectionKeyword(String text) {
    const kw = [
      'ingredient', 'nguyên liệu', 'nguyên liêu',
      'step', 'instruction', 'direction', 'cách làm', 'cach lam',
      'note', 'tip', 'nutrition', 'dinh dưỡng',
      'preparation', 'chuẩn bị', 'serve', 'khẩu phần',
    ];
    final lower = text.toLowerCase();
    return kw.any((k) => lower.contains(k));
  }

  String _extractTitleFromMarkdown(String text) {
    // 1. First heading that is NOT a known section keyword
    for (final m in RegExp(r'^#{1,3}\s+(.+)$', multiLine: true).allMatches(text)) {
      final title = m.group(1)!.trim().replaceAll(RegExp(r'\*+'), '');
      if (title.isNotEmpty && !_isSectionKeyword(title)) return title;
    }
    // 2. Bold text in the intro (before the first heading), e.g. **Pepper Chicken**
    final firstHeadingOffset =
        RegExp(r'^#{1,3}\s+', multiLine: true).firstMatch(text)?.start;
    final intro = firstHeadingOffset != null
        ? text.substring(0, firstHeadingOffset)
        : text;
    final bold = RegExp(r'\*\*([^*\n]{3,80})\*\*').firstMatch(intro);
    if (bold != null) {
      final t = bold.group(1)!.trim();
      if (!_isSectionKeyword(t)) return t;
    }
    // 3. First non-empty, non-heading plain line in intro
    for (final line in intro.split('\n')) {
      final clean = line.trim().replaceAll(RegExp(r'\*+'), '').trim();
      if (clean.isNotEmpty && clean.length >= 3 && clean.length <= 80) return clean;
    }
    return 'Recipe';
  }

  List<String> _extractSectionLines(String text, RegExp sectionPattern) {
    final lines = text.split('\n');
    final result = <String>[];
    var inSection = false;
    for (final line in lines) {
      final trimmed = line.trim();
      final isHeading = RegExp(r'^#{1,4}\s+', multiLine: true).hasMatch(trimmed) ||
          RegExp(r'^\*\*[^*]+\*\*\s*:?\s*$').hasMatch(trimmed);
      if (isHeading) {
        if (sectionPattern.hasMatch(trimmed.toLowerCase())) {
          inSection = true;
          continue;
        } else if (inSection) {
          break;
        }
      }
      if (!inSection) continue;
      if (trimmed.isEmpty || trimmed == '---' || trimmed == '***' || trimmed == '___') continue;
      final clean = trimmed
          .replaceFirst(RegExp(r'^[-*•]\s+'), '')
          .replaceFirst(RegExp(r'^\d+\.\s+'), '')
          .replaceAll(RegExp(r'\*+'), '')
          .trim();
      if (clean.isNotEmpty) result.add(clean);
    }
    return result;
  }

  List<String> _extractIngredientsFromMarkdown(String text) {
    return _extractSectionLines(
      text,
      RegExp(r'ingredient|nguy[eê]n\s*li[eê]u', caseSensitive: false),
    );
  }

  List<String> _extractDirectionsFromMarkdown(String text) {
    return _extractSectionLines(
      text,
      RegExp(r'(?:cooking\s+)?steps?|instructions?|directions?|c[aá]ch\s+l[aà]m', caseSensitive: false),
    );
  }

  /// Looks backward from [beforeIndex] for an AI message that has a recipe
  /// whose title best matches [title] (case-insensitive contains).
  RagRecipeModel? _findSnapshotRecipe(String title, int beforeIndex) {
    final lower = title.toLowerCase();
    for (var i = beforeIndex - 1; i >= 0; i--) {
      final msg = _messages[i];
      if (msg.isUser || msg.recipes.isEmpty) continue;
      // Exact or contains match
      final exact = msg.recipes.where(
        (r) => r.title.toLowerCase() == lower,
      ).firstOrNull;
      if (exact != null) return exact;
      final contains = msg.recipes.where(
        (r) => r.title.toLowerCase().contains(lower) ||
            lower.contains(r.title.toLowerCase()),
      ).firstOrNull;
      if (contains != null) return contains;
      // Any recipe from the last list message (best guess)
      return msg.recipes.first;
    }
    return null;
  }

  Future<void> _addRecipeFromChat(int messageIndex) async {
    if (messageIndex < 0 || messageIndex >= _messages.length) return;
    final message = _messages[messageIndex];
    if (message.savedRecipeId != null) return;
    if (_savingRecipeMessages.contains(messageIndex)) return;

    final title = _extractTitleFromMarkdown(message.text);
    final ingredients = _extractIngredientsFromMarkdown(message.text);
    final directions = _extractDirectionsFromMarkdown(message.text);

    if (ingredients.isEmpty || directions.isEmpty) {
      if (mounted) showErrorToast(context, S.of(context).unableToSaveRecipe);
      return;
    }

    // Snapshot from nearest preceding list reply
    final snapshot = _findSnapshotRecipe(title, messageIndex);
    final imageUrl = snapshot?.imageUrl ?? '';
    final dietary = snapshot?.dietaryRestrictions ?? const [];
    final servings = snapshot?.estimatedServings;

    setState(() => _savingRecipeMessages.add(messageIndex));

    Future<RecipeModel> tryCreate() => _recipeService.createRecipe(
          title: title,
          ingredients: ingredients,
          directions: directions,
          dietaryRestrictions: dietary.isNotEmpty ? dietary : null,
          estimatedServings: servings,
          imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
        );

    RecipeModel? created;
    String? errorMsg;
    try {
      created = await tryCreate();
    } on ApiException catch (e) {
      debugPrint('[Recs] Add from chat fail #1: ${e.statusCode} ${e.message}');
      try {
        created = await tryCreate();
      } on ApiException catch (e2) {
        debugPrint('[Recs] Add from chat fail #2: ${e2.statusCode} ${e2.message}');
        errorMsg = '[${e2.statusCode ?? "?"}] ${e2.message}';
      }
    }

    if (!mounted) return;
    setState(() {
      _savingRecipeMessages.remove(messageIndex);
      if (created != null) _messages[messageIndex].savedRecipeId = created.id;
    });
    if (created != null) {
      RecipeService.changes.value++;
      showSuccessToast(context, S.of(context).savedAsPersonalRecipe);
    } else {
      showErrorToast(context, errorMsg ?? S.of(context).unableToSaveRecipe);
    }
  }

  Future<void> _sendOptionSelection(ChatOptionModel option) async {
    if (_isSending || _isBootstrapping) return;
    if (_sessionId == null || _sessionId!.isEmpty) return;

    // Clear options from the last AI message so buttons disappear after tap.
    setState(() {
      if (_messages.isNotEmpty && !_messages.last.isUser) {
        final last = _messages.last;
        _messages[_messages.length - 1] = _ChatMessage(
          text: last.text,
          isUser: false,
          recipes: last.recipes,
        );
      }
      _messages.add(_ChatMessage(text: option.label, isUser: true));
      _isSending = true;
    });
    _scrollToBottom();
    await _sendToAi(option.label, []);
  }

  Future<void> _openCaptureOverlay() async {
    final result = await AiCaptureScreen.show(context);
    if (!mounted || result == null) return;

    setState(() {
      switch (result) {
        case AiCaptureIngredientsResult(:final ingredients):
          _composeIngredientsText = S
              .of(context)
              .ingredientsDetectedList(ingredients.join(', '));
        case AiCaptureDishResult(:final dish):
          _setDishComposeFrom(dish, context);
      }
    });
  }

  Future<void> _editComposeText({
    required String title,
    required String initialText,
    required ValueChanged<String?> onSave,
  }) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: isDarkMode ? const Color(0xFF141414) : Colors.white,
      builder: (context) => _TextAreaEditSheet(
        title: title,
        initialText: initialText,
        isDarkMode: isDarkMode,
      ),
    );
    if (!mounted || result == null) return;
    final trimmed = result.trim();
    onSave(trimmed.isEmpty ? null : trimmed);
  }

  void _editDishes() {
    final text = _composeDishText;
    if (text == null) return;
    _editComposeText(
      title: S.of(context).editDishesLabel,
      initialText: text,
      onSave: (value) => setState(() => _composeDishText = value),
    );
  }

  void _editIngredients() {
    final text = _composeIngredientsText;
    if (text == null) return;
    _editComposeText(
      title: S.of(context).editIngredientsLabel,
      initialText: text,
      onSave: (value) => setState(() => _composeIngredientsText = value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dishText = _composeDishText?.trim();
    final ingredientsText = _composeIngredientsText?.trim();
    final hasDish = dishText != null && dishText.isNotEmpty;
    final hasIngredients =
        ingredientsText != null && ingredientsText.isNotEmpty;

    if (_selectedRecipeDetail != null) {
      final detail = _selectedRecipeDetail!;
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _closeRecipeDetails();
        },
        child: RecipeDetailView(
          recipe: detail,
          cardColor: const Color(0xFF059669),
          onBack: _closeRecipeDetails,
          isSaved: _favoritesLoaded
              ? _recipeToFavoriteId.containsKey(detail.id)
              : null,
          onToggleSave: _favoritesLoaded
              ? () => unawaited(_toggleSave(detail.id))
              : null,
          onSaveEdited: _saveAsPersonalRecipe,
        ),
      );
    }

    final busy = _isSending || _isBootstrapping;

    return Container(
      color: isDarkMode ? const Color(0xFF0A0A0A) : const Color(0xFFE5E7EB),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 4, 0),
              child: _ChatHeader(
                isDarkMode: isDarkMode,
                onReset: busy ? null : _resetChat,
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                itemCount: _messages.length + (busy ? 1 : 0),
                itemBuilder: (context, index) {
                  if (busy && index == _messages.length) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TypingIndicatorBubble(isDarkMode: isDarkMode),
                          Padding(
                            padding: const EdgeInsets.only(left: 38, top: 4),
                            child: Text(
                              _isBootstrapping
                                  ? S.of(context).startingSession
                                  : S.of(context).aiThinking,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? Colors.white54
                                    : Colors.black45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final message = _messages[index];
                  final isLatestAiMessage =
                      !busy && !message.isUser && index == _messages.length - 1;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ChatBubble(
                      message: message,
                      isDarkMode: isDarkMode,
                      onOpenRecipe: _openRecipeFromChat,
                      onSelectOption: isLatestAiMessage
                          ? _sendOptionSelection
                          : null,
                      imageResolver: _resolveRecipeImageUrl,
                      messageIndex: index,
                      savedRecipeId: message.savedRecipeId,
                      isAddingRecipe: _savingRecipeMessages.contains(index),
                      onAddRecipe: message.isUser
                          ? null
                          : () => _addRecipeFromChat(index),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF0A0A0A) : Colors.white,
              ),
              child: Column(
                children: [
                  if (hasDish) ...[
                    _ComposeDetectionField(
                      text: dishText,
                      icon: Icons.restaurant_menu_rounded,
                      isDarkMode: isDarkMode,
                      enabled: !busy,
                      onEdit: _editDishes,
                      onSend: _sendDishDetection,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (hasIngredients) ...[
                    _ComposeDetectionField(
                      text: ingredientsText,
                      icon: Icons.shopping_basket_outlined,
                      isDarkMode: isDarkMode,
                      enabled: !busy,
                      onEdit: _editIngredients,
                      onSend: _sendIngredientsDetection,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (hasDish || hasIngredients) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Text('💡', style: TextStyle(fontSize: 11.5)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Want recipe suggestions based on this? Hit send to see some ideas!',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDarkMode
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  _UserComposeField(
                    controller: _promptController,
                    isDarkMode: isDarkMode,
                    enabled: !busy,
                    onCamera: _openCaptureOverlay,
                    onSubmit: _onPromptSubmitted,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.isDarkMode, required this.onReset});

  final bool isDarkMode;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFF059669),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 17,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              S.of(context).aiCompanion,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDarkMode
                    ? const Color(0xFFF8FAFC)
                    : const Color(0xFF111827),
              ),
            ),
          ),
          IconButton(
            onPressed: onReset,
            tooltip: 'Reset chat',
            icon: Icon(
              Icons.restart_alt_rounded,
              size: 22,
              color: isDarkMode
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposeDetectionField extends StatelessWidget {
  const _ComposeDetectionField({
    required this.text,
    required this.icon,
    required this.isDarkMode,
    required this.enabled,
    required this.onEdit,
    this.onSend,
  });

  final String text;
  final IconData icon;
  final bool isDarkMode;
  final bool enabled;
  final VoidCallback onEdit;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF111827);
    final muted = isDarkMode
        ? const Color(0xFF94A3B8)
        : const Color(0xFF6B7280);

    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF059669).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 11, 0, 11),
            child: Icon(icon, size: 18, color: const Color(0xFF059669)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 11, 4, 11),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.35,
                  color: textColor,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: enabled ? onEdit : null,
            tooltip: 'Edit',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.edit_outlined, size: 18, color: muted),
          ),
          if (onSend != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: InkWell(
                onTap: enabled ? onSend : null,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: enabled
                        ? const Color(0xFF059669)
                        : const Color(0xFF059669).withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, size: 13, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UserComposeField extends StatelessWidget {
  const _UserComposeField({
    required this.controller,
    required this.isDarkMode,
    required this.enabled,
    required this.onCamera,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isDarkMode;
  final bool enabled;
  final VoidCallback onCamera;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    // Borderless, recessed into the white/dark compose bar.
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF111111) : const Color(0xFFE8EAED),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: InkWell(
              onTap: enabled ? onCamera : null,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF059669),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
              child: TextField(
                controller: controller,
                enabled: enabled,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFF111827),
                ),
                decoration: InputDecoration(
                  hintText: S.of(context).askForRecipesHint,
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: isDarkMode
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF6B7280),
                  ),
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => onSubmit(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final canSend = enabled && controller.text.isNotEmpty;
                return InkWell(
                  onTap: canSend ? onSubmit : null,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: canSend
                          ? const Color(0xFF059669)
                          : const Color(0xFF059669).withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, size: 15, color: Colors.white),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  _ChatMessage({
    required this.text,
    required this.isUser,
    this.recipes = const [],
    this.options = const [],
  });

  final String text;
  final bool isUser;
  final List<RagRecipeModel> recipes;
  final List<ChatOptionModel> options;
  int? savedRecipeId;
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.isDarkMode,
    this.onOpenRecipe,
    this.onSelectOption,
    this.imageResolver,
    this.messageIndex,
    this.savedRecipeId,
    this.isAddingRecipe = false,
    this.onAddRecipe,
  });

  final _ChatMessage message;
  final bool isDarkMode;
  final void Function(RecipeLinkRef link)? onOpenRecipe;
  final void Function(ChatOptionModel option)? onSelectOption;
  final Future<String?> Function(String recipeId)? imageResolver;
  final int? messageIndex;
  final int? savedRecipeId;
  final bool isAddingRecipe;
  final VoidCallback? onAddRecipe;

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.only(left: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF059669), Color(0xFF047857)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(4),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDarkMode ? 0.35 : 0.06,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: message.options.isNotEmpty
                    ? Text(
                        'I\'ve got ${message.options.length} ${message.options.length == 1 ? 'way' : 'ideas'} for you — pick what works best:',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: isDarkMode
                              ? const Color(0xFFE2E8F0)
                              : const Color(0xFF111827),
                        ),
                      )
                    : MarkdownReplyBody(
                        markdown: message.text,
                        isDarkMode: isDarkMode,
                        recipes: message.recipes,
                        onOpenRecipe: onOpenRecipe,
                        imageResolver: imageResolver,
                      ),
              ),
            ),
          ],
        ),
        if (message.options.isNotEmpty && onSelectOption != null)
          Padding(
            padding: const EdgeInsets.only(left: 38, top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: message.options.map((opt) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Material(
                      color: isDarkMode
                          ? const Color(0xFF1A1A1A)
                          : Colors.white,
                      child: InkWell(
                        onTap: () => onSelectOption!(opt),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(
                                0xFF059669,
                              ).withValues(alpha: 0.45),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF059669),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${opt.index}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      opt.label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDarkMode
                                            ? const Color(0xFFE2E8F0)
                                            : const Color(0xFF111827),
                                        height: 1.3,
                                      ),
                                    ),
                                    if (opt.rationale.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        opt.rationale,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDarkMode
                                              ? const Color(0xFF64748B)
                                              : const Color(0xFF9CA3AF),
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: Color(0xFF059669),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        if (onAddRecipe != null && isDetailRecipeMarkdown(message.text))
          Padding(
            padding: const EdgeInsets.only(left: 38, top: 8),
            child: _AddRecipeFromChatButton(
              isSaving: isAddingRecipe,
              savedRecipeId: savedRecipeId,
              isDarkMode: isDarkMode,
              onAdd: onAddRecipe,
            ),
          ),
      ],
    );
  }
}

class _AddRecipeFromChatButton extends StatelessWidget {
  const _AddRecipeFromChatButton({
    required this.isSaving,
    required this.savedRecipeId,
    required this.isDarkMode,
    required this.onAdd,
  });

  final bool isSaving;
  final int? savedRecipeId;
  final bool isDarkMode;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final isSaved = savedRecipeId != null;
    final bgColor = isDarkMode ? const Color(0xFF1A2E1A) : const Color(0xFFECFDF5);
    final borderColor = isDarkMode
        ? const Color(0xFF059669).withValues(alpha: 0.4)
        : const Color(0xFF059669).withValues(alpha: 0.3);
    final textColor =
        isDarkMode ? const Color(0xFF4ADE80) : const Color(0xFF059669);

    return GestureDetector(
      onTap: (isSaving || isSaved) ? null : onAdd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSaving)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: textColor,
                ),
              )
            else if (isSaved)
              Icon(Icons.check_circle_rounded, size: 14, color: textColor)
            else
              Icon(Icons.bookmark_add_outlined, size: 14, color: textColor),
            const SizedBox(width: 6),
            Text(
              isSaving
                  ? 'Saving…'
                  : isSaved
                      ? 'Saved to my recipes'
                      : 'Add to my recipes',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextAreaEditSheet extends StatefulWidget {
  const _TextAreaEditSheet({
    required this.title,
    required this.initialText,
    required this.isDarkMode,
  });

  final String title;
  final String initialText;
  final bool isDarkMode;

  @override
  State<_TextAreaEditSheet> createState() => _TextAreaEditSheetState();
}

class _TextAreaEditSheetState extends State<_TextAreaEditSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryText = widget.isDarkMode
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF111827);
    final secondaryText = widget.isDarkMode
        ? const Color(0xFF94A3B8)
        : const Color(0xFF6B7280);
    final fieldBg = widget.isDarkMode
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF9FAFB);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Edit the text below, then save.',
              style: TextStyle(fontSize: 12, color: secondaryText),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 6,
              minLines: 4,
              style: TextStyle(fontSize: 14, height: 1.4, color: primaryText),
              decoration: InputDecoration(
                filled: true,
                fillColor: fieldBg,
                hintText: 'Type here...',
                hintStyle: TextStyle(color: secondaryText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: const Color(0xFF059669).withValues(alpha: 0.4),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: const Color(0xFF059669).withValues(alpha: 0.35),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF059669),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_controller.text),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                ),
                child: Text(S.of(context).save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
